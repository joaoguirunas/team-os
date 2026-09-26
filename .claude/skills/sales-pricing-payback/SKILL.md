---
name: sales-pricing-payback
description: "Economia de propostas comerciais — preço vs. equivalente de tabela, desconto efetivo e seu custo, breakeven da implantação, payback do cliente (receita recuperada, horas economizadas), comparativo de alternativas, permuta, escada de participação e valuation com sensibilidade. Use para calcular, validar ou defender qualquer número de proposta, deck, follow-up ou planilha de negociação."
version: "1.0"
updated: "2026-09-25"
---

# Sales Pricing & Payback — todo número com dono

**Quando usar esta vs. `pricing`:** esta calcula os números de *uma proposta* (desconto, breakeven, payback do cliente, permuta). Para definir a *estratégia* de preço e empacotamento do produto (tiers, freemium, métrica de valor, página de preços), use `pricing`.

Sem a conta, preço é preço. Com a conta, é investimento. Esta skill dá as fórmulas padrão para que **cada número de uma proposta saia com fórmula, fonte/hipótese e status** — e para que quem decide preço decida sabendo o que custa.

Princípios:
1. **Fórmula antes do resultado.** Um número sem fórmula escrita é opinião.
2. **Dado do cliente é placeholder até chegar** — `R$ ____` com a hipótese ao lado. Nunca inventar.
3. **Arredondar só para baixo, com nota.** 37,04% é 37%; nunca 40%.
4. **Toda projeção tem cenário conservador e o ponto fraco calculado** antes que o comprador aponte.
5. **Decisão é de quem decide; a conta é sua.** Você entrega o custo de cada caminho.

## 1. Preço vs. equivalente de tabela

Mostra ao cliente o tamanho do que recebe — e ao time o tamanho do que está dando.

```
Equivalente mensal de tabela = Σ (preço de tabela de cada entrega recorrente)
Entregas únicas (páginas, implantação, BI) listadas à parte, com valor de tabela
Desconto efetivo = 1 − (investimento cobrado ÷ equivalente mensal)
```

Apresentação recomendada: equivalente em destaque, acumulado do ciclo em letra menor (no PDF, "é o tamanho do presente, não do boleto"). Desconto em % **e** em R$/mês.

## 2. Custo do desconto e breakeven

O time precisa saber quanto investe no início da conta e quando recupera.

```
Custo do desconto/mês   = equivalente − cobrado
Investimento inicial    = custo de implantação (horas × custo/hora) + entregas únicas incluídas sem cobrança
Margem mensal           = cobrado − custo de operação mensal
Breakeven (meses)       = investimento inicial ÷ margem mensal
Exposição em saída antecipada = investimento inicial − (margem mensal × meses cumpridos)
```

Se breakeven > prazo mínimo garantido (aviso prévio), há **risco comercial**: o desconto precisa de contrapartida — permanência mínima, ressarcimento proporcional da implantação, ou desconto escalonado. Isso vai para a estrategista como decisão, com os três cenários calculados.

## 3. Payback do cliente

Duas contas clássicas — preencher com dados reais ou deixar placeholders explícitos.

**Conta A — receita recuperada/gerada**
```
Ganho mensal = volume de oportunidades/mês × Δ taxa de conversão × ticket médio × margem do cliente
```
Ex.: carrinhos abandonados × (taxa alvo − taxa atual) × ticket × margem.

**Conta B — horas economizadas**
```
Economia mensal = tickets ou tarefas/mês × % automatizada × tempo médio (h) × custo/hora
+ ganho indireto: mesmo time absorve mais volume sem contratar
```

**Régua de argumentação:** o investimento se paga com **quanto** de melhora? (ex.: "um ponto percentual de recuperação"). Se a régua exigir melhora implausível, a proposta está cara ou a dor está mal escolhida — voltar à tese.

Sem dado do cliente: entregar a **estrutura da conta** com `R$ ____` e as perguntas exatas na seção de pendências. Nunca preencher com "estimativa de mercado" sem fonte.

## 4. Comparativo de alternativas

| Alternativa | Custo mensal (faixa, com fonte) | O que entrega | O que não entrega |
|---|---|---|---|
| Contratar internamente | salário + encargos (fonte: pesquisa salarial, ano) | uma pessoa | arquitetura, operação, BI |
| Stack de ferramentas separadas | soma dos planos (fonte: tabela pública) | ferramentas | integração |
| Fornecedor por projeto | faixa (fonte) | entrega e sai | evolução, operação |
| **Sua oferta** | cobrado | … | … |

Faixas com fonte. Concorrente **nomeado** só no interno — no PDF, categorias.

## 5. Permuta

```
Valor de referência do nosso lado   = Σ (tabela de cada entrega) — mensal e único
Valor de referência do lado deles   = Σ (tabela de cada veiculação/contrapartida)
Equilíbrio                          = razão entre os dois, por mês e acumulado
```
Regras: **medição do retorno** antes da primeira contrapartida (link rastreável exclusivo, cupom próprio, página de destino específica); cláusula de **reequilíbrio** em marco intermediário; valores de referência validados internamente antes do PDF.

## 6. Captação — escada de participação e valuation

**Escada de participação:** participação de entrada + degraus por patamar de métrica (MRR, receita) com janela de aferição. Calcular o **valuation implícito** em cada degrau:
```
Valuation post-money implícito = aporte ÷ participação
```
Mostrar que a entrada precifica o futuro e os degraus só se realizam se o futuro acontecer — "a conta fecha para os dois lados".

**Régua de valuation — usar a categoria certa:**

| O que se ouve | O que é | Serve? |
|---|---|---|
| "IA vale 10-24× receita" | múltiplo de **receita** em rodada de capital para **produto/SaaS** | só se você for SaaS em rodada |
| "Consultoria de tecnologia vale 6-8× EBITDA" | múltiplo de **EBITDA** em M&A para **serviço com recorrência** | típico para serviço |
| "Plataforma vale 7-10×+" | EBITDA acima de certo porte | só quando o porte chegar |

Sempre: **fonte** (relatório, autor, ano — via pesquisa), **faixa** (piso e topo), **sensibilidade** (o que acontece se a margem normalizar para a média do setor) e o **ponto fraco** já respondido. Nunca prometer exit; retorno vem de dividendos + valor da participação.

## 7. Planilha (quando houver projeção)

- Abas: `Premissas` (todas as entradas, uma por linha, com fonte) · `Cálculo` (só fórmulas) · `Saída` (tabelas que vão para o plano/PDF) · `Sensibilidade`
- **Nenhuma célula de resultado com valor digitado** — só fórmula
- Cenários base / conservador / (otimista opcional) lado a lado
- Nome do arquivo conforme a convenção do projeto; referenciado na ficha de números

## 8. A ficha de números — contrato com o resto da squad

Cada número que aparece em qualquer artefato tem uma linha na ficha com `#id`, valor, fórmula, fonte/hipótese e status. Redatora e designer **copiam** o `#id`; QA cruza PDF ↔ ficha. Ficha só fecha com zero pendências.

Referência rápida das fórmulas: `reference/formulas.md`.
