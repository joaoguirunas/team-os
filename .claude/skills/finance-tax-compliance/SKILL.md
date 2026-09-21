---
name: finance-tax-compliance
description: Método genérico de obrigações fiscais — calendário de obrigações (o quê, quando, órgão, base, responsável, status), apuração preparatória por tributo cruzando base `#id` do fechamento com regra citada por fonte (lei, artigo, órgão, data de consulta), conferência documental de notas, remuneração de sócios com regra e custo, pacote mensal para o contador e o checklist fiscal; a squad prepara e organiza, o contador valida e o usuário recolhe. Use ao montar o calendário fiscal, preparar a apuração de um tributo, conferir notas, comparar pró-labore e distribuição ou organizar o que vai ao contador.
version: "1.0"
updated: "2026-09-20"
---

# Finance Tax & Compliance — sem fonte não há alíquota, sem contador não há guia

Imposto errado custa duas vezes: a multa e a confiança. Este método existe para que toda obrigação apareça no calendário com data e órgão, toda alíquota e prazo saia com fonte datada, todo valor preparado cruze a base `#id` do fechamento com a regra citada — e para que **o contador da empresa valide antes de qualquer guia** e o usuário recolha. A squad não declara, não transmite e não recolhe.

## 1. Princípios

1. **Sem fonte não há alíquota.** Alíquota, base, prazo e regra saem com `fonte: {lei/artigo/ato normativo} · {órgão} · consultado em {data}`. Sem fonte → `[CONFIRMAR COM CONTADOR]` e o valor é `rascunho`, não `preparado`.
2. **O contador valida antes de qualquer guia ou declaração.** Status `validado pelo contador` exige alias do contador, data e meio. Sem ele, nada segue para recolhimento.
3. **A squad não recolhe nem transmite.** Guia, declaração, envio a órgão e pagamento de tributo são atos do usuário ou do contador.
4. **Regime vem de `project/finance-context.md`, nunca presumido.** Regime tributário, atividade, município, enquadramento: preenchidos com o usuário e confirmados pelo contador.
5. **Base vem do fechamento FECHADO.** Toda apuração cita o `#id` da receita, folha ou nota que forma a base.
6. **Prazo é regra com fonte, não memória.** "Sempre foi dia 20" não é fonte. Prazo sai com a norma e com a regra do órgão para dia não útil.
7. **País é referência, não método.** `reference/brasil.md` descreve o que existe e onde confirmar; o método vale para qualquer jurisdição declarada em `finance-context.md`.
8. **Dado sensível por alias.** CNPJ/CPF completos, senhas de portal, certificado digital: nunca em template nem smart-memory.

## 2. Calendário de obrigações

```
| # | Obrigação | Tipo (tributo/declaração/informe/renovação) | Órgão | Periodicidade | Regra de prazo + fonte | Base (#id ou documento) | Prepara / Valida / Executa | Próxima data | Status |
```
Status: `a preparar · preparado · validado pelo contador · executado (data, referência ao comprovante) · atrasado (motivo, custo)`. Toda obrigação nomeia os três responsáveis: RENO prepara, contador valida, usuário ou contador executa. Obrigação nova entra só com fonte; obrigação extinta vira `histórico` com a norma que a extinguiu.

Alertas: D-10 (base disponível?) · D-5 (validado pelo contador?) · D-1 (executado?). Alerta vencido → linha nos alertas do relatório de SENA.

## 3. Apuração preparatória por tributo

```
base_calculo     = Σ #id do fechamento que compõem a base (listar cada #id)
regra            = {alíquota ou faixa, com fonte} × base − {deduções/retenções previstas, com fonte}
valor_preparado  = resultado da regra                    ; status: rascunho | preparado | validado pelo contador | recolhido
variação vs mês anterior > 20% ⇒ explicar pela base (#id) ou pela regra (mudança com fonte)
```

| Campo | Regra |
|---|---|
| Base | `#id` de fechamento FECHADO; ABERTO → apuração `rascunho` |
| Alíquota/faixa | valor **e** fonte datada; faixa progressiva → cálculo da faixa mostrado |
| Retenções na fonte | por nota, com o campo da nota que comprova; sem comprovante → não abate |
| Compensações/créditos | só com decisão do contador registrada (data) |
| Arredondamento | regra do órgão, com fonte; nunca por conta própria |
| Status | `preparado` → RENO · `validado pelo contador` → contador (alias, data, meio) · `recolhido` → usuário (data, referência ao comprovante) |

Apuração cuja regra depende de enquadramento não confirmado em `finance-context.md` fica inteira em `[CONFIRMAR COM CONTADOR]`.

## 4. Conferência documental

Para cada nota emitida/recebida no mês (lista de GANGES/NILO):

| Checagem | Critério | Falha → |
|---|---|---|
| Natureza/código da operação | coerente com o objeto do contrato e com o cadastro da empresa | `⚠ natureza` — contador decide |
| Tomador/prestador | alias bate com contrato e fechamento | `⚠ parte` |
| Valor | = `#id` do fechamento | `⚠ valor` — não segue |
| Retenções destacadas | previstas na regra com fonte; campo preenchido | `⚠ retenção` |
| Emissão vs competência | mesmo mês do fato gerador | `⚠ competência` |
| Cancelada/substituída | par registrado (original ↔ substituta) | `⚠ sem par` |

Nota com `⚠` entra no pacote do contador com a pergunta pronta; não alimenta apuração até resolver.

## 5. Remuneração de sócios

```
| Via | Requisito (regra + fonte) | Encargos/tributos incidentes (regra + fonte) | Custo total para a empresa | Líquido para o sócio | Restrição |
| Pró-labore            | | | R$ ____ | R$ ____ | |
| Distribuição de lucro | | | R$ ____ | R$ ____ | lucro apurado em fechamento FECHADO (#id), contrato social |
```
A escolha é do usuário com o contador; AMAZONAS registra em `decisions.md`. "Distribuição não tem imposto" não é regra — é `[CONFIRMAR COM CONTADOR]` até ter fonte.

## 6. Pacote para o contador (`para-o-contador-{AAAA-MM}.md`)

Ordem fixa: (1) fechamento FECHADO referenciado (`#id` de receita e resultado); (2) notas emitidas e recebidas com status da conferência; (3) folha e pró-labore por referência, sem dados pessoais; (4) apurações preparadas por tributo com fonte; (5) perguntas `[CONFIRMAR COM CONTADOR]` numeradas; (6) documentos por nome de arquivo na pasta do projeto; (7) prazo pedido para retorno ≥ 3 dias úteis antes do vencimento mais próximo. Envio do pacote é do usuário. Retorno registrado item a item: `confirmado · corrigido (valor novo, motivo) · pendente`.

## 7. Checklist mensal fiscal

| # | Item | Critério |
|---|---|---|
| 1 | Regime e enquadramento lidos em `finance-context.md` | confirmação do contador ≤ 12 meses |
| 2 | Calendário atualizado para o mês | toda obrigação com próxima data e status |
| 3 | Bases com `#id` de fechamento FECHADO | nenhuma apuração sobre ABERTO |
| 4 | Toda alíquota/prazo com fonte datada | `[CONFIRMAR COM CONTADOR]` só nas perguntas listadas |
| 5 | Notas conferidas | zero `⚠` sem pergunta no pacote |
| 6 | Pacote enviado ao contador pelo usuário | data, meio |
| 7 | Retorno do contador registrado | item a item |
| 8 | `validado pelo contador` antes de qualquer guia | por tributo |
| 9 | Recolhimento registrado pelo usuário | data + referência ao comprovante |
| 10 | PASS de TIGRE (ponto 7 do checklist do QA) | referência em `agents/qa/` |

## 8. Templates e referência

- `templates/calendario-fiscal.md` — calendário (§2) com alertas e histórico
- `templates/apuracao-mensal.md` — apuração por tributo (§3), conferência (§4), retorno do contador
- `reference/brasil.md` — regimes, tributos, documentos fiscais e remuneração de sócios no Brasil em alto nível: o que existe, onde confirmar, o que perguntar ao contador. Sem alíquota numérica.

## 9. Contrato com o resto da squad

RENO escreve `agents/tax/calendario-fiscal.md`, `{AAAA-MM}-apuracao.md`, `regras.md` e `para-o-contador-{AAAA-MM}.md`. GANGES fornece o fechamento FECHADO (`#id`) e a lista de notas; NILO entrega documentos fiscais e pesquisa a fonte primária da norma com data; TEJO recebe vencimentos e valores preparados para a agenda de pagamentos (recolhimento pelo usuário via lote confirmado); DANUBIO recebe datas e valores para o plano de caixa; AMAZONAS decide pró-labore vs distribuição com o usuário a partir de §5; SENA copia carga tributária e alertas pelo `#id`; TIGRE verifica regra com fonte, base `#id` e `validado pelo contador` antes de qualquer PASS que libere recolhimento.
