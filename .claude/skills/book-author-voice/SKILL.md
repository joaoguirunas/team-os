---
name: book-author-voice
description: "Método para escrever o livro na voz do autor — perfil de voz extraído de amostras reais (áudios, posts, aulas, e-mails), material bruto virando capítulo sem inventar ([PERGUNTA AO AUTOR]), anatomia de capítulo de não ficção, aprovação do autor capítulo a capítulo, sem cara de IA; em ficção, cena, diálogo, ponto de vista e mostrar × contar. Use ao montar voice-profile.md ou redigir CAP-NN."
version: "1.0"
updated: "2026-11-17"
---

# Book Author Voice — o livro soa como o autor falando

O leitor compra o livro pela pessoa. Se o texto soa como manual genérico, o autor não se reconhece, não aprova e não divulga. MACHADO escreve com o material do autor e no jeito dele; tudo que não veio desse material vira pergunta. Arquivos: `docs/smart-memory/agents/book/manuscript/voice-profile.md` e `manuscrito/CAP-NN-<slug>.md` na raiz do projeto.

## 1. O que o redator nunca inventa

- Experiência pessoal, história, diálogo vivido, lugar, data
- Caso de cliente, depoimento, nome de pessoa
- Número de resultado ("triplicou o faturamento", "300 alunos")
- Opinião do autor sobre tema que ele não comentou
- Frase atribuída a terceiro (vai para HYPATIA como `F-NN`)

Quando o capítulo precisa disso e o material não tem, escreva no lugar o marcador:

> `[PERGUNTA AO AUTOR: Qual foi o primeiro cliente que você atendeu com o método? O que ele tinha de problema e o que mudou em quanto tempo?]`

Cada marcador entra também na lista "Perguntas ao autor" no fim do arquivo do capítulo, numerada. G2 reprova capítulo com marcador aberto.

## 2. Material de origem — o que pedir

| Tipo | Por que serve | Mínimo útil |
|---|---|---|
| Áudios, lives, aulas transcritas (`/book-research-sources` §5) | Ritmo da fala, histórias, expressões | 3–5 horas |
| Posts e legendas longas | Como ele escreve para o público | 20–30 textos |
| E-mails, newsletter | Registro escrito mais cuidado | 10 textos |
| Apostila, slides, material do curso | Nomes do método, sequência, exemplos | o que houver |
| Entrevista de capítulo (perguntas do redator, respostas em áudio) | Preenche lacuna específica | por capítulo |

Total recomendado para o perfil: 10 mil palavras ou mais de amostra real, misturando fala e escrita. Texto que o autor mandou escrever por outra pessoa ou por IA não serve como amostra; pergunte.

## 3. Perfil de voz — `voice-profile.md`

Monte com trechos reais ao lado de cada observação (com origem: arquivo e minuto ou data do post).

| Dimensão | O que registrar | Exemplo |
|---|---|---|
| Pessoa gramatical | Fala com "você", "a gente", "nós"? | "Você" com o leitor; "a gente" para o time dele |
| Tamanho de frase | Média e variação em 3 amostras | Média 14 palavras; frases de 3 palavras para dar ênfase |
| Vocabulário | Palavras que ele repete; termos técnicos que usa e os que evita | Diz "caixa", nunca "fluxo de caixa operacional" |
| Expressões-assinatura | Bordões, imagens recorrentes | "Empresa não é mãe" |
| Humor | Tipo e frequência | Autoironia, uma vez por história |
| Histórias | Como conta: começa pelo fim? usa diálogo? | Começa pela cena e depois explica |
| Referências | Autores, esportes, regiões, cultura que ele cita | Futebol, avô comerciante |
| Nunca diria | Palavrões, jargão de coach, anglicismos, promessas | "Mindset", "escalar exponencialmente" |
| Grau de formalidade | Escala 1–5 | 2: conversa, sem gíria pesada |

Feche o perfil com **três parágrafos de teste** escritos por MACHADO sobre um tema do livro. O autor lê e marca o que não soa como ele. Ajuste o perfil até ele aprovar; a aprovação vira `D-NN`.

## 4. Do material bruto ao capítulo

1. **Leia o objetivo do capítulo** em `outline.md` (entrada, saída, alvo em palavras).
2. **Separe os trechos** do material que servem ao objetivo. Monte uma tabela de rastreio no topo do rascunho (fica fora da versão final):

   | Parte do capítulo | Origem | Fato |
   |---|---|---|
   | Abertura (cena das férias) | Áudio 03, 12:40–15:10 | — |
   | Prova | — | F-14 |

3. **Escreva na ordem da §5**, usando as palavras do autor sempre que possível. Reorganizar, cortar repetição e completar frase é trabalho do redator; criar conteúdo novo, não.
4. **Do falado para o escrito:** tire muletas ("né", "tipo", "então assim"), repetições e frases interrompidas. Mantenha as expressões-assinatura, a pessoa gramatical e o ritmo do perfil.
5. **Marque cada lacuna** com `[PERGUNTA AO AUTOR: …]` (§1).
6. **Confira o tamanho** contra o alvo. Mais de 20% acima ou abaixo: avise CAMPBELL antes de cortar ou esticar.

## 5. Anatomia do capítulo de não ficção

| Parte | Função | Proporção típica |
|---|---|---|
| Abertura | Cena ou caso do autor que põe o leitor dentro do problema | 10–15% |
| Ideia | A tese do capítulo em uma ou duas frases claras | 5% |
| Explicação | Por que acontece; o método ou o conceito | 30–35% |
| Prova | Caso, dado `F-NN`, exemplo de cliente com consentimento | 20% |
| Aplicação | Passo a passo, exercício, checklist, pergunta para o leitor | 20–25% |
| Fechamento | Resumo em 2–3 frases e ponte para o próximo capítulo | 5% |

Regras: uma ideia central por capítulo; abertura com cena real (nunca definição de dicionário nem estatística solta); toda prova com origem; aplicação que o leitor faz em menos de uma hora. Intertítulos a cada 600–1.000 palavras ajudam leitura no celular e no Kindle.

## 6. Aprovação do autor, capítulo a capítulo

1. Envie o capítulo com: tamanho final, lista de perguntas, trechos onde a voz ficou insegura (marcados com `[VOZ?]`).
2. O autor responde às perguntas (de preferência por áudio, que vira material) e marca o que não soa como ele.
3. MACHADO incorpora, remove os marcadores e reenvia só o que mudou.
4. Aprovação registrada no topo do arquivo: `Aprovado pelo autor: AAAA-MM-DD — versão do rascunho`. Sem essa linha, o capítulo não vai para PERKINS (piso 5).
5. Mudança de sentido feita depois da aprovação (por edição ou revisão) volta para o autor. Correção de vírgula, não.

## 7. Tirar a cara de IA

Antes de mandar ao autor, rode `/copy-humanize` no capítulo inteiro. Em livro, atenção extra a:
- Frase de efeito no fim de todo parágrafo
- Listas de três adjetivos e pares de opostos em série
- Pergunta retórica seguida de resposta curta ("O resultado? …")
- Travessão em excesso; o perfil do autor diz quanto ele usa
- Vocabulário que não está no perfil (§3) e transições de manual ("Além disso", "Nesse sentido", "Vale ressaltar")
- Parágrafos todos do mesmo tamanho

O teste final: o autor lê um trecho em voz alta. Se ele tropeça ou muda as palavras, reescreva com as palavras que ele usou.

## 8. Em ficção

A voz pode ser do autor (narrador próximo dele) ou de um personagem; o perfil da §3 vale para cada narrador.
- **Cena:** objetivo do personagem, obstáculo, virada, consequência. Toda cena muda algo; se nada muda, corte ou junte.
- **Diálogo:** cada personagem com vocabulário e ritmo próprios (registre na bíblia). Corte cumprimentos e falas que só informam o leitor. "Disse" é invisível; verbos de elocução enfeitados chamam atenção.
- **Ponto de vista:** um PDV por cena. Primeira pessoa ou terceira próxima; o narrador só sabe o que o personagem do PDV sabe.
- **Mostrar × contar:** mostre momentos de emoção e virada com ação, gesto e sentido concreto; conte passagens de tempo e transições. "Ela ficou nervosa" vira o gesto que o leitor reconhece.
- O enredo e as histórias vêm do autor e da bíblia; o redator não muda o rumo da trama sem `D-NN`.

## 9. Checklist antes de entregar a PERKINS

- [ ] Tabela de rastreio completa: toda parte tem origem no material do autor ou `F-NN`
- [ ] Zero `[PERGUNTA AO AUTOR]` e zero `[VOZ?]` abertos
- [ ] Anatomia da §5 (ou cena da §8) presente
- [ ] Tamanho dentro de ±20% do alvo, ou CAMPBELL avisado
- [ ] `/copy-humanize` aplicado
- [ ] Linha de aprovação do autor com data (§6.4)

## 10. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "Uma historinha genérica ilustra bem" | História apresentada como do autor sem ser dele é texto falso com o nome dele (piso 5). Use o marcador. |
| "O autor está ocupado, aprovo eu" | Só o autor aprova a própria voz. Sem a linha de aprovação o capítulo para. |
| "A fala dele é muito informal para livro" | Limpe as muletas e mantenha o resto. Formalizar demais apaga o motivo pelo qual o leitor comprou. |
| "Fica mais elegante com sinônimos" | Se o autor diz "caixa" vinte vezes, o livro diz "caixa". |
| "Escrevo tudo e ele responde as perguntas no final" | Perguntas por capítulo; respostas no fim do livro chegam tarde demais para mudar a estrutura. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de rhavekost/author-toolkit (MIT, © 2026 rhavekost, commit b5e15ef) — skill `narrative-nonfiction` (sequência gancho → contexto → ensino → evidência → aplicação → ponte) e `fiction-workshop` (cena, PDV e diálogo por personagem).
