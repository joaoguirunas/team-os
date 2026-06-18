# Squad Monitor

Dashboard local realtime para agentes Claude Code.

## Setup

```bash
cd squad-monitor
npm install
npm start
```

Abrir http://localhost:3099

## Configurar hooks

Cole o conteudo de `hooks/settings.snippet.json` dentro de `"hooks"` no seu `~/.claude/settings.json` (ou `.claude/settings.json` do projeto).

## O que aparece

- **Sessoes**: cada instancia do Claude Code rodando
- **Agentes**: subagents com estado (running/done/error), tempo decorrido, tool atual
- **Timeline**: sequencia de tool calls por agente
- **Detalhe**: clique num agente para ver prompt inicial, tokens e tool calls completos

## Arquitetura

Event store em memoria + JSONL append-only em `.runs/`. Sem banco. SSE unidirecional. Node 20+.
