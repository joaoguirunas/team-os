---
name: finance-receivables-payables
description: "Método de contas a receber e a pagar — cobrança com `#id`, régua D-5/D0/D+3/D+10/D+30, aging e inadimplência por cliente, negociação registrada, agenda de pagamentos por prioridade, lote de pagamento com documento, alçada, PASS e confirmação; a squad prepara, o humano executa. Use ao preparar cobrança, agenda ou lote de pagamento, medir inadimplência ou registrar negociação."
version: "1.0"
updated: "2026-09-25"
---

# Finance Receivables & Payables — a squad prepara, o humano executa

Dinheiro sai e entra por atos que não se desfazem: um PIX, um boleto pago, uma nota emitida, uma cobrança enviada. Este método existe para que tudo o que antecede esse ato — valor, documento, destinatário, prioridade, texto — chegue pronto e conferido, e para que o ato em si seja sempre do usuário, com PASS de TIGRE e confirmação explícita **para este lote ou esta cobrança**.

## 1. Princípios

1. **A squad prepara o lote/cobrança; o humano executa.** Pagamento, transferência, PIX, boleto, emissão de NF e envio de cobrança ao cliente são executados pelo usuário (ou pelo sistema que ele opera), só com PASS de TIGRE + confirmação explícita do usuário para este lote/esta cobrança. Agendar no banco é executar.
2. **Todo valor vem de `#id`.** Cobrança cita o `#id` da receita/contrato no fechamento; pagamento cita o `#id` do documento lançado. Sem `#id`, não há item.
3. **Nunca alterar valor aprovado.** Desconto, parcelamento, juros perdoados são decisão de AMAZONAS/usuário, registrada antes de entrar na cobrança.
4. **Alçada define quem aprova o item; não dispensa PASS nem confirmação para executar.**
5. **Confirmação não se herda.** "O usuário confirmou o lote de ontem" não vale para o de hoje. Um lote, uma confirmação, com data e texto.
6. **Beneficiário e pagador por alias.** Conta bancária, chave PIX e CPF/CNPJ completo nunca vão a template nem smart-memory; ficam no sistema do usuário.
7. **Toda interação registrada.** Cobrança enviada, resposta, promessa de pagamento, negociação — linha no ledger com data e autor.

## 2. Contas a receber

### 2.1 Ledger (`receivables.md`)
```
| Cliente (alias) | #id | Documento (contrato/NF) | Emissão | Vencimento | Valor | Status | Régua (último passo, data) | Próximo passo | Data |
```
Status: `a emitir · emitido · a vencer · vencido · negociado · recebido (#lanc) · perdido (decisão)`. `recebido` só com par na conciliação de GANGES.

### 2.2 Emissão preparada
Pacote por cobrança: cliente (alias), `#id`, descrição conforme contrato, valor, vencimento (regra do contrato), forma de pagamento (do contrato — sem dados bancários no pacote), texto da mensagem (template). Emissão de NF e envio → usuário, após PASS + confirmação.

### 2.3 Régua de cobrança

| Passo | Quando | Canal | Tom | Conteúdo mínimo | Gate |
|---|---|---|---|---|---|
| D-5 | 5 dias antes | e-mail | lembrete | `#id`, valor, vencimento, forma | PASS do template (uma vez) + confirmação por envio |
| D0 | vencimento | e-mail | neutro | idem + "vence hoje" | idem |
| D+3 | 3 dias após | e-mail + mensagem | direto | valor em aberto, pedido de previsão | idem |
| D+10 | 10 dias após | telefone/mensagem + e-mail | firme | valor, encargos conforme contrato (cláusula citada), prazo para regularizar | PASS + confirmação; encargo só se contratual |
| D+30 | 30 dias após | e-mail formal | formal | histórico das tentativas, próximos passos previstos em contrato | PASS + confirmação + decisão de AMAZONAS sobre o próximo passo |

Mensagens em `cobranca-templates.md` com placeholders `{cliente}`, `{valor}`, `{vencimento}`, `{#id}`; sem ameaça fora do contrato; sem desconto não aprovado. Cliente que responde com promessa → status `negociado`, data prometida registrada, régua pausada até essa data + 1 dia.

### 2.4 Aging e inadimplência
```
faixas               = a vencer | 1–30 | 31–60 | 61–90 | > 90 dias
inadimplencia_pct    = Σ vencido > 30 dias ÷ Σ receita faturada nos últimos 12 meses     ; vs limite da política
concentracao_pct     = maior saldo em aberto por cliente ÷ Σ em aberto
taxa_recebimento_prazo = Σ recebido até D0 (6 meses) ÷ Σ faturado no período             ; DANUBIO usa no conservador
```
Inadimplência acima do limite da política → alerta para AMAZONAS e linha no relatório de SENA. `perdido` só com decisão escrita em `decisions.md`.

### 2.5 Negociação registrada
`data · cliente (alias) · #id · proposta do cliente · contraproposta · quem aprovou (AMAZONAS/usuário, data) · resultado · novo vencimento`. Desconto ou parcelamento sem aprovação registrada não entra no ledger.

## 3. Contas a pagar

### 3.1 Agenda (`payables.md`)
```
| Fornecedor (alias) | #id (documento) | Tipo (fixo/variável/tributo/dívida) | Vencimento | Valor | Prioridade | Alçada | Status | Lote |
```
Status: `agendado · em lote · PASS · confirmado pelo usuário · pago (#lanc) · adiado (decisão) · cancelado (motivo)`. `pago` só com par na conciliação.

### 3.2 Prioridade em aperto
Ordem da política de AMAZONAS (`finance-policy.md`). Sem política escrita, a agenda usa a ordem default e marca `[POLÍTICA PENDENTE]`: 1 folha e encargos · 2 tributos com multa e juros · 3 dívidas com garantia · 4 fornecedores críticos para a receita · 5 aluguel/infra · 6 demais. Adiar qualquer item = decisão do usuário por escrito com custo (multa, juros, relacionamento).

### 3.3 Lote de pagamento preparado
Um lote = itens com vencimento na mesma janela; cada item com fornecedor (alias), `#id` do documento, valor, vencimento, prioridade, alçada de quem aprova. Total do lote comparado com a folga da semana no plano de caixa (DANUBIO).

```
para cada item: documento existe? valor = documento? vencimento ≤ janela? já pago (#lanc) ou em lote anterior?
duplicidade      : mesmo fornecedor + mesmo valor + vencimento ±7 dias de item pago/em lote ⇒ ⚠ até o documento provar que são dois
total_lote       = Σ valor                                   ; deve bater com a soma do template
ciclo de status  : preparado → PASS (TIGRE) → confirmado pelo usuário (data, texto) → executado pelo usuário → conciliado (#lanc)
```

### 3.4 Alçadas
| Faixa | Aprova o item | Executa |
|---|---|---|
| até `R$ ____` (política) | responsável definido na política | usuário |
| acima de `R$ ____` | usuário | usuário |
Alçadas vêm de `finance-policy.md`; sem política, tudo é alçada do usuário.

## 4. Notas fiscais
TEJO prepara os dados (tomador por alias, descrição, valor, `#id`, natureza conforme RENO); emissão é do usuário/sistema. NF recebida sem lançamento → NILO/GANGES; NF a emitir sem contrato → não se prepara.

## 5. Templates

- `templates/lote-pagamento.md` — lote preparado (§3.3): itens, documento, total, alçada, PASS, confirmação, execução, conciliação
- `templates/regua-cobranca.md` — régua (§2.3) com mensagens por passo e registro de envios
- `templates/aging.md` — aging por cliente (§2.4), inadimplência, concentração, negociações

## 6. Contrato com o resto da squad

TEJO mantém `receivables.md`, `payables.md`, `lotes/{AAAA-MM-DD}-lote-pagamento.md` e `cobranca-templates.md` em `agents/billing/`. GANGES fornece os `#id` e fecha o ciclo com `#lanc` na conciliação; TEJO nunca lança. AMAZONAS define prioridade, alçadas, limite de inadimplência e aprova desconto/parcelamento; RENO fornece vencimentos e valores preparados de tributos para a agenda; DANUBIO consome agenda e ledger para o plano de caixa e devolve a folga da semana; SENA copia inadimplência e concentração pelo `#id`; TIGRE aplica os pontos 5 e 6 do checklist (documento em 100% dos itens, total bate, alias, duplicidade; cobrança com valor = `#id`, cliente certo, régua respeitada, sem desconto não aprovado) e o ponto 12 (confirmação do usuário registrada). Sem PASS + confirmação, o lote fica `preparado` e a cobrança fica `a emitir`.
