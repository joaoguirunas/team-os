---
name: machine-resources
description: "Mede a máquina do usuário (memória livre, núcleos, swap, disco) antes de processo local pesado e decide quantos jobs cabem ao mesmo tempo sem travar o computador — transcrição (Whisper), modelo de IA local, render de vídeo, build grande, testes com navegador, lote de arquivos. Use ANTES de rodar qualquer coisa pesada ou várias cópias em paralelo."
version: "1.0"
updated: "2026-11-16"
---

# Machine Resources — não trave o computador do usuário

O computador é do usuário e ele está usando enquanto você trabalha. Um lote mal dimensionado esgota a memória, o sistema passa a usar o disco como memória (swap) e tudo congela, inclusive a sessão do Claude. Caso real: 5 transcrições do Whisper disparadas juntas num Mac de 18 GB travaram a máquina.

**Regra:** antes de processo pesado, **meça → estime → escolha → rode acompanhando**. Na dúvida, um de cada vez.

## 1. Quando esta skill é obrigatória

- Transcrição de áudio ou vídeo (Whisper, whisper.cpp, faster-whisper)
- Modelo de IA local (Ollama, LM Studio, llama.cpp, Stable Diffusion, PyTorch)
- Vídeo e imagem em volume (ffmpeg, render, upscale, conversão em lote)
- Build grande (Next.js, Docker, compilação de firmware em várias placas), suíte E2E com navegadores
- Dado grande na memória (pandas com CSV de centenas de MB, planilha gigante)
- **Qualquer** comando que você pensou em rodar N vezes em paralelo, em background ou com `&`

Comando leve (ler arquivo, `git`, `grep`, teste unitário pequeno) não precisa.

## 2. Quanto cada job costuma usar

Ordem de grandeza para decidir. O valor real depende da versão e do arquivo: **meça o primeiro job** (§4) e use o número medido.

| Job | Memória por job | Núcleos |
|---|---|---|
| Whisper (openai-whisper, PyTorch): tiny / base / small / medium / large / turbo | ~1 / ~1 / ~2 / ~5 / ~10 / ~6 GB | todos |
| whisper.cpp: tiny / base / small / medium / large | ~0,3 / ~0,4 / ~0,9 / ~2,1 / ~3,9 GB | todos (`-t` limita) |
| LLM local quantizado (Ollama, q4): 3B / 7–8B / 13B / 70B | ~3 / ~5–6 / ~9–10 / ~40 GB | todos |
| ffmpeg recodificando 1080p (x264/x265) | ~0,5–1,5 GB | todos (`-threads` limita) |
| Build Next.js / Vite de projeto médio | ~1–3 GB | vários |
| Docker Desktop (a VM inteira) | o que estiver configurado nele (4–8 GB comum) | — |
| Navegador de teste (Playwright/Chromium), por instância | ~0,3–0,6 GB | 1–2 |
| pandas lendo CSV | ~3–5× o tamanho do arquivo | 1 |
| Compilação de firmware (PlatformIO, Arduino) | < 1 GB | vários |

Fonte dos números do Whisper: README do openai/whisper e do ggerganov/whisper.cpp; os demais são típicos e devem ser medidos.

## 3. Medir antes — o script

```bash
bash "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/.claude/skills/machine-resources/scripts/check-resources.sh" --per-job-gb 5
```

Só leitura, macOS e Linux. Devolve `RAM_AVAILABLE_GB`, `SWAP_USED_GB`, `CPU_CORES`, `LOAD_1M`, os 5 processos que mais usam memória e, com `--per-job-gb`, **`MAX_PARALLEL`** e **`VERDICT`**:

| VERDICT | O que fazer |
|---|---|
| `ok` | Rode até `MAX_PARALLEL` jobs ao mesmo tempo |
| `apertado` | Um por vez, e avise o usuário que vai ficar lento; ofereça modelo menor |
| `parar` | Não rode. Diga quanto falta e as saídas: fechar programas, modelo menor ou rodar em nuvem |

O script deixa uma reserva (o maior entre 4 GB e 25% da RAM) para o sistema, o Claude e o navegador. Nunca reduza a reserva para caber mais jobs.

`--threads-per-job N` quando o job usa só N núcleos (ex.: `whisper.cpp -t 2`). Sem a flag, o script assume que o job ocupa todos os núcleos e então `MAX_PARALLEL` nunca passa de 1.

## 4. Medir o primeiro job (o número real)

Rode **um** job sozinho e leia o pico de memória:

- macOS: `/usr/bin/time -l <comando>` → linha `maximum resident set size` (em bytes)
- Linux: `/usr/bin/time -v <comando>` → `Maximum resident set size` (em KB)

Use esse pico (+20% de margem) como `--per-job-gb` para decidir o resto do lote.

## 5. Paralelo quase nunca acelera processo pesado

Processo que já usa todos os núcleos (Whisper, ffmpeg, LLM, build) **não fica mais rápido em paralelo**: as cópias disputam os mesmos núcleos e cada uma carrega o modelo inteiro na memória. Cinco Whispers juntos = 5× a memória, mesmo tempo total, máquina travada.

Prefira, nesta ordem:
1. **Um processo com vários arquivos:** o modelo carrega uma vez só. Ex.: `whisper a.mp3 b.mp3 c.mp3 --model small`.
2. **Fila sequencial:** `for f in audios/*.mp3; do whisper "$f" --model small; done`.
3. **Paralelo limitado ao `MAX_PARALLEL`:** `ls audios/*.mp3 | xargs -P 2 -I{} whisper {} --model small`, e só se o job usar poucos núcleos.
4. **Modelo menor ou versão otimizada** quando nem um cabe: `small` em vez de `medium`; whisper.cpp ou faster-whisper (int8) em vez do Whisper do PyTorch.

Job longo: rode em background com log (`> logs/transcricao.log 2>&1`) e com prioridade baixa (`nice -n 10`), assim o computador continua usável.

## 6. Acompanhar durante e parar a tempo

Entre um job e outro do lote, rode o script de novo (sem `--per-job-gb` é rápido). **Pare o lote** (e não dispare o próximo) se:

- `SWAP_USED_GB` subiu mais de 1 GB desde o início
- `MEM_FREE_PCT` (macOS) caiu abaixo de 20
- `RAM_AVAILABLE_GB` ficou abaixo da reserva
- O usuário disse que o computador está lento

Parou: diga quantos jobs terminaram, quais faltam e o comando para retomar só os que faltam.

## 7. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "São só 5 arquivos, roda tudo junto que é mais rápido" | Não é mais rápido: dividem os mesmos núcleos e multiplicam a memória. |
| "A máquina tem 18 GB, cabe" | Cabe o que está **livre agora**, menos a reserva. Navegador e apps abertos já usam boa parte. |
| "Rodo em background, não atrapalha" | Background usa a mesma memória. Trava igual. |
| "Se travar, o usuário reinicia" | Travar o computador do usuário é falha sua, não dele. |
| "Medi ontem" | Memória livre muda a cada minuto. Meça antes de cada lote. |

## 8. Exemplo — 5 áudios no Whisper num Mac de 18 GB

1. `check-resources.sh --per-job-gb 5` (modelo medium) → `RAM_AVAILABLE_GB=8.3`, reserva 4,5, `MAX_PARALLEL=1`, `VERDICT=apertado`.
2. Decisão: um processo só, com os 5 arquivos (`whisper *.mp3 --model medium`), ou o modelo `small` (~2 GB), que cabe com folga.
3. Durante: script entre os arquivos; o swap subiu 1,5 GB → pausa, avisa o usuário, sugere o `small` para o resto.

## 9. Como falar com o usuário

Antes de começar, uma linha com a decisão e o motivo: "Vou transcrever um de cada vez: com 8 GB livres, dois juntos travariam o computador. Leva ~X min." Se o `VERDICT` for `parar`, diga quanto falta e dê as 2 saídas mais simples. Nunca peça para o usuário fechar programas sem dizer quanto isso libera.
