#!/usr/bin/env python3
"""generate-agents-page.py — gera docs/agentes.html (página oficial dos agentes do team-os).

Card inteiro clicável abre modal de PERFIL COMPLETO por agente (bio, matriz de autoridade,
regras absolutas, skills) e modal de skill enriquecido (versão, seções), com navegação
cruzada entre os dois modais. JSON embutido protegido contra fechamento prematuro de
<script> (safe_json escapa "</" — nunca confiar em texto livre sem escapar).

Fontes de dados (tudo do repositório, nada manual na página):
  - .claude/agents/*.md          → frontmatter + persona + autoridade exclusiva + bio (1º parágrafo
                                    após o H1) + matriz de autoridade + regras absolutas (para o modal)
  - README.md                    → coluna "Skills relacionadas" (última célula das tabelas §5)
  - .claude/skills/*/SKILL.md    → descrição, versão, data e títulos de seção de cada skill (para o modal)
  - RESUMOS_PT (dict abaixo)     → resumo em PT por agente (fallback: 1ª frase da description)
  - fotos (opcional): docs/fotos-agentes/<nome>.png no próprio CT, ou --photos <dir> → comprimidas e embutidas
    como data URI (agente sem foto fica com o monograma).

Uso:  python3 generate-agents-page.py [--photos <dir>] [--out <path>] [--check]
  --check   não escreve: exit 0 se docs/agentes.html já está igual ao que seria gerado,
            exit 1 se está desatualizado (ou ausente) — para uso no CI/pre-commit.
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
CHECK = "--check" in args

SQUADS = [
    ("dev", "Dev", "Fullstack SaaS — da arquitetura ao deploy"),
    ("sites", "Sites", "Websites e landing pages — SEO, CRO, performance"),
    ("social", "Social", "Social media — copy, design, foto, vídeo, publicação"),
    ("traffic", "Traffic", "Tráfego pago — Google, Meta, TikTok, BI e atribuição"),
    ("pm", "PM", "Gestão de projetos — sprints, dailies, portfólio"),
    ("sales", "Sales", "Propostas e apresentações — discovery, tese, números, copy, PDF, QA, fechamento"),
    ("brand", "Brand", "Reposicionamento de marca — pesquisa, plataforma, arquitetura, voz, visual, medição, rollout, QA"),
    ("finance", "Finance", "Gestão financeira — coleta, política, plano de caixa, conciliação, contas a pagar/receber, fiscal, relatório, QA"),
    ("legal", "Legal", "Jurídico do dia a dia — pesquisa, postura, arquitetura documental, minutas, registro e LGPD, conflitos, operações, QA"),
    ("seo", "SEO", "Auditoria e otimização de busca — técnico, conteúdo, schema, sitemap/i18n, CWV, GEO/AI search, SXO, clusters, local, backlinks, e-commerce, dados Google, drift, QA"),
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
    "brand-analyst": "Audita a marca como ela é hoje, mapeia concorrentes e territórios, sintetiza públicos — toda afirmação com fonte. Entrega evidência; outros decidem.",
    "brand-strategist": "Escreve a plataforma de marca e a postura do reposicionamento; gate da plataforma e da direção de identidade. Nunca escreve a peça.",
    "brand-architect": "Arquitetura de marca (marca-mãe, sub-marcas, marca pessoal, sistema de nomes) e autoridade exclusiva das stories do reposicionamento.",
    "brand-voice": "Identidade verbal a partir da plataforma aprovada: guia de voz, framework de mensagens, manifesto, tagline, glossário, nomes dentro do sistema.",
    "brand-designer": "Identidade visual via Claude Design: direções com opções, sistema de cor/tipo/grid/imagem e brandbook — cada elemento rastreado à plataforma.",
    "brand-insights": "Fonte única dos números da marca: scorecard, linha de base antes da virada, leitura do depois com o mesmo método, ficha com #id.",
    "brand-rollout": "Implantação depois do PASS: plano interno → externo, inventário de ativos, checklist por canal e o kit de handoff que as outras squads seguem.",
    "brand-qa": "Gate final de todo deliverable de marca — fidelidade à plataforma, coerência verbal ↔ visual, fonte e #id em tudo. Veredictos PASS / CONCERNS / FAIL / WAIVED.",
    "sales-analyst": "Discovery: transforma reunião/transcrição em ficha de intake e pesquisa cliente, setor e benchmarks — todo número com fonte.",
    "sales-strategist": "Estrategista do negócio: tese, enquadramento da oferta, postura de negociação e gate de aprovação do planejamento. Nunca escreve a proposta.",
    "sales-planner": "Arquiteto da proposta. Autoridade exclusiva para criar a story e escrever o planejamento interno — roadmap com aceite, bastidor e estrutura página a página do PDF.",
    "sales-finance": "Fonte única dos números: preço vs. tabela, desconto e breakeven, payback do cliente, permuta, plano de negócios e valuation com sensibilidade.",
    "sales-copywriter": "Redatora da proposta: texto página a página com voz declarativa, compromisso conjunto e número só com origem na ficha.",
    "sales-designer": "Produz PDF e deck no design system do projeto — HTML com print CSS, export headless e checagem de páginas, fontes e overflow.",
    "sales-qa": "QA da proposta. Veredictos PASS / CONCERNS / FAIL / WAIVED antes de qualquer envio — convenção, marca, rastreabilidade numérica, zero risco no cliente.",
    "sales-closer": "Fechamento: brief de reunião a partir das objeções, follow-up, ledger de propostas. Só envia com PASS e confirmação do usuário.",
    "finance-analyst": "Coleta e classifica documentos do período, extrai dados para o controller e pesquisa benchmarks, tarifas e índices — toda cifra com documento ou fonte datada. Entrega evidência; não lança.",
    "finance-strategist": "Escreve a política financeira (margem, reserva, alçadas, prioridade de pagamento, distribuição) e é o gate do orçamento e do plano de caixa. Nunca lança, paga ou escreve relatório.",
    "finance-planner": "Orçamento, plano de caixa de 13 semanas, forecast com cenários e roadmap de metas — sempre sobre fechamento fechado e política aprovada. Autoridade exclusiva das stories financeiras.",
    "finance-controller": "Fonte única dos números: plano de contas, conciliação item a item, DRE gerencial, fechamento mensal com #id. Nenhum número entra em relatório, plano ou cobrança sem passar por ele.",
    "finance-billing": "Contas a receber e a pagar preparadas — cobranças, régua de inadimplência, agenda e lotes de pagamento com documento. Prepara, nunca executa: quem paga é o humano, com PASS e confirmação.",
    "finance-tax": "Calendário de obrigações, apuração preparatória por tributo com regra e fonte, pacote para o contador. Não declara, não transmite, não recolhe — o contador valida e o usuário executa.",
    "finance-reporter": "Fechamento em linguagem de sócio, painel de indicadores, relatório para sócios, investidores e banco — todo número com #id do fechamento fechado, nenhum aproximado.",
    "finance-qa": "Gate final de fechamento, plano, lote de pagamento, cobrança, apuração e relatório — conciliação conferida, cada número com #id, confirmação do usuário antes de executar dinheiro. Veredictos PASS / CONCERNS / FAIL / WAIVED.",
    "legal-analyst": "Pesquisa lei, jurisprudência, doutrina e o histórico contratual da empresa — fonte primária com artigo ou acórdão e data; separa achado de leitura e nunca emite parecer.",
    "legal-strategist": "Escreve a postura jurídica (apetite a risco, inegociáveis, negociáveis com piso e teto, foro, postura em conflito) e é o gate de toda minuta e notificação. Nunca redige.",
    "legal-architect": "Arquitetura documental: matriz de relações por documento, sistema de modelos versionado, hierarquia contrato-mãe/anexos/aditivos. Autoridade exclusiva das stories jurídicas.",
    "legal-drafter": "Redige e revisa contratos, aditivos, distratos, NDAs e termos a partir do modelo e da postura aprovada, com matriz de desvios em toda minuta. Nunca inventa cláusula sem origem, nunca envia.",
    "legal-compliance": "Fonte única de prazos e obrigações: registro de contratos vigentes com #id, mapa de dados com base legal, consentimentos, incidentes e calendário regulatório.",
    "legal-disputes": "Notificação extrajudicial, cobrança, acordo, distrato e dossiê para o advogado externo com prazos com fonte. Prepara; nunca envia, ameaça, assina ou protocola.",
    "legal-ops": "Depois do PASS: fluxo de assinatura com versão travada, arquivamento, registro, renovações e envio à contraparte só com PASS e confirmação do usuário. Minuta enviada vira versão nova.",
    "legal-qa": "Gate final de minuta, aditivo, notificação, política e dossiê — matriz de desvios completa, inegociáveis intactos, partes e valores coerentes, base legal com fonte. Veredictos PASS / CONCERNS / FAIL / WAIVED.",
}


def fm_field(fm, key):
    m = re.search(rf"^{key}:\s*(.+)$", fm, re.M)
    return m.group(1).strip() if m else ""


def first_sentence(text):
    s = re.split(r"(?<=[.!?])\s", text.strip())[0]
    return s if len(s) <= 220 else s[:217] + "…"


def clean_md(text):
    """Tira ** * ` de ênfase markdown pra texto puro de modal, preserva o resto."""
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"(?<!\w)\*(.+?)\*(?!\w)", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    return " ".join(text.split())


def load_agent_details(path):
    """Lê o corpo do agente e extrai bio (1º parágrafo após o H1), matriz de autoridade e regras absolutas."""
    out = {"bio": "", "matrix": [], "rules": []}
    text = open(path).read()
    m = re.match(r"^---\n(.*?)\n---\n(.*)", text, re.S)
    if not m:
        return out
    body = m.group(2)
    h1 = re.search(r"^# (.+)$", body, re.M)
    if h1:
        after = body[h1.end():]
        para = re.match(r"\s*\n+([^\n].*?)(?=\n\s*\n|\n##)", after, re.S)
        if para:
            out["bio"] = clean_md(para.group(1))
    mat = re.search(r"\*\*Matriz de autoridade:?\*\*\s*\n((?:\|.*\n?)+)", body)
    if mat:
        rows = [r for r in mat.group(1).strip().split("\n") if r.strip().startswith("|")]
        rows = [r for r in rows if not re.match(r"^\|[\s:|-]+\|$", r)]  # tira separador ---
        for r in rows[1:] if rows else []:  # rows[0] é o cabeçalho
            cells = [clean_md(c.strip()) for c in r.strip("|").split("|")]
            if len(cells) >= 2:
                out["matrix"].append(cells[:3])
    ra = re.search(r"##\s*Regras absolutas\s*\n((?:.*\n?)+?)(?=\n##|\Z)", body)
    if ra:
        bullets = re.findall(r"^[-*]\s+(.+)$", ra.group(1), re.M)
        out["rules"] = [clean_md(b) for b in bullets[:8]]
    return out


def load_skill_details(path):
    """Lê o SKILL.md e extrai versão, data de atualização e os títulos de seção (## ...)."""
    out = {"version": "", "updated": "", "sections": []}
    text = open(path).read()
    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    if m:
        vm = re.search(r'^version:\s*"?([\w.]+)"?', m.group(1), re.M)
        um = re.search(r'^updated:\s*"?([\d-]+)"?', m.group(1), re.M)
        out["version"] = vm.group(1) if vm else ""
        out["updated"] = um.group(1) if um else ""
    out["sections"] = [clean_md(t) for t in re.findall(r"^##\s+(.+)$", text, re.M)][:8]
    return out


def safe_json(obj):
    """json.dumps não escapa '</' — texto livre com '</script' fecharia a tag cedo e quebraria
    todo o JS depois. Escapar '</' pra '<\\/' é o padrão pra JSON embutido em HTML."""
    return json.dumps(obj, ensure_ascii=False).replace("</", "<\\/")


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
        details = load_agent_details(os.path.join(adir, f))
        agents.append({
            "name": name, "squad": name.split("-")[0], "persona": persona,
            "desc": desc, "resumo": RESUMOS_PT.get(name) or first_sentence(desc),
            "model": fm_field(fm, "model"), "effort": fm_field(fm, "effort"),
            "hook": "block-git-push" in fm,
            "aut": re.sub(r"[`*]", "", aut.group(1)).strip()[:180] if aut else "",
            "mcp": len([t for t in fm_field(fm, "tools").split(",") if t.strip().startswith("mcp__")]),
            **details,
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
        skills[d] = {"desc": desc, **load_skill_details(p)}
    return skills


def load_skill_map(skills):
    """Última célula das linhas de agente nas tabelas §5 do README + skills novas curadas."""
    amap = {}
    for row in open(os.path.join(ROOT, "README.md")).read().splitlines():
        m = re.match(r"^\|\s*`((?:dev|sites|social|traffic|pm|sales)-[a-z-]+)`\s*\|", row)
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
    # Só squads oficiais (com preset). Agente de squad ainda sem preset — em construção noutra sessão — não entra na página.
    _official = {s[0] for s in SQUADS}
    agents = [a for a in agents if a['squad'] in _official]
    skills = load_skills()
    amap = load_skill_map(skills)
    photos = load_photos()
    counts = {s: sum(1 for a in agents if a["squad"] == s) for s, _, _ in SQUADS}
    opus_n = sum(1 for a in agents if a["model"] == "opus")
    _squad_prefixes = {s for s, _, _ in SQUADS}
    skill_names_all = [s for s in skills if s != "team-os-creator"]
    skill_counts = {
        s: sum(1 for sk in skill_names_all if sk == s or sk.startswith(s + "-"))
        for s, _, _ in SQUADS
    }
    general_skill_names = [
        sk for sk in skill_names_all
        if not any(sk == s or sk.startswith(s + "-") for s in _squad_prefixes)
    ]
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
        return f'''<article class="agent" data-squad="{a["squad"]}" data-q="{q}" data-agent="{a["name"]}" tabindex="0" role="button" aria-label="Ver perfil completo de {html.escape(pname)}">
<div class="agent-top">{photo}<div><h3>{html.escape(pname)}</h3>{f'<div class="role">{html.escape(ptitle)}</div>' if ptitle else ''}<code>{a["name"]}</code></div></div>
<p class="resumo">{html.escape(a["resumo"])}</p>
{aut}
{f'<div class="skills"><span class="skills-l">skills</span>{chips}</div>' if chips else ''}
<footer>{"".join(meta)}</footer>
<div class="vermais"><span>perfil completo</span></div>
</article>'''

    sections = []
    for i, (s, label, sub) in enumerate(SQUADS, 1):
        cards = "\n".join(card(a) for a in agents if a["squad"] == s)
        sections.append(f'''<section class="squad" data-squad="{s}" id="{s}">
<h2><span class="idx">{i:02d}</span> {label} <span class="count">{counts[s]} agentes</span></h2>
<p class="squad-sub">{sub}</p>
<div class="agents">{cards}</div>
</section>''')

    n_skills_total = len(skill_names_all)
    n_general_skills = len(general_skill_names)
    totals_rows = "\n".join(
        f'<tr><td class="sqname">{label}</td><td class="n">{counts[s]}</td><td class="n">{skill_counts[s]}</td></tr>'
        for s, label, _ in SQUADS
    )
    totals_table = f'''<table class="totals">
<caption>Totais por squad — gerado de <code>.claude/agents/</code> e <code>.claude/skills/</code></caption>
<thead><tr><th>Squad</th><th>Agentes</th><th>Skills próprias</th></tr></thead>
<tbody>
{totals_rows}
<tr><td class="sqname">Gerais / orquestração <span style="color:var(--mute);font-weight:300">(deep-research, accessibility, team-os…)</span></td><td class="n">—</td><td class="n">{n_general_skills}</td></tr>
<tr class="tot"><td>Total</td><td class="n">{len(agents)}</td><td class="n">{n_skills_total}</td></tr>
</tbody>
</table>'''

    filters = f'<button class="fbtn active" data-f="all">Todos · {len(agents)}</button>' + "".join(
        f'<button class="fbtn" data-f="{s}">{label} · {counts[s]}</button>' for s, label, _ in SQUADS)

    squad_label = {s: label for s, label, _ in SQUADS}

    def agent_js_entry(a):
        persona = a["persona"]
        pname, ptitle = (persona.split("—", 1) + [""])[:2] if "—" in persona else (persona, "")
        pname, ptitle = pname.strip(), ptitle.strip() or persona
        return {
            "role": ptitle, "persona": pname, "squad": squad_label.get(a["squad"], a["squad"]),
            "desc": a["desc"], "bio": a["bio"], "matrix": a["matrix"], "rules": a["rules"],
            "skills": amap.get(a["name"], []),
            "model": a["model"], "effort": a["effort"], "hook": a["hook"], "mcp": a["mcp"],
        }

    agents_json = safe_json({a["name"]: agent_js_entry(a) for a in agents})
    skills_json = safe_json({
        s: {"desc": skills[s]["desc"], "version": skills[s]["version"], "updated": skills[s]["updated"],
            "sections": skills[s]["sections"], "agents": sorted(used_by.get(s, []))}
        for s in skills
    })

    tpl = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "templates",
                            "agents-page.html.tpl")).read()
    page = (tpl.replace("{{FILTERS}}", filters)
               .replace("{{SECTIONS}}", "".join(sections))
               .replace("{{AGENTS_JSON}}", agents_json)
               .replace("{{SKILLS_JSON}}", skills_json)
               .replace("{{TOTALS_TABLE}}", totals_table)
               .replace("{{N_AGENTS}}", str(len(agents)))
               .replace("{{N_SQUADS}}", str(len(SQUADS)))
               .replace("{{N_SKILLS}}", str(len(skills) - 1))  # -1: team-os-creator é interna
               .replace("{{N_OPUS}}", str(opus_n)))
    if CHECK:
        current = open(OUT).read() if os.path.exists(OUT) else None
        if current == page:
            print(f"OK — {OUT} está em dia ({len(agents)} agentes · {len(skills)} skills)")
            sys.exit(0)
        print(f"DESATUALIZADO — {OUT} difere do que seria gerado; rode: python3 {os.path.relpath(__file__, ROOT)}", file=sys.stderr)
        sys.exit(1)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w").write(page)
    print(f"OK → {OUT} ({len(page)//1024} KB · {len(agents)} agentes · {len(photos)} fotos · {len(skills)} skills)")


if __name__ == "__main__":
    build()
