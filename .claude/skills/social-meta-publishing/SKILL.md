---
name: social-meta-publishing
description: Publicação via Meta MCP — Instagram e Facebook. Workflow de upload, agendamento e verificação. Injectado em PULSE (social-publisher).
---

# Social Meta Publishing — Workflow de Publicação

## Regra de dupla confirmação (CRÍTICO)

```
PULSE NUNCA publica sem:
  1. Aprovação formal de VERA (com timestamp)
  AND
  2. Confirmação explícita do utilizador nesta sessão
```

**Script de confirmação obrigatório:**
```
"Vou publicar [descrição do conteúdo] em [plataforma].

Confirmações:
✅ VERA aprovou em [data/hora]
✅ Assets validados e dentro dos specs

Confirmas a publicação? (sim / não / agendar para [data])"
```

## Workflow de publicação via Meta MCP

### Fase 1: Preparação
1. Verificar aprovação VERA no ficheiro de validação
2. Solicitar confirmação do utilizador
3. Verificar ficheiros de assets em `social-media/campaigns/{id}/assets/`
4. Confirmar specs técnicas (tamanho, formato, duração)

### Fase 2: Upload
1. Carregar assets para Meta MCP
2. Verificar upload bem-sucedido
3. Adicionar copy (legenda, hashtags)
4. Configurar localização (se aplicável)

### Fase 3: Publicação/Agendamento
```
Opção A — Publicar imediatamente
Opção B — Agendar para data/hora específica
Opção C — Guardar como rascunho
```

### Fase 4: Verificação
1. Confirmar publicação bem-sucedida
2. Verificar post no feed
3. Registar em `social-media/campaigns/{id}/published/`
4. Notificar SIRIA com URL do post

## Horários óptimos por plataforma

| Plataforma | Melhores dias | Melhores horas |
|---|---|---|
| Instagram | Ter, Qua, Sex | 9h-11h ou 19h-21h |
| Facebook | Qui, Sex, Sab | 13h-16h |
| TikTok | Seg-Sex | 7h-9h ou 19h-23h |
| LinkedIn | Ter, Qua, Qui | 8h-10h ou 12h |

*Ajustar com base em analytics históricos da conta específica*

## Registo de publicações

```markdown
## Publicação — [Campaign ID]

**Data/hora:** [timestamp]
**Plataforma:** ...
**Formato:** ...
**URL do post:** ...
**Aprovação VERA:** [timestamp]
**Confirmação utilizador:** [timestamp]
**Assets publicados:** ...
```
