# Régua editorial — padrões de busca e leitura

Aplicar em **todo texto que o cliente lê**: PDF, deck, one-pager, e-mail de envio, follow-up. Grep encontra o óbvio; a leitura página a página encontra o resto. Os dois são obrigatórios.

## R1 — Condicional de resultado (bloqueante)

Padrões (case-insensitive, pt-BR):
```
\bse der certo\b | \besperamos\b | \bespera-se\b | \bpretendemos\b | \bpode ser que\b
\btentaremos\b | \btentar\b | \bcaso funcione\b | \bprovavelmente\b | \btalvez\b
\bacreditamos que\b | \bdeve(ria)? (funcionar|entrar|melhorar)\b | \bidealmente\b
```
Exceção legítima: condicional **de escolha do cliente** ("se quiserem a página adicional, ela entra como add-on") — permitido porque descreve opção, não incerteza de entrega. Julgar na leitura.

## R2 — Risco enunciado (bloqueante)

```
\brisco(s)?\b | \bcaso (a|o|não|haja)\b | \bse (a|o) .{0,40} (atrasar|falhar|não)\b
\bdepend(e|emos) de\b | \bnão garantimos\b | \bsujeito a\b | \bpode atrasar\b
```
Reescrever como sequenciamento ("abrimos X no primeiro dia; enquanto corre, Y já opera") ou como compromisso conjunto (tabela). `depende de` só é aceitável dentro da tabela "o que precisamos de vocês".

## R3 — Objeção enunciada (bloqueante)

Sem grep confiável — leitura. Sinais: frases que começam com "você pode achar", "é comum pensar", "apesar de parecer", "embora"; parágrafos que argumentam contra algo que o texto mesmo levantou. Reescrever afirmando o enquadramento sem citar a dúvida.

## R4 — Número sem origem (bloqueante)

Todo valor (R$, %, prazos em dias/meses, quantidades, múltiplos) tem um `#id` na ficha de números com **valor e formato idênticos**. Procedimento: listar todos os números do artefato (grep `R\$|\d+%|\d+ (dias|meses|semanas|páginas|módulos)`), cruzar um a um. Número na ficha com status pendente = bloqueante.

## R5 — Estatística sem fonte (bloqueante)

Dados de mercado ("47 min de tempo médio de resposta", "44% param na 1ª tentativa") exigem fonte (autor, ano) no artefato ou em rodapé, conforme a nota de marca. A fonte vem do research do analista; se não existe lá, o dado não entra.

## R6 — Termos da oferta (bloqueante)

Nomes de produtos, pacotes, módulos e marcas registradas exatamente como no `project/offer-catalog.md` (grafia, maiúsculas, símbolos ™/®). Grep pelos nomes do catálogo e pelas variações erradas conhecidas.

## R7 — Dependência como compromisso conjunto (bloqueante)

A página de governança traz a tabela "O que entregamos / O que precisamos de vocês". Nenhuma dependência aparece fora dela como alerta. Tom: "o cronograma é nosso compromisso — e ele depende de N coisas que só vocês têm".

## R8 — Títulos são asserções

Índice lido em sequência deve contar a história sozinho. "Diagnóstico", "Solução", "Investimento" são rótulos; "Onde a receita vaza", "Um lugar só, com tudo dentro", "O investimento" (este é aceitável por convenção) são asserções ou promessas.

## R9 — Marca

Conforme `project/brand.md`: emoji permitido?, termos vetados, maiúsculas, tratamento (você/vocês), pontuação, palavras de marca em itálico/negrito. Grep de emoji: `[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]`. Sem brand.md → **não improvisar**: perguntar ao lead.

## R10 — Páginas = plano

Contagem e ordem de páginas iguais ao §9 do planejamento aprovado. Índice bate com os títulos reais.

## Procedimento

1. Rodar os greps R1, R2, R4, R6, R9 no texto-fonte (markdown/HTML) — anotar linha e trecho
2. Ler página a página para R3, R5, R7, R8, R10
3. Registrar resultado por regra (ok / trecho + página) — a redatora antes de entregar, o QA antes do veredicto
4. Qualquer falha em R1–R7 → volta para a redatora (ou para a financeira, se R4/R5 for de número)
