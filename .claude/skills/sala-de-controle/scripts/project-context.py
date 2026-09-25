#!/usr/bin/env python3
"""project-context.py — em que ETAPA está um projeto, lido da smart-memory dele (READ-ONLY).

Lê, em ordem de importância, SÓ estes pontos (nunca código, nunca pasta inteira, nunca _archive/):
  1. _session/ledger-<data>.md mais recente  — a etapa real (DONE / in-progress / BLOCKED / Rulings)
  2. stories/active, stories/in-review, stories/BACKLOG.md
  3. _inbox/*.md dos últimos N dias           — o que os agentes registraram
  4. agents/<área>/DIGEST.md → "Contexto recente"
  5. decisions/ (3 mais recentes)
  6. INDEX.md + project/overview.md           — o que o projeto é
  + .claude/agents/*.md (nomes → squads)

Usage: project-context.py <pasta> [--days 7] [--json]
Saída: KEY=value por linha; listas em linhas repetidas (LEDGER=…, STORY_ACTIVE=…, INBOX=…).
"""
import json, os, re, sys, time

ARGS = [a for a in sys.argv[1:]]
AS_JSON = "--json" in ARGS
DAYS = 7
if "--days" in ARGS:
    try:
        DAYS = int(ARGS[ARGS.index("--days") + 1])
    except Exception:
        pass
POS = [a for i, a in enumerate(ARGS) if not a.startswith("--") and (i == 0 or ARGS[i - 1] != "--days")]
if not POS:
    print("ERROR=missing_path|Usage: project-context.py <pasta> [--days 7] [--json]", file=sys.stderr)
    sys.exit(2)
ROOT = os.path.abspath(POS[0])
if not os.path.isdir(ROOT):
    print(f"ERROR=not_a_dir|PATH={ROOT}", file=sys.stderr)
    sys.exit(1)
SM = os.path.join(ROOT, "docs", "smart-memory")
NOW = time.time()
out = {"PATH": ROOT, "NAME": os.path.basename(ROOT)}


def read(p, limit=400_000):
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return f.read(limit)
    except Exception:
        return ""


def frontmatter(txt):
    m = re.match(r"^---\n(.*?)\n---\n?", txt, re.S)
    fm = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line and not line.startswith(" "):
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm, (txt[m.end():] if m else txt)


def title_of(p):
    fm, body = frontmatter(read(p, 20_000))
    if fm.get("title"):
        return fm["title"]
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return os.path.basename(p)


def summary_of(p):
    fm, body = frontmatter(read(p, 20_000))
    if fm.get("summary") and "TODO" not in fm["summary"]:
        return fm["summary"]
    seen = False
    for line in body.splitlines():
        if line.startswith("# "):
            seen = True
            continue
        s = line.strip()
        if seen and s and not s.startswith(("#", ">", "<!--", "|", "---")) and "TODO" not in s \
                and not re.search(r":\s*[—–-]?\s*$", s.replace("**", "")):
            return s
    return ""


def clip(s, n=220):
    s = " ".join(re.sub(r"\*\*|`", "", s).split())
    return s[:n] + ("…" if len(s) > n else "")


def md_files(d):
    if not os.path.isdir(d):
        return []
    return sorted((os.path.join(d, f) for f in os.listdir(d)
                   if f.endswith(".md") and not f.startswith(".")),
                  key=os.path.getmtime, reverse=True)


# ── Negócio (contêiner) ───────────────────────────────────────────────────────
parent = os.path.dirname(ROOT)
pname = os.path.basename(parent)
out["BUSINESS"] = pname if out["NAME"].startswith(pname + " |") or out["NAME"].startswith(pname + "|") else ""

# ── Agentes / squads ─────────────────────────────────────────────────────────
ad = os.path.join(ROOT, ".claude", "agents")
agents = sorted(f[:-3] for f in os.listdir(ad) if f.endswith(".md")) if os.path.isdir(ad) else []
out["AGENT_COUNT"] = str(len(agents))
out["SQUADS"] = ",".join(sorted({a.split("-")[0] for a in agents})) or "(sem agentes)"
out["HAS_TEAM_OS"] = "1" if os.path.isdir(os.path.join(ROOT, ".claude", "skills", "team-os")) else "0"
out["HAS_SMART_MEMORY"] = "1" if os.path.isfile(os.path.join(SM, "INDEX.md")) else "0"

# ── O que o projeto é ────────────────────────────────────────────────────────
summ = ""
for cand in (os.path.join(SM, "project", "overview.md"), os.path.join(SM, "INDEX.md")):
    if os.path.isfile(cand):
        summ = summary_of(cand)
        if summ:
            break
out["SUMMARY"] = clip(summ, 240) if summ else "(sem resumo — smart-memory ainda não bootstrapada)"

lists = {k: [] for k in ("LEDGER", "STORY_ACTIVE", "STORY_IN_REVIEW", "BACKLOG", "INBOX", "DIGEST", "DECISION")}
latest_touch = 0.0

if os.path.isdir(SM):
    # 1. Ledger mais recente
    ledgers = [p for p in md_files(os.path.join(SM, "_session")) if os.path.basename(p).startswith("ledger")]
    if ledgers:
        lp = ledgers[0]
        out["LEDGER_FILE"] = os.path.relpath(lp, SM)
        out["LEDGER_UPDATED"] = time.strftime("%Y-%m-%d %H:%M", time.localtime(os.path.getmtime(lp)))
        out["LEDGER_TITLE"] = clip(title_of(lp), 160)
        lines = [l for l in read(lp).splitlines() if l.strip()]
        key = re.compile(r"DONE|in-progress|in progress|pending|BLOCKED|bloquead|waiting|aguard|Ruling|FAIL|PASS|próximo|pendente", re.I)
        picked = [l for l in lines if key.search(l) and not l.startswith("#")]
        # Mantém a ordem do arquivo, prioriza o fim (estado mais novo)
        for l in picked[-12:]:
            lists["LEDGER"].append(clip(l.lstrip("-* ").strip(), 230))
        latest_touch = max(latest_touch, os.path.getmtime(lp))
    # 2. Stories
    for sub, key in (("active", "STORY_ACTIVE"), ("in-review", "STORY_IN_REVIEW")):
        for p in md_files(os.path.join(SM, "stories", sub))[:10]:
            fm, _ = frontmatter(read(p, 8000))
            lists[key].append(f"{os.path.basename(p)[:-3]} — {clip(title_of(p), 120)}"
                              + (f" · status: {fm['status']}" if fm.get("status") else ""))
            latest_touch = max(latest_touch, os.path.getmtime(p))
    bl = os.path.join(SM, "stories", "BACKLOG.md")
    if os.path.isfile(bl):
        rows = [l for l in read(bl).splitlines() if l.startswith("|") and not re.match(r"^\|\s*-", l)]
        rows = [r for r in rows[1:]  # sem o cabeçalho
                if (r.strip("|").split("|") or [""])[0].strip().lower() not in ("story", "id", "#", "título")]
        open_rows = [r for r in rows if not re.search(r"\bdone\b|concluíd", r, re.I)]
        out["BACKLOG_OPEN"] = str(len(open_rows))
        for r in open_rows[:8]:
            lists["BACKLOG"].append(clip(" · ".join(c.strip() for c in r.strip("|").split("|") if c.strip()), 180))
    # 3. Inbox recente
    for p in md_files(os.path.join(SM, "_inbox")):
        if NOW - os.path.getmtime(p) > DAYS * 86400:
            continue
        s = summary_of(p) or title_of(p)
        lists["INBOX"].append(f"{time.strftime('%m-%d', time.localtime(os.path.getmtime(p)))} {os.path.basename(p)[:-3]} — {clip(s, 180)}")
        latest_touch = max(latest_touch, os.path.getmtime(p))
        if len(lists["INBOX"]) >= 10:
            break
    # 4. DIGEST → Contexto recente
    agd = os.path.join(SM, "agents")
    if os.path.isdir(agd):
        for area in sorted(os.listdir(agd)):
            dg = os.path.join(agd, area, "DIGEST.md")
            if not os.path.isfile(dg):
                continue
            txt = read(dg)
            m = re.search(r"^##+\s*Contexto recente.*?$(.*?)(?=^##\s|\Z)", txt, re.S | re.M | re.I)
            if not m:
                continue
            items = [l.strip().lstrip("-* ").strip() for l in m.group(1).splitlines()
                     if l.strip().startswith(("-", "*")) and "<!--" not in l]
            for it in items[:3]:
                lists["DIGEST"].append(f"{area}: {clip(it, 180)}")
            if items:
                latest_touch = max(latest_touch, os.path.getmtime(dg))
    # 5. Decisões recentes
    for p in md_files(os.path.join(SM, "decisions"))[:3]:
        lists["DECISION"].append(f"{os.path.basename(p)[:-3]} — {clip(title_of(p), 140)}")

out["LAST_TOUCH"] = time.strftime("%Y-%m-%d %H:%M", time.localtime(latest_touch)) if latest_touch else "(sem atividade registrada)"
out["SCANNED_AT"] = time.strftime("%Y-%m-%d %H:%M")

if AS_JSON:
    print(json.dumps({**out, **lists}, ensure_ascii=False, indent=1))
else:
    for k, v in out.items():
        print(f"{k}={v}")
    for k, vs in lists.items():
        for v in vs:
            print(f"{k}={v}")
