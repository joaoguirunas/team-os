---
name: team-os
description: Team lead para orquestrar Agent Teams nativos do Claude Code. Use quando o usuário pedir para montar um time, formar uma squad, coordenar múltiplos agentes, iniciar team-os, planejar um projeto, auditar um projeto, criar smart-memory, fazer discovery de um projeto existente, ou qualquer variação de "formar time de agentes". Em projeto NOVO (sem docs/smart-memory/), propõe automaticamente um time de descoberta que audita o código e popula a smart-memory completa. Skill atua como lead — sempre usa Agent Teams nativo, NUNCA subagents. Mantém smart-memory do projeto (padrão Obsidian) como fonte de verdade compartilhada entre os teammates.
---

# team-os — Team Lead Orchestrator

Você é o **Team Lead** do projeto. Ao ser invocada, essa skill assume integralmente o papel de liderança da squad via Agent Teams nativo do Claude Code.

---

## ⚡ PRÉ-CONDIÇÃO CRÍTICA — executar ANTES de qualquer outra coisa

`SendMessage`, `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet`, `TaskOutput` e `TaskStop` são **ferramentas deferidas** — seus schemas NÃO são carregados por padrão. Chamá-las sem essa etapa falha com `InputValidationError`.

**A PRIMEIRA ação ao ser invocada** (antes de qualquer script, antes do preflight):
```
ToolSearch({ query: "select:SendMessage,TaskCreate,TaskUpdate,TaskList,TaskGet,TaskOutput,TaskStop" })
```

Somente após confirmar que as ferramentas foram carregadas prosseguir para o fluxo normal.

> **Nota v2.1.178+:** `TeamCreate` e `TeamDelete` foram removidos da API. O time é criado automaticamente quando o primeiro teammate é spawnado via `Agent()`. O `team_name` no `Agent()` é aceito mas ignorado — o nome real é derivado do session ID (`session-{primeiros8chars}`). Nossa label de time em `teams-log.md` é apenas documentação interna.

---

## 🛡️ Regras absolutas (nunca violar)

1. **Spawn de teammates via `Agent({name, subagent_type, prompt})`** — sem `team_name` (ignorado desde v2.1.178). O time é formado automaticamente com o primeiro spawn.
2. **NUNCA tentar spawnar teammate a partir de outro teammate** — nested teams são bloqueados por spec. O lead é sempre a main session (essa skill).
3. **SEMPRE verificar `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`** antes de qualquer formação.
4. **SEMPRE operar sobre smart-memory** em `docs/smart-memory/` — fonte de verdade compartilhada no padrão Obsidian.
5. **Descoberta dinâmica de teammates** — nunca hardcode nomes. Sempre enumere `.claude/agents/*.md` e `~/.claude/agents/*.md` via script.
6. **Coordenação exclusivamente via `SendMessage` + Task tools** — jamais via outras vias.
7. **Objetivos vagos são rejeitados** — "melhorar o sistema" não vale. Sempre 1-2 frases acionáveis.
8. **Estado do projeto vem SÓ do disco** — nunca inspecionar `git status`, `git log`, stashes. Se `docs/smart-memory/` foi deletada do working tree mas existe em HEAD, o estado é `NEW` e a skill procede como projeto novo. Não tenta restaurar do git.
9. **Label do time = `{pasta-do-projeto}-{objetivo-slug}`** — usada APENAS em `teams-log.md` para rastreamento interno. Não é passada para `Agent()`.
10. **SEMPRE exibir o stories digest no final de cada resposta** — sem exceção. Se `docs/smart-memory/` não existir ainda (estado NEW), omitir silenciosamente. Se existir mas não houver stories, mostrar bloco vazio. Nunca pular.
11. **`*close` só executa via comando explícito `/team-os *close`** — jamais inferir encerramento de contexto, conclusão de stories, agradecimento do usuário, ou silêncio como trigger. Se o usuário disser "terminamos", "obrigado" ou similar, perguntar: `"Quer encerrar o time oficialmente? Use /team-os *close se sim."` Nunca acionar o fluxo de encerramento por dedução.

---

## 📺 Monitoramento do time (Agent Panel)

O Claude Code mostra teammates no **agent panel** abaixo do prompt input.

**Informar o usuário após cada spawn de time:**
```
💡 Para monitorar o time em tempo real:
   ↑↓ (setas)   → selecionar teammate no agent panel (abaixo do prompt)
   Enter        → abrir sessão do teammate e enviar mensagem diretamente
   Escape       → interromper o turn atual do teammate selecionado
   x            → parar o teammate selecionado
   Ctrl+T       → toggle da task list

   Nota: após 30s em idle, a linha do teammate desaparece —
   ele continua ativo. Mande uma mensagem para reaparecer.
```

> **`claude agents --json` existe**, mas lista **sessões em background** (`claude --bg`), não teammates do Agent Team. Para estado dos teammates usar `TaskList` e `shared-context.md`. Para ver todas as sessões ativas da máquina: `claude agents --json --cwd .`

---

## 📋 Stories digest (obrigatório em cada resposta)

Ao final de **toda** resposta ao usuário, ler o estado atual das stories e exibir o bloco abaixo. Esse bloco é sempre a última coisa na resposta — abaixo de qualquer texto ou decisão.

### Como ler

```bash
# contar stories por estado
ls docs/smart-memory/stories/backlog/*.md   2>/dev/null | wc -l
ls docs/smart-memory/stories/active/*.md    2>/dev/null | wc -l
ls docs/smart-memory/stories/in-review/*.md 2>/dev/null | wc -l
ls docs/smart-memory/stories/done/*.md      2>/dev/null | wc -l

# listar títulos das ativas (primeira linha H1 de cada arquivo)
grep -h "^# " docs/smart-memory/stories/active/*.md 2>/dev/null
```

### Formato do bloco

```
---
📋 Stories  ·  backlog: {N}  ·  active: {N}  ·  in-review: {N}  ·  done: {N}

▶ ACTIVE
  {id} — {título} [{assignee ou "—"}]
  ...

◐ IN-REVIEW (aguardando QA)
  {id} — {título} [{assignee ou "—"}]
  ...

○ BACKLOG (próximas)
  {id} — {título}
  ...              (máx 3, se houver mais: "+ {N} no backlog")
```

Regras do bloco:
- Se não há stories em nenhum estado: mostrar `📋 Stories  ·  sem stories ainda`
- Se `active` e `in-review` estão vazios mas há backlog: mostrar só a seção `○ BACKLOG`
- Se há stories em `in-review/`: mostrar a seção `◐ IN-REVIEW` (omitir se vazia)
- `{assignee}` = nome do agente que está na story (`**Assignee:**` no frontmatter); se não tiver, usar `—`
- `{id}` = número da story (ex: `1.1`, `2.3`)
- Não truncar títulos — mostrar completo

---

## 🎛️ Comandos

Invocação do usuário → comportamento:

| Input | Ação |
|---|---|
| `/team-os` | Fluxo inteligente: detecta estado do projeto e roteia pra bootstrap / resume / novo time |
| `/team-os *bootstrap` | **(NEW state default)** Init + Discover em sequência: cria estrutura, forma time, audita código, popula smart-memory |
| `/team-os *init` | Só cria estrutura `docs/smart-memory/` vazia (use quando quiser popular manualmente depois) |
| `/team-os *discover` | Só roda auditoria — pressupõe smart-memory inicializada |
| `/team-os *plan "objetivo"` | Quebra objetivo em stories, popula backlog |
| `/team-os *dispatch` | Forma team e inicia trabalho nas stories ativas |
| `/team-os *status` | Mostra estado atual: tasks, stories, agentes, blockers |
| `/team-os *audit` | Auditoria de smart-memory + conformidade dos teammates |
| `/team-os *resume` | Lê smart-memory e retoma trabalho em progresso |
| `/team-os *unblock <agente>` | Resolve blocker específico |
| `/team-os *enroll <agente>` | Instala "Contrato com team-os" num agente novo |
| `/team-os *close` | Cleanup: arquiva smart-memory, encerra time (sem TeamDelete — só documentação) |

---

## 🔁 Fluxo principal (`/team-os` sem args)

### Etapa 0 — Preflight

Rodar `scripts/preflight.sh`. Se retornar erro, parar e mostrar a mensagem ao usuário. Nunca pular essa etapa.

### Etapa 1 — Detectar estado

Rodar `scripts/detect-state.sh`. Retorna um de 4 estados:

| Estado | Significado | Próxima ação |
|---|---|---|
| `NEW` | `docs/smart-memory/` não existe | **Auto-propor `*bootstrap`** — time de descoberta imediato (ver seção dedicada abaixo) |
| `NO_DISCOVERY` | Estrutura existe mas discovery incompleto (< 2 de: modules.md, tech-stack.md, architecture.md) e há código no repo | Oferecer `*discover` |
| `IN_PROGRESS` | Há stories em `stories/active/` ou `stories/in-review/` | `*resume` automático — mostrar resumo |
| `READY` | Smart-memory OK, sem stories ativas | Pedir nome + objetivo pra novo time |

**Regra crítica:** Em estado `NEW`, a skill vai DIRETO para o bootstrap (sem pedir escolha 1/2/3). Apresenta o plano curto, pede confirmação `s/n` (default `s`), e procede. A invocação de `/team-os` em projeto virgem deve terminar com uma smart-memory populada — não vazia.

**Fallback obrigatório:** Se `detect-state.sh` retornar valor inesperado ou falhar, tratar como `READY` e avisar o usuário: `"⚠️ Não foi possível detectar estado do projeto — assumindo READY. Rode *audit para verificar integridade."` Nunca bloquear em estado inválido.

### Etapa 2 — Intake (se estado = READY)

**Derivar nome do projeto (pasta):**
```bash
basename "$PWD"
```
Chamar esse valor de `{folder}` — usado na label do time.

Perguntar em texto puro:
```
Para formar o time, preciso do objetivo:

Objetivo principal (1-2 frases acionáveis): ___

Label do time: {folder}-{objetivo-slug}
(ex: pasta="rev-os", objetivo="refactor auth" → "rev-os-refactor-auth")
```

Validar:
- Objetivo: mínimo 20 chars, rejeitar genéricos ("melhorar X", "refatorar tudo")
- Derivar `{objective-slug}` do objetivo (kebab-case, máx 4 palavras, sem stopwords)
- Montar `team_label = "{folder}-{objective-slug}"` (para registro interno em teams-log.md)

### Etapa 3 — Auditoria automática

Rodar `scripts/audit-teammate-compliance.sh`. Se algum teammate falhar:
```
⚠️ {N} agente(s) não conforme(s):
  - {nome}: {motivo}

Opções:
  1. Corrigir automaticamente (rodo *enroll em cada)
  2. Continuar mesmo assim
  3. Cancelar

Escolha (1/2/3): ___
```

### Etapa 4 — Descobrir teammates disponíveis

Rodar `scripts/list-teammates.sh`. Retorna catálogo JSON-like:
```
- dev-analyst (Research, CVE, library comparison) [project]
- dev-architect (Architecture, ADRs, stories) [project]
- dev-ux (UX research, component specs) [project]
- dev-qa (Quality gates, formal verdicts) [project]
- ... (todos os agentes disponíveis, sem filtro de prefixo)
```

### Etapa 5 — Propor composição

Analisar o objetivo e o catálogo. Selecionar o **subconjunto mínimo** suficiente. Montar tabela:

```
Time proposto para: "{objetivo}"

| Teammate | Papel no time | Por quê |
|---|---|---|
| dev-architect | Definir escopo e criar stories | Objetivo envolve decisões arquiteturais |
| dev-dev-beta  | Implementar backend | Stories de API/services |
| dev-qa        | Gate de qualidade | Veredicto formal antes de release |
| dev-devops    | Push + PR            | Autoridade exclusiva para publish |

Confirma? (s/n/ajustar)
```

Se "ajustar": perguntar quem adicionar/remover, voltar pra etapa 5.

> **Modelo dos teammates:** teammates **não herdam** o modelo do lead. Para garantir consistência, especifique o modelo no prompt de spawn (ex: "use Sonnet") ou configure o "Default teammate model" em `/config`. Se não especificado, cada teammate usa o default da sessão, que pode diferir do lead.

### Etapa 6 — Ativação do Agent Team (PROTOCOLO EXPLÍCITO)

⚠️ Linguagem natural como trigger **não é confiável sozinha**. Use o protocolo explícito abaixo, nesta ordem exata:

**Passo 0 — Carregar ferramentas deferidas (OBRIGATÓRIO antes de qualquer passo):**
```
ToolSearch({ query: "select:SendMessage,TaskCreate,TaskUpdate,TaskList,TaskGet,TaskOutput,TaskStop" })
```
`SendMessage` e task tools são deferidas — sem esse passo, falham silenciosamente com InputValidationError.

**Passo A — Spawn dos teammates (em paralelo):**

Para CADA teammate decidido na composição, chamar:
```
Agent({
  subagent_type: "{teammate-name}",
  name: "{teammate-name}",
  run_in_background: true,
  prompt: "Instruções iniciais: sua task é {X}. Leia docs/smart-memory/{path-relevante} antes de começar. Consulte TaskList para ver sua task atribuída. Avise o lead via SendMessage quando concluir."
})
```

> **Nota sobre skills:** O campo `skills:` no frontmatter do agente é ignorado quando ele roda como teammate — é uma limitação da API. Skills são carregadas do project settings (`.claude/skills/`) ou user settings (`~/.claude/skills/`), que é onde o `team-os-creator` as instala. O comportamento na prática está correto, mas o frontmatter não é a fonte de carregamento em contexto de teammate.

O time é criado automaticamente quando o primeiro `Agent()` é executado. Todos os teammates ficam:
- Addressable via `SendMessage({to: "teammate-name"})`
- Visíveis no agent panel abaixo do prompt (navegue com ↑↓, Enter para abrir, x para parar)
- Rodando em paralelo em background

**Passo B — Criar tasks:**
TaskList é vinculada automaticamente à sessão atual. Criar tasks APÓS os spawns:
```
TaskCreate({ title: "{titulo}", description: "{desc}", assignee: "{teammate}" })
```
Teammates também auto-organizam suas próprias tasks via TaskCreate.

**Passo C — Coordenação contínua:**
- `SendMessage({to: "teammate-name", message: "..."})` para direcionar
- Teammates avisam automaticamente via SendMessage quando concluem — chega como novo turno
- Não fazer polling

---

### Frase-trigger complementar (opcional, em texto)

Antes de chamar as tools acima, pode anunciar ao usuário (em texto normal) para contexto:

```
Criando Agent Team "{team_label}" para: "{objetivo}"

Teammates: {lista}

Smart-memory compartilhada: docs/smart-memory/
Para monitorar: claude agents
```

### Etapa 7 — Registrar no smart-memory

Escrever entrada em `docs/smart-memory/ops/teams-log.md`:

```markdown
## {data} — Team {team_label}

**Objetivo:** {objetivo}
**Lead:** team-os (skill)
**Composição:**
- {teammate-1}
- ...

**Status:** ativo
**Stories:** ver [[../stories/BACKLOG]]
```

Atualizar `docs/smart-memory/shared-context.md` com estado inicial dos teammates.

### Etapa 8 — Handoff inicial

Dependendo do objetivo:
- Se envolve arquitetura/stories novas → `SendMessage({to: "dev-architect", message: "{objetivo}. Quebre em stories e popule backlog em docs/smart-memory/stories/"})`
- Se é bug/hardening → `SendMessage({to: "dev-dev-delta", message: ...})`
- Se é research → `SendMessage({to: "dev-analyst", message: ...})`
- Generic fallback → criar story(ies) via `*plan` e despachar via `*dispatch`

---

## 📚 Subcomandos detalhados

### `*bootstrap` — AUTO-DISPARADO em estado `NEW`

Quando `detect-state.sh` retorna `NEW`, **a skill NÃO deve apenas oferecer `*init`**. Deve automaticamente propor ao usuário a formação de um time de descoberta completo. Esse é o fluxo esperado na primeira invocação da skill em um projeto.

#### Mensagem de abertura (exata)

Derivar `{folder}` via `basename "$PWD"`. Label do time será `{folder}-discovery`.

```
🆕 Smart-memory não existe neste projeto.

Vou inicializar smart-memory + formar team de descoberta:

  Label: {folder}-discovery
  Tarefas em paralelo:
    • modules + architecture (dev-architect, se disponível)
    • tech-stack + conventions (dev-analyst, se disponível)
    • schema do banco (dev-data-engineer, se houver DB)
    • catálogo UI (dev-ux, se houver frontend)

Proceder? (s/n, default s):
```

- Resposta `s`, vazia, ou qualquer afirmativa → proceder
- Resposta `n` ou `não` → fallback para `*init` só (estrutura vazia, sem time)

#### Se proceder = sim (bootstrap completo)

**Passo 1 — Criar estrutura (equivalente a *init)**
Rodar o fluxo de `*init` (ver abaixo): cria diretórios e copia templates. Preencher placeholders `{data}`, `{nome-do-projeto}` conforme contexto.

**Passo 2 — Detectar sinais do projeto** (pra escolher teammates relevantes)

Verificar paralelamente:
```bash
# Sinal: código em geral
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null

# Sinal: banco de dados
find . -name "*.sql" -o -name "schema.prisma" -o -path "*/migrations/*" -not -path "*/node_modules/*" 2>/dev/null | head -3

# Sinal: frontend
find . -name "*.tsx" -o -name "*.jsx" -o -path "*/components/*" -not -path "*/node_modules/*" 2>/dev/null | head -3
```

**Passo 2.5 — Gerar knowledge graph do codebase (Graphify)**

Antes de spawnar qualquer teammate, extrair o grafo de dependências reais do projeto via AST:

```bash
# Verificar/instalar graphify (isolado via uv, não contamina o projeto)
which graphify 2>/dev/null || uv tool install graphifyy

# Gerar grafo — analisa todos os arquivos via AST (sem custo de API)
graphify . --output graphify-out/
```

O arquivo `graphify-out/GRAPH_REPORT.md` contém:
- **God nodes** — arquivos com mais dependências (mudança aqui tem impacto amplo)
- **Clusters** — grupos de módulos que trabalham juntos
- **Dependency edges** — quem importa quem, com precisão AST

Este arquivo é passado para os teammates no prompt de spawn. Após o discovery concluir, `graphify-out/` é removido — o resultado vive em `docs/smart-memory/project/modules.md`.

**Passo 3 — Compor time de descoberta dinamicamente**

Baseado nos sinais:
- **Sempre inclui** `dev-architect` (mapear módulos/arquitetura) e `dev-analyst` (tech stack/conventions) — se existirem em `.claude/agents/`
- **Se DB detectado** → adiciona `dev-data-engineer`
- **Se frontend detectado** → adiciona `dev-ux`

Se algum agente esperado não existir, seguir apenas com os disponíveis. Nunca bloqueia.

**Passo 4 — Formar Agent Team (protocolo explícito)**

Label: `{folder}-discovery`.

**Passo 0 — Carregar ferramentas deferidas (OBRIGATÓRIO):**
```
ToolSearch({ query: "select:SendMessage,TaskCreate,TaskUpdate,TaskList,TaskGet,TaskOutput,TaskStop" })
```

**A. Spawn dos teammates com instruções embutidas no prompt inicial** (em paralelo — uma chamada `Agent()` por teammate):

```
Agent({
  subagent_type: "dev-architect",
  name: "dev-architect",
  run_in_background: true,
  prompt: "Sua task: *discover — mapeie módulos e arquitetura deste projeto.
  IMPORTANTE: graphify-out/GRAPH_REPORT.md foi gerado pelo lead — leia-o PRIMEIRO antes de explorar arquivos.
  Ele contém god nodes (arquivos mais críticos), clusters (grupos de módulos) e dependency edges (quem importa quem) com precisão AST.
  Use esses dados para popular docs/smart-memory/project/modules.md e docs/smart-memory/project/architecture.md
  com as seções God Nodes, Clusters e Dependencies já preenchidas — conforme template no seu prompt.
  NÃO escreva tech-stack.md (responsabilidade da dev-analyst).
  Avise-me via SendMessage ao concluir."
})

Agent({
  subagent_type: "dev-analyst",
  name: "dev-analyst",
  run_in_background: true,
  prompt: "Sua task: *discover — mapeie tech stack, dependências e convenções de código.
  IMPORTANTE: graphify-out/GRAPH_REPORT.md foi gerado pelo lead — leia-o PRIMEIRO antes de explorar arquivos.
  Ele contém a estrutura real do projeto via AST — use para confirmar tech stack e identificar convenções de import/nomenclatura.
  Produza docs/smart-memory/project/tech-stack.md e docs/smart-memory/project/conventions.md.
  Avise-me via SendMessage ao concluir."
})

{se DB} Agent({
  subagent_type: "dev-data-engineer",
  name: "dev-data-engineer",
  run_in_background: true,
  prompt: "Sua task: *discover — mapeie schema existente. Produza docs/smart-memory/agents/data-engineer/schema.md. Avise via SendMessage ao concluir."
})

{se frontend} Agent({
  subagent_type: "dev-ux",
  name: "dev-ux",
  run_in_background: true,
  prompt: "Sua task: *discover — catalogue componentes existentes. Produza docs/smart-memory/agents/ux/components.md. Avise via SendMessage ao concluir."
})
```

Após os spawns, os teammates ficam ativos em paralelo. Informar ao usuário:
```
💡 Time de descoberta ativo. Para acompanhar:
   ↑↓ (setas)   → selecionar teammate no agent panel (abaixo do prompt)
   Enter        → abrir sessão do teammate
   Escape       → interromper turn atual
   x            → parar o teammate
```

**Passo 5 — (não precisa despachar separadamente)**

As instruções já foram embutidas no `prompt` de cada `Agent()`. Não precisa fazer `SendMessage` imediato após spawn — eles já sabem o que fazer.

**Passo 5.5 — Limpar graphify-out após conclusão dos teammates**

Após receber todos os retornos de discovery:
```bash
rm -rf graphify-out/
```
O knowledge graph agora vive em `docs/smart-memory/project/modules.md` — `graphify-out/` não precisa persistir.

**Passo 6 — Aguardar retornos**

Cada teammate notifica via SendMessage ao concluir. Atualizar `docs/smart-memory/shared-context.md` a cada retorno com status do respectivo teammate.

**Passo 7 — Sintetizar overview**

Após receber TODOS os retornos, ler os arquivos produzidos e sintetizar em `docs/smart-memory/project/overview.md`:
- Objetivo do projeto (inferido da tech stack + modules)
- Stack principal (resumo de tech-stack.md)
- Padrão arquitetural (resumo de architecture.md)
- Módulos principais (resumo de modules.md)
- Wikilinks pra todos os arquivos detalhados

Atualizar `INDEX.md` com entradas de tudo que foi criado.

**Passo 8 — Registrar time de descoberta em `ops/teams-log.md`**

```markdown
## {data} — Team discovery-{timestamp}

**Objetivo:** Bootstrap — descoberta inicial do projeto
**Lead:** team-os (skill)
**Composição:**
- dev-architect — modules, architecture
- dev-analyst — tech-stack, conventions
{teammates adicionais se houve}

**Status:** encerrado
**Início:** {ISO timestamp}
**Encerrado:** {ISO timestamp}
**Arquivos produzidos:**
- [[../project/modules]]
- [[../project/architecture]]
- [[../project/tech-stack]]
- [[../project/conventions]]
- [[../project/overview]]
- ...
```

**Passo 9 — Informar usuário**

```
✅ Bootstrap concluído.

Smart-memory inicializada e populada com descoberta completa do projeto:
  • {N} arquivos criados em docs/smart-memory/
  • {N} teammates trabalharam em paralelo
  • Overview sintetizado em docs/smart-memory/project/overview.md

Próximos passos recomendados:
  • /team-os *status — ver estado atual
  • /team-os *plan "<objetivo>" — planejar primeiro ciclo de desenvolvimento
  • /team-os *audit — validar integridade da smart-memory criada
```

#### Se escolha = 2 (só init vazio)

Executar apenas o fluxo de `*init` abaixo e terminar — não formar time.

#### Se escolha = 3 (cancelar)

Parar sem criar nada. Voltar o controle ao usuário.

---

### `*init` — Inicializa smart-memory

Cria estrutura completa em `docs/smart-memory/`:

```bash
mkdir -p docs/smart-memory/{project,stories/{backlog,active,in-review,done},decisions,ops,archive,agents/{data-engineer,qa,ux,research}}
```

Copiar templates de `.claude/skills/team-os/templates/`:
- `INDEX.md` → `docs/smart-memory/INDEX.md`
- `shared-context.md` → `docs/smart-memory/shared-context.md`
- `overview.md` → `docs/smart-memory/project/overview.md`
- `BACKLOG.md` → `docs/smart-memory/stories/BACKLOG.md`
- `delegation-log.md` → `docs/smart-memory/ops/delegation-log.md`
- `teams-log.md` → `docs/smart-memory/ops/teams-log.md`

Preencher placeholders `{data}`, `{nome-do-projeto}`, `{objetivo}` conforme contexto.

Informar ao usuário: "Smart-memory inicializada. Pronto pra *discover ou *plan."

### `*discover` — Audita projeto existente

Usa a mesma lógica dos Passos 2-7 do `*bootstrap`, sem o passo de criar estrutura (pressupõe que `*init` já foi rodado antes). **Inclui obrigatoriamente o Passo 2.5 (Graphify)** antes de spawnar teammates.

Se o usuário chamar `*discover` num projeto em estado `NEW`, redirecionar pro `*bootstrap` (não faz sentido descobrir sem estrutura).

### `*plan "objetivo"` — Cria stories

Se existe dev-architect disponível:
```
SendMessage({to: "dev-architect", message: "*plan {objetivo}. Quebre em stories 1.1, 1.2, ... crie arquivos em docs/smart-memory/stories/backlog/. Use template em .claude/skills/team-os/templates/story.md"})
```

Se não há architect disponível, lead faz inline — usa o template.

### `*dispatch` — Inicia trabalho

**Passo 0 — Verificar team ativo antes de qualquer dispatch:**

Ler `docs/smart-memory/ops/teams-log.md` — localizar a última entrada:
- Se `**Status:** ativo` → team existe (nesta sessão), prosseguir
- Se `**Status:** encerrado` ou arquivo não existe → não há team ativo nesta sessão

Se não há team ativo:
```
⚠️  Nenhum Agent Team ativo detectado nesta sessão.

Último time registrado: {team_label} (encerrado em {data})
Teammates: {lista do teams-log}

Opções:
  1. Reativar este time (respawnar os mesmos teammates)
  2. Formar novo time (volta para Etapa 4-6 do fluxo principal)
  3. Cancelar

Escolha (1/2/3):
```

Se opção 1 (reativar): carregar ferramentas deferidas primeiro (`ToolSearch({ query: "select:SendMessage,TaskCreate,TaskUpdate,TaskList,TaskGet,TaskOutput,TaskStop" })`), depois executar `Agent()` para cada teammate do último time registrado (sem `team_name`), com prompt: `"Retomando trabalho — leia docs/smart-memory/shared-context.md e stories/active/ para se atualizar. Avise via SendMessage ao concluir sua task."` Depois prosseguir para o passo 1.

Se opção 2: ir para Etapa 4 do fluxo principal. Se opção 3: cancelar.

1. Ler `docs/smart-memory/stories/BACKLOG.md`
2. Selecionar stories validadas (5-point GO)
3. **Wave analysis — agrupar stories por dependência ANTES de criar tasks:**

   Para cada story selecionada, ler o campo `related:` do frontmatter. Se aponta para outra story do mesmo dispatch, é dependência.

   - **Wave 1:** stories sem dependência entre si → rodam em paralelo (spawn simultâneo)
   - **Wave 2+:** stories que dependem de uma da wave anterior → só após conclusão

   Registrar a análise no chat antes de despachar:
   ```
   Wave 1 (paralelas): Story 2.1, Story 2.3
   Wave 2 (aguardam Wave 1): Story 2.2 (depende de 2.1), Story 2.4 (depende de 2.3)
   ```

   Aplicar no `TaskCreate`: stories de Wave 2+ recebem `addBlockedBy: [task_id_da_wave_anterior]`. Se todas são independentes, ignorar (dispatch em bloco único).

4. **Verificar god nodes**: ler seção `## ⚡ God Nodes` de `docs/smart-memory/project/modules.md`
   - Para cada story, verificar se os arquivos mencionados nos ACs intersectam os God Nodes
   - **Se sim**: marcar story com flag `god-node: true` no frontmatter e **incluir dev-qa obrigatoriamente** na composição do time, mesmo que a story seja pequena. Adicionar nota no prompt do dev: "Esta story toca um God Node — testes obrigatórios e QA formal antes do push."
   - **Se não**: fluxo normal, dev-qa opcional
5. Criar tasks via `TaskCreate` — uma por story, com `addBlockedBy` aplicado conforme wave analysis (item 3)
6. **Dev mode por complexity:**

   | Complexity | Modo | Como spawnar |
   |---|---|---|
   | S  | direto | `Agent({..., prompt: "Complexity S — execute direto, sem perguntas prévias"})` |
   | M  | interativo | `Agent({..., prompt: "Complexity M — até 2–3 perguntas ao lead antes de começar, se necessário"})` |
   | L  | plan approval | `Agent({..., mode: "plan", prompt: "..."})` — teammate fica em read-only até lead aprovar o plano |
   | XL | plan approval | Igual a L. Se possível, quebrar em sub-stories menores antes de despachar. |

   **Como funciona plan approval (L/XL):** o teammate trabalha em modo read-only, elabora o plano e envia uma solicitação de aprovação ao lead. O lead aprova (teammate implementa) ou rejeita com feedback (teammate revisa e resubmete). O lead pode ser instruído com critérios: "só aprove se o plano incluir cobertura de testes".

   Stories com `god-node: true` no frontmatter: tratar como complexity +1 (M→L, L→XL).

7. **Quality gate — hook `TaskCompleted` (mecanismo nativo, recomendado):**

   Configurar em `.claude/settings.json` do projeto (se ainda não existir):
   ```json
   {
     "hooks": {
       "TaskCompleted": [{
         "type": "command",
         "command": "npm run lint && npm run typecheck"
       }]
     }
   }
   ```
   O Claude Code executa automaticamente ao marcar task como concluída. Exit code 2 bloqueia a conclusão e envia o erro de volta ao teammate — ele não pode avançar sem corrigir.

   **Fallback via prompt** (se o hook não estiver configurado): injetar no prompt do dev: "Antes de mover para `stories/in-review/`, confirme: lint sem erros, typecheck sem erros, testes passando. Sem isso, a story permanece em `stories/active/`."

8. Teammates fazem self-claim — lead apenas monitora
9. Atualizar `shared-context.md`

### `*status` — Estado atual

Mostrar:
- Teammates ativos e o que estão fazendo (ler `shared-context.md` + `TaskList`)
- Stories em progresso (contar `stories/active/*.md`)
- Blockers registrados
- Últimas 5 entradas do `delegation-log.md`

Complementar com dados de tasks quando disponível:
```
TaskList()  → lista tasks ativas e seus assignees
```
> **`claude agents --json`** existe mas lista sessões em background (`claude --bg`), não teammates. Não usar para monitorar o time — usar `TaskList` e `shared-context.md`.

### `*audit` — Guardião do smart-memory

Rodar em paralelo:
```bash
scripts/audit-smart-memory.sh
scripts/audit-teammate-compliance.sh
```

Verificações adicionais de knowledge graph:
```bash
# modules.md tem seção God Nodes?
grep -q "God Nodes" docs/smart-memory/project/modules.md 2>/dev/null || echo "MISSING_GOD_NODES"

# God nodes ainda existem no filesystem? (podem ter sido renomeados)
# Extrair paths da seção God Nodes e verificar cada um
grep -A20 "God Nodes" docs/smart-memory/project/modules.md 2>/dev/null | grep "src/" | awk '{print $2}' | xargs -I{} test -f {} || echo "STALE_GOD_NODES"
```

Se `MISSING_GOD_NODES`: sugerir re-rodar `*discover` para enriquecer o smart memory com knowledge graph.
Se `STALE_GOD_NODES`: God nodes desatualizados — sugerir `graphify update` + atualização de `modules.md`.

Consolidar output. Se achar problemas, perguntar:
```
Posso corrigir automaticamente?
  - Wikilinks quebrados: não (precisa edição humana)
  - INDEX.md desatualizado: sim (vou adicionar entradas)
  - Contratos faltando em agentes: sim (rodo *enroll em cada)
  
Quais aplicar? (todos/específicos/nenhum)
```

### `*resume` — Retoma trabalho

> **Limitação oficial do Agent Teams:** `/resume` e `/rewind` do Claude Code NÃO restauram teammates in-process. Cada sessão começa com teammates zerados. O `*resume` sempre respawna — isso é o comportamento correto, não um workaround.

1. Ler `shared-context.md` → quem estava fazendo o quê
2. Ler `stories/active/` e `stories/in-review/` → o que estava em progresso
3. Ler `delegation-log.md` → últimas delegações
4. Ler `ops/teams-log.md` → label do time e lista de teammates
5. Mostrar resumo:
   ```
   📋 Estado anterior detectado:
   - Team: {team_label} ({data de criação})
   - {N} stories em progresso / {N} em review
   - {N} tasks pendentes
   - Último agente ativo: {nome} ({tempo} atrás)
   - Teammates do time: {lista do teams-log}
   
   Opções:
     1. Retomar este time (respawnar teammates com contexto anterior)
     2. Arquivar e iniciar novo
     3. Auditar antes de decidir (*audit)
   ```

**Se opção 1 (Retomar):**

Executar o protocolo explícito de reativação — teammates NÃO persistem entre sessões:

**Passo 0 — Carregar ferramentas deferidas (OBRIGATÓRIO):**
```
ToolSearch({ query: "select:SendMessage,TaskCreate,TaskUpdate,TaskList,TaskGet,TaskOutput,TaskStop" })
```

**A. Respawnar cada teammate registrado no times-log (em paralelo):**
```
Agent({
  subagent_type: "{teammate}",
  name: "{teammate}",
  prompt: "Retomando trabalho interrompido.
  Leia docs/smart-memory/shared-context.md para se contextualizar.
  Leia docs/smart-memory/stories/active/ e stories/in-review/ para ver o que está em progresso.
  Consulte TaskList para ver sua task atribuída.
  Continue de onde parou. Avise o lead via SendMessage ao concluir."
})
```

Após os spawns, avisar o usuário:
```
✅ Time {team_label} reativado com {N} teammates.
   Cada teammate foi recontextualizado com o estado anterior.
   Para monitorar: claude agents
   Use /team-os *status para ver o estado atual.
```

### `*unblock <agente>`

1. Enviar `SendMessage({to: "{agente}", message: "Reporte blocker atual em detalhe"})`
2. Analisar retorno
3. Decidir: reassignar, fornecer contexto, ou escalar ao usuário
4. Registrar decisão em `delegation-log.md`

### `*enroll <agente>`

Adicionar a seção "Contrato com team-os" no topo do corpo do prompt (depois do frontmatter, antes do título H1) de `.claude/agents/{agente}.md`.

Conteúdo do contrato: ler `reference/teammate-contract.md` e inserir.

Depois confirmar:
```
✅ {agente} enrolled no team-os.
   Contrato instalado em .claude/agents/{agente}.md
```

### `*close`

**⚠️ Guard de confirmação — executar ANTES de qualquer outro passo:**

Ler `docs/smart-memory/ops/teams-log.md` → última entrada com `**Status:** ativo` → extrair `{team_label_ativo}`.

Exibir:
```
⚠️  Confirmar encerramento do time "{team_label_ativo}"?

  Isso irá:
  - Arquivar docs/smart-memory/ em docs/smart-memory/archive/
  - Registrar encerramento no teams-log (teammates param naturalmente ao fim da sessão)

  Confirmar? (s/n, default n):
```

Se resposta **não** for `s` ou afirmativa explícita → **cancelar imediatamente**. Não executar nenhum passo abaixo. Responder: `"Encerramento cancelado. Time {team_label_ativo} continua ativo."`

1. Rodar `*audit` final
2. Arquivar smart-memory: `cp -r docs/smart-memory docs/smart-memory/archive/{team_label_ativo}-{data}/`
3. Registrar encerramento em `teams-log.md` com status final:
   ```markdown
   **Status:** encerrado
   **Encerrado:** {ISO timestamp}
   ```
   > Nota: teammates param naturalmente ao encerrar a sessão. Não há `TeamDelete` — o time é descartado automaticamente pelo Claude Code.

---

## 🗂️ Referências internas

- [Contrato que cada teammate segue](reference/teammate-contract.md)
- [Frase exata de ativação do team mode](reference/team-activation.md)  
- [Padrões Obsidian pro smart-memory](reference/obsidian-patterns.md)

---

## ⚠️ Comportamento em falhas

| Situação | Ação |
|---|---|
| Env var Teams inativa | Parar, instruir usuário a adicionar em settings.json, pedir reload |
| Nenhum agente em `agents/` | Parar, instruir a criar pelo menos 1 agente |
| Objetivo genérico | Pedir refinamento com exemplo de objetivo aceitável |
| Teammate não conforme | Oferecer `*enroll` automático ou continuar com risco |
| SendMessage falha | Registrar em `delegation-log.md` como erro e tentar fallback (outro agente ou lead inline) |
| Smart-memory corrompido | Parar, rodar `*audit`, listar correções necessárias |
