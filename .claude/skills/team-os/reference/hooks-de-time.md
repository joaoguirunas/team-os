# Hooks de time

> Extraído do SKILL.md — carregar sob demanda.

Dois hooks de qualidade fazem parte do **settings padrão** de todo projeto team-os (registrados pelo `scripts/ensure-settings.sh` e pelo `*install`); o terceiro (`TeammateIdle`) é receita **opcional** por projeto.

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

`check-story-progress.sh` roda quando uma task é marcada como concluída e valida o progresso da story: **story só fecha com evidência** (commits/artefatos reais, ACs checados). Complementa a doutrina "Não confie no relato" do Lead OS — o hook barra o fechamento sem evidência antes mesmo de o lead verificar.

Registro (o `ensure-settings.sh` garante — não edite à mão):
```json
{
  "hooks": {
    "TaskCompleted": [{
      "matcher": "",
      "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-story-progress.sh" }]
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
PENDING=$(claude tasks list 2>/dev/null | grep -c 'pending' || true)
if [ "${PENDING:-0}" -gt 0 ]; then
  echo "Há $PENDING task(s) pendente(s) na fila — faça self-claim da próxima compatível." >&2
  exit 2   # condicional: SÓ quando há trabalho real esperando
fi
exit 0     # fila vazia → idle é o estado correto; NUNCA exit 2 aqui
```
