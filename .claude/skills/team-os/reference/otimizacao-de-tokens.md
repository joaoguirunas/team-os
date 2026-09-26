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
