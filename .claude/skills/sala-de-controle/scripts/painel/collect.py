#!/usr/bin/env python3
"""collect.py — estado vivo para o painel da Sala de Controle (READ-ONLY).

Junta, num só JSON, o que já existe no disco:
  • organização (org-map.py)                → negócios e projetos
  • etapa de cada projeto (project-context.py) → resumo, ledger, stories, backlog
  • sessões abertas (scan-sessions.py)       → uma por processo do Claude Code
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

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.dirname(HERE)
HOME = os.path.expanduser("~")
TEAMS_DIR = os.path.join(HOME, ".claude", "teams")
PROJ_DIR = os.path.join(HOME, ".claude", "projects")


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
    last_tool = None
    last_ts = ""
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
                txt = clean(text_of(content))
                if txt:
                    turns.append({"who": "usuário", "text": txt, "ts": ts})
            last_role = "user"
    return {"last_tool": last_tool, "turns": list(turns), "last_ts": last_ts,
            "last_epoch": iso_to_epoch(last_ts), "pending_tool": pending_tool, "last_role": last_role}


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
                          "pending_tool": st["pending_tool"], "last_role": st["last_role"]})
        agents[name] = a
    now = time.time()
    for a in agents.values():
        age = now - a.get("last_epoch", 0) if a.get("last_epoch") else 1e9
        last_text = (a["turns"][-1]["text"] if a["turns"] else "")
        if a.get("pending_tool") or age < 20:
            a["state"] = "active"
        elif age < 180 and a.get("last_role") == "assistant" and re.search(r"\?\s*$|DECIS[ÃA]O|aprova|autoriza|confirm", last_text, re.I):
            a["state"] = "approval"
        elif age < 600:
            a["state"] = "waiting"
        else:
            a["state"] = "idle"
        if a.get("tool"):
            a["now"] = f"{a['tool'][0]} · {a['tool'][1]}" if a["tool"][1] else a["tool"][0]
        elif last_text:
            a["now"] = last_text
        a["age"] = int(age) if age < 1e9 else None
    return sorted(agents.values(), key=lambda x: x["name"])


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
    self_name = sc.get("self", "")
    teams = teams_by_lead()
    now = time.time()

    projects = {}
    for n in nodes:
        p = nfc(n["path"])
        ctx = context(n["path"]) if n.get("smart_memory") else {}
        projects[p] = {"path": p, "name": nfc(n["name"]), "business": nfc(n.get("business") or ""),
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
        sdir = tr[:-6] if tr.endswith(".jsonl") else ""
        team_name, cfg = teams.get(sid, (None, None))
        members = (cfg or {}).get("members", [])
        agents = agents_of(sdir, members) if sdir else []
        main = read_transcript_state(tr, 5) if tr and os.path.isfile(tr) else {"turns": [], "last_tool": None, "last_epoch": 0}
        is_sala = "sala de controle" in (s.get("NAME", "") + " " + cwd).lower()
        status = s.get("STATUS") or s.get("STATE") or ""
        sess = {"id": sid, "short": s.get("SHORT_ID") or sid[:8], "name": nfc(s.get("NAME", "")), "cwd": cwd,
                "folder": nfc(s.get("FOLDER", "")), "kind": s.get("KIND"), "status": status,
                "state": s.get("STATE", ""), "updated": s.get("UPDATED", ""), "is_self": s.get("IS_SELF") == "1",
                "is_sala": is_sala, "team": team_name, "agents": agents,
                "turns": main.get("turns", []), "tool": main.get("last_tool"), "last_epoch": main.get("last_epoch", 0),
                "project": cwd if cwd in projects else ""}
        # projeto pai por prefixo (sessão aberta numa subpasta)
        if not sess["project"]:
            for p in projects:
                if cwd.startswith(p + "/"):
                    sess["project"] = p
                    break
        if team_name:
            msgs = inbox_messages(team_name, now - 3600)
            for m in msgs:
                events.append({"epoch": m["epoch"], "session": sid, "from": m["from"], "to": m["to"],
                               "kind": m["kind"], "title": m["subject"] or m["text"][:90], "project": sess["project"] or cwd})
                if now - m["epoch"] < 90:
                    edges.append({"session": sid, "from": m["from"], "to": m["to"], "epoch": m["epoch"], "kind": m["kind"]})
        if sess["project"]:
            projects[sess["project"]]["sessions"].append(sid)
        out_sessions.append(sess)

    events.sort(key=lambda e: e["epoch"], reverse=True)
    counts = {"sessions": len([s for s in out_sessions if not s["is_self"]]),
              "agents": sum(len(s["agents"]) for s in out_sessions),
              "active": sum(1 for s in out_sessions for a in s["agents"] if a["state"] == "active"),
              "approval": sum(1 for s in out_sessions for a in s["agents"] if a["state"] == "approval")
              + sum(1 for s in out_sessions if s.get("state") == "blocked")}
    return {"root": nfc(root), "self": nfc(self_name), "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "took_ms": int((time.time() - t0) * 1000), "projects": list(projects.values()),
            "sessions": out_sessions, "events": events[:60], "edges": edges, "counts": counts}


def default_root():
    cwd = os.getcwd()
    # a Sala mora em <raiz>/1 | Sala de Controle; o CT em <raiz>/0 | Centro de Treinamento
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
