---
name: finance-bookkeeping
description: "Método da escrituração gerencial — plano de contas com regras de classificação, categorização só com documento, conciliação bancária item a item, tratamento de diferenças, estorno documentado, DRE, fechamento mensal com `#id` por número e checklist ABERTO/FECHADO. Use ao classificar lançamentos, conciliar uma conta, revisar o plano de contas, produzir a DRE ou fechar o mês."
version: "1.0"
updated: "2026-09-25"
---

# Finance Bookkeeping — nenhum número sem conciliação, nenhum ajuste sem motivo

O fechamento é a única fonte dos números da squad. Se ele estiver errado, plano, cobrança, apuração e relatório herdam o erro com cara de certo. Este método existe para que cada lançamento tenha documento, cada saldo bata com o extrato item a item, cada correção deixe rastro e cada número saia do mês com um `#id` que os demais copiam sem recalcular.

## 1. Princípios

1. **Nenhum número sem conciliação.** Saldo de conta que não bateu item a item com o extrato não entra no fechamento.
2. **Nunca apagar lançamento.** Erro se corrige com estorno (lançamento inverso) + lançamento correto, ambos com motivo e referência ao original.
3. **Nenhum lançamento sem documento.** Extrato, nota, fatura, contrato, recibo, folha. Sem documento → `[DOC PENDENTE]` em conta transitória; nunca classificado "por intuição".
4. **Fechamento com `#id`.** Cada número do mês recebe `#F{AAAA-MM}-{NN}`; quem cita, copia. Mudou o valor → nova linha; a antiga não se apaga.
5. **ABERTO ≠ FECHADO.** FECHADO = 100% das contas conciliadas + transitória zerada + PASS de TIGRE. Prazo não fecha mês; conciliação fecha.
6. **Plano de contas é do controller.** Conta nova só com regra de classificação escrita. Classificação declarada pelo usuário sem documento é hipótese, não fato.
7. **Dado sensível fora da smart-memory.** Número de conta, chave PIX, CPF/CNPJ completo de terceiro: referência por alias (`conta operacional`, `cliente {slug}`).

## 2. Plano de contas gerencial

| Grupo | Código | Contas típicas | Regra de classificação |
|---|---|---|---|
| 1 Receita | 1.x | recorrente · pontual · outras | pelo contrato/NF; recorrente = contrato com renovação; pontual = entrega única |
| 2 Deduções | 2.x | tributos sobre receita · devoluções · descontos concedidos | tributo pela apuração de RENO; desconto só com decisão registrada |
| 3 Custo direto | 3.x | fornecedores de entrega · ferramentas por projeto · comissões | só existe porque a receita existe |
| 4 Despesa fixa | 4.x | folha e encargos · pró-labore · aluguel/infra · assinaturas · contador | existe com receita zero |
| 5 Despesa variável | 5.x | marketing · viagens · tarifas bancárias · serviços eventuais | não é 3 nem 4 |
| 6 Resultado financeiro | 6.x | juros pagos · juros recebidos · multas · variação cambial | documento = extrato |
| 7 Não operacional | 7.x | aporte · empréstimo (principal) · distribuição · ativo | nem receita nem despesa; nunca entra na margem |
| 9 Transitória | 9.x | a classificar `[DOC PENDENTE]` · transferência entre contas próprias | zera antes do FECHADO |

Cada conta tem código, nome, grupo, regra (uma frase com condição), exemplo e contra-exemplo. Mudança no plano gera versão nova com data e vale a partir do mês seguinte — nunca reclassifica mês FECHADO.

## 3. Categorização com documento

Um lançamento = `#lanc · data · valor · conta (código) · contraparte (alias) · documento (tipo, nº ou nome de arquivo) · origem (extrato/NF/folha) · autor`. Fluxo: NILO entrega a coleta com documentos → GANGES classifica pela regra do plano → nenhuma regra se aplica → 9.x + pergunta em `agents/research/pendencias.md`. Documento que chega depois fecha a pendência com a data de chegada.

## 4. Conciliação bancária item a item

```
para cada linha do extrato:
    procurar lançamento com data ±2 dias úteis, mesmo valor, mesma contraparte
    encontrou      → ✅ par (id_extrato ↔ #lanc)
    não encontrou  → ⚠ criar #lanc em 9.x [DOC PENDENTE] com hipótese
para cada #lanc sem par no extrato:
    ⚠ classificar: pendente de compensação | duplicado | conta errada
saldo_contabil(conta) = saldo_anterior_conciliado + Σ #lanc do mês
diferença             = saldo_extrato − saldo_contabil          ; FECHADO exige diferença = 0 em toda conta
```

| Diferença | Tratamento | Nunca |
|---|---|---|
| Tarifa/juros não lançados | lançar em 6.x com o extrato como documento | "ajuste manual" |
| Recebimento sem NF/contrato | 9.x + `⚠ {valor} — hipótese: {cliente alias}` até o documento | classificar como receita pelo palpite |
| Lançamento em duplicidade | estorno do duplicado com motivo | apagar |
| Valor divergente (recebido líquido de taxa) | lançamento complementar da taxa em 6.x | arredondar |
| Centavos | mesma regra: lançamento com motivo | "é centavo, ignoro" |

Transferência entre contas próprias: dois lançamentos em 9.x que se anulam no mesmo dia; sobra em 9.x no fim do mês é diferença.

## 5. Estorno

```
#lanc original   : mantido; marcado `estornado por #lanc-E`
#lanc-E          : mesma conta, sinal invertido, motivo, referência ao original, data do estorno
#lanc-C          : o lançamento como deveria ter sido; referência a ambos
```
Motivos aceitos: conta errada, valor errado, duplicidade, contraparte errada, documento substituído. "Limpeza" não é motivo.

## 6. DRE gerencial

```
Receita bruta              = Σ 1.x
(−) Deduções               = Σ 2.x
= Receita líquida
(−) Custo direto           = Σ 3.x
= Margem de contribuição             ; % sobre receita líquida
(−) Despesa fixa           = Σ 4.x
(−) Despesa variável       = Σ 5.x
= Resultado operacional              ; % sobre receita líquida
(+/−) Resultado financeiro = Σ 6.x
= Resultado do mês
7.x aparece só no fluxo de caixa realizado; nunca na DRE.
```

Regime: competência na DRE (mês do fato gerador — NF, folha); caixa no fluxo realizado (mês do extrato). Cada linha da DRE e do fluxo recebe `#id`. Comparação com mês anterior só entre dois fechamentos FECHADOS.

## 7. Fechamento mensal

| # | Item | Critério |
|---|---|---|
| 1 | Coleta do mês recebida de NILO | `agents/research/{AAAA-MM}-coleta.md` com status por documento |
| 2 | 100% dos lançamentos com documento ou em 9.x | `[DOC PENDENTE]` só em 9.x |
| 3 | Conciliação item a item de cada conta (alias) | diferença = 0 por conta |
| 4 | 9.x zerada ou listada em `## Pendências` com hipótese | nenhum valor de 9.x em conta de resultado |
| 5 | Estornos do mês com motivo e referência | tabela em `## Diferenças de conciliação` |
| 6 | DRE com `#id` por linha | tabela `# · número · valor · origem · conciliação · status` |
| 7 | Fluxo realizado (caixa) por bloco com `#id` | bate com os extratos |
| 8 | Saldo final por conta (alias) com `#id` | = saldo do extrato |
| 9 | Documentos fiscais separados para RENO | lista referenciada em `agents/tax/para-o-contador-{AAAA-MM}.md` |
| 10 | PASS de TIGRE | referência em `agents/qa/` |

`FECHADO` só com 10/10. Itens 1–9 completos e 10 pendente → `ABERTO — aguardando QA`. Reabrir mês FECHADO é proibido: correção posterior é lançamento de ajuste no mês corrente com referência ao `#id` original.

## 8. Templates

- `templates/chart-of-accounts.md` — plano de contas gerencial (§2) com regra por conta e histórico de versões
- `templates/fechamento-mensal.md` — o fechamento (§6, §7): status, tabela `#id`, diferenças, pendências, planilhas

## 9. Contrato com o resto da squad

GANGES é o único autor do plano de contas (`project/chart-of-accounts.md`), da conciliação (`agents/controller/conciliacao-{AAAA-MM}.md`) e do fechamento (`agents/controller/{AAAA-MM}-fechamento.md`). NILO entrega documentos classificados em pré-triagem em `agents/research/{AAAA-MM}-coleta.md`; não lança. TEJO usa `#id` de receita e de documento para cobrança e agenda, e devolve `#lanc` de recebimento/pagamento pela conciliação; RENO usa a base `#id` para apuração e recebe o pacote de documentos fiscais; DANUBIO usa saldo conciliado e custo fixo médio; SENA copia cada número da DRE e do fluxo pelo `#id`; AMAZONAS lê o fechamento antes de qualquer gate; TIGRE confere por amostra ≥ 20% dos pares extrato ↔ lançamento e 100% dos itens acima da alçada antes do PASS que torna o mês FECHADO.
