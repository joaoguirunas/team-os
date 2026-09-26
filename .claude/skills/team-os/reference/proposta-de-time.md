# Fase 5 — formato da proposta de time

> Extraído do SKILL.md — carregar sob demanda ao montar a proposta. Ajustar ao contexto real.


```
🧑‍💻 Time proposto para: "{objetivo resumido}"
   {N} agentes  ·  {N} tasks  ·  paralelo máximo: {N} simultâneos

─────────────────────────────────────────────────────────────
① {agente-type}  →  nome: "{nome-curto}"
   Ownership: {paths exclusivos deste agente}
   Skills: {/skill-a}, {/skill-b}  (disponíveis via /nome-da-skill)
   Plan mode: {SIM/NÃO} — {razão se SIM}
   Missão: "{spawn prompt — específico, com paths, entregável claro}"

② {agente-type}  →  nome: "{nome-curto}"
   Ownership: {paths exclusivos}
   ...

③ (após ① completar) {agente-type}  →  nome: "{nome-curto}"
   ...
─────────────────────────────────────────────────────────────
📋 Tasks:
   ① → [ ] {task 1} (owner: {nome})
   ① → [ ] {task 2} (owner: {nome})
   ②∥③ → [ ] {task 3} (self-claim)
   depende de ① → [ ] {task 4}

📊 Modelo sugerido: Sonnet (padrão) | Haiku para pesquisa pura (mais barato)
🎚 Effort sugerido: architect/QA → high · implementers → médio (default) · pesquisa rápida → low
⚡ Paralelismo: {N} agentes simultâneos na fase inicial

[s] Spawnar  [a] Ajustar composição  [+] Mais agentes  [p] Plan mode em todos  [n] Cancelar
```
