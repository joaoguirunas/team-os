---
name: brand-visual-system
description: Método da identidade visual — direções com moodboard e racional por traço, sistema de cor com papéis e contraste medido, tipografia com hierarquia e fallbacks, grid e espaçamento, iconografia e formas, fotografia e imagem, movimento, hierarquia de logos conforme a arquitetura, proibições, aplicações-chave e a estrutura do brandbook, com Claude Design como ferramenta padrão. Use ao propor direções visuais, construir o sistema visual ou especificar o brandbook a partir da plataforma aprovada.
version: "1.0"
updated: "2026-09-16"
---

# Brand Visual System — a plataforma que se vê

Sistema visual não é "a cara" da marca — é o conjunto de **regras com papel** que permite a qualquer squad produzir uma peça consistente sem perguntar. Cada elemento rastreia a um traço da personalidade ou a uma regra da arquitetura; cada cor tem um papel e um contraste medido; cada regra tem uma proibição correspondente. Ferramenta padrão do CT: **Claude Design** (`/design`) — sem marketplaces externos, sem template de terceiros.

## 1. Regra de rastreio

Toda seção do sistema cita o traço da plataforma (`↳ §3 traço "direta"`) ou a regra da arquitetura (`↳ arquitetura §5 endosso`) que a sustenta. Bonito sem rastreio é gosto. O que se preserva da identidade atual é decisão da strategist (postura §6) — pergunte, não assuma.

## 2. Direções (antes do sistema)

Sempre **2–3 direções** para a strategist escolher por contraste. Cada direção, num canvas do Claude Design: **território estético** (1 frase), **moodboard** (8–12 referências com o que cada uma empresta — nunca a identidade de outra marca inteira), **paleta-teste** (3–5 cores), **tipografia-teste** (1 par), **1 aplicação-teste** (a mais visível da marca: capa de perfil, hero do site ou capa de deck), e a tabela "traço da plataforma → como aparece". E "de qual concorrente esta direção se afasta" (território visual do mapa de SIRIUS).

## 3. Cor

| Papel | Cor | HEX | Uso | Contraste sobre fundo (AA/AAA) | ↳ traço |
|---|---|---|---|---|---|
| Primária | | | identidade, CTA principal | | |
| Secundária | | | apoio, destaque | | |
| Neutras (3–5) | | | texto, fundos, bordas | | |
| Funcionais | | | sucesso / alerta / erro / info | | |

Regras: proporção de uso (ex.: 60/30/10); combinações permitidas e proibidas; contraste mínimo **WCAG AA** para texto (`/web-design-guidelines`); comportamento em modo escuro se houver. Cor sem papel não entra.

## 4. Tipografia

Par (título + texto) ou família única com pesos. Para cada uso: fonte, peso, tamanho base, entrelinha, tracking. **Fallbacks** de sistema declarados (a peça não pode depender de fonte que o canal não carrega). Hierarquia: display, H1–H3, corpo, legenda, UI. Licença verificada e registrada. `↳ traço` que a escolha traduz (ex.: serifa contemporânea → "profunda, não acadêmica").

## 5. Grid, espaçamento e formas

Unidade base (ex.: 8px), escala de espaçamento, margens por formato (quadrado, story, 16:9, A4/print, hero), raio de borda, espessura de traço, formas recorrentes. Regras de composição: densidade (respiração vs. cheio), alinhamento, onde a marca "assina" a peça.

## 6. Iconografia e ilustração

Estilo (linha/preenchido, peso, cantos), grid do ícone, o que ilustra e o que não ilustra. Se usa ilustração: estilo, paleta permitida, o que representa pessoas/objetos. `↳ traço`.

## 7. Fotografia e imagem

O que **é** (luz, enquadramento, pessoas reais ou não, cor, momento) e o que **não é**. Tratamento (grading, filtros permitidos). Uso de imagem gerada: permitido? com que regras e sinalização? `/social-cinematic-composition` como referência de enquadramento quando o canal é social.

## 8. Movimento

Se a marca se move (vídeo, UI, reels): ritmo, curvas, duração típica, o que anima e o que não anima. `↳ traço` (ex.: "direta" → cortes secos, sem easing longo).

## 9. Logo e hierarquia de marcas

Versões (principal, reduzida, símbolo, monocromática), área de proteção, tamanho mínimo, fundos permitidos. **Hierarquia conforme a arquitetura**: como marca-mãe, sub-marcas e produtos aparecem juntos (ordem, proporção, "by"), lockups permitidos. Nunca redesenhe a arquitetura aqui — aplique.

## 10. Proibições

Lista explícita, uma linha cada: cores fora da paleta, fontes fora do sistema, distorção de logo, combinações proibidas, estilos de imagem recusados, elementos do concorrente mapeado que a marca não adota. Proibição é o que torna o sistema auditável.

## 11. Aplicações-chave

As 6–10 peças que mais aparecem, especificadas no canvas: avatar e capa de perfil, post padrão e carrossel (`/social-key-visual` para o key visual de campanha), hero do site, slide de deck (capa + conteúdo), assinatura de e-mail, papelaria digital. Cada uma com a regra que exemplifica.

## 12. Brandbook

Estrutura em ordem: plataforma em 1 página (copiada, não parafraseada) → voz em 1 página (essencial do guia) → logo → cor → tipografia → grid/formas → imagem → movimento → hierarquia de marcas → proibições → aplicações → contatos/versão. Especificação em `brand-visual.md`; canvas no Claude Design; exportação em PDF quando o usuário pedir.

## 13. Template

`templates/brand-visual.md` — sistema completo (§3 a §11) com rastreio por seção e link do canvas.
