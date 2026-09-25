#!/usr/bin/env python3
"""org-map.py — mapa da organização de pastas: negócios → projetos → squads, e o que está fora do padrão (READ-ONLY).

Padrão esperado (o que o team-os entende):
  <raiz>/
  ├── 0 | Centro de Treinamento         ← CT (fonte do pack; só existe na máquina do mantenedor)
  ├── 1 | Sala de Controle              ← UMA pasta isolada com a skill sala-de-controle (sem agentes)
  ├── <Negócio>/                        ← contêiner: sem .claude/ nem .git próprios
  │   ├── <Negócio> | <Projeto>         ← projeto: .claude/agents (squad) + docs/smart-memory
  │   └── <Negócio> | Sala de Controle  ← opcional: maestri-os (modo Maestri) daquele negócio
  └── …

Nunca move, renomeia nem escreve nada — só aponta e sugere. Quem executa é o usuário (ou o
team-os-creator, com OK explícito).

Usage: org-map.py [raiz] [--tree] [--json]
  raiz default: pai da pasta atual (a Sala de Controle mora na raiz).
Saída padrão (TSV): ROOT=…, uma linha NODE=… por pasta, uma linha FINDING=… por problema,
e SUMMARY=… no fim. --tree imprime a árvore legível + os achados.
"""
import json, os, sys

ARGS = sys.argv[1:]
TREE = "--tree" in ARGS
AS_JSON = "--json" in ARGS
POS = [a for a in ARGS if not a.startswith("--")]
ROOT = os.path.abspath(POS[0]) if POS else os.path.dirname(os.getcwd())
SKIP = {"node_modules", ".git", ".claude", "docs"}


def lc(s):
    return s.lower()


def is_sala_name(n):
    n = lc(n)
    return any(k in n for k in ("sala de controle", "sala-de-controle", "control room", "control-room"))


def is_ct(path):
    return os.path.isdir(os.path.join(path, ".claude", "skills", "team-os-creator"))


def info(path):
    ad = os.path.join(path, ".claude", "agents")
    agents = [f[:-3] for f in os.listdir(ad) if f.endswith(".md")] if os.path.isdir(ad) else []
    sk = os.path.join(path, ".claude", "skills")
    return {
        "path": path,
        "name": os.path.basename(path),
        "agents": len(agents),
        "squads": sorted({a.split("-")[0] for a in agents}),
        "team_os": os.path.isdir(os.path.join(sk, "team-os")),
        "sala": os.path.isdir(os.path.join(sk, "sala-de-controle")),
        "maestri": os.path.isdir(os.path.join(sk, "maestri-os")),
        "smart_memory": os.path.isfile(os.path.join(path, "docs", "smart-memory", "INDEX.md")),
        "is_project": os.path.isdir(os.path.join(path, ".claude")) or os.path.isdir(os.path.join(path, ".git"))
                      or os.path.isdir(os.path.join(path, "docs", "smart-memory")),
        "is_ct": is_ct(path),
    }


def children(path):
    try:
        return sorted(os.path.join(path, n) for n in os.listdir(path)
                      if not n.startswith(".") and n not in SKIP and os.path.isdir(os.path.join(path, n)))
    except Exception:
        return []


def kind_of(i):
    if i["is_ct"]:
        return "ct"
    if i["sala"] or i["maestri"] or is_sala_name(i["name"]):
        return "sala"
    if i["is_project"]:
        return "projeto"
    return "pasta"


nodes, findings = [], []


def add_finding(code, where, what, suggestion):
    findings.append({"code": code, "where": where, "what": what, "suggestion": suggestion})


if not os.path.isdir(ROOT):
    print(f"ERROR=not_a_dir|PATH={ROOT}", file=sys.stderr)
    sys.exit(1)

containers = {}
for top in children(ROOT):
    i = info(top)
    k = kind_of(i)
    if k == "pasta":
        subs = [info(s) for s in children(top)]
        if any(s["is_project"] or is_sala_name(s["name"]) for s in subs) or not subs:
            k = "negocio"
            containers[i["name"]] = top
    i["kind"], i["level"], i["business"] = k, 0, ""
    nodes.append(i)
    if k == "negocio":
        for s in [info(x) for x in children(top)]:
            sk = kind_of(s)
            s["kind"], s["level"], s["business"] = sk, 1, i["name"]
            nodes.append(s)
            # um nível a mais (negócio → área → projeto) ainda é lido, mas marcado
            if sk == "pasta":
                for g in [info(x) for x in children(s["path"])]:
                    gk = kind_of(g)
                    if gk in ("projeto", "sala"):
                        g["kind"], g["level"], g["business"] = gk, 2, i["name"]
                        nodes.append(g)
                        add_finding("NIVEL_EXTRA", g["name"],
                                    f"projeto dois níveis abaixo do negócio ({i['name']}/{s['name']}/{g['name']})",
                                    f"trazer para '{i['name']}/{i['name']} | {g['name'].split(' | ')[-1]}' "
                                    "— o team-os e a Sala de Controle esperam negócio → projeto")

# ── Achados ──────────────────────────────────────────────────────────────────
salas = [n for n in nodes if n["sala"] and not n["is_ct"]]
maestris = [n for n in nodes if n["maestri"] and not n["is_ct"]]
for n in nodes:
    nm, biz = n["name"], n["business"]
    if n["kind"] == "projeto" and n["level"] == 0:
        prefix = nm.split(" | ")[0] if " | " in nm else ""
        if prefix and prefix in containers:
            add_finding("PROJETO_SOLTO", nm, f"projeto na raiz, mas existe o negócio '{prefix}'",
                        f"mover para '{prefix}/{nm}'")
        elif prefix:
            add_finding("PROJETO_SOLTO", nm, f"projeto na raiz sem pasta de negócio",
                        f"criar '{prefix}/' e mover para '{prefix}/{nm}'")
        else:
            add_finding("PROJETO_SOLTO", nm, "projeto na raiz, fora de um negócio e sem prefixo de negócio",
                        f"decidir o negócio dono e mover para '<Negócio>/<Negócio> | {nm}'")
    if n["level"] >= 1 and n["kind"] in ("projeto", "sala") and biz and not nm.startswith(biz + " | "):
        add_finding("NOME_FORA_DO_PADRAO", nm, f"dentro de '{biz}' mas o nome não começa com '{biz} | '",
                    f"renomear para '{biz} | {nm}'")
    if n["kind"] == "projeto" and n["agents"] == 0 and not n["is_ct"]:
        add_finding("SEM_SQUAD", nm, "projeto sem nenhum agente instalado",
                    "rodar /team-os-creator *install com a squad da categoria (ou confirmar que não precisa)")
    if n["kind"] == "projeto" and n["agents"] > 0 and not n["smart_memory"]:
        add_finding("SEM_SMART_MEMORY", nm, "squad instalada mas smart-memory não criada",
                    "abrir uma sessão na pasta e rodar /team-os (o Discovery cria a smart-memory)")
    if n["kind"] == "projeto" and n["agents"] > 0 and not n["team_os"]:
        add_finding("SEM_TEAM_OS", nm, "tem agentes mas não tem a skill team-os",
                    "rodar /team-os-creator *propagate (team-os é obrigatória)")
    if n["kind"] == "sala" and not (n["sala"] or n["maestri"]):
        add_finding("SALA_VAZIA", nm, "pasta de Sala de Controle sem skill instalada",
                    "instalar sala-de-controle (--squads none --extra-skills sala-de-controle) "
                    "ou maestri-os (modo Maestri)")
    if n["kind"] == "sala" and n["agents"] > 0:
        add_finding("SALA_COM_AGENTES", nm, f"Sala de Controle com {n['agents']} agentes",
                    "Sala de Controle não tem agentes por design — mover a squad para um projeto")
    if n["sala"] and n["maestri"] and not n["is_ct"]:
        add_finding("SALA_DUPLA", nm, "sala-de-controle e maestri-os na mesma pasta",
                    "escolher um modo por pasta (Claude sessions ou Maestri)")
    if n["kind"] == "negocio":
        kids = [c for c in nodes if c["business"] == nm and c["level"] == 1]
        if not kids:
            add_finding("NEGOCIO_VAZIO", nm, "pasta de negócio sem projetos", "remover ou criar o primeiro projeto")
empty_salas = [n for n in nodes if n["kind"] == "sala" and not (n["sala"] or n["maestri"])]
if not salas and empty_salas:
    pass  # SALA_VAZIA já aponta a pasta pronta para receber a skill
elif not salas:
    add_finding("SALA_AUSENTE", "(raiz)", "nenhuma pasta com a skill sala-de-controle",
                f"criar '{ROOT}/1 | Sala de Controle' e instalar só a skill sala-de-controle")
elif len(salas) > 1:
    add_finding("SALAS_MULTIPLAS", ", ".join(s["name"] for s in salas),
                f"{len(salas)} pastas com sala-de-controle — ela já enxerga todas as sessões da máquina",
                "manter uma só, na raiz ('1 | Sala de Controle')")
elif salas[0]["level"] > 0:
    add_finding("SALA_FORA_DA_RAIZ", salas[0]["name"], "a sala-de-controle está dentro de um negócio",
                "mover para a raiz ('1 | Sala de Controle') — ela atende todos os negócios")

summary = {
    "negocios": sum(1 for n in nodes if n["kind"] == "negocio"),
    "projetos": sum(1 for n in nodes if n["kind"] == "projeto" and not n["is_ct"]),
    "salas": len(salas), "maestri": len(maestris), "achados": len(findings),
}

if AS_JSON:
    print(json.dumps({"root": ROOT, "nodes": nodes, "findings": findings, "summary": summary},
                     ensure_ascii=False, indent=1))
elif TREE:
    print(f"{ROOT}/")
    for n in nodes:
        ind = "│   " * n["level"]
        if n["kind"] == "negocio":
            desc = "negócio"
        elif n["kind"] == "ct":
            desc = "CT (fonte do pack)"
        elif n["kind"] == "sala":
            desc = "Sala de Controle · " + ("sala-de-controle" if n["sala"] else "maestri-os" if n["maestri"] else "vazia")
        elif n["kind"] == "projeto":
            desc = (f"{n['agents']} agentes · {','.join(n['squads']) or 'sem squad'}"
                    + ("" if n["smart_memory"] else " · sem smart-memory"))
        else:
            desc = "pasta"
        print(f"{ind}├── {n['name']}  ({desc})")
    print()
    if findings:
        print(f"Fora do padrão ({len(findings)}):")
        for f in findings:
            print(f"  • [{f['code']}] {f['where']} — {f['what']}\n      → {f['suggestion']}")
    else:
        print("Organização no padrão — nada a sugerir.")
else:
    print(f"ROOT={ROOT}")
    for n in nodes:
        print("\t".join([f"NODE={n['name']}", f"KIND={n['kind']}", f"LEVEL={n['level']}",
                         f"BUSINESS={n['business']}", f"AGENTS={n['agents']}",
                         f"SQUADS={','.join(n['squads'])}", f"SMART_MEMORY={int(n['smart_memory'])}",
                         f"SALA={int(n['sala'])}", f"MAESTRI={int(n['maestri'])}", f"PATH={n['path']}"]))
    for f in findings:
        print("\t".join([f"FINDING={f['code']}", f"WHERE={f['where']}", f"WHAT={f['what']}",
                         f"SUGGESTION={f['suggestion']}"]))
    print("SUMMARY=" + " ".join(f"{k}:{v}" for k, v in summary.items()))
