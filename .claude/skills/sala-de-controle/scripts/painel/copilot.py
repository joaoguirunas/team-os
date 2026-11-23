"""Copiloto da Ganga (etapa 5) e fila de pedidos às sessões (etapa 4).

Copiloto: compara cada leitura do painel com a anterior e gera avisos curtos —
  • alguém precisa de você (sessão ou agente esperando resposta/permissão)
  • uma sessão terminou o que estava fazendo
  • deu erro
  • resumo a cada hora cheia
Só fala (voz do Mac, `say`) com a Ganga ligada no modo Copiloto e fora de uma conversa por voz.
Agrupa avisos próximos, nunca fala mais de uma vez a cada 20 s e nunca repete o mesmo aviso em 10 min.

Pedidos: a Ganga só PREPARA o pedido (rascunho) e, depois do "sim" do João, grava na fila
`docs/smart-memory/sala-de-controle/ganga/pedidos.jsonl` do CT. Quem entrega é a sessão da Sala,
que escuta a fila com `ganga-fila.py --wait` e despacha pelas regras dela. Nada perigoso sai direto:
push, deploy, publicar, apagar, pagar ou enviar para fora fica marcado `ok_no_chat` e a Sala pergunta no chat.
"""
import json
import os
import re
import subprocess
import threading
import time
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
CT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", ".."))
QDIR = os.path.join(CT, "docs", "smart-memory", "sala-de-controle", "ganga")
QUEUE = os.path.join(QDIR, "pedidos.jsonl")
HEARTBEAT = os.path.join(QDIR, ".sala-ouvindo")

ERR_RE = re.compile(r"\b(erro|falhou|falha|quebrou|failed|error|exception|traceback|FAIL)\b", re.I)
DANGER_RE = re.compile(
    r"\b(push|deploy|publi(ca|que|car)|post(a|e|ar)\b|apag|delet|exclu|remov|pag(a|ue|ar)|transf|pix|"
    r"envi(a|e|ar)\b.*\b(cliente|whats|e-?mail|mensagem|fora)|whats|e-?mail|merge|produ[cç][aã]o|rotacion|senha)", re.I)


def short(name):
    name = name or ""
    return name.split("|")[-1].strip() if "|" in name else name.replace("(casa da Sala)", "").strip()


class Copilot:
    def __init__(self, prefs_fn):
        self.prefs_fn = prefs_fn
        self.prev = {}            # chave -> estado anterior
        self.notices = []         # [{seq, kind, text, epoch, spoken}]
        self.seq = 0
        self.lock = threading.Lock()
        self.pending = []         # avisos esperando a janela de agrupamento
        self.first_at = 0.0
        self.last_spoken = 0.0
        self.recent = {}          # texto -> epoch (anti-repetição)
        self.last_hour = time.strftime("%Y-%m-%d %H")
        self.live = False         # o painel avisa quando há conversa por voz aberta
        self.primed = False

    # ---------- leitura do estado ----------
    def feed(self, data):
        p = self.prefs_fn()
        out = []
        cur = {}
        for s in data.get("sessions", []):
            if s.get("stopped") or s.get("is_self") or s.get("is_sala"):
                continue
            proj = short(s.get("project_name") or s.get("name") or "")
            sname = short(s.get("name") or proj)
            k = "s:" + s["id"]
            last = (s.get("turns") or [{}])[-1].get("text", "") if s.get("turns") else ""
            st = {"status": s.get("status", ""), "state": s.get("state", ""), "last": last[:300]}
            cur[k] = st
            pv = self.prev.get(k)
            if pv:
                if st["state"] == "approval" and pv["state"] != "approval":
                    out.append(("wait", f"A sessão {sname} precisa de você."))
                elif pv["status"] == "busy" and st["status"] != "busy" and st["state"] != "approval":
                    if ERR_RE.search(st["last"]):
                        out.append(("error", f"A sessão {sname} parou com erro."))
                    else:
                        out.append(("done", f"A sessão {sname} terminou."))
            for a in s.get("agents", []):
                ka = k + "/" + a.get("name", "")
                cur[ka] = {"status": a.get("state", ""), "state": a.get("state", ""), "last": ""}
                pa = self.prev.get(ka)
                if pa and a.get("state") != pa["state"]:
                    if a.get("state") == "approval":
                        out.append(("wait", f"{a.get('name')}, em {sname}, precisa de você."))
                    elif a.get("state") == "done":
                        out.append(("done", f"{a.get('name')} concluiu em {sname}."))
        self.prev = cur
        if not self.primed:               # 1ª leitura só aprende o estado, não avisa
            self.primed = True
            return
        notify = p.get("notify", {})
        for kind, text in out:
            if notify.get(kind, True):
                self.queue(kind, text)
        hour = time.strftime("%Y-%m-%d %H")
        if hour != self.last_hour:
            self.last_hour = hour
            if notify.get("hourly", True):
                self.queue("hourly", self.summary(data), group=False)
        self.flush(p)

    def summary(self, data):
        c = data.get("counts", {})
        ss = [s for s in data.get("sessions", []) if s.get("recent") and not s.get("is_self") and not s.get("stopped")]
        busy = [short(s.get("name", "")) for s in ss if s.get("status") == "busy"]
        wait = [short(s.get("name", "")) for s in ss if s.get("state") == "approval"]
        parts = [f"Resumo das {time.strftime('%H')} horas."]
        if busy:
            parts.append(f"{len(busy)} {'sessão trabalhando' if len(busy) == 1 else 'sessões trabalhando'}: {', '.join(busy[:3])}.")
        else:
            parts.append("Nenhuma sessão trabalhando agora.")
        if wait:
            parts.append(f"Esperando você: {', '.join(wait[:3])}.")
        if c.get("done"):
            parts.append(f"{c['done']} {'entrega concluída' if c['done'] == 1 else 'entregas concluídas'}.")
        return " ".join(parts)

    # ---------- avisos ----------
    def queue(self, kind, text, group=True):
        now = time.time()
        if now - self.recent.get(text, 0) < 600:
            return
        self.recent[text] = now
        self.pending.append((kind, text))
        if not self.first_at:
            self.first_at = now
        if not group:
            self.first_at = 0  # sai já

    def flush(self, p):
        now = time.time()
        if not self.pending or (self.first_at and now - self.first_at < 6):
            return
        items, self.pending, self.first_at = self.pending, [], 0.0
        order = {"wait": 0, "error": 1, "done": 2, "hourly": 3}
        items.sort(key=lambda x: order.get(x[0], 9))
        if len(items) > 3:
            text = " ".join(t for _, t in items[:2]) + f" E mais {len(items) - 2} novidades."
        else:
            text = " ".join(t for _, t in items)
        kind = items[0][0]
        on = p.get("on") and p.get("mode") == "copiloto"
        speak = on and not self.live and now - self.last_spoken > 20
        with self.lock:
            self.seq += 1
            self.notices.append({"seq": self.seq, "kind": kind, "text": text, "epoch": now, "spoken": bool(speak)})
            self.notices = self.notices[-60:]
        if speak:
            self.last_spoken = now
            self.say(text, p.get("mac_voice") or "Luciana")

    @staticmethod
    def say(text, voice="Luciana"):
        try:
            subprocess.Popen(["say", "-v", voice, "-r", "190", text], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

    def since(self, seq):
        with self.lock:
            return [n for n in self.notices if n["seq"] > seq]


# ---------- etapa 4: pedidos às sessões ----------
DRAFTS = {}


def _sessions_of(project, data):
    ids = set(project.get("sessions", []))
    ss = [s for s in data.get("sessions", []) if s["id"] in ids and not s.get("stopped") and not s.get("is_self") and not s.get("is_sala")]
    ss.sort(key=lambda s: (s.get("age") is None, s.get("age") or 0))
    return ss


def draft(project, text, data):
    text = re.sub(r"\s+", " ", (text or "")).strip()[:1500]
    if not text:
        return {"error": "pedido vazio"}
    ss = _sessions_of(project, data)
    sess = ss[0] if ss else None
    did = uuid.uuid4().hex[:8]
    d = {"id": did, "created": time.time(), "project": project["name"], "project_path": project.get("path", ""),
         "session": sess["name"] if sess else None, "session_id": sess["id"] if sess else None,
         "session_status": (sess.get("status") if sess else None), "text": text,
         "ok_no_chat": bool(DANGER_RE.search(text))}
    DRAFTS[did] = d
    for k in [k for k, v in DRAFTS.items() if time.time() - v["created"] > 600]:
        DRAFTS.pop(k, None)
    return d


def confirm(did):
    d = DRAFTS.pop(did or "", None)
    if not d:
        return {"error": "rascunho não encontrado ou expirado — prepare de novo"}
    if time.time() - d["created"] > 300:
        return {"error": "rascunho expirou (5 min) — prepare de novo"}
    os.makedirs(QDIR, exist_ok=True)
    line = {**d, "status": "na_fila", "confirmed": time.strftime("%Y-%m-%dT%H:%M:%S"), "via": "ganga"}
    with open(QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps(line, ensure_ascii=False) + "\n")
    return {"ok": True, "id": d["id"], "sala_ouvindo": sala_listening(), "ok_no_chat": d["ok_no_chat"]}


def read_queue(limit=20):
    if not os.path.exists(QUEUE):
        return []
    rows = {}
    for ln in open(QUEUE, encoding="utf-8"):
        try:
            r = json.loads(ln)
        except Exception:
            continue
        rows[r["id"]] = {**rows.get(r["id"], {}), **r}   # linhas de status atualizam o pedido
    return sorted(rows.values(), key=lambda r: r.get("confirmed", ""), reverse=True)[:limit]


def sala_listening():
    try:
        return time.time() - os.path.getmtime(HEARTBEAT) < 90
    except OSError:
        return False
