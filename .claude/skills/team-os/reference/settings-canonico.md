# Settings.json canônico

> Extraído do SKILL.md — carregar sob demanda. O `.claude/settings.json` do projeto é **garantido pelo `scripts/ensure-settings.sh`** (Fase 2-C; o `*install` também o chama) — nunca edite à mão. O script só adiciona o que falta, nunca sobrescreve valor existente (divergência vira aviso) e valida o JSON final.

## `.claude/settings.json` (por projeto — o que o `ensure-settings.sh` garante)

```json
{
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
  "worktree": { "bgIsolation": "none" },
  "subagentPromptCacheTtl": "1h",
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent|Task|EnterWorktree",
        "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-worktree.sh" }] },
      { "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-worktree.sh" }] }
    ],
    "TaskCreated": [
      { "matcher": "",
        "hooks": [{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/task-quality.sh" }] }
    ],
    "TaskCompleted": [
      { "matcher": "",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-story-progress.sh" },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-social-progress.sh" },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-proposal-progress.sh" },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-finance-progress.sh" },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-legal-progress.sh" }
        ] }
    ]
  }
}
```

- `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"` — só vale para sessões iniciadas depois (Gate 0 checa o runtime).
- `worktree.bgIsolation = "none"` + `block-worktree.sh` em dois matchers — trava anti-worktree (regra dura).
- `subagentPromptCacheTtl = "1h"` — cache de prompt dos teammates.
- Hooks de time: `TaskCreated` (task vaga) e os 5 gates de `TaskCompleted` — ver `reference/hooks-de-time.md`. `TeammateIdle` **não** é instalado por padrão.
- Os scripts referenciados precisam existir em `.claude/hooks/` do projeto — o `ensure-settings.sh` avisa se faltarem (`/team-os-creator *propagate` no CT os distribui).

## `~/.claude/settings.json` (global — sugerido, não gerenciado pelo script)

```json
{
  "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
  "teammateMode": "auto"
}
```

O `*install` também instala o hook global `SessionStart` (`~/.claude/hooks/team-os-session-title.sh`) — ver `reference/session-naming.md`. Não fixe `model` no settings global por causa do team-os: a política de modelos é **por agente** (`model:` no arquivo — Híbrido).

**`teammateMode` — opções:**
| Valor | Comportamento |
|---|---|
| `"in-process"` | Todos no terminal principal, agent panel ativo. **Default desde v2.1.179** |
| `"auto"` | Split panes se já estiver em sessão tmux ou terminal for iTerm2; in-process caso contrário (recomendado pela skill) |
| `"tmux"` | Forçar split panes — auto-detecta tmux vs iTerm2 (requer tmux ou iTerm2 com it2 CLI) |

> O default mudou para `"in-process"` na v2.1.179 — sessões atualizadas que antes abriam split panes agora ficam num terminal só, a menos que você defina `"auto"`/`"tmux"` explicitamente. Split-pane não funciona no terminal integrado do VS Code, Windows Terminal nem Ghostty.

Flag por sessão: `claude --teammate-mode auto`
