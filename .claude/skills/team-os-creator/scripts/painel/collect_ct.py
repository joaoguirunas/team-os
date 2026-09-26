#!/usr/bin/env python3
"""collect_ct.py — mapa estático do Centro de Treinamento para o `*painel` do team-os-creator (READ-ONLY).

Lê o que existe no CT e devolve um JSON com:
  • squads   ← presets/*.yaml (nome, descrição, agentes com persona/cargo/archetype/skills)
  • agents   ← .claude/agents/*.md (frontmatter + seções do body + skills citadas)
  • skills   ← .claude/skills/*/SKILL.md (frontmatter) + quem usa cada uma
  • projects ← org-map.py da sala-de-controle (quais projetos têm cada squad)

Usage: collect_ct.py [--root <CT>] [--json]
"""
import glob, json, os, re, subprocess, sys, time, unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(os.path.dirname(HERE))     # .claude/skills/team-os-creator
CT = os.path.abspath(os.path.join(SKILL_DIR, "..", "..", ".."))
CORE_SKILLS = ["team-os", "team-os-creator", "sala-de-controle", "maestri-os"]

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.S)


def nfc(s):
    return unicodedata.normalize("NFC", s or "")


def parse_fm(text):
    m = FM_RE.match(text)
    fm, body = {}, text
    if m:
        cur = None
        for line in m.group(1).splitlines():
            if re.match(r"^[A-Za-z_][\w-]*:", line):
                k, v = line.split(":", 1)
                cur = k.strip()
                fm[cur] = v.strip().strip('"').strip("'")
            elif cur and line.strip():
                fm[cur] = (fm.get(cur, "") + "\n" + line).strip()
        body = text[m.end():]
    return fm, body


def parse_preset(path):
    """Parser mínimo para os presets (name/description/agents: - name: … skills: [a, b])."""
    out = {"name": "", "description": "", "archetypes": [], "agents": []}
    cur = None
    for raw in open(path, encoding="utf-8"):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("name:"):
            out["name"] = line.split(":", 1)[1].strip()
        elif line.startswith("description:"):
            out["description"] = line.split(":", 1)[1].strip().strip('"')
        elif line.startswith("project_archetypes:"):
            out["archetypes"] = [x.strip() for x in line.split(":", 1)[1].strip().strip("[]").split(",") if x.strip()]
        elif line.lstrip().startswith("- name:"):
            cur = {"name": line.split(":", 1)[1].strip(), "skills": []}
            out["agents"].append(cur)
        elif cur and re.match(r"^\s+[a-z_]+:", line):
            k, v = line.strip().split(":", 1)
            v = v.strip()
            if k == "skills":
                cur["skills"] = [x.strip().strip('"') for x in v.strip("[]").split(",") if x.strip()]
            else:
                cur[k] = v.strip('"')
    return out


def sections(body):
    """Título e seções `## …` do body (texto curto de cada uma)."""
    secs = []
    title = ""
    cur = None
    for line in body.splitlines():
        if line.startswith("# ") and not title:
            title = line[2:].strip()
        elif line.startswith("## "):
            cur = {"h": line[3:].strip(), "text": ""}
            secs.append(cur)
        elif cur is not None:
            cur["text"] += line + "\n"
    for s in secs:
        s["text"] = s["text"].strip()[:600]
    return title, secs


_cache = {"t": 0, "v": None, "org": (0, None)}


def org_projects(ttl=60):
    t, v = _cache["org"]
    if v is None or time.time() - t > ttl:
        script = os.path.join(CT, ".claude", "skills", "sala-de-controle", "scripts", "org-map.py")
        root = os.path.dirname(CT)
        v = []
        if os.path.isfile(script):
            try:
                out = subprocess.run([sys.executable, script, root, "--json"], capture_output=True, text=True, timeout=30).stdout
                d = json.loads(out[out.find("{"):])
                v = [{"name": nfc(n["name"]), "path": nfc(n["path"]), "business": nfc(n.get("business") or ""),
                      "squads": n.get("squads", []), "kind": n.get("kind"), "smart_memory": bool(n.get("smart_memory"))}
                     for n in d.get("nodes", []) if n.get("is_project") and not n.get("is_ct")]
            except Exception:
                v = []
        _cache["org"] = (time.time(), v)
    return v


def collect(ttl=10):
    if _cache["v"] is not None and time.time() - _cache["t"] < ttl:
        return _cache["v"]
    t0 = time.time()
    # skills
    skills = {}
    for sk in sorted(glob.glob(os.path.join(CT, ".claude", "skills", "*", "SKILL.md"))):
        name = os.path.basename(os.path.dirname(sk))
        try:
            text = open(sk, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        fm, body = parse_fm(text)
        title, secs = sections(body)
        skills[name] = {"name": name, "description": fm.get("description", "")[:400], "version": fm.get("version", ""),
                        "updated": fm.get("updated", ""), "invocable": fm.get("user-invocable", "") == "true",
                        "core": name in CORE_SKILLS, "title": title, "sections": [s["h"] for s in secs],
                        "size": os.path.getsize(sk), "used_by": [], "files": len(glob.glob(os.path.join(os.path.dirname(sk), "**", "*"), recursive=True))}
    # presets
    squads = {}
    preset_agent = {}
    for py in sorted(glob.glob(os.path.join(SKILL_DIR, "presets", "*.yaml"))):
        p = parse_preset(py)
        if not p["name"]:
            continue
        squads[p["name"]] = {"name": p["name"], "description": p["description"], "archetypes": p["archetypes"],
                             "agents": [a["name"] for a in p["agents"]], "skills": [], "projects": []}
        for a in p["agents"]:
            a["squad"] = p["name"]
            preset_agent[a["name"]] = a
    # agents
    agents = {}
    skill_names = set(skills)
    for am in sorted(glob.glob(os.path.join(CT, ".claude", "agents", "*.md"))):
        name = os.path.splitext(os.path.basename(am))[0]
        try:
            text = open(am, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        fm, body = parse_fm(text)
        title, secs = sections(body)
        pa = preset_agent.get(name, {})
        squad = pa.get("squad") or name.split("-")[0]
        cited = sorted(s for s in skill_names if re.search(r"(?<![\w-])" + re.escape(s) + r"(?![\w-])", body))
        related = [s for s in (pa.get("skills") or []) if s in skill_names]
        for s in related:
            if s not in cited:
                cited.append(s)
        exclusive = next((s["text"] for s in secs if re.search(r"autoridade|exclusiv", s["h"], re.I)), "")
        agents[name] = {"name": name, "squad": squad, "persona": pa.get("persona", ""), "role": pa.get("role_title", ""),
                        "archetype": pa.get("archetype", ""), "description": fm.get("description", "")[:500],
                        "model": fm.get("model", ""), "effort": fm.get("effort", ""), "color": fm.get("color", ""),
                        "permission": fm.get("permissionMode", ""), "memory": fm.get("memory", ""),
                        "tools": [t.strip() for t in fm.get("tools", "").split(",") if t.strip()],
                        "hooks": sorted(set(re.findall(r"hooks/([\w-]+\.sh)", fm.get("hooks", "")))),
                        "title": title, "sections": [s["h"] for s in secs], "exclusive": exclusive[:400],
                        "skills": cited, "lines": text.count("\n") + 1}
        if squad not in squads:
            squads[squad] = {"name": squad, "description": "", "archetypes": [], "agents": [], "skills": [], "projects": []}
        if name not in squads[squad]["agents"]:
            squads[squad]["agents"].append(name)
        for s in cited:
            skills[s]["used_by"].append(name)
    for sq in squads.values():
        sk = set()
        for a in sq["agents"]:
            sk.update(agents.get(a, {}).get("skills", []))
        sq["skills"] = sorted(s for s in sk if not skills[s]["core"])
        sq["agents"] = [a for a in sq["agents"] if a in agents]
    projects = org_projects()
    for pr in projects:
        for s in pr["squads"]:
            if s in squads:
                squads[s]["projects"].append(pr["name"])
    hooks = sorted(os.path.basename(h) for h in glob.glob(os.path.join(CT, ".claude", "hooks", "*.sh")))
    v = {"ct": nfc(CT), "generated": time.strftime("%Y-%m-%dT%H:%M:%S"), "took_ms": int((time.time() - t0) * 1000),
         "counts": {"agents": len(agents), "skills": len(skills), "squads": len(squads), "projects": len(projects), "hooks": len(hooks)},
         "squads": [squads[k] for k in sorted(squads)], "agents": agents, "skills": skills, "projects": projects, "hooks": hooks}
    _cache["t"], _cache["v"] = time.time(), v
    return v


def read_file(kind, name):
    """Conteúdo completo de um agente ou skill (só dentro do CT)."""
    if not re.fullmatch(r"[\w.-]+", name or ""):
        return None
    if kind == "agent":
        p = os.path.join(CT, ".claude", "agents", name + ".md")
    elif kind == "skill":
        p = os.path.join(CT, ".claude", "skills", name, "SKILL.md")
    else:
        return None
    if not os.path.isfile(p):
        return None
    text = open(p, encoding="utf-8", errors="replace").read()
    fm, body = parse_fm(text)
    return {"kind": kind, "name": name, "path": os.path.relpath(p, CT), "frontmatter": fm, "body": body}


if __name__ == "__main__":
    st = collect()
    if "--json" in sys.argv:
        print(json.dumps(st, ensure_ascii=False, indent=1))
    else:
        c = st["counts"]
        print(f"CT {st['ct']} · {c['agents']} agentes · {c['skills']} skills · {c['squads']} squads · {c['projects']} projetos ({st['took_ms']} ms)")
        for sq in st["squads"]:
            print(f"- {sq['name']}: {len(sq['agents'])} agentes · {len(sq['skills'])} skills · projetos: {', '.join(sq['projects']) or '—'}")
