#!/usr/bin/env python3
"""Aplica as adições de Graphify/God Nodes a todos os projetos."""

import os
import shutil
from pathlib import Path

BASE = Path("/Users/joaoramos/Desktop/Projetos/Centro de Treinamento/claude")
MASTER_AGENTS = BASE / ".claude/agents"
MASTER_SKILLS = BASE / ".claude/skills"

DEV_PROJECTS = [
    Path("/Users/joaoramos/Desktop/Projetos/Projetos/ora"),
    Path("/Users/joaoramos/Desktop/Projetos/Projetos/viva-america"),
    Path("/Users/joaoramos/Desktop/Projetos/Sistemas/rev-os"),
    Path("/Users/joaoramos/Desktop/Projetos/Sistemas/team-os"),
    Path("/Users/joaoramos/Desktop/Projetos/Sistemas/work-os"),
]

SITES_PROJECTS = [
    Path("/Users/joaoramos/Desktop/Projetos/Projetos/joao-guirunas-site"),
    Path("/Users/joaoramos/Desktop/Projetos/Projetos/joao-guirunas-social"),
]

ALL_PROJECTS = DEV_PROJECTS + SITES_PROJECTS


def patch_file(path: Path, old: str, new: str, label: str) -> bool:
    if not path.exists():
        print(f"  SKIP (não existe): {path.name}")
        return False
    content = path.read_text()
    if old not in content:
        if new.split('\n')[1] in content:
            print(f"  JÁ APLICADO: {path.name} — {label}")
            return False
        print(f"  ÂNCORA NÃO ENCONTRADA: {path.name} — {label}")
        return False
    path.write_text(content.replace(old, new, 1))
    print(f"  OK: {path.name} — {label}")
    return True


# ── 1. Copiar team-os/SKILL.md para todos os projetos ───────────────────────

SKILL_SRC = MASTER_SKILLS / "team-os/SKILL.md"

print("\n=== team-os/SKILL.md ===")
for project in ALL_PROJECTS:
    dest = project / ".claude/skills/team-os/SKILL.md"
    if dest.exists():
        shutil.copy2(SKILL_SRC, dest)
        print(f"  COPIADO: {project.name}")
    else:
        print(f"  SKIP (sem team-os skill): {project.name}")


# ── 2. dev-analyst: adicionar verificação de GRAPH_REPORT ───────────────────

ANALYST_OLD = """\
## Auditoria de projeto (*discover)

Quando acionado pelo Chief para discovery, ler o codebase e documentar o que encontra — sem pesquisa externa, apenas leitura do que existe.

**1. Mapear tech stack**
```bash
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || cat go.mod 2>/dev/null
cat .nvmrc .node-version 2>/dev/null
```
Identificar: linguagem, framework principal, dependências-chave, versões.

**2. Mapear convenções de código**
Ler arquivos de configuração:
```bash
cat .eslintrc* tsconfig.json prettier.config.* .editorconfig 2>/dev/null | head -60
```
Identificar: estilo de código, regras de lint, padrões de import, convenções de nomenclatura.

**3. Ler README e docs existentes**
```bash
cat README.md CONTRIBUTING.md docs/*.md 2>/dev/null | head -100
```"""

ANALYST_NEW = """\
## Auditoria de projeto (*discover)

Quando acionado pelo Chief para discovery, documentar o codebase — sem pesquisa externa, apenas leitura do que existe.

**1. Verificar se GRAPH_REPORT.md está disponível**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "GRAPH_OK" || echo "GRAPH_MISSING"
```
- **Se `GRAPH_OK`**: ler `graphify-out/GRAPH_REPORT.md` PRIMEIRO. Ele revela dependências reais via AST — use para identificar tech stack (quais libs aparecem nos imports), convenções de nomenclatura (padrões detectados nos módulos) e estrutura do projeto. Complement com as leituras abaixo apenas para preencher lacunas.
- **Se `GRAPH_MISSING`**: explorar manualmente via leitura de arquivos.

**2. Mapear tech stack**
```bash
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || cat go.mod 2>/dev/null
cat .nvmrc .node-version 2>/dev/null
```
Identificar: linguagem, framework principal, dependências-chave, versões.

**3. Mapear convenções de código**
Ler arquivos de configuração:
```bash
cat .eslintrc* tsconfig.json prettier.config.* .editorconfig 2>/dev/null | head -60
```
Identificar: estilo de código, regras de lint, padrões de import, convenções de nomenclatura.

**4. Ler README e docs existentes**
```bash
cat README.md CONTRIBUTING.md docs/*.md 2>/dev/null | head -100
```"""

ANALYST_STEP6_OLD = "**6. Notificar Chief via SendMessage:**"
ANALYST_STEP6_NEW = "**7. Notificar Chief via SendMessage:**"

print("\n=== dev-analyst ===")
for project in DEV_PROJECTS:
    f = project / ".claude/agents/dev-analyst.md"
    patch_file(f, ANALYST_OLD, ANALYST_NEW, "discover + GRAPH_REPORT")
    patch_file(f, ANALYST_STEP6_OLD, ANALYST_STEP6_NEW, "renumerar step 6→7")


# ── 3. dev-architect: GRAPH_REPORT + templates enriquecidos ─────────────────

ARCH_OLD = """\
## Auditoria de projeto (*discover)

Quando acionado pelo Chief para discovery, ler o codebase existente e documentar o que encontra — não redesenhar, não opinar, apenas mapear.

> **Responsabilidade de escopo:** Você produz `modules.md` e `architecture.md`.
> `tech-stack.md` e `conventions.md` são responsabilidade da Lyra (dev-analyst) — não duplicar.

**1. Mapear estrutura de módulos**
```bash
find . -type d -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/.claude/*" | head -40
```
Identificar: quais são os módulos principais, o que cada um faz, como se relacionam.

**2. Identificar padrões arquiteturais**
- Monolito, microserviços, serverless?
- MVC, clean architecture, feature-based?
- Quais camadas existem (api, services, repositories, etc.)?

**3. Produzir `docs/smart-memory/project/modules.md`:**
```markdown
---
title: Mapa de Módulos
type: overview
agent: dev-architect
created: {data}
updated: {data}
tags: [architecture, modules]
related: ["[[architecture]]", "[[../tech-stack]]"]
---

# Mapa de Módulos

## Estrutura
{árvore simplificada dos diretórios principais}

## Módulos

### {nome-do-módulo}
**Path:** `{path}`
**Responsabilidade:** {o que faz}
**Depende de:** {outros módulos}
**Consumido por:** {quem usa}
```

**4. Produzir `docs/smart-memory/project/architecture.md`:**
```markdown
---
title: Arquitetura
type: overview
agent: dev-architect
created: {data}
updated: {data}
tags: [architecture]
related: ["[[modules]]"]
---

# Arquitetura

## Padrão
{monolito / microserviços / etc.}

## Camadas
{lista de camadas com responsabilidades}

## Fluxo principal
```mermaid
{diagrama do fluxo principal da aplicação}
```

## Decisões arquiteturais identificadas
{o que foi encontrado no código que revela decisões de design}
```

**5. Notificar Chief via SendMessage:**
```
SendMessage(team-os, "*discover concluído — modules.md e architecture.md prontos em docs/smart-memory/project/. Resumo: {padrão arquitetural em 1 linha}")
```"""

ARCH_NEW = """\
## Auditoria de projeto (*discover)

Quando acionado pelo Chief para discovery, documentar o codebase — não redesenhar, não opinar, apenas mapear.

> **Responsabilidade de escopo:** Você produz `modules.md` e `architecture.md`.
> `tech-stack.md` e `conventions.md` são responsabilidade da dev-analyst — não duplicar.

**1. Verificar se GRAPH_REPORT.md está disponível**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "GRAPH_OK" || echo "GRAPH_MISSING"
```
- **Se `GRAPH_OK`**: ler `graphify-out/GRAPH_REPORT.md` PRIMEIRO — contém god nodes, clusters e dependency edges com precisão AST. Use como fonte primária; explore arquivos apenas para complementar.
- **Se `GRAPH_MISSING`**: explorar manualmente via `find` e leitura de arquivos-chave.

**2. Identificar padrões arquiteturais**
- Monolito, microserviços, serverless?
- MVC, clean architecture, feature-based?
- Quais camadas existem (api, services, repositories, etc.)?

**3. Produzir `docs/smart-memory/project/modules.md`:**
```markdown
---
title: Mapa de Módulos
type: overview
agent: dev-architect
created: {data}
updated: {data}
graph-updated: {data}
tags: [architecture, modules]
related: ["[[architecture]]", "[[../tech-stack]]"]
---

# Mapa de Módulos

## ⚡ God Nodes
Arquivos com mais dependências — mudança aqui tem impacto amplo. **QA obrigatório sempre que uma story tocar estes arquivos.**

| Arquivo | Conexões | Papel |
|---|---|---|
| `{path}` | {N} | {o que faz e por que é crítico} |
| `{path}` | {N} | {o que faz e por que é crítico} |

> Extraído via AST em {data}. Atualizar após refactors estruturais.

## 📦 Clusters de Módulos
Grupos por dependências reais:

### {nome-do-cluster}
`{arquivo-raiz}` → `{dependente}` → `{dependente}`
**Responsabilidade:** {o que esse cluster faz junto}

## 🗺️ Estrutura e Módulos

{árvore simplificada dos diretórios principais}

### {nome-do-módulo}
**Path:** `{path}`
**Responsabilidade:** {o que faz}
**Depende de:** {outros módulos}
**Consumido por:** {quem usa}
```

**4. Produzir `docs/smart-memory/project/architecture.md`:**
```markdown
---
title: Arquitetura
type: overview
agent: dev-architect
created: {data}
updated: {data}
tags: [architecture]
related: ["[[modules]]"]
---

# Arquitetura

## Padrão
{monolito / microserviços / etc.}

## Camadas
{lista de camadas com responsabilidades}

## Mapa de Dependências Principais
```
{arquivo-a} → {arquivo-b} → {arquivo-c}
{arquivo-x} ← {arquivo-y}
```
> Baseado em análise AST — reflete imports reais, não intenção.

## Fluxo principal
```mermaid
{diagrama do fluxo principal da aplicação}
```

## Decisões arquiteturais identificadas
{o que foi encontrado no código que revela decisões de design}
```

**5. Notificar Chief via SendMessage:**
```
SendMessage(team-os, "*discover concluído — modules.md e architecture.md prontos em docs/smart-memory/project/. God nodes identificados: {N}. Resumo: {padrão arquitetural em 1 linha}")
```"""

print("\n=== dev-architect ===")
for project in DEV_PROJECTS:
    f = project / ".claude/agents/dev-architect.md"
    patch_file(f, ARCH_OLD, ARCH_NEW, "discover + GRAPH_REPORT + templates enriquecidos")


# ── 4. dev-dev-alpha/beta/gamma: step 1.5 God Nodes ────────────────────────

GOD_NODE_ALPHA = """\
**1.5. Verificar impacto em God Nodes**
```bash
grep -A20 "God Nodes" docs/smart-memory/project/modules.md 2>/dev/null | grep "src/"
```
Comparar os arquivos listados nos ACs da story com os God Nodes. **Se houver interseção:** testes unitários obrigatórios (coverage ≥ 80% em código novo) e notificar o lead que QA formal é necessário antes do push.

**2. Atualizar story — início**"""

GOD_NODE_BETA = """\
**1.5. Verificar impacto em God Nodes**
```bash
grep -A20 "God Nodes" docs/smart-memory/project/modules.md 2>/dev/null | grep "src/"
```
Comparar os arquivos mencionados nos ACs com os God Nodes. **Se houver interseção:** testes obrigatórios (coverage ≥ 80% em código novo) e notificar o lead que QA formal é necessário antes do push.

**2. Atualizar story — início**"""

GOD_NODE_GAMMA = """\
**1.5. Verificar impacto em God Nodes**
```bash
grep -A20 "God Nodes" docs/smart-memory/project/modules.md 2>/dev/null | grep "src/"
```
Comparar os arquivos dos ACs com os God Nodes. **Se houver interseção:** testes obrigatórios (coverage ≥ 80% em código novo), definir contrato de integração com cuidado redobrado, e notificar o lead que QA formal é necessário antes do push.

**2. Atualizar story — início**"""

# Âncora comum antes do step 2 em cada agent
STEP2_ANCHOR_ALPHA = "| Nova (dev-dev-alpha) |"
STEP2_ANCHOR_BETA  = "| Rex (dev-dev-beta) |"
STEP2_ANCHOR_GAMMA = "| Sera (dev-dev-gamma) |"

def add_god_node_step(path: Path, anchor_line: str, god_node_block: str, label: str):
    """Insere o bloco God Node antes da linha que contém o anchor."""
    if not path.exists():
        print(f"  SKIP (não existe): {path.name}")
        return
    content = path.read_text()
    if "God Nodes" in content:
        print(f"  JÁ APLICADO: {path.name} — {label}")
        return
    # Encontrar o step 2 e inserir antes dele
    old = "**2. Atualizar story — início**\n```markdown\n| Agente | " + anchor_line
    new = god_node_block + "\n```markdown\n| Agente | " + anchor_line
    if old not in content:
        print(f"  ÂNCORA NÃO ENCONTRADA: {path.name} — {label}")
        return
    path.write_text(content.replace(old, new, 1))
    print(f"  OK: {path.name} — {label}")

print("\n=== dev-dev-alpha ===")
for project in DEV_PROJECTS:
    add_god_node_step(
        project / ".claude/agents/dev-dev-alpha.md",
        "Nova (dev-dev-alpha) |",
        GOD_NODE_ALPHA,
        "step 1.5 god nodes"
    )

print("\n=== dev-dev-beta ===")
for project in DEV_PROJECTS:
    add_god_node_step(
        project / ".claude/agents/dev-dev-beta.md",
        "Rex (dev-dev-beta) |",
        GOD_NODE_BETA,
        "step 1.5 god nodes"
    )

print("\n=== dev-dev-gamma ===")
for project in DEV_PROJECTS:
    add_god_node_step(
        project / ".claude/agents/dev-dev-gamma.md",
        "Sera (dev-dev-gamma) |",
        GOD_NODE_GAMMA,
        "step 1.5 god nodes"
    )


# ── 5. dev-qa: verificação God Nodes + checklist expandido ──────────────────

QA_OLD = """\
## 8-Point QA Checklist

| # | Critério |
|---|---|
| 1 | Code review — patterns, legibilidade, manutenibilidade |
| 2 | Unit tests — coverage adequada, todos passando |
| 3 | Acceptance criteria — todos atendidos |
| 4 | Sem regressões — testes existentes passando |
| 5 | Performance — sem N+1 óbvio, sem blocking calls |
| 6 | Security — input validado, sem stack traces expostos, RLS ativo |
| 7 | Documentação — atualizada se funcionalidade mudou |
| 8 | Contratos de API — atualizados se endpoint mudou |"""

QA_NEW = """\
## Verificação de God Nodes (antes do checklist)

```bash
grep -A20 "God Nodes" docs/smart-memory/project/modules.md 2>/dev/null | grep "src/"
```

Verificar se a story tocou algum God Node. **Se sim:** aplicar checklist expandido (itens marcados com ⚡ abaixo). Se não, checklist padrão.

## 8-Point QA Checklist

| # | Critério | God Node |
|---|---|---|
| 1 | Code review — patterns, legibilidade, manutenibilidade | — |
| 2 | Unit tests — coverage adequada, todos passando | ⚡ coverage ≥ 80% obrigatório |
| 3 | Acceptance criteria — todos atendidos | — |
| 4 | Sem regressões — testes existentes passando | ⚡ verificar dependentes do god node |
| 5 | Performance — sem N+1 óbvio, sem blocking calls | — |
| 6 | Security — input validado, sem stack traces expostos, RLS ativo | — |
| 7 | Documentação — atualizada se funcionalidade mudou | ⚡ atualizar god nodes em modules.md se assinatura mudou |
| 8 | Contratos de API — atualizados se endpoint mudou | — |"""

print("\n=== dev-qa ===")
for project in DEV_PROJECTS:
    f = project / ".claude/agents/dev-qa.md"
    patch_file(f, QA_OLD, QA_NEW, "god node check + checklist expandido")


# ── 6. dev-devops: graphify update no cleanup ────────────────────────────────

DEVOPS_OLD = """\
### *cleanup — Após merge

```bash
git branch --merged main
git branch -d {branch}
git push origin --delete {branch}
git worktree list
git worktree remove {path}  # limpar worktrees dos devs
```

Após cleanup:
```
SendMessage(team-os, "CLEANUP concluído — branch e worktree de feature/{N}-{M}-{descricao} removidos")
```"""

DEVOPS_NEW = """\
### *cleanup — Após merge

```bash
git branch --merged main
git branch -d {branch}
git push origin --delete {branch}
git worktree list
git worktree remove {path}  # limpar worktrees dos devs
```

**Atualizar knowledge graph se houve mudanças estruturais:**
```bash
# Verificar se há novos módulos, arquivos movidos ou dependências alteradas
git diff main --name-only | grep -E "\\.(ts|tsx|js|jsx|py|go)$" | wc -l
```
Se > 10 arquivos alterados ou novos módulos criados:
```bash
graphify update  # re-analisa apenas arquivos alterados (rápido)
```
Notificar team-os para que dev-architect atualize a seção God Nodes de `modules.md` se necessário.

Após cleanup:
```
SendMessage(team-os, "CLEANUP concluído — branch e worktree de feature/{N}-{M}-{descricao} removidos. {graphify update rodado / knowledge graph sem mudanças}")
```"""

print("\n=== dev-devops ===")
for project in DEV_PROJECTS:
    f = project / ".claude/agents/dev-devops.md"
    patch_file(f, DEVOPS_OLD, DEVOPS_NEW, "graphify update no cleanup")


# ── 7. sites-architect: discover section ────────────────────────────────────

SITES_ARCH_OLD = """\
## O que você escreve na smart-memory

- `docs/smart-memory/project/architecture.md` — estrutura do site, routing, stack
- `docs/smart-memory/project/modules.md` — mapa de páginas/componentes
- `docs/smart-memory/decisions/ADR-{N}-{slug}.md` — todo ADR
- `docs/smart-memory/stories/backlog/{N.M}-{slug}.md` — stories novas
- `docs/smart-memory/stories/BACKLOG.md` — índice atualizado"""

SITES_ARCH_NEW = """\
## O que você escreve na smart-memory

- `docs/smart-memory/project/architecture.md` — estrutura do site, routing, stack
- `docs/smart-memory/project/modules.md` — mapa de páginas/componentes (com God Nodes e Clusters quando gerado via Graphify)
- `docs/smart-memory/decisions/ADR-{N}-{slug}.md` — todo ADR
- `docs/smart-memory/stories/backlog/{N.M}-{slug}.md` — stories novas
- `docs/smart-memory/stories/BACKLOG.md` — índice atualizado

## Auditoria de projeto (*discover)

Quando acionado pelo Chief para discovery de um site existente:

**1. Verificar se GRAPH_REPORT.md está disponível**
```bash
test -f graphify-out/GRAPH_REPORT.md && echo "GRAPH_OK" || echo "GRAPH_MISSING"
```
- **Se `GRAPH_OK`**: ler PRIMEIRO — revela quais componentes têm mais dependências (god nodes), clusters de páginas/features relacionadas e imports reais. Use para popular `modules.md` com dados precisos.
- **Se `GRAPH_MISSING`**: explorar manualmente estrutura de páginas e componentes.

**2. Mapear estrutura do site**
```bash
find src/app src/pages -type f -name "*.tsx" 2>/dev/null | head -40
find src/components -type d 2>/dev/null | head -20
```

**3. Produzir `docs/smart-memory/project/modules.md`** com seções:
- `## ⚡ God Nodes` — componentes/pages mais importados (se graphify disponível)
- `## 📦 Clusters` — grupos de páginas/features relacionadas
- `## 🗺️ Estrutura` — rotas, layouts, componentes principais

**4. Produzir `docs/smart-memory/project/architecture.md`** com stack, routing strategy, padrões de componentes.

**5. Notificar Chief:**
```
SendMessage(team-os, "*discover concluído — modules.md e architecture.md prontos. God nodes: {N}. Stack: {resumo}")
```"""

print("\n=== sites-architect ===")
for project in SITES_PROJECTS:
    f = project / ".claude/agents/sites-architect.md"
    patch_file(f, SITES_ARCH_OLD, SITES_ARCH_NEW, "discover section + god nodes")


# ── 8. sites-devops: graphify update no cleanup ──────────────────────────────

SITES_DEVOPS_OLD = """\
## Cleanup após merge

```bash
git branch -d {branch}
git push origin --delete {branch}
git worktree list
git worktree remove {path}
```

## Regras absolutas"""

SITES_DEVOPS_NEW = """\
## Cleanup após merge

```bash
git branch -d {branch}
git push origin --delete {branch}
git worktree list
git worktree remove {path}
```

**Atualizar knowledge graph se houve mudanças estruturais:**
```bash
git diff main --name-only | grep -E "\\.(ts|tsx|js|jsx)$" | wc -l
```
Se > 10 arquivos alterados ou novos componentes/páginas criados:
```bash
graphify update
```
Notificar team-os para que sites-architect atualize God Nodes em `modules.md` se necessário.

## Regras absolutas"""

print("\n=== sites-devops ===")
for project in SITES_PROJECTS:
    f = project / ".claude/agents/sites-devops.md"
    patch_file(f, SITES_DEVOPS_OLD, SITES_DEVOPS_NEW, "graphify update no cleanup")


print("\n✅ Propagação concluída.")
