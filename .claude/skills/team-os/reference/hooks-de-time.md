# Hooks de time

> Extraído do SKILL.md — carregar sob demanda.

Seis hooks de qualidade fazem parte do **settings padrão** de todo projeto team-os (registrados pelo `scripts/ensure-settings.sh`, que o `*install` chama): **TaskCreated** → `task-quality.sh`; **TaskCompleted** → `check-story-progress.sh`, `check-social-progress.sh`, `check-proposal-progress.sh`, `check-finance-progress.sh`, `check-legal-progress.sh`. `TeammateIdle` é receita **opcional** por projeto. Os scripts vivem em `.claude/hooks/` (distribuídos pelo `*propagate`) e são testados pelo `team-os-creator/scripts/test-hooks.sh`.

## TaskCreated — gate de qualidade de task (PADRÃO)

`task-quality.sh` roda quando uma task é criada e **rejeita task vaga** — sem entregável claro, sem owner/escopo identificável, ou descrição de uma linha genérica ("melhorar X"). Task rejeitada volta ao lead para reescrever com paths, entregável e critério de done.

Registro (o `ensure-settings.sh` garante — não edite à mão):
```json
{
  "hooks": {
    "TaskCreated": [{
      "matcher": "",
      "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/task-quality.sh" }]
    }]
  }
}
```

## TaskCompleted — gate de evidência (PADRÃO)

`check-story-progress.sh` roda quando uma task é marcada como concluída e valida o progresso da story: **story só fecha com evidência** (`## QA Results` ou `status: done|in-review` na story). Complementa a doutrina "Não confie no relato" do Lead OS — o hook barra o fechamento sem evidência antes mesmo de o lead verificar. Os outros quatro gates do mesmo evento — `check-social-progress.sh` (publicação social só com aprovação VERA/strategist), `check-proposal-progress.sh` (proposta só com PASS do `sales-qa` + confirmação do usuário), `check-finance-progress.sh` (execução financeira só com PASS do `finance-qa` + confirmação) e `check-legal-progress.sh` (saída jurídica só com PASS do `legal-qa` + confirmação) — seguem o mesmo padrão: **a squad prepara, o humano executa**.

Registro (o `ensure-settings.sh` garante — não edite à mão):
```json
{
  "hooks": {
    "TaskCompleted": [{
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-story-progress.sh" },
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-social-progress.sh" },
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-proposal-progress.sh" },
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-finance-progress.sh" },
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-legal-progress.sh" }
      ]
    }]
  }
}
```

> Se algum desses scripts faltar em `.claude/hooks/` do projeto, o `ensure-settings.sh` avisa — rode `/team-os-creator *propagate` no CT (os hooks são distribuídos de lá).

## TeammateIdle — OPCIONAL, e CUIDADO com loop

> **Atenção:** ficar ocioso é o estado **desejado** (teammate vivo, esperando mais task). O que resolve o encerramento precoce é a **regra Team Persistence** (no SKILL.md), não este hook. Use-o só se quiser que teammates puxem tasks pendentes em vez de ociar.
>
> ⚠ **Loop infinito:** um hook TeammateIdle que **sempre** sai com `exit 2` prende o teammate — ele nunca consegue ficar idle, gira para sempre queimando tokens. `exit 2` só é aceitável quando há de fato task pendente na fila; caso contrário o hook DEVE sair com `exit 0`.

**Não é instalado por padrão** (não está no `ensure-settings.sh`). Receitas:

Versão **segura** (só nudge informativo, `exit 0` — nunca bloqueia o idle):
```json
{
  "hooks": {
    "TeammateIdle": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Teammate ocioso (vivo). Se há tasks pendentes na fila, faça self-claim.'; exit 0"
      }]
    }]
  }
}
```

Versão **condicional segura** ("mantém trabalhando" sem loop): `exit 2` **apenas se** existir task pendente compatível — senão `exit 0`. Exemplo com um script no projeto:
```json
{
  "hooks": {
    "TeammateIdle": [{
      "matcher": "",
      "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/idle-nudge.sh" }]
    }]
  }
}
```
```bash
#!/bin/bash
# idle-nudge.sh — exemplo de TeammateIdle SEM loop infinito.
# Só devolve exit 2 (bloqueia o idle, com mensagem) se houver task pendente na fila.
# Como contar tasks pendentes depende do seu projeto (não há CLI oficial para a
# task list do Agent Teams). Exemplo: um arquivo de fila mantido pelo lead.
PENDING=$(grep -c '^- \[ \]' "$CLAUDE_PROJECT_DIR/docs/smart-memory/_session/queue.md" 2>/dev/null || echo 0)
if [ "${PENDING:-0}" -gt 0 ]; then
  echo "Há $PENDING task(s) pendente(s) na fila — faça self-claim da próxima compatível." >&2
  exit 2   # condicional: SÓ quando há trabalho real esperando
fi
exit 0     # fila vazia → idle é o estado correto; NUNCA exit 2 aqui
```
