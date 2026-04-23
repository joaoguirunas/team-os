---
name: social-format-specs
description: Especificações técnicas de formatos para todas as plataformas sociais — dimensões, duração, tamanho de ficheiro e requisitos. Injectado em FLUX (social-video).
---

# Social Format Specs — Especificações por Plataforma

## Instagram

### Feed (Foto/Vídeo)
| Formato | Dimensões | Aspect Ratio | Máx ficheiro |
|---|---|---|---|
| Quadrado | 1080x1080 | 1:1 | 30MB (foto), 100MB (vídeo) |
| Portrait | 1080x1350 | 4:5 | 30MB (foto), 100MB (vídeo) |
| Landscape | 1080x566 | 1.91:1 | 30MB (foto), 100MB (vídeo) |

**Vídeo feed:** 60s máx, H.264, 30fps, 5.500kbps máx

### Reels
| Dimensões | Aspect Ratio | Duração | Máx ficheiro |
|---|---|---|---|
| 1080x1920 | 9:16 | 15s - 90s | 100MB |

**Codec:** H.264, 30fps, AAC 128kbps

### Stories
- **Dimensões:** 1080x1920 (9:16)
- **Duração:** 15s por clip (foto: 7s automático)
- **Zona segura:** 250px top e bottom (UI da plataforma)

## TikTok

| Dimensões | Aspect Ratio | Duração | Máx ficheiro |
|---|---|---|---|
| 1080x1920 | 9:16 | 15s - 10min | 287.6MB |
| 1080x1080 | 1:1 | 15s - 10min | 287.6MB |

**Codec:** H.264/H.265, 30fps mínimo (60fps recomendado), AAC

## YouTube Shorts

| Dimensões | Aspect Ratio | Duração | Máx ficheiro |
|---|---|---|---|
| 1080x1920 | 9:16 | Até 60s | 256GB |

**Codec:** H.264, 30-60fps, AAC 128kbps+

## Facebook

### Feed
- **Foto:** 1200x630 (link) ou 1080x1080 (post)
- **Vídeo:** 1280x720 mínimo, 30fps, max 240min, 4GB

### Stories
- **Dimensões:** 1080x1920 (9:16)
- **Duração:** 20s foto, 60s vídeo

## LinkedIn

### Feed
- **Foto:** 1200x627 (artigo) ou 1080x1080 (post)
- **Vídeo:** 1920x1080 ou 1080x1080, max 10min, 5GB

### Documento (Carousel)
- **Formato:** PDF, até 300 slides
- **Dimensões:** 1080x1080 ou 1080x1350 por slide

## Checklist de exportação

```
[ ] Resolução correcta para plataforma
[ ] Aspect ratio verificado
[ ] Ficheiro dentro do limite de tamanho
[ ] Codec compatível (H.264 padrão)
[ ] Frame rate adequado (30fps mínimo)
[ ] Áudio: AAC, sem clipping
[ ] Legendas incluídas (.srt ou burned-in)
```
