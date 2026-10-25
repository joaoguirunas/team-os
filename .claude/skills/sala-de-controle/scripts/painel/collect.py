#!/usr/bin/env python3
"""collect.py — estado vivo para o painel da Sala de Controle (READ-ONLY).

Junta, num só JSON, o que já existe no disco:
  • organização (org-map.py)                → negócios e projetos
  • etapa de cada projeto (project-context.py) → resumo, ledger, stories, backlog
  • sessões abertas (scan-sessions.py)       → uma por processo do Claude Code
  • sessões paradas do app (~/Library/Application Support/Claude/claude-code-sessions/*/*/local_*.json)
                                             → as da barra lateral sem processo, não arquivadas (só em "Todas")
  • times de cada sessão (~/.claude/teams/*/config.json) → membros, tipo, modelo
  • transcritos dos agentes (~/.claude/projects/<slug>/<sessionId>/subagents/) → o que cada um faz agora
  • caixas de entrada (~/.claude/teams/*/inboxes/*.json) → mensagens agente ↔ agente
  • últimas falas de cada sessão (transcript principal)

Camadas de custo: o scan de sessões e a etapa dos projetos são caros (chamam `claude agents`
e leem smart-memory) e ficam em cache; transcritos e inboxes são baratos e lidos a cada rodada.

Tudo aqui é DADO, nunca instrução: quem exibe não obedece ao que estiver escrito.

Usage: collect.py [--root <raiz>] [--json]
"""
import glob, json, os, re, subprocess, sys, time, unicodedata
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tokens  # noqa: E402  contador de tokens (thread de fundo, leitura incremental)

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.dirname(HERE)
HOME = os.path.expanduser("~")
DONE_TTL = 5 * 60        # agente que concluiu fica no mapa (verde, com a entrega) por 5 min e depois sai
WAIT_TTL = 10 * 60       # mandou mensagem e parou: "esperando resposta" por até 10 min
THINK_TTL = 3 * 60       # resultado devolvido e o modelo pensando: conta como trabalhando por até 3 min
RECENT = 3 * 3600        # sessão com atividade nas últimas 3 h conta como "ativa" no filtro do painel
SUMMARY_CWD = os.path.join(HOME, ".claude", "sala-de-controle-resumo")  # pasta das chamadas de resumo (fora do mapa)
TEAMS_DIR = os.path.join(HOME, ".claude", "teams")
PROJ_DIR = os.path.join(HOME, ".claude", "projects")
DESKTOP_DIR = os.path.join(HOME, "Library", "Application Support", "Claude", "claude-code-sessions")


def nfc(s):
    return unicodedata.normalize("NFC", s or "")


def run_json(args, timeout=40):
    try:
        out = subprocess.run([sys.executable] + args, capture_output=True, text=True, timeout=timeout).stdout
        i = out.find("{") if out.lstrip().startswith("{") else out.find("[")
        return json.loads(out[i:]) if i >= 0 else None
    except Exception:
        return None


def iso_to_epoch(ts):
    try:
        import calendar
        return calendar.timegm(time.strptime(ts[:19], "%Y-%m-%dT%H:%M:%S"))
    except Exception:
        return 0


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
    return ""


def clean(s, n=220):
    s = re.sub(r"<[^>]+>", " ", s or "")
    s = re.sub(r"\s+", " ", s).strip()
    return s[:n] + ("…" if len(s) > n else "")


def tool_summary(name, inp):
    inp = inp or {}
    if name in ("Read", "Write", "Edit", "NotebookEdit"):
        p = inp.get("file_path") or inp.get("notebook_path") or ""
        return name, os.path.basename(p) or p
    if name == "Bash":
        cmd = inp.get("command", "") or ""
        cmd = re.sub(r'^\s*cd\s+("[^"]*"|\'[^\']*\'|\S+)\s*(&&|;)\s*', "", cmd)   # tira o `cd "..." &&` inicial
        cmd = cmd.split("\n")[0]
        return name, clean(cmd, 80)
    if name in ("Grep", "Glob"):
        return name, inp.get("pattern", "")
    if name == "SendMessage":
        return name, "→ " + str(inp.get("to", "")) + (" · " + clean(inp.get("summary", ""), 60) if inp.get("summary") else "")
    if name in ("WebSearch", "WebFetch"):
        return name, clean(inp.get("query") or inp.get("url") or "", 80)
    if name.startswith("Task"):
        return name, clean(inp.get("subject") or inp.get("description") or "", 60)
    return name, clean(json.dumps(inp, ensure_ascii=False), 80)


# blocos que o harness injeta na fala do usuário: não são pedido de ninguém
NOISE_RE = re.compile(r"<(system-reminder|task-notification|local-command-stdout|local-command-caveat|command-message|"
                      r"tool-use-id|output-file|status|summary)>.*?</\1>", re.S)
TEST_RE = re.compile(r"\b(pytest|jest|vitest|playwright|npm (run )?test|pnpm test|yarn test|test-[\w-]+\.sh|go test|cargo test)\b")


def human_action(name, inp):
    """A ação de uma ferramenta em português simples ("Editando index.html")."""
    inp = inp or {}
    base = lambda p: os.path.basename(p or "") or (p or "")
    if name == "Read":
        return "Lendo " + base(inp.get("file_path"))
    if name == "Write":
        return "Escrevendo " + base(inp.get("file_path"))
    if name in ("Edit", "MultiEdit", "NotebookEdit"):
        return "Editando " + base(inp.get("file_path") or inp.get("notebook_path"))
    if name == "Bash":
        cmd = re.sub(r'^\s*cd\s+("[^"]*"|\'[^\']*\'|\S+)\s*(&&|;)\s*', "", inp.get("command", "") or "").split("\n")[0]
        if inp.get("description"):
            return clean(inp["description"], 70)
        if TEST_RE.search(cmd):
            return "Rodando os testes"
        if re.match(r"\s*git\b", cmd):
            return "Mexendo no git: " + clean(cmd[4:], 40)
        if re.search(r"\b(build|tsc|next build|vite build)\b", cmd):
            return "Rodando o build"
        if re.search(r"\b(npm|pnpm|yarn) (i|install|add)\b", cmd):
            return "Instalando dependências"
        m = re.search(r"([\w.-]+\.(py|sh|js|ts|mjs|sql))\b", cmd)
        if m:
            return "Rodando " + m.group(1)
        # tira `VAR=valor`, `cd …` e `export …` do começo e fica com o programa
        rest = cmd
        for _ in range(6):
            rest2 = re.sub(r'^\s*(export\s+)?\w+=("[^"]*"|\'[^\']*\'|\S*)\s*(;|&&)?\s*', "", rest)
            rest2 = re.sub(r'^\s*cd\s+("[^"]*"|\'[^\']*\'|\S+)\s*(;|&&)\s*', "", rest2)
            if rest2 == rest:
                break
            rest = rest2
        prog = os.path.basename((rest.split() or ["comando"])[0].strip("\"'"))
        if prog == "cd":
            return "Mudando de pasta"
        return "Rodando " + (prog if re.fullmatch(r"[\w.+-]{1,30}", prog) else "comando no terminal")
    if name in ("Grep", "Glob"):
        return "Procurando “" + clean(inp.get("pattern", ""), 40) + "”"
    if name == "WebSearch":
        return "Pesquisando na web: " + clean(inp.get("query", ""), 60)
    if name == "WebFetch":
        return "Lendo a página " + (urlparse_host(inp.get("url", "")) or "web")
    if name == "SendMessage":
        return "Mandando mensagem para " + str(inp.get("to", "?"))
    if name in ("Agent", "Task"):
        return "Chamando o agente " + str(inp.get("subagent_type") or inp.get("description") or "")
    if name.startswith("Task"):
        return "Atualizando as tarefas"
    if name == "SubagentHandback":
        return "Entregou o trabalho"
    if name == "Skill":
        return "Usando a skill " + str(inp.get("skill", ""))
    if name == "TodoWrite":
        return "Organizando a lista de tarefas"
    if name.startswith("mcp__"):
        parts = name.split("__")
        return "Usando " + (parts[1] if len(parts) > 1 else name) + (" · " + parts[2].replace("_", " ") if len(parts) > 2 else "")
    return "Usando " + name


def urlparse_host(u):
    m = re.match(r"https?://([^/]+)", u or "")
    return m.group(1) if m else ""


def tail_lines(path, max_bytes=200_000):
    """Últimas linhas de um jsonl sem ler o arquivo inteiro."""
    try:
        size = os.path.getsize(path)
        with open(path, "rb") as f:
            if size > max_bytes:
                f.seek(size - max_bytes)
                f.readline()
            data = f.read().decode("utf-8", errors="replace")
        return data.splitlines()
    except Exception:
        return []


def read_transcript_state(path, n_turns=6):
    """Resume um transcript: última ação, últimas falas, último timestamp, pendência de tool."""
    turns = deque(maxlen=n_turns)
    steps = deque(maxlen=5)
    last_tool = None
    last_ts = ""
    last_ask = ""
    handback = ""
    pending_tool = False
    last_role = ""
    for line in tail_lines(path):
        try:
            d = json.loads(line)
        except Exception:
            continue
        t = d.get("type")
        if t not in ("user", "assistant"):
            continue
        ts = d.get("timestamp") or last_ts
        last_ts = ts
        msg = d.get("message") or {}
        content = msg.get("content")
        if t == "assistant":
            tool_here = False
            if isinstance(content, list):
                for c in content:
                    if isinstance(c, dict) and c.get("type") == "tool_use":
                        last_tool = tool_summary(c.get("name", ""), c.get("input"))
                        act = human_action(c.get("name", ""), c.get("input"))
                        if c.get("name") == "SubagentHandback":
                            handback = clean(re.sub(r"^\s*(\[handoff\]\s*|STATUS:\s*)*(conclu[ií]do\.?)?\s*", "", str((c.get("input") or {}).get("message", ""))), 200)
                        if not steps or steps[-1]["text"] != act:
                            steps.append({"text": act, "ts": ts})
                        tool_here = True
            txt = clean(text_of(content))
            if txt:
                turns.append({"who": "agente", "text": txt, "ts": ts})
            pending_tool = tool_here
            last_role = "assistant"
        else:
            is_result = isinstance(content, list) and any(isinstance(c, dict) and c.get("type") == "tool_result" for c in content)
            if is_result:
                pending_tool = False
            else:
                raw = NOISE_RE.sub(" ", text_of(content))
                txt = clean(raw)
                if txt:
                    turns.append({"who": "usuário", "text": txt, "ts": ts})
                    if not d.get("isMeta") and not txt.startswith(("Caveat:", "[Request interrupted")):
                        last_ask = clean(raw, 180)
            last_role = "user"
    doing = steps[-1]["text"] if (steps and pending_tool) else ""
    if not doing and turns and turns[-1]["who"] == "agente":
        doing = "Respondeu: " + clean(turns[-1]["text"], 110)
    return {"last_tool": last_tool, "turns": list(turns), "last_ts": last_ts,
            "last_epoch": iso_to_epoch(last_ts), "pending_tool": pending_tool, "last_role": last_role,
            "steps": list(steps), "last_ask": last_ask, "handback": handback, "doing": doing or (steps[-1]["text"] if steps else "")}


def first_prompt(path):
    """O pedido que abriu o transcript de um agente (a missão dele)."""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for _ in range(15):
                line = fh.readline()
                if not line:
                    break
                d = json.loads(line)
                if d.get("type") == "user":
                    t = clean(text_of((d.get("message") or {}).get("content")), 180)
                    if t:
                        return t
    except Exception:
        pass
    return ""


# ---------- camada cara (cache) ----------
_cache = {"org": (0, None), "ctx": {}, "scan": (0, None)}


def org(root, ttl=20):
    t, v = _cache["org"]
    if v is None or time.time() - t > ttl:
        v = run_json([os.path.join(SCRIPTS, "org-map.py"), root, "--json"]) or {"nodes": []}
        _cache["org"] = (time.time(), v)
    return v


def context(path, ttl=30):
    t, v = _cache["ctx"].get(path, (0, None))
    if v is None or time.time() - t > ttl:
        v = run_json([os.path.join(SCRIPTS, "project-context.py"), path, "--json"]) or {}
        _cache["ctx"][path] = (time.time(), v)
    return v


def scan(ttl=3):
    t, v = _cache["scan"]
    if v is None or time.time() - t > ttl:
        v = run_json([os.path.join(SCRIPTS, "scan-sessions.py"), "--json"]) or {"sessions": []}
        _cache["scan"] = (time.time(), v)
    return v


def desktop_sessions(live_ids, live_names):
    """Sessões da barra lateral do app (local_<uuid>.json) que não têm processo vivo e não estão arquivadas.
    Viram linhas no formato do scan-sessions.py com STATUS=parada. Pula a que já aparece pelo processo
    (mesmo cliSessionId, um id anterior dela, ou mesmo título + pasta)."""
    rows = []
    for f in glob.glob(os.path.join(DESKTOP_DIR, "*", "*", "local_*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        if d.get("isArchived"):
            continue
        cli = d.get("cliSessionId") or ""
        ids = {cli, *(d.get("priorCliSessionIds") or [])} - {""}
        cwd = nfc(d.get("cwd") or "")
        title = nfc(d.get("title") or "")
        if ids & live_ids or (title, cwd) in live_names:
            continue
        last = (d.get("lastActivityAt") or d.get("createdAt") or 0) / 1000
        rows.append({"NAME": title or os.path.basename(cwd), "SESSION_ID": cli or d.get("sessionId", ""),
                     "SHORT_ID": (d.get("sessionId") or "")[6:14], "CWD": cwd,
                     "FOLDER": os.path.basename(cwd.rstrip("/")), "KIND": "desktop", "STATUS": "parada",
                     "STATE": "", "UPDATED": time.strftime("%Y-%m-%d %H:%M", time.localtime(last)) if last else "",
                     "IS_SELF": "0", "TRANSCRIPT": "", "STOPPED": "1", "LAST_EPOCH": last})
    return rows


# ---------- camada barata ----------
def teams_by_lead():
    out = {}
    for cfg in glob.glob(os.path.join(TEAMS_DIR, "*", "config.json")):
        try:
            c = json.load(open(cfg, encoding="utf-8"))
        except Exception:
            continue
        lead = c.get("leadSessionId") or ""
        if lead:
            out[lead] = (os.path.basename(os.path.dirname(cfg)), c)
    return out


def inbox_messages(team_name, since_epoch):
    msgs = []
    for f in glob.glob(os.path.join(TEAMS_DIR, team_name, "inboxes", "*.json")):
        to = os.path.basename(f)[:-5]
        try:
            arr = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for m in arr[-40:] if isinstance(arr, list) else []:
            ts = m.get("timestamp") or ""
            ep = iso_to_epoch(ts) if isinstance(ts, str) else (ts / 1000 if ts > 1e11 else ts)
            if ep < since_epoch:
                continue
            text = m.get("text") or ""
            subject = ""
            kind = m.get("type") or "message"
            if isinstance(text, str) and text.startswith("{"):
                try:
                    j = json.loads(text)
                    kind = j.get("type") or kind
                    subject = j.get("subject") or j.get("summary") or ""
                    text = j.get("description") or j.get("message") or text
                except Exception:
                    pass
            msgs.append({"from": m.get("from", "?"), "to": to, "kind": kind, "subject": clean(subject, 90),
                         "text": clean(text, 160), "epoch": ep, "read": bool(m.get("read"))})
    msgs.sort(key=lambda m: m["epoch"])
    return msgs


def agents_of(session_dir, members):
    """Agentes de uma sessão: membros do time + subagents com transcript."""
    agents = {}
    for m in members:
        if m.get("agentType") == "team-lead":
            continue
        agents[m["name"]] = {"name": m["name"], "type": m.get("agentType") or "", "model": m.get("model") or "",
                             "color": m.get("color") or "", "kind": "teammate", "state": "idle",
                             "now": "", "tool": None, "turns": [], "last_epoch": 0}
    sub = os.path.join(session_dir, "subagents")
    for meta_path in glob.glob(os.path.join(sub, "*.meta.json")):
        try:
            meta = json.load(open(meta_path, encoding="utf-8"))
        except Exception:
            continue
        name = meta.get("name") or meta.get("agentType") or os.path.basename(meta_path)
        jsonl = meta_path[:-len(".meta.json")] + ".jsonl"
        st = read_transcript_state(jsonl) if os.path.isfile(jsonl) else None
        a = agents.get(name) or {"name": name, "type": meta.get("customAgentType") or meta.get("agentType") or "",
                                 "model": meta.get("model") or "", "color": meta.get("color") or "",
                                 "kind": "teammate" if meta.get("taskKind") == "in_process_teammate" else "subagent",
                                 "state": "idle", "now": "", "tool": None, "turns": [], "last_epoch": 0}
        if not a.get("type"):
            a["type"] = meta.get("customAgentType") or meta.get("agentType") or ""
        a["description"] = clean(meta.get("description", ""), 120)
        if st:
            # um agente pode ter vários transcritos (re-spawn): fica o mais recente
            if st["last_epoch"] >= a.get("last_epoch", 0):
                a.update({"tool": st["last_tool"], "turns": st["turns"], "last_epoch": st["last_epoch"],
                          "pending_tool": st["pending_tool"], "last_role": st["last_role"],
                          "steps": st["steps"], "doing": st["doing"], "src": jsonl, "handback": st["handback"],
                          "goal": a["description"] or first_prompt(jsonl)})
        agents[name] = a
    now = time.time()
    for a in agents.values():
        age = now - a.get("last_epoch", 0) if a.get("last_epoch") else 1e9
        last_text = (a["turns"][-1]["text"] if a["turns"] else "")
        # ferramenta rodando, ou resultado devolvido e o modelo pensando no próximo passo = trabalhando
        # (sem isso o agente piscava entre "concluiu" e "voltou a trabalhar" a cada pausa para pensar)
        delivered = bool(a.get("tool") and a["tool"][0] == "SubagentHandback" and not a.get("pending_tool"))
        if delivered:
            a["state"] = "done" if age < DONE_TTL else "idle"   # entregou: concluiu na hora
            a["doing"] = "Concluiu: " + (a.get("handback") or "entregou o trabalho")
        elif a.get("pending_tool") or age < 20 or (a.get("last_role") == "user" and age < THINK_TTL):
            a["state"] = "active"
        elif age < 180 and a.get("last_role") == "assistant" and re.search(r"\?\s*$|DECIS[ÃA]O|aprova|autoriza|confirm", last_text, re.I):
            a["state"] = "approval"
        elif age < WAIT_TTL and a.get("tool") and a["tool"][0] == "SendMessage":
            a["state"] = "waiting"
            a["doing"] = "Esperando resposta de " + (a["tool"][1] or "").replace("→", "").split("·")[0].strip()
        elif age < DONE_TTL:
            a["state"] = "done"
            a["doing"] = "Concluiu: " + (a.get("handback") or clean(last_text, 160)) if (a.get("handback") or last_text) else "Concluiu a tarefa"
        else:
            a["state"] = "idle"
        if a.get("tool"):
            a["now"] = f"{a['tool'][0]} · {a['tool'][1]}" if a["tool"][1] else a["tool"][0]
        elif last_text:
            a["now"] = last_text
        a["age"] = int(age) if age < 1e9 else None
    # quem está operando, esperando o usuário, esperando resposta ou concluiu na última hora
    fresh = [a for a in agents.values() if a["state"] != "idle"]
    return sorted(fresh, key=lambda x: x["name"])


def stage_line(ctx):
    """Uma linha de etapa em linguagem simples a partir do contexto do projeto."""
    if not ctx:
        return ""
    for key in ("LEDGER", "STORY_ACTIVE", "STORY_IN_REVIEW", "INBOX", "DIGEST"):
        v = ctx.get(key)
        if v:
            first = v[0] if isinstance(v, list) else str(v)
            return clean(re.sub(r"\[\[|\]\]", "", str(first)), 160)
    return clean(ctx.get("SUMMARY", ""), 160)


def collect(root):
    t0 = time.time()
    o = org(root)
    nodes = [n for n in o.get("nodes", []) if n.get("is_project")]
    sc = scan()
    sessions = sc.get("sessions", [])
    sessions = sessions + desktop_sessions({s.get("SESSION_ID", "") for s in sessions} - {""},
                                           {(nfc(s.get("NAME", "")), nfc(s.get("CWD", ""))) for s in sessions})
    self_name = sc.get("self", "")
    teams = teams_by_lead()
    now = time.time()

    projects = {}
    for n in nodes:
        p = nfc(n["path"])
        ctx = context(n["path"]) if n.get("smart_memory") else {}
        nm = nfc(n["name"]) + (" (casa da Sala)" if n.get("kind") == "ct" else "")
        projects[p] = {"path": p, "name": nm, "business": nfc(n.get("business") or ""),
                       "kind": n.get("kind"), "squads": n.get("squads", []), "agents_installed": n.get("agents", 0),
                       "smart_memory": bool(n.get("smart_memory")), "stage": stage_line(ctx),
                       "summary": clean(ctx.get("SUMMARY", ""), 200) if ctx else "",
                       "backlog_open": ctx.get("BACKLOG_OPEN", "") if ctx else "",
                       "last_touch": ctx.get("LAST_TOUCH", "") if ctx else "", "sessions": []}

    events = []
    edges = []
    out_sessions = []
    for s in sessions:
        cwd = nfc(s.get("CWD", ""))
        sid = s.get("SESSION_ID", "")
        tr = s.get("TRANSCRIPT", "")
        # registro pode apontar a pasta errada (app desktop): confia no transcript
        if (not tr or not os.path.isfile(tr)) and sid:
            found = glob.glob(os.path.join(PROJ_DIR, "*", sid + ".jsonl"))
            tr = found[0] if found else tr
        if tr and os.path.isfile(tr):
            try:
                with open(tr, encoding="utf-8", errors="replace") as fh:
                    for _ in range(40):
                        line = fh.readline()
                        if not line:
                            break
                        try:
                            c = json.loads(line).get("cwd")
                        except Exception:
                            c = None
                        if c:
                            if nfc(c) != cwd:
                                cwd = nfc(c)
                            break
            except Exception:
                pass
        sdir = tr[:-6] if tr.endswith(".jsonl") else ""
        team_name, cfg = teams.get(sid, (None, None))
        members = (cfg or {}).get("members", [])
        agents = agents_of(sdir, members) if sdir else []
        if SUMMARY_CWD and nfc(cwd).startswith(SUMMARY_CWD):
            continue  # chamada do resumo por IA (serve.py) — não é sessão de trabalho
        stopped = s.get("STOPPED") == "1"
        main = read_transcript_state(tr, 5) if tr and os.path.isfile(tr) else {"turns": [], "last_tool": None, "last_epoch": 0}
        if stopped and not main.get("last_epoch"):
            main["last_epoch"] = s.get("LAST_EPOCH") or 0
        # a Sala mora no CT: reconhece pelo nome da sessão ("Sala de Controle" ou
        # "0 | Centro de Treinamento | Sala de Controle"); pastas de Sala antigas também contam
        is_sala = not stopped and (s.get("IS_SELF") == "1" or "sala de controle" in (s.get("NAME", "") + " " + cwd).lower())
        status = s.get("STATUS") or s.get("STATE") or ""
        sess = {"id": sid, "short": s.get("SHORT_ID") or sid[:8], "name": nfc(s.get("NAME", "")), "cwd": cwd,
                "folder": nfc(s.get("FOLDER", "")), "kind": s.get("KIND"), "status": status,
                "state": s.get("STATE", ""), "updated": s.get("UPDATED", ""), "is_self": s.get("IS_SELF") == "1",
                "is_sala": is_sala, "stopped": stopped, "team": team_name, "agents": agents,
                "turns": main.get("turns", []), "tool": main.get("last_tool"), "last_epoch": main.get("last_epoch", 0),
                "tokens": tokens.summary(tr) if tr and os.path.isfile(tr) and not stopped else None,
                "doing": main.get("doing", ""), "goal": main.get("last_ask", ""), "steps": main.get("steps", []),
                "age": int(now - main["last_epoch"]) if main.get("last_epoch") else None, "src": tr,
                "project": cwd if cwd in projects else ""}
        # projeto pai por prefixo (sessão aberta numa subpasta)
        if not sess["project"]:
            for p in projects:
                if cwd.startswith(p + "/"):
                    sess["project"] = p
                    break
        # sessão numa pasta fora da raiz (ex.: outro negócio no Drive): vira projeto "fora da raiz"
        # para os agentes dela aparecerem no mapa em vez de sumirem
        if not sess["project"] and cwd and not is_sala and os.path.isdir(cwd):
            sm = os.path.isfile(os.path.join(cwd, "docs", "smart-memory", "INDEX.md"))
            projects[cwd] = {"path": cwd, "name": os.path.basename(cwd), "business": os.path.basename(os.path.dirname(cwd)),
                             "kind": "external", "squads": [], "agents_installed": 0, "smart_memory": sm,
                             "stage": "fora da raiz do Command Center", "summary": "", "backlog_open": "",
                             "last_touch": "", "sessions": []}
            sess["project"] = cwd
        if team_name:
            msgs = inbox_messages(team_name, now - 3600)
            for m in msgs:
                events.append({"epoch": m["epoch"], "session": sid, "from": m["from"], "to": m["to"],
                               "kind": m["kind"], "title": m["subject"] or m["text"][:90], "project": sess["project"] or cwd})
                if now - m["epoch"] < 90:
                    edges.append({"session": sid, "from": m["from"], "to": m["to"], "epoch": m["epoch"], "kind": m["kind"]})
        # parada (sem processo) só entra em "Todas": "Ativas" segue igual
        sess["recent"] = not stopped and bool(status == "busy" or sess["state"] == "blocked" or agents
                              or (sess["age"] is not None and sess["age"] < RECENT) or is_sala)
        if sess["project"]:
            projects[sess["project"]]["sessions"].append(sid)
        out_sessions.append(sess)

    events.sort(key=lambda e: e["epoch"], reverse=True)
    counts = {"sessions": len([s for s in out_sessions if not s["is_self"]]),
              "recent": len([s for s in out_sessions if s["recent"] and not s["is_self"] and not s["is_sala"]]),
              "agents": sum(len(s["agents"]) for s in out_sessions),
              "active": sum(1 for s in out_sessions for a in s["agents"] if a["state"] == "active"),
              "done": sum(1 for s in out_sessions for a in s["agents"] if a["state"] == "done"),
              "approval": sum(1 for s in out_sessions for a in s["agents"] if a["state"] == "approval")
              + sum(1 for s in out_sessions if s.get("state") == "blocked"),
              "tokens": sum((s.get("tokens") or {}).get("total", 0) for s in out_sessions),
              "tokens_rate": sum((s.get("tokens") or {}).get("rate", 0) for s in out_sessions)}
    home = "CT" if os.path.isdir(os.path.join(os.getcwd(), ".claude", "skills", "team-os-creator")) else ""
    return {"root": nfc(root), "self": nfc(self_name), "home": home, "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "took_ms": int((time.time() - t0) * 1000), "projects": list(projects.values()),
            "sessions": out_sessions, "events": events[:60], "edges": edges, "counts": counts}


def default_root():
    cwd = os.getcwd()
    # a Sala mora no CT (<raiz>/0 | Centro de Treinamento): a raiz é a pasta-mãe do CT
    parent = os.path.dirname(cwd)
    return parent if os.path.isdir(parent) else cwd


if __name__ == "__main__":
    args = sys.argv[1:]
    root = args[args.index("--root") + 1] if "--root" in args else default_root()
    st = collect(root)
    if "--json" in args:
        print(json.dumps(st, ensure_ascii=False, indent=1))
    else:
        print(f"root={st['root']} sessões={st['counts']['sessions']} agentes={st['counts']['agents']} ativos={st['counts']['active']} ({st['took_ms']} ms)")
        for s in st["sessions"]:
            print(f"- {s['name']} [{s['status']}] {len(s['agents'])} agentes · {s['folder']}")
            for a in s["agents"]:
                print(f"    · {a['name']} ({a['type']}) {a['state']} — {a['now'][:80]}")
