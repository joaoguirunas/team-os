---
name: social-apify-research
description: Research de tendências e concorrentes via Apify — Instagram, TikTok, hashtags e análise de engagement. Usa wrapper Bash (o MCP não expõe actors de Instagram de forma confiável). Injectado em LYRIS (social-content) e social-analyst.
---

# Social Apify Research — Research via Apify

## ⚠️ Como rodar de verdade — leia antes

**Não confie no MCP `apify` para Instagram.** Mesmo configurado com
`--actors apify/instagram-scraper,apify/instagram-hashtag-scraper --tools actors`, o
processo MCP do Claude Code frequentemente não respawna com os args novos e o registro
continua só com `rag-web-browser`. Nem `/mcp` reconnect nem restart de janela resolvem
(exigiria Cmd+Q total do app). **Além disso, `social-analyst` tem `Bash` mas NÃO tem
tools MCP do Apify** — para ele o wrapper não é alternativa, é o único caminho.

**Use o wrapper.** Chama a API da Apify direto, é determinístico e não depende de MCP:

```bash
# posts por hashtag (limite default 5)
.claude/skills/social-apify-research/scripts/apify-ig-scrape.sh hashtag previdenciaprivada 5

# posts de um perfil
.claude/skills/social-apify-research/scripts/apify-ig-scrape.sh profile portoseguro 5
```

Saída: JSON com `perfil · legenda · likes · coments · url`; contagem de itens no stderr.

### Token

Resolve nesta ordem: **1.** `$APIFY_TOKEN` no ambiente → **2.** `~/.claude.json` em
`projects[<raiz do projeto>].mcpServers.apify.env.APIFY_TOKEN`.

> ⚠️ A chave do `~/.claude.json` é o **caminho absoluto** do projeto. Se a pasta for
> movida, a chave continua apontando pro caminho antigo e o token some — o wrapper
> avisa isso na mensagem de erro. Migre a chave ou exporte `APIFY_TOKEN`.
> Nunca versione o token.

### 💰 Custo — actors de Instagram são PAGOS

Cobram **por item retornado**. Não é WebSearch: cada chamada gasta crédito real.

- **Sempre passe limite explícito e baixo.** Default 5; acima de 50 o wrapper avisa.
- **Research exploratório:** 3–5 itens bastam para ler um padrão. Só suba o limite com
  uma pergunta específica que justifique.
- **Antes de um lote:** estime `nº de alvos × limite` = itens cobrados. 10 hashtags × 20 = 200.
- **Cheque o saldo** em apify.com/account — conta FREE tem crédito mensal fechado;
  estourou, para.
- Se o objetivo é só validar uma tendência, **WebSearch primeiro** e Apify só para
  confirmar com dado real. Marque no relatório o que é `[VALIDADO-IG]` vs `[ESTIMATIVA]`.

---

## Casos de uso principais

### 1. Trend research por nicho
Identificar o que está a viralizar num nicho específico para informar criação de conteúdo.

**Output esperado:**
```markdown
## Trends — [Nicho] — [Data]

**Formatos em alta:**
- Reels curtos (15-30s) com [padrão]
- Carousels sobre [tema]

**Sounds/músicas trending:**
- [Nome do som] — [nº de vídeos]

**Temas virais:**
- [Tema 1]: [por que está a crescer]
- [Tema 2]: ...

**Padrões de copy:**
- Hooks frequentes: "...", "..."
- CTAs mais usados: "..."
```

### 2. Análise de concorrentes
Perceber o que funciona para concorrentes directos.

**Métricas a recolher:**
- Posts com maior engagement (últimos 30 dias)
- Formatos mais usados
- Frequência de publicação
- Hashtags mais usadas
- Horários de publicação

Modo `profile`, um perfil por chamada:
```bash
for p in portoseguro bradescoseguros tokiomarine; do
  .claude/skills/social-apify-research/scripts/apify-ig-scrape.sh profile "$p" 5
done
```

### 3. Hashtag research
Identificar hashtags com bom volume e competição adequada.

**Output:**
```markdown
## Hashtags — [Nicho]

**Volume alto, competição alta (awareness):**
#hashtag — Xk posts

**Volume médio, nicho (reach):**
#hashtag — Xk posts

**Volume baixo, muito específico (conversão):**
#hashtag — Xk posts

**Recomendação mix:** 3 alta + 7 média + 5 baixa
```

## Protocolo de research

1. Definir nicho e mercado (PT, BR, ES, EN)
2. Identificar 5-10 concorrentes directos
3. **Estimar custo** (alvos × limite) antes de disparar
4. Correr o wrapper nos alvos relevantes
5. Consolidar dados em relatório estruturado, marcando `[VALIDADO-IG]` vs `[ESTIMATIVA]`
6. Extrair 3-5 insights accionáveis para LYRIS implementar em copy

## Frequência recomendada
- Trend research: semanal
- Análise de concorrentes: quinzenal
- Hashtag research: mensal ou por campanha

## Notas de manutenção
- O wrapper vive **nesta skill** (`scripts/apify-ig-scrape.sh`) e é propagado pelo CT
  junto com ela. Corrija-o **no CT** — edição no projeto destino é sobrescrita no
  próximo `*propagate`.
- Actors usados: `apify/instagram-hashtag-scraper` (hashtag) e `apify/instagram-scraper`
  (perfil), via endpoint `run-sync-get-dataset-items`.
- O wrapper local do De Castro (`scripts/apify-ig-scrape.sh` na raiz daquele projeto)
  é o original desta skill, feito na story 2.1. Ficou redundante quando o wrapper subiu
  para cá — pode ser removido de lá.
