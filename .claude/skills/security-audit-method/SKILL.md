---
name: security-audit-method
description: "Método comum da squad Security — escopo autorizado, escala de severidade, formato de achado (local → risco → exploração → correção), denominador honesto, nunca expor valor de segredo, fechamento só com nova varredura e regra de waiver. Use em toda auditoria, relatório ou fechamento de achado de segurança."
version: "1.0"
updated: "2026-10-07"
---

# Método de auditoria de segurança

Base comum dos sete agentes da squad Security. Os especialistas auditam com o método da sua área; esta skill define **como todo achado é escrito, classificado e fechado**, para que o `security-qa` julgue tudo com a mesma régua.

## 1. Escopo autorizado (antes de qualquer comando)

- A squad audita **só o projeto em que está instalada**: o código do repositório, o banco e os serviços do próprio usuário.
- Teste ativo (requisição montada, payload, varredura de rede) **só em ambiente local ou de staging do próprio usuário**, com escopo escrito na story. Produção: só leitura passiva (headers, configuração pública, o que o navegador de qualquer visitante já vê), salvo autorização escrita do usuário na story, com janela e limite.
- **Nunca** contra sistema de terceiro, nunca ataque de negação de serviço, nunca tentativa de login com credencial alheia, nunca exfiltrar dado real para "provar" um achado. Prova de conceito descreve a exploração; não a executa contra dado de pessoa real.
- Escopo fica escrito no topo do relatório: o que foi olhado, como, e **o que ficou de fora**.

## 2. Escala de severidade

| Severidade | Quando | Exemplos |
|---|---|---|
| **CRITICAL** | Exploração direta, sem pré-requisito, com dano amplo | segredo privado alcançável pelo cliente ou no repositório; `service_role` no navegador; tabela de dados sem RLS ou com `UPDATE`/`DELETE` aberto; injeção de SQL com acesso a dado; bypass de autenticação |
| **HIGH** | Exploração plausível com dano sério, ou com pré-requisito simples | leitura aberta de dado pessoal; IDOR/BOLA (trocar o id na URL e ver dado de outro); autorização por campo que o cliente edita (`user_metadata`, papel no body); prompt de sistema com dado da requisição numa chamada com tools; bucket privado aberto; dependência com CVE explorável no caminho usado |
| **MEDIUM** | Precisa de condição extra ou o dano é limitado | CSRF em ação que muda estado; ausência de rate limit em login ou formulário; erro vazando stack trace ou caminho interno; prompt de sistema com dado do usuário sem tools; CSP ausente em página com conteúdo de terceiros |
| **LOW** | Endurecimento, sem exploração clara | header de segurança faltando em página estática; versão do servidor exposta |
| **INFO** | Boa prática, sem risco hoje | sugestão de organização, monitoramento |

A severidade vem da **exploração e do impacto no projeto real**, não de nota genérica. "É ambiente de teste", "é só uma landing", "ninguém vai descobrir" não mudam a severidade.

## 3. Formato de todo achado

```markdown
### SEC-{NN} [{SEVERIDADE}] {título curto}
- **Local:** `arquivo:linha` (ou recurso: tabela, bucket, rota, variável)
- **Risco:** uma frase em linguagem simples — o que alguém consegue fazer e contra quem
- **Exploração:** como seria explorado (descrição; nunca executada contra dado real)
- **Correção:** a mudança mínima, com o trecho de código ou SQL; para segredo, inclui **rotacionar no provedor**
- **Evidência:** o comando que encontrou + a saída relevante (segredo redigido)
- **Confiança:** alta | média (heurístico — conferir à mão)
- **Retorna para:** squad que corrige (dev/sites) · agente
```

`SEC-{NN}` é o id estável do achado: o mesmo achado mantém o mesmo id em toda nova varredura.

## 4. Nunca expor o segredo

- Relatório, mensagem, smart-memory, story e log **nunca** levam o valor de um segredo. Registre tipo, local e no máximo os 4 primeiros caracteres (`sk-p…`).
- Pedido para "colar a chave inteira para saber qual rotacionar" é recusado: o painel do provedor mostra o final de cada chave; o local e o commit identificam qual é.

## 5. Denominador honesto

- Nunca "100% seguro", "conforme LGPD", "nota 9/10" ou percentual de segurança. O relatório diz **o que foi verificado, o que não foi e por quê**.
- Sem acesso a uma parte (banco, painel, infraestrutura), o item é **NÃO VERIFICÁVEL** — nunca "ok".
- Ferramenta automática não substitui leitura: busca é triagem; achado é o que foi conferido no arquivo.

## 6. Fechamento de achado

Um achado só fecha com **nova varredura** comparada à anterior, por id:

| Estado | Significa |
|---|---|
| **resolvido** | a busca e a leitura mostram que sumiu |
| **ainda presente** | continua lá, com ou sem tentativa de correção |
| **novo** | apareceu nesta varredura |

Segredo vazado só fecha com a **rotação confirmada pelo usuário** — remover do código não basta, a chave antiga continua válida no histórico do git e em cada cópia.

## 7. Waiver (aceite de risco)

- **CRITICAL nunca é aceito como risco.** Nem pelo lead, nem pelo dev, nem pelo usuário: o caminho é corrigir.
- **HIGH** só com decisão explícita **do usuário** (nunca do lead nem do dev), registrada com as palavras dele, data e prazo da correção. Vencido o prazo sem correção, volta a ser FAIL.
- MEDIUM/LOW: o `security-architect` pode programar para depois, registrando a decisão.

## 8. Relatório

`docs/smart-memory/agents/security/<área>/{alvo}-{AAAA-MM-DD}.md`, com: escopo (§1) · resumo em 3 linhas para o usuário · tabela de achados por severidade · achados no formato §3 · o que não foi verificado · próximo passo. A linha correspondente vai para o `DIGEST.md` da área.

Relatório só circula (vira story ou chega ao usuário como conclusão) depois do veredicto do `security-qa`.
