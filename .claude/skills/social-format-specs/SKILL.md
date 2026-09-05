---
name: social-format-specs
description: Especificações técnicas de formatos para todas as plataformas sociais — dimensões, duração, tamanho de arquivo, codecs e zonas seguras. Use ao exportar ou validar vídeo/foto para Instagram, TikTok, YouTube Shorts, Facebook ou LinkedIn antes de publicar.
version: "1.0"
updated: "2026-09-04"
---

# Social Format Specs — Especificações por Plataforma

Usada por FLUX (social-video).

> **Specs verificadas em 2026-09; se `updated` > 6 meses, confirmar nas docs oficiais antes de bloquear entrega.**

## Instagram

### Feed (Foto/Vídeo)
| Formato | Dimensões | Aspect Ratio | Máx arquivo |
|---|---|---|---|
| Quadrado | 1080x1080 | 1:1 | 30MB (foto) |
| Portrait | 1080x1350 | 4:5 | 30MB (foto) |
| Landscape | 1080x566 | 1.91:1 | 30MB (foto) |

**Vídeo feed:** até 60 min (recomendado <90s para engajamento), H.264, 30fps, AAC

### Reels
| Dimensões | Aspect Ratio | Duração | Recomendado |
|---|---|---|---|
| 1080x1920 | 9:16 | até 3 min | 15-90s para alcance |

**Codec:** H.264, 30fps, AAC 128kbps

### Stories
- **Dimensões:** 1080x1920 (9:16)
- **Duração:** 60s por card (foto: 7s automático)
- **Zona segura:** 250px top e bottom (UI da plataforma)

## TikTok

| Dimensões | Aspect Ratio | Duração | Máx arquivo |
|---|---|---|---|
| 1080x1920 | 9:16 | 15s - 10min | 287.6MB |
| 1080x1080 | 1:1 | 15s - 10min | 287.6MB |

**Codec:** H.264/H.265, 30fps mínimo (60fps recomendado), AAC

## YouTube Shorts

| Dimensões | Aspect Ratio | Duração |
|---|---|---|
| 1080x1920 | 9:16 | até 3 min |

**Codec:** H.264, 30-60fps, AAC 128kbps+

## Facebook

### Feed
- **Foto:** 1200x630 (link) ou 1080x1080 (post)
- **Vídeo:** 1280x720 mínimo, 30fps, máx 240min, 4GB

### Stories
- **Dimensões:** 1080x1920 (9:16)
- **Duração:** 20s foto, 60s vídeo

## LinkedIn

### Feed
- **Foto:** 1200x627 (artigo) ou 1080x1080 (post)
- **Vídeo:** 1920x1080 ou 1080x1080, máx 10min, 5GB

### Documento (Carousel)
- **Formato:** PDF, até 300 slides
- **Dimensões:** 1080x1080 ou 1080x1350 por slide

## Checklist de exportação

```
[ ] Resolução correta para plataforma
[ ] Aspect ratio verificado
[ ] Arquivo dentro do limite de tamanho
[ ] Codec compatível (H.264 padrão)
[ ] Frame rate adequado (30fps mínimo)
[ ] Áudio: AAC, sem clipping
[ ] Legendas incluídas (.srt ou burned-in)
```
