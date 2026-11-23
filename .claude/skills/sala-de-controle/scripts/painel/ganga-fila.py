#!/usr/bin/env python3
"""Fila de pedidos da Ganga — lida pela sessão da Sala de Controle (etapa 4).

  ganga-fila.py --wait            fica ouvindo: imprime 1 linha JSON por pedido novo `na_fila` (para o Monitor
                                  da sessão da Sala) e marca o batimento "Sala ouvindo" a cada 20 s
  ganga-fila.py --list            pedidos recentes (todos os status)
  ganga-fila.py --mark ID STATUS [NOTA]
                                  STATUS: entregue | respondido | aguardando_ok | erro | cancelado

Os pedidos foram confirmados pelo João por voz ou por clique no painel. Mesmo assim, push, deploy, publicar,
apagar, pagar ou enviar para fora vêm com `ok_no_chat: true` — a Sala pergunta no chat antes de despachar.
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import copilot  # noqa: E402

STATUSES = {"entregue", "respondido", "aguardando_ok", "erro", "cancelado"}


def beat():
    os.makedirs(copilot.QDIR, exist_ok=True)
    with open(copilot.HEARTBEAT, "w") as f:
        f.write(time.strftime("%Y-%m-%dT%H:%M:%S"))


def mark(pid, status, note=""):
    if status not in STATUSES:
        sys.exit(f"status inválido: {status} (use {', '.join(sorted(STATUSES))})")
    if not any(r["id"] == pid for r in copilot.read_queue(500)):
        sys.exit(f"pedido não encontrado: {pid}")
    with open(copilot.QUEUE, "a", encoding="utf-8") as f:
        f.write(json.dumps({"id": pid, "status": status, "note": note[:500], "updated": time.strftime("%Y-%m-%dT%H:%M:%S")},
                           ensure_ascii=False) + "\n")
    print(f"OK {pid} → {status}")


def wait():
    seen = {r["id"] for r in copilot.read_queue(500) if r.get("status") != "na_fila"}
    announced = set()
    last_beat = 0
    print("GANGA_FILA=ouvindo", flush=True)
    while True:
        if time.time() - last_beat > 20:
            beat()
            last_beat = time.time()
        for r in reversed(copilot.read_queue(50)):
            if r.get("status") == "na_fila" and r["id"] not in announced and r["id"] not in seen:
                announced.add(r["id"])
                out = {k: r.get(k) for k in ("id", "project", "project_path", "session", "session_id", "session_status",
                                              "text", "ok_no_chat", "confirmed")}
                print("PEDIDO_GANGA " + json.dumps(out, ensure_ascii=False), flush=True)
        time.sleep(2)


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["--wait"]:
        try:
            wait()
        except KeyboardInterrupt:
            pass
    elif a[:1] == ["--list"]:
        for r in copilot.read_queue(30):
            print(f"{r.get('confirmed', '')[:16]}  {r['id']}  {r.get('status', ''):<13} {r.get('project', '')} — {r.get('text', '')[:90]}")
    elif a[:1] == ["--mark"] and len(a) >= 3:
        mark(a[1], a[2], " ".join(a[3:]))
    else:
        print(__doc__)
