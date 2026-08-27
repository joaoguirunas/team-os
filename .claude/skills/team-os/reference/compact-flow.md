# `*compact` — fluxo detalhado (Smart-Memory Compaction)

> Extraído do SKILL.md — carregar sob demanda. O resumo do que `*compact` faz e a sinalização (weigh) estão na seção "Smart-Memory Compaction" do SKILL.md.

## `*compact` — fluxo (UMA confirmação, depois executa tudo)

```
/team-os *compact          → plano completo + 1 confirmação + execução integral
/team-os *compact --auto   → sem confirmação: aplica o plano inteiro direto
```

O fluxo tem uma fase mecânica (script) e uma semântica (archivist). O lead monta **um único plano consolidado**, pede **uma única confirmação** (tabela: o que vira digest, o que vai pro archive, o que fica) e então executa tudo — **zero pergunta por arquivo**. Com `--auto`, nem a confirmação: mostra o plano e aplica.

**Passo 1 — Mecânico (script, sempre primeiro):**
```bash
bash .claude/skills/team-os/scripts/compact-memory.sh --dry-run   # colhe o plano mecânico
```
O script arquiva: `stories/done/*` e **toda nota com `status: resolved` ou `superseded`** no frontmatter (comportamento default — nunca toca em `project/`, `decisions/`, stories ativas, DIGESTs e INDEXes). Gordos de `WEIGH_FAT_LIST` entram no plano como candidatos via `--archive-file`.

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

**Lead Discipline:** disparar os scripts e consolidar o plano é coordenação — o lead faz. O julgamento semântico (quente/frio, summaries, DIGESTs) é trabalho substantivo — **é do archivist**, nunca do lead (ver "⛔ Lead Discipline" no SKILL.md).
