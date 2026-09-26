# Controle do time durante a sessão

> Extraído do SKILL.md — carregar sob demanda. As **regras** (fix loop com cap, mensagens enxutas) continuam no SKILL.md; aqui ficam painel, keybindings, gestão de tasks, redirecionar, encerrar e escalar.


> **Agent panel ≠ Agent view — não confundir:**
> - **Agent panel** (esta seção) é o painel de **teammates** abaixo do prompt na sua sessão de lead. São os agentes do time que você spawnou; comunicam-se entre si peer-to-peer.
> - **Agent view** (`claude agents`) é uma tela separada que gerencia **sessões em background** independentes (cada prompt = nova sessão; Space=peek, Enter=attach). Teammates e subagents que uma sessão spawna **NÃO** aparecem como linhas no agent view. Você pode até carregar `/team-os` dentro de uma sessão dispatchada pelo agent view, mas os dois mecanismos são distintos.

> **🎯 Como ter o painel navegável (setas ↑↓) — leia se você usa `claude agents`:**
> O painel de teammates é da **sessão que rodou o `/team-os`**, não do agent view. No fluxo `claude agents`:
> 1. Dispache/abra uma sessão e **dê attach nela** (Enter/→ na linha dela). Você precisa estar **dentro** da sessão.
> 2. Rode `/team-os` aí dentro (com Agent Teams ativo — Gate 0). Os teammates aparecem no painel **dessa sessão**, navegáveis por ↑↓.
> 3. Se você sair (detach) para o agent view, o painel some — os teammates seguem vivos na sessão; reattach (Enter) para voltar a navegar.
>
> **Alternativa mais simples para orquestrar ao vivo:** abra `claude` (foreground) direto no projeto e rode `/team-os` — o painel navegável fica logo abaixo do prompt, sem precisar de attach. Use `claude agents` quando quiser tocar várias sessões em background; use `claude` foreground quando quiser pilotar o time de perto.

### Agent panel

Keybindings (verificado na v2.1.18x, 2026-09 — podem mudar em versões futuras):
```
In-process mode (padrão):
  ↑↓      → selecionar agente no panel
  Enter   → abrir sessão e enviar mensagem diretamente
  Esc     → interromper turno atual do agente
  x       → parar agente selecionado
  Ctrl+T  → toggle da task list

Split-pane mode (tmux/iTerm2):
  Click   → entrar na sessão do agente
  (não requer navegação por teclado)
```

### Gestão de tasks

Tasks têm 3 estados: `pending` → `in_progress` → `completed`

Tasks com dependências ficam bloqueadas até que as dependências sejam completadas — o sistema desbloqueia automaticamente.

**Self-claim:** Após completar uma task, o agente pega automaticamente a próxima task livre compatível com seu perfil. Isso significa que 5-6 tasks por agente mantém o pipeline fluindo sem intervenção do lead.

### Redirecionar um agente
Entre na sessão (Enter no panel) e dê instrução direta. O agente processa como mensagem prioritária.

### Encerrar graciosamente
```
"Peça ao agente {nome} para encerrar"
```
O agente termina o turno atual, confirma o encerramento e sai. Cleanup automático.

### Quando escalar agentes
Se o trabalho expande além do planejado:
```
"Spawn mais um agente {tipo} chamado {nome} para cobrir {escopo adicional}"
```
Adicione um agente por vez, conforme cada um acelerar de fato o trabalho paralelo real — não para "cobrir tudo de uma vez".
