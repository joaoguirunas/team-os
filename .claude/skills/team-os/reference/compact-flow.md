# `*compact` — fluxo detalhado (Smart-Memory Compaction v3)

> Extraído do SKILL.md — carregar sob demanda. O resumo do que `*compact` faz e a sinalização (weigh) estão na seção "Smart-Memory Compaction" do SKILL.md.

## `*compact` — fluxo (UMA confirmação, depois executa tudo)

```
/team-os *compact          → plano completo + 1 confirmação + execução integral
/team-os *compact --auto   → sem confirmação: aplica o plano inteiro direto
```

O fluxo tem uma fase mecânica (script), uma de **consolidação** (archivist + `_inbox/`) e uma semântica (archivist sobre o working set). O lead monta **um único plano consolidado**, pede **uma única confirmação** (tabela: o que vira digest, o que vai pro archive, o que fica) e então executa tudo — **zero pergunta por arquivo**. Com `--auto`, nem a confirmação: mostra o plano e aplica.

**Passo 1 — Mecânico (script, sempre primeiro):**
```bash
bash .claude/skills/team-os/scripts/compact-memory.sh --dry-run   # colhe o plano mecânico
```
O script arquiva automaticamente: `stories/done/*`, **toda nota com `status: resolved` ou `superseded`** e — novo no v3 — **toda nota com `expires: YYYY-MM-DD` vencido (TTL)** → `_archive/<Q>/expired/`, registrada no LEDGER como "(expired)". Nunca toca em `project/`, `decisions/`, stories ativas, `_inbox/`, DIGESTs e INDEXes. O dry-run também reporta o inbox pendente (`COMPACT_INBOX_PENDING=<n>` + lista `INBOX:`). Gordos de `WEIGH_FAT_LIST` entram no plano como candidatos via `--archive-file`.

**Passo 2 — Consolidação do `_inbox/` (archivist, quando `COMPACT_INBOX_PENDING > 0`):**
Durante as sessões, os agentes anotam barato em `docs/smart-memory/_inbox/` — a curadoria é adiada para cá. O archivist:

1. Lê o `_inbox/` **inteiro de uma vez** (leitura em lote, não nota a nota ao longo da sessão).
2. **Funde, deduplica e supersede** contra os DIGESTs das áreas: cada informação vira fato atômico datado no DIGEST certo (Core ou Contexto recente), substituindo fato antigo quando for o caso; o que merecer nota própria vira nota com frontmatter v3 (`kind`/`status`/`summary`, `expires` se tiver prazo).
3. **Zera o inbox**: para cada nota consolidada,
   ```bash
   bash .claude/skills/team-os/scripts/compact-memory.sh --clear-inbox <arquivo>
   ```
   (move para `_archive/<Q>/inbox/` + linha no LEDGER — nada é deletado).

**Passo 3 — Semântico (archivist, quando o peso é largura):**
Se o peso vem de muitos arquivos sem metadata de ciclo de vida (caso típico de memória antiga, pré-v2), o mecânico não basta. Spawne **um teammate archivist** (archetype `analyst`/`researcher` da squad) com esta missão:

```
"Você é o archivist. Escopo EXCLUSIVO: docs/smart-memory/ (leitura) e
 docs/smart-memory/**/DIGEST.md + _inbox/ + _archive/ (escrita).
 Missão em UMA passada:
 1. Consolide o _inbox/ (se houver): funda/deduplique/supersede contra os
    DIGESTs e zere via --clear-inbox (passo 2 do compact-flow).
 2. Para cada área (agents/*, decisions/), cluster por tópico e detecte:
    cadeias supersedidas (sufixos -r2/-r3/-v2, investigation-round*, audit→fix
    já corrigido), investigações fechadas, planos executados, notas com prazo
    natural sem `expires:` (adicione o TTL).
 3. Infira e grave o frontmatter v3 (kind/status/summary, expires quando couber)
    nas notas que não têm.
 4. Escreva/atualize o DIGEST.md de cada área (template team-os/templates/digest.md,
    formato v3): fatos atômicos datados em Core/Contexto recente + Apontadores.
    Máx ~40 linhas, bullets ≤200 chars, fato novo substitui o antigo.
 5. Produza o PLANO DE COMPACTAÇÃO: tabela [arquivo | veredicto quente/frio | razão].
    NÃO mova nada ainda. Reporte ao lead via SendMessage."
```

**Passo 4 — Confirmação única:** o lead consolida mecânico + consolidação + semântico numa tabela só e apresenta: `N arquivos → _archive (X resolved · Y expired · Z inbox) · M fatos → DIGESTs · K ficam quentes`. Usuário dá **um** "sim" (ou já rodou com `--auto`).

**Passo 5 — Execução integral, sem mais perguntas:**
```bash
bash .claude/skills/team-os/scripts/compact-memory.sh                     # done + resolved/superseded + TTL vencido
bash .claude/skills/team-os/scripts/compact-memory.sh --archive-file <p>  # cada frio do plano semântico
bash .claude/skills/team-os/scripts/compact-memory.sh --clear-inbox <f>   # cada inbox consolidado (se restou)
```

**Passo 6 — Relatório de órfãos + re-pesagem:** todo modo do `compact-memory.sh` que move arquivo varre o working set por wikilinks `[[...]]` que apontavam para o que saiu e reporta `COMPACT_ORPHAN_LINKS=<n>` com a lista (`ORPHAN_LINK: [[nota]] ainda referenciado em: ...`). O lead (ou o archivist) corrige cada órfão — aponta para o LEDGER ou remove a referência. Ao final: re-pesar (`weigh-memory.sh`) e reportar antes/depois em linhas **e em bootstrap tokens** (`WEIGH_BOOTSTRAP_MAX`).

**Segurança (regra dura):** `compact-memory.sh` **só faz `mv`, nunca `rm`**. Não toca em `stories/active`, `in-review`, `backlog`, `project/`, `decisions/`, `INDEX.md` nem em notas `kind: reference` ou `DIGEST.md` — em **nenhum modo** (o `--archive-file` aplica as mesmas guardas: nunca INDEX/DIGEST/LEDGER, nunca `kind: reference|digest`, nada fora de `docs/smart-memory/`, paths com `..` rejeitados). Zero perda — o conteúdo integral vive em `_archive/`, o fato/summary vive no DIGEST.

**Lead Discipline:** disparar os scripts e consolidar o plano é coordenação — o lead faz. O julgamento semântico (quente/frio, fatos atômicos, DIGESTs, consolidação do inbox) é trabalho substantivo — **é do archivist**, nunca do lead (ver "⛔ Lead Discipline" no SKILL.md).
