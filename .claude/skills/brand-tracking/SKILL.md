---
name: brand-tracking
description: Método de medição de marca — scorecard com funil (awareness, consideração, preferência, recomendação), atributos de percepção da plataforma, share of voice, sentimento, consistência de aplicação e métricas de negócio que a marca deve mover; definição operacional, fonte, cadência e limitações de cada métrica; instrumentos (survey de atributos, roteiro de menções); linha de base travada antes da virada e leitura do depois com o mesmo método; ficha de números com id. Use ao definir o que medir num reposicionamento, fixar o antes, ler o depois ou validar qualquer número de marca.
version: "1.0"
updated: "2026-09-16"
---

# Brand Tracking — o antes, o depois, e nenhum número sem dono

Reposicionamento sem linha de base é fé. Comparação com método diferente é ilusão. Número sem ficha é boato com casas decimais. Este método existe para que, seis meses depois, alguém consiga dizer **o que mudou, com que confiança e o que não dá para atribuir** — e para que nenhum número apareça em manifesto, brandbook ou deck sem ter passado pela ficha.

## 1. Princípios

1. **Baseline antes de qualquer aplicação nova sair.** Se não der tempo, o usuário decide por escrito sabendo que o lançamento sai sem prova de resultado.
2. **Mesmo método no antes e no depois** — métrica, fonte, janela, população. Mudou o método, nova série começa do zero e o relatório diz isso.
3. **Toda métrica tem definição operacional** (como exatamente se calcula), fonte, cadência, dono e limitações. Proxy é declarado como proxy.
4. **Todo número tem `#id`** na ficha, com status ABERTO/FECHADO. Só FECHADO sai em deliverable.
5. **n baixo é declarado.** Abaixo de ~100 respostas, "não generalizável" vai junto do número.

## 2. O scorecard

### 2.1 Funil de marca (público prioritário da plataforma)
| Métrica | Definição operacional | Fonte típica | Limitação típica |
|---|---|---|---|
| Awareness espontânea | % que cita a marca ao pensar na categoria (pergunta aberta) | survey própria | amostra, viés de quem responde |
| Awareness estimulada | % que reconhece a marca numa lista | survey própria | lista enviesa |
| Consideração | % que consideraria a marca na próxima decisão | survey | intenção ≠ ação |
| Preferência | % que escolheria a marca entre as alternativas mapeadas | survey | idem |
| Recomendação | NPS ou % que recomendou nos últimos N meses | survey / CRM | NPS varia com o momento |

### 2.2 Atributos de percepção
Um por traço/promessa da plataforma (§3): "% que associa {atributo} à marca" — e aos 2–3 concorrentes do território, para ler distância. Atributo da plataforma que **não é mensurável** com as fontes disponíveis: avisar a strategist por escrito e propor proxy declarado.

### 2.3 Presença e conversa
| Métrica | Definição | Fonte | Limitação |
|---|---|---|---|
| Share of voice | menções da marca ÷ menções da marca + concorrentes mapeados, janela de 30d, canais listados | social, imprensa, busca | bots, homônimos |
| Sentimento | % positivo/neutro/negativo das menções, codificação declarada (manual ou ferramenta) | idem | codificação subjetiva |
| Busca pela marca | volume de busca do nome (branded search), tendência | ferramenta de busca | homônimos, sazonalidade |
| Audiência própria | seguidores/assinantes **por canal** — proxy de alcance, não de awareness | plataformas | nome errado vira promessa errada |

### 2.4 Consistência
Taxa de conformidade da aplicação com o kit de handoff, por canal, a partir das auditorias do QA: `peças conformes ÷ peças amostradas`. É a única métrica que a squad controla diretamente.

### 2.5 Negócio
Com o usuário: o que a marca deve mover (leads qualificados, ticket médio, ciclo de venda, churn, preço aceito). Marca influencia, não determina — declarar a atribuição como parcial.

## 3. Instrumentos

- **Survey de atributos** (8–12 perguntas, ≤4 min): categoria aberta → estimulada → atributos (marca e concorrentes, escala) → consideração/preferência → demografia mínima. Mesma redação no antes e no depois. Aplicação com clientes reais é **decisão do usuário**.
- **Roteiro de menções**: canais, termos (marca, variações, concorrentes), janela, regra de exclusão (bots, homônimos), codificação de sentimento com exemplos.
- **Auditoria de consistência**: amostra datada por canal, tabela peça × regra do kit.

## 4. Linha de base

Coletar tudo o que o scorecard define **antes** da fase externa do rollout. Travar `baseline.md` com data, método, n e limitações. Instrumento que não pôde ser aplicado → métrica marcada `[SEM BASELINE]` — e isso aparece no relatório do depois como "não comparável".

## 5. Leitura do depois

Janela mínima depois da virada: 60–90 dias para percepção; 30 dias para presença. Relatório: por métrica, antes → depois → diferença → n → intervalo de confiança (ou aviso de ausência) → **leitura** (o que mudou, o que não dá para atribuir ao reposicionamento, o que precisa de mais tempo). `/data-analytics-engineering` para a modelagem; `/social-analytics` para as fontes sociais.

## 6. Ficha de números

```
#B{NN} | métrica | valor | fonte | data | método (n, janela, codificação) | status ABERTO|FECHADO
```
Toda referência em deliverable usa o `#id`. Mudou o valor → nova linha com nova data; a antiga não se apaga.

## 7. Template

`templates/brand-scorecard.md` — scorecard (§2) com definição, fonte, cadência, dono, limitações e status de baseline por métrica.
