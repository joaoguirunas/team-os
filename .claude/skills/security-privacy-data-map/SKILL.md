---
name: security-privacy-data-map
description: "Privacidade no código — mapa técnico de dados pessoais (campo → onde mora → quem lê → para onde vai → retenção → caminho de exclusão), varredura de logs, analytics e terceiros, minimização na coleta, consentimento aplicado no ponto de escrita e exclusão provada em todos os lugares. Use ao criar formulário, tabela ou integração com dado pessoal e ao atender pedido de exclusão."
version: "1.0"
updated: "2026-10-07"
---

# Mapa técnico de dados pessoais

Você não protege dado que não encontrou. Este mapa é **técnico**: onde o dado pessoal está no código, no banco, nos logs e nos terceiros, e por onde ele sai. A base legal e o registro jurídico são da squad Legal (`legal-compliance`), quando instalada — este mapa alimenta o dela.

## 1. Onde procurar (todos, não só o banco)

Tabelas e colunas · Storage (arquivos enviados) · logs de aplicação e de erro (Sentry, console do servidor, Vercel) · eventos de analytics (GA4, PostHog, Meta Pixel) · e-mail transacional e CRM · provedores de IA (o que vai no prompt) · webhooks enviados · backups · planilhas exportadas.

```bash
# Colunas com cara de dado pessoal nas migrations
grep -rniE "\b(nome|name|email|e_mail|telefone|phone|whatsapp|cpf|cnpj|rg|endereco|address|cep|nascimento|birth|ip_address)\b" --include='*.sql' --exclude-dir=node_modules .
# Dado pessoal indo para log ou analytics
grep -rnE "console\.(log|error)|logger\.|gtag\(|posthog\.capture|fbq\(" --include='*.[jt]s' --include='*.[jt]sx' --exclude-dir=node_modules --exclude-dir=.next . | grep -iE "email|phone|whatsapp|cpf|nome|name|user\b"
```

## 2. O mapa

`docs/smart-memory/agents/security/privacy/data-map.md` — nota viva:

| Campo (categoria) | Onde mora | Quem lê | Para onde vai | Finalidade | Retenção | Caminho de exclusão |
|---|---|---|---|---|---|---|
| e-mail do lead | `leads.email` | painel interno (service_role) | CRM via webhook | contato comercial | 24 meses | `delete` em `leads` + exclusão no CRM |

Categorias, nunca o dado em si: "e-mail do lead", não um e-mail real.

Campo sem finalidade escrita é recomendação de **não coletar**. Finalidade e base legal ficam em branco para a squad Legal preencher quando não houver resposta técnica.

## 3. Regras no código

- **Minimizar na coleta:** cada campo do formulário precisa de finalidade. Sem finalidade, sai do formulário — é o dado mais barato de proteger.
- **Consentimento aplicado onde o dado é usado:** opt-out de analytics bloqueia o envio do evento no código, não só grava uma flag.
- **Nada de dado pessoal em log, URL ou evento de analytics** (e-mail em query string vai parar no log de todo servidor do caminho).
- **Prompt de IA:** só o dado necessário para a tarefa; nunca documento inteiro "para dar contexto".
- **Anonimizado é afirmação a provar:** tirar o nome não anonimiza se CEP + data de nascimento + gênero reidentificam.
- **Retenção é automática:** job de exclusão ou arquivamento, não lembrete.

## 4. Pedido de exclusão (ou de acesso)

1. Resolver todos os lugares do titular pelo mapa (não por palpite).
2. Listar a ação em cada lugar (banco, Storage, CRM, e-mail, analytics, IA, backup conforme política).
3. A squad de código executa; o titular é referido por alias na smart-memory.
4. Prova: para cada lugar, a consulta que mostra que o dado não está mais lá.
5. Prazo e resposta ao titular: squad Legal / usuário.
