# Nomeação automática da sessão (SessionStart hook)

> Extraído do SKILL.md — carregar sob demanda.

**Problema que resolve:** sem isso, toda sessão `/team-os` fica com nome genérico ("team-os bootstrap gate", "team-os social media session"…) — no agent view e no `/resume` você não distingue qual projeto é nem o que estava fazendo.

**Mecanismo (único robusto):** um hook `SessionStart` que emite `hookSpecificOutput.sessionTitle` — mesmo efeito do `/rename`, aplicado em `startup` e `resume`. É o **único** caminho com API oficial:
- A skill **não** consegue digitar `/rename` em si mesma (slash command é input do usuário).
- Escrever a entrada `agent-name` direto no `.jsonl` é frágil (o app regrava o nome em memória a cada turno).
- `UserPromptSubmit` **não** suporta `sessionTitle` (só `SessionStart`) — por isso "atualizar na primeira tarefa" automático não tem API; usa-se o `/rename` pronto da Fase 6 (ver SKILL.md).

**Convenção de nome:** `{nome-da-pasta-do-projeto} · {branch}` (a branch só aparece quando há git não-detached). Ex.: `projeto-a · main`. Preserva rename deliberado do usuário; migra títulos antigos `team-os …`.

**Registro (global — `~/.claude/settings.json`):** vale para todos os projetos de uma vez.
```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash \"$HOME/.claude/hooks/team-os-session-title.sh\"" }
      ] }
    ]
  }
}
```
O script `team-os-session-title.sh` acompanha o pack (`.claude/hooks/`). O `*install` do `team-os-creator` instala o hook em `~/.claude/hooks/` e registra o `SessionStart` global automaticamente. **Vale só em sessões iniciadas DEPOIS do registro** (a sessão atual não é renomeada — igual à flag `AGENT_TEAMS`).
