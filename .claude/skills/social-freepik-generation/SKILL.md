---
name: social-freepik-generation
description: Geração de imagens AI via Freepik para conteúdo social — prompts eficazes, estilos fotográficos e especificações por formato. Injectado em IRIS (social-photo).
---

# Social Freepik Generation — Geração de Imagens AI

## Estrutura de prompt eficaz

```
[Sujeito] + [Acção/Estado] + [Contexto/Cenário] + [Iluminação] + 
[Estilo fotográfico] + [Especificações técnicas] + [Mood] + [Ratio]
```

**Exemplo completo:**
```
Young professional woman smiling confidently, holding laptop, 
modern minimalist office with plants, soft natural window light from left, 
editorial lifestyle photography, 85mm f/1.8 portrait lens, 
warm neutral tones, genuine and approachable mood, 4:5 ratio, 
photorealistic, high resolution
```

## Estilos fotográficos disponíveis

| Estilo | Descrição | Quando usar |
|---|---|---|
| Editorial | Clean, composed, magazine-quality | Moda, lifestyle premium |
| Documentary | Raw, authentic, candid | Autenticidade, B2B |
| Commercial | Bright, optimistic, polished | Produto, SaaS |
| Cinematic | High contrast, film-like, moody | Storytelling, luxury |
| Flat lay | Top-down, styled, arranged | Produto, food, lifestyle |
| Street | Urban, spontaneous, real | Casual, youth |

## Negative prompts essenciais

```
deformed hands, extra fingers, blurry, low quality, watermark, 
text overlay, distorted face, artificial looking, uncanny valley, 
oversaturated, HDR, pixelated, grainy
```

## Lighting presets

- `soft morning window light` — natural, warm, flattering
- `golden hour backlight` — cinematic, warm glow
- `studio soft box` — clean, commercial
- `overcast diffused light` — even, no harsh shadows
- `neon accent lights` — urban, contemporary
- `candlelight/warm artificial` — intimate, cozy

## Especificações por formato social

| Formato | Ratio no prompt | Pixels |
|---|---|---|
| Feed 1:1 | `square format` | 1080x1080 |
| Feed 4:5 | `portrait 4:5 format` | 1080x1350 |
| Story | `vertical 9:16 format` | 1080x1920 |
| LinkedIn | `horizontal 1.91:1` | 1200x627 |

## Regras de composição

- Incluir "leading room" para texto overlay
- "Rule of thirds — subject in left third" para copy à direita
- "Negative space on right side" para texto horizontal
- "Upper third clear for title text" para carousels
