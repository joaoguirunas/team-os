# Otimização de tokens

> Extraído do SKILL.md — carregar sob demanda.


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

**8. Smart-memory enxuta (leitura em camadas L0/L1/L2 + compactação)**
Cada agente lê **L0** (INDEX + DIGEST da sua área + stories ativas), busca via **L1** (`sm-find.sh` pelos summaries — path/kind/status/summary) e só abre nota inteira no **L2** com summary confirmando — **máx 3 notas por tarefa**, nunca pastas inteiras. O DIGEST (~40 linhas, máx 60; "Core (permanente)" + "Contexto recente" com decay de ~14 dias) é a porta de entrada; o `weigh-memory.sh` mede o custo do L0 por área contra o budget (2000 tokens). Escrita de sessão vai ao `_inbox/`; frontmatter de ciclo de vida (`kind`/`status`/`summary`/`expires`/`supersedes`). O bootstrap pesa a base e sinaliza quando engorda; `/team-os *compact` consolida o inbox e move o frio ao `_archive/` numa tacada só. Ver "Leitura em camadas", "Smart-Memory Compaction" e `reference/obsidian-patterns.md`.

Desde a v3 as regras desta alavanca são **mecanismo**, não só pedido:
- **Compactação automática** (Fase 2-F): `HEAVY` ou arquivável → `compact-memory.sh --mechanical-only` roda sem confirmação (só `mv`), re-pesa e o painel mostra `compactado: N arquivados` (`COMPACT_MOVED`). Opt-out `TEAM_OS_AUTO_COMPACT=0`. A parte semântica fica no `*compact`.
- **Teto de DIGEST**: `DIGEST.md` acima de `DIGEST_MAX_LINES` (60) conta como `HEAVY` (`WEIGH_DIGEST_OVER`/`_LIST`); o archivist tem como item obrigatório enxugar cada um para ~40 linhas.
- **Buscar em vez de ler** (`guard-smart-memory-read.sh`): `_archive/` e leitura de pasta inteira bloqueados; a 4ª nota L2 distinta sem nova busca é bloqueada — o `sm-find.sh` zera o contador.
- **Mensagens curtas** (`guard-message-size.sh`): SendMessage acima de 20 linhas / 1.500 caracteres é bloqueado; `[handoff]` na 1ª linha libera até 60 / 4.000 para o resultado final ao lead.

## Placar da sessão

Mede se a sessão deixou a memória mais leve ou mais pesada — sem estimativa, contando linhas e tokens do L0.

```bash
W="$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/weigh-memory.sh"
bash "$W" --quiet --save-start   # Fase 0: grava a baseline (${TMPDIR:-/tmp}/team-os-weigh-<cksum do path>.start)
bash "$W" --report               # fim da rodada / *status / fim do *compact
```

O `--report` re-pesa e imprime:

| Chave | Significado |
|---|---|
| `WEIGH_DELTA_LINES=<±n>` | linhas do working set agora − na baseline |
| `WEIGH_DELTA_FILES=<±n>` | arquivos do working set agora − na baseline |
| `WEIGH_DELTA_BOOTSTRAP_MAX=<±n>` | tokens do L0 da pior área agora − na baseline |
| `WEIGH_ARCHIVED_SESSION=<n>` | linhas em `_archive/` agora − na baseline (o que saiu do working set) |
| `WEIGH_ARCHIVED_SESSION_FILES=<n>` | notas em `_archive/` agora − na baseline |
| `WEIGH_REPORT=…` | linha pronta para o painel: `Memória: 1.240 → 1.180 linhas (−60) · bootstrap pior área 1.900 → 1.400 tokens · 12 notas arquivadas` |

Sem baseline (sessão não passou pela Fase 0, `TMPDIR` limpo) → `WEIGH_REPORT=sem baseline desta sessão`. Sem smart-memory (CT) → `WEIGH_REPORT=sem smart-memory neste projeto`. A baseline é por projeto (hash do path) e sobrevive entre rodadas da mesma sessão; um novo `/team-os` a regrava.
