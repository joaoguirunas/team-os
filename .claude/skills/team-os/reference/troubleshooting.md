# Troubleshooting — Limitações conhecidas

> Extraído do SKILL.md — carregar sob demanda. As seções citadas abaixo ("⛔ Lead Discipline", "Fase 2-C") estão no SKILL.md. As duas linhas de worktree também permanecem no SKILL.md por serem regra de garantia dura.

| Problema | Causa | Solução |
|---|---|---|
| Agentes criando branches extras | Lead usou `isolation: worktree` ao spawnar — proibido | NUNCA usar isolation: worktree. Agentes escrevem direto na branch ativa. Resolve conflito de arquivo com ownership disjunto (paths exclusivos por agente). |
| Worktrees aparecendo mesmo sem spawn manual | Background tasks com isolamento automático, ou settings sem a trava | Garantir no `.claude/settings.json` do projeto: `"worktree": { "bgIsolation": "none" }` + hook `block-worktree.sh` registrado em PreToolUse (Fase 2-C do SKILL.md). Limpar zumbis: `git worktree list` → `git worktree remove` + delete da branch (devops). |
| Resume não restaura teammates | Limitação: `/resume` não restaura in-process teammates | Re-spawnar com mesmo nome + contexto do smart-memory |
| Task travada (done mas não marca) | Bug known: task status pode atrasar | Verificar se work está feito → atualizar manualmente ou pedir ao lead |
| Agente sumiu do panel | Idle após 30s (hide automático, v2.1.181+) — NÃO parou, reaparece no próximo turno | SendMessage por nome: `"Mensagem para {nome}: continue"` |
| Lead começa a implementar sozinho | Violação da Lead Discipline | Ver seção "⛔ Lead Discipline" no SKILL.md — o lead NUNCA executa, só delega. `"Pare e spawna um agente para isso; você é o orquestrador"` |
| Muitos permission prompts | Teammates pedem aprovação para tudo | Pre-aprovar operações em settings ANTES de spawnar |
| Tmux sessions órfãs | Session não encerrou limpo | `tmux ls` → `tmux kill-session -t {nome}` |
| Agente em loop de erros | Sem recovery automático | Entrar na sessão (Enter no panel) e dar instrução direta ou spawnar replacement |
| Lead promovido antes da hora | Lead declarou "concluído" cedo | `"Continue — há tasks incompletas"` |
