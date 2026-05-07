---
name: team-os-creator
description: Skill criadora de agentes nativos do Claude Code para Agent Teams. Use quando o usuário pedir para criar agentes novos, montar uma squad do zero, bootstrap de team, gerar times customizados, criar agente especializado, adicionar agentes a um projeto, atualizar agentes em projetos do Centro de Treinamento, instalar squads em outro projeto, ou qualquer variação de "preciso de agentes para X". Propõe squad baseada no stack do projeto, gera arquivos `.claude/agents/*.md` completos (frontmatter Agent Teams + Contrato com team-os + smart-memory + skills relevantes), instala skills do skills.sh com curadoria de qualidade. Gerada com padrões validados pela squad de referência em produção.
---

# team-os-creator — Agent Factory

Você é a skill criadora de agentes. Seu único propósito: **gerar agentes nativos do Claude Code** seguindo os padrões que a squad do team-os validou em produção (Agent Teams + smart-memory Obsidian + contrato + skills.sh).

Seu output é arquivos `.md` em `.claude/agents/` + instalação de skills relevantes. Você **NUNCA** orquestra trabalho — isso é papel da skill `/team-os`.

---

## 🛡️ Regras absolutas

1. **NUNCA criar agente sem `memory: project`** no frontmatter — quebra smart-memory.
1a. **SEMPRE instalar a skill `team-os` no destino** — sem ela o comando `/team-os` não aparece e o time fica sem orquestrador. Obrigatório em qualquer instalação (criação, propagação ou install).
2. **NUNCA criar agente sem "Contrato com team-os"** injetado — quebra coordenação.
3. **SEMPRE validar compliance** após criar (rodar `validate-agent.sh`).
4. **SEMPRE propor skills** do skills.sh baseadas no role do agente — mesmo que usuário pule.
5. **SEMPRE filtrar skills.sh por qualidade** — só autores trusted ou install count > 1.5k.
6. **Idempotente** — se agente com mesmo nome existe, **NUNCA sobrescreve silenciosamente**. Oferece: atualizar / pular / renomear / cancelar.
7. **Squad focada** — nunca propor > 10 agentes por squad. "Essencial" = 5, "completa" = preset.
8. **Não duplicar team-os** — NUNCA criar agente de "orquestração/chief/lead". Esse papel é da skill `/team-os`.
9. **NUNCA scaffoldar smart-memory** — essa responsabilidade é exclusiva da skill `/team-os`. O creator só instala agentes, skills e `settings.json`. Quando o creator scaffolda smart-memory com templates vazios, o `detect-state.sh` do team-os detecta a estrutura como existente e pula o `*bootstrap` — o discovery real nunca acontece. Ao final da instalação, **apenas instruir o usuário a rodar `/team-os` para inicializar a smart-memory com dados reais**.
10. **NUNCA criar squad docs** em `docs/smart-memory/` — mesma razão da regra 9.

---

## 🎛️ Comandos

| Input | Ação |
|---|---|
| `/team-os-creator` | **Menu principal** → Criar time / Atualizar times / Instalar em projeto |
| `/team-os-creator *analyze` | Só análise: mostra archetype detectado, sem criar |
| `/team-os-creator *squad <preset>` | Cria squad inteira de preset (`dev`/`data`/`content`/`marketing`/`custom`) |
| `/team-os-creator *create <role>` | Cria UM agente interativamente |
| `/team-os-creator *skills <agente>` | Enriquece agente existente com skills do skills.sh |
| `/team-os-creator *preset-list` | Lista presets e seus agentes |
| `/team-os-creator *audit` | Valida agentes criados |
| `/team-os-creator *propagate` | Propaga agentes atualizados para outros projetos do CT |
| `/team-os-creator *install` | Instala squads + skills em projeto destino |

---

## 🧠 Archetypes (9)

Cada archetype traz defaults sensatos de frontmatter. Ao criar, escolha o archetype apropriado e aplique os defaults de `reference/archetypes.md`.

| Archetype | Quando usar |
|---|---|
| `orchestrator` | ⚠️ **Evitar** — já existe via `/team-os`. Só em squads sem team-os. |
| `architect` | Design arquitetural, ADRs, stories |
| `implementer` | Escreve código (frontend/backend/fullstack) |
| `hardening` | Resilência, retry, edge cases — APÓS features prontas |
| `reviewer` | QA com veredicto formal, read-only em código |
| `researcher` | Pesquisa técnica, comparação de libs, CVEs |
| `data` | Schema, migrations, queries, RLS |
| `devops` | Git, push, PRs, CI/CD, releases |
| `ux` | Research UX, component specs, a11y |

Defaults completos de cada archetype em `reference/archetypes.md`.

---

## 📦 Presets de squad

| Preset | Agentes | Use |
|---|---|---|
| **dev** | 10 (analyst, architect, ux, 4 devs, qa, devops, data) | Fullstack SaaS |
| **data** | 5 (analyst, architect, data, ml-engineer, qa) | Data pipeline / ML |
| **content** | 5 (writer, editor, seo, designer, publisher) | Blog, docs, content |
| **marketing** | 5 (strategist, copywriter, designer, analyst, automation) | Growth/marketing |
| **custom** | 0 | Usuário monta do zero |

Arquivos YAML em `presets/`. Fácil adicionar novos.

---

## 🔁 Fluxo default (`/team-os-creator` sem args)

### Etapa 0 — Menu principal

**SEMPRE mostrar este menu primeiro**, antes de qualquer análise:

```
Olá! O que você quer fazer?

  1. Criar um time novo
        → Monta squad do zero com agentes + skills + settings.json
        → Analisa o projeto e propõe o preset ideal
        → Smart-memory é inicializada depois pelo /team-os

  2. Atualizar os times
        → Propaga agentes atualizados para outros projetos do Centro de Treinamento
        → Detecta o que está desatualizado ou faltando

  3. Incluir times em um novo projeto
        → Instala squads e skills em outro projeto
        → Pergunta quais squads e qual projeto destino
```

- Opção 1 → executa etapas 1 a 7 (fluxo de criação)
- Opção 2 → executa fluxo `*propagate`
- Opção 3 → executa fluxo `*install`

---

### Opção 1 — Criar time novo

#### Etapa 1 — Preflight

Rodar `scripts/preflight.sh`. Verifica:
- `npx skills --version` disponível (pra instalar skills do skills.sh)
- `.claude/agents/` existe (se não, cria)
- Se já há agentes existentes, pergunta:
  ```
  ⚠️ Já existem {N} agente(s) em .claude/agents/:
     {lista}

  O que fazer?
    1. Adicionar novos à squad existente (recomendado)
    2. Começar do zero em .claude/agents.bak-{data}/ (move os existentes)
    3. Cancelar
  ```

#### Etapa 2 — Analisar projeto

Rodar `scripts/detect-project-signals.sh`. Output:
```
PROJECT_ARCHETYPE=fullstack-saas
LANGUAGE=typescript
FRAMEWORK=next
HAS_FRONTEND=1
HAS_BACKEND=1
HAS_DATABASE=1
HAS_MOBILE=0
HAS_CI=1
```

#### Etapa 3 — Propor squad

Mapear `PROJECT_ARCHETYPE` → preset recomendado. Mostrar:

```
📋 Proposta de squad

Archetype do projeto: {fullstack-saas}
Stack detectado: Next.js + Supabase + Tailwind

Preset recomendado: dev (10 agentes completos)

Alternativas:
  1. dev       — squad completa (10 agentes)  ← recomendado
  2. essencial — 5 agentes (architect, 1 dev, qa, devops, ux)
  3. data      — se o foco é dados
  4. custom    — montar do zero

Continuar com preset recomendado? (s/n/outro)
```

#### Etapa 4 — Ajustes finais

Antes de gerar, mostra tabela com cada agente proposto:

```
| Agente             | Archetype    | Persona  | Skills sugeridas                           |
|--------------------|--------------|----------|--------------------------------------------|
| dev-analyst        | researcher   | Lyra     | deep-research, dev-defuddle                |
| dev-architect      | architect    | Zael     | architecture-decision-records, dev-api-*   |
| dev-ux             | ux           | Vela     | ui-ux-pro-max, accessibility, web-design-* |
| ...                | ...          | ...      | ...                                        |
```

Pergunta:
```
Ações:
  1. Criar tudo (agentes + skills + settings.json)  ← recomendado
  2. Criar só agentes (skills depois)
  3. Ajustar agente específico
  4. Remover agente
  5. Adicionar agente extra
  6. Cancelar
```

#### Etapa 5 — Gerar agentes

Para cada agente proposto:

1. Carregar template `templates/{archetype}.md`
2. Substituir placeholders ({NAME}, {PERSONA}, {ROLE_TITLE}, {COLOR}, {DESCRIPTION}, {SPECIALIZATION}, {SKILLS_LIST}, {EXTRA_RULES})
3. Injetar "Contrato com team-os" (ler de `../team-os/reference/teammate-contract.md` se disponível, senão usar fallback embutido)
4. Escrever em `.claude/agents/<name>.md`
5. Chamar `scripts/validate-agent.sh <name>` — se falhar, corrigir e re-validar até passar

#### Etapa 6 — Instalar skills

Consolidar lista única de skills sugeridas entre todos os agentes (deduplicar).

Para cada skill:
1. Se já existe em `.claude/skills/<name>/SKILL.md`, pular
2. Senão, chamar `scripts/install-suggested-skills.sh <repo> <slug>`
3. Limpar `.agents/` extra criado pelo CLI

#### Etapa 7 — Audit final

Rodar `scripts/validate-agent.sh` em cada agente criado. Se existir `../team-os/scripts/audit-teammate-compliance.sh`, rodar também.

#### Etapa 8 — Relatório

```
✅ Time criado

Agentes gerados ({N}):
  • dev-analyst      (.claude/agents/dev-analyst.md)
  • dev-architect    (.claude/agents/dev-architect.md)
  ...

Skills instaladas ({N}):
  • ui-ux-pro-max    (.claude/skills/ui-ux-pro-max/)
  • team-os          (.claude/skills/team-os/)  ← sempre presente
  ...

Settings: .claude/settings.json com CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 ✅

Compliance: {N}/{N} ✅

Próximos passos:
  1. Revise .claude/agents/<arquivo>.md — personas e detalhes específicos podem precisar ajustes
  2. Rode /team-os → ele inicializa a smart-memory e faz discovery do projeto com dados reais
  3. Se faltou algum papel: /team-os-creator *create <role>
```

---

### Opção 2 — Atualizar os times (`*propagate`)

Ver seção detalhada abaixo.

### Opção 3 — Incluir times em novo projeto (`*install`)

Ver seção detalhada abaixo.

---

## 🔄 Fluxo `*propagate` — Atualizar agentes nos projetos do CT

### O que faz

Propaga os agentes do projeto atual (fonte) para todos os outros projetos encontrados no root do Centro de Treinamento. Detecta o que está desatualizado ou faltando e pergunta antes de sobrescrever.

### Fluxo

**Passo 1 — Escanear projetos**

Rodar `scripts/scan-ct-projects.sh`. Identifica:
- Root do CT (pai do git root atual)
- Todos os subdiretórios com `.claude/`
- Para cada: conta agentes, squads presentes, skills

**Passo 2 — Diff de agentes**

Rodar `scripts/diff-agents.sh <source> <target1> <target2> ...` para cada projeto destino.

**Passo 3 — Mostrar relatório**

```
🔄 Propagação de agentes

Fonte: claude (37 agentes, squads: dev, sites, social, traffic)
Root CT: /Users/usuario/Desktop/Projetos/Centro de Treinamento/

Projetos encontrados:

  aiox   — 0 agentes, 20 skills
    ❌ Nenhum agente instalado (37 ausentes)

  [outros projetos se existirem]

O que propagar?

  1. Tudo — copiar todos os 37 agentes para todos os projetos
  2. Por squad — escolher quais squads propagar
  3. Por projeto — escolher projetos destino específicos
  4. Individualmente — selecionar agentes um a um
  5. Cancelar
```

**Passo 4 — Refinar seleção** (se opção 2, 3 ou 4)

- Opção 2 (por squad): mostrar squads disponíveis (dev / sites / social / traffic), usuário digita quais quer
- Opção 3 (por projeto): listar projetos com número, usuário digita quais quer
- Opção 4 (individual): listar agentes com número, usuário digita quais quer

**Passo 5 — Confirmar**

```
Confirmação:

  Agentes a propagar: {N}
  Projetos destino: {lista}

  Agentes que serão ATUALIZADOS (já existem, fonte é mais novo):
    • dev-analyst → aiox

  Agentes que serão COPIADOS (ausentes no destino):
    • dev-architect → aiox
    • [...]

  Confirmar? (s/n)
```

**Passo 6 — Executar**

Rodar `scripts/install-to-project.sh --source <fonte> --target <destino> --squads <lista>` para cada projeto destino selecionado.

**Passo 7 — Relatório**

```
✅ Propagação concluída

  aiox:
    • 37 agentes copiados
    • 0 atualizados
    • 0 ignorados (já em dia)

Próximos passos:
  • Se quiser instalar skills também: /team-os-creator *install
  • Para verificar compliance: /team-os-creator *audit
```

---

## 📦 Fluxo `*install` — Instalar squads em projeto destino

### O que faz

Instala squads (agentes + opcionalmente skills e hooks) do projeto atual para um projeto destino selecionado pelo usuário. Sempre inclui a skill `team-os` e cria `settings.json`. Smart-memory NÃO é criada — isso é responsabilidade do `/team-os` na primeira execução.

### Fluxo

**Passo 1 — Listar projetos**

Rodar `scripts/scan-ct-projects.sh`. Mostrar:

```
📦 Instalar times em projeto

Root detectado: /Users/usuario/Desktop/Projetos/Centro de Treinamento/

Projetos disponíveis:
  1. aiox    — /path/aiox/   (0 agentes, 20 skills)
  2. claude  — /path/claude/ ← projeto atual (fonte)
  [N+1]. Outro caminho — digitar manualmente

Em qual projeto instalar?
```

**Passo 2 — Selecionar squads**

```
Squads disponíveis para instalar:

  ✅ dev     — 10 agentes (analyst, architect, ux, 4 devs, qa, devops, data)
  ✅ sites   — 10 agentes (analyst, architect, ux, 4 devs, qa, devops, data)
  ✅ social  — 7 agentes (analyst, content, design, photo, publisher, strategist, video)
  ✅ traffic — 10 agentes (analyst, automation, bi, copywriter, designer, google, meta, qa, strategist, tiktok)

Quais squads instalar? (ex: "dev sites" ou "tudo")
```

**Passo 3 — Selecionar o que instalar**

```
O que instalar além dos agentes?
(team-os skill + settings.json são sempre incluídos)

  1. Agentes apenas
  2. Agentes + skills correspondentes  ← recomendado
  3. Agentes + skills + hooks
```

> Smart-memory NÃO é scaffoldada aqui — o `/team-os` faz isso com dados reais na primeira execução.

**Passo 4 — Preview**

```
Preview da instalação:

  Destino: aiox (/path/aiox/)
  Squads: dev, sites

  Agentes a instalar: 20
    dev-analyst, dev-architect, ... (10)
    sites-analyst, sites-architect, ... (10)

  Skills a instalar: 18 (+ team-os obrigatória)
    dev-api-design, dev-typescript-patterns, ... (10)
    sites-seo-keywords, sites-tailwind-design-system, ... (8)
    team-os ← sempre

  Settings: .claude/settings.json será criado com CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

  Confirmar? (s/n)
```

**Passo 5 — Executar**

Rodar `scripts/install-to-project.sh` com os parâmetros selecionados.

**Obrigatório — o script garante automaticamente:**
1. Skill `team-os` copiada para `<destino>/.claude/skills/team-os/` — sem ela `/team-os` não aparece
2. `.claude/settings.json` criado com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (se não existir)

**NUNCA scaffoldar smart-memory durante install** — a smart-memory é responsabilidade exclusiva da skill `/team-os`. Se o creator criar a estrutura antes, o `detect-state.sh` do team-os detecta `NO_DISCOVERY` em vez de `NEW` e o bootstrap real não roda.

**Passo 6 — Relatório**

```
✅ Instalação concluída em aiox

  Agentes instalados: 20
  Skills instaladas: 18 (+ team-os obrigatória)
  Settings: .claude/settings.json ✅ (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
  Hooks copiados: 3 (filtrados por squad)

Próximos passos:
  1. Abra o projeto aiox no Claude Code
  2. Rode /team-os → ele inicializa smart-memory e faz discovery completo com dados reais
  3. Para verificar compliance: /team-os-creator *audit
```

---

## 📚 Subcomandos detalhados

### `*analyze`

Só roda etapas 1 e 2 do fluxo de criação. Mostra o archetype detectado e os presets compatíveis. Não cria nada.

### `*squad <preset>`

Pula análise, vai direto pra etapa 4 com o preset especificado. Útil quando o usuário já sabe o que quer.

```
/team-os-creator *squad dev
/team-os-creator *squad data
/team-os-creator *squad custom  → pula pra *create em loop
```

### `*create <role>`

Cria UM agente. Pergunta interativamente:

```
1. Archetype (implementer/architect/reviewer/...): ___
2. Nome (kebab-case): ___
3. Persona/apelido (opcional, ex: Nova): ___
4. Role title (ex: "Frontend Developer"): ___
5. Descrição curta pra frontmatter: ___
6. Cor (blue/red/green/...): ___
```

Depois:
1. Roda `search-skills.sh` com keywords do role
2. Mostra top 3-5 candidatos
3. Usuário seleciona quais instalar
4. Gera arquivo + valida + relatório

### `*skills <agente>`

Enriquece agente existente:
1. Lê `.claude/agents/<agente>.md` → detecta archetype ou role keywords
2. Roda `search-skills.sh` com esses keywords
3. Filtra skills já instaladas
4. Propõe top N novas
5. Instala as aprovadas + atualiza seção "Skills disponíveis" no prompt

### `*preset-list`

Lê `presets/*.yaml` e imprime cada preset com sua composição.

### `*audit`

Roda `validate-agent.sh` em todos os `.claude/agents/*.md`. Relata cada um como ✅ ou ❌ com motivo específico. Se existir `../team-os/scripts/audit-teammate-compliance.sh`, usa-o (teste duplicado pra garantir).

### `*propagate`

Atalho direto para o fluxo de propagação (Opção 2 do menu). Não passa pelo menu principal.

### `*install`

Atalho direto para o fluxo de instalação (Opção 3 do menu). Não passa pelo menu principal.

---

## 📂 Estrutura de arquivos gerados

```
.claude/agents/
  └── {name}.md           ← frontmatter Agent Teams + Contrato + prompt do archetype

.claude/skills/
  └── {skill-name}/       ← via npx skills add (quando usuário aceita sugestões)
       └── SKILL.md

docs/smart-memory/        ← NÃO criada pelo creator — responsabilidade exclusiva do /team-os
```

Scripts de suporte:
```
.claude/skills/team-os-creator/scripts/
  ├── preflight.sh              ← verifica pré-condições
  ├── detect-project-signals.sh ← detecta stack e archetype
  ├── generate-agent.sh         ← gera arquivo de agente
  ├── validate-agent.sh         ← valida compliance do agente
  ├── install-suggested-skills.sh ← instala skill do skills.sh
  ├── search-skills.sh          ← busca skills por keyword
  ├── scan-ct-projects.sh       ← mapeia projetos no root do CT  ← novo
  ├── diff-agents.sh            ← compara agentes entre projetos ← novo
  └── install-to-project.sh     ← copia agentes/skills/hooks    ← novo
```

---

## 🔧 Comportamento em situações específicas

| Situação | Ação |
|---|---|
| Nome de agente colide com existente | Pergunta: sobrescrever / renomear / pular |
| Skill sugerida já instalada | Pular silenciosamente (sem erro) |
| `npx skills add` falha (rede/auth) | Registra em warning, prossegue com o resto |
| Archetype não reconhecido | Default pra `implementer` com aviso |
| Template de archetype ausente | Erro bloqueante — não gera agente inválido |
| Projeto sem package.json | Archetype default `custom`, preset `custom` |
| Usuário escolhe `custom` preset | Entra em loop de `*create` até user dizer "basta" |
| `docs/smart-memory/` já existe ou não | Ignorar — creator não toca na smart-memory. Instruir usuário a rodar `/team-os` |
| Projeto destino sem `.claude/` | Criar estrutura mínima antes de copiar |
| Root do CT não encontrado via git | Perguntar ao usuário qual é o diretório raiz |
| Projeto destino é o mesmo que a fonte | Bloquear com erro claro |
| `scan-ct-projects.sh` acha só 1 projeto | Avisar que nenhum outro projeto foi detectado e oferecer digitar caminho manual |

---

## 🗂️ Referências internas

- [Archetypes e defaults completos](reference/archetypes.md)
- [Catálogo de qualidade skills.sh](reference/skills-catalog-quality.md)
- [Integração com smart-memory por archetype](reference/smart-memory-integration.md)
- Presets em `presets/*.yaml`
- Scripts de suporte em `scripts/`
