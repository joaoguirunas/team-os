#!/usr/bin/env python3
"""scan-sessions.py — lista as sessões REAIS do Claude Code abertas nesta máquina (READ-ONLY).

Fontes (cruzadas, porque nenhuma sozinha é completa):
  1. ~/.claude/sessions/<pid>.json   — registro vivo: uma entrada por processo (cwd, name, status…)
  2. `claude agents --json`          — lista oficial (traz `state`, ex.: blocked = esperando o usuário)

Filtra: sessões "spare" (pré-aquecidas pelo Claude, ninguém abriu), processos mortos e a
própria Sala de Controle (marcada IS_SELF=1, não é alvo). Nunca escreve nada.

Usage: scan-sessions.py [--json]
Saída padrão: uma linha TSV por sessão, campos KEY=value:
  NAME  SESSION_ID  SHORT_ID  PID  CWD  FOLDER  KIND  ENTRYPOINT  STATUS  STATE  UPDATED
  NAME_STANDARD  SUGGESTED_NAME  ORPHAN  IS_SELF  TRANSCRIPT
e no fim: SESSIONS_TOTAL=<n>  SELF_NAME=<nome desta sessão>
"""
import json, os, re, subprocess, sys, time

HOME = os.path.expanduser("~")
SESS_DIR = os.path.join(HOME, ".claude", "sessions")
PROJ_DIR = os.path.join(HOME, ".claude", "projects")


def alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except (OSError, ValueError, TypeError):
        return False


def parent_pids():
    """PIDs ancestrais deste script — a sessão que o chamou é um deles."""
    pids, pid = set(), os.getpid()
    for _ in range(40):
        try:
            out = subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)],
                                 capture_output=True, text=True, timeout=5).stdout.strip()
            pid = int(out)
        except Exception:
            break
        if pid <= 1:
            break
        pids.add(pid)
    return pids


def slug(cwd):
    return re.sub(r"[^A-Za-z0-9]", "-", cwd)


def transcript_path(cwd, session_id):
    p = os.path.join(PROJ_DIR, slug(cwd), f"{session_id}.jsonl")
    return p if os.path.isfile(p) else ""


def official():
    try:
        out = subprocess.run(["claude", "agents", "--json"], capture_output=True,
                             text=True, timeout=30).stdout
        return {s.get("sessionId"): s for s in json.loads(out or "[]")}
    except Exception:
        return {}


def main():
    as_json = "--json" in sys.argv
    ancestors = parent_pids()
    off = official()
    rows = []
    if os.path.isdir(SESS_DIR):
        for fn in os.listdir(SESS_DIR):
            if not fn.endswith(".json"):
                continue
            try:
                with open(os.path.join(SESS_DIR, fn), encoding="utf-8") as f:
                    s = json.load(f)
            except Exception:
                continue
            if s.get("spare"):
                continue                      # fantasma pré-aquecida
            pid = s.get("pid")
            if not alive(pid):
                continue                      # processo já morreu
            cwd = s.get("cwd") or ""
            name = s.get("name") or ""
            folder = os.path.basename(cwd.rstrip("/")) if cwd not in ("", "/") else ""
            o = off.get(s.get("sessionId"), {})
            # Padrão de nome: "<NOME DA PASTA> | <Título>"
            std = 1 if folder and name.startswith(folder + " | ") and len(name) > len(folder) + 3 else 0
            rows.append({
                "NAME": name,
                "SESSION_ID": s.get("sessionId", ""),
                "SHORT_ID": s.get("jobId") or o.get("id") or "",
                "PID": str(pid),
                "CWD": cwd,
                "FOLDER": folder,
                "KIND": s.get("kind", ""),
                "ENTRYPOINT": s.get("entrypoint", ""),
                "STATUS": s.get("status", ""),
                "STATE": o.get("state", ""),
                "UPDATED": time.strftime("%Y-%m-%d %H:%M",
                                         time.localtime((s.get("updatedAt") or 0) / 1000)),
                "NAME_STANDARD": str(std),
                "SUGGESTED_NAME": name if std else (f"{folder} | <Título>" if folder else ""),
                "ORPHAN": "1" if cwd and cwd != "/" and not os.path.isdir(cwd) else "0",
                "IS_SELF": "1" if int(pid) in ancestors else "0",
                "TRANSCRIPT": transcript_path(cwd, s.get("sessionId", "")),
            })
    rows.sort(key=lambda r: (r["FOLDER"], r["NAME"]))
    self_name = next((r["NAME"] for r in rows if r["IS_SELF"] == "1"), "")
    if as_json:
        print(json.dumps({"self": self_name, "sessions": rows}, ensure_ascii=False, indent=1))
        return
    for r in rows:
        print("\t".join(f"{k}={v}" for k, v in r.items()))
    print(f"SESSIONS_TOTAL={sum(1 for r in rows if r['IS_SELF'] == '0')}")
    print(f"SELF_NAME={self_name}")


if __name__ == "__main__":
    main()
