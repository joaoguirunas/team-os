---
name: security-incident-response
description: "Resposta a incidente de segurança em projetos web — classificação SEV1–SEV4, primeira hora, preservação de evidência, contenção planejada (executada por quem tem autoridade), rotação de credencial sem derrubar o serviço, linha do tempo em UTC e post-mortem com 3–5 correções. Use ao suspeitar ou confirmar vazamento, acesso indevido ou chave exposta."
version: "1.0"
updated: "2026-10-07"
---

# Resposta a incidente

A squad **prepara e coordena**. Quem executa contenção em produção é o devops da squad de código ou o usuário; quem comunica fora da empresa é o usuário (com advogado, se houver dado pessoal). Esta divisão não é burocracia: contenção errada apaga a evidência e comunicação errada vira passivo.

## 1. Classificação

| SEV | Situação | Exemplo |
|---|---|---|
| **SEV1** | Dado sendo exfiltrado ou alterado agora; acesso indevido ativo | tabela aberta sendo lida em massa; chave usada por terceiro |
| **SEV2** | Exposição confirmada de dado pessoal ou credencial privada, sem uso confirmado | `service_role` no bundle publicado; bucket de contratos aberto |
| **SEV3** | Vulnerabilidade explorável encontrada, sem sinal de exposição | IDOR descoberto em auditoria |
| **SEV4** | Violação de política sem exposição | chave de teste commitada e já revogada |

Na dúvida entre dois níveis, use o mais grave até a evidência dizer o contrário.

## 2. Primeira hora (SEV1/SEV2)

1. **Abrir o registro** em `docs/smart-memory/agents/security/incident/INC-{NN}.md`, horário em **UTC**: o que se sabe, o que não se sabe, quem foi avisado. Marque `[PARCIAL]`.
2. **Avisar o lead** (que avisa o usuário) — fatos, não suposição: "confirmamos X", "ainda não sabemos Y".
3. **Preservar evidência antes de mudar qualquer coisa:** exportar logs do provedor (Supabase, Vercel, provedor de IA) do período, anotar commit e deploy atuais, print do painel de uso da chave. Nunca apagar commit, log, linha ou arquivo "para limpar".
4. **Propor a contenção** (o devops ou o usuário executa): revogar/rotacionar a credencial, fechar a policy, tirar a rota do ar, desativar a feature. Cada ação com dono, horário e como verificar que funcionou.
5. **Se houver dado pessoal envolvido:** a squad Legal (se instalada) registra o incidente — `legal-compliance` registra em ≤ 24h e o advogado avalia comunicação ao regulador e aos titulares no prazo da norma vigente. Sem squad Legal: avisar o usuário que a avaliação de comunicação é com o advogado dele. A squad Security nunca decide nem envia comunicação externa.

## 3. Rotação sem derrubar o serviço

Ordem que evita outage:

1. Criar a credencial **nova** no provedor.
2. Colocar a nova no ambiente (Vercel/servidor) e fazer redeploy.
3. Testar o fluxo que usa a credencial.
4. **Só então revogar a antiga.**
5. Conferir no painel do provedor que a antiga não aparece mais em uso.

Quem rotaciona é o usuário (ou o devops, com acesso dado por ele). A squad entrega o roteiro com os nomes das variáveis e dos serviços — nunca o valor.

## 4. Investigação

- A cadeia completa: **entrada → o que foi feito → impacto**. Sem explicar a cadeia inteira, a causa raiz não foi encontrada.
- Janela de exposição: do commit/deploy que expôs até a contenção. Verifique uso da credencial nesse período no painel do provedor.
- Atribuição a pessoa ou grupo só com evidência técnica forte — e normalmente não é necessária.

## 5. Post-mortem

`INC-{NN}.md` fecha com:

- Linha do tempo em UTC
- Causa raiz × fatores contribuintes × gatilho
- O que funcionou e o que atrasou
- **3 a 5 correções** priorizadas (não uma lista de 50), cada uma com dono e story — o `security-architect` cria as stories
- Requisitos de modelagem de ameaças que teriam evitado (`security-threat-modeling`)

Sem culpados nomeados: o post-mortem descreve sistemas e decisões, não pessoas.
