---
name: sales-discovery-intake
description: Transformar reunião, transcrição, resumo ou troca de e-mails com um cliente em ficha de intake estruturada — dores priorizadas na linguagem do cliente, stack e processo atual, sinais de compra, objeções e sensibilidades, decisor e ponto focal, números declarados e pendências com a pergunta pronta. Use antes de planejar qualquer proposta comercial, ao receber material de reunião ou quando faltar dado do cliente.
version: "1.0"
updated: "2026-09-07"
---

# Sales Discovery Intake — da reunião à ficha

Uma proposta boa começa com um diagnóstico que o cliente reconhece como seu. Esta skill converte material bruto de discovery em uma **ficha de intake** que o planejador, a estrategista e a financeira consomem sem voltar à gravação.

Princípio único: **o que o cliente disse é dado; o que você deduziu é hipótese; o que falta é pergunta.** Os três nunca se misturam na ficha.

## 1. Insumos aceitos

| Insumo | Como tratar |
|---|---|
| Transcrição (call, reunião) | Fonte primária. Citações literais com marcador de tempo quando houver |
| Resumo escrito por alguém do time | Fonte secundária — marcar `[resumo de {autor}]`; não vira citação |
| E-mails, mensagens | Literal, com data |
| Screenshots de chamada / anotações | Transcrever o que está legível; o resto é `[ILEGÍVEL]` |
| Site, redes, materiais públicos do cliente | Pesquisa, não intake — vai para o research report |

Nunca inferir o que não está no material. Se duas fontes divergem, registre ambas e marque `[CONFIRMAR COM O CLIENTE]`.

## 2. O que extrair — em ordem

### 2.1 Dores, priorizadas e na linguagem do cliente

| # | Dor | Como o cliente descreveu (literal) | Impacto que ele percebe | Prioridade |
|---|---|---|---|---|

Regras:
- **Prioridade** = Crítica (ele abriu a reunião com isso / repetiu / tem número) · Alta (mencionou com detalhe) · Média (surgiu de passagem)
- A coluna literal é obrigatória para dores Críticas — é ela que vira a página "O que ouvimos" da proposta
- Dor política (impacto em pessoas, cargos, fornecedores atuais) recebe a tag `sensível` — precisa de tratamento cuidadoso no planejamento

### 2.2 Stack e processo atual
Ferramentas, planilhas, pessoas, integrações que não se falam, o que é manual, o que já foi tentado. Quem opera hoje. Custos declarados de ferramentas.

### 2.3 Sinais de compra
Perguntas que revelam que o cliente já se projeta usando a solução ("como fica a comissão de venda recuperada?", "dá pra virar um produto depois?", "e o meu time?"). Cada sinal vira argumento ou cuidado no planejamento.

### 2.4 Objeções e sensibilidades observadas
O que ele hesitou, perguntou duas vezes, ou onde mudou o tom. Diferente de objeção *prevista* (isso é do planejador): aqui só o que **aconteceu**.

### 2.5 Pessoas
| Nome | Papel | Função na decisão (decisor / influenciador / operacional / veto) | Observação |

### 2.6 Números declarados
| Número | Valor | Quem disse | Quando | Verificado? |
Sempre `Verificado? = não` no intake. Quem valida é a financeira; quem verifica fonte externa é a pesquisa.

### 2.7 Princípios e acordos técnicos já fechados na reunião
Coisas que o time já combinou com o cliente ("API acima de automação de tela", "texto antes de voz") — vão para a proposta como credibilidade, não podem ser contrariadas depois.

### 2.8 Pendências — a pergunta pronta
| O que falta | Pergunta exata a fazer | Por que importa (que conta/decisão depende) | Quem pergunta |

Pendência sem pergunta pronta não é pendência — é preguiça.

## 3. Template

Use `templates/intake.md` desta skill. Frontmatter Obsidian (`kind: reference`, `status`, `summary`), salvo em `docs/smart-memory/agents/discovery/{cliente-slug}-intake.md`. O `summary` traz: nº de dores críticas, nº de pendências, decisor identificado ou não.

## 4. Do intake para o resto da squad

| Seção do intake | Quem consome | Para quê |
|---|---|---|
| 2.1 Dores + literal | Planejador, redatora | Diagnóstico e página "O que ouvimos" |
| 2.2 Stack | Planejador | Lacunas técnicas, roadmap |
| 2.3 Sinais | Estrategista, planejador | Tese, cuidados de escopo |
| 2.4 Objeções observadas | Estrategista, planejador, fechamento | Postura, seção de objeções, brief de reunião |
| 2.5 Pessoas | Estrategista, fechamento | Quem decide, quem convencer |
| 2.6 Números | Financeira | Base (declarada) das contas de payback |
| 2.7 Acordos | Redatora | Credibilidade técnica no texto |
| 2.8 Pendências | Lead / usuário | O que perguntar antes de emitir |

## 5. Anti-padrões

- **Diagnóstico traduzido** — trocar as palavras do cliente por jargão seu. A proposta perde o efeito "eles me entenderam".
- **Dor inventada por dedução** — "ele deve ter problema de X". Se não disse, não está na ficha (pode estar no research como hipótese).
- **Recomendar solução no intake** — a ficha mapeia; a tese é da estrategista.
- **Número do cliente como fato** — "o ticket médio é R$ 7.500" → "ticket médio de R$ 7.500, declarado por {nome} em {data}, não verificado".
- **Pendência genérica** — "levantar dados financeiros" → "faturamento mensal, ticket médio, pedidos/mês, carrinhos abandonados/mês e taxa de recuperação atual — necessários para a conta de payback A".
