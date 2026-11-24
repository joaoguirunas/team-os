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
QDIR = os.environ.get("GANGA_QDIR") or os.path.join(CT, "docs", "smart-memory", "sala-de-controle", "ganga")
QUEUE = os.path.join(QDIR, "pedidos.jsonl")
HEARTBEAT = os.path.join(QDIR, ".sala-ouvindo")

ERR_RE = re.compile(r"\b(erro|falhou|falha|quebrou|failed|error|exception|traceback|FAIL)\b", re.I)
NOERR_RE = re.compile(r"\b(sem|nenhum|zero|0|corrig\w+|resolv\w+|consert\w+|tratamento de|handling)\s+(o\s+|os\s+|de\s+)?(erros?|falhas?|errors?)\b|"
                      r"\berror handling\b", re.I)
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


ASK_RE = re.compile(r"(\?\s*$|quer que eu|posso (seguir|continuar|fazer|mandar|enviar|aplicar|subir|publicar)|voc[eê] prefere|"
                    r"(me )?confirma[s]?\b|voc[eê] aprova|me (diga|fala)\b|qual (voc[eê]|delas|deles|op[cç][aã]o)|"
                    r"aguardo (sua|seu|voc)|preciso (de|que) voc|sua (resposta|aprova|decis|confirma)|depende de voc)", re.I)


def needs_reply(text):
    """A última mensagem da sessão termina pedindo algo do usuário (pergunta, decisão, aprovação)? Olha só o final."""
    tail = (text or "").strip()
    if not tail:
        return False
    last = re.split(r"(?<=[.!?…])\s+", tail[-400:])[-2:]        # as duas últimas frases
    return bool(ASK_RE.search(" ".join(last)))


def has_error(text):
    t = (text or "")[-400:]
    return bool(ERR_RE.search(NOERR_RE.sub(" ", t)))


def short(name):
    name = name or ""
    return name.split("|")[-1].strip() if "|" in name else name.replace("(casa da Sala)", "").strip()


AUTO_NOTE = ("[Copiloto da Ganga — resposta automática; o usuário NÃO foi consultado] ")
AUTO_GUARD = (" Limite: siga só com o que o usuário já tinha pedido. Não publique, não envie nada para fora, não apague, "
              "não gaste dinheiro e não decida por ele — nesses casos pare e pergunte.")


class Copilot:
    """Olha as sessões e mantém o trabalho andando.

    · Sessão parou pedindo só licença para continuar o que o usuário já pediu → responde sozinha ("pode seguir").
    · Sessão parou com erro que ela mesma pode corrigir → pede uma tentativa (uma vez).
    · Pedido entregue há mais de 10 min e sem retorno → cobra a sessão (uma vez).
    · Decisão de verdade (escolha, aprovação, publicar, enviar, apagar, gastar, permissão do app) → chama o usuário.
    Tudo o que ela faz sozinha vira pedido na fila com `auto: true` e aparece no painel. Avisos são falados um por vez;
    o que chega durante uma conversa por voz espera a conversa acabar.
    """

    def __init__(self, prefs_fn, tts_fn=None):
        self.prefs_fn = prefs_fn
        self.tts_fn = tts_fn      # texto → WAV com a voz da Ganga (ou None)
        self.line_fn = None       # aviso → fala curta com a personalidade da Ganga (ou None)
        self.decide_fn = None     # (sessão, objetivo, fim da fala) → {"tipo", "resposta", "pergunta"} (ou None)
        self.panel_at = 0.0       # último contato do painel aberto no navegador
        self.prev = {}            # chave -> estado anterior
        self.notices = []         # [{seq, kind, text, epoch, spoken, ...}]
        self.seq = 0
        self.lock = threading.Lock()
        self.todo = []            # avisos esperando a vez de serem falados
        self.speaking = False
        self.last_spoken = 0.0
        self.recent = {}          # chave -> epoch (anti-repetição)
        self.autos = {}           # session_id -> [epochs das ações automáticas]
        self.nudged = set()       # pedidos já cobrados
        self.last_hour = time.strftime("%Y-%m-%d %H")
        self.live = False         # o painel avisa quando há conversa por voz aberta
        self.live_at = 0.0        # e repete a cada 5 s; sem aviso por 30 s, a conversa acabou (aba fechada)
        self.primed = False

    # ---------- leitura do estado ----------
    def feed(self, data):
        p = self.prefs_fn()
        events, cur = [], {}
        pname = {pr.get("path"): pr.get("name") for pr in data.get("projects", [])}
        for s in data.get("sessions", []):
            if s.get("stopped") or s.get("is_self") or s.get("is_sala"):
                continue
            proj = pname.get(s.get("project")) or s.get("name") or ""
            sname = short(s.get("name") or proj)
            k = "s:" + s["id"]
            tail = s.get("tail") or next((t.get("text", "") for t in reversed(s.get("turns") or []) if t.get("who") == "agente"), "")
            st = {"status": s.get("status", ""), "state": s.get("state", "")}
            cur[k] = st
            pv = self.prev.get(k)
            meta = {"session": sname, "project": proj, "session_id": s["id"], "session_full": s.get("name") or sname,
                    "project_path": s.get("project") or s.get("cwd") or "", "goal": s.get("goal", ""), "ask": tail[-1200:]}
            if pv:
                if st["state"] == "approval" and pv["state"] != "approval":
                    events.append(("wait", f"A sessão {sname} está pedindo uma permissão sua no app.", meta))
                elif pv["status"] == "busy" and st["status"] != "busy" and st["state"] != "approval":
                    events.append(("stopped", "", meta))
        # pedido parado esperando o OK do usuário → a Ganga chama e pergunta
        queue = read_queue(40)
        for r in queue:
            if r.get("status") == "aguardando_ok":
                cur["o:" + r["id"]] = {"status": "aguardando_ok", "state": ""}
                if "o:" + r["id"] not in self.prev:
                    events.append(("order", f"Um pedido para {short(r.get('project', ''))} está esperando sua aprovação.",
                                   {"session": short(r.get("project", "")), "project": r.get("project", ""), "order_id": r["id"],
                                    "ask": (r.get("text", "") + (" — " + r["note"] if r.get("note") else ""))[:900]}))
        self.prev = cur
        if not self.primed:               # 1ª leitura só aprende o estado, não avisa
            self.primed = True
            return
        active = bool(p.get("on")) and p.get("mode") == "copiloto"
        notify = p.get("notify", {})
        for kind, text, meta in events:
            if kind == "stopped":
                if active:                # decidir pode chamar o Gemini: fora do laço de coleta
                    threading.Thread(target=self._on_stop, args=(meta, p), daemon=True).start()
            elif notify.get("wait", True):
                self.notify(kind, text, meta)
        if active and p.get("auto", True):
            self._nudge(queue, data)
        hour = time.strftime("%Y-%m-%d %H")
        if hour != self.last_hour:
            self.last_hour = hour
            if notify.get("hourly", False):
                self.notify("hourly", self.summary(data), {})
        self._pump(p)

    def _on_stop(self, meta, p):
        """A sessão parou: decide se é nada, continuação (age sozinha), erro (tenta uma vez) ou decisão (chama o usuário)."""
        try:
            tail = meta.get("ask", "")
            d = (self.decide_fn(meta["session"], meta.get("goal", ""), tail) if self.decide_fn else None) or {}
            tipo = d.get("tipo")
            if tipo not in ("nada", "continuar", "erro", "decisao"):          # sem Gemini: regra simples e conservadora
                tipo = "decisao" if needs_reply(tail) else "erro" if has_error(tail) else "nada"
                d = {}
            if tipo == "decisao" and not needs_reply(tail) and not has_error(tail):
                tipo = "nada"             # ela não perguntou nada: não incomoda o usuário
            # continuar nunca cobre o que publica, envia, apaga ou gasta — isso é decisão do usuário
            if tipo == "continuar" and (HARD_RE.search(tail[-500:]) or SENSITIVE_RE.search(tail[-500:]) or EXTERNAL_RE.search(tail[-500:])):
                tipo = "decisao"
            auto_ok = p.get("auto", True) and self._can_auto(meta["session_id"])
            notify = p.get("notify", {})
            if tipo == "continuar" and auto_ok:
                txt = d.get("resposta") or "Pode seguir com o que já estava combinado."
                if self._auto(meta, txt, "continuar"):
                    return
            if tipo == "continuar":       # não pôde agir sozinha (desligado, limite ou repetido): pergunta ao usuário
                tipo = "decisao"
            if tipo == "erro" and auto_ok and not self._did(meta["session_id"], "erro"):
                txt = d.get("resposta") or "Tente corrigir esse erro e seguir. Se não conseguir, diga em uma frase o que falta."
                if self._auto(meta, txt, "erro"):
                    return
            if tipo == "erro":
                if notify.get("error", True):
                    self.notify("error", f"A sessão {meta['session']} parou com erro.", meta)
            elif tipo == "decisao":
                if notify.get("wait", True):
                    self.notify("ask", d.get("pergunta") or f"A sessão {meta['session']} terminou e quer saber de você.", meta)
            elif tipo == "nada" and p.get("auto_next") and auto_ok and not self._did(meta["session_id"], "proximo"):
                self._auto(meta, "Se o plano ou o backlog do projeto tem um próximo passo já aprovado, siga para ele. "
                                 "Se não tem, ou se precisar de decisão, responda só com o que falta decidir.", "proximo")
            self._pump(p)
        except Exception:
            pass

    # ---------- ações automáticas ----------
    def _can_auto(self, sid, per_hour=3):
        now = time.time()
        ts = [t for t, _ in self.autos.get(sid, []) if now - t < 3600]
        return len(ts) < per_hour

    def _did(self, sid, kind):
        now = time.time()
        return any(k == kind and now - t < 3600 for t, k in self.autos.get(sid, []))

    def _auto(self, meta, text, kind):
        full = AUTO_NOTE + text.strip()[:400] + AUTO_GUARD
        if not auto_order(meta, full, kind):
            return False
        self.autos.setdefault(meta["session_id"], []).append((time.time(), kind))
        label = {"continuar": "disse para seguir", "erro": "pediu uma correção", "proximo": "mandou seguir o plano",
                 "cobrar": "cobrou o retorno"}.get(kind, "agiu")
        self.notify("auto", f"{meta['session']}: {label} sozinha. “{text.strip()[:140]}”", meta, speak=False)
        return True

    def _nudge(self, queue, data):
        """Pedido entregue há mais de 10 min, sessão parada e sem retorno → cobra uma vez."""
        by_id = {s["id"]: s for s in data.get("sessions", [])}
        for r in queue:
            if r.get("status") != "entregue" or r.get("auto") or r["id"] in self.nudged or r.get("cobrado"):
                continue
            age = time.time() - _epoch(r.get("updated") or r.get("confirmed"))
            if age < 600 or age > 7200:          # só cobra o que foi entregue entre 10 min e 2 h atrás
                continue
            s = by_id.get(r.get("session_id") or "")
            if not s or s.get("status") == "busy" or s.get("state") == "approval" or s.get("stopped"):
                continue
            self.nudged.add(r["id"])
            append_status(r["id"], "entregue", r.get("note", ""), cobrado=True)
            meta = {"session": short(r.get("session") or r.get("project", "")), "project": r.get("project", ""), "session_id": s["id"],
                    "session_full": r.get("session"), "project_path": r.get("project_path", "")}
            if self._can_auto(s["id"]) and not self._did(s["id"], "cobrar"):     # uma cobrança por sessão por hora
                self._auto(meta, f"Como ficou este pedido: “{r.get('text', '')[:160]}”? Se terminou, responda com um resumo curto; "
                                 f"se falta algo, diga o quê.", "cobrar")

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
        return " ".join(parts)

    # ---------- avisos: um por item, falados um de cada vez ----------
    def notify(self, kind, text, meta, speak=True):
        now = time.time()
        key = kind + "|" + (meta.get("session_id") or meta.get("order_id") or "") + "|" + (meta.get("ask") or text)[-200:]
        with self.lock:
            for k in [k for k, t in self.recent.items() if now - t > 600]:
                self.recent.pop(k, None)
            if key in self.recent:
                return
            self.recent[key] = now
            self.seq += 1
            n = {"seq": self.seq, "kind": kind, "text": text, "epoch": now, "spoken": False, "wants_voice": bool(speak),
                 "session": meta.get("session"), "project": meta.get("project"), "ask": (meta.get("ask") or "")[-900:],
                 "order_id": meta.get("order_id"), "line": None, "call": False}
            self.notices.append(n)
            self.notices = self.notices[-80:]
            if speak:
                self.todo.append(n)

    def _pump(self, p):
        """Fala o próximo aviso da fila, se ninguém está falando e não há conversa por voz aberta."""
        now = time.time()
        if not (p.get("on") and p.get("mode") == "copiloto"):
            with self.lock:
                self.todo.clear()
            return
        live = self.live and now - self.live_at < 30
        with self.lock:
            self.todo = [n for n in self.todo if now - n["epoch"] < 1800]       # aviso com mais de 30 min não é mais falado
            if self.speaking or live or not self.todo or now - self.last_spoken < 6:
                return
            self.todo.sort(key=lambda n: {"order": 0, "ask": 0, "wait": 1, "error": 2}.get(n["kind"], 9))
            n = self.todo.pop(0)
            n["mais"] = len(self.todo)
            n["spoken"] = True
            self.speaking = True
        threading.Thread(target=self._announce, args=(n, p), daemon=True).start()

    def _announce(self, n, p):
        """A Ganga chama o usuário. Com o painel aberto, ele abre a conversa por voz (ela fala e já escuta a resposta);
        sem painel, ou se ele não atender em 8 s, toca a fala com a voz dela no Mac."""
        try:
            line = (self.line_fn(n) if self.line_fn else None) or n["text"]
            if n.get("mais"):
                line += f" Depois tenho mais {n['mais']} {'ponto' if n['mais'] == 1 else 'pontos'} para você."
            with self.lock:
                n["line"] = line
                # só pedido parado esperando o OK dele abre a voz ao vivo (cara: minutos de Gemini Live); o resto ela fala
                # pelo Mac e, se ele disser "Ganga" logo depois, a conversa já começa no assunto do aviso
                n["call"] = time.time() - self.panel_at < 8 and n["kind"] == "order"
            if n["call"]:
                t0 = time.time()
                while time.time() - t0 < 8:
                    if self.live and self.live_at > t0:
                        return                      # o painel atendeu: a fala sai pela conversa ao vivo
                    time.sleep(0.5)
            self._say(line, p.get("mac_voice") or "Ganga", n["seq"])
        finally:
            self.last_spoken = time.time()
            self.speaking = False

    def say(self, text, voice="Ganga", seq=None):
        """Fala um texto (teste de voz no ⚙). Padrão: a voz da própria Ganga (Gemini TTS) tocada no Mac."""
        threading.Thread(target=self._say, args=(text, voice, seq), daemon=True).start()

    _say_lock = threading.Lock()

    def _say(self, text, voice, seq):
        dur, how = 0.0, "mac"
        wav = self.tts_fn(text) if (voice == "Ganga" and self.tts_fn) else None
        with self._say_lock:                         # uma fala por vez, um arquivo por vez
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
                    subprocess.run(["say", "-r", "190", text] if voice == "Ganga" else ["say", "-v", voice, "-r", "190", text],
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
            return [dict(n) for n in self.notices if n["seq"] > seq]


def auto_order(meta, text, kind):
    """Pedido criado pelo Copiloto (não pelo usuário): vai para a fila como normal, marcado `auto`."""
    recent = [r for r in read_queue(40) if r.get("auto") and r.get("session_id") == meta.get("session_id")
              and r.get("auto_kind") == kind and time.time() - _epoch(r.get("confirmed")) < 600]
    if recent:
        return False
    os.makedirs(QDIR, exist_ok=True)
    line = {"id": uuid.uuid4().hex[:8], "created": time.time(), "project": meta.get("project", ""),
            "project_path": meta.get("project_path", ""), "session": meta.get("session_full") or meta.get("session"),
            "session_id": meta.get("session_id"), "text": text, "nivel": "normal", "status": "na_fila", "via": "copiloto",
            "auto": True, "auto_kind": kind, "confirmed": time.strftime("%Y-%m-%dT%H:%M:%S")}
    with open(QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps(line, ensure_ascii=False) + "\n")
    return True


# ---------- etapa 4: pedidos às sessões ----------
DRAFTS = {}


def _sessions_of(project, data):
    ids = set(project.get("sessions", []))
    ss = [s for s in data.get("sessions", []) if s["id"] in ids and not s.get("stopped") and not s.get("is_self") and not s.get("is_sala")]
    ss.sort(key=lambda s: (s.get("age") is None, s.get("age") or 0))
    return ss


# piso que nenhum classificador rebaixa: dinheiro, apagar por comando, forçar, segredo
HARD_RE = re.compile(r"\b(pag(a|ue|ar|amento)\b|\bpix\b|boleto|transfer[eê]ncia|transf(ira|erir)|rm\s+-|drop\s+(table|database)|"
                     r"reset\s+--hard|force[- ]push|senha|credencia)|--force|\.env\b", re.I)
RANK = {"normal": 0, "externo": 1, "sensivel": 2}


def level(text, project_name="", classify=None):
    """Nível do pedido. Com classificador (Gemini), ele decide; a regex fica de reserva e HARD_RE é o piso."""
    if HARD_RE.search(text):
        return "sensivel"
    lv = classify(text) if classify else None
    if lv in RANK:
        return lv
    if SENSITIVE_RE.search(text):
        return "sensivel"
    if EXTERNAL_RE.search(text):
        return "externo"
    words = {w.lower() for w in re.findall(r"[A-Za-zÀ-ÿ]+", project_name or "")}
    for m in PERSON_RE.finditer(text):
        if m.group(1).lower() not in words:      # "manda pro Comercial" é o projeto; "manda pro Carlos" é pessoa
            return "externo"
    return "normal"


def draft(project, text, data, classify=None):
    text = re.sub(r"\s+", " ", (text or "")).strip()[:1500]
    if not text:
        return {"error": "pedido vazio"}
    ss = _sessions_of(project, data)
    sess = ss[0] if ss else None
    did = uuid.uuid4().hex[:8]
    d = {"id": did, "created": time.time(), "project": project["name"], "project_path": project.get("path", ""),
         "session": sess["name"] if sess else None, "session_id": sess["id"] if sess else None,
         "session_status": (sess.get("status") if sess else None), "text": text,
         "nivel": level(text, project.get("name", ""), classify), "passo": 0}
    d["ok_no_chat"] = False       # toda aprovação é dada na Ganga (voz ou botão); a Sala não pergunta de novo no chat
    DRAFTS[did] = d
    for k in [k for k, v in DRAFTS.items() if time.time() - v["created"] > 600]:
        DRAFTS.pop(k, None)
    return d


def confirm(did):
    """1 "sim" para externo. Para sensível, 2: o primeiro devolve precisa_segunda; o segundo envia."""
    d = DRAFTS.get(did or "")
    if not d:
        return {"error": "rascunho não encontrado ou expirado — prepare de novo"}
    if time.time() - d["created"] > 300:
        DRAFTS.pop(did, None)
        return {"error": "rascunho expirou (5 min) — prepare de novo"}
    if d["nivel"] == "sensivel" and not d.get("passo"):
        d["passo"] = 1
        return {"ok": True, "id": did, "enviado": False, "precisa_segunda": True, "nivel": "sensivel",
                "instrucao": "Ação sensível (vai ao ar, apaga ou mexe com dinheiro). Diga em 1 frase exatamente o que vai "
                             "acontecer e pergunte de novo: \"Confirma mesmo?\". Só com o segundo sim chame confirmar_pedido outra vez."}
    DRAFTS.pop(did, None)
    dup = [r for r in read_queue(30) if r.get("project") == d["project"] and r.get("text") == d["text"]
           and r.get("status") in ("na_fila", "anunciado", "entregue") and time.time() - _epoch(r.get("confirmed")) < 120]
    if dup:
        return {"ok": True, "id": dup[0]["id"], "enviado": True, "duplicado": True, "sala_ouvindo": sala_listening()}
    os.makedirs(QDIR, exist_ok=True)
    # o "sim" do usuário na Ganga (2 para sensível) É a aprovação dele para ESTE pedido
    line = {**d, "status": "na_fila", "confirmed": time.strftime("%Y-%m-%dT%H:%M:%S"), "via": "ganga",
            "ok_por_voz": d["nivel"] != "normal", "aprovado_pelo_usuario": d["nivel"] != "normal"}
    with open(QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps(line, ensure_ascii=False) + "\n")
    return {"ok": True, "id": d["id"], "enviado": True, "nivel": d["nivel"], "sala_ouvindo": sala_listening()}


def _epoch(stamp):
    try:
        return time.mktime(time.strptime((stamp or "")[:19], "%Y-%m-%dT%H:%M:%S"))
    except ValueError:
        return 0.0


_QCACHE = {"key": None, "rows": []}


def read_queue(limit=20):
    try:
        st = os.stat(QUEUE)
    except OSError:
        return []
    key = (QUEUE, st.st_mtime_ns, st.st_size)
    if _QCACHE["key"] == key:                 # a fila é lida várias vezes por segundo: só relê se o arquivo mudou
        return [dict(r) for r in _QCACHE["rows"][:limit]]
    rows = {}
    for ln in open(QUEUE, encoding="utf-8"):
        try:
            r = json.loads(ln)
        except Exception:
            continue
        if not isinstance(r, dict) or not r.get("id"):
            continue
        rows[r["id"]] = {**rows.get(r["id"], {}), **r}   # linhas de status atualizam o pedido
    out = sorted(rows.values(), key=lambda r: r.get("confirmed", ""), reverse=True)
    _QCACHE.update(key=key, rows=out)
    return [dict(r) for r in out[:limit]]


def append_status(pid, status, note="", **extra):
    with open(QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps({"id": pid, "status": status, "note": (note or "")[:500],
                            "updated": time.strftime("%Y-%m-%dT%H:%M:%S"), **extra}, ensure_ascii=False) + "\n")


OPEN_STATES = ("na_fila", "anunciado", "aguardando_ok", "aprovado", "entregue")


def set_status(pid, status, note=""):
    """Aprovar ou cancelar pela Ganga (voz ou botão). Aprovar só o que espera OK; cancelar só o que ainda está aberto."""
    rows = {r["id"]: r for r in read_queue(500)}
    r = rows.get(pid or "")
    if not r:
        return {"error": "pedido não encontrado"}
    cur = r.get("status")
    if status == "aprovado" and cur != "aguardando_ok":
        return {"error": f"esse pedido está {cur}, não espera aprovação"}
    if status == "cancelado" and cur not in OPEN_STATES:
        return {"error": f"esse pedido já está {cur}"}
    append_status(pid, status, note, **({"aprovado_pelo_usuario": True, "aprovado_em": time.strftime("%Y-%m-%dT%H:%M:%S")}
                                        if status == "aprovado" else {}))
    return {"ok": True, "id": pid, "status": status, "ja_estava_com_a_sessao": cur == "entregue", "sala_ouvindo": sala_listening()}


def sala_listening():
    try:
        return time.time() - os.path.getmtime(HEARTBEAT) < 90
    except OSError:
        return False
