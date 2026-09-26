---
name: finance-reporting
description: "Método do relatório financeiro — relatório mensal para sócios (resumo, alertas, receita, custos, margem, caixa, runway, inadimplência, realizado vs plano), dicionário de indicadores com fórmula e `#id`, todo número com `#id` do fechamento FECHADO, sem 'aproximadamente'. Use ao escrever ou revisar o relatório mensal, definir indicador ou preparar relatório para investidor ou banco."
version: "1.0"
updated: "2026-09-25"
---

# Finance Reporting — cada número com `#id`, cada alerta no tamanho real

Relatório financeiro é o único ponto em que sócio, investidor ou banco encontra os números da empresa. Se ele arredonda, suaviza ou calcula por conta própria, a decisão de quem lê nasce errada. Este método existe para que todo número venha do fechamento FECHADO por `#id`, toda leitura cite a decisão de quem decidiu, todo alerta apareça com data e tamanho — e para que o que foi enviado nunca seja editado, só corrigido em versão nova.

## 1. Princípios

1. **Todo número com `#id` do fechamento FECHADO.** Fechamento ABERTO → não há relatório, há rascunho interno marcado `RASCUNHO — fechamento ABERTO`, que não sai.
2. **SENA não calcula número novo.** Indicador que não existe no fechamento → pede a GANGES, que devolve com `#id`. Uma divisão feita no relatório é número sem dono.
3. **Sem "aproximadamente".** Nem "cerca de", "em torno de", "quase". O valor é o do `#id`, com as casas decimais do dicionário. Arredondamento só o definido no dicionário, declarado.
4. **Alerta não se suaviza.** Caixa abaixo da reserva, gap na S{n}, inadimplência acima do limite: segunda seção do relatório, com data, tamanho e opção em análise. Adjetivo não substitui número.
5. **Relatório enviado não se corrige.** Erro descoberto → `v{N+1}` com seção `Correções em relação à v{N}` no topo e novo ciclo; a v{N} fica arquivada, imutável.
6. **Política se cita, não se interpreta.** Meta, limite, regra: `finance-policy.md §{x}` ou `decisão de AMAZONAS em decisions.md ({data})`.
7. **Envio é ato do usuário.** Só com PASS de TIGRE + confirmação explícita para esta versão e estes destinatários. Dado sensível (contas, chaves, CPF/CNPJ de terceiros) nunca aparece — alias.

## 2. Estrutura do relatório mensal (sócios)

| # | Seção | Conteúdo | Origem |
|---|---|---|---|
| 0 | Cabeçalho | mês, versão, `#F{AAAA-MM}` FECHADO em {data}, PASS de TIGRE em {data}, destinatários | fechamento, QA |
| 1 | Resumo | 5 linhas: resultado, caixa, reserva/runway, maior alerta, decisão pedida — cada uma com `#id` | tudo abaixo |
| 2 | Alertas | alerta · valor `#id` · limite (política §) · data · opção em análise · quem decide | cash-plan, aging, calendário fiscal |
| 3 | Receita | bruta, deduções, líquida; recorrente/pontual; concentração por cliente (alias) | DRE `#id` |
| 4 | Custos e despesas | direto, fixo, variável; 3 maiores variações vs mês anterior com causa | DRE `#id` |
| 5 | Margem e resultado | margem de contribuição, resultado operacional, resultado do mês — valor e % | DRE `#id` |
| 6 | Caixa e runway | saldo conciliado por conta (alias), reserva em meses vs mínimo, burn, runway, gap previsto (S{n}, tamanho) | fechamento + cash-plan `#id` |
| 7 | Inadimplência | aging por faixa, % vs limite, concentração, negociações em curso | aging `#id` |
| 8 | Realizado vs plano | receita, despesas, caixa: planejado · realizado · desvio · causa | orçamento/cash-plan de DANUBIO |
| 9 | Obrigações | tributos do mês: preparado/validado/recolhido; atrasos com custo | calendário de RENO |
| 10 | Decisões pedidas | uma por linha: decisão · opções com custo · prazo · quem decide (usuário) | AMAZONAS |
| 11 | Anexos | fechamento, plano de caixa, aging, indicadores — por caminho | — |

Comparação mês a mês só entre dois fechamentos FECHADOS. Mês anterior ABERTO → coluna vazia com a nota `mês anterior ABERTO`.

## 3. Dicionário de indicadores (`indicadores.md`)

```
| Indicador | Definição operacional | Fórmula | Componentes (#id) | Casas decimais / arredondamento | Cadência | Meta (política §) | Dono do cálculo | Limitação |
```

Indicadores mínimos (GANGES calcula e entrega com `#id`; SENA copia):

```
margem_contribuicao_pct = (receita_liquida − custo_direto) ÷ receita_liquida
margem_operacional_pct  = resultado_operacional ÷ receita_liquida
receita_recorrente_pct  = receita_recorrente ÷ receita_bruta
concentracao_cliente    = maior receita por cliente ÷ receita_bruta
custo_fixo_mensal       = média(despesa fixa, 3 fechamentos FECHADOS)
reserva_meses           = saldo_conciliado ÷ custo_fixo_mensal
burn_liquido            = média 3 meses (saídas − entradas)           ; ≤ 0 ⇒ "não aplicável (caixa positivo)"
runway_meses            = saldo_conciliado ÷ burn_liquido
inadimplencia_pct       = vencido > 30 dias ÷ receita faturada 12 meses
desvio_plano_pct        = (realizado − planejado) ÷ planejado
```

Indicador novo ou fórmula alterada → nova linha com data e versão; a série anterior fica `descontinuada em {data}`, nunca sobrescrita. Indicador sem meta na política aparece com `meta: não definida (AMAZONAS)`.

## 4. Régua de linguagem

| Proibido | Em vez disso |
|---|---|
| "aproximadamente R$ X", "cerca de", "em torno de", "quase" | o valor do `#id` |
| "a margem melhorou" | "margem de contribuição {valor} (`#id`), +{pp} vs {mês} (`#id`)" |
| "caixa confortável", "situação delicada" | reserva em meses vs mínimo da política; gap com data |
| "esperamos receber" | "a vencer: R$ ____ (`#id`); vencido > 30d: R$ ____ (`#id`)" |
| "achamos que", "provavelmente" | fato com `#id`, ou premissa de DANUBIO com data e origem |
| "sugerimos cortar X" | "decisão pedida: {opções com custo} — AMAZONAS, {data}" |
| número no texto sem `#id` | número + `(#id)` |

Verificação antes do PASS: `grep -inE "aprox|cerca de|em torno|quase|provavelmente|confort|delicad"` no relatório — qualquer ocorrência bloqueia.

## 5. Variações

| Destinatário | Acrescenta | Remove | Não muda |
|---|---|---|---|
| Sócios (padrão) | — | — | — |
| Investidor | receita recorrente %, crescimento vs mesmo mês do ano anterior, runway conservador, uso do aporte vs plano | decisões operacionais internas (§10) | `#id` em tudo; alertas intactos |
| Banco/credor | cobertura da dívida = `resultado_operacional ÷ serviço da dívida`, garantias por alias, cronograma de parcelas; formato pedido pelo banco | §10 | idem; gap nunca omitido |

Variação é documento próprio (`{AAAA-MM}-relatorio-{destinatario}.md`), com PASS e confirmação próprios.

## 6. Ciclo

```
fechamento FECHADO (GANGES) → rascunho v1 (SENA) → auto-check (grep §4 + todo número com #id) → PASS (TIGRE)
→ confirmação do usuário para v{N} e destinatários (data, texto) → envio pelo usuário → registro (data, versão, destinatários)
→ v{N} arquivada, imutável. Correção ⇒ v{N+1} com seção de correções no topo e ciclo completo de novo.
```

## 7. Templates

- `templates/relatorio-mensal.md` — as 11 seções de §2 com tabelas e `#id` em cada célula de valor
- `templates/indicadores.md` — dicionário (§3) com histórico de versões por indicador

## 8. Contrato com o resto da squad

SENA escreve `agents/reporting/{AAAA-MM}-relatorio.md` e `indicadores.md`. GANGES é a origem de todo número (`#id`) e calcula o indicador que faltar; DANUBIO fornece plano, premissas e gap para §6 e §8; TEJO fornece aging e negociações para §7; RENO fornece status das obrigações para §9; AMAZONAS fornece metas (política §) e as decisões pedidas de §10 — SENA não redige recomendação própria; NILO fornece índices citados (câmbio, inflação) com fonte e data; TIGRE aplica os pontos 2 (número ↔ `#id`, valor idêntico), 11 (indicadores conforme dicionário) e 12 (confirmação registrada antes do envio) e emite FAIL para qualquer número sem `#id` ou termo da régua de §4.
