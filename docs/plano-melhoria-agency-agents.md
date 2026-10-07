# Plano de melhoria do team-os com base no `agency-agents`

Fonte analisada: https://github.com/msitarzewski/agency-agents (MIT), clonado em `~/Desktop/agency-agents` (commit `5baafd5`, 06/10/2026).
Comparado contra: CT atual (95 agentes, 108 skills, 10 squads).

---

## 1. Resumo

- O repositório tem **~290 agentes em 18 divisões**, mais playbooks de orquestração (NEXUS), runbooks por cenário, templates de handoff e scripts de lint e de conversão para vários CLIs.
- É uma **biblioteca ampla de personas**. O que o CT tem de diferente é **governança**: Native Teams Protocol, autoridade exclusiva, veredictos PASS/CONCERNS/FAIL/WAIVED, hooks, smart-memory, pressure-test e propagação. O repositório não tem hooks, autoridade exclusiva nem pressure-test. Memória só aparece como exemplo opcional (um servidor MCP de memória em `examples/workflow-with-memory.md`), não como convenção dos agentes.
- Cerca de **70% do catálogo não serve** para o CT: China (Douyin, WeChat, Baidu…), game dev, Roblox, GIS, spatial/XR, firmware, blockchain, ServiceNow, Salesforce, healthcare, imobiliário, estudo no exterior, etc.
- Os ganhos reais são **3 squads novas (1 de prioridade alta)**, **3–4 agentes avulsos**, **algumas skills**, **~6 melhorias em agentes que já temos** e **4 melhorias de processo**.

> **Revisão (2ª passada, conferida contra o CT):** a 1ª versão deste plano superestimou algumas lacunas. Rastreamento (GTM/CAPI) e palavras-chave negativas já estão em `traffic-google`/`traffic-meta`/`traffic-bi`; busca agêntica/WebMCP já está na skill `seo-geo`; risco de churn já é do `pm-client`; o `dev-dev-alpha` já tem "nada fora do escopo IN". Esses itens foram rebaixados ou removidos abaixo. A conta de agentes também foi corrigida.
- Regra de ouro: **não copiar agente.** Reescrever em PT-BR, no padrão do CT (NTP, área na smart-memory, autoridade, Lei de Ferro, archetype), e passar por `*pressure-test` e pelo ciclo da RULE #12. Atribuir a origem no `THIRD_PARTY_NOTICES.md`, como já foi feito com o claude-seo.

---

## 2. Cobertura: onde já somos melhores ou iguais

| Domínio | Eles | Nós | Conclusão |
|---|---|---|---|
| Finance | 5 agentes | 8 (squad com QA, política, fechamento com `#id`) | Nós à frente. Não importar. |
| Legal | 3 agentes (voltados a escritório de advocacia) | 8 (jurídico da empresa) | Não é o mesmo problema. Não importar. |
| SEO / GEO | 3 agentes (AEO, citação por IA, SEO) | 15 + 27 skills `seo*` | Nós à frente. Não importar (busca agêntica já está na skill `seo-geo`). |
| Brand | 1 (Brand Guardian) | 8 | Nós à frente. |
| Social | ~15 por plataforma | 6 + skills `social-*` | Cobertura diferente (ver 4.8). |
| Paid media | 7 | 10 (traffic) | Quase equivalentes. No máximo um método de auditoria de conta (ver 3.5). |
| Sales | 9 (pipeline inteiro) | 8 (só proposta comercial) | Eles cobrem o funil. Nós só a proposta (ver 3.3). |
| PM | 7 | 10 | Nós à frente em gestão de projeto. Eles têm produto, que nós não temos. |
| Dev / QA | ~65 engineering + 9 testing | 12 dev + 10 sites | Eles têm profundidade em nichos. Nós temos o gate formal. |
| **Segurança** | 12 agentes | **nenhum agente; só a skill `dev-security-patterns`** | **Maior lacuna.** |

---

## 3. Lacunas que valem a pena preencher

### 3.1 Squad `security` — prioridade ALTA (add-on, como o `seo`)

Hoje segurança é a skill `dev-security-patterns` (JWT, RLS, OWASP, `.env`, tudo genérico) e o item 6 do checklist do `dev-qa` ("RLS ativo"). Conferido no CT: nenhum agente ou skill do pack trata das armadilhas específicas de código gerado por IA. "RLS ativo" é exatamente a checagem que deixa passar uma política `USING (true)`. Os projetos usam Next.js, Supabase e Vercel.

Agentes propostos (reescritos, não copiados):

| Agente CT (proposta) | Origem no repo | Função | Archetype |
|---|---|---|---|
| `security-appsec` | `security-appsec-engineer` | Threat modeling, code review seguro, OWASP | reviewer |
| `security-ai-code-auditor` | `security-ai-generated-code-auditor` | Segredos em `NEXT_PUBLIC_`/`VITE_`, RLS com `USING (true)`, autorização por `user_metadata`, prompt-injection em chamadas de LLM | reviewer |
| `security-secrets` | `security-secrets-credential-engineer` | Detecção, rotação e resposta a vazamento (vazou = rotaciona) | data/devops-like |
| `security-architect` | `security-architect` + `engineering-privacy-engineer` | Trust boundaries, desenho seguro, PII e minimização (LGPD técnico; o FIDES continua dono do registro legal) | architect |
| `security-incident` | `security-incident-responder` | Resposta e post-mortem (só prepara; contenção em produção é do devops/usuário) | researcher |
| `security-qa` | novo | Gate PASS/CONCERNS/FAIL/WAIVED de achados e correções | reviewer |

Regras próprias, no padrão do CT:
- A squad **audita e recomenda; nunca corrige nem sobe deploy** (fix é da squad `dev`/`sites`, deploy é do devops), igual ao `seo`.
- Excluir o `security-penetration-tester` e o `threat-intelligence-analyst`: risco de uso ofensivo sem contexto de autorização e pouco valor para os projetos atuais.

Instalação: `--squads sites,security` ou `dev,security`.

### 3.2 Funil de receita / outbound — prioridade MÉDIA

A squad `sales` do CT cuida de **uma proposta**. O repo cobre o funil.

| Origem | Aproveitar |
|---|---|
| `sales-outbound-strategist` | ICP, sequências multicanal por sinal |
| `sales-pipeline-analyst` | Saúde do pipeline, velocidade, acurácia de forecast |
| `sales-deal-strategist` | Qualificação MEDDPICC, plano de vitória |
| `sales-discovery-coach` | Método de discovery (reforça o `sales-analyst`) |
| `sales-account-strategist` | Expansão pós-venda (land-and-expand) |
| `sales-offer-lead-gen-strategist` | Ofertas e iscas de lead (útil para a mentoria) |

Proposta: squad nova `revenue` (6–7 agentes) em vez de inflar a `sales`. A `sales` fica "proposta e fechamento"; a `revenue` fica "funil, prospecção, pipeline, expansão". Autoridade exclusiva a definir (quem cria stories; quem aprova ICP).

### 3.3 Customer success e suporte — prioridade MÉDIA

O CT tem só parte disso: o `pm-client` (Eshara) já acompanha status de relacionamento e risco de churn, mas apenas como camada de dados da squad `pm`. Não há onboarding de cliente, health score com método, base de suporte nem e-mail de ciclo de vida. Antes de criar a squad, decidir se o `pm-client` continua como está ou passa a ser a fonte de dados dela. Fontes: `customer-success-manager`, `support-support-responder`, `product-feedback-synthesizer`, `support-analytics-reporter`, `marketing-email-strategist` (lifecycle e CRM).
Proposta: squad `cx` (5–6 agentes): onboarding e health score, churn, base de respostas de suporte, síntese de feedback, e-mail de ciclo de vida, QA. Tem aderência direta à Mentoria e ao comercial da Scalify.

### 3.4 Produto — prioridade BAIXA (decidir antes)

O "pm" do CT é gestão de **projeto**. Não há descoberta/estratégia de **produto**. Fontes: `product-manager`, `product-sprint-prioritizer` (RICE/MoSCoW), `product-trend-researcher`, `project-management-experiment-tracker`.
Risco: sobreposição com a autoridade exclusiva do `dev-architect` (criar stories). Se entrar, o agente de produto decide "o quê e por quê" e o architect continua dono da story.

### 3.5 Agentes avulsos para squads que já existem

| Agente novo (proposta) | Squad | Origem | Por quê |
|---|---|---|---|
| `traffic-auditor` | traffic | `paid-media-auditor` | Auditoria de conta Google/Meta com nota por categoria (hoje cai no `traffic-analyst`, sem método). Opcional: pode ser só uma skill do `traffic-analyst`. |
| `dev-ai-engineer` | dev | `engineering-ai-engineer` + `prompt-engineer` + `rag-pipeline-engineer` | Prompts, RAG e avaliação. Útil para quem constrói produtos com IA. |
| `dev-mcp-builder` | dev | `specialized-mcp-builder` | Constrói e testa servidores MCP (já mantemos `reference/mcp-servers.md`). |
| `dev-workflow-architect` | dev | `specialized-workflow-architect` + `automation-governance-architect` | Mapeia a árvore completa de um fluxo (incluindo falhas) antes de automatizar (n8n e afins). |
| `dev-payments` (condicional) | dev | `engineering-payments-billing-engineer` | Só se houver SaaS com Stripe/PSP. Idempotência e webhooks. |

Retirado na revisão: `traffic-tracking`. GTM, CAPI e atribuição já estão em `traffic-google`, `traffic-meta` e `traffic-bi`, e a skill `traffic-analytics-tracking` descreve o método.

Não criar agente para: `code-reviewer` (o `dev-qa` já tem veredicto formal), `technical-writer` (skill `dev-technical-writing` cobre), `devops-automator`/`git-workflow-master` (devops tem autoridade exclusiva), `sre` e `incident-response-commander` (cobertos por skill/plugin; no máximo uma skill `dev-incident-response`).

### 3.6 Skills e métodos (sem agente novo)

| Skill nova (proposta) | Origem | Para quem |
|---|---|---|
| `stats-experiment-design` | `academic-statistician` | traffic-bi, brand-insights, dev-data-performance (teste A/B válido, amostra, poder) |
| `evidence-grading` | `research-synthesist` | todos os analysts (nível de evidência, avaliação de fonte) |
| `training-design` | `corporate-training-designer` | Mentoria / Centro de Treinamento (levantamento de necessidade, currículo, avaliação) |
| `social-linkedin` | `marketing-linkedin-content-creator` | social (autoridade e marca pessoal, ligado ao `social-strategist`) |
| `social-youtube` | `marketing-video-optimization-specialist` | social-video (retenção, capítulos, miniatura) |
| `exec-summary` | `support-executive-summary-generator` | pm-reporter, finance-reporter, relatórios a cliente |
| `codebase-onboarding` | `engineering-codebase-onboarding-engineer` | Discovery Engine da `team-os` |
| `zettelkasten-notes` | `specialized-zk-steward` | Disciplina de notas atômicas e links na smart-memory |

---

## 4. Melhorias nos agentes e skills que já temos

Tudo isto é endurecimento de regras existentes. Antes de editar, conferir o texto atual de cada agente: este plano comparou temas, não linha a linha.

| # | Alvo | Melhoria | Origem |
|---|---|---|---|
| 4.1 | `dev-qa`, `sites-qa` | Checklist de **segurança de código gerado por IA** (segredo em variável pública, RLS `USING (true)`, auth por `user_metadata`, entrada não confiável em prompt) e regra "fix só vale com re-scan". Ganho imediato, sem squad nova. | `security-ai-generated-code-auditor` |
| 4.2 | `dev-security-patterns` (skill), `dev-data-engineer`, `sites-data` | Mesmo conteúdo, com os padrões Supabase/RLS. | idem |
| 4.3 | Todos os `*-qa` | Na Lei de Ferro: **nota perfeita de agente anterior é sinal de alerta**; primeira entrega nasce "precisa de ajuste"; cruzar a afirmação com arquivo/print, não com o relatório; gatilhos de falha automática. Conferir o que já existe nas 49 Leis de Ferro antes de duplicar. | `testing-reality-checker` |
| 4.4 | `sites-qa`, `dev-qa` | Evidência por captura de tela e fluxo completo (comandos Playwright obrigatórios no checklist). | `testing-evidence-collector` |
| 4.5 | `dev-dev-beta/gamma` (o `alpha` já tem "nada fora do escopo IN"; **não** o `delta`, que é hardening) | Disciplina de **diff mínimo**: só o que a story pede, "pergunte antes de assumir a interpretação maior", sugestão fora de escopo vira follow-up, não edição escondida. No `alpha`, só completar a regra que já existe. | `engineering-minimal-change-engineer` |
| 4.6 | `sites-ux` | Passeio cognitivo por persona e revisão "UI genérica/intercambiável" antes de entregar. | `design-persona-walkthrough`, `design-ui-finish-gate-reviewer` |
| ~~4.7~~ | `traffic-google` | **Retirado na revisão.** O agente já tem lista de negativas, checklist e revisão semanal do Search Terms Report. | — |
| 4.8 | `social-photo`, `social-design` | Guarda de representação inclusiva e engenharia de prompt de imagem. | `design-inclusive-visuals-specialist`, `design-image-prompt-engineer` |
| ~~4.9~~ | `seo-geo` | **Retirado na revisão.** A skill `seo-geo` já cobre agentes de busca, WebMCP e crawlers agênticos. No máximo, uma linha no agente apontando para essa seção da skill. | — |
| 4.10 | `sales-planner`, `sales-analyst` | Matriz de conformidade/win themes (proposta) e MEDDPICC na ficha de intake. | `sales-proposal-strategist`, `sales-deal-strategist` |

---

## 5. Melhorias de processo (as mais valiosas do repo)

1. **Runbooks por cenário com portão por fase.** O NEXUS define 7 fases (descoberta → estratégia → fundação → build → hardening → lançamento → operação), com critério de passagem em cada uma, e 4 runbooks (MVP de startup, feature enterprise, resposta a incidente, campanha de marketing) com roster em JSON. O `team-os` hoje dimensiona o time, mas não tem receitas prontas. Proposta: `team-os/reference/runbooks/` com receitas **nas nossas squads e nos nossos agentes** (site novo, feature nova, incidente, campanha, proposta, reposicionamento, fechamento do mês), cada uma com fases, paralelismo e portão.
2. **Template de handoff e relatório de escalonamento.** O repo padroniza o handoff (de/para, contexto, critério de aceite, evidência exigida) e o ciclo QA com **tentativa N de 3** e relatório de escalonamento ao falhar a 3ª vez. O CT tem o `[handoff]` até 60 linhas e o ciclo QA↔implementer. Proposta: adotar os campos "critério de aceite" e "evidência exigida" e formalizar o escalonamento na 3ª falha. Respeitar o limite do `guard-message-size.sh`.
3. **Checagem de originalidade na criação.** O `check-agent-originality.sh` compara agentes por sobreposição de trechos de 8 palavras (ignorando nomes próprios) para barrar "re-skins". Proposta: rodar algo equivalente no `*create` e no `*audit`, principalmente para agentes próprios (`origin: custom`) e para os que vamos importar daqui.
4. **Seção "Métricas de sucesso" nos agentes.** Só 5 dos 95 agentes têm. O repo exige o par identidade/missão/regras e recomenda métricas. Adicionar métricas observáveis ajuda `*pressure-test` e QA. Fazer por squad, junto com outras edições, não em lote.

Não adotar: instaladores e conversores para outros CLIs (Cursor, Gemini, Aider…). O CT é Claude Code nativo; manter a manutenção fora do foco.

---

## 6. O que NÃO importar (e por quê)

| Item | Motivo |
|---|---|
| `agents-orchestrator` | Viola a RULE #7 (a sessão principal já é o lead). |
| `accounts-payable-agent` | Executa pagamentos. A squad `finance` prepara e nunca move dinheiro. |
| `finance-investment-researcher`, `chief-financial-officer`, `finance-tax-strategist` | Aconselhamento de investimento e tributação de outras jurisdições. A política do CT é preparar para o contador. |
| Penetration tester, threat intel | Risco de uso ofensivo; sem demanda. |
| Legal de escritório (intake, cobrança de horas) | Problema diferente do jurídico da empresa. |
| China, game, Roblox, GIS, XR, firmware, blockchain, healthcare, imobiliário, estudo no exterior, línguas | Fora do negócio. |
| Plataformas isoladas (Reddit, Twitter, Instagram, TikTok, Podcast, ASO) | Cobertas por skills `social-*` e `tiktok-marketing`. ASO só se houver app. |

---

## 7. Roadmap sugerido

| Fase | Entrega | Esforço | Risco |
|---|---|---|---|
| **0 — Ganhos rápidos** (sem agente novo) | 4.1 a 4.5, checagem de originalidade (5.3), template de handoff/escalonamento (5.2) | 1–2 sessões | Baixo |
| **1 — Squad `security`** | 3.1 completa: 6 agentes, preset, skills `security-*`, pressure-test, `*audit`, `*propagate` | 2–3 sessões | Médio (autoridades) |
| **2 — Runbooks** | 5.1 com 5–7 receitas | 1–2 sessões | Baixo |
| **3 — Receita e CX** | squads `revenue` e `cx` (3.2, 3.3) | 3–4 sessões | Médio (sobreposição com `sales`/`pm`) |
| **4 — Avulsos e skills** | 3.5 e 3.6, por demanda real | contínuo | Baixo |
| **5 — Condicional** | 3.4 (produto), `dev-payments`, RH/treinamento | só se houver demanda | — |

Cada item segue a **RULE #12**: refinar → pressure-test (agente novo) → sincronizar README/CLAUDE.md/contagens → `generate-agents-page.py` → `*audit` (agentes e `--skills`) → `test-hooks.sh` → commit (só o mantenedor) → `*propagate --match-target-squads`.

Impacto nas contagens ao fim das fases 1 a 4: `security` +6, `revenue` +6 a 7, `cx` +5 a 6, avulsos +3 a 4. Isso leva de 95 para **cerca de 115 a 118 agentes** e de 10 para 13 squads. Só a Fase 1 dá 101 agentes e 11 squads. Os números do `README.md`, do `CLAUDE.md` e do CI mudam juntos.

---

## 8. Decisões que dependem de você

1. Começo pela Fase 0 (ganhos rápidos), ou já pela squad `security`?
2. `revenue` e `cx` devem ser squads separadas, ou agentes extras dentro de `sales` e `pm`?
3. Há SaaS com cobrança (Stripe) ou app mobile? Isso decide `dev-payments` e ASO.
4. Quer que o repo clonado em `~/Desktop/agency-agents` fique como referência, ou removo depois?

---

## 9. Licença e atribuição

O repositório é MIT. Adaptar é permitido, mantendo o aviso de copyright. Cada agente ou skill derivado entra no `THIRD_PARTY_NOTICES.md` (seção `agency-agents`, titular "AgentLand Contributors" conforme o `LICENSE`, repositório `msitarzewski/agency-agents`), com origem e o que foi adaptado. Conteúdo reescrito em PT-BR e no padrão do CT.
