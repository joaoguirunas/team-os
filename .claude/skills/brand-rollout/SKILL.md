---
name: brand-rollout
description: "Método de implantação de um reposicionamento — pré-condições (voz e visual com PASS, baseline travada, confirmação do usuário), inventário de ativos (mantém, migra, aposenta), fases interno → transição → externo, checklist por canal, kit de handoff e ledger da virada. Use ao planejar ou conduzir a virada de uma marca nos canais e preparar o material das outras squads."
version: "1.0"
updated: "2026-09-25"
---

# Brand Rollout — a virada, na ordem certa, sem executar no canal

Marca que vira pela metade é duas marcas brigando no mesmo feed. Rollout é **ordem + gate**: só sai o que tem PASS, só sai depois da baseline, interno antes do externo, todo ativo antigo com data para morrer. E a squad de marca **não executa no canal** — entrega o kit e o checklist; site, social, tráfego e propostas aplicam nos projetos delas, com o QA delas.

## 1. Pré-condições (nenhuma é opcional)

| Pré-condição | Evidência | Sem ela |
|---|---|---|
| Guia de voz com PASS | `agents/qa/results.md` | não há kit |
| Sistema visual/brandbook com PASS | idem | não há kit |
| Baseline travada | `agents/tracking/baseline.md` FECHADA | fase externa não sai — decisão do usuário por escrito se quiser sair assim |
| Ordem de migração | `agents/architecture/migration-roadmap.md` | não há sequência de canais |
| Confirmação do usuário para a data externa | ledger | nada externo sai |

## 2. Inventário de ativos

Cada ponto de contato vivo (da auditoria + o que nasceu depois): onde vive, quem controla, o que muda, **destino** (mantém / migra / aposenta), data, dono.

| Ativo | Onde | Controla | Destino | O que muda | Data | Dono |
|---|---|---|---|---|---|---|

Aposentar tem data de desligamento e o que acontece com quem chega lá (redirect, aviso, arquivo). Migrar tem a versão nova pronta **antes** de desligar a antiga.

## 3. Fases

### Interno (mínimo 48h antes de qualquer coisa externa)
Time, sócios, parceiros próximos, fornecedores de canal. Recebem: kit de handoff, sessão de alinhamento (30–60 min: por que mudou, o que muda, o que não pode mais), FAQ interno (as 10 perguntas que vão aparecer). Objetivo: **ninguém descobre a marca nova junto com o público**.

### Transição (canais próprios, por visibilidade)
Ordem típica: avatar/capa e bio dos perfis → site (hero, sobre, rodapé, favicon) → assinaturas de e-mail e templates → materiais de venda (propostas, decks — via `project/brand.md` da squad sales) → conteúdo agendado → ads. Cada item aplicado pela **squad do canal**, no projeto dela, seguindo o checklist do canal. Janela curta (24–72h) para não conviver duas marcas.

### Externo
Comunicado (post/manifesto/vídeo — produzido pela squad do canal a partir do manifesto com PASS), imprensa/parceiros se houver, mudança de nome em diretórios e marketplaces. Data confirmada pelo usuário no ledger.

## 4. Checklist por canal

Para cada canal, o que a squad dele precisa aplicar, em ordem, e como o QA de marca vai auditar depois:

| Canal | Itens (ordem) | Regra do kit | Squad responsável | Auditoria |
|---|---|---|---|---|
| Site | favicon, logo, cores/tipografia do tema, hero, sobre, rodapé, OG image | §cor, §tipo, §logo, §voz | sites | amostra de 5 páginas |
| Social | avatar, capa, bio, destaque, template de post/carrossel/story, tom das legendas | §aplicações, §voz | social | últimos 12 posts |
| Tráfego | criativos, copy, landing | §aplicações, §voz, §proibições | traffic | criativos ativos |
| Propostas/decks | capa, template, `project/brand.md` | kit inteiro | sales | próxima proposta |
| E-mail | assinatura, template de newsletter | §logo, §tipo, §voz | usuário/sites | 1 envio |

## 5. Kit de handoff — `handoff/brand.md`

O arquivo que vai para `docs/smart-memory/project/brand.md` de **cada projeto de canal** (é o que a squad `sales` já lê como `brand.md`, e o que as outras passam a ler). **≤150 linhas, copiado das regras aprovadas — nunca parafraseado**:

1. Identidade em 5 linhas: promessa, personalidade (traços "é / não é"), público prioritário
2. Voz: dimensões com posição + 6–10 pares dizemos/não dizemos essenciais + tratamento
3. Cor: paleta com papéis e HEX + proporção + proibidas
4. Tipografia: fontes, pesos, fallbacks
5. Logo: versões, proteção, mínimo, hierarquia de marcas (lockups)
6. Imagem: é / não é
7. Proibições (lista)
8. Termos fixos e grafias (glossário essencial)
9. Links: `brand-voice.md`, `brand-visual.md`, canvas, contato para dúvida
10. Versão + data + veredicto do QA

Distribuição: o lead copia o kit para cada projeto (a squad de marca não escreve fora do próprio projeto). `templates/handoff-brand.md`.

## 6. Ledger da virada

```
canal | item | status (planejado / aplicado / verificado / desligado) | data | evidência (link/captura) | confirmado por
```
Toda mudança de status tem evidência. "Aplicado" sem captura não é aplicado. Desligamento sem data não existe.

## 7. Pós-virada

+7 dias: varredura de sobras (ativo antigo ainda no ar) → ledger. +30 dias: auditoria de consistência do QA por canal → métrica de consistência (insights). +60–90 dias: leitura do depois (insights). Sobras e desvios voltam para a squad do canal via lead — a squad de marca aponta, não corrige.

## 8. Templates

- `templates/rollout-plan.md` — pré-condições, inventário, fases, checklist por canal, ledger
- `templates/handoff-brand.md` — o kit `brand.md` de 10 seções
