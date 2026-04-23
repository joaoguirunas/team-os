---
name: social-video-editing
description: Edição de vídeo para redes sociais com ffmpeg — cortes, legendas, música, transições e exportação. Injectado em FLUX (social-video).
---

# Social Video Editing — ffmpeg Essencial

## Comandos ffmpeg mais usados

### Conversão de formato e aspect ratio
```bash
# 16:9 para 9:16 (horizontal para vertical)
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1" \
  -c:a copy output_9x16.mp4

# Crop central para 1:1
ffmpeg -i input.mp4 \
  -vf "crop=ih:ih,scale=1080:1080" \
  output_1x1.mp4
```

### Corte de clips
```bash
# Cortar de 10s a 40s
ffmpeg -ss 00:00:10 -to 00:00:40 -i input.mp4 -c copy output_clip.mp4

# Cortar primeiros 30s
ffmpeg -i input.mp4 -t 30 -c copy output_30s.mp4
```

### Adicionar legendas
```bash
# Com ficheiro .srt
ffmpeg -i input.mp4 \
  -vf "subtitles=legendas.srt:force_style='FontSize=28,FontName=Arial Bold,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=2,Alignment=2'" \
  output_com_legendas.mp4
```

### Adicionar música de fundo
```bash
# Mix de vídeo + música (música a 30% de volume)
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex "[1:a]volume=0.3[music];[0:a][music]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" \
  output_com_musica.mp4
```

### Comprimir para redes sociais
```bash
# Instagram Reel (máx 100MB)
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 23 -preset medium \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  output_instagram.mp4

# TikTok (máx 287.6MB)
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 20 -preset slow \
  -c:a aac -b:a 192k \
  output_tiktok.mp4
```

### Concatenar clips
```bash
# Criar lista de clips
echo "file 'clip1.mp4'
file 'clip2.mp4'
file 'clip3.mp4'" > lista.txt

ffmpeg -f concat -safe 0 -i lista.txt -c copy output_final.mp4
```

### Adicionar fade in/out
```bash
# Fade in 0.5s no início, fade out 0.5s no fim (vídeo de 30s)
ffmpeg -i input.mp4 \
  -vf "fade=in:0:12,fade=out:708:12" \
  output_fade.mp4
```

## Especificações por plataforma

| Plataforma | Resolução | FPS | Codec | Máx |
|---|---|---|---|---|
| Instagram Reel | 1080x1920 | 30 | H.264 | 100MB |
| TikTok | 1080x1920 | 30 | H.264 | 287.6MB |
| YouTube Shorts | 1080x1920 | 30/60 | H.264 | 256GB |
| Facebook | 1080x1920 | 30 | H.264 | 4GB |
