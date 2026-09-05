---
name: social-editorial-validation
description: Validação editorial de conteúdo social — checklist de qualidade, alinhamento estratégico e compliance. Use ao revisar conteúdo antes de publicar, validar alinhamento com a estratégia da marca, checar compliance ou emitir aprovação editorial de posts e campanhas.
version: "1.0"
updated: "2026-09-04"
---

# Social Editorial Validation — Checklist VERA

> Skill injetada no agente VERA (social-strategist).

## Checklist completo de validação

### 1. Alinhamento estratégico
- [ ] Conteúdo serve o objectivo da campanha (awareness/engagement/conversão)
- [ ] Mensagem alinha com posicionamento da marca
- [ ] Tom de voz consistente com guidelines
- [ ] Público-alvo correcto para o conteúdo

### 2. Qualidade de copy
- [ ] Hook eficaz (para-scroll nos primeiros 3 segundos/linhas)
- [ ] Sem erros ortográficos ou gramaticais
- [ ] CTA claro e específico
- [ ] Hashtags relevantes e em número adequado (10-15)
- [ ] Emojis usados estrategicamente (não decorativamente)
- [ ] Comprimento adequado à plataforma

### 3. Qualidade visual
- [ ] Resolução adequada para a plataforma
- [ ] Identidade de marca presente e correta
- [ ] Contraste de texto legível (WCAG AA mínimo)
- [ ] Zona segura respeitada (elementos importantes fora das bordas)
- [ ] Consistência com KV da campanha

### 4. Compliance e risco
- [ ] Sem claims não substantiados ("o melhor", "o único")
- [ ] Sem comparações directas com concorrentes sem dados
- [ ] Direitos de imagem verificados
- [ ] Direitos musicais verificados (para vídeo)
- [ ] Sem conteúdo potencialmente ofensivo
- [ ] Políticas da plataforma respeitadas

### 5. Plataforma específica
- [ ] Formato correcto para a plataforma
- [ ] Specs técnicas verificadas
- [ ] Horário de publicação optimizado

## Veredictos possíveis

| Veredicto | Critério | Próximo passo |
|---|---|---|
| **APROVADO** | Todos os itens ok | → PULSE pode publicar (após confirmação usuário) |
| **APROVADO COM RESSALVAS** | Pequenos ajustes necessários | Ajustar e publicar sem nova validação |
| **REJEITADO** | Falhas críticas | Devolver ao agente responsável com feedback específico |

## Template de output VERA

```markdown
## Validação VERA — [Campanha] — [dd/mm/yyyy hh:mm]

**Veredicto:** [APROVADO | APROVADO COM RESSALVAS | REJEITADO]

**Copy:** [ok | problema: ...]
**Visual:** [ok | problema: ...]
**Estratégia:** [ok | problema: ...]
**Compliance:** [ok | problema: ...]

**Ações requeridas antes de publicar:**
1. [se houver]

**Aprovado por:** VERA — [timestamp]
```

## Critérios de rejeição automática
- Erros ortográficos não corrigidos
- Imagem sem direitos verificados
- Claim não substantiado
- Fora dos specs técnicos da plataforma
- Tom completamente inconsistente com a marca
