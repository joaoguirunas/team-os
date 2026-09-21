---
kind: reference
status: rascunho
summary: "Notificação extrajudicial v{N} — {contraparte alias}, contrato #K{NN}, pedido {…}, prazo {N} dias, estratégia {aprovada em … / pendente}, envio {pendente / confirmado}"
title: "Notificação extrajudicial — {contraparte alias} — v{N}"
agent: legal-disputes
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [legal, disputes, notificacao, v{N}]
related: ["[[cronologia]]", "[[dossie]]", "[[../casos]]", "[[../../../project/contracts-registry]]", "[[../../strategy/validations]]", "[[../../research/{tema}-research]]"]
---

# Notificação extrajudicial — {contraparte alias} — v{N}

> Preparada pela squad; **enviada pelo usuário** com PASS de IUSTITIA + confirmação explícita para este arquivo e este destinatário. Zero ameaça de medida judicial sem aprovação de PRUDENTIA **e** do advogado. Prazo prescricional só com fonte. Destinatário por alias aqui; dados completos no arquivo final. Isto não é parecer.

## Pré-condições
| Item | Status | Evidência |
|---|---|---|
| Estratégia aprovada por PRUDENTIA | | validations.md — {data} |
| Advogado (alias) ciente da consequência prevista | | {data} |
| Achados de VERITAS para fundamento e prazos | | {research-slug} |
| Valor por alias de `#id` financeiro | | |
| PASS IUSTITIA para v{N} | | results.md — {data} |
| Confirmação do usuário — arquivo (hash) + destinatário | | signature-ledger — {data} |
| Meio de envio com prova de recebimento | | {cartório / AR / ferramenta} |

## Texto
**Destinatário:** {alias — dados completos no arquivo final}
**Referência:** Contrato #K{NN} — {tipo}, assinado em {data} — cláusulas {…}

**1. Fatos**
| Data | Fato | Evidência |
|---|---|---|

**2. Fundamento**
Cláusula {N} do contrato; {norma — citação completa de VERITAS, conferir na fonte}.

**3. Pedido**
{O quê}, no valor de {alias #id} , no prazo de {N} dias {corridos / úteis} contados de {marco}.

**4. Consequência prevista** _(conforme estratégia aprovada)_
{texto aprovado — cada menção a medida judicial com aprovação de PRUDENTIA e advogado registrada}

**5. Canal de resposta**
{canal} · {prazo}

{Local}, {data}. — {signatário por cargo}

## Changelog
| Versão | Data | O que mudou | Origem |
|---|---|---|---|
| v1 | | primeira versão | estratégia aprovada em {data} |

## Envio
Enviado pelo usuário em {data/hora} · Meio: {…} · Comprovante (path, hash): {…} · Ledger de casos #P{NN} → fase `notificado`
