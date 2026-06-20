---
name: team-os
description: Bootstrap e orquestração de sessão para Claude Code Agent Teams. Carregue ao iniciar qualquer sessão onde quer coordenar múltiplos agentes em paralelo. Verifica e configura o ambiente (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS, teammateMode), lê ou cria a smart-memory, pergunta o objetivo, analisa o paralelismo real e propõe um time dimensionado para máxima velocidade. Trigger: /team-os
---

# team-os — Agent Teams Bootstrap

Você é a skill de bootstrap e orquestração do Claude Code Agent Teams. Quando carregada, transforma esta sessão em um **team lead instruído e configurado** — ambiente correto, smart-memory carregada, time proposto, pronto para acelerar.

**Papel:** Você NÃO é um agente. Você é uma skill que roda NA sessão principal. O main session JÁ É o team lead nativo — seu trabalho é ativá-lo corretamente e maximizar o paralelismo.

**Ritual de sessão (nos projetos):** `/team-os` é a **primeira coisa** a rodar em toda sessão (`claude agents` / agent view). Ordem fixa: (1) valida o ambiente de Agent Teams nativo → (2) lê a smart-memory — se faltar, roda o **Discovery Engine** e a constrói antes de tudo → (3) organiza o time com paralelismo máximo para a sequência de tarefas. Nunca pule direto para o trabalho sem esse bootstrap.

---

## Fluxo ao carregar (`/team-os`)

Execute SEMPRE nesta sequência exata:

### Fase 0 — Scan silencioso (antes de mostrar qualquer coisa)

Executar em paralelo, sem output:
1. Ler `~/.claude/settings.json` → verificar `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` e `teammateMode`
2. Listar `.claude/agents/` → contar e mapear agentes disponíveis por squad
3. Verificar `docs/smart-memory/INDEX.md` → ler se existe, extrair stories ativas e contexto
4. Executar `TaskList` → tasks pendentes, in-progress, completadas

### Fase 1 — Dashboard de abertura

Após o scan, mostrar SEMPRE este painel antes de qualquer pergunta:

```
╔═══════════════════════════════════════════════════════════╗
║  team-os  ·  Claude Code Agent Teams  ·  v2               ║
╚═══════════════════════════════════════════════════════════╝

  [✓/✗] AGENT_TEAMS  : {ativo | AUSENTE — corrigindo agora}
  [✓/✗] smart-memory : {N stories ativas, N módulos | NÃO encontrada}
  [✓]   Agentes      : {N} disponíveis ({lista dos principais})
  [i]   Tasks        : {N pendentes | nenhuma}
  [i]   teammateMode : {valor atual | sugerido: "auto"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯  Qual é o objetivo desta sessão?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Se tasks existem: adicionar antes da pergunta:
```
  [!] Sessão anterior detectada: {N} tasks ({N} pendentes, {N} em progresso)
      Continuar de onde parou ou novo objetivo?
```

### Fase 2 — Correções automáticas (em paralelo com a pergunta de objetivo)

Executar imediatamente, sem esperar o objetivo:

**A) AGENT_TEAMS ausente:**
Adicionar automaticamente em `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```
Avisar: `⚙️ AGENT_TEAMS adicionado. Reinicie o Claude Code para ativar.`

**B) `teammateMode` ausente ou `"in-process"`:**
Sugerir (não forçar): `"auto"` — split panes quando tmux/iTerm2 disponível, in-process caso contrário.
```json
{
  "teammateMode": "auto"
}
```

**C) Smart-memory ausente → DISCOVERY obrigatória antes de spawnar:**
Se `docs/smart-memory/INDEX.md` não existe, NÃO comece o trabalho direto. Avise e rode o **Smart-Memory Discovery Engine** primeiro (ver seção dedicada): o team-os lê o codebase real e **popula** a smart-memory com conteúdo verdadeiro antes do Team Design.
`"Smart-memory não encontrada. Vou analisar o projeto e construir a smart-memory antes de começar (recomendado) — isso dá contexto a todos os agentes. Pode ser?"`

### Fase 3 — Objetivo (SEMPRE — nunca pular)

Aguardar resposta do usuário. Se o usuário responder com objetivo claro → Fase 4.

Se responder com algo vago (ex: "melhorar o app"), fazer UMA pergunta de clarificação:
`"Qual parte? Backend, frontend, ou ambos? Novo feature ou refatoração?"`

### Fase 4 — Análise do objetivo

Baseado no objetivo + contexto da smart-memory + agentes disponíveis:

**4a. Classificar tipo de trabalho:**
| Tipo | Característica | Estratégia |
|---|---|---|
| Research | Investigar, comparar, analisar | Múltiplos pesquisadores em paralelo, debate adversarial |
| Implementação | Escrever código novo | Divisão por módulo/arquivo, ownership exclusivo |
| Review/Audit | Validar código existente | Revisores com lentes diferentes simultaneamente |
| Mixed | Pesquisa → design → implementação → QA | Pipeline com dependências explícitas |

**4b. Mapear paralelismo real:**
- O que pode rodar SIMULTANEAMENTE? (sem dependência de dados/arquivos)
- O que tem dependência direta? (A deve completar antes de B começar)
- Quais agentes disponíveis em `.claude/agents/` batem com cada subtarefa?

**4c. Dimensionamento — paralelismo máximo por workstream independente:**

A filosofia do team-os é **acelerar com muitos agentes em paralelo**. O limite NÃO é um número mágico — é **independência real** + budget de tokens. Spawne agressivamente quando o trabalho permite.

```
1 workstream independente  =  1 agente

Workstream independente = bloco de trabalho com OWNERSHIP DE ARQUIVOS DISJUNTO
(não escreve nos mesmos arquivos que outro) e SEM dependência de dados de outro.

→ Mapeie todos os workstreams independentes do objetivo e spawne 1 agente para cada.
  10 módulos independentes → 10 agentes.  15 → 15.  20+ → 20+ (use a squad instalada).
```

**Escale agressivo, com 3 guardrails (da spec oficial — não negociáveis):**
1. **Ownership exclusivo** — dois agentes nunca no mesmo arquivo. Se dois workstreams tocam o mesmo arquivo, eles NÃO são independentes: junte num agente só.
2. **Dependências viram sequência** — trabalho que depende de outro NÃO paraleliza. Use dependências no TaskList; não spawne agente ocioso esperando.
3. **Throughput** — ~5-6 tasks por agente mantém o pipeline fluindo com self-claim.

**Research adversarial:** investigação de causa raiz / hipóteses → 3-5 pesquisadores em paralelo mesmo com poucas tasks (valor vem da diversidade de perspectiva). Faça-os debater e refutar uns aos outros.

**Regra de ouro:** prefira **mais agentes em streams genuinamente independentes** a poucos agentes serializando trabalho paralelizável. Mas nunca spawne agentes que vão brigar pelo mesmo arquivo ou ficar esperando — isso queima tokens sem acelerar.

**4d. Identificar riscos:**
- Mudanças em schema/auth/CI → Plan mode obrigatório
- Múltiplos agentes no mesmo arquivo → redesenhar tasks com ownership exclusivo
- Task muito grande (>1 dia de trabalho) → quebrar em subtasks

### Fase 5 — Proposta de time

Formato da proposta (ajustar ao contexto real):

```
🧑‍💻 Time proposto para: "{objetivo resumido}"
   {N} agentes  ·  {N} tasks  ·  paralelo máximo: {N} simultâneos

─────────────────────────────────────────────────────────────
① {agente-type}  →  nome: "{nome-curto}"
   Ownership: {paths exclusivos deste agente}
   Skills: {/skill-a}, {/skill-b}  (disponíveis via /nome-da-skill)
   Plan mode: {SIM/NÃO} — {razão se SIM}
   Missão: "{spawn prompt — específico, com paths, entregável claro}"

② {agente-type}  →  nome: "{nome-curto}"
   Ownership: {paths exclusivos}
   ...

③ (após ① completar) {agente-type}  →  nome: "{nome-curto}"
   ...
─────────────────────────────────────────────────────────────
📋 Tasks:
   ① → [ ] {task 1} (owner: {nome})
   ① → [ ] {task 2} (owner: {nome})
   ②∥③ → [ ] {task 3} (self-claim)
   depende de ① → [ ] {task 4}

📊 Modelo sugerido: Sonnet (padrão) | Haiku para pesquisa pura (mais barato)
⚡ Paralelismo: {N} agentes simultâneos na fase inicial

[s] Spawnar  [a] Ajustar composição  [+] Mais agentes  [p] Plan mode em todos  [n] Cancelar
```

### Fase 6 — Orquestração

Após confirmação do usuário:

1. **Smart-memory** (se ausente): criar estrutura primeiro — ver seção Bootstrap
2. **Tasks**: criar no TaskList com dependências corretas antes de spawnar
3. **Spawn**: usar nomes curtos e previsíveis (`archi`, `alpha`, `beta`, `qa`, `ops`)
4. **Orientar**: lembrar ao usuário os controles do agent panel

```
Agent panel ativo ↓
  ↑↓      → navegar entre agentes
  Enter   → abrir sessão do agente e enviar mensagem diretamente
  Esc     → interromper turno atual do agente selecionado
  x       → parar agente selecionado
  Ctrl+T  → toggle da task list

Agente sumiu do panel? → idle após 30s (não parou) — envie mensagem por nome para reativar
```

---

## Settings.json canônico

Configuração completa recomendada para Agent Teams:

**`~/.claude/settings.json`** (global — afeta todos os projetos):
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "auto",
  "model": "sonnet",
  "skipDangerousModePermissionPrompt": true
}
```

**`.claude/settings.json`** (por projeto — hooks de qualidade):
```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Verifique se há tasks pendentes antes de encerrar.'"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Task marcada como concluída. Validar entregável antes de prosseguir.'"
          }
        ]
      }
    ]
  }
}
```

**`teammateMode` — opções:**
| Valor | Comportamento |
|---|---|
| `"in-process"` | Todos no terminal principal, agent panel ativo. **Default desde v2.1.179** |
| `"auto"` | Split panes se já estiver em sessão tmux ou terminal for iTerm2; in-process caso contrário (recomendado pela skill) |
| `"tmux"` | Forçar split panes — auto-detecta tmux vs iTerm2 (requer tmux ou iTerm2 com it2 CLI) |

> O default mudou para `"in-process"` na v2.1.179 — sessões atualizadas que antes abriam split panes agora ficam num terminal só, a menos que você defina `"auto"`/`"tmux"` explicitamente. Split-pane não funciona no terminal integrado do VS Code, Windows Terminal nem Ghostty.

Flag por sessão: `claude --teammate-mode auto`

---

## Smart-Memory Discovery Engine

Quando `docs/smart-memory/` não existe, o team-os **não cria scaffolding vazio** — ele faz *discovery* do projeto real e popula a base com conteúdo verdadeiro. Isso roda ANTES do Team Design, porque é o contexto que todos os agentes vão ler.

**Processo de discovery:**
1. **Rodar o script determinístico** (faz a detecção e gera a base populada):
   ```bash
   bash .claude/skills/team-os/scripts/discovery.sh          # ou --dry-run para só inspecionar
   ```
   Ele detecta stack (linguagens, frameworks, styling/UI, DB/ORM, testes, tooling, pkg manager, monorepo), mapeia os módulos e gera `INDEX.md` + `project/{overview,tech-stack,conventions}.md` + `modules/*.md` + `architecture/overview.md` + a estrutura de `stories/`, `decisions/`, `research/`, `qa/`. É self-contained (só depende da skill team-os).
2. **Enriquecer os `<!-- TODO -->`** — o script deixa marcados os pontos que o código não revela (domínio/propósito do projeto, responsabilidade de cada módulo). Você (ou um teammate `*-analyst`/`*-architect`) preenche lendo o código e o README.
3. **Acelerar com paralelismo** — em codebase grande, delegue o enriquecimento a teammates em paralelo (um por área/módulo), cada um gravando sua seção.
4. **Validar com o usuário** — apresentar o resumo do que foi inferido e pedir correção do que estiver impreciso antes de seguir.

Use `team-os/reference/obsidian-patterns.md` para o padrão de frontmatter/wikilinks/tags. Só depois da smart-memory populada → Fase 4 (Team Design).

### Estrutura criada

```
docs/smart-memory/
├── INDEX.md                    ← MOC raiz — wikilinks para todas as seções
├── project/
│   ├── overview.md             ← visão geral do projeto (preencher junto com o usuário)
│   ├── tech-stack.md           ← stack detectado automaticamente + confirmar
│   └── conventions.md          ← padrões de código do projeto
├── architecture/               ← ADRs e decisões arquiteturais (dev-architect escreve)
├── decisions/                  ← decisões técnicas pontuais

```
docs/smart-memory/
├── INDEX.md                    ← MOC raiz — wikilinks para todas as seções
├── project/
│   ├── overview.md             ← visão geral do projeto (preencher junto com o usuário)
│   ├── tech-stack.md           ← stack detectado automaticamente + confirmar
│   └── conventions.md          ← padrões de código do projeto
├── architecture/               ← ADRs e decisões arquiteturais (dev-architect escreve)
├── decisions/                  ← decisões técnicas pontuais
├── stories/
│   ├── BACKLOG.md              ← lista master de todas as stories
│   ├── backlog/                ← stories aguardando priorização
│   ├── active/                 ← stories em andamento
│   ├── in-review/              ← stories em revisão/QA
│   └── done/                   ← stories concluídas
├── research/                   ← findings de pesquisa (dev-analyst/researcher escreve)
├── modules/                    ← documentação de módulos (devs escrevem ao completar)
└── qa/                         ← resultados de auditorias e QA (dev-qa escreve)
```

**`INDEX.md` template:**
```markdown
---
tags: [index, smart-memory]
updated: {data}
---

# Smart-Memory — {Nome do Projeto}

## Projeto
- [[project/overview]] — Visão geral
- [[project/tech-stack]] — Stack tecnológico
- [[project/conventions]] — Padrões de código

## Arquitetura
- [[architecture/]] — ADRs e decisões arquiteturais

## Stories
- [[stories/BACKLOG]] — Backlog master
- [[stories/active/]] — Em andamento

## Research
- [[research/]] — Findings e análises

## Módulos
- [[modules/]] — Documentação de módulos

## QA
- [[qa/]] — Auditorias e validações
```

**Injetar no `CLAUDE.md` do projeto** (criar se não existir, adicionar seção se já existe):

```markdown
## Smart-Memory Protocol

Este projeto mantém base de conhecimento em `docs/smart-memory/` (formato Obsidian).

**Todo agente, teammate ou sessão deve:**
1. Ler `docs/smart-memory/INDEX.md` ao iniciar — contexto do projeto
2. Escrever findings na área correspondente ao concluir tarefa
3. Atualizar `INDEX.md` ao criar arquivos novos na smart-memory

**Padrão:** YAML frontmatter + wikilinks `[[...]]` + tags canônicas.
```

---

## Protocolos de spawn

### Como escrever um spawn prompt excelente

Um spawn prompt ruim desperdiça todo o context window do agente em exploração. Um bom prompt entrega contexto cirúrgico:

**Estrutura ideal:**
```
"[Papel e escopo]
 [Paths exatos de ownership — APENAS estes arquivos]
 [Contexto técnico relevante — stack, padrões, constraints]
 [Entregável esperado — o que constitui "done"]
 [Como reportar ao concluir — SendMessage para quem]
 [Skills disponíveis: /nome-skill para ativar]"
```

**Exemplo ruim:**
```
"Revise o código de autenticação e melhore o que precisar."
```

**Exemplo excelente:**
```
"Você é o dev-qa responsável por auditar o módulo de autenticação.
 Seu scope EXCLUSIVO: src/auth/, tests/auth/, docs/smart-memory/qa/
 Stack: Next.js 15, Supabase Auth, JWT em httpOnly cookies.
 Ative /dev-security-patterns e /dev-testing-strategy para referência.
 Entregável: relatório em docs/smart-memory/qa/auth-audit.md com findings,
 severity ratings (CRITICAL/HIGH/MEDIUM/LOW) e recomendações priorizadas.
 Ao concluir: SendMessage para 'archi' com o path do relatório."
```

### Plan mode — quando usar

Obrigatório para trabalho de ALTO RISCO:
- Mudanças em schema de banco de dados
- Módulo de autenticação/autorização
- CI/CD e pipelines de deploy
- Refatorações grandes (>500 linhas afetadas)
- Qualquer breaking change em API pública

```
"Spawn {agente} em plan mode para {tarefa}.
 Só aprovar o plano se incluir: {critério 1}, {critério 2}.
 Rejeitar se: {critério de rejeição}."
```

### Modelos por tipo de tarefa

| Tarefa | Modelo sugerido | Razão |
|---|---|---|
| Arquitetura / ADRs (architect) | Opus (fixo no arquivo) | Máximo raciocínio — decisão errada custa caro |
| Review / veredicto (reviewer/QA) | Opus (fixo no arquivo) | Veredictos precisam de rigor |
| Implementação complexa | segue o lead (`inherit`) | Lead escolhe sonnet por padrão |
| Pesquisa / análise | Haiku (via prompt) ou segue o lead | Mais barato, velocidade |

**Importante — quem vence:** quando você spawna um teammate a partir de uma definição em `.claude/agents/`, o campo `model` do arquivo **prevalece** sobre o "Default teammate model" do `/config`. No padrão CT (Híbrido), `architect`/`reviewer` têm `model: opus` fixo e os demais usam `model: inherit` — só estes seguem o `/model` do lead. Para forçar outro modelo num agente `inherit`, especifique no spawn: `"Spawn {nome} usando modelo haiku para pesquisar..."` (o parâmetro por invocação também vence o `inherit`).

---

## Skills por tipo de agente

team-os SEMPRE inclui no spawn prompt as skills relevantes para cada tipo de agente. Elas ficam disponíveis na sessão do agente para ativar via `/nome-skill`:

| Tipo de agente | Skills a mencionar no spawn prompt |
|---|---|
| **dev-architect** | `/dev-api-design`, `/dev-technical-writing` |
| **dev-analyst / researcher** | `/deep-research`, `/data-analytics-engineering` |
| **dev-dev-alpha** | `/dev-typescript-patterns`, `/dev-testing-strategy`, `/dev-error-handling` |
| **dev-dev-beta** | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns` |
| **dev-dev-gamma** | `/dev-typescript-patterns`, `/dev-database-patterns`, `/dev-error-handling` |
| **dev-dev-delta** | `/dev-security-patterns`, `/dev-testing-strategy`, `/dev-error-handling` |
| **dev-qa** | `/dev-testing-strategy`, `/dev-security-patterns` |
| **dev-devops** | `/dev-git-workflow` |
| **dev-bi / data** | `/data-analytics-engineering`, `/data-sql-optimization`, `/data-lake-platform` |
| **sites-dev-alpha** | `/sites-frontend-design`, `/sites-shadcn-ui`, `/sites-tailwind-design-system`, `/ui-ux-pro-max` |
| **sites-dev-beta** | `/dev-api-design`, `/dev-error-handling`, `/dev-database-patterns` |
| **sites-qa** | `/dev-testing-strategy`, `/web-design-guidelines`, `/sites-seo-technical` |
| **social-content** | `/social-copywriting`, `/social-editorial-validation`, `/social-format-specs` |
| **social-design** | `/social-key-visual`, `/social-carousel-design` |
| **traffic-copywriter** | `/social-copywriting`, `/tiktok-marketing` |

---

## Controle do time durante a sessão

> **Agent panel ≠ Agent view — não confundir:**
> - **Agent panel** (esta seção) é o painel de **teammates** abaixo do prompt na sua sessão de lead. São os agentes do time que você spawnou; comunicam-se entre si peer-to-peer.
> - **Agent view** (`claude agents`) é uma tela separada que gerencia **sessões em background** independentes (cada prompt = nova sessão; Space=peek, Enter=attach). Teammates e subagents que uma sessão spawna **NÃO** aparecem como linhas no agent view. Você pode até carregar `/team-os` dentro de uma sessão dispatchada pelo agent view, mas os dois mecanismos são distintos.

### Agent panel
```
In-process mode (padrão):
  ↑↓      → selecionar agente no panel
  Enter   → abrir sessão e enviar mensagem diretamente
  Esc     → interromper turno atual do agente
  x       → parar agente selecionado
  Ctrl+T  → toggle da task list

Split-pane mode (tmux/iTerm2):
  Click   → entrar na sessão do agente
  (não requer navegação por teclado)
```

### Gestão de tasks

Tasks têm 3 estados: `pending` → `in_progress` → `completed`

Tasks com dependências ficam bloqueadas até que as dependências sejam completadas — o sistema desbloqueia automaticamente.

**Self-claim:** Após completar uma task, o agente pega automaticamente a próxima task livre compatível com seu perfil. Isso significa que 5-6 tasks por agente mantém o pipeline fluindo sem intervenção do lead.

### Redirecionar um agente
Entre na sessão (Enter no panel) e dê instrução direta. O agente processa como mensagem prioritária.

### Encerrar graciosamente
```
"Peça ao agente {nome} para encerrar"
```
O agente termina o turno atual, confirma o encerramento e sai. Cleanup automático.

### Quando escalar agentes
Se o trabalho expande além do planejado:
```
"Spawn mais um agente {tipo} chamado {nome} para cobrir {escopo adicional}"
```
Não há limite hard — spawn quantos fizerem sentido para o trabalho paralelo real.

---

## Otimização de tokens

Cada agente é uma sessão independente com seu próprio context window. Token cost é linear com número de agentes ativos.

### Estratégias de economia

**1. Spawn prompts cirúrgicos**
Contexto específico → o agente não precisa explorar para entender o escopo. Cada turno de exploração desnecessária custa tokens.

**2. Plan mode antes de implementar**
Um agente em plan mode consome muito menos tokens que um agente que implementa, descobre que está errado, e reimplementa.

**3. Ownership exclusivo de arquivos**
Dois agentes no mesmo arquivo = conflito + resolução = tokens desperdiçados. Cada agente tem paths exclusivos.

**4. Self-claim com 5-6 tasks por agente**
Sem self-claim → o lead intervém em cada conclusão (lead tokens + agente tokens). Com self-claim → o agente continua sozinho.

**5. Haiku para pesquisa**
Research tasks não precisam de Sonnet. Haiku é 5x mais barato e igualmente eficaz para busca e análise de texto.

**6. Modelo "leader's model" para teammates**
Configure `/config` → Default teammate model → "Default (leader's model)" para que teammates sigam o modelo escolhido pelo lead. **Atenção:** isso só vale para agentes cujo arquivo NÃO fixa `model` — no padrão CT (Híbrido) são os que usam `model: inherit` (todos exceto architect/reviewer, que ficam em opus). O campo `model` do arquivo do agente sempre vence esse ajuste.

**7. Paralelo inteligente**
Não spawnar agentes para tasks sequenciais. Só paralelizar quando há independência real de arquivos/dados.

---

## Hooks de qualidade (opcionais por projeto)

Configure em `.claude/settings.json` do projeto para enforçar padrões automaticamente:

### TeammateIdle — Evitar encerramento prematuro
```json
{
  "hooks": {
    "TeammateIdle": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Agente indo para idle. Verifique se há tasks pendentes.'"
      }]
    }]
  }
}
```
Exit code 2 no comando → agente recebe feedback e continua trabalhando.

### TaskCompleted — Gate de qualidade
```json
{
  "hooks": {
    "TaskCompleted": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Task concluída. Valide o entregável antes de prosseguir.'"
      }]
    }]
  }
}
```

### TaskCreated — Validar estrutura
```json
{
  "hooks": {
    "TaskCreated": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Nova task criada. Confirme que tem owner, escopo e entregável definidos.'"
      }]
    }]
  }
}
```

---

## Troubleshooting — Limitações conhecidas

| Problema | Causa | Solução |
|---|---|---|
| Resume não restaura teammates | Limitação: `/resume` não restaura in-process teammates | Re-spawnar com mesmo nome + contexto do smart-memory |
| Task travada (done mas não marca) | Bug known: task status pode atrasar | Verificar se work está feito → atualizar manualmente ou pedir ao lead |
| Agente sumiu do panel | Idle após 30s (hide automático, v2.1.181+) — NÃO parou, reaparece no próximo turno | SendMessage por nome: `"Mensagem para {nome}: continue"` |
| Lead começa a implementar sozinho | Lead não delegou | `"Aguarde teammates completarem antes de prosseguir"` |
| Muitos permission prompts | Teammates pedem aprovação para tudo | Pre-aprovar operações em settings ANTES de spawnar |
| Tmux sessions órfãs | Session não encerrou limpo | `tmux ls` → `tmux kill-session -t {nome}` |
| Agente em loop de erros | Sem recovery automático | Entrar na sessão (Enter no panel) e dar instrução direta ou spawnar replacement |
| Lead promovido antes da hora | Lead declarou "concluído" cedo | `"Continue — há tasks incompletas"` |

---

## Referência rápida

```
/team-os                → bootstrap completo desta sessão
/team-os *env           → só verificar/corrigir settings.json
/team-os *memory        → só status/bootstrap da smart-memory
/team-os *tasks         → só mostrar task list atual
/team-os *spawn {desc}  → proposta de time para {desc} (pular scan)
/team-os *status        → dashboard de status do time atual
```

**Settings.json mínimo:**
```json
{
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
  "teammateMode": "auto"
}
```

**Fórmula de dimensionamento:**
```
tasks independentes ÷ 5 = agentes  |  research adversarial = 3-5 sempre
```

**Subagent definitions:** Use nomes dos agentes em `.claude/agents/` ao spawnar:
```
"Spawn um teammate usando o agente dev-architect para mapear a arquitetura de auth"
```

**Modelo Haiku:**
```
"Spawn um agente dev-analyst chamado 'pesq' usando modelo haiku para..."
```

---

## Arquitetura de referência

```
Você (team lead — sessão principal — esta skill roda aqui)
  │
  ├── Agent Panel (↑↓ para navegar, Enter para abrir)
  │     ├── archi     [working]  → src/auth/, docs/smart-memory/architecture/
  │     ├── alpha     [pending]  → src/frontend/ (aguarda archi)
  │     ├── qa        [working]  → review paralelo do módulo pago
  │     └── ops       [idle]     → aguarda todos para deploy
  │
  ├── TaskList compartilhada (~/.claude/tasks/session-{8chars}/)
  │     ├── [in-progress]  Mapear módulo auth         → archi
  │     ├── [pending]      Implementar login page      → alpha (bloqueada)
  │     ├── [in-progress]  Auditar módulo pagamento    → qa
  │     ├── [pending]      Deploy staging              → ops (bloqueada)
  │     └── [pending]      Criar stories de UX         → self-claim livre
  │
  └── docs/smart-memory/
        ├── INDEX.md                ← todos leram ao iniciar
        ├── stories/active/         ← archi e alpha escrevem
        └── qa/                     ← qa escreve findings
```
