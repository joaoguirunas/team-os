# Arquitetura de referência

> Extraído do SKILL.md — carregar sob demanda.


```
Você (team lead — sessão principal — esta skill roda aqui)
  │
  ├── Agent Panel (↑↓ para navegar, Enter para abrir)
  │     ├── archi     [working]  → src/auth/, docs/smart-memory/project/
  │     ├── alpha     [pending]  → src/frontend/ (aguarda archi)
  │     ├── qa        [working]  → review paralelo do módulo pago
  │     └── ops       [idle]     → aguarda todos para deploy
  │
  ├── TaskList compartilhada (nativa — Ctrl+T para ver)
  │     ├── [in-progress]  Mapear módulo auth         → archi
  │     ├── [pending]      Implementar login page      → alpha (bloqueada)
  │     ├── [in-progress]  Auditar módulo pagamento    → qa
  │     ├── [pending]      Deploy staging              → ops (bloqueada)
  │     └── [pending]      Criar stories de UX         → self-claim livre
  │
  └── docs/smart-memory/
        ├── INDEX.md                ← L0: todos leram ao iniciar
        ├── _inbox/                 ← notas rápidas da sessão (consolidadas no *compact)
        ├── stories/active/         ← archi e alpha escrevem
        ├── agents/dev/qa/          ← qa escreve findings (agents/<squad>/<área>/)
        │     └── DIGEST.md         ← porta de entrada da área (Core + Contexto recente)
        └── _archive/               ← frio (stories-done/, resolved/) — nunca lido no bootstrap
```
