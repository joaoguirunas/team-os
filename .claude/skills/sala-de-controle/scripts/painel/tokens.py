#!/usr/bin/env python3
"""tokens.py — contador de tokens por sessão e por agente (READ-ONLY, incremental).

Lê os transcripts (.jsonl) que o Claude Code já grava e soma o `usage` de cada resposta:
  • novos   = input_tokens + cache_creation_input_tokens + output_tokens  (o que foi de fato escrito/enviado)
  • relidos = cache_read_input_tokens                                     (histórico relido a cada turno — o grosso do consumo)
  • contexto = tamanho do histórico na última resposta (é ele que multiplica o gasto de cada turno)

Detalhes que importam:
  • o transcript repete o mesmo `usage` em várias linhas da mesma resposta (uma por bloco) → deduplica por `message.id`;
  • leitura incremental por offset: cada rodada lê só o que cresceu; arquivo que encolheu é relido do zero;
  • uma thread de fundo faz a leitura — a primeira passada em transcripts grandes não trava o painel;
  • nada aqui gasta token: é leitura de arquivo local.

API: register(path) → pede para acompanhar um transcript; summary(main_jsonl) → dict pronto para o painel.
"""
import calendar, glob, json, os, threading, time
from collections import deque

RATE_WINDOW = 300          # ritmo = tokens dos últimos 5 min
CTX_WARN, CTX_HIGH = 200_000, 400_000
_files = {}                # path → estado
_lock = threading.Lock()
_started = False
_meta_names = {}           # caminho do .meta.json → nome do agente


def _epoch(ts):
    try:
        return calendar.timegm(time.strptime(ts[:19], "%Y-%m-%dT%H:%M:%S"))
    except Exception:
        return 0


def _new_state():
    return {"off": 0, "ids": {}, "new": 0, "reread": 0, "out": 0, "ctx": 0, "samples": deque(), "ready": False, "size": 0}


def _consume(path, st):
    try:
        size = os.path.getsize(path)
    except OSError:
        return
    if size < st["off"]:                      # arquivo reescrito: recomeça
        st.update(_new_state())
    if size == st["off"]:
        st["ready"] = True
        return
    try:
        with open(path, "rb") as f:
            f.seek(st["off"])
            data = f.read(size - st["off"])
    except OSError:
        return
    cut = data.rfind(b"\n")
    if cut < 0:
        return                                # linha ainda incompleta: espera a próxima rodada
    st["off"] += cut + 1
    for line in data[:cut].split(b"\n"):
        if b'"usage"' not in line or b'"assistant"' not in line:
            continue
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get("type") != "assistant":
            continue
        m = d.get("message") or {}
        u = m.get("usage")
        if not isinstance(u, dict):
            continue
        mid = m.get("id") or d.get("uuid")
        cur = (int(u.get("input_tokens") or 0) + int(u.get("cache_creation_input_tokens") or 0),
               int(u.get("cache_read_input_tokens") or 0), int(u.get("output_tokens") or 0))
        old = st["ids"].get(mid, (0, 0, 0))
        cur = (max(cur[0], old[0]), max(cur[1], old[1]), max(cur[2], old[2]))   # a mesma resposta nunca encolhe
        delta = (cur[0] - old[0]) + (cur[1] - old[1]) + (cur[2] - old[2])
        st["ids"][mid] = cur
        st["new"] += (cur[0] - old[0]) + (cur[2] - old[2])
        st["reread"] += cur[1] - old[1]
        st["out"] += cur[2] - old[2]
        st["ctx"] = cur[0] + cur[1]             # input + cache_creation + cache_read da última resposta
        if delta > 0:
            st["samples"].append((_epoch(d.get("timestamp") or ""), delta))
    cutoff = time.time() - RATE_WINDOW
    while st["samples"] and st["samples"][0][0] < cutoff:
        st["samples"].popleft()
    st["ready"] = True


def _worker():
    while True:
        with _lock:
            items = list(_files.items())
        for path, st in items:
            try:
                _consume(path, st)
            except Exception:
                pass
        time.sleep(1.5)


def register(path):
    global _started
    if not path:
        return
    with _lock:
        if path not in _files:
            _files[path] = _new_state()
        if not _started:
            _started = True
            threading.Thread(target=_worker, daemon=True, name="tokens").start()


def _read(path):
    st = _files.get(path)
    if not st:
        return None
    now = time.time()
    rate = sum(d for t, d in list(st["samples"]) if t >= now - RATE_WINDOW) * 60 / RATE_WINDOW
    return {"new": st["new"], "reread": st["reread"], "out": st["out"], "total": st["new"] + st["reread"],
            "ctx": st["ctx"], "rate": int(rate), "ready": st["ready"]}


def _agent_name(jsonl):
    meta = jsonl[:-len(".jsonl")] + ".meta.json"
    if meta not in _meta_names:
        try:
            m = json.load(open(meta, encoding="utf-8"))
            _meta_names[meta] = m.get("name") or m.get("agentType") or os.path.basename(jsonl)[:-6]
        except Exception:
            _meta_names[meta] = os.path.basename(jsonl)[:-6]
    return _meta_names[meta]


def level(ctx):
    return "high" if ctx >= CTX_HIGH else "warn" if ctx >= CTX_WARN else "ok"


def summary(main_jsonl):
    """Totais da sessão = líder + todos os agentes (subagents/*.jsonl). None enquanto nada foi lido."""
    if not main_jsonl:
        return None
    register(main_jsonl)
    lead = _read(main_jsonl)
    agents = {}
    sub = main_jsonl[:-len(".jsonl")] + "/subagents"
    for p in glob.glob(os.path.join(sub, "*.jsonl")):
        register(p)
        r = _read(p)
        if not r:
            continue
        name = _agent_name(p)
        a = agents.setdefault(name, {"name": name, "new": 0, "reread": 0, "total": 0, "rate": 0, "ctx": 0})
        for k in ("new", "reread", "total", "rate"):
            a[k] += r[k]
        a["ctx"] = max(a["ctx"], r["ctx"])
    ag = sorted(agents.values(), key=lambda x: -x["total"])
    if not lead:
        return {"ready": False, "total": 0, "new": 0, "reread": 0, "rate": 0, "ctx": 0, "level": "ok",
                "lead": None, "agents": [], "agents_total": 0}
    a_total = sum(a["total"] for a in ag)
    return {"ready": lead["ready"], "total": lead["total"] + a_total,
            "new": lead["new"] + sum(a["new"] for a in ag), "reread": lead["reread"] + sum(a["reread"] for a in ag),
            "rate": lead["rate"] + sum(a["rate"] for a in ag), "ctx": lead["ctx"], "level": level(lead["ctx"]),
            "lead": {"total": lead["total"], "new": lead["new"], "rate": lead["rate"], "ctx": lead["ctx"]},
            "agents": ag[:8], "agents_total": a_total, "agents_n": len(ag)}


if __name__ == "__main__":                       # teste manual: tokens.py <transcript.jsonl>
    import sys
    p = sys.argv[1]
    summary(p)
    time.sleep(0.5)
    while not (summary(p) or {}).get("ready"):
        time.sleep(0.5)
    print(json.dumps(summary(p), ensure_ascii=False, indent=1))
