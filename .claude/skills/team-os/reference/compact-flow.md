# `*compact` — fluxo detalhado (Smart-Memory Compaction v3)

> Extraído do SKILL.md — carregar sob demanda. O resumo do que `*compact` faz e a sinalização (weigh) estão na seção "Smart-Memory Compaction" do SKILL.md.

## Compactação automática (Fase 2-F — mecânica, sem confirmação)

Todo `/team-os` pesa a memória na Fase 0. Se `WEIGH_STATUS=HEAVY` **ou** `WEIGH_ARCHIVABLE>0`, a Fase 2-F roda a fase **mecânica** sozinha, sem perguntar:

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/compact-memory.sh" --mechanical-only   # só mv
bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/weigh-memory.sh" --quiet             # re-pesa
```

- Move só o que já está decidido como frio: `stories/done/*`, notas `status: resolved|superseded` e `expires:` vencido. Nada é reescrito nem apagado (mesmas guardas do `*compact`).
- Lê `COMPACT_MOVED=<n>` (última linha do script; também `COMPACT_MOVED_STORIES/RESOLVED/EXPIRED`) e mostra no painel `compactado: N arquivados`. `COMPACT_ORPHAN_LINKS>0` → aviso no painel (corrigir no próximo `*compact`).
- O que exige julgamento — `_inbox/`, DIGEST acima do teto (`WEIGH_DIGEST_OVER`), notas sem metadata, gordos — **não** é automático: continua no `*compact` (archivist).
- **Opt-out:** `TEAM_OS_AUTO_COMPACT=0` (env da sessão ou `env` do `.claude/settings.json`) → a 2-F só sinaliza, como antes.
- No CT (`IS_CT=1`, sem smart-memory → `WEIGH_STATUS=ABSENT`) nada acontece.

## `*compact` — fluxo (UMA confirmação, depois executa tudo)

```
/team-os *compact          → plano completo + 1 confirmação + execução integral
/team-os *compact --auto   → sem confirmação: aplica o plano inteiro direto
```

O fluxo tem uma fase mecânica (script), uma de **consolidação** (archivist + `_inbox/`) e uma semântica (archivist sobre o working set). O lead monta **um único plano consolidado**, pede **uma única confirmação** (tabela: o que vira digest, o que vai pro archive, o que fica) e então executa tudo — **zero pergunta por arquivo**. Com `--auto`, nem a confirmação: mostra o plano e aplica.

**Passo 1 — Mecânico (script, sempre primeiro):**
```bash
bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/compact-memory.sh" --dry-run   # colhe o plano mecânico
```
O script arquiva automaticamente: `stories/done/*`, **toda nota com `status: resolved` ou `superseded`** e — novo no v3 — **toda nota com `expires: YYYY-MM-DD` vencido (TTL)** → `_archive/<Q>/expired/`, registrada no LEDGER como "(expired)". Nunca toca em `project/`, `decisions/`, stories ativas, `_inbox/`, DIGESTs e INDEXes. O dry-run também reporta o inbox pendente (`COMPACT_INBOX_PENDING=<n>` + lista `INBOX:`). Gordos de `WEIGH_FAT_LIST` entram no plano como candidatos via `--archive-file`. `WEIGH_DIGEST_OVER_LIST` (`path:linhas;…`, todo `DIGEST.md` acima de `DIGEST_MAX_LINES`, default 60) vai **inteiro** para o prompt do archivist (passo 3).

**Passo 2 — Consolidação do `_inbox/` (archivist, quando `COMPACT_INBOX_PENDING > 0`):**
Durante as sessões, os agentes anotam barato em `docs/smart-memory/_inbox/` — a curadoria é adiada para cá. O archivist:

1. Lê o `_inbox/` **inteiro de uma vez** (leitura em lote, não nota a nota ao longo da sessão).
2. **Funde, deduplica e supersede** contra os DIGESTs das áreas: cada informação vira fato atômico datado no DIGEST certo (Core ou Contexto recente), substituindo fato antigo quando for o caso; o que merecer nota própria vira nota com frontmatter v3 (`kind`/`status`/`summary`, `expires` se tiver prazo).
3. **Zera o inbox**: para cada nota consolidada,
   ```bash
   bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/compact-memory.sh" --clear-inbox <arquivo>
   ```
   (move para `_archive/<Q>/inbox/` + linha no LEDGER — nada é deletado).

**Passo 3 — Semântico (archivist, quando o peso é largura):**
Se o peso vem de muitos arquivos sem metadata de ciclo de vida (caso típico de memória antiga, pré-v2) **ou há DIGEST acima do teto**, o mecânico não basta. Spawne **um teammate archivist** (archetype `analyst`/`researcher` da squad) com esta missão (substitua `{DIGEST_OVER_LIST}` pelo valor de `WEIGH_DIGEST_OVER_LIST`, um por linha):

```
"Você é o archivist. Escopo EXCLUSIVO: docs/smart-memory/ (leitura) e
 docs/smart-memory/**/DIGEST.md + _inbox/ + _archive/ (escrita).
 Missão em UMA passada:
 1. Consolide o _inbox/ (se houver): funda/deduplique/supersede contra os
    DIGESTs e zere via --clear-inbox (passo 2 do compact-flow).
 2. Para cada área (agents/<squad>/<área>/, decisions/), cluster por tópico e detecte:
    cadeias supersedidas (sufixos -r2/-r3/-v2, investigation-round*, audit→fix
    já corrigido), investigações fechadas, planos executados, notas com prazo
    natural sem `expires:` (adicione o TTL).
 3. Infira e grave o frontmatter v3 (kind/status/summary, expires quando couber)
    nas notas que não têm.
 4. Escreva/atualize o DIGEST.md de cada área (template team-os/templates/digest.md,
    formato v3): fatos atômicos datados em Core/Contexto recente + Apontadores.
    ~40 linhas (máx 60), bullets ≤200 chars, fato novo substitui o antigo.
 5. OBRIGATÓRIO — DIGESTs acima do teto (enxugue cada um para ~40 linhas):
    {DIGEST_OVER_LIST}
    Core fica só com o permanente; fato datado vai para "Contexto recente" com
    `expires:`; histórico sai para _archive/ via compact-memory.sh --archive-file
    (nota própria primeiro, se o DIGEST não puder ser arquivado).
 6. Produza o PLANO DE COMPACTAÇÃO: tabela [arquivo | veredicto quente/frio | razão].
    NÃO mova nada ainda. Escreva o plano em _inbox/archivist-plano.md e mande ao
    lead uma mensagem [handoff] curta com o path.
 Leitura: o hook guard-smart-memory-read.sh limita 3 notas L2 por busca — rode
 sm-find.sh por área/tópico antes de cada lote (o contador zera a cada busca);
 _archive/ nunca é lido."
```

**Passo 4 — Confirmação única:** o lead consolida mecânico + consolidação + semântico numa tabela só e apresenta: `N arquivos → _archive (X resolved · Y expired · Z inbox) · M fatos → DIGESTs · K ficam quentes`. Usuário dá **um** "sim" (ou já rodou com `--auto`).

**Passo 5 — Execução integral, sem mais perguntas:**
```bash
bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/compact-memory.sh"                     # done + resolved/superseded + TTL vencido
bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/compact-memory.sh" --archive-file <p>  # cada frio do plano semântico
bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/compact-memory.sh" --clear-inbox <f>   # cada inbox consolidado (se restou)
```

**Passo 6 — Relatório de órfãos + re-pesagem:** todo modo do `compact-memory.sh` que move arquivo varre o working set por wikilinks `[[...]]` que apontavam para o que saiu e reporta `COMPACT_ORPHAN_LINKS=<n>` com a lista (`ORPHAN_LINK: [[nota]] ainda referenciado em: ...`). O lead (ou o archivist) corrige cada órfão — aponta para o LEDGER ou remove a referência. Ao final: re-pesar (`weigh-memory.sh`) e mostrar o **placar** — `weigh-memory.sh --report` imprime `WEIGH_REPORT=Memória: A → B linhas (±n) · bootstrap pior área X → Y tokens · N notas arquivadas` contra a baseline gravada na Fase 0 (`--save-start`). `WEIGH_DIGEST_OVER` tem que voltar a 0.

**Segurança (regra dura):** `compact-memory.sh` **só faz `mv`, nunca `rm`**. Não toca em `stories/active`, `in-review`, `backlog`, `project/`, `decisions/`, `INDEX.md` nem em notas `kind: reference` ou `DIGEST.md` — em **nenhum modo** (o `--archive-file` aplica as mesmas guardas: nunca INDEX/DIGEST/LEDGER, nunca `kind: reference|digest`, nada fora de `docs/smart-memory/`, paths com `..` rejeitados). Zero perda — o conteúdo integral vive em `_archive/`, o fato/summary vive no DIGEST.

**Lead Discipline:** disparar os scripts e consolidar o plano é coordenação — o lead faz. O julgamento semântico (quente/frio, fatos atômicos, DIGESTs, consolidação do inbox) é trabalho substantivo — **é do archivist**, nunca do lead (ver "⛔ Lead Discipline" no SKILL.md).
