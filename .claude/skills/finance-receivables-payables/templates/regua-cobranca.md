---
kind: reference
status: active
summary: "Régua de cobrança v{N} — 5 passos (D-5 · D0 · D+3 · D+10 · D+30) · templates com PASS em {data} · {n} cobranças ativas na régua"
title: "Régua de Cobrança — {empresa}"
agent: finance-billing
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [finance, billing, receivables, cobranca]
related: ["[[receivables]]", "[[cobranca-templates]]", "[[aging]]", "[[../../project/finance-policy]]", "[[../strategy/decisions]]"]
---

# Régua de Cobrança — {empresa} (v{N})

> A squad prepara a mensagem; o envio é do usuário, com PASS de TIGRE e confirmação para **esta** cobrança. Valor sempre = `#id`. Encargo só se previsto em contrato. Desconto só com decisão registrada.

## 1. Passos
| Passo | Quando | Canal | Tom | Conteúdo mínimo | Gate |
|---|---|---|---|---|---|
| D-5 | 5 dias antes do vencimento | e-mail | lembrete | `#id`, valor, vencimento, forma de pagamento (do contrato) | PASS do template + confirmação por envio |
| D0 | dia do vencimento | e-mail | neutro | idem + "vence hoje" | idem |
| D+3 | 3 dias após | e-mail + mensagem | direto | valor em aberto, pedido de previsão de pagamento | idem |
| D+10 | 10 dias após | telefone/mensagem + e-mail | firme | valor, encargos conforme contrato (cláusula __), prazo para regularizar | PASS + confirmação; encargo só se contratual |
| D+30 | 30 dias após | e-mail formal | formal | histórico das tentativas (datas), próximos passos previstos em contrato | PASS + confirmação + decisão de AMAZONAS |

## 2. Mensagens (placeholders — não preencher aqui)
### D-5
> Assunto: {empresa} — fatura {#id} vence em {vencimento}
> {cliente}, a fatura {#id} no valor de {valor} vence em {vencimento}. Forma de pagamento conforme contrato. Qualquer dúvida, respondemos por aqui.

### D0
> Assunto: {empresa} — fatura {#id} vence hoje
> {cliente}, a fatura {#id} ({valor}) vence hoje, {vencimento}. Se o pagamento já foi feito, desconsidere.

### D+3
> Assunto: {empresa} — fatura {#id} em aberto
> {cliente}, não identificamos o pagamento da fatura {#id} ({valor}, vencida em {vencimento}). Pode nos passar a previsão?

### D+10
> Assunto: {empresa} — fatura {#id} vencida há 10 dias
> {cliente}, a fatura {#id} ({valor}) segue em aberto desde {vencimento}. Conforme a cláusula {__} do contrato, incidem {encargos previstos}. Pedimos regularização até {prazo}.

### D+30
> Assunto: {empresa} — fatura {#id} — regularização
> {cliente}, registramos contatos em {datas}. A fatura {#id} ({valor}) está vencida desde {vencimento}. Os próximos passos previstos no contrato (cláusula {__}) são {…}. Seguimos à disposição para regularizar.

Proibido nas mensagens: ameaça não prevista em contrato; desconto ou parcelamento sem decisão registrada; dados bancários no corpo (forma de pagamento remete ao contrato/sistema).

## 3. Cobranças ativas na régua
| Cliente (alias) | `#id` | Valor | Vencimento | Passo atual | Enviado em (pelo usuário) | PASS | Confirmação (data) | Resposta do cliente | Próximo passo | Data |
|---|---|---|---|---|---|---|---|---|---|---|

## 4. Pausas (promessa de pagamento)
| Cliente (alias) | `#id` | Data prometida | Régua retoma em | Registrado em | Cumprido |
|---|---|---|---|---|---|

## 5. Histórico de versões da régua
| Versão | Data | Mudança | PASS (TIGRE) |
|---|---|---|---|
| v1 | {data} | criação | {data} |
