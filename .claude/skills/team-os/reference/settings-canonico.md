# Settings.json canônico

> Extraído do SKILL.md — carregar sob demanda.

Configuração completa recomendada para Agent Teams:

**`~/.claude/settings.json`** (global — afeta todos os projetos):
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "teammateMode": "auto",
  "model": "sonnet"
}
```

**`.claude/settings.json`** (por projeto — hooks de qualidade):
```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Verifique se há tasks pendentes antes de encerrar.'"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Task marcada como concluída. Validar entregável antes de prosseguir.'"
          }
        ]
      }
    ]
  }
}
```

**`teammateMode` — opções:**
| Valor | Comportamento |
|---|---|
| `"in-process"` | Todos no terminal principal, agent panel ativo. **Default desde v2.1.179** |
| `"auto"` | Split panes se já estiver em sessão tmux ou terminal for iTerm2; in-process caso contrário (recomendado pela skill) |
| `"tmux"` | Forçar split panes — auto-detecta tmux vs iTerm2 (requer tmux ou iTerm2 com it2 CLI) |

> O default mudou para `"in-process"` na v2.1.179 — sessões atualizadas que antes abriam split panes agora ficam num terminal só, a menos que você defina `"auto"`/`"tmux"` explicitamente. Split-pane não funciona no terminal integrado do VS Code, Windows Terminal nem Ghostty.

Flag por sessão: `claude --teammate-mode auto`
