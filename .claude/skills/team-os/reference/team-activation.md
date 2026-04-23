# Protocolo de ativação do Agent Team

> Atualizado após teste real: linguagem natural sozinha NÃO ativa team mode de forma confiável. Use o protocolo explícito abaixo — é o mecanismo oficial da tool `TeamCreate`.

## Protocolo explícito (sempre usar este)

### Passo 1 — TeamCreate

```
TeamCreate({
  team_name: "{folder}-{objective-slug}"
})
```

Onde:
- `{folder}` = `basename "$PWD"` (nome da pasta do projeto atual)
- `{objective-slug}` = slug kebab-case do objetivo (máx 4 palavras, sem stopwords)

Exemplos válidos:
- `rev-os-discovery`
- `team-os-auth-refactor`
- `my-app-payment-integration`

**Nunca usar** nomes genéricos sem prefixo de pasta (ex: `discovery-20260422`) — causa colisão em `~/.claude/teams/` quando múltiplos projetos rodam a skill.

### Passo 2 — Spawn de cada teammate via Agent()

Para cada teammate na composição do time, uma chamada (em paralelo):

```
Agent({
  subagent_type: "<nome-do-agente>",
  team_name: "<mesmo-team_name-do-passo-1>",
  name: "<nome-do-agente>",
  prompt: "<instruções iniciais: task, arquivos a ler/escrever, como avisar o lead ao concluir>"
})
```

Parâmetros:
- `subagent_type` — referência ao `.claude/agents/<nome>.md` (usa o name: do frontmatter do agent)
- `team_name` — idêntico ao usado no TeamCreate (liga o spawn ao team)
- `name` — nome de endereçamento pra SendMessage (normalmente igual ao subagent_type)
- `prompt` — missão inicial do teammate, incluindo contexto de smart-memory e obrigação de notificar via SendMessage ao terminar

Após essa chamada:
- Teammate aparece no painel Shift+Tab do usuário
- Fica addressable via `SendMessage({ to: "<name>" })`
- Começa a trabalhar em paralelo imediatamente

### Passo 3 — Coordenação contínua

- `SendMessage({ to: "<teammate-name>", message: "..." })` — direcionar
- `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet` — operam na TaskList do team (1:1 entre team e TaskList)
- Teammates avisam automaticamente via SendMessage ao concluir — chega como novo turno, sem precisar de polling

### Passo 4 — Cleanup ao encerrar

```
TeamDelete({ team_name: "<team_name>" })
```

Antes disso, garantir que:
- Não há teammates ainda ativos (eles morrem naturalmente ao concluir tasks)
- Smart-memory foi atualizada com resultados finais
- `ops/teams-log.md` registra o encerramento com status e entregáveis

---

## Observações importantes

### Sobre TaskList
TaskList é 1:1 com team. Se você chamar `TaskCreate` ANTES do `TeamCreate`, as tasks vão pra TaskList default e somem quando o team é criado. **Ordem correta:**
1. TeamCreate
2. Agent() × N
3. (opcional) TaskCreate pra formalizar — mas teammates geralmente auto-criam as próprias

### Sobre persistência entre sessões
Indocumentado no spec oficial. Na prática, os arquivos em `~/.claude/teams/{team}/` persistem mas os processos dos teammates são da sessão atual. Ao retomar em nova sessão, pode ser necessário re-spawnar via Agent() com o mesmo team_name.

### Sobre SendMessage antes de spawn
Se chamar `SendMessage({to: "X"})` antes de `Agent()` ter spawnado o teammate X, retorna:
```
No agent named 'X' is currently addressable. Spawn a new one or use the agent ID.
```
**Fluxo correto:** TeamCreate → Agent() × N → SendMessage funciona.

### Sobre o erro comum "NUNCA usar Agent()"
Antiga instrução errada que causou confusão. **A regra correta é:**
- `Agent()` sem `team_name` → spawna subagent isolado, proibido nesse contexto
- `Agent()` com `team_name` → mecanismo oficial de spawn de teammate, obrigatório após TeamCreate
