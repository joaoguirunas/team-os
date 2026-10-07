---
name: security-threat-modeling
description: "Modelagem de ameaças leve para web apps, sites e apps com LLM — inventário de ativos, fronteiras de confiança, fluxos de dado, STRIDE por fronteira e saída em requisitos de segurança testáveis que viram critério de aceite de story. Use antes de feature nova com auth, pagamento, dado pessoal, upload, integração ou IA."
version: "1.0"
updated: "2026-10-07"
---

# Modelagem de ameaças

O objetivo não é um documento bonito: é uma lista curta de **requisitos testáveis** que entram como critério de aceite nas stories antes de o código existir. Modelo que não vira requisito não protegeu nada.

## Quando modelar

Feature nova ou mudança em: login/cadastro/sessão · papéis e permissões · pagamento · dado pessoal (lead, cliente, documento) · upload de arquivo · webhook ou integração de terceiro · chamada a modelo de IA com tools ou com dado do usuário · painel administrativo · API pública.

Mudança de texto, estilo ou página estática sem formulário: não precisa.

## Passo 1 — Ativos (o que vale proteger)

| Ativo | Onde mora | Quem deveria acessar |
|---|---|---|
| ex.: leads (nome, e-mail, WhatsApp) | tabela `leads` | só o painel interno |

## Passo 2 — Fronteiras de confiança

Desenhe o caminho do dado e marque cada ponto onde ele **muda de dono de confiança**:

```
navegador (não confiável) → rota de API / server action → banco (RLS) → storage
                          → provedor de IA (prompt) → tools (ações reais)
                          → webhook de terceiro (não confiável) → rota de servidor
```

Em projeto Next.js + Supabase, as fronteiras típicas: tudo que roda no navegador (inclusive variável `NEXT_PUBLIC_`); a anon key + RLS; rotas de servidor com `service_role`; Storage; webhooks; chamada ao modelo.

## Passo 3 — STRIDE em cada fronteira

| Letra | Pergunta | Controle típico |
|---|---|---|
| **S**poofing | Alguém se passa por outro usuário ou sistema? | sessão do provedor de auth; assinatura de webhook |
| **T**ampering | Alguém altera dado que não é dele? | RLS com `auth.uid()`; validação no servidor; `WITH CHECK` |
| **R**epudiation | Alguém nega ter feito uma ação sensível? | log com `requestId` e `userId` em ação crítica |
| **I**nformation disclosure | Alguém lê o que não devia? | RLS de leitura; nada de segredo no cliente; erro sem stack trace |
| **D**enial of service | Alguém derruba ou encarece o serviço? | rate limit em login, formulário e rota de IA; limite de tamanho |
| **E**levation of privilege | Alguém ganha papel que não tem? | papel em `app_metadata` ou tabela, nunca `user_metadata`; tools da IA com confirmação |

Para apps com LLM, acrescente: **injeção de prompt** (dado não confiável vira instrução), **agência excessiva** (tool que age sem confirmação), **saída do modelo tratada como confiável** (HTML do modelo renderizado sem sanitizar, SQL ou comando montado pelo modelo).

## Passo 4 — Requisitos testáveis

Cada ameaça relevante vira um requisito no formato:

```markdown
- **REQ-SEC-{n}** {o que deve ser verdade} — **Teste:** {como provar: comando, requisição com a anon key, teste automatizado} — **Story:** {id}
```

Exemplo: "**REQ-SEC-3** um visitante com a anon key não lê nenhuma linha de `leads` — **Teste:** `select` com a anon key retorna 0 linhas e o teste `leads-rls.spec.ts` cobre — **Story:** L2".

"Usar criptografia" ou "seguir boas práticas" não é requisito. Requisito diz o que deve ser verdade e como se prova.

## Passo 5 — O que fica de fora

Liste as ameaças consideradas e **aceitas** ou adiadas, com o motivo e quem decidiu (regras de waiver em `security-audit-method` §7).

## Onde fica

`docs/smart-memory/agents/security/architecture/threat-model-{feature}.md` — nota viva da feature, atualizada in-place quando a feature muda. Os REQ-SEC entram como critério de aceite nas stories pelo `security-architect`.
