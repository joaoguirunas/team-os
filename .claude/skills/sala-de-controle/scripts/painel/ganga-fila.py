#!/usr/bin/env python3
"""Fila de pedidos da Ganga — lida pela sessão da Sala de Controle.

  ganga-fila.py --wait            fica ouvindo: imprime `PEDIDO_GANGA {json}` por pedido a despachar e
                                  `CANCELADO_GANGA {id}` se o usuário cancelar um já anunciado; marca o batimento
                                  "Sala ouvindo" a cada 20 s
  ganga-fila.py --list            pedidos recentes (todos os status)
  ganga-fila.py --mark ID STATUS [NOTA]
                                  STATUS: entregue | respondido | aguardando_ok | erro | cancelado

Toda aprovação é dada pelo usuário NA GANGA (voz ou botão): pedido comum sai direto; envio para fora leva 1 "sim";
ação sensível (publicar no ar, deploy, apagar, pagar) leva 2. O que chega aqui já está aprovado — a Sala despacha
sem perguntar de novo no chat. Cada pedido é anunciado UMA vez (vira `anunciado`); se ficar mais de 15 min sem ser
entregue, volta para `aguardando_ok` e a Ganga pergunta de novo ao usuário.
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import copilot  # noqa: E402

STATUSES = {"entregue", "respondido", "aguardando_ok", "aprovado", "erro", "cancelado"}


def beat():
    os.makedirs(copilot.QDIR, exist_ok=True)
    with open(copilot.HEARTBEAT, "w") as f:
        f.write(time.strftime("%Y-%m-%dT%H:%M:%S"))


def mark(pid, status, note=""):
    if status not in STATUSES:
        sys.exit(f"status inválido: {status} (use {', '.join(sorted(STATUSES))})")
    if not any(r["id"] == pid for r in copilot.read_queue(500)):
        sys.exit(f"pedido não encontrado: {pid}")
    copilot.append_status(pid, status, note)
    print(f"OK {pid} → {status}")


STALE = 900   # 15 min


def wait():
    def age(r, k="confirmed"):
        return time.time() - copilot._epoch(r.get(k) or r.get("updated") or r.get("confirmed"))
    told = set()        # anunciados por ESTE processo (para avisar cancelamento)
    last_beat = 0
    print("GANGA_FILA=ouvindo", flush=True)
    while True:
        if time.time() - last_beat > 20:
            beat()
            last_beat = time.time()
        for r in reversed(copilot.read_queue(80)):
            st, pid = r.get("status"), r["id"]
            if st in ("na_fila", "aprovado"):
                if age(r, "aprovado_em" if st == "aprovado" else "confirmed") > STALE:
                    copilot.append_status(pid, "aguardando_ok", "pedido antigo — a Ganga confirma de novo com o usuário")
                    continue
                copilot.append_status(pid, "anunciado")          # grava ANTES de imprimir: nunca anuncia duas vezes
                told.add(pid)
                out = {k: r.get(k) for k in ("id", "project", "project_path", "session", "session_id", "session_status",
                                              "text", "nivel", "ok_por_voz", "aprovado_pelo_usuario", "confirmed")}
                print("PEDIDO_GANGA " + json.dumps(out, ensure_ascii=False), flush=True)
            elif st == "anunciado" and age(r, "updated") > STALE:
                copilot.append_status(pid, "aguardando_ok", "anunciado e não entregue — a Ganga confirma de novo com o usuário")
            elif st == "cancelado" and pid in told:
                told.discard(pid)
                print("CANCELADO_GANGA " + json.dumps({"id": pid}), flush=True)
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
