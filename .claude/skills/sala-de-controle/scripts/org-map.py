#!/usr/bin/env python3
"""org-map.py — mapa da organização de pastas: negócios → projetos → squads, e o que está fora do padrão (READ-ONLY).

Padrão esperado (o que o team-os entende):
  <raiz>/
  ├── 0 | Centro de Treinamento         ← CT: fonte do pack e casa da Sala de Controle
  │                                       (skill sala-de-controle; memória em docs/smart-memory/sala-de-controle/)
  ├── <Negócio>/                        ← contêiner: sem .claude/ nem .git próprios
  │   └── <Negócio> | <Projeto>         ← projeto: .claude/agents (squad) + docs/smart-memory
  ├── <Grupo>/  (ex.: Outros)            ← reúne negócios menores, um nível abaixo
  │   ├── <Negócio>/<Negócio> | <Projeto>
  │   └── <Negócio> | <Projeto>          ← projeto direto no grupo, com nome próprio
  └── …

A Sala de Controle mora no CT. Pasta fora do CT com a skill sala-de-controle, com a antiga
maestri-os ou com "Sala de Controle" no nome é uma Sala antiga → achado SALA_ANTIGA, com o
comando de migração (migrate-sala-to-ct.sh, simulação por padrão).

Nunca move, renomeia nem escreve nada — só aponta e sugere. Quem executa é o usuário (ou o
team-os-creator, com OK explícito).

Usage: org-map.py [raiz] [--tree] [--json]
  raiz default: pai da pasta atual (rodando no CT, a raiz é a pasta-mãe do CT).
Saída padrão (TSV): ROOT=…, uma linha NODE=… por pasta, uma linha FINDING=… por problema,
e SUMMARY=… no fim. --tree imprime a árvore legível + os achados.
"""
import json, os, sys, unicodedata

# macOS: nomes de pasta vêm do disco em NFD ('ã' decomposto) e o cwd das sessões em NFC.
# Tudo que é comparado ou exibido passa por nfc() — senão sessão e projeto nunca batem.
def nfc(s):
    return unicodedata.normalize("NFC", s or "")

ARGS = sys.argv[1:]
TREE = "--tree" in ARGS
AS_JSON = "--json" in ARGS
POS = [a for a in ARGS if not a.startswith("--")]
ROOT = nfc(os.path.abspath(POS[0]) if POS else os.path.dirname(os.getcwd()))
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
        "path": nfc(path),
        "name": nfc(os.path.basename(path)),
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

def is_business_dir(i, path):
    """Pasta de negócio dentro de um grupo: não é projeto e tem filho '<pasta> | …'."""
    if kind_of(i) != "pasta":
        return False
    return any(nfc(os.path.basename(c)).startswith(i["name"] + " |") for c in children(path))


containers = {}
for top in children(ROOT):
    i = info(top)
    k = kind_of(i)
    # GRUPO (ex.: "Outros/"): pasta da raiz que reúne negócios — "Outros/Sahaj/Sahaj | Marketing".
    # Pode ter também projetos diretos com nome próprio ("Outros/Céu de Gaia | Site").
    if k == "pasta" and any(is_business_dir(info(s), s) for s in children(top)):
        i["kind"], i["level"], i["business"] = "grupo", 0, ""
        nodes.append(i)
        for s in [info(x) for x in children(top)]:
            if is_business_dir(s, s["path"]):
                s["kind"], s["level"], s["business"] = "negocio", 1, ""
                containers[s["name"]] = s["path"]
                nodes.append(s)
                for g in [info(x) for x in children(s["path"])]:
                    g["kind"], g["level"], g["business"] = kind_of(g), 2, s["name"]
                    nodes.append(g)
            else:
                sk = kind_of(s)
                nm = s["name"]
                s["kind"], s["level"] = sk, 1
                s["business"] = nm.split(" | ")[0] if " | " in nm else i["name"]
                nodes.append(s)
        continue
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
CT_PATH = next((n["path"] for n in nodes if n["is_ct"]), os.path.join(ROOT, "0 | Centro de Treinamento"))
MIGRATE = os.path.join(CT_PATH, ".claude", "skills", "team-os-creator", "scripts", "migrate-sala-to-ct.sh")
salas = [n for n in nodes if n["kind"] == "sala"]          # Salas antigas (fora do CT)
for n in nodes:
    nm, biz = n["name"], n["business"]
    if n["kind"] == "sala":
        what = ("pasta de Sala de Controle fora do CT"
                + (" (skill sala-de-controle)" if n["sala"] else "")
                + (" (skill maestri-os, que saiu do pack)" if n["maestri"] else "")
                + ("" if n["sala"] or n["maestri"] else " (sem skill)")
                + " — a Sala agora mora no CT")
        add_finding("SALA_ANTIGA", nm, what,
                    f'migrar para o CT: bash "{MIGRATE}" "{n["path"]}" (simulação; --apply executa)')
        continue
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
    if n["level"] >= 1 and n["kind"] == "projeto" and biz and not nm.startswith(biz + " | "):
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
    if n["kind"] == "negocio":
        kids = [c for c in nodes if c["business"] == nm and c["level"] == n["level"] + 1]
        if not kids:
            add_finding("NEGOCIO_VAZIO", nm, "pasta de negócio sem projetos", "remover ou criar o primeiro projeto")

summary = {
    "negocios": sum(1 for n in nodes if n["kind"] == "negocio"),
    "projetos": sum(1 for n in nodes if n["kind"] == "projeto" and not n["is_ct"]),
    "salas_antigas": len(salas), "achados": len(findings),
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
        elif n["kind"] == "grupo":
            desc = "grupo de negócios"
        elif n["kind"] == "ct":
            desc = "CT · fonte do pack e casa da Sala de Controle"
        elif n["kind"] == "sala":
            desc = "Sala de Controle ANTIGA · " + ("sala-de-controle" if n["sala"] else "maestri-os" if n["maestri"] else "sem skill") + " · migrar para o CT"
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
