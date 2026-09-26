---
name: legal-compliance-lgpd
description: "Método de conformidade em proteção de dados pessoais — mapa de dados, exigências de cada base legal, política de privacidade e termos de uso, consentimento e revogação, direitos do titular com prazo, incidente registrado em até 24 horas, operadores e calendário regulatório com `#id`. Use ao mapear dados, definir base legal, preparar política ou termos, atender titular ou registrar incidente."
version: "1.0"
updated: "2026-09-25"
---

# Legal Compliance LGPD — nenhum dado sem base legal, nenhum prazo fora do registro

Dado pessoal sem finalidade escrita é passivo. Base legal escolhida por conveniência é ficção que dura até a primeira reclamação. Incidente sem registro na hora vira versão. Esta skill dá o método de conformidade que a squad **prepara e registra** — mapa, bases, requisitos, fluxos — para o advogado inscrito da empresa validar e o usuário executar. A nomenclatura segue a LGPD (Lei nº 13.709/2018 — conferir na fonte); o método vale para qualquer regime de proteção de dados declarado em `legal-context.md`. Isto não é parecer.

## 1. Princípios

1. **Nenhum dado sem base legal.** Dado no mapa sem base = `[DEFINIR BASE LEGAL]` — e o tratamento não começa enquanto isso.
2. **"Legítimo interesse" não é padrão.** Só entra com teste documentado (finalidade, necessidade, expectativa do titular, balanceamento, salvaguardas) e aprovação de PRUDENTIA. Nunca para dado sensível.
3. **Finalidade específica e retenção com prazo.** "Melhorar o serviço" não é finalidade; "indefinido" não é retenção.
4. **Incidente registrado em ≤ 24h** do conhecimento, com o que se sabe, marcado `[PARCIAL]`. Avaliação e comunicação vêm depois — o registro, não.
5. **Nenhum prazo fora do registro.** Prazo de titular, de comunicação de incidente e de obrigação regulatória tem `#id`, fonte (norma + artigo, data de consulta) e dono.
6. **Dado sensível não entra em template nem smart-memory.** O mapa descreve categorias ("documento de identificação do cliente"), nunca o dado. Titular em incidente ou requisição: alias.
7. **A squad prepara; encarregado, advogado e usuário decidem e assinam.** Comunicação ao regulador e ao titular é ato do usuário com o advogado, com PASS de IUSTITIA + confirmação explícita.

## 2. Mapa de dados — `agents/compliance/data-map.md`

```
#D{NN} | categoria do dado | titular (cliente, lead, colaborador, usuário) | sensível? | finalidade específica | base legal (nome + art. + fonte datada) | coleta (onde, como) | retenção (prazo + gatilho) | quem acessa (papel) | operador/fornecedor (alias) | transferência internacional? | sistema | status
```

Uma linha por par dado × finalidade (mesmo dado, duas finalidades = duas linhas). Dado sensível marcado e com base do rol próprio (art. 11 — conferir). Retenção com gatilho ("término do contrato + N anos, fonte: …"). Acesso por papel, não por nome. Sem base = `[DEFINIR BASE LEGAL]`; sem retenção = `[DEFINIR RETENÇÃO]`. Revisão a cada novo sistema, fornecedor ou produto.

## 3. Bases legais — o que cada uma exige

Rol do art. 7 (dados pessoais) e art. 11 (sensíveis) — nomes abaixo; texto e requisitos, conferir na fonte; o advogado da empresa valida a escolha.

| Base | Exige | Serve para | Não serve para |
|---|---|---|---|
| Consentimento | manifestação livre, informada, inequívoca, por finalidade; registro; revogação fácil | marketing, cookies não essenciais, finalidade opcional | condição de serviço essencial; dado que a lei já exige |
| Obrigação legal ou regulatória | norma que obriga, citada | fiscal, trabalhista, registro contábil | "por segurança" sem norma |
| Execução de contrato / preliminares | contrato ou proposta com o titular | cadastro, entrega, cobrança, suporte | dado que o contrato não precisa |
| Exercício regular de direitos | processo, procedimento ou defesa concreta | guarda de prova, disputa | retenção genérica "caso precise" |
| Proteção do crédito | operação de crédito real | análise e cobrança de crédito | perfilamento comercial |
| Legítimo interesse | teste documentado + opt-out + aprovação de PRUDENTIA | segurança da informação, prevenção a fraude, aviso a cliente atual sobre o próprio serviço | dado sensível; finalidade que o titular não esperaria |
| Demais do rol (vida, saúde, pesquisa, políticas públicas) | hipótese estrita da norma | casos específicos | uso empresarial comum |

Cada base usada tem nota em `data-map.md` com a fonte; no legítimo interesse, o teste em anexo.

## 4. Política de privacidade e termos de uso — requisitos

FIDES escreve os **requisitos** (a partir do mapa); CONCORDIA escreve o **texto** (`M8`); PRUDENTIA aprova; IUSTITIA confere requisito ↔ texto ↔ mapa.

| Requisito | Fonte | Verificação |
|---|---|---|
| Identidade e canal do controlador e do encarregado (canal, não pessoa) | norma sobre informações ao titular — conferir | presente e funcional |
| Cada finalidade ativa do mapa, com a base legal | `#D` | 100% das finalidades listadas |
| Compartilhamentos e operadores por categoria | coluna operador | nenhum operador ativo fora da lista |
| Transferência internacional, se houver | mapa | mecanismo declarado |
| Retenção por categoria | mapa | igual ao mapa |
| Direitos do titular e como exercer (canal, prazo) | §6 | canal testado |
| Cookies: essenciais vs opcionais; consentimento para opcionais | mapa | banner coerente com o texto |
| Data da versão e histórico | — | versão publicada = versão com PASS |

Publicar política/termos é saída — hook `check-legal-progress.sh`: PASS + confirmação explícita do usuário.

## 5. Consentimento — `agents/compliance/consentimentos.md`

```
#C{NN} | finalidade (#D) | titular (alias / categoria) | texto apresentado (versão) | canal | data/hora | evidência (log, hash) | revogado em | efeito da revogação (o que parou)
```

Um consentimento por finalidade — nunca "aceito tudo". Texto versionado (mudou o texto, novo consentimento). Revogação pelo mesmo canal ou mais fácil, executada e datada. Sem evidência = sem consentimento.

## 6. Direitos do titular — fluxo de atendimento

```
1. Recebimento  → #R{NN}, canal, data/hora, direito pedido (confirmação, acesso, correção, anonimização, portabilidade, eliminação, informação, revogação), titular por alias
2. Identidade   → verificar sem coletar dado além do necessário; registrar método
3. Prazo        → contado do recebimento; prazo e forma conforme norma vigente (art. 18 e 19 — conferir) → #O no calendário
4. Levantamento → localizar no data-map (#D) tudo do titular: sistemas, operadores
5. Resposta     → preparada por FIDES; texto por CONCORDIA se sair do padrão; PASS de IUSTITIA; enviada pelo usuário
6. Registro     → resposta, data, o que foi feito; exceção legal citada com fonte
```

Pedido não atendível (obrigação de guarda, direito de terceiro): resposta fundamentada com citação — nunca silêncio.

## 7. Incidentes — `agents/compliance/incidentes.md`

| Fase | Prazo | O que se registra | Quem |
|---|---|---|---|
| Registro inicial | ≤ 24h do conhecimento | `#I{NN}`, data/hora do conhecimento, o que se sabe (categorias, titulares estimados, sistema, vetor), `[PARCIAL]` | FIDES |
| Contenção | imediata | ações, por quem, quando | usuário / TI; FIDES registra |
| Avaliação | ≤ 72h | risco ou dano relevante? (natureza, volume, sensibilidade, reversibilidade) — critério e prazo do regulador com achados de VERITAS | FIDES prepara; PRUDENTIA + advogado decidem |
| Comunicação a regulador e titulares | prazo da norma vigente (conferir na ANPD) → `#O` | minuta por CONCORDIA, PASS de IUSTITIA, **envio pelo usuário com o advogado** | AEQUITAS prepara o envio |
| Encerramento | — | causa raiz, medidas, lições; data-map e calendário atualizados | FIDES |

Nunca: apagar registro, esperar "ter certeza" para registrar, comunicar sem decisão de quem pode. Titular afetado: alias.

## 8. Fornecedores e operadores

Antes de contratar ou renovar fornecedor que trata dado: linha no data-map (coluna operador); cláusula de dados em `M2`/`M7` — papéis, finalidade limitada, instruções, segurança, subcontratação com aviso, incidente com prazo entre partes, auditoria, término com devolução/eliminação, transferência internacional; evidência mínima (política, certificações, local dos servidores) arquivada por alias. Fornecedor sem cláusula = `[OPERADOR SEM CLÁUSULA]` no mapa e alerta a PRUDENTIA.

## 9. Calendário de obrigações regulatórias — `agents/compliance/calendario-obrigacoes.md`

```
#O{NN} | obrigação | norma + art. (fonte VERITAS, data de consulta) | periodicidade / gatilho | próximo prazo | dono | evidência de cumprimento | status | alerta (D-30 / D-15 / D-7)
```

Entram: revisão anual do mapa e da política, relatório de impacto quando exigido, resposta a titular em aberto, comunicação de incidente em curso, obrigações setoriais de `legal-context.md`. Prazo sem fonte não entra; obrigação cumprida guarda evidência (arquivo por alias, data). `/data-analytics-engineering` se o calendário virar base.

## 10. Templates

- `templates/data-map.md` — mapa §2 com colunas fixas e marcas `[DEFINIR BASE LEGAL]` / `[DEFINIR RETENÇÃO]`
- `templates/registro-incidente.md` — `#I{NN}` com as cinco fases, prazos e decisões
- `templates/calendario-obrigacoes.md` — `#O{NN}` com fonte, dono, alerta e evidência

## 11. Contrato com o resto da squad

- **Produz:** FIDES (legal-compliance) — data-map, consentimentos, registro de titulares e incidentes, requisitos de política/termos, calendário.
- **Consome:** VERITAS fornece norma, artigo e prazo com citação datada; CONCORDIA escreve o texto da política, dos termos, da cláusula de dados e da comunicação de incidente a partir dos requisitos e do mapa; PRUDENTIA aprova base por legítimo interesse, política e decisão de comunicar; AEQUITAS prepara envio de resposta/comunicação só com PASS + confirmação; LEX abre a story `L4` (mapa) e as de política.
- **Cruza:** IUSTITIA confere política ↔ mapa ↔ bases (100% das finalidades com base e fonte), incidente registrado ≤ 24h, prazos com `#O` e fonte, zero dado de titular em smart-memory — falha = FAIL.
