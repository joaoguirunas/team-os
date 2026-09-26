# Spawn prompts — exemplos, plan mode e modelos por tarefa

> Extraído do SKILL.md — carregar sob demanda. As regras (estrutura ideal, quando plan mode é obrigatório, quem vence entre `model` do arquivo e `/config`) continuam no SKILL.md.

## Exemplos de spawn prompt

**Exemplo ruim:**
```
"Revise o código de autenticação e melhore o que precisar."
```

**Exemplo excelente:**
```
"Você é o dev-qa responsável por auditar o módulo de autenticação.
 Seu scope EXCLUSIVO: src/auth/, tests/auth/, docs/smart-memory/agents/dev/qa/
 Stack: Next.js 15, Supabase Auth, JWT em httpOnly cookies.
 Ative /dev-security-patterns e /dev-testing-strategy para referência.
 Entregável: relatório em docs/smart-memory/agents/dev/qa/auth-audit.md com findings,
 severity ratings (CRITICAL/HIGH/MEDIUM/LOW) e recomendações priorizadas.
 Ao concluir: SendMessage para 'archi' com o path do relatório."
```

## Plan mode — instrução de spawn

```
"Spawn {agente} em plan mode para {tarefa}.
 Só aprovar o plano se incluir: {critério 1}, {critério 2}.
 Rejeitar se: {critério de rejeição}."
```

## Modelos por tipo de tarefa

| Tarefa | Modelo sugerido | Razão |
|---|---|---|
| Arquitetura / ADRs (architect) | Opus (fixo no arquivo) | Máximo raciocínio — decisão errada custa caro |
| Review / veredicto (reviewer/QA) | Opus (fixo no arquivo) | Veredictos precisam de rigor |
| Implementação complexa | segue o lead (`inherit`) | Lead escolhe sonnet por padrão |
| Pesquisa / análise | Haiku (via prompt) ou segue o lead | Mais barato, velocidade |

