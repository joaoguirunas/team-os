---
kind: reference
status: living
summary: "Sistema de modelos: {N} modelos ({a} aprovados, {b} rascunho, {c} deprecated), {T} cláusulas, última revisão {data}"
title: "Model System — biblioteca de modelos e cláusulas"
agent: legal-architect
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [legal, architecture, models, library]
related: ["[[../../project/contract-architecture]]", "[[../../project/legal-posture]]", "[[../drafting/clausulas]]", "[[../strategy/validations]]"]
---

# Model System — biblioteca de modelos e cláusulas

> Só `status: aprovada` é origem válida em matriz de desvios. Versão é imutável: mudança = nova versão. Placeholders nomeados; zero dado real de terceiro. Advogado inscrito valida cada modelo antes do primeiro uso — não é parecer da squad.

## 1. Índice de modelos
| Modelo | Relação | Versão | Status | Aprovado por / data | Validado por advogado (data) | Documentos do sistema | Minutas que usam |
|---|---|---|---|---|---|---|---|
| M1 | cliente | v1 | rascunho | | | contrato-mãe, anexo de escopo, OS, aditivo, distrato | |
| M2 | fornecedor | | | | | | |
| M3 | parceiro | | | | | | |
| M4 | sócio / investidor | | | | | | |
| M5 | colaborador / PJ | | | | | | |
| M6 | NDA | | | | | | |
| M7 | licença / SaaS | | | | | | |
| M8 | termos de uso e privacidade | | | | | | |

## 2. Cláusulas por modelo
### M{N} — {relação} — v{V}
| Cláusula | Título | Padrão | Variantes (piso → teto) | Proibidas | Inegociável? | Postura § | Base legal | Registrável (FIDES) | Status | Ficha |
|---|---|---|---|---|---|---|---|---|---|---|
| M{N}.1 | Qualificação | .p | — | — | não | — | — | — | | [[clausulas#M{N}.1]] |
| M{N}.6 | Preço e pagamento | .p | .v1 {x} dias → .v2 {y} dias | .x | não | §{…} | — | vencimento, reajuste | | |
| M{N}.9 | Propriedade intelectual | .p | nenhuma | .x | sim | §{…} | {citação} | — | | |

## 3. Histórico de versões
| Modelo | Versão | Data | O que mudou | Gatilho (FAIL / ≥3 pedidos / norma / postura) | Aprovado por |
|---|---|---|---|---|---|

## 4. Pendências
- `[BASE LEGAL PENDENTE]`: {M{N}.{c} …}
- `[SEM MODELO]`: relações na mesa sem `M{N}`: {…}

## 5. Próxima revisão trimestral
{data} — VERITAS (vigência das bases) · PRUDENTIA (postura) · LEX (índice)
