# Amazon — ranking, categorias, Kindle Unlimited e padrão dos líderes

Complementa o §3 e o §8 do `SKILL.md`. Números de ferramenta de terceiro são **estimativa**: entram em `signals.md` com confiança baixa e em faixa.

## 1. O que é o ranking (BSR)

- "Classificação nos mais vendidos" aparece na página do produto, em "Detalhes do produto": um número na loja inteira (ex.: "#1.240 em Loja Kindle") e até três números em categorias ("#4 em Gestão de pequenas empresas").
- Cada **formato tem ranking próprio**: e-book, brochura, capa dura e audiolivro de um mesmo título têm números diferentes. Compare sempre formato com formato.
- Cada **loja tem ranking próprio**: .com.br e .com não se comparam. A loja Kindle dos EUA tem muito mais venda total; #10.000 lá exige mais vendas que #10.000 no Brasil.
- É **relativo e recente**: reflete as vendas das últimas horas e dias contra os outros livros. A página de Mais vendidos da Amazon diz que é atualizada com frequência; ferramentas relatam atualização de hora em hora (Kindlepreneur e profitable.app, conferidos em 17/11/2026). Uma promoção ou um envio de newsletter derruba o número por um ou dois dias.
- A Amazon **não publica** conversão de ranking em vendas.

Como registrar (uma linha `M-NN` por leitura):

```
M-12 | Ranking "Fora do Balcão" (Kindle) | amazon.com.br/dp/XXXX | 17/11/2026 14h10 | #2.310 Loja Kindle; #3 Gestão | alta
```

Para tendência, leia o mesmo livro em 3 dias e horários diferentes e use a **mediana**, nunca a melhor leitura.

## 2. Estimar vendas a partir do ranking — só ordem de grandeza

Tabela pública da profitable.app (Kindle Store, amazon.com; a página chama os números de "guia de ordem de grandeza" e diz que são menos confiáveis no topo e na cauda; consultada em 17/11/2026, sem data da calibração):

| Ranking na loja Kindle (EUA) | Vendas estimadas por dia | Por mês |
|---|---|---|
| #100 | ~1.000 | ~30 mil |
| #1.000 | ~120 | ~3.600 |
| #5.000 | ~35 | ~1.000 |
| #25.000 | ~9 | ~280 |
| #100.000 | ~1 | ~46 |
| #500.000 | ~0,3 | ~11 |

Referência qualitativa da calculadora da Kindlepreneur (dados do Publisher Rocket, ferramenta paga; conferida em 17/11/2026): abaixo de 10.000 = vendas diárias fortes; abaixo de 100.000 = vende com regularidade; acima de 500.000 = vende raramente.

Regras de uso:
- Escreva **faixa e fonte**: "#5.000 na loja Kindle dos EUA ≈ 25–50 vendas/dia (estimativa, profitable.app, 17/11/2026)".
- **Brasil:** não há tabela pública confiável para .com.br. Use só como comparação relativa entre livros da mesma loja ("o 1º vende várias vezes o 20º") ou escreva "ordem de grandeza não confirmada para .com.br".
- **Impresso** tem curva diferente do Kindle; não aplique a tabela do Kindle a brochura.
- Ferramentas pagas (Publisher Rocket, BookBeam e similares) podem ser usadas pelo usuário; registre nome, data e "estimativa da ferramenta". O agente não assina nem paga ferramenta.
- Dado de venda mais próximo do real no Brasil: lista semanal **PublishNews/Nielsen BookScan** (livro físico, exemplares vendidos na semana nos varejistas do painel; o PublishNews informa cobertura de 60–70% do mercado — conferir em publishnews.com.br/ranking-nielsen, consultado em 17/11/2026). Livro que aparece ali vende de verdade.

## 3. Ler uma categoria — passo a passo

1. Abra a página de Mais vendidos da categoria (loja Kindle e Livros, .com.br; repita no .com se o autor quer leitor fora do Brasil).
2. Para os 20 primeiros, anote: título, ranking na loja, nº de avaliações, nota média, data de publicação, preço e-book e impresso, KU sim/não, páginas.
3. Calcule e registre em `categories.md`:

| Indicador | Como medir | Leitura (para intenção "vender") |
|---|---|---|
| Demanda do topo | Ranking na loja do 1º | Kindle EUA abaixo de ~#2.000 = categoria quente |
| Profundidade | Ranking na loja do 10º e do 20º | 20º ainda abaixo de ~#30.000 (EUA) = demanda espalhada, cabe um livro novo |
| Concorrência fraca | Nº de livros do top 20 com < 100 avaliações | 5 ou mais = dá para entrar |
| Frescor | Nº do top 20 publicados nos últimos 12 meses | 3 ou mais = leitor aceita livro novo |
| Preço | Mediana e faixa, por formato | Define a faixa que o leitor espera (passa para LOBATO) |
| KU | Quantos do top 20 estão no Kindle Unlimited | Mais da metade = leitor da categoria lê por assinatura |

Os limiares são heurística de mercado para comparar categorias entre si, não regra oficial. No .com.br, compare as categorias candidatas umas com as outras pelos mesmos indicadores.

4. Repita para **3 a 5 categorias** candidatas e monte a comparação:

| Categoria (loja) | 1º | 10º | 20º | Top 20 < 100 aval. | Publicados < 12 meses | Preço mediano e-book | KU | Leitura |
|---|---|---|---|---|---|---|---|---|
| Gestão de pequenas empresas (.com.br, Kindle) | #312 | #4.100 | #9.800 | 7 | 4 | R$ 29,90 | 11/20 | demanda média, entrada possível |

Categoria com demanda e pouca concorrência = 1º e 20º fortes **e** vários do top 20 com poucas avaliações ou recentes. Categoria com o 1º em #300 e o 20º em #200.000 é dominada por um ou dois títulos.

## 4. Kindle Unlimited (KU)

- Assinatura de leitura; o autor recebe por páginas lidas (KENP) e o e-book precisa estar no KDP Select, que exige exclusividade digital por 90 dias (`/book-publishing` §7).
- Leituras por KU contam para o ranking segundo ferramentas e autores independentes; a Amazon não detalha o peso. Trate como sinal, conferir na ajuda do KDP.
- Categoria com KU dominante (ficção de gênero, autoajuda curta) favorece livro em KU e preço baixo. Categoria com poucos em KU (negócio de editora tradicional) aceita preço maior.

## 5. Padrão dos líderes — tabela do §8

Para os 10 primeiros de cada categoria-alvo:

| # | Título (palavras) | Subtítulo (palavras) | Promessa / número no subtítulo | Capa: cor dominante | Capa: tipo × foto × ilustração | Rosto do autor | Preço e-book / impresso | Páginas | Estrutura |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 3 | 11 | "sem…", "em 30 dias" | preto + amarelo | só tipo, título enorme | não | R$ 34,90 / R$ 59,90 | 224 | 3 partes, 12 cap., exercícios |

Linha de resumo no fim: "7 de 10 com título até 4 palavras; 6 de 10 com número no subtítulo; 8 de 10 só tipografia; mediana 208 páginas". Essa linha vai para CAMPBELL (título, tamanho) e MUNARI (capa). Nunca reproduza a capa de outro livro no relatório além de miniatura para análise interna.
