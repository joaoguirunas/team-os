# Integração smart-memory por archetype (taxonomia v3)

Todo agente gerado pela skill precisa saber **como lê** e **o que escreve em `docs/smart-memory/`** — e em que formato (padrão Obsidian, taxonomia v3). Esta referência é consumida pelos templates em `templates/{archetype}.md` — a seção "O que você escreve na smart-memory".

---

## Leitura em camadas (todo archetype — summary-first)

O prompt de todo agente gerado deve impor o protocolo de leitura L0/L1/L2:

1. **L0 (bootstrap):** `INDEX.md` + o `DIGEST.md` da **sua área** (`agents/<área>/DIGEST.md`) + stories ativas (`stories/active/*.md`). Nada além disso ao iniciar.
2. **L1 (busca):** para achar contexto além do L0, buscar pelos summaries:
   `bash "$CLAUDE_PROJECT_DIR/.claude/skills/team-os/scripts/sm-find.sh" "<termo>"` — saída `path / kind / status / summary`.
3. **L2 (nota inteira):** só quando o `summary` confirma relevância — **máximo 3 notas por tarefa**.
4. ⛔ Nunca ler pastas inteiras nem `_archive/`.

---

## Matriz: archetype × responsabilidade em smart-memory

| Archetype | Escreve em | Formato |
|---|---|---|
| `architect` | `project/architecture.md`, `project/modules.md`, `decisions/ADR-*.md`, `stories/backlog/*.md`, `stories/BACKLOG.md` | Obsidian + Mermaid |
| `implementer` | `stories/active/<N.M>-*.md` (só updates em Dev Agent Record / File List / AC) | Não cria arquivos, só atualiza |
| `hardening` | `stories/active/<N.M>-*.md` (mesmas regras do implementer) | Updates on story |
| `reviewer` (QA) | `agents/qa/DIGEST.md` (linha por veredicto) + episódios em `agents/qa/*.md`, seção QA Results da story | Veredicto formal |
| `researcher` | `agents/research/*.md` + `agents/research/DIGEST.md`, `project/tech-stack.md`, `project/conventions.md` | Research reports |
| `data` | `agents/data-engineer/schema.md`, `agents/data-engineer/migrations-log.md` (+ DIGEST da área) | Schema tabular + log |
| `devops` | `agents/devops/releases-log.md` (+ DIGEST da área) | Log de releases |
| `ux` | `agents/ux/components.md`, `agents/ux/flows/*.md` (+ DIGEST da área) | Component specs + ASCII wireframes + Mermaid user flows |

**Durante a sessão**, qualquer archetype pode (e deve, preferencialmente) anotar em `_inbox/<agente>-<data>.md` em vez de editar DIGESTs no meio do trabalho — a consolidação nos DIGESTs acontece no `/team-os *compact` (archivist funde, deduplica e aplica supersedes).

---

## Regras comuns (todos os archetypes)

1. **Frontmatter v3 obrigatório** em todo `.md` criado em `docs/smart-memory/`:
   ```yaml
   ---
   title: "..."
   kind: overview | story | decision | research | qa-result | schema | task-log | backlog | index | component-spec | episode | reference
   status: active | backlog | done | resolved | superseded | deprecated | proposed | accepted   # quando aplicável
   summary: "1 linha objetiva — é o que o sm-find e o archivist leem; obrigatório"
   agent: <nome-do-agente>
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   expires: YYYY-MM-DD          # SÓ em notas temporárias — TTL: o *compact arquiva quando vence
   supersedes: "[[nota-antiga]]" # quando esta nota substitui outra (a antiga vira status: superseded)
   tags: [...]
   related: ["[[...]]", "[[...]]"]
   ---
   ```
   `kind`, `status` e `summary` são o mínimo inegociável — sem eles a nota é invisível ao `sm-find` e à compactação.

2. **DIGEST.md da área** tem duas seções fixas: **"Core (permanente)"** — fatos estáveis — e **"Contexto recente (expira ~14 dias)"** — fatos com decay. Cada fato é **uma linha atômica e datada**; fato novo **SUBSTITUI** a linha antiga (supersedes), nunca acumula versões da mesma verdade.

3. **Wikilinks `[[arquivo]]`** pra navegação — nunca links relativos crus no corpo.

4. **Tags canônicas** (não inventar): `#project`, `#architecture`, `#story`, `#decision`, `#research`, `#qa`, `#database`, `#ux`, `#security`, `#performance`, `#task-log`.

5. **Atualizar `INDEX.md`** sempre que criar arquivo novo (fora do `_inbox/`, que é efêmero).

6. **Datas ISO 8601** (`YYYY-MM-DD`) — nunca relativas.

---

## Templates de frontmatter por tipo de arquivo

### Story
```yaml
---
title: "Story {N}.{M}: {Título}"
kind: story
status: backlog | active | done
summary: "{o que a story entrega, em 1 linha}"
epic: {N}
complexity: S | M | L | XL
agent: {quem-assumiu}
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [story, {domínio}]
related: [[../../decisions/ADR-{N}]]
---
```

### ADR
```yaml
---
title: "ADR-{N}: {Título}"
kind: decision
status: proposed | accepted | deprecated
summary: "{decisão tomada + razão, em 1 linha}"
agent: {architect-name}
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [architecture, {domínio}]
related: [[../agents/research/{tema}]]
---
```

### Research report
```yaml
---
title: "Research: {tema}"
kind: research
status: active | resolved
summary: "{conclusão principal da pesquisa, em 1 linha}"
agent: {researcher-name}
created: YYYY-MM-DD
updated: YYYY-MM-DD
expires: YYYY-MM-DD   # se a pesquisa tem prazo de validade (ex.: benchmark, versão de lib)
tags: [research, {domínio}]
related: [[../../decisions/ADR-{N}]]
---
```

### Schema
```yaml
---
title: Schema Atual
kind: schema
status: active
summary: "{escopo do schema + última mudança relevante}"
agent: {data-name}
updated: YYYY-MM-DD
tags: [database, schema]
related: [[migrations-log]]
---
```

### QA Results (episódio de veredicto)
```yaml
---
title: "QA: {story/módulo}"
kind: qa-result
status: active | resolved
summary: "{veredicto + achado principal, em 1 linha}"
agent: {qa-name}
updated: YYYY-MM-DD
tags: [qa]
---
```

### Component specs
```yaml
---
title: Component Specs
kind: component-spec
status: active
summary: "{componentes cobertos, em 1 linha}"
agent: {ux-name}
updated: YYYY-MM-DD
tags: [ux, components]
---
```

### Nota de inbox (efêmera — consolidada no *compact)
```yaml
---
title: "Inbox: {agente} — {data}"
kind: episode
status: active
summary: "{fatos/decisões anotados nesta sessão, em 1 linha}"
agent: {nome}
created: YYYY-MM-DD
tags: [task-log]
---
```

---

## Anti-patterns a evitar nos templates gerados

1. **NÃO deixar o prompt do agente sem seção "O que escreve na smart-memory"** — obriga o agente a entender seu dever de persistência.

2. **NÃO deixar o prompt sem o protocolo de leitura L0/L1/L2** — agente sem o protocolo lê pastas inteiras e queima o context window.

3. **NÃO deixar o prompt sem mention de atualizar `INDEX.md`** — novos arquivos ficam órfãos.

4. **NÃO deixar o agente escrever em paths fora de `docs/smart-memory/`** pra conhecimento canônico — todo conhecimento vive sob `docs/smart-memory/` (saídas por agente em `agents/<área>/`, ex.: `agents/devops/releases-log.md` — nunca pastas top-level novas como `ops/`). Só escreva em outros lugares se for parte do código do projeto (implementers escrevem código fora de smart-memory; isso é ok).

5. **NÃO misturar responsabilidades** — ex: analyst NÃO escreve `modules.md` (é do architect); architect NÃO escreve `tech-stack.md` (é do analyst). Conflitos de escrita quebram a discovery paralela.

6. **NÃO criar `-v2`/`-r3` nem duplicar fatos** — atualizar in-place ou usar `supersedes`; no DIGEST, a linha nova substitui a antiga.

7. **NÃO omitir `expires:` em notas sabidamente temporárias** — sem TTL, o lixo temporário vira peso permanente até alguém notar.

---

## Como a skill valida

A skill team-os-creator não audita a smart-memory dos projetos — o status/verificação da smart-memory é do `/team-os *memory`. Mas o `validate-agent.sh` verifica que:

1. O prompt menciona `docs/smart-memory/` em alguma parte do corpo
2. O prompt menciona `SendMessage` (pra coordenação peer-to-peer)
3. O prompt menciona "Native Teams Protocol" (e NÃO contém o padrão antigo "Contrato com team-os")

Se algum faltar, o validate falha e a skill tenta reinjetar o bloco faltante a partir dos templates.
