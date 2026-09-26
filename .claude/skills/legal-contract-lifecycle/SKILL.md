---
name: legal-contract-lifecycle
description: "Método do ciclo de vida de contratos e conflitos depois do PASS — registro único com `#id`, vigência, renovação e alertas, assinatura com versão travada, envio à contraparte só com PASS e confirmação, arquivamento, aditivo e distrato, notificação extrajudicial e dossiê para o advogado. Use ao registrar contrato, preparar assinatura ou envio, renovar, aditar, distratar ou notificar."
version: "1.0"
updated: "2026-09-25"
---

# Legal Contract Lifecycle — do PASS à assinatura, o humano executa

Contrato assinado que ninguém sabe onde está, quando renova ou o que obriga é passivo com assinatura. Minuta que sai antes do PASS é concessão sem dono. Esta skill cobre o que acontece **depois** que IUSTITIA aprovou: registrar, travar, enviar (o humano), assinar (o humano), arquivar, acompanhar prazos, renovar, aditar, distratar, notificar e — quando dá errado — montar o dossiê para o advogado inscrito, que é quem assina peça, protocola e representa. Isto não é parecer.

## 1. Princípios

1. **Envio, assinatura, protocolo e notificação são do humano/advogado.** A squad prepara. Cada saída exige PASS de IUSTITIA **e** confirmação explícita do usuário **para este arquivo e este destinatário** — confirmação de ontem não vale para a versão de hoje.
2. **Versão final travada com hash.** O que sai é o arquivo cujo hash está no ledger; hash diferente = outro documento = outro PASS.
3. **Nenhum prazo fora do registro.** Vigência, renovação, aviso prévio, obrigação recorrente e prazo de caso têm `#id`, fonte (cláusula ou norma) e dono.
4. **Documento enviado não se corrige — vira versão nova.** Erro após envio: `v{N+1}` com CONCORDIA, novo PASS, nova confirmação.
5. **Resolver antes de litigar**, conforme `legal-posture.md`. Ameaça de medida judicial só com estratégia aprovada por PRUDENTIA e advogado.
6. **Dado sensível fora da smart-memory.** Partes por alias; dados completos só no arquivo final, no repositório de arquivo da empresa.

## 2. Registro de contratos — `project/contracts-registry.md`

```
#K{NN} | tipo | relação (M{N}) | contraparte (alias) | objeto (1 linha) | assinado em | vigência início–fim | renovação (automática? data-limite de denúncia) | aviso prévio (dias, contados de) | obrigações recorrentes (o quê, quando, dono) | valor (alias do #id financeiro, se houver) | status (vigente | renovado | em aviso | encerrado | em disputa) | próximo prazo (data, o quê) | dono | arquivo (path, hash) | versão assinada
```

Contrato vigente sem `#K` não existe para a squad. Renovação automática **tem** prazo registrado (a data-limite de denúncia). Alertas em D-30, D-15 e D-7 do próximo prazo, no calendário de FIDES, ao dono e ao lead. Aditivo é linha própria vinculada ao contrato-mãe (`#K{NN}.a{k}`). Encerrado guarda data e motivo. `/data-analytics-engineering` se o registro virar planilha ou base.

## 3. Fluxo de assinatura

| Pré-condição | Evidência | Sem ela |
|---|---|---|
| PASS de IUSTITIA para **esta** versão | `agents/qa/results.md` — `{slug} v{N}` | não sai |
| Gate APROVADA de PRUDENTIA para esta versão | `agents/strategy/validations.md` | não sai |
| Confirmação explícita do usuário — arquivo + destinatário | ledger, com data e texto da confirmação | não sai |
| Arquivo final gerado e travado | `shasum -a 256 {arquivo}` no ledger | não sai |
| Poderes de quem assina conferidos | ato societário / procuração (alias, data) | `[PODERES A CONFIRMAR]` — não sai |
| Advogado da empresa validou o modelo `M{N}` (primeiro uso) | `model-system.md` | não sai |

```
1. Travar      → PDF final a partir da v{N} com PASS; nome pela convenção §4; hash no ledger; status: travado
2. Ordem       → signatários e sequência; testemunhas se a postura exigir; ferramenta declarada em legal-context.md
3. Confirmar   → usuário confirma por escrito: "enviar {arquivo} (hash …) para {destinatário alias}" → ledger
4. Enviar      → o usuário envia/dispara na ferramenta; AEQUITAS registra data/hora e evidência (id do envelope, comprovante)
5. Acompanhar  → status por signatário; lembrete D+3 / D+7; contraparte pede mudança → CONCORDIA (v{N+1}), nunca edição no arquivo
6. Concluir    → arquivo assinado + trilha de auditoria arquivados; hash do assinado; FIDES abre #K com base no assinado
```

## 4. Arquivamento

```
Convenção:  {AAAA-MM-DD}_{tipo}_{contraparte-alias}_{slug}_v{N}_{estado}.{ext}
            estado ∈ {minuta, enviado, assinado, aditivo-a{k}, distrato, notificacao}
Pastas:     {repositório da empresa}/{relação}/{contraparte-alias}/     ← arquivos completos (fora da smart-memory)
Índice:     agents/ops/arquivo.md → #K, path, hash, estado, data
```

Arquivo completo (com dados das partes) fica no repositório declarado em `legal-context.md`; a smart-memory guarda path, hash e alias. Versão assinada e trilha de auditoria nunca são substituídas.

## 5. Renovação, aditivo e distrato

| Evento | Gatilho | Fluxo | Registro |
|---|---|---|---|
| Renovação | alerta D-30 | FIDES avisa dono + lead → decisão do usuário (renovar / denunciar / renegociar) → se renegociar, LEX abre story e CONCORDIA redige aditivo | `#K` com nova vigência, ou status `em aviso` |
| Aditivo | mudança de escopo, valor, prazo ou parte | story `L{N}` → CONCORDIA (`M{N}` aditivo + matriz) → gates → §3 | `#K{NN}.a{k}`; obrigações novas com `#id` |
| Distrato | decisão do usuário ou fim com pendências | CONCORDIA/CLEMENTIA a partir do modelo; quitação, devolução de dados e materiais, confidencialidade sobrevivente, pendências financeiras por alias de `#id` | `#K` → `encerrado` com data, motivo, arquivo |
| Denúncia (não renovar) | decisão do usuário dentro do aviso prévio | notificação de não renovação (§6) | `#K` → `em aviso` → `encerrado` |

## 6. Notificação extrajudicial

Estrutura fixa (`templates/notificacao.md`): destinatário (alias) · referência ao contrato `#K` e cláusulas · **fatos** em ordem cronológica com data e evidência · **fundamento** (cláusula ou norma com citação de VERITAS) · **pedido** específico (o quê, valor por alias de `#id`, prazo em dias, contado de) · consequência prevista **conforme estratégia aprovada** · canal de resposta · data.

| Regra | Verificação |
|---|---|
| Estratégia aprovada por PRUDENTIA antes de redigir | `validations.md` |
| Zero ameaça de medida judicial sem aprovação de PRUDENTIA **e** advogado | grep de "medidas judiciais", "ação", "processo", "cabíveis" → cada ocorrência com aprovação registrada |
| Prazo prescricional ou decadencial citado só com fonte | `/legal-research` §3 |
| Meio de envio com prova de recebimento (cartório, AR, ferramenta com trilha) | postura + ledger |
| Envio pelo usuário, PASS + confirmação para este arquivo e este destinatário | ledger |

Cobrança extrajudicial coordenada com o financeiro do projeto via smart-memory (valor sempre por `#id` financeiro) — CLEMENTIA prepara, não cobra. `/negotiation` para a postura de conversa antes da notificação.

## 7. Dossiê para o advogado externo

`templates/dossie-advogado.md`: resumo em 5 linhas · partes por alias (dados completos no arquivo) · **cronologia** (data, fato, evidência, quem) · documentos (contrato `#K`, aditivos, mensagens, comprovantes — path e hash) · cláusulas relevantes (número, o que foi descumprido) · achados de VERITAS (norma, jurisprudência, com citação) · pedidos possíveis (o que a empresa quer) · valores por alias de `#id` · **prazos** prescricionais e decadenciais com fonte e data de contagem · tentativas de solução (negociação, mediação) · perguntas abertas. O dossiê **não recomenda** estratégia processual — pergunta.

## 8. Ledger de casos — `agents/disputes/casos.md`

```
#P{NN} | caso (slug) | contraparte (alias) | contrato #K | fase (negociação | notificado | mediação | advogado acionado | judicial | acordo | encerrado) | próximo passo | prazo (#id, fonte) | dono | advogado (alias) | atualizado em
```

Fase muda só com evidência (comprovante da notificação, ata de mediação, protocolo do advogado). Acordo com valor: decisão do usuário por escrito; minuta a partir de `M{N}`, gates, §3.

## 9. Templates

- `templates/contracts-registry.md` — registro §2 com alertas e aditivos vinculados
- `templates/signature-ledger.md` — pré-condições §3, hash, signatários, confirmação, evidência
- `templates/dossie-advogado.md` — dossiê §7
- `templates/notificacao.md` — estrutura §6 com checklist de aprovação e envio

## 10. Contrato com o resto da squad

- **Produz:** FIDES (legal-compliance) — `contracts-registry.md`, alertas D-30/15/7; AEQUITAS (legal-ops) — signature-ledger, arquivo, follow-up, preparo de envio; CLEMENTIA (legal-disputes) — notificação, acordo, distrato de conflito, dossiê, ledger de casos.
- **Consome:** IUSTITIA fornece o PASS por versão; PRUDENTIA aprova estratégia de disputa e gate da notificação; CONCORDIA redige aditivo, distrato, acordo e a nova versão quando a contraparte pede mudança; VERITAS fornece citação de norma e prazo prescricional; LEX abre story de renovação/aditivo e valida o `M{N}` de aditivo e distrato.
- **Cruza:** IUSTITIA confere hash do arquivo ↔ versão com PASS, confirmação do usuário registrada com arquivo + destinatário, prazos com `#id` e fonte, zero dado sensível — e o hook `check-legal-progress.sh` só fecha task de envio, assinatura ou notificação com PASS + confirmação.
