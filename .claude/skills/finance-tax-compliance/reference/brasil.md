# Referência — Brasil (alto nível, sem alíquotas)

Esta página descreve **o que existe** no sistema tributário brasileiro para uma empresa de serviços/tecnologia de pequeno e médio porte, **onde confirmar** e **o que perguntar ao contador**. Não é método (o método é o `SKILL.md`) e não é fonte: cada item traz o tipo de norma a confirmar **na data**, porque alíquotas, faixas, prazos e obrigações mudam. **Nenhum valor numérico aqui é para ser usado — o contador da empresa valida tudo antes de qualquer guia.** O regime da empresa vem de `project/finance-context.md`, nunca desta página.

## 1. Regimes tributários (visão geral)

| Regime | O que é, em uma frase | Base típica | Confirmar em | Perguntar ao contador |
|---|---|---|---|---|
| Simples Nacional | regime unificado para micro e pequenas empresas: vários tributos recolhidos numa guia mensal única (DAS), com faixas progressivas por receita acumulada em 12 meses e anexo por atividade | receita bruta mensal e acumulada 12 meses | Lei Complementar do Simples Nacional e resoluções do Comitê Gestor (CGSN) vigentes na data; portal do Simples Nacional | anexo aplicável à atividade; fator "r" (relação folha/receita) se aplicável; limite de receita; sublimites estaduais/municipais; efeito de retenções |
| Lucro Presumido | tributos federais sobre o lucro calculados a partir de um percentual presumido da receita, por atividade; tributos sobre receita e sobre serviços apurados à parte | receita bruta (presunção) · receita (PIS/COFINS) · serviços (ISS) | legislação do IRPJ/CSLL (presunção por atividade), legislação de PIS/COFINS cumulativos, lei municipal do ISS — vigentes na data | percentual de presunção da atividade; periodicidade (trimestral); regime de caixa vs competência para a presunção |
| Lucro Real | tributos federais sobre o lucro contábil ajustado; exige contabilidade completa e apuração de PIS/COFINS geralmente não cumulativa | lucro contábil ajustado · receita com créditos | legislação do IRPJ/CSLL e de PIS/COFINS não cumulativos, vigentes na data | obrigatoriedade (porte/atividade); periodicidade; créditos admitidos |
| Reforma tributária sobre consumo | transição em curso para novos tributos sobre consumo (IBS/CBS) em substituição gradual a tributos atuais, com calendário de anos | consumo/serviços | Emenda Constitucional e leis complementares da reforma, regulamentação e cronograma de transição publicados | em que ano da transição a empresa está; o que muda na nota e na apuração no exercício corrente |

Regra: a página **não** afirma qual regime é melhor. Comparação entre regimes = simulação com fonte, feita com o contador, decisão do usuário.

## 2. Tributos e contribuições que tipicamente aparecem

| Tributo | Nível | Incide sobre | Onde aparece no método | Confirmar em |
|---|---|---|---|---|
| ISS | municipal | prestação de serviços; pode haver retenção pelo tomador | apuração por receita de serviços (`#id`); conferência de retenção na NFS-e | lei do ISS do município do prestador (e do tomador quando há retenção); lista de serviços da lei complementar nacional |
| PIS e COFINS | federal | receita | apuração por receita; regime cumulativo/não cumulativo depende do regime | legislação federal de PIS/COFINS vigente |
| IRPJ e CSLL | federal | lucro (real ou presumido) | apuração trimestral/anual conforme regime | legislação federal de IRPJ/CSLL |
| Contribuições sobre folha (INSS patronal, terceiros, FGTS) | federal | remuneração de empregados e, no caso do INSS, também de pró-labore | folha (referência); custo da remuneração de sócios (§4) | legislação previdenciária e trabalhista; eSocial; regras específicas do Simples por anexo |
| IRRF e retenções na fonte (INSS, PIS/COFINS/CSLL, ISS) | federal/municipal | pagamentos a pessoas jurídicas e físicas em certas hipóteses | conferência documental (nota recebida/emitida com retenção destacada) | legislação de retenções; regras do Simples sobre dispensa de retenção |
| ICMS / IPI | estadual / federal | mercadorias e industrialização | normalmente não incide em serviço puro; confirmar se há venda de bens ou software com enquadramento próprio | legislação estadual e federal vigente |

## 3. Documentos fiscais e obrigações acessórias

| Item | O que é | Ponto de atenção no método | Confirmar em |
|---|---|---|---|
| NFS-e | nota fiscal de serviço, emitida no sistema do município (ou padrão nacional, onde adotado) | natureza/código do serviço, retenções destacadas, competência; emissão é do usuário/sistema | prefeitura do município; padrão nacional da NFS-e, se aplicável |
| NF-e | nota fiscal eletrônica para mercadorias | só se a empresa vende bens | legislação estadual; portal nacional da NF-e |
| DAS | guia única do Simples Nacional | valor preparado só com base `#id` e faixa com fonte; validado pelo contador antes de gerar | portal do Simples Nacional |
| DARF | guia de tributos federais fora do Simples | código de receita e período de apuração corretos | Receita Federal |
| Declarações periódicas (ex.: DCTF/DCTFWeb, EFD-Contribuições, ECD, ECF, DEFIS/PGDAS-D, eSocial, DIRF ou sucessora) | obrigações acessórias federais, variam por regime e por ano | entram no calendário como `declaração`, com órgão e prazo com fonte; transmissão é do contador | Receita Federal; cronograma anual de obrigações |
| Obrigações municipais/estaduais | declarações de serviços, cadastros, alvarás, taxas anuais | calendário, tipo `informe/renovação` | prefeitura e secretaria estadual |
| Certidões negativas | prova de regularidade fiscal (federal, estadual, municipal, trabalhista, FGTS) | pedidas em contratos e licitações; validade limitada → linha no calendário | órgão emissor de cada certidão |

## 4. Remuneração de sócios

| Via | O que é | Custo típico a confirmar | Restrição típica a confirmar | Perguntar ao contador |
|---|---|---|---|---|
| Pró-labore | remuneração pelo trabalho do sócio na empresa | contribuição previdenciária do sócio e da empresa; imposto de renda na fonte pela tabela progressiva | obrigatoriedade quando o sócio trabalha na empresa; base mínima | valor mínimo recomendado; efeito no fator "r" (Simples) |
| Distribuição de lucro | parcela do lucro apurado paga aos sócios | regra de isenção no imposto de renda do sócio **condicionada** a lucro efetivamente apurado e a regras contábeis/limites por regime | lucro apurado em fechamento FECHADO (`#id`); previsão no contrato social; regularidade fiscal da empresa | limite isento no regime da empresa; documentação exigida; periodicidade |

"Distribuição não tem imposto" **não** é regra: é condição com requisitos — `[CONFIRMAR COM CONTADOR]` com fonte antes de qualquer pagamento.

## 5. Índices e referências que NILO fornece com fonte e data

| Índice | Uso no método | Fonte primária típica |
|---|---|---|
| Selic / CDI | correção de tributos em atraso; cenário de reserva | Banco Central do Brasil |
| IPCA | reajuste contratual; forecast | IBGE |
| Câmbio (PTAX) | receita/custo em moeda estrangeira | Banco Central do Brasil |
| Salário mínimo e tabelas previdenciárias/IR | folha e pró-labore | Diário Oficial da União; Receita Federal; INSS |

## 6. O que esta página não faz

- Não crava alíquota, faixa, limite nem prazo — cada um é `{regra} — fonte: {norma, artigo} · consultado em {data}` no `regras.md` da empresa, e **o contador da empresa valida**.
- Não substitui contador nem advogado tributarista.
- Não decide regime: monta a pergunta; a simulação é com o contador; a decisão é do usuário.
