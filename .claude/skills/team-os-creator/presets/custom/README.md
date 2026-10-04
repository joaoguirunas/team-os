# presets/custom — seus agentes

Esta pasta é **sua**. O `/team-os-creator *update` nunca mexe nela, e ela não faz parte do `pack-manifest.json`.

- Quando você cria um agente com `/team-os-creator *create`, ele ganha `origin: custom` no frontmatter e é registrado aqui, em `custom.yaml`.
- O nome do agente é livre. A squad é o começo do nome, antes do primeiro hífen (ex.: `acme-writer` → squad `acme`).
- O `*audit` (`validate-agent.sh`) confere seus agentes com as mesmas regras do pack e conta à parte: "N do pack + M próprios".
- Pode ter mais de um arquivo `.yaml` aqui. Todos são lidos.

Formato de cada entrada (o mesmo dos presets do pack):

```yaml
name: custom
description: "Agentes próprios"
agents:
  - name: acme-writer
    archetype: implementer
    persona: Ana
    role_title: "Content Writer"
    color: green
    description: "Escreve os textos da Acme. Use para redigir posts."
```
