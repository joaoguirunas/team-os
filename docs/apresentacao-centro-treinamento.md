# Apresentação: Centro de Treinamento de Agentes Claude Code

> **Briefing para o time de design:** criar apresentação com 8 slides. Tom: técnico-executivo. Público: times que querem adotar IA com orquestração real. Cada slide tem título, conteúdo e sugestão visual.

---

## Slide 1 — Capa

**Título:** Centro de Treinamento de Agentes Claude Code

**Subtítulo:** Squads de IA nativas que se comunicam, colaboram e entregam

**Visual sugerido:** diagrama hub-and-spoke — `team-os` no centro, 4 squads ao redor (dev, sites, social, traffic)

---

## Slide 2 — O que é o Centro de Treinamento

**Título:** Um sistema operacional para squads de IA

**Conteúdo:**
- Repositório central de **37 agentes** + **42 skills** nativos do Claude Code
- Cada agente tem papel, ferramentas e responsabilidades bem definidos
- Nenhum agente sabe fazer tudo — cada um faz **uma coisa com excelência**
- Tudo configurado em `.claude/agents/` e `.claude/skills/` — portável entre projetos

**4 squads disponíveis:**

| Squad | Agentes | Foco |
|---|---|---|
| **dev** | 10 | Software complexo (backend, frontend, infra, QA) |
| **sites** | 10 | Websites / Next.js (landing pages, CMS, SEO, deploy) |
| **social** | 7 | Redes sociais (content, design, photo, video, publish) |
| **traffic** | 10 | Tráfego pago Google / Meta / TikTok |

**Visual sugerido:** 4 cards lado a lado com ícone de cada squad

---

## Slide 3 — A Vantagem da Orquestração em Time

**Título:** Por que agentes que se falam são diferentes

**Tabela comparativa:**

| IA solo | Agentes em time |
|---|---|
| Uma sessão, um contexto | Múltiplos agentes em paralelo |
| Faz tudo, faz mal | Cada um especializado no seu papel |
| Sem verificação cruzada | QA formal com veredicto PASS / FAIL |
| Sem memória entre sessões | Smart-memory compartilhada e persistente |
| Bloqueante — uma coisa por vez | Tasks em paralelo real |

**Destaque (quote box):**
> Enquanto o dev-backend implementa a API, o dev-qa já lê a spec e prepara os critérios de aceite. Quando termina, vai direto ao gate — zero retrabalho de handoff.

**Visual sugerido:** duas colunas com ícones de contraste (vermelho/verde ou cinza/azul)

---

## Slide 4 — Como os Agentes se Comunicam

**Título:** Protocolo nativo: Agent Teams + SendMessage

**Fluxo:**

```
Usuário → /team-os
           │
           ├── TeamCreate("projeto-objetivo")
           │
           ├── Agent(dev-architect) ──► escreve stories em paralelo
           ├── Agent(dev-dev-beta)  ──► implementa em paralelo
           ├── Agent(dev-qa)        ──► emite PASS / FAIL
           └── Agent(dev-devops)    ──► git push + PR
                    │
                    └── SendMessage(lead) ao concluir ──► próximo passo automático
```

**3 garantias do protocolo:**
1. **Autoridade exclusiva** — só `dev-qa` emite veredictos, só `dev-devops` faz git push
2. **Sem nested teams** — agentes nunca spawnam sub-agentes (lead controla tudo)
3. **Sem polling** — cada agente avisa quando termina via `SendMessage`

**Visual sugerido:** diagrama de fluxo com setas e caixas coloridas por papel

---

## Slide 5 — team-os: O Maestro da Squad

**Título:** `/team-os` — Lead que detecta, planeja e orquestra

**O que faz:**
- **Detecta o estado do projeto** automaticamente (NEW / READY / IN_PROGRESS)
- **Bootstrap automático** em projetos novos — popula todo o smart-memory via discovery
- **Planeja** objetivos em stories com `/team-os *plan "objetivo"`
- **Despacha** trabalho para o time com `*dispatch`
- **Monitora** blockers e retoma sessões com `*resume`
- **Fecha** o ciclo: auditoria + arquiva smart-memory + encerra o team

**Comandos principais:**

| Comando | O que faz |
|---|---|
| `/team-os` | Detecta estado e roteia automaticamente |
| `*bootstrap` | Init + Discovery completo do projeto |
| `*plan "objetivo"` | Quebra objetivo em stories no backlog |
| `*dispatch` | Forma time e inicia trabalho |
| `*status` | Estado atual: tasks, agentes, blockers |
| `*close` | Arquiva e encerra o team |

**Visual sugerido:** ícone de maestro/regente + timeline dos estados do projeto

---

## Slide 6 — Smart Memory Obsidian

**Título:** `docs/smart-memory/` — A fonte de verdade compartilhada

**O problema que resolve:**
> Agentes não têm memória entre sessões. Cada conversa começa do zero. Sem um repositório externo, o contexto se perde — e o time regride.

**Como funciona:**
- Todos os agentes **lêem e escrevem** em `docs/smart-memory/`
- Compatível com **Obsidian** — wikilinks `[[arquivo]]`, frontmatter YAML, tags canônicas
- Estruturado por tipo: `project/`, `stories/`, `decisions/`, `ops/`
- Cada arquivo tem `agent:` (responsável), `status:`, `related:` (wikilinks de contexto)

**Estrutura de diretórios:**
```
docs/smart-memory/
├── project/          ← overview, arquitetura, tech-stack, módulos
├── stories/
│   ├── backlog/      ← próximas histórias
│   ├── active/       ← em progresso agora
│   └── done/         ← concluídas
├── decisions/        ← ADRs (Architecture Decision Records)
└── ops/              ← log de times, delegações
```

**Resultado:** qualquer agente (ou humano) entra numa sessão nova e tem contexto completo em segundos.

**Visual sugerido:** screenshot/mockup do vault Obsidian com wikilinks visíveis entre arquivos

---

## Slide 7 — team-os-creator: A Fábrica de Agentes

**Título:** `/team-os-creator` — Cria e instala squads em qualquer projeto

**O que faz:**
- Analisa o stack do projeto e **propõe a squad ideal** automaticamente
- Gera arquivos `.claude/agents/*.md` completos e prontos para uso
- Injeta o **Contrato com team-os** em cada agente (coordenação garantida)
- Instala as **skills relevantes** junto com os agentes
- **Propaga atualizações** de agentes para múltiplos projetos de uma vez

**Comandos principais:**

| Comando | O que faz |
|---|---|
| `/team-os-creator` | Menu principal: criar / atualizar / instalar |
| `*squad dev` | Cria squad dev completa (10 agentes) |
| `*create <role>` | Cria um agente interativamente |
| `*install` | Instala squads em projeto destino |
| `*propagate` | Propaga agentes atualizados para outros projetos |
| `*audit` | Valida conformidade de todos os agentes |

**Garantias de qualidade:**
- Nunca sobrescreve silenciosamente (idempotente)
- Nunca cria mais de 10 agentes por squad
- Nunca duplica o orquestrador (`/team-os` já é o lead)
- Skills são **sempre** instaladas junto — sem agente incompleto

**Visual sugerido:** animação ou diagrama de "fábrica" gerando arquivos `.md` em sequência

---

## Slide 8 — Por onde começar

**Título:** Do zero ao time rodando em 3 passos

**Passo 1 — Instalar a squad no seu projeto**
```bash
/team-os-creator *install
```
Detecta o stack, propõe agentes, instala tudo em `.claude/`

**Passo 2 — Inicializar o smart-memory**
```bash
/team-os
```
Bootstrap automático: descobre o projeto, popula o smart-memory, já começa a trabalhar

**Passo 3 — Planejar e executar**
```bash
/team-os *plan "construir sistema de autenticação com JWT e refresh tokens"
/team-os *dispatch
```
Stories criadas, time formado, trabalho em paralelo — você só aprova.

**Visual sugerido:** linha do tempo horizontal com os 3 passos + ícone de "equipe trabalhando em paralelo" no final

---

## Notas de design para o time

- **Paleta sugerida:** tons escuros (fundo) + acento em roxo/azul elétrico — referência ao Claude Code
- **Tipografia:** Sans-serif técnica (Inter, JetBrains Mono para código)
- **Ícones:** minimalistas, monocromáticos — evitar clipart
- **Código nos slides:** usar blocos com syntax highlight (fundo `#1e1e2e` ou similar)
- **Diagramas:** manter simples — hub-and-spoke, fluxos lineares, não sobrecarregar
- **Tamanho:** 16:9, resolução mínima 1920×1080
