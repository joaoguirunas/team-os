"""Copiloto da Ganga (etapa 5) e fila de pedidos às sessões (etapa 4).

Copiloto: compara cada leitura do painel com a anterior e gera avisos curtos —
  • alguém precisa de você (sessão ou agente esperando resposta/permissão)
  • uma sessão terminou o que estava fazendo
  • deu erro
  • resumo a cada hora cheia
Só fala (voz do Mac, `say`) com a Ganga ligada no modo Copiloto e fora de uma conversa por voz.
Agrupa avisos próximos, nunca fala mais de uma vez a cada 20 s e nunca repete o mesmo aviso em 10 min.

Pedidos: a Ganga só PREPARA o pedido (rascunho) e, depois do "sim" do usuário, grava na fila
`docs/smart-memory/sala-de-controle/ganga/pedidos.jsonl` do CT. Quem entrega é a sessão da Sala,
que escuta a fila com `ganga-fila.py --wait` e despacha pelas regras dela. Nada perigoso sai direto:
envio para fora (WhatsApp, e-mail, cliente, publicar) pede um "sim" falado na Ganga e sai com `ok_por_voz`;
só o muito sensível (pagar, apagar, push, deploy, produção, senha) fica `ok_no_chat` e a Sala pergunta no chat.
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
# muito sensível: mexe em dinheiro, apaga, vai para produção ou toca em senha → OK no chat da Sala
SENSITIVE_RE = re.compile(
    r"\b(push|deploy|merge|(em|para|na|no\s+ambiente\s+de|subir\s+(para|pra))\s+produ[cç][aã]o|"
    r"apag(a|ue|ar|ando)|delet(a|e|ar)|exclu(a|i|ir|indo|s[aã]o)\b|drop\b|rm\s+-|reset\s+--hard|--force|force[- ]push|"
    r"descart(a|e|ar)\s+(as\s+|os\s+)?(mudan|altera)|limp(a|e|ar)\s+(a\s+|o\s+)?(pasta|banco|base|tabela|disco|dados)|"
    r"instal(a|e|ar)\s+(o\s+|um\s+)?(pacote|programa|app)|execut(a|e|ar)\s+(o\s+|um\s+)?(script|comando)|"
    r"rod(a|e|ar)\s+(o\s+|um\s+)?(script|comando|\.sh)|pag(a|ue|ar|amento)\b|transfer[eê]ncia|transf(ira|erir)|\bpix\b|boleto|"
    r"rotacion|senha|credencia|token|cancel(a|ar)\s+(o\s+)?(contrato|assinatura))", re.I)
# sai para fora (WhatsApp, e-mail, cliente, publicar): basta o "sim" falado na Ganga, depois de ela ler destino e texto
EXTERNAL_RE = re.compile(
    r"\b(publi(ca|que|car)|post(a|e|ar)\b|github|whats|zap|e-?mail|sms|instagram|telegram|linkedin|slack|\bdm\b|direct|"
    r"dispar(a|e|ar)|cliente|contato|n[uú]mero\s+\d|\+?\d{10,}|"
    r"(envi|mand|respond|encaminh)\w*\b.{0,50}\b(mensagem|fora|cliente|contato|n[uú]mero))", re.I)
# "manda pro Carlos" / "responde a Ana": verbo de envio + pessoa (nome com maiúscula) → externo
PERSON_RE = re.compile(r"\b(?i:mand\w*|envi\w*|respond\w*|encaminh\w*|fal[ae])\b.{0,40}\b(?i:pr[oa]|para|ao|à|a)\s+([A-ZÁ-Ú][a-zá-ú]+)")
DANGER_RE = re.compile(SENSITIVE_RE.pattern + "|" + EXTERNAL_RE.pattern, re.I)   # compatibilidade


ASK_RE = re.compile(r"(\?\s*$|\?\s*\n|quer que eu|posso (seguir|continuar|fazer|mandar|enviar|aplicar|subir)|prefere|"
                    r"confirma|aprova|me (diga|avise|fala)|qual (voc[eê]|delas|deles|op[cç][aã]o)|decis[aã]o|escolh|"
                    r"aguardo|preciso (de|que) voc|sua (resposta|aprova|decis|confirma|vez)|depende de voc)", re.I)


def needs_reply(text):
    """A última mensagem da sessão termina pedindo algo do usuário (pergunta, decisão, aprovação)?"""
    tail = (text or "").strip()[-500:]
    return bool(tail) and bool(ASK_RE.search(tail))


def short(name):
    name = name or ""
    return name.split("|")[-1].strip() if "|" in name else name.replace("(casa da Sala)", "").strip()


class Copilot:
    def __init__(self, prefs_fn, tts_fn=None):
        self.prefs_fn = prefs_fn
        self.tts_fn = tts_fn      # texto → WAV com a voz da Ganga (ou None)
        self.line_fn = None       # aviso → fala curta com a personalidade da Ganga (ou None)
        self.panel_at = 0.0       # último contato do painel aberto no navegador
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
        self.live_at = 0.0        # e repete o aviso a cada 5 s; sem aviso por 30 s, a conversa acabou (aba fechada)
        self.primed = False

    # ---------- leitura do estado ----------
    # Só avisa quando o usuário precisa agir: sessão pedindo permissão, sessão que terminou PERGUNTANDO algo, ou que parou
    # com erro. Agente, subtarefa e "terminou" sem pergunta não interessam — ficam só no painel.
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
            turns = s.get("turns") or []
            last = next((t.get("text", "") for t in reversed(turns) if t.get("who") == "agente"), "")
            st = {"status": s.get("status", ""), "state": s.get("state", ""), "last": last[-1500:]}
            cur[k] = st
            pv = self.prev.get(k)
            meta = {"session": sname, "project": proj, "session_id": s["id"]}
            if pv:
                if st["state"] == "approval" and pv["state"] != "approval":
                    out.append(("wait", f"A sessão {sname} está pedindo uma permissão sua no app.", {**meta, "ask": st["last"][-600:]}))
                elif pv["status"] == "busy" and st["status"] != "busy" and st["state"] != "approval":
                    if ERR_RE.search(st["last"][-400:]) and not needs_reply(st["last"]):
                        out.append(("error", f"A sessão {sname} parou com erro.", {**meta, "ask": st["last"][-600:]}))
                    elif needs_reply(st["last"]):
                        out.append(("ask", f"A sessão {sname} terminou e quer saber de você.", {**meta, "ask": st["last"][-900:]}))
        # pedido da Ganga parado esperando o OK do usuário → a Ganga chama e pergunta "aprovo?"
        for r in read_queue(20):
            if r.get("status") == "aguardando_ok":
                cur["o:" + r["id"]] = {"status": "aguardando_ok", "state": "", "last": ""}
                if "o:" + r["id"] not in self.prev:
                    out.append(("order", f"Um pedido para {short(r.get('project', ''))} está esperando sua aprovação.",
                                {"session": short(r.get("project", "")), "project": r.get("project", ""), "order_id": r["id"],
                                 "ask": r.get("text", "")}))
        self.prev = cur
        if not self.primed:               # 1ª leitura só aprende o estado, não avisa
            self.primed = True
            return
        notify = p.get("notify", {})
        for kind, text, meta in out:
            if notify.get("wait" if kind in ("ask", "order") else kind, True):
                self.queue(kind, text, meta=meta)
        hour = time.strftime("%Y-%m-%d %H")
        if hour != self.last_hour:
            self.last_hour = hour
            if notify.get("hourly", False):
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
    def queue(self, kind, text, group=True, meta=None):
        now = time.time()
        key = text + (meta or {}).get("ask", "")[-200:]
        if now - self.recent.get(key, 0) < 600:
            return
        self.recent[key] = now
        self.pending.append((kind, text, meta or {}))
        if not self.first_at:
            self.first_at = now
        if not group:
            self.first_at = 0  # sai já

    def flush(self, p):
        now = time.time()
        if not self.pending or (self.first_at and now - self.first_at < 4):
            return
        items, self.pending, self.first_at = self.pending, [], 0.0
        order = {"order": 0, "ask": 0, "wait": 1, "error": 2, "hourly": 3}
        items.sort(key=lambda x: order.get(x[0], 9))
        kind, text, meta = items[0]
        if len(items) > 1:
            text += f" E mais {len(items) - 1} {'sessão precisa' if len(items) == 2 else 'sessões precisam'} de você."
        on = p.get("on") and p.get("mode") == "copiloto"
        live = self.live and now - self.live_at < 30
        speak = on and not live
        with self.lock:
            self.seq += 1
            n = {"seq": self.seq, "kind": kind, "text": text, "epoch": now, "spoken": bool(speak),
                 "session": meta.get("session"), "project": meta.get("project"), "ask": meta.get("ask", "")[-900:],
                 "order_id": meta.get("order_id"), "line": None, "call": False}
            self.notices.append(n)
            self.notices = self.notices[-60:]
        if speak:
            self.last_spoken = now
            threading.Thread(target=self._announce, args=(n, p), daemon=True).start()

    def _announce(self, n, p):
        """A Ganga chama o usuário: escreve a fala com a personalidade dela e pergunta o que fazer.
        Com o painel aberto no Chrome, o painel abre a conversa por voz (ela fala e já escuta a resposta);
        sem painel, ou se ele não atender em 8 s, toca a fala com a voz dela no Mac."""
        line = (self.line_fn(n) if self.line_fn else None) or n["text"]
        with self.lock:
            n["line"] = line
            n["call"] = time.time() - self.panel_at < 8 and n["kind"] in ("ask", "error", "wait", "order")
        if n["call"]:
            t0 = time.time()
            while time.time() - t0 < 8:
                if self.live and self.live_at > t0:
                    return                      # o painel atendeu: a fala sai pela conversa ao vivo
                time.sleep(0.5)
        self._say(line, p.get("mac_voice") or "Ganga", n["seq"])

    def say(self, text, voice="Ganga", seq=None):
        """Fala o aviso. Padrão: a voz da própria Ganga (Gemini TTS) tocada no Mac; o painel anima a esfera junto.
        Sem chave, sem rede ou com voz do Mac escolhida em ⚙ → `say` do macOS."""
        threading.Thread(target=self._say, args=(text, voice, seq), daemon=True).start()

    def _say(self, text, voice, seq):
        dur, how = 0.0, "mac"
        wav = self.tts_fn(text) if (voice == "Ganga" and self.tts_fn) else None
        try:
            if wav:
                path = os.path.join(QDIR, ".aviso.wav")
                os.makedirs(QDIR, exist_ok=True)
                with open(path, "wb") as f:
                    f.write(wav)
                dur, how = max(0.5, (len(wav) - 44) / 48000), "ganga"
                self._mark(seq, how, dur)
                subprocess.run(["afplay", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
            else:
                dur = max(1.5, len(text) / 14)
                self._mark(seq, how, dur)
                subprocess.run(["say", "-v", voice if voice != "Ganga" else "Luciana", "-r", "190", text],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
        except Exception:
            pass

    def _mark(self, seq, how, dur):
        with self.lock:
            for n in self.notices:
                if n["seq"] == seq:
                    n.update(voz=how, speak_at=time.time(), dur=round(dur, 1))

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


def level(text, project_name=""):
    if SENSITIVE_RE.search(text):
        return "sensivel"
    if EXTERNAL_RE.search(text):
        return "externo"
    words = {w.lower() for w in re.findall(r"[A-Za-zÀ-ÿ]+", project_name or "")}
    for m in PERSON_RE.finditer(text):
        if m.group(1).lower() not in words:      # "manda pro Comercial" é o projeto; "manda pro Carlos" é pessoa
            return "externo"
    return "normal"


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
         "nivel": level(text, project.get("name", ""))}
    d["ok_no_chat"] = d["nivel"] == "sensivel"      # só o muito sensível ainda pede OK no chat da Sala
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
    dup = [r for r in read_queue(30) if r.get("project") == d["project"] and r.get("text") == d["text"]
           and r.get("status") in ("na_fila", "entregue") and time.time() - _epoch(r.get("confirmed")) < 120]
    if dup:
        return {"ok": True, "id": dup[0]["id"], "duplicado": True, "sala_ouvindo": sala_listening(), "ok_no_chat": d["ok_no_chat"]}
    os.makedirs(QDIR, exist_ok=True)
    line = {**d, "status": "na_fila", "confirmed": time.strftime("%Y-%m-%dT%H:%M:%S"), "via": "ganga",
            "ok_por_voz": d["nivel"] == "externo"}   # o "sim" falado do usuário para ESTE envio já é o OK
    with open(QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps(line, ensure_ascii=False) + "\n")
    return {"ok": True, "id": d["id"], "sala_ouvindo": sala_listening(), "ok_no_chat": d["ok_no_chat"]}


def _epoch(stamp):
    try:
        return time.mktime(time.strptime((stamp or "")[:19], "%Y-%m-%dT%H:%M:%S"))
    except ValueError:
        return 0.0


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


def set_status(pid, status, note=""):
    """Aprovar ou cancelar pela Ganga um pedido que espera o OK do usuário."""
    rows = {r["id"]: r for r in read_queue(500)}
    r = rows.get(pid or "")
    if not r:
        return {"error": "pedido não encontrado"}
    if status == "aprovado" and r.get("status") not in ("aguardando_ok", "na_fila"):
        return {"error": f"esse pedido está {r.get('status')}, não espera aprovação"}
    with open(QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps({"id": pid, "status": status, "note": note[:300], "updated": time.strftime("%Y-%m-%dT%H:%M:%S"),
                            **({"aprovado_pelo_usuario": True} if status == "aprovado" else {})}, ensure_ascii=False) + "\n")
    return {"ok": True, "id": pid, "status": status, "sala_ouvindo": sala_listening()}


def sala_listening():
    try:
        return time.time() - os.path.getmtime(HEARTBEAT) < 90
    except OSError:
        return False
