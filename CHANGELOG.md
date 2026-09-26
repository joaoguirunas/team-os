# Changelog

Todas as mudanças relevantes deste repositório. Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/); commits seguem [Conventional Commits](https://www.conventionalcommits.org/pt-br/).

## [2.3.0] — 2026-09-26 · Economia de tokens e painéis ao vivo

### Adicionado
- **`/sala-de-controle *painel`** — mapa vivo em tempo real (atualiza a cada segundo) no navegador do próprio Claude: a Sala no centro, um nó por projeto, um nó por sessão e os agentes de cada uma, com estado por cor, mensagens entre agentes, feed de eventos e leitor da smart-memory de cada projeto no estilo Obsidian (árvore, wikilinks, grafo). Mostra só quem está operando ou esperando o usuário; agentes parados somem após 30 minutos. Só lê, servidor apenas em `127.0.0.1:8787` (59dc366 … 7139309).
- **`/team-os-creator *painel`** — mapa vivo do CT em `127.0.0.1:8788`: raio no centro, as 10 squads no anel, agentes (persona + cargo) e skills; clique abre o perfil e o arquivo inteiro; layout com barra superior, busca e drawer (443b7a9 … 00f5902).
- **Compactação automática**: no início de cada `/team-os`, se a memória estiver pesada ou tiver notas arquiváveis, a fase mecânica do compact roda sozinha (só `mv`, nunca apaga). Opt-out: `TEAM_OS_AUTO_COMPACT=0`. A fase semântica continua no `*compact`.
- **Teto de DIGEST por script**: `weigh-memory.sh` marca todo `DIGEST.md` acima de 60 linhas (`DIGEST_MAX_LINES`) como HEAVY e o archivist tem o enxugamento como item obrigatório.
- **Hook `guard-smart-memory-read.sh`**: bloqueia leitura de `_archive/`, de pasta inteira e a 4ª nota fora do L0 sem nova busca (`sm-find.sh` zera o contador).
- **Hook `guard-message-size.sh`**: mensagens entre agentes com teto de 20 linhas / 1.500 caracteres; `[handoff]` até 60 linhas.
- **Placar da sessão**: `weigh-memory.sh --save-start` no início e `--report` no fim de rodada, no `*status` e no `*compact` ("Memória: 1.240 → 1.180 linhas (−60) · …").
- `compact-memory.sh --mechanical-only` e saída `COMPACT_MOVED=<n>`; 91 casos novos em `test-hooks.sh` (493 no total).

### Corrigido
- Modelos da Sala de Controle e do maestri-os trocam caminhos reais de máquina por exemplos genéricos (`<raiz>/Minha Marca/…`); o CI volta a checar essas pastas.
- `*install` da Sala de Controle põe `docs/smart-memory/sala-de-controle/snapshot.json` no `.gitignore` — o snapshot guarda trechos das conversas de todas as sessões da máquina.
- Painel da Sala: casa sessão ↔ projeto com acento, não pisca ao redimensionar, clique não se perde, botão da smart-memory aceita aspas no caminho.

### Alterado
- Bloco Native Teams Protocol (regras 1 e 4) cita os dois hooks novos e remove a brecha "grep de frontmatter"; reaplicado nos 95 agentes e 9 templates via `migrate-ntp.sh`.

## [2.2.0] — 2026-09-25 · Auditoria completa aplicada

### Corrigido
- **Hooks de task (`task-quality`, `check-*-progress`) estavam inertes**: liam `title`/`subject` em vez dos campos reais `task_subject`/`task_description` do Claude Code. Corrigidos e cobertos por `scripts/test-hooks.sh`.
- **Guards de git** (`block-git-push`, `block-worktree`, `guard-push-branch`): bloqueiam shell embutido (`sh -c`, `eval`, `xargs`, heredoc, `python -c`), alias inline (`git -c alias.x=push`), `send-pack`, `gh release`/`repo sync`; `guard-push-branch` decide pela branch do repo alvo; `block-worktree` deixa de bloquear `git branch -m/-M/-u`.
- **Regex dos gates em português**: "relatório das campanhas" não bloqueia mais; "Pagar fornecedor X" agora exige PASS; negação ("não aprovado") não conta como aprovação; particípios ("contrato enviado pela contraparte") não bloqueiam.
- **`*install`/`*propagate` copiava 1,3 GB** de runtime da skill `seo` (`.venv`, `ms-playwright`) para cada projeto destino.
- **`*install` cortava skills citadas pelos agentes** de outra squad; agora a lista é derivada do que os agentes instalados citam.
- **`discovery.sh` criava áreas que os agentes não liam** (e não cobria `seo`); áreas agora derivadas da linha `**Área na smart-memory:**` de cada agente.
- Squad `seo` ausente das listas do `team-os`, do `team-os-creator` e do `detect-project-signals.sh`.
- Referências quebradas em skills (`extensions/` inexistente nas `seo-*`, links para repositórios de origem em `sales-enablement`, `data-lake-platform`, `seo-flow`, `slides`).
- Nomes de tools MCP inválidos na squad Social.
- README: contagens, política de modelos, archetypes (9), presets (10), estrutura §5/§6, dimensionamento, comandos e flags do `team-os-creator`.
- `CLAUDE.md` contradizia a si mesmo sobre `block-git-push.sh`.
- Caminho de Python de uma máquina (`CLAUDE_SEO_PYTHON`) commitado em `.claude/settings.json` (movido para `settings.local.json`).

### Alterado
- **Convenção de smart-memory por squad**: `docs/smart-memory/agents/<squad>/<área>/` (antes `agents/<área>/`, que colidia quando duas squads dividiam a mesma pasta). PM sai de `docs/smart-memory/pm/` para `agents/pm/`.
- **Convenção única de stories**: `stories/BACKLOG.md` + `stories/{backlog,active,in-review,done}/<id>-<slug>.md`.
- Squad PM tornada genérica (schema/RPCs específicos de um produto saíram dos agentes).
- Descrições de agentes e skills em português; teto de tamanho (300/400 caracteres).
- `team-os/SKILL.md` reduzido; seções longas movidas para `reference/` (carga sob demanda).
- `validate-agent.sh`: novos checks (`permissionMode`/`effort` obrigatórios, linha de área, paths canônicos, tools MCP contra `reference/mcp-servers.md`, `hooks:` do frontmatter, modo `--skills`).
- `*install` faz merge de `settings.json` (via `ensure-settings.sh`) e backup `.claude.bak-<data>/`.
- `docs/agentes.html` sem fontes externas; verificado no CI (`--check`).

### Adicionado
- `LICENSE` (MIT) e `THIRD_PARTY_NOTICES.md` com a origem e a licença de cada skill importada.
- `scripts/test-hooks.sh`, `scripts/migrate-ntp.sh`, `reference/mcp-servers.md`, `reference/ntp-canonical.md`.
- `CONTRIBUTING.md`, `CHANGELOG.md`, `.editorconfig`, `.gitattributes`.
- CI: teste dos hooks, lint das skills, checagem da página de agentes e dos hooks executáveis.

## [2.1.0] — 2026-09-25

### Adicionado
- `sala-de-controle`: skill opt-in que roteia pedidos entre as sessões do Claude Code (18b1fe2, 411fbba, aaa682c).
- `docs/agentes.html`: perfil completo em modal e tabela de totais por squad (393c5b0, bcc527d).
- Squad **SEO** — 15 agentes, 27 skills, incorporação do claude-seo v2.3.1 (0abf135).
- Squads **Finance** e **Legal** — 16 agentes, 10 skills, 2 hooks de garantia (5fb6182).
- Squad **Brand** — 8 agentes, 6 skills, 2 gates (b869e85).
- Squad **Sales** — 8 agentes, 11 skills, gate de envio (9972c52).
- `maestri-os`: Sala de Controle para o Maestri (3281163 … fbcbc94).
- Squad Sites ganha Astro (85b6c93); `ui-ux-pro-max` v2.13 ligado aos agentes UX (7462a01).

### Corrigido
- Removido o teto arbitrário de 10 agentes simultâneos/por squad (59400e1).

## [2.0.0] — 2026-09-05

### Adicionado
- Ondas 1–5: auditoria aplicada, Smart-Memory v3 (orçamento de tokens, fatos atômicos, TTL, inbox), orquestração de elite, main blindada e fábrica com pressure-test (1e1acb4, 9b672aa, 36fee5a).
- Página oficial dos agentes + gerador (ac80ba7, 9b33ba8).
- Skills dos MCPs oficiais do Google (Ads + GA4) na squad Traffic (baa2bbf).

### Alterado
- Repositório autossuficiente, zero referências a projetos pessoais (130ee5b).

## [1.x] — 2026-04-23 → 2026-08-26

- Commit inicial com agentes, skills e hooks (b70017d).
- Squads Dev, Sites, Social, Traffic e PM; identidade dos agentes; Native Teams Protocol (7f3f64a); rebrand para team-os (2ae05b6).
- Garantia anti-worktree em todo o ecossistema (4274c32); Smart-Memory v2 (b2c900b); compactação (bbf0803).
- Auditoria de agosto: correções críticas, consistência, 6 skills novas (3592555).
