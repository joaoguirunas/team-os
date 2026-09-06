#!/usr/bin/env python3
"""generate-agents-page.py — gera docs/agentes.html (página oficial dos agentes do CT).

Fontes de dados (tudo do repositório, nada manual na página):
  - .claude/agents/*.md          → frontmatter + persona + autoridade exclusiva
  - README.md                    → coluna "Skills relacionadas" (última célula das tabelas §5)
  - .claude/skills/*/SKILL.md    → descrição de cada skill (para o modal)
  - RESUMOS_PT (dict abaixo)     → resumo em PT por agente (fallback: 1ª frase da description)
  - fotos (opcional): docs/fotos-agentes/<nome>.png no próprio CT, ou --photos <dir> → comprimidas e embutidas
    como data URI (agente sem foto fica com o monograma).

Uso:  python3 generate-agents-page.py [--photos <dir>] [--out <path>]
Rode a partir de qualquer lugar — o script resolve a raiz do CT sozinho.
"""
import os, re, sys, json, base64, subprocess, tempfile, html

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True, cwd=os.path.dirname(os.path.abspath(__file__))).stdout.strip()
PHOTOS = os.path.join(ROOT, "docs", "fotos-agentes")  # dir local opcional; sem fotos a página sai só com iniciais
OUT = os.path.join(ROOT, "docs", "agentes.html")
args = sys.argv[1:]
if "--photos" in args: PHOTOS = args[args.index("--photos") + 1]
if "--out" in args: OUT = args[args.index("--out") + 1]

SQUADS = [
    ("dev", "Dev", "Fullstack SaaS — da arquitetura ao deploy"),
    ("sites", "Sites", "Websites e landing pages — SEO, CRO, performance"),
    ("social", "Social", "Social media — copy, design, foto, vídeo, publicação"),
    ("traffic", "Traffic", "Tráfego pago — Google, Meta, TikTok, BI e atribuição"),
    ("pm", "PM", "Gestão de projetos — sprints, dailies, portfólio"),
]

# Resumo em PT por agente (linha principal do card). Agente ausente → 1ª frase da description.
RESUMOS_PT = {
    "dev-analyst": "Pesquisa técnica sob demanda: comparação de libs, CVEs, viabilidade — entrega evidências antes das decisões de arquitetura.",
    "dev-architect": "Arquiteto do sistema. Autoridade exclusiva para criar e validar stories, ADRs e decisões de stack.",
    "dev-bi": "Arquiteto de dados e dashboards. Consulta o banco (só leitura), compila achados e mantém o dicionário de métricas.",
    "dev-data-engineer": "Dono do banco: schema, migrations, RLS e otimização — sempre com snapshot → dry-run → apply → smoke-test.",
    "dev-data-performance": "Interpreta os dados compilados pelo BI: insights acionáveis, anomalias, previsões e recomendações priorizadas.",
    "dev-dev-alpha": "Desenvolvedor frontend: React, Next.js, Tailwind, componentes de UI e lógica client-side.",
    "dev-dev-beta": "Desenvolvedor backend: APIs, serviços, regras de negócio, performance e integrações server-side.",
    "dev-dev-delta": "Especialista em resiliência — entra DEPOIS das features prontas para blindar: retry, timeouts, edge cases.",
    "dev-dev-gamma": "Desenvolvedor fullstack para o que cruza camadas: integrações, glue code e utilidades.",
    "dev-devops": "Guardião de release. Autoridade exclusiva de git push, PRs, CI/CD e releases.",
    "dev-qa": "QA mestre. Emite os veredictos formais PASS / CONCERNS / FAIL / WAIVED — autoridade exclusiva do gate de qualidade.",
    "dev-ux": "UX e design: research, fluxos, wireframes, specs de componente e acessibilidade antes da implementação.",
    "sites-analyst": "Research para sites: keywords, concorrência, viabilidade de stack e SEO antes das decisões.",
    "sites-architect": "Arquiteto de sites. Autoridade exclusiva para criar e validar stories; define estrutura de páginas e stack.",
    "sites-data": "Banco de dados dos projetos de site: schema, migrations, RLS — com o protocolo de segurança completo.",
    "sites-dev-alpha": "Frontend de sites: React, Next.js, Tailwind, shadcn/ui, landing pages e UI.",
    "sites-dev-beta": "Backend de sites: APIs, integrações com CMS, lógica server-side e performance.",
    "sites-dev-delta": "Hardening de sites: error handling, Core Web Vitals, edge cases — mentalidade adversarial.",
    "sites-dev-gamma": "Fullstack de sites: CRO, SEO técnico, wiring de analytics e features que cruzam camadas.",
    "sites-devops": "Release de sites. Autoridade exclusiva de push, PRs e deploys Vercel/Netlify.",
    "sites-qa": "QA de sites: veredictos formais, acessibilidade, qualidade de copy, SEO e performance.",
    "sites-ux": "UX de sites: research, fluxos, wireframes, specs visuais e a11y antes do alpha implementar.",
    "social-analyst": "Research de social: tendências, concorrência, hashtags e benchmarks — entrega dados, outros decidem.",
    "social-content": "Criador de conteúdo: research de mercado via Apify + copy (legendas, roteiros, hooks, hashtags).",
    "social-design": "Designer gráfico da squad: key visuals, carrosséis, templates e overlays via Google Stitch.",
    "social-photo": "Fotos AI via Freepik: capas, carrosséis, heroes e fundos cinematográficos.",
    "social-publisher": "Publica (via Meta) e analisa métricas — só depois da aprovação da VERA E confirmação do usuário.",
    "social-strategist": "Estrategista e validadora editorial. Nunca cria — valida e direciona; aprovação obrigatória antes de publicar.",
    "social-video": "Editor de vídeo: Reels, Stories, TikToks com ffmpeg + avatar AI e dublagem via HeyGen.",
}


def fm_field(fm, key):
    m = re.search(rf"^{key}:\s*(.+)$", fm, re.M)
    return m.group(1).strip() if m else ""


def first_sentence(text):
    s = re.split(r"(?<=[.!?])\s", text.strip())[0]
    return s if len(s) <= 220 else s[:217] + "…"


def load_agents():
    agents = []
    adir = os.path.join(ROOT, ".claude", "agents")
    for f in sorted(os.listdir(adir)):
        if not f.endswith(".md"):
            continue
        text = open(os.path.join(adir, f)).read()
        m = re.match(r"^---\n(.*?)\n---", text, re.S)
        fm, body = m.group(1), text[m.end():]
        name = fm_field(fm, "name")
        h1 = re.search(r"^# (.+)$", body, re.M)
        persona = (h1.group(1).strip() if h1 else name)
        aut = re.search(r"\*\*Autoridade[s]? exclusiva[s]?:?\*\*:?\s*(.+)", body)
        desc = fm_field(fm, "description")
        agents.append({
            "name": name, "squad": name.split("-")[0], "persona": persona,
            "desc": desc, "resumo": RESUMOS_PT.get(name) or first_sentence(desc),
            "model": fm_field(fm, "model"), "effort": fm_field(fm, "effort"),
            "hook": "block-git-push" in fm,
            "aut": re.sub(r"[`*]", "", aut.group(1)).strip()[:180] if aut else "",
            "mcp": len([t for t in fm_field(fm, "tools").split(",") if t.strip().startswith("mcp__")]),
        })
    return agents


def load_skills():
    skills = {}
    sdir = os.path.join(ROOT, ".claude", "skills")
    for d in sorted(os.listdir(sdir)):
        p = os.path.join(sdir, d, "SKILL.md")
        if not os.path.isfile(p):
            continue
        t = open(p).read()
        m = re.match(r"^---\n(.*?)\n---", t, re.S)
        desc = ""
        if m:
            dm = re.search(r"^description:\s*(.+?)(?=\n[a-zA-Z_-]+:|\Z)", m.group(1), re.S | re.M)
            if dm:
                desc = " ".join(dm.group(1).split())
        skills[d] = desc
    return skills


def load_skill_map(skills):
    """Última célula das linhas de agente nas tabelas §5 do README + skills novas curadas."""
    amap = {}
    for row in open(os.path.join(ROOT, "README.md")).read().splitlines():
        m = re.match(r"^\|\s*`((?:dev|sites|social|traffic|pm)-[a-z-]+)`\s*\|", row)
        if not m:
            continue
        last = row.rstrip("|").rsplit("|", 1)[-1]
        amap[m.group(1)] = [s for s in re.findall(r"/([a-z0-9-]+)", last) if s in skills]
    extras = {
        "nextjs-react-best-practices": ["dev-architect", "dev-dev-alpha", "dev-dev-beta", "dev-dev-delta",
                                        "dev-dev-gamma", "sites-architect", "sites-dev-alpha", "sites-dev-beta",
                                        "sites-dev-delta", "sites-dev-gamma"],
        "data-supabase-patterns": ["dev-data-engineer", "dev-bi", "sites-data", "pm-data"],
        "testing-playwright-e2e": ["dev-qa", "sites-qa"],
        "traffic-paid-ads-optimization": ["traffic-strategist", "traffic-google", "traffic-meta",
                                          "traffic-tiktok", "traffic-copywriter"],
        "traffic-analytics-tracking": ["traffic-bi", "traffic-qa", "traffic-analyst"],
        "verify-before-done": ["dev-qa", "sites-qa", "traffic-qa", "pm-qa", "dev-dev-alpha", "dev-dev-beta",
                               "dev-dev-gamma", "sites-dev-alpha", "sites-dev-beta", "sites-dev-gamma"],
    }
    for skill, targets in extras.items():
        for a in targets:
            amap.setdefault(a, [])
            if skill not in amap[a]:
                amap[a].append(skill)
    return amap


def load_photos():
    photos = {}
    if not os.path.isdir(PHOTOS):
        return photos
    with tempfile.TemporaryDirectory() as tmp:
        for f in sorted(os.listdir(PHOTOS)):
            if not f.endswith(".png"):
                continue
            out = os.path.join(tmp, f[:-4] + ".jpg")
            r = subprocess.run(["sips", "-Z", "220", "-s", "format", "jpeg",
                                "-s", "formatOptions", "72", os.path.join(PHOTOS, f), "--out", out],
                               capture_output=True)
            if r.returncode == 0 and os.path.isfile(out):
                photos[f[:-4]] = base64.b64encode(open(out, "rb").read()).decode()
    return photos


def build():
    agents = load_agents()
    skills = load_skills()
    amap = load_skill_map(skills)
    photos = load_photos()
    counts = {s: sum(1 for a in agents if a["squad"] == s) for s, _, _ in SQUADS}
    opus_n = sum(1 for a in agents if a["model"] == "opus")
    used_by = {}
    for a, sks in amap.items():
        for s in sks:
            used_by.setdefault(s, []).append(a)

    def card(a):
        persona = a["persona"]
        pname, ptitle = (persona.split("—", 1) + [""])[:2] if "—" in persona else (persona, "")
        pname, ptitle = pname.strip(), ptitle.strip()
        photo = (f'<img class="face" src="data:image/jpeg;base64,{photos[a["name"]]}" alt="{html.escape(pname)}">'
                 if a["name"] in photos else f'<div class="face mono-face">{html.escape(pname[:2].upper())}</div>')
        meta = [f'<span class="tag {"opus" if a["model"] == "opus" else ""}">{a["model"]}</span>']
        if a["effort"]:
            meta.append(f'<span class="tag">effort {a["effort"]}</span>')
        if a["hook"]:
            meta.append('<span class="tag" title="hook block-git-push — push só pelo devops">push ⊘</span>')
        if a["mcp"]:
            meta.append(f'<span class="tag">{a["mcp"]} MCP</span>')
        chips = "".join(f'<button class="skill" data-skill="{s}">/{s}</button>' for s in amap.get(a["name"], []))
        aut = (f'<div class="aut"><span>autoridade exclusiva</span>{html.escape(a["aut"])}</div>' if a["aut"] else "")
        q = html.escape((a["name"] + " " + persona + " " + a["desc"] + " " + a["resumo"] + " "
                         + " ".join(amap.get(a["name"], []))).lower(), quote=True)
        return f'''<article class="agent" data-squad="{a["squad"]}" data-q="{q}">
<div class="agent-top">{photo}<div><h3>{html.escape(pname)}</h3>{f'<div class="role">{html.escape(ptitle)}</div>' if ptitle else ''}<code>{a["name"]}</code></div></div>
<p class="resumo">{html.escape(a["resumo"])}</p>
<details><summary>descrição completa</summary><p>{html.escape(a["desc"])}</p></details>
{aut}
{f'<div class="skills"><span class="skills-l">skills</span>{chips}</div>' if chips else ''}
<footer>{"".join(meta)}</footer>
</article>'''

    sections = []
    for i, (s, label, sub) in enumerate(SQUADS, 1):
        cards = "\n".join(card(a) for a in agents if a["squad"] == s)
        sections.append(f'''<section class="squad" data-squad="{s}" id="{s}">
<h2><span class="idx">{i:02d}</span> {label} <span class="count">{counts[s]} agentes</span></h2>
<p class="squad-sub">{sub}</p>
<div class="agents">{cards}</div>
</section>''')

    filters = f'<button class="fbtn active" data-f="all">Todos · {len(agents)}</button>' + "".join(
        f'<button class="fbtn" data-f="{s}">{label} · {counts[s]}</button>' for s, label, _ in SQUADS)

    skills_json = json.dumps(
        {s: {"desc": skills[s], "agents": sorted(used_by.get(s, []))} for s in skills},
        ensure_ascii=False)

    tpl = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "templates",
                            "agents-page.html.tpl")).read()
    page = (tpl.replace("{{FILTERS}}", filters)
               .replace("{{SECTIONS}}", "".join(sections))
               .replace("{{SKILLS_JSON}}", skills_json)
               .replace("{{N_AGENTS}}", str(len(agents)))
               .replace("{{N_SKILLS}}", str(len(skills) - 1))  # -1: team-os-creator é interna
               .replace("{{N_OPUS}}", str(opus_n)))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w").write(page)
    print(f"OK → {OUT} ({len(page)//1024} KB · {len(agents)} agentes · {len(photos)} fotos · {len(skills)} skills)")


if __name__ == "__main__":
    build()
