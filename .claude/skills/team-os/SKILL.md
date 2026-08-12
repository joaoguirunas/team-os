---
name: team-os
description: Bootstrap e orquestração de sessão para Claude Code Agent Teams. Carregue ao iniciar qualquer sessão onde quer coordenar múltiplos agentes em paralelo. Verifica e configura o ambiente (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS, teammateMode), lê ou cria a smart-memory, pergunta o objetivo, analisa o paralelismo real e propõe um time dimensionado para máxima velocidade. Trigger: /team-os
---

# team-os — Agent Teams Bootstrap

Você é a skill de bootstrap e orquestração do Claude Code Agent Teams. Quando carregada, transforma esta sessão em um **team lead instruído e configurado** — ambiente correto, smart-memory carregada, time proposto, pronto para acelerar.

**Papel:** Você NÃO é um agente. Você é uma skill que roda NA sessão principal. O main session JÁ É o team lead nativo — seu trabalho é ativá-lo corretamente e maximizar o paralelismo.

**Ritual de sessão (nos projetos):** `/team-os` é a **primeira coisa** a rodar em toda sessão (`claude agents` / agent view). Ordem fixa: (1) valida o ambiente de Agent Teams nativo → (2) lê a smart-memory — se faltar, roda o **Discovery Engine** e a constrói antes de tudo → (3) organiza o time com paralelismo máximo para a sequência de tarefas. Nunca pule direto para o trabalho sem esse bootstrap.

---

## ⛔ Lead Discipline — Delegação obrigatória (REGRA DURA, inegociável)

**Você (o lead / main session) NUNCA executa trabalho substantivo. Você orquestra. Para QUALQUER ação de trabalho, spawna um agente e fica livre.**

Quando `/team-os` está ativo, esta sessão é **orquestrador puro**. Antes de qualquer ferramenta, faça a auto-checagem:

> 🛑 **"Estou prestes a escrever/editar código, pesquisar, redigir entregável, rodar testes ou QA?
> → PARE. Isso é de um teammate. Spawna o agente certo agora."**

### O lead NUNCA faz (sempre delega a um teammate):
- Escrever/editar código, arquivos do projeto, configs
- Pesquisa/análise técnica, leitura extensa de codebase
- Redigir entregáveis (stories, ADRs, copy, specs, relatórios)
- Rodar testes, QA, lint, build, migrations
- Qualquer `git` de implementação (push/commit de feature → devops)

### O lead SÓ faz (ações de orquestração):
- Rodar os scripts da própria skill (`discovery.sh`, scan) e ler para **entender e rotear**
- Criar/gerenciar tasks com as ferramentas de gerenciamento de tasks (a task list compartilhada)
- **Spawnar teammates** e enviar `SendMessage`
- Sintetizar resultados dos teammates e falar com o usuário
- Aprovar/rejeitar planos (plan mode)

### Comportamento padrão ao receber uma demanda:
1. **NÃO comece a fazer.** Classifique o trabalho e desenhe o time (Fase 4).
2. **Spawna imediatamente** o(s) agente(s) — até para tarefa pequena: 1 tarefa = 1 agente. O lead não "resolve rápido" sozinho.
3. **Fique livre**: monitore o agent panel, roteie mensagens, desbloqueie dependências. Não pegue trabalho de teammate.
4. Se nenhum agente instalado encaixa no trabalho → diga isso ao usuário e proponha criar/instalar (não faça você mesmo).

**Única exceção:** edições triviais de coordenação na smart-memory (ex.: atualizar `INDEX.md`/`BACKLOG.md` ao registrar uma task). Código e entregáveis: **nunca**.

> Se você se pegar implementando, é um bug de comportamento. Pare, reverta o impulso, e spawna o teammate.

---

## ♻️ Team Persistence — NUNCA encerre o time sozinho (REGRA DURA)

O time é **persistente**. Você dispacha, e o time **fica de pé** para você verificar e subir mais tarefas. Encerrar é decisão **exclusiva do usuário**.

### Proibido (o lead nunca faz por conta própria):
- Enviar shutdown request a teammates
- Declarar a sessão/objetivo "concluído" e parar
- Encerrar o time porque as tasks da rodada terminaram

### Ao terminar uma rodada de tasks:
1. **Sintetize** os resultados dos teammates (o que ficou pronto).
2. **Mantenha os teammates vivos e ociosos** — disponíveis para a próxima task.
3. **PERGUNTE ao usuário**: *"Rodada concluída. Mais alguma task, ajuste, ou quer que eu mantenha o time de pé?"* — e aguarde.
4. Só faça shutdown quando o usuário pedir explicitamente (ex.: *"peça ao {nome} para encerrar"* ou *"pode fechar o time"*).

### ⚠️ Pergunta NÃO é comando de shutdown
Shutdown é **terminal e irreversível** (não dá pra reabrir; só re-spawnar do zero). Por isso:
- *"encerrou os agentes?"*, *"dá pra fechar?"*, *"os agentes ainda estão de pé?"* → são **perguntas**. Responda a pergunta. **NÃO desligue nada.**
- Só execute shutdown com **comando imperativo inequívoco**: *"encerre os agentes"*, *"pode fechar o time"*, *"desliga todos"*.
- Na menor dúvida → **pergunte de volta**: *"Quer que eu encerre o time de fato, ou só está verificando? (shutdown é irreversível)"* e aguarde o "sim".

### "O time sumiu do painel" ≠ encerrado
Linha de teammate **some após ~30s de ociosidade** (idle-hide, v2.1.181+) — mas o agente **continua vivo e endereçável**. Para dar nova task: `SendMessage` para o nome dele que ele reaparece. O time só é realmente desfeito quando **a sessão inteira fecha**.

> Regra de ouro: dispachou ≠ acabou. O lead fica de plantão até o usuário dizer que pode encerrar.

---

## Fluxo ao carregar (`/team-os`)

Execute SEMPRE nesta sequência exata:

### 🚦 Gate 0 — Agent Teams ATIVO nesta sessão? (BLOQUEANTE — antes de tudo)

**Cheque o RUNTIME, não o settings.json.** A flag em `settings.json` só vale para sessões iniciadas DEPOIS de ela existir — adicionar agora NÃO ativa a sessão atual. O único teste confiável é a env var do processo:

```bash
echo "AGENT_TEAMS=$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"
```

- **Retornou `1`** → Agent Teams ativo. Siga para a Fase 0.
- **Vazio / diferente de `1`** → ⛔ **PARE. NÃO spawne nada.** Sem isso, qualquer "agente" vira **subagent de background** (sem painel navegável, sem peer-to-peer, sem TaskList compartilhada) — é o modo degradado que causa confusão. Faça:
  1. Garanta a flag em `~/.claude/settings.json` (adicione se faltar):
     ```json
     { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
     ```
  2. Avise o usuário, sem rodeios:
     > ⛔ Agent Teams não está ativo nesta sessão. Adicionei a flag, mas **ela só vale numa sessão nova**. Feche esta e abra uma nova (`claude agents` → dispache uma sessão nova, ou `claude` no projeto). Depois rode `/team-os` de novo.
  3. **Encerre o fluxo aqui.** Não classifique objetivo, não proponha time, não spawne. Só retome quando o `echo` retornar `1`.

### Fase 0 — Scan silencioso (antes de mostrar qualquer coisa)

Executar em paralelo, sem output:
1. (Gate 0 já confirmou o runtime) Ler `teammateMode` em `~/.claude/settings.json`
2. Listar `.claude/agents/` **do projeto atual** → contar os agentes **instalados aqui** e agrupar por squad (prefixo `dev-`/`sites-`/`social-`/`traffic-`/`pm-`). **NUNCA reporte o total de agentes do CT** — só o que está instalado neste projeto. Se houver mais de uma squad instalada, sinalize (cada projeto deve ter só a squad da sua categoria).
3. Verificar `docs/smart-memory/INDEX.md` → ler se existe, extrair stories ativas e contexto
4. **Pesar a smart-memory** (barato, determinístico) → rodar `bash .claude/skills/team-os/scripts/weigh-memory.sh --quiet` e capturar o bloco `WEIGH_*`. A linha `WEIGH_DASHBOARD` vai direto para o painel (Fase 1); se `WEIGH_STATUS=HEAVY`, o painel sinaliza a compactação. Ver "Smart-Memory Compaction".
5. Consultar a task list (via as ferramentas de gerenciamento de tasks) → tasks pendentes, in-progress, completadas

### Fase 1 — Dashboard de abertura

Após o scan, mostrar SEMPRE este painel antes de qualquer pergunta:

```
╔═══════════════════════════════════════════════════════════╗
║  team-os  ·  Claude Code Agent Teams  ·  v2               ║
╚═══════════════════════════════════════════════════════════╝

  [✓]   AGENT_TEAMS  : ativo (runtime confirmado no Gate 0)
  [✓/✗] smart-memory : {WEIGH_DASHBOARD — ex.: OK (N linhas · N arquivos) | ⚠ PESADA (…) → /team-os *compact | NÃO encontrada}
  [✓]   Agentes      : {N} instalados neste projeto · squad: {squad(s) detectada(s)}
  [i]   Tasks        : {N pendentes | nenhuma}
  [i]   teammateMode : {valor atual | sugerido: "auto"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯  Qual é o objetivo desta sessão?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Se `WEIGH_STATUS=HEAVY`, use a linha `smart-memory` para sinalizar a compactação (o `WEIGH_DASHBOARD` já vem formatado). **Não compacte automaticamente** — apenas sinalize; a compactação só roda quando o usuário pedir `/team-os *compact` (ver "Smart-Memory Compaction").

Se tasks existem: adicionar antes da pergunta:
```
  [!] Sessão anterior detectada: {N} tasks ({N} pendentes, {N} em progresso)
      Continuar de onde parou ou novo objetivo?
```

Se houver **mais de uma squad** instalada (prefixos distintos em `.claude/agents/`), adicionar:
```
  [⚠] Múltiplas squads instaladas ({lista}). Este projeto é de categoria {X} e
      deveria ter só a squad correspondente. Rode `/team-os-creator` → Atualizar
      para podar as squads sobrando.
```

### Fase 2 — Correções automáticas (em paralelo com a pergunta de objetivo)

Executar imediatamente, sem esperar o objetivo:

**A) AGENT_TEAMS:** já tratado no **Gate 0** (bloqueante, no topo do fluxo). Se você chegou aqui, o runtime já retornou `1`. Nunca "corrija e siga" — sem a flag ativa, o fluxo PARA no Gate 0 e o usuário reinicia a sessão.

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

**4b. Casting — escolher o archetype CERTO por tipo de trabalho (não chute):**

Mapeie cada tipo de trabalho ao papel correto. **Regras duras de casting:**

| Trabalho | Archetype certo | NUNCA use |
|---|---|---|
| Pesquisar/comparar/levantar dados | `analyst`/`researcher` | — |
| **Escrever entregável** (código, tutorial, doc, copy, spec) | `dev-*`/implementer (ou writer/copywriter da squad) | ❌ analyst (analyst só pesquisa, não escreve entregável) |
| **Abrir/gerenciar PR, push, release** | **`devops`** (autoridade EXCLUSIVA) | ❌ analyst, ❌ implementer (bloqueado por hook de push) |
| Validar/QA com veredicto | `qa`/reviewer | — |
| Arquitetura/stories | `architect` | — |

**Erros de casting que causam falha real:**
- "analyst escreve o conteúdo" → analyst entrega pesquisa, não o entregável. Use um `dev-*`/writer.
- "cada agente abre seu próprio PR" → push é gated: só `devops` empurra; implementers têm o hook que bloqueia. Padrão correto: escritores **commitam direto na branch ativa** → handoff (`SendMessage`) ao `devops` → ele faz push e abre os PRs.
- Se a squad não tem o papel ideal (ex.: sites sem copywriter dedicado), use o implementer mais próximo (`dev-gamma`) e avise o usuário — não force um analyst.

**4b.1 Mapear paralelismo real:**
- O que pode rodar SIMULTANEAMENTE? (sem dependência de dados/arquivos)
- O que tem dependência direta? (A deve completar antes de B começar)
- Quais agentes disponíveis em `.claude/agents/` batem com cada subtarefa (pelo casting acima)?

**4c. Dimensionamento — um agente por workstream genuinamente independente:**

A filosofia do team-os é **acelerar com paralelismo real**. **Comece com 3-5 teammates** e escale só conforme o trabalho genuinamente se beneficiar de mais paralelismo. O limite NÃO é um número mágico — é **independência real** + budget de tokens. Três teammates focados frequentemente superam cinco espalhados; não trate "mais agentes" como default.

```
1 workstream independente  =  1 agente

Workstream independente = bloco de trabalho com OWNERSHIP DE ARQUIVOS DISJUNTO
(não escreve nos mesmos arquivos que outro) e SEM dependência de dados de outro.

→ Mapeie os workstreams independentes do objetivo. Comece com os 3-5 mais relevantes
  e adicione mais só quando houver ganho real de paralelismo (não para "cobrir tudo de uma vez").
```

**Escale conforme o ganho real, com 3 guardrails (da spec oficial — não negociáveis):**
1. **Ownership exclusivo** — dois agentes nunca no mesmo arquivo. Se dois workstreams tocam o mesmo arquivo, eles NÃO são independentes: junte num agente só.
2. **Dependências viram sequência** — trabalho que depende de outro NÃO paraleliza. Use dependências na task list; não spawne agente ocioso esperando.
3. **Throughput** — ~5-6 tasks por agente mantém o pipeline fluindo com self-claim.

**Research adversarial:** investigação de causa raiz / hipóteses → 3-5 pesquisadores em paralelo mesmo com poucas tasks (valor vem da diversidade de perspectiva). Faça-os debater e refutar uns aos outros.

**Regra de ouro:** prefira **agentes em streams genuinamente independentes** a poucos agentes serializando trabalho paralelizável — mas adicione cada agente porque ele acelera, não por completude. Nunca spawne agentes que vão brigar pelo mesmo arquivo ou ficar esperando: isso queima tokens sem acelerar.

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

1. **Smart-memory** (se ausente): rodar o Discovery Engine primeiro — ver seção dedicada
2. **Tasks**: criar na task list (via as ferramentas de gerenciamento de tasks) com dependências corretas antes de spawnar
3. **Spawn imediato**: spawna TODOS os agentes do plano de uma vez (nomes curtos: `archi`, `alpha`, `beta`, `qa`, `ops`). Não execute nenhuma task você mesmo — cada uma é de um teammate.
4. **Lead fica livre**: após spawnar, seu trabalho é **monitorar, rotear e sintetizar** — nunca pegar trabalho. Se há demanda nova no meio, spawna mais um agente (não faça você).
5. **Nomear a sessão pela tarefa** (opcional, 1 tecla): o título da sessão já vem do projeto+branch (hook `SessionStart` — ver "Nomeação automática da sessão"). Para fixar TAMBÉM a tarefa atual no nome (útil ao retomar depois), imprima ao usuário um `/rename` pronto pra colar, com um slug curto do objetivo:
   ```
   💡 Para identificar esta sessão depois, fixe a tarefa no nome:
      /rename {projeto}: {slug-curto-do-objetivo}
   ```
   (Slash command é input do usuário — a skill não consegue executar `/rename` sozinha; por isso entregamos a linha pronta.)
6. **Orientar**: lembrar ao usuário os controles do agent panel

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

## Nomeação automática da sessão (SessionStart hook)

**Problema que resolve:** sem isso, toda sessão `/team-os` fica com nome genérico ("team-os bootstrap gate", "team-os social media session"…) — no agent view e no `/resume` você não distingue qual projeto é nem o que estava fazendo.

**Mecanismo (único robusto):** um hook `SessionStart` que emite `hookSpecificOutput.sessionTitle` — mesmo efeito do `/rename`, aplicado em `startup` e `resume`. É o **único** caminho com API oficial:
- A skill **não** consegue digitar `/rename` em si mesma (slash command é input do usuário).
- Escrever a entrada `agent-name` direto no `.jsonl` é frágil (o app regrava o nome em memória a cada turno).
- `UserPromptSubmit` **não** suporta `sessionTitle` (só `SessionStart`) — por isso "atualizar na primeira tarefa" automático não tem API; usa-se o `/rename` pronto da Fase 6.

**Convenção de nome:** `{nome-da-pasta-do-projeto} · {branch}` (a branch só aparece quando há git não-detached). Ex.: `joao-guirunas-site · main`. Preserva rename deliberado do usuário; migra títulos antigos `team-os …`.

**Registro (global — `~/.claude/settings.json`):** vale para todos os projetos de uma vez.
```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash \"$HOME/.claude/hooks/team-os-session-title.sh\"" }
      ] }
    ]
  }
}
```
O script `team-os-session-title.sh` acompanha o pack (`.claude/hooks/`). O `*install` do `team-os-creator` instala o hook em `~/.claude/hooks/` e registra o `SessionStart` global automaticamente. **Vale só em sessões iniciadas DEPOIS do registro** (a sessão atual não é renomeada — igual à flag `AGENT_TEAMS`).

---

## Smart-Memory Discovery Engine

Quando `docs/smart-memory/` não existe, o team-os **não cria scaffolding vazio** — ele faz *discovery* do projeto real e popula a base com conteúdo verdadeiro. Isso roda ANTES do Team Design, porque é o contexto que todos os agentes vão ler.

**Processo de discovery:**
1. **Rodar o script determinístico** (faz a detecção e gera a base populada):
   ```bash
   bash .claude/skills/team-os/scripts/discovery.sh          # ou --dry-run para só inspecionar
   ```
   Ele detecta stack (linguagens, frameworks, styling/UI, DB/ORM, testes, tooling, pkg manager, monorepo), mapeia os módulos e gera `INDEX.md` + `project/{overview,tech-stack,conventions,architecture,modules}.md` + `stories/BACKLOG.md` + a estrutura de pastas `stories/{backlog,active,in-review,done}/`, `decisions/` e `agents/{research,qa,data-engineer,ux,bi,data-performance}/`. É self-contained (só depende da skill team-os).
2. **Enriquecer os `<!-- TODO -->`** — o script deixa marcados os pontos que o código não revela (domínio/propósito do projeto, responsabilidade de cada módulo). Você (ou um teammate `*-analyst`/`*-architect`) preenche lendo o código e o README.
3. **Acelerar com paralelismo** — em codebase grande, delegue o enriquecimento a teammates em paralelo (um por área/módulo), cada um gravando sua seção.
4. **Validar com o usuário** — apresentar o resumo do que foi inferido e pedir correção do que estiver impreciso antes de seguir.

Use `team-os/reference/obsidian-patterns.md` para o padrão de frontmatter/wikilinks/tags. Só depois da smart-memory populada → Fase 4 (Team Design).

---

## Smart-Memory Compaction

A smart-memory é um **cache quente**, não um baú infinito. Ela guarda **estado e decisões, não histórico narrativo** (ver `reference/obsidian-patterns.md` §0-1). Com o tempo acumula conteúdo frio — stories concluídas, episódios resolvidos, cadeias supersedidas, logs — que infla o working set e queima tokens a cada sessão. A compactação separa o quente do frio.

**Princípio:** conteúdo frio é **movido** (nunca deletado) para `docs/smart-memory/_archive/YYYY-QN/`, fora do caminho de leitura. O `summary` de cada episódio sobrevive na tabela do `DIGEST.md` da área (memória institucional), e os LEDGERs indexam o que foi arquivado. O `_archive/` **não é lido** no bootstrap nem pelos agentes.

### Sinalização (automática, barata)

O `weigh-memory.sh` roda na **Fase 0** de todo `/team-os` e classifica a smart-memory:

| Limiar (env override) | Default | Dispara |
|---|---|---|
| `TOTAL_LINES_WARN` | 8.000 linhas | working set pesado |
| `DONE_FILES_WARN` | 30 arquivos em `stories/done/` | stories frias acumuladas |
| `FAT_FILE_LINES` | 1.500 linhas num único arquivo | arquivo gordo (candidato a esfriar) |
| `resolved`/`superseded` não-arquivados | ≥ 1 | episódios frios esquecidos no working set |

Qualquer limiar cruzado → `WEIGH_STATUS=HEAVY` e a linha do painel vira `⚠ PESADA (…) → /team-os *compact`. O bootstrap **só sinaliza**; a compactação roda no `*compact`.

### `*compact` — fluxo (UMA confirmação, depois executa tudo)

```
/team-os *compact          → plano completo + 1 confirmação + execução integral
/team-os *compact --auto   → sem confirmação: aplica o plano inteiro direto
```

O fluxo tem uma fase mecânica (script) e uma semântica (archivist). O lead monta **um único plano consolidado**, pede **uma única confirmação** (tabela: o que vira digest, o que vai pro archive, o que fica) e então executa tudo — **zero pergunta por arquivo**. Com `--auto`, nem a confirmação: mostra o plano e aplica.

**Passo 1 — Mecânico (script, sempre primeiro):**
```bash
bash .claude/skills/team-os/scripts/compact-memory.sh --dry-run   # colhe o plano mecânico
```
O script arquiva: `stories/done/*` e **toda nota com `status: resolved` ou `superseded`** no frontmatter (`--archive-resolved`, incluído no default). Gordos de `WEIGH_FAT_LIST` entram no plano como candidatos.

**Passo 2 — Semântico (archivist, quando o peso é largura):**
Se o peso vem de muitos arquivos sem metadata de ciclo de vida (caso típico de memória antiga, pré-v2), o mecânico não basta. Spawne **um teammate archivist** (archetype `analyst`/`researcher` da squad) com esta missão:

```
"Você é o archivist. Escopo EXCLUSIVO: docs/smart-memory/ (leitura) e
 docs/smart-memory/**/DIGEST.md + _archive/ (escrita).
 Missão em UMA passada:
 1. Para cada área (agents/*, decisions/), cluster por tópico e detecte:
    cadeias supersedidas (sufixos -r2/-r3/-v2, investigation-round*, audit→fix
    já corrigido), investigações fechadas, planos executados.
 2. Infira e grave o frontmatter v2 (kind/status/summary) nas notas que não têm.
 3. Escreva/atualize o DIGEST.md de cada área (template team-os/templates/digest.md):
    estado atual + tabela de episódios com summaries de 1-2 linhas.
 4. Produza o PLANO DE COMPACTAÇÃO: tabela [arquivo | veredicto quente/frio | razão].
    NÃO mova nada ainda. Reporte ao lead via SendMessage."
```

**Passo 3 — Confirmação única:** o lead consolida mecânico + semântico numa tabela só e apresenta: `N arquivos → _archive · M summaries → DIGESTs · K ficam quentes`. Usuário dá **um** "sim" (ou já rodou com `--auto`).

**Passo 4 — Execução integral, sem mais perguntas:**
```bash
bash .claude/skills/team-os/scripts/compact-memory.sh                     # done + resolved/superseded
bash .claude/skills/team-os/scripts/compact-memory.sh --archive-file <p>  # cada frio do plano semântico
```
Ao final: re-pesar (`weigh-memory.sh`) e reportar antes/depois em linhas.

**Segurança (regra dura):** `compact-memory.sh` **só faz `mv`, nunca `rm`**. Não toca em `stories/active`, `in-review`, `backlog`, `project/`, `INDEX.md` nem em notas `kind: reference` ou `DIGEST.md`. Zero perda — o conteúdo integral vive em `_archive/`, o summary vive no DIGEST.

**Lead Discipline:** disparar os scripts e consolidar o plano é coordenação — o lead faz. O julgamento semântico (quente/frio, summaries, DIGESTs) é trabalho substantivo — **é do archivist**, nunca do lead.

### Estrutura criada

```
docs/smart-memory/
├── INDEX.md                    ← MOC raiz — wikilinks para todas as seções
├── project/
│   ├── overview.md             ← visão geral do projeto (preencher junto com o usuário)
│   ├── tech-stack.md           ← stack detectado automaticamente + confirmar
│   ├── conventions.md          ← padrões de código do projeto
│   ├── architecture.md         ← visão arquitetural + diagrama Mermaid (dev-architect refina)
│   └── modules.md              ← mapa de módulos + God Nodes (devs enriquecem)
├── decisions/                  ← decisões técnicas / ADRs pontuais
├── stories/
│   ├── BACKLOG.md              ← lista master de todas as stories
│   ├── backlog/                ← stories aguardando priorização
│   ├── active/                 ← stories em andamento
│   ├── in-review/              ← stories em revisão/QA
│   └── done/                   ← stories concluídas
├── agents/                     ← saídas por agente (findings, QA, research)
│   ├── research/               ← findings de pesquisa (dev-analyst/researcher escreve)
│   │   └── DIGEST.md           ← resumo vivo da área (≤150 linhas) — ÚNICA leitura obrigatória
│   ├── qa/          (+DIGEST)  ← resultados de auditorias e QA (dev-qa escreve)
│   ├── data-engineer/ (+DIGEST) ← saídas de dados / schema
│   ├── ux/          (+DIGEST)  ← saídas de UX
│   ├── bi/          (+DIGEST)  ← saídas de BI
│   └── data-performance/ (+DIGEST) ← saídas de performance/insights
└── _archive/                   ← arquivo morto (conteúdo frio compactado). NÃO é lido no
    │                              bootstrap nem pelos agentes — só sob pedido explícito.
    ├── README.md               ← explica a convenção (criado pelo discovery)
    ├── LEDGER.md               ← índice de arquivos gordos esfriados (criado pelo *compact)
    └── YYYY-QN/                ← criado sob demanda pelo *compact (stories-done/, misc/)
```

> `_archive/` fica fora do working set: o `weigh-memory.sh` o exclui da contagem de peso e os agentes não o leem (convenção reforçada no Smart-Memory Protocol). Ver "Smart-Memory Compaction".

**`INDEX.md` template:**
```markdown
---
title: "Smart-Memory — {Nome do Projeto}"
type: index
agent: team-os (discovery)
created: {data}
updated: {data}
tags: [index, smart-memory]
---

# Smart-Memory — {Nome do Projeto}

## Projeto
- [[project/overview]] — Visão geral
- [[project/tech-stack]] — Stack tecnológico (detectado)
- [[project/conventions]] — Padrões de código

## Arquitetura
- [[project/architecture]] — Visão arquitetural

## Módulos
- [[project/modules]] — Mapa de módulos + God Nodes

## Stories
- [[stories/BACKLOG]] — Backlog master

## Saídas por agente
- [[agents/research/]] · [[agents/qa/]] · [[agents/data-engineer/]] · [[agents/ux/]] · [[agents/bi/]] · [[agents/data-performance/]]
```

**Injetar no `CLAUDE.md` do projeto** (criar se não existir, adicionar seção se já existe):

```markdown
## Smart-Memory Protocol

Este projeto mantém base de conhecimento em `docs/smart-memory/` (formato Obsidian).

**Todo agente, teammate ou sessão deve (leitura em camadas):**
1. Ao iniciar: ler `docs/smart-memory/INDEX.md` + o `DIGEST.md` da sua área + stories ativas — **nunca pastas inteiras**. Notas profundas só quando o DIGEST/wikilink apontar.
2. Ao concluir: atualizar a nota viva in-place (nunca criar `-v2`/`-r3`) ou criar episódio com frontmatter completo (`kind`, `status`, `summary`) e refletir a linha no `DIGEST.md` da área.
3. Atualizar `INDEX.md` ao criar arquivos novos na smart-memory.
4. **Nunca ler `docs/smart-memory/_archive/`** — é conteúdo frio (compactado). Consulte-o só se um LEDGER/DIGEST apontar um item específico que você precisa.
5. A memória guarda **estado e decisões, não histórico narrativo** — evidência bruta (dumps, logs) não entra no working set.

**Padrão:** YAML frontmatter + wikilinks `[[...]]` + tags canônicas.
```

---

## Protocolos de spawn

> ⛔ **PROIBIDO: `isolation: worktree`** — NUNCA spawnar agentes com `isolation: worktree`. Isso cria branches isoladas automáticas, impede que as mudanças apareçam no working directory principal (onde o servidor dev roda), gera branches zumbis no git e quebra o fluxo de trabalho local. Todo agente escreve **diretamente na branch ativa** (main). Se dois agentes podem conflitar no mesmo arquivo, resolva com **ownership disjunto** — não com isolation.

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

> **🎯 Como ter o painel navegável (setas ↑↓) — leia se você usa `claude agents`:**
> O painel de teammates é da **sessão que rodou o `/team-os`**, não do agent view. No fluxo `claude agents`:
> 1. Dispache/abra uma sessão e **dê attach nela** (Enter/→ na linha dela). Você precisa estar **dentro** da sessão.
> 2. Rode `/team-os` aí dentro (com Agent Teams ativo — Gate 0). Os teammates aparecem no painel **dessa sessão**, navegáveis por ↑↓.
> 3. Se você sair (detach) para o agent view, o painel some — os teammates seguem vivos na sessão; reattach (Enter) para voltar a navegar.
>
> **Alternativa mais simples para orquestrar ao vivo:** abra `claude` (foreground) direto no projeto e rode `/team-os` — o painel navegável fica logo abaixo do prompt, sem precisar de attach. Use `claude agents` quando quiser tocar várias sessões em background; use `claude` foreground quando quiser pilotar o time de perto.

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
Adicione um agente por vez, conforme cada um acelerar de fato o trabalho paralelo real — não para "cobrir tudo de uma vez".

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

**8. Smart-memory enxuta (leitura em camadas + compactação)**
Cada agente lê **INDEX + DIGEST da sua área + stories ativas** — nunca pastas inteiras. O DIGEST (≤150 linhas) é a porta de entrada; notas profundas só sob demanda via wikilink. Escrita é update-in-place com frontmatter de ciclo de vida (`kind`/`status`/`summary`). O bootstrap pesa a base e sinaliza quando engorda; `/team-os *compact` move o frio ao `_archive/` numa tacada só. Ver "Smart-Memory Compaction" e `reference/obsidian-patterns.md`.

---

## Hooks de qualidade (opcionais por projeto)

Configure em `.claude/settings.json` do projeto para enforçar padrões automaticamente:

### TeammateIdle — opcional, e CUIDADO com loop

> **Atenção:** ficar ocioso é o estado **desejado** (teammate vivo, esperando mais task). O que resolve o encerramento precoce é a **regra Team Persistence** (acima), não este hook. Use o hook só se quiser que teammates puxem tasks pendentes em vez de ociar — e **nunca** com `exit 2` incondicional (isso gera loop infinito: o teammate nunca consegue parar).

Versão **segura** (só nudge informativo, `exit 0` — não bloqueia o idle):
```json
{
  "hooks": {
    "TeammateIdle": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Teammate ocioso (vivo). Se há tasks pendentes na fila, faça self-claim.'; exit 0"
      }]
    }]
  }
}
```
Para "manter trabalhando", o comando só deve sair com `exit 2` **se houver task pendente compatível na fila** — caso contrário `exit 0`. Um `exit 2` fixo trava o teammate em loop. Não é auto-instalado nos projetos por padrão.

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
| Agentes criando branches extras | Lead usou `isolation: worktree` ao spawnar — proibido | NUNCA usar isolation: worktree. Agentes escrevem direto na branch ativa. Resolve conflito de arquivo com ownership disjunto (paths exclusivos por agente). |
| Resume não restaura teammates | Limitação: `/resume` não restaura in-process teammates | Re-spawnar com mesmo nome + contexto do smart-memory |
| Task travada (done mas não marca) | Bug known: task status pode atrasar | Verificar se work está feito → atualizar manualmente ou pedir ao lead |
| Agente sumiu do panel | Idle após 30s (hide automático, v2.1.181+) — NÃO parou, reaparece no próximo turno | SendMessage por nome: `"Mensagem para {nome}: continue"` |
| Lead começa a implementar sozinho | Violação da Lead Discipline | Ver seção "⛔ Lead Discipline" — o lead NUNCA executa, só delega. `"Pare e spawna um agente para isso; você é o orquestrador"` |
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
/team-os *compact       → compactação integral: mecânica + semântica (archivist), 1 confirmação
/team-os *compact --auto → idem, sem confirmação (mostra o plano e aplica)
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
