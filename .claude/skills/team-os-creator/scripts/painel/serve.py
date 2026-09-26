#!/usr/bin/env python3
"""serve.py — servidor local do mapa do Centro de Treinamento (`/team-os-creator *painel`). READ-ONLY.

Rotas:
  GET /                 → a página (index.html)
  GET /api/state        → squads, agentes, skills, projetos (cache de 10 s; relê os arquivos do CT)
  GET /api/file?k=&n=   → conteúdo completo de um agente (k=agent) ou skill (k=skill), só dentro do CT

Usage: serve.py [--port 8788] [--bg | --stop | --status]
"""
import json, os, signal, socket, subprocess, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import collect_ct  # noqa: E402

PID_FILE = os.path.join(os.path.expanduser("~"), ".claude", "team-os-creator-painel.pid")
LOG_FILE = os.path.join(os.path.expanduser("~"), ".claude", "team-os-creator-painel.log")


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
        try:
            if u.path == "/":
                return self._send(200, open(os.path.join(HERE, "index.html"), encoding="utf-8").read(), "text/html; charset=utf-8")
            if u.path == "/api/state":
                return self._send(200, collect_ct.collect())
            if u.path == "/api/file":
                d = collect_ct.read_file(q.get("k", ""), q.get("n", ""))
                return self._send(200, d) if d else self._send(404, {"error": "arquivo não encontrado"})
        except Exception as e:
            return self._send(500, {"error": str(e)})
        return self._send(404, {"error": "rota desconhecida"})


def port_open(port):
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def main():
    a = sys.argv[1:]
    port = int(a[a.index("--port") + 1]) if "--port" in a else 8788
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
        log = open(LOG_FILE, "ab")
        p = subprocess.Popen([sys.executable, os.path.abspath(__file__), "--port", str(port)], stdout=log, stderr=log,
                             stdin=subprocess.DEVNULL, start_new_session=True, cwd=collect_ct.CT)
        open(PID_FILE, "w").write(str(p.pid))
        for _ in range(40):
            if port_open(port):
                break
            time.sleep(0.25)
        print(f"STARTED=1 PID={p.pid} URL=http://127.0.0.1:{port} CT={collect_ct.CT}")
        return
    srv = ThreadingHTTPServer(("127.0.0.1", port), H)
    srv.daemon_threads = True
    print(f"mapa do CT · http://127.0.0.1:{port} · {collect_ct.CT}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
