---
name: social-stitch-workflow
description: Workflow de design com Google Stitch MCP — geração de assets, iteração e exportação para redes sociais. Injectado em AEON (social-design).
---

# Social Stitch Workflow — Google Stitch MCP

## Quando usar Stitch

- Criação de Key Visuals de campanha
- Geração de templates de posts
- Iteração rápida de variações de design
- Criação de sistemas de design visual para social media

## Workflow padrão com Stitch (tool calls reais)

### Fase 1: Setup do projecto
```
# 1. Listar projetos existentes
mcp__stitch__list_projects()

# 2. Criar projeto novo para a campanha
mcp__stitch__create_project({
  name: "campanha-{id}",
  description: "Campaign visual assets"
})

# 3. Criar design system da marca
mcp__stitch__create_design_system({
  project_id: "{project_id}",
  name: "brand-{cliente}",
  primary_color: "#hex",
  secondary_color: "#hex",
  font_family: "Inter",
  style: "modern"  # modern | playful | editorial | minimal
})

# 4. Aplicar design system ao projeto
mcp__stitch__apply_design_system({
  project_id: "{project_id}",
  design_system_id: "{ds_id}"
})
```

### Fase 2: Geração do KV
```
# Gerar primeiro conceito via prompt descritivo
mcp__stitch__generate_screen_from_text({
  project_id: "{project_id}",
  prompt: "[estilo], [composição], [paleta], [tipografia], [mood], [formato]",
  screen_name: "kv-main-v1"
})

# Gerar variações A/B
mcp__stitch__generate_variants({
  project_id: "{project_id}",
  screen_id: "{screen_id}",
  count: 3
})

# Ver resultado
mcp__stitch__get_screen({
  project_id: "{project_id}",
  screen_id: "{screen_id}"
})
```

### Fase 3: Derivações e ajustes
```
# Editar screen aprovada
mcp__stitch__edit_screens({
  project_id: "{project_id}",
  screen_ids: ["{screen_id}"],
  instructions: "Adaptar para formato 9:16, manter hierarquia visual"
})

# Listar todos os screens do projeto
mcp__stitch__list_screens({ project_id: "{project_id}" })
```

## Prompts eficazes para Stitch

**Estrutura de prompt:**
```
[Estilo visual], [sujeito/composição], [paleta de cores], 
[tipografia sugerida], [mood], [formato], [elementos de marca]
```

**Exemplo:**
```
Modern editorial social media post, product centered on minimal background, 
brand colors #1a1a2e and #e94560, bold sans-serif typography, 
confident and premium mood, 1:1 format, logo bottom right corner
```

## Output de entrega

Organizar sempre em:
```
assets/design/
├── kv/
│   ├── kv_main_v1.png
│   └── kv_dark_v1.png
├── feed/
│   ├── feed_1x1_v1.png
│   └── feed_4x5_v1.png
└── story/
    └── story_9x16_v1.png
```
