# Protocolo de ativação do Agent Team

> Atualizado para v2.1.178+: `TeamCreate` e `TeamDelete` foram removidos da API. O time é criado automaticamente quando o primeiro `Agent()` é executado. `team_name` no `Agent()` é aceito mas ignorado — o nome real é derivado do session ID (`session-{primeiros8chars}`).

## Protocolo explícito (sempre usar este)

### Passo 0 — Carregar ferramentas deferidas (OBRIGATÓRIO)

`SendMessage` e task tools são deferidas — sem esse passo falham com `InputValidationError`:

```
ToolSearch({ query: "select:SendMessage,TaskCreate,TaskUpdate,TaskList,TaskGet,TaskOutput,TaskStop" })
```

### Passo 1 — Spawn de cada teammate via Agent()

Para cada teammate na composição do time, uma chamada (em paralelo):

```
Agent({
  subagent_type: "<nome-do-agente>",
  name: "<nome-do-agente>",
  run_in_background: true,
  prompt: "<instruções iniciais: task, arquivos a ler/escrever, como avisar o lead ao concluir>"
})
```

Parâmetros:
- `subagent_type` — referência ao `.claude/agents/<nome>.md`
- `name` — nome de endereçamento para `SendMessage` (normalmente igual ao `subagent_type`)
- `run_in_background: true` — executa em paralelo sem bloquear o lead
- `prompt` — missão inicial do teammate, incluindo contexto de smart-memory e obrigação de notificar via `SendMessage` ao terminar

O time é criado automaticamente com o primeiro spawn. Não há passo separado de criação.

### Passo 2 — Criar tasks (após os spawns)

```
TaskCreate({ title: "<titulo>", description: "<desc>", assignee: "<teammate>" })
```

TaskList é vinculada à sessão atual. Criar APÓS os spawns.

### Passo 3 — Coordenação contínua

- `SendMessage({ to: "<teammate-name>", message: "..." })` — direcionar
- `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet` — operam na TaskList da sessão
- Teammates avisam automaticamente via `SendMessage` ao concluir — chega como novo turno, sem polling

### Passo 4 — Encerramento

Não há `TeamDelete`. O time e seus diretórios em `~/.claude/teams/` são limpos automaticamente quando a sessão termina. O lead apenas:
1. Atualiza `docs/smart-memory/shared-context.md` com resultados finais
2. Registra encerramento em `ops/teams-log.md`

---

## Monitorar o time (Agent Panel)

Após o spawn, teammates aparecem no agent panel abaixo do prompt input:

| Tecla | Ação |
|-------|------|
| `↑` / `↓` | Selecionar teammate |
| `Enter` | Abrir sessão do teammate e enviar mensagem diretamente |
| `Escape` | Interromper o turn atual do teammate selecionado |
| `x` | Parar o teammate selecionado |
| `Ctrl+T` | Toggle da task list |

Após 30s em idle, a linha do teammate desaparece — ele continua ativo. Envie uma mensagem para reaparecer.

---

## Observações importantes

### Sobre TaskList
TaskList é vinculada à sessão, não ao time. Tasks criadas antes ou depois dos spawns ficam na mesma lista. Teammates podem auto-criar suas próprias tasks via `TaskCreate`.

### Sobre persistência entre sessões
`/resume` e `/rewind` NÃO restauram in-process teammates. Cada sessão começa com teammates zerados. O `*resume` do team-os sempre respawna os teammates — esse é o comportamento correto, não um workaround.

### Sobre SendMessage antes de spawn
Se chamar `SendMessage({to: "X"})` antes de `Agent()` ter spawnado o teammate X, retorna erro. Fluxo correto: spawn via `Agent()` → depois `SendMessage`.

### Sobre `Agent()` sem `team_name`
Desde v2.1.178+, `Agent()` sem `team_name` cria um teammate automaticamente (não um subagent isolado), desde que `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` esteja ativo. `team_name` pode ser passado mas é ignorado.
