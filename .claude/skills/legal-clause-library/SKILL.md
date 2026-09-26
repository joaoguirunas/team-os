---
name: legal-clause-library
description: "Método da biblioteca de modelos e cláusulas — organização por relação (cliente, fornecedor, parceiro, sócio, PJ, NDA, SaaS, termos de uso), numeração `M{N}.{c}`, anatomia de cada cláusula (padrão, variantes com piso e teto, proibidas, base legal), aprovação por PRUDENTIA e índice vivo. Use ao criar, aprovar, versionar ou consultar modelo ou cláusula antes de redigir uma minuta."
version: "1.0"
updated: "2026-09-25"
---

# Legal Clause Library — modelo antes de variante, variante antes de improviso

Toda minuta que começa do zero repete um erro que já foi negociado. A biblioteca é a memória negociada da empresa: para cada relação, um modelo; para cada cláusula, uma versão padrão, as variantes que a postura permite (com piso e teto) e o que nunca se assina. CONCORDIA redige a partir dela, PRUDENTIA aprova o que entra, LEX indexa, IUSTITIA cruza. Nada aqui é parecer; o advogado inscrito da empresa valida cada modelo antes do primeiro uso.

## 1. Princípios

1. **Um modelo por relação real.** Não existe modelo para relação que a empresa não tem na mesa; não existe modelo único para cliente e fornecedor.
2. **Cada cláusula tem três camadas:** versão padrão, variantes negociáveis com piso/teto, lista de proibidas. Cláusula com uma camada só está incompleta.
3. **Nada entra sem aprovação de PRUDENTIA.** Status `rascunho` até a strategist aprovar; só `aprovada` pode ser origem em minuta.
4. **Base legal onde a cláusula exige** — citação completa de VERITAS (`/legal-research` §3), datada e vigente.
5. **Versão é imutável.** Mudança = nova versão; minutas antigas continuam apontando para a versão que usaram.
6. **Genérica e pública.** Texto de cláusula não carrega nome, CNPJ, endereço ou valor de terceiro — só placeholders nomeados (`{PARTE A}`, `{VALOR}`, `{PRAZO}`).

## 2. Biblioteca por relação

| Relação | Modelo | Documentos do sistema | Cláusulas críticas (postura §) |
|---|---|---|---|
| Cliente — prestação / serviço recorrente | `M1` | contrato-mãe, anexo de escopo, ordem de serviço, aditivo, distrato | preço e reajuste, SLA, PI do entregável, limitação, rescisão |
| Fornecedor | `M2` | contrato, ordem de compra, anexo de SLA | responsabilidade, dados pessoais (operador), subcontratação, rescisão |
| Parceiro / permuta / revenda | `M3` | acordo de parceria, anexo comercial | exclusividade, comissão, uso de marca, não concorrência |
| Sócio / investidor | `M4` | acordo de sócios, termo de investimento | governança, vesting, saída, não concorrência, confidencialidade |
| Colaborador / PJ | `M5` | contrato de prestação PJ, termo de PI e confidencialidade | PI, confidencialidade, autonomia, término |
| NDA | `M6` | NDA unilateral, NDA mútuo | escopo, exceções, prazo pós-término, penalidade |
| Licença / SaaS | `M7` | contrato de licença ou assinatura, SLA, anexo de dados | licença, disponibilidade, dados pessoais, limitação, suspensão |
| Termos de uso e privacidade | `M8` | termos de uso, política de privacidade (requisitos de FIDES; texto de CONCORDIA) | dados, conteúdo do usuário, limitação, alteração dos termos |

Relação nova → LEX cria `M{N}` na arquitetura antes de qualquer minuta; relação sem `M{N}` = minuta `[SEM MODELO]` com aprovação prévia de PRUDENTIA.

## 3. Numeração e versionamento

```
M{N}                modelo da relação                      ex.: M1
M{N}.{c}            cláusula c do modelo N                 ex.: M1.6  (preço e pagamento)
M{N}.{c}.p          versão padrão                          ex.: M1.6.p
M{N}.{c}.v{k}       variante negociável k                  ex.: M1.6.v2 (pagamento em 45 dias)
M{N}.{c}.x          lista de proibidas da cláusula         ex.: M1.6.x
M{N}.def / .obj / .ger   blocos fixos: definições, objeto, disposições gerais
M{N} v{V}           versão do modelo inteiro               ex.: M1 v3 — incrementa quando qualquer cláusula muda de versão
```

Numeração de cláusula segue a anatomia de `/legal-contract-drafting` §3 (1 qualificação … 15 anexos). A matriz de desvios cita sempre `M{N}.{c}.{p|vk}` e `M{N} v{V}`. Versão deprecada permanece legível com `status: deprecated` e a versão que a substituiu.

## 4. Anatomia de uma cláusula

| Campo | Obrigatório | Regra |
|---|---|---|
| `id` + título | sim | `M{N}.{c}` |
| Padrão (`.p`) | sim | texto completo com placeholders nomeados; linguagem clara (`/legal-contract-drafting` §4) |
| Variantes (`.v{k}`) | sim — ≥ 1, ou "nenhuma: inegociável" | cada uma: texto, **piso**, **teto**, quando usar, quem aprova (CONCORDIA dentro do piso/teto · PRUDENTIA fora · usuário se toca inegociável) |
| Proibidas (`.x`) | sim | o que nunca se assina nesta cláusula, uma por linha, com motivo da postura § |
| Postura § | sim | qual seção da postura a cláusula implementa |
| Base legal | quando a cláusula exige | citação completa + data de consulta + vigência |
| Inegociável? | sim | `sim / não` — se sim, variantes vazias e `.x` ampla |
| Registrável | sim | o que FIDES cadastra ao assinar (prazo, obrigação, renovação) |
| Histórico | sim | versões, data, quem aprovou, minutas que usaram |

Piso e teto são **valores ou faixas verificáveis** (dias, %, múltiplos de mensalidade, anos) — nunca "razoável".

## 5. Processo de aprovação

```
1. Proposta      CONCORDIA escreve/atualiza a cláusula em agents/drafting/clausulas.md → status: rascunho
2. Base legal    VERITAS anexa citação §3 quando a cláusula exige → sem ela, [BASE LEGAL PENDENTE]
3. Postura       PRUDENTIA confere: implementa a postura §? piso/teto dentro do apetite? proibidas completas?
                 → APROVADA | AJUSTES | REPROVADA, registrado em agents/strategy/validations.md
4. Índice        LEX registra em agents/architecture/model-system.md: M{N}.{c} v{k}, status, data, relação
5. Advogado      primeiro uso de cada M{N}: validação do advogado inscrito registrada (data, alias) — não é parecer da squad
6. Uso           só status aprovada é origem válida em matriz de desvios
```

Gatilhos de revisão: FAIL de IUSTITIA que aponte a cláusula; mesma variante pedida por ≥ 3 contrapartes (candidata a novo padrão — decisão de PRUDENTIA); norma alterada (VERITAS avisa); mudança de postura.

## 6. Índice vivo — `agents/architecture/model-system.md`

```
M{N} | relação | v{V} | status (rascunho | aprovada | deprecated) | aprovado por / data | validado por advogado (data) | cláusulas {c} … | minutas que usam ({slug} v{N})
```

Uma linha por modelo, uma sub-tabela por cláusula (`templates/biblioteca-modelos.md`). Revisão trimestral com VERITAS (vigência das bases legais) e PRUDENTIA (postura).

## 7. Regras de uso na minuta

| Situação | Origem na matriz de desvios | Quem aprova |
|---|---|---|
| Cláusula igual ao padrão | `M{N}.{c}.p` — `= modelo` | ninguém |
| Variante dentro do piso/teto | `M{N}.{c}.v{k}` — `variante` | CONCORDIA registra; PRUDENTIA vê no gate |
| Fora do piso/teto, sem ferir inegociável | `M{N}.{c}.p` + `DESVIO` | PRUDENTIA |
| Toca inegociável | `DESVIO` | usuário, por escrito |
| Cláusula sem `M{N}.{c}` | `postura §` ou `fonte` + `DESVIO: sem modelo` | PRUDENTIA; candidata a entrar na biblioteca |

## 8. Checklist de entrada na biblioteca

| # | Verificação |
|---|---|
| 1 | `id` único, título, relação e postura § preenchidos |
| 2 | Padrão em linguagem clara; zero adjetivo sem critério |
| 3 | ≥ 1 variante com piso e teto verificáveis, ou marcada inegociável |
| 4 | Lista de proibidas com motivo |
| 5 | Base legal com citação completa e vigente, quando exigida |
| 6 | Campo "registrável por FIDES" preenchido |
| 7 | Placeholders nomeados; zero dado real de terceiro |
| 8 | Aprovação de PRUDENTIA registrada em `validations.md` |

## 9. Templates

- `templates/biblioteca-modelos.md` — índice `model-system.md` por relação e cláusula
- `templates/clausula.md` — ficha de uma cláusula: padrão, variantes com piso/teto, proibidas, base legal, histórico

## 10. Contrato com o resto da squad

- **Produz:** LEX (legal-architect) — sistema `M{N}`, índice, versionamento; CONCORDIA (legal-drafter) — texto das cláusulas e variantes em `agents/drafting/clausulas.md`.
- **Consome:** CONCORDIA redige toda minuta a partir daqui; PRUDENTIA aprova cada entrada e usa pisos/tetos no gate; VERITAS anexa base legal e avisa quando norma muda; FIDES lê o campo "registrável" para cadastrar prazos; AEQUITAS e CLEMENTIA partem do `M{N}` para aditivo, distrato e acordo.
- **Cruza:** IUSTITIA confere que toda origem citada na matriz existe no índice com `status: aprovada` e na versão indicada — origem inexistente ou `rascunho` = FAIL.
