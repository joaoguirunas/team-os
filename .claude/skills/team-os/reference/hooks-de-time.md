# Hooks de qualidade (opcionais por projeto)

> Extraído do SKILL.md — carregar sob demanda.

Configure em `.claude/settings.json` do projeto para enforçar padrões automaticamente:

## TeammateIdle — opcional, e CUIDADO com loop

> **Atenção:** ficar ocioso é o estado **desejado** (teammate vivo, esperando mais task). O que resolve o encerramento precoce é a **regra Team Persistence** (no SKILL.md), não este hook. Use o hook só se quiser que teammates puxem tasks pendentes em vez de ociar — e **nunca** com `exit 2` incondicional (isso gera loop infinito: o teammate nunca consegue parar).

Versão **segura** (só nudge informativo, `exit 0` — não bloqueia o idle):
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
Para "manter trabalhando", o comando só deve sair com `exit 2` **se houver task pendente compatível na fila** — caso contrário `exit 0`. Um `exit 2` fixo trava o teammate em loop. Não é auto-instalado nos projetos por padrão.

## TaskCompleted — Gate de qualidade
```json
{
  "hooks": {
    "TaskCompleted": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Task concluída. Valide o entregável antes de prosseguir.'"
      }]
    }]
  }
}
```
