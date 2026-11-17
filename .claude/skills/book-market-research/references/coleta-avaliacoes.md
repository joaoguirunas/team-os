# Coleta com Apify e mineração de avaliações

Complementa o §6 e o §7 do `SKILL.md`.

## 1. Quando automatizar

| Volume | Caminho |
|---|---|
| Até ~20 páginas (ranking de 20 livros, 50 avaliações) | Manual: WebFetch ou o usuário abre e copia; sem custo |
| 200–500 avaliações, 3–5 categorias, contagem de hashtags em várias semanas | Apify (`mcp__apify`), com custo aprovado |
| Milhares de itens, coleta agendada, perfis de pessoas | Não. Pare e pergunte ao usuário; é raspagem em massa |

## 2. Apify — passo a passo

Ferramentas do servidor (conferidas na sessão de 17/11/2026): `search-actors`, `fetch-actor-details`, `call-actor`, `get-actor-run`, `get-dataset-items`, `abort-actor-run`.

1. **Procurar o tipo de actor** com `search-actors`, por função, não por nome:
   - avaliações de produto da Amazon (`amazon reviews scraper`)
   - dados de produto e ranking da Amazon (`amazon product scraper`, `amazon bestsellers`)
   - resultados de busca da Amazon (`amazon search`)
   - hashtag ou vídeos do TikTok, hashtag do Instagram (`tiktok hashtag`, `instagram hashtag`)
   Escolha pelo que o resultado mostra: suporte a amazon.com.br, nota e nº de usuários do actor, última atualização. **Não escreva nome de actor no relatório que não tenha aparecido no `search-actors` desta sessão.**
2. **Ler o actor** com `fetch-actor-details`: campos de entrada (URL, país/domínio, limite de itens, filtro por estrelas), campos de saída, modelo de preço (por resultado, por evento, aluguel mensal ou uso de computação) e termos.
3. **Estimar o custo** e mostrar ao usuário antes de rodar:
   > Coleta: avaliações de 6 livros, até 60 por livro (360 itens), actor Y (visto em `search-actors` hoje), preço Z por mil resultados → custo estimado ≈ R$ … / US$ …. Posso rodar?
   Sem "sim" do usuário, não roda. Actor de aluguel mensal: avise que é assinatura.
4. **Rodar pequeno primeiro:** `call-actor` com 1 livro e 20 itens; confira a saída com `get-dataset-items`. Só então a rodada completa, com limite explícito de itens.
5. **Acompanhar:** `get-actor-run` para status e custo real; `abort-actor-run` se passar do combinado.
6. **Registrar** em `signals.md`: actor, data, entrada, nº de itens, custo real, e o que ficou de fora.

Regras fixas:
- Respeite os termos de uso da plataforma e do actor; coleta pequena e dirigida para pesquisa.
- **Sem dado pessoal:** guarde só texto da avaliação, nota, data, país, formato e se é compra verificada. Descarte nome, perfil, foto e link do avaliador antes de salvar em `reviews.md`. Em hashtag, só números agregados e títulos de livro, nunca lista de perfis.
- Amostra e data sempre registradas: "312 avaliações de 6 comparáveis, coletadas em 17/11/2026, .com.br e .com".
- Nada é publicado, curtido, seguido ou enviado por esta coleta: ela só lê.

## 3. Mineração de 200–500 avaliações

**Amostra:** de 5–8 comparáveis, 40–60 avaliações cada, distribuídas por nota: todas as de 3 estrelas disponíveis até ~15 por livro, mais 1–2 estrelas e 4–5 estrelas. Prefira compra verificada e avaliações com texto de mais de 2 linhas. Inclua .com.br; avaliações em inglês do .com valem para livro traduzido.

**Passo a passo:**

1. Uma linha por avaliação numa tabela de trabalho (fora do relatório): livro, nota, data, texto.
2. Primeira leitura de 50 avaliações para criar os códigos (ex.: "teórico demais", "faltou exemplo brasileiro", "repetitivo", "mudou minha rotina").
3. Codifique todas; uma avaliação pode ter mais de um código.
4. Conte e ordene. Só vira achado o grupo com pelo menos ~5% das avaliações ou 10 menções.
5. Separe as **frases exatas** mais fortes (sem identificar o avaliador).

**Saída em `reviews.md`:**

| Grupo | Código | Menções (de 312) | Livros onde aparece | Frase exata típica | Uso |
|---|---|---|---|---|---|
| Dor | "sou o gargalo" | 41 | 5 de 6 | "comprei porque não consigo tirar férias" | título / abertura do CAP-01 |
| Promessa não cumprida | "teórico demais" | 37 | 4 de 6 | "ótimas ideias, nenhum passo a passo" | posição A |
| Pedido | "queria exemplos de PME brasileira" | 22 | 3 de 6 | "queria que tivesse casos daqui" | diferença verificável |
| Elogio | "checklist no fim do capítulo" | 30 | 2 de 6 | "o checklist vale o livro" | estrutura |

**Avaliações de 3 estrelas:** leia todas antes das outras. O leitor de 3 estrelas comprou pelo motivo certo e diz o que faltou; é a fonte principal da coluna "Pedido" e da lacuna do §9. Leitor de 1 estrela muitas vezes reclama de entrega, preço ou expectativa errada; leitor de 5 estrelas diz o que precisa ser mantido.

**Linguagem do leitor:** as frases exatas mais repetidas alimentam título e subtítulo (CAMPBELL), descrição da Amazon (LOBATO) e copy de lançamento (squads de marketing). Usar a ideia e o vocabulário do leitor é permitido; colar avaliação de outro livro como depoimento do nosso, nunca.

Repasse a HYPATIA o que precisar virar fato do livro: avaliação não é fonte de fato (`/book-research-sources` §2).
