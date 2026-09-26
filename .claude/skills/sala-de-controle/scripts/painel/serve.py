#!/usr/bin/env python3
"""serve.py — servidor local do painel da Sala de Controle (READ-ONLY sobre os projetos).

Rotas:
  GET /                → a página (index.html)
  GET /events          → SSE: estado completo a cada ~1 s + eventos novos (diff entre rodadas)
  GET /api/state       → estado atual (JSON)
  GET /api/vault?p=    → árvore da smart-memory de um projeto (p = caminho do projeto)
  GET /api/note?p=&n=  → conteúdo de uma nota (n = caminho relativo dentro de docs/smart-memory)

Só lê. Nunca escreve em projeto nenhum. Só aceita caminhos de projetos conhecidos pelo org-map
e só dentro de docs/smart-memory (sem `..`, sem symlink para fora).

Usage: serve.py [--root <raiz>] [--port 8787] [--bg | --stop | --status]
  --bg    sobe em segundo plano (pid em ~/.claude/sala-de-controle-painel.pid) e imprime a URL
  --stop  derruba o servidor de segundo plano
"""
import json, os, re, signal, socket, subprocess, sys, threading, time, unicodedata
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import collect  # noqa: E402

PID_FILE = os.path.join(os.path.expanduser("~"), ".claude", "sala-de-controle-painel.pid")
LOG_FILE = os.path.join(os.path.expanduser("~"), ".claude", "sala-de-controle-painel.log")
STATE = {"data": None, "events": [], "seq": 0, "prev": {}}
LOCK = threading.Lock()


def nfc(s):
    return unicodedata.normalize("NFC", s or "")


def diff_events(prev, cur):
    """Eventos novos: mudança de ação/estado de agente, mensagem nova, despacho da Sala."""
    ev = []
    now = time.time()
    seen = {}
    for s in cur["sessions"]:
        for a in s["agents"]:
            key = s["id"] + "/" + a["name"]
            seen[key] = a
            p = prev.get(key)
            if p is None:
                if a["state"] == "active":
                    ev.append({"kind": "start", "session": s["id"], "who": a["name"], "what": "começou", "where": s["name"], "epoch": now})
                continue
            if a["now"] != p["now"] and a["now"]:
                kind = "msg" if a["now"].startswith("SendMessage") else ("done" if a["now"].startswith("SubagentHandback") else "tool")
                what = a["now"]
                if kind == "msg":
                    what = "mandou mensagem " + a["now"].split("·")[0].replace("SendMessage", "").strip()
                    to = a["now"].replace("SendMessage · → ", "").split(" · ")[0].strip()
                    ev.append({"kind": "edge", "session": s["id"], "from": a["name"], "to": to, "epoch": now})
                elif kind == "done":
                    what = "entregou"
                ev.append({"kind": kind, "session": s["id"], "who": a["name"], "what": what, "where": s["name"], "epoch": now})
            elif a["state"] != p["state"]:
                if a["state"] == "approval":
                    ev.append({"kind": "approval", "session": s["id"], "who": a["name"], "what": "precisa de você", "where": s["name"], "epoch": now})
                elif a["state"] == "active":
                    ev.append({"kind": "start", "session": s["id"], "who": a["name"], "what": "voltou a trabalhar", "where": s["name"], "epoch": now})
        # a própria sessão (líder) — despacho da Sala ou fala nova
        key = s["id"] + "/__main__"
        cur_now = (s.get("tool") or ["", ""])
        cur_sig = json.dumps(cur_now) + "|" + (s["turns"][-1]["text"] if s["turns"] else "")
        seen[key] = {"now": cur_sig, "state": s["status"]}
        p = prev.get(key)
        if p is not None and p["now"] != cur_sig:
            if cur_now and cur_now[0] == "SendMessage":
                to = (cur_now[1] or "").replace("→", "").split("·")[0].strip()
                ev.append({"kind": "edge", "session": s["id"], "from": "__main__", "to": to, "epoch": now, "hub": s["is_sala"]})
                ev.append({"kind": "dispatch" if s["is_sala"] else "msg", "session": s["id"], "who": s["name"],
                           "what": ("despachou → " if s["is_sala"] else "mandou → ") + to, "where": (cur_now[1] or "").split("·")[-1].strip(), "epoch": now})
            elif s["turns"] and s["turns"][-1]["who"] == "usuário":
                ev.append({"kind": "user", "session": s["id"], "who": s["name"], "what": "recebeu pedido", "where": s["turns"][-1]["text"][:90], "epoch": now})
    return ev, seen


def refresh_loop(root):
    while True:
        try:
            data = collect.collect(root)
            with LOCK:
                ev, seen = diff_events(STATE["prev"], data)
                STATE["prev"] = {k: {"now": v.get("now", ""), "state": v.get("state", "")} for k, v in seen.items()}
                STATE["data"] = data
                for e in ev:
                    STATE["seq"] += 1
                    e["seq"] = STATE["seq"]
                    STATE["events"].append(e)
                STATE["events"] = STATE["events"][-200:]
        except Exception as e:  # nunca derruba o servidor
            sys.stderr.write(f"collect error: {e}\n")
        time.sleep(1.0)


# ---------- smart-memory (leitura segura) ----------
def known_projects():
    d = STATE["data"] or {}
    return {p["path"]: p for p in d.get("projects", [])}


def vault_root(p):
    p = nfc(p)
    if p not in known_projects():
        return None
    base = os.path.realpath(os.path.join(p, "docs", "smart-memory"))
    return base if os.path.isdir(base) else None


FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.S)
WL_RE = re.compile(r"\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]")


def parse_fm(text):
    m = FM_RE.match(text)
    fm = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line and not line.startswith(" "):
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip().strip('"')
        text = text[m.end():]
    return fm, text


def vault_tree(base):
    files = []
    for dp, dn, fn in os.walk(base):
        dn[:] = sorted(d for d in dn if not d.startswith(".") and d != "_archive")
        for f in sorted(fn):
            if not f.endswith(".md"):
                continue
            full = os.path.join(dp, f)
            if not os.path.realpath(full).startswith(base):
                continue
            rel = os.path.relpath(full, base)
            try:
                head = open(full, encoding="utf-8", errors="replace").read(6000)
            except Exception:
                head = ""
            fm, body = parse_fm(head)
            title = fm.get("title") or next((l[2:].strip() for l in body.splitlines() if l.startswith("# ")), os.path.splitext(f)[0])
            links = sorted(set(l.strip() for l in WL_RE.findall(body)))
            files.append({"path": rel, "dir": os.path.dirname(rel), "name": os.path.splitext(f)[0], "title": title[:90],
                          "kind": fm.get("kind", ""), "status": fm.get("status", ""), "updated": fm.get("updated", "") or time.strftime("%Y-%m-%d %H:%M", time.localtime(os.path.getmtime(full))),
                          "links": links, "size": os.path.getsize(full)})
    return files


def resolve_link(base, files, target):
    t = target.strip().replace("\\", "")
    cands = [f for f in files if f["path"] == t or f["path"] == t + ".md" or f["name"] == t or f["name"] == os.path.basename(t) or f["path"].endswith("/" + t + ".md")]
    return cands[0]["path"] if cands else None


# ---------- HTTP ----------
class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype="application/json; charset=utf-8"):
        if not isinstance(body, bytes):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8") if ctype.startswith("application/json") else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        if u.path == "/":
            return self._send(200, open(os.path.join(HERE, "index.html"), encoding="utf-8").read(), "text/html; charset=utf-8")
        if u.path == "/api/state":
            with LOCK:
                return self._send(200, STATE["data"] or {"projects": [], "sessions": [], "counts": {}})
        if u.path == "/api/vault":
            base = vault_root(q.get("p", ""))
            if not base:
                return self._send(404, {"error": "projeto desconhecido ou sem smart-memory"})
            files = vault_tree(base)
            for f in files:
                f["resolved"] = [r for r in (resolve_link(base, files, l) for l in f["links"]) if r]
            return self._send(200, {"project": q.get("p"), "files": files})
        if u.path == "/api/note":
            base = vault_root(q.get("p", ""))
            n = q.get("n", "")
            if not base or ".." in n.split("/"):
                return self._send(404, {"error": "nota inválida"})
            full = os.path.realpath(os.path.join(base, n))
            if not full.startswith(base) or not os.path.isfile(full):
                return self._send(404, {"error": "nota não encontrada"})
            text = open(full, encoding="utf-8", errors="replace").read()
            fm, body = parse_fm(text)
            files = vault_tree(base)
            links = {l: resolve_link(base, files, l) for l in set(WL_RE.findall(body))}
            back = [f["path"] for f in files if n in [resolve_link(base, files, l) for l in f["links"]]]
            return self._send(200, {"path": n, "frontmatter": fm, "body": body, "links": links, "backlinks": back})
        if u.path == "/events":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Connection", "keep-alive")
            self.end_headers()
            last_seq = int(q.get("since", STATE["seq"]))
            try:
                while True:
                    with LOCK:
                        data = STATE["data"]
                        new = [e for e in STATE["events"] if e["seq"] > last_seq]
                        if new:
                            last_seq = new[-1]["seq"]
                    if data:
                        self.wfile.write(("event: state\ndata: " + json.dumps({"state": data, "events": new}, ensure_ascii=False) + "\n\n").encode("utf-8"))
                        self.wfile.flush()
                    time.sleep(1.0)
            except (BrokenPipeError, ConnectionResetError, OSError):
                return
        return self._send(404, {"error": "rota desconhecida"})


def default_root():
    parent = os.path.dirname(os.getcwd())
    return parent if os.path.isdir(parent) else os.getcwd()


def port_open(port):
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def main():
    a = sys.argv[1:]
    root = a[a.index("--root") + 1] if "--root" in a else default_root()
    port = int(a[a.index("--port") + 1]) if "--port" in a else 8787
    if "--stop" in a:
        try:
            os.kill(int(open(PID_FILE).read().strip()), signal.SIGTERM)
            os.remove(PID_FILE)
            print("STOPPED=1")
        except Exception as e:
            print(f"STOPPED=0 ({e})")
        return
    if "--status" in a:
        print(f"RUNNING={1 if port_open(port) else 0} URL=http://127.0.0.1:{port}")
        return
    if "--bg" in a:
        if port_open(port):
            print(f"ALREADY=1 URL=http://127.0.0.1:{port}")
            return
        cmd = [sys.executable, os.path.abspath(__file__), "--root", root, "--port", str(port)]
        log = open(LOG_FILE, "ab")
        p = subprocess.Popen(cmd, stdout=log, stderr=log, stdin=subprocess.DEVNULL, start_new_session=True, cwd=os.getcwd())
        open(PID_FILE, "w").write(str(p.pid))
        for _ in range(40):
            if port_open(port):
                break
            time.sleep(0.25)
        print(f"STARTED=1 PID={p.pid} URL=http://127.0.0.1:{port} ROOT={root}")
        return
    threading.Thread(target=refresh_loop, args=(root,), daemon=True).start()
    srv = ThreadingHTTPServer(("127.0.0.1", port), H)
    srv.daemon_threads = True
    print(f"painel · http://127.0.0.1:{port} · raiz {root}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
