---
name: social-heygen-avatar
description: Geração de vídeo com avatar AI via HeyGen — talking-head, image-to-video, dublagem multilíngue e seleção de voz. Injectado em FLUX (social-video).
---

# Social HeyGen Avatar — Vídeo com Avatar AI

Camada de vídeo **gerativo** do FLUX (o ffmpeg continua sendo edição/corte/export).
HeyGen produz o que o ffmpeg não faz: apresentador falando, animação de imagem e dublagem.

## Transporte (detectar antes de gerar)

Ladder de detecção — **a primeira que existir vence**:

1. **MCP do plano** — tools `mcp__claude_ai_Hey_Gen__*` visíveis → usar direto.
   Consome créditos do **plano** HeyGen (OAuth, sem key). É o padrão.
2. **API key (fallback headless)** — se `HEYGEN_API_KEY` estiver setada e o MCP
   indisponível (contexto teammate/headless costuma não ter MCP interativo),
   usar o caminho CLI/API. Consome créditos de **API** (~6/min).

⚠️ Setar `HEYGEN_API_KEY` curto-circuita a detecção de MCP no pacote oficial —
no CT mantemos os dois: MCP como padrão interativo, key só como fallback.
Se o MCP sumir num run headless e não houver key, **pare e avise o lead**.

## Três modos de produção

| Modo | Tool | Quando |
|---|---|---|
| **Prompt → vídeo** | `create_video_agent` | Caminho recomendado. Texto descritivo vira vídeo completo. Modo `generate` para one-shot. |
| **Avatar + roteiro** | `create_video_from_avatar` | Controle explícito de `avatar_id` + `voice_id` + script do LYRIS. |
| **Animar imagem** | `create_video_from_image` | Dá vida a Key Visual (AEON) ou foto (IRIS) com script/áudio. |

> `create_video_agent` em `mode: "generate"` para one-shot. **Nunca** deixar em
> `chat` por engano — trava em `waiting_for_input`. Surface o link
> `https://app.heygen.com/video-agent/{session_id}` ao lead.

## Pipeline do produtor

1. **Descobrir assets** — `list_avatar_looks` / `list_voices` (filtrar por idioma/tom).
   Se a campanha tem avatar fixo, reusar o `avatar_id`/`voice_id` salvos na smart-memory.
2. **Roteiro** — usar o copy do LYRIS (`social-media/campaigns/{id}/copy/`). Texto
   curto: hook nos 3s, frases faladas curtas.
3. **Aspect ratio** — social = **9:16** (`portrait`). Pedir vertical na criação;
   se vier 16:9, FLUX corrige no ffmpeg (`scale=1080:1920...crop`).
4. **Gerar** — chamar a tool do modo escolhido.
5. **Polling** — `get_video_agent_session` (Video Agent) ou `get_video` até
   `status: completed`. Só então há `video_id`/URL de download.
6. **Pós** — baixar o `.mp4`, passar pelo FLUX (legendas `.srt` SEMPRE, música,
   compressão por plataforma) e arquivar em
   `social-media/campaigns/{id}/assets/videos/exports/`.
7. **Notificar VERA** para validação editorial antes de publicar.

## Voz

- `list_voices` → escolher por idioma + tom (PT-BR para conteúdo nacional).
- Manter consistência de voz por marca/campanha — registrar o `voice_id` na smart-memory.
- Para clonar voz da marca: `clone_voice` / `design_voice` (opt-in, requer consentimento).

## Avatar da marca/persona

- Reusar o avatar da campanha sempre que existir (consistência > novidade).
- Criar novo: `create_photo_avatar` (foto real, requer consentimento via
  `create_avatar_consent`) ou `create_prompt_avatar` (prompt, sem pessoa real).
- Salvar `avatar_id` + `voice_id` na smart-memory ao criar — é o source of truth
  para os próximos vídeos.

## Dublagem / multilíngue (heygen-translate)

- `list_video_translation_languages` → idiomas suportados.
- `create_video_translation` (vídeo + idioma alvo) → `get_video_translation` (polling).
- Use para reaproveitar 1 vídeo em vários mercados. **Sempre revisar** a tradução
  antes de publicar (nomes próprios, CTA, gíria).

## Custos e regras

- API: ~6 créditos/min de Avatar V. Plano (MCP): consome créditos do plano.
- **Smoke test** novo setup: 5s ("HeyGen install working") ≈ meio crédito.
- Sem créditos → avisar o lead e apontar `app.heygen.com/billing`. Nunca tentar em loop.
- Legenda `.srt` é obrigatória no output final (regra do FLUX) — gerar no pós-ffmpeg.
