---
name: finance-cash-flow
description: "Método do plano de caixa de 13 semanas rolling — saldo inicial conciliado, entradas por origem, saídas fixas e variáveis, saldo contra o mínimo da política, gap com data e tamanho, cenários base/conservador/estresse, reserva, runway e burn, premissas datadas. Use ao montar, atualizar ou aprovar plano de caixa, forecast ou cenário, e ao calcular runway, burn ou reserva."
version: "1.0"
updated: "2026-09-25"
---

# Finance Cash Flow — o caixa das próximas 13 semanas, sem surpresa escondida

**Quando usar esta vs. `startup-financial-modeling`:** esta é o plano de caixa operacional de 13 semanas sobre números conciliados. Para projeções de 3–5 anos, cenários de captação e financials para investidor, use `startup-financial-modeling`.

Empresa não quebra por falta de lucro; quebra por falta de caixa numa quarta-feira específica. Este método existe para que a semana em que o dinheiro falta apareça no plano **com data e tamanho** semanas antes, para que toda entrada projetada tenha origem verificável e para que ninguém planeje sobre número que ainda não foi conciliado.

## 1. Princípios

1. **Plano só sobre fechamento FECHADO.** Saldo inicial é o `#id` do saldo conciliado do último fechamento de GANGES. Fechamento ABERTO → o plano espera.
2. **Receita só com origem.** Contrato assinado, ledger de cobrança com status, histórico de recorrência ≥ 3 meses. "Esperado" e "pipeline" não entram no cenário base.
3. **Premissa com data e origem.** Toda premissa tem `{valor} · {origem} · {registrada em} · {informada por} · {válida até}`. Sem data e origem, não entra.
4. **Gap com data e tamanho, nunca em "outros".** A semana em que o saldo cai abaixo do mínimo da política é uma linha própria: `GAP S{n} · R$ ____ · {causa}`.
5. **Cenário conservador é obrigatório.** Base sem conservador é aposta. Estresse é obrigatório quando há dívida ou cliente > 30% da receita.
6. **Reserva é em meses de custo fixo, não em valor absoluto.** A política de AMAZONAS define o mínimo; o plano mede contra ele toda semana.
7. **Decisão de dinheiro é do usuário.** Contrair dívida, atrasar pagamento, furar reserva — o plano mostra o custo de cada opção; quem decide assina em `agents/strategy/decisions.md`.
8. **Dado sensível fora do plano.** Contas por alias (`conta operacional`, `conta reserva`); cliente e fornecedor por alias.

## 2. Estrutura do plano de 13 semanas

Uma coluna por semana (S1 = semana corrente, data da segunda-feira), linhas em blocos:

| Bloco | Linhas | Origem exigida |
|---|---|---|
| Saldo inicial | saldo conciliado (S1) · saldo final da semana anterior (S2+) | `#id` do fechamento |
| Entradas | recebíveis por cliente (alias) com vencimento · recorrência contratada · pontuais assinadas · aporte/empréstimo (só com decisão escrita) | `receivables.md` de TEJO, contrato, `decisions.md` |
| Saídas fixas | folha e encargos · pró-labore · aluguel/infra · parcelas de dívida · tributos (data de RENO) · assinaturas | `payables.md` de TEJO, `calendario-fiscal.md` de RENO |
| Saídas variáveis | fornecedores por projeto · comissões · tributos sobre receita · variáveis por volume | `payables.md`, política |
| Saldo final | saldo inicial + entradas − saídas | fórmula |
| Mínimo da política | reserva mínima em R$ para a semana | `finance-policy.md` |
| Folga / GAP | saldo final − mínimo | fórmula |

```
saldo_final(S)      = saldo_inicial(S) + Σ entradas(S) − Σ saidas_fixas(S) − Σ saidas_variaveis(S)
saldo_inicial(S+1)  = saldo_final(S)
custo_fixo_mensal   = média(saídas fixas dos últimos 3 fechamentos FECHADOS)
minimo_politica     = reserva_meses (política) × custo_fixo_mensal
folga(S)            = saldo_final(S) − minimo_politica          ; < 0 ⇒ GAP com data e tamanho
```

Recebível vencido há mais de 30 dias sai do base: a linha fica `R$ 0` com nota `inadimplente — aging D+{n}`; entra só no cenário em que a negociação registrada previr recebimento.

## 3. Cenários

| Cenário | Entradas | Saídas | Decide |
|---|---|---|---|
| Base | contratado + recorrência com histórico ≥ 3 meses | tudo agendado + variáveis pela média de 3 meses | gestão semanal |
| Conservador (obrigatório) | contratado × taxa de recebimento no prazo dos últimos 6 meses; pontuais só se assinadas | fixas integrais + variáveis pelo pior mês dos últimos 6 | contratação, investimento, distribuição |
| Estresse | perda do maior cliente a partir de S{n} · atraso de 30 dias em 100% dos recebíveis | fixas integrais | dívida, dependência de cliente, prazo com fornecedor |

```
taxa_recebimento_prazo = Σ recebido até D0 (6 meses) ÷ Σ faturado no período       ; TEJO fornece
entradas_conservador   = entradas_contratadas × taxa_recebimento_prazo
```

Cada cenário lista **o que aciona** o gap e **o que cobre** (antecipação de recebível, corte, adiamento negociado, aporte). Cobertura sem custo escrito não é cobertura.

## 4. Reserva, burn e runway

```
reserva_atual_meses    = saldo_conciliado ÷ custo_fixo_mensal
burn_liquido_mensal    = média 3 meses (saídas totais − entradas totais)     ; > 0 ⇒ queimando caixa
runway_meses           = saldo_conciliado ÷ burn_liquido_mensal
runway_conservador     = saldo_conciliado ÷ burn no cenário conservador
```

Burn ≤ 0 → escrever `runway: não aplicável (caixa positivo)`, nunca "infinito". Reserva abaixo do mínimo da política dispara alerta para AMAZONAS e vira linha nos alertas do relatório de SENA.

## 5. Premissas

```
| # | Premissa | Valor | Origem | Registrada em | Informada por | Válida até | Cenário |
```

Premissa declarada pelo usuário sem documento: `declarado pelo usuário em {data}` + `[DOC PENDENTE]`. Premissa com `Válida até` vencida ou sem reconfirmação em 90 dias → `[REVALIDAR]` e sai do base até ser confirmada. Índice (câmbio, CDI, IPCA) só com fonte e data de NILO (`agents/research/benchmarks.md`).

## 6. Gap

| Campo | Regra |
|---|---|
| Semana | S{n} com a data da segunda-feira |
| Tamanho | `R$ ____` = mínimo da política − saldo final da semana |
| Causa | linha(s) que geram: vencimento concentrado, recebível atrasado, tributo, parcela |
| Opções | ≥ 2, cada uma com custo (juros, desconto de antecipação, multa, relacionamento) e prazo |
| Decisão | quem decidiu, quando, referência em `decisions.md` — ou `PENDENTE: usuário` |

Gap sem opção escrita não vai ao gate. "Atrasar tributo" ou "atrasar folha" exige decisão do usuário por escrito e aparece no relatório de SENA.

## 7. Atualização semanal (rolling)

Toda segunda-feira, nesta ordem: (1) substituir a projeção de S1 pelo realizado (extrato conciliado de GANGES); (2) registrar `desvio = realizado − projetado` por bloco, com causa; (3) descartar S1 e acrescentar a nova S13; (4) reconfirmar premissas com `Válida até` vencida; (5) recalcular gap e cenários; (6) atualizar o `summary` do frontmatter. Desvio acumulado > 10% nas entradas em 4 semanas obriga recalcular `taxa_recebimento_prazo`.

## 8. Gate do plano (AMAZONAS, 7 pontos)

1 rastreável ao fechamento FECHADO (`#id` do saldo inicial) · 2 política respeitada (reserva, alçadas) · 3 base + conservador com premissas escritas · 4 receitas com origem · 5 fixas completas com data (folha, tributos, aluguel, dívidas) · 6 gap coberto ou decisão do usuário · 7 critério de aceite verificável por TIGRE. `APROVADO | AJUSTES | REPROVADO`; APROVADO só 7/7.

## 9. Templates

- `templates/cash-plan-13w.md` — o plano rolling (§2, §5, §6, §7)
- `templates/forecast-cenarios.md` — base/conservador/estresse lado a lado, reserva, burn, runway (§3, §4)

## 10. Contrato com o resto da squad

DANUBIO escreve o plano e o forecast em `agents/planning/`; AMAZONAS aprova pelo gate e decide prioridade com o usuário; GANGES fornece saldo conciliado, custo fixo médio e o realizado semanal (`#id`); TEJO alimenta entradas e saídas agendadas (`receivables.md`, `payables.md`) e a taxa de recebimento no prazo; RENO fornece datas e valores preparados de tributos; NILO fornece índices com fonte e data; SENA copia runway, reserva e gap para o relatório citando `#id` e semana; TIGRE verifica os pontos 8 e 9 do checklist (premissas com data e origem, gap visível com data). Nenhum número do plano cria `#id` novo — todo realizado vem do fechamento.
