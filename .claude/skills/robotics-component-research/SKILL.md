---
name: robotics-component-research
description: "Pesquisa de componentes da squad Robotics — ledger de afirmações (achado × leitura, datasheet com página e revisão), tabela de limites elétricos, armadilhas de peças comuns de hobby, como reconhecer falsificação, maturidade de biblioteca, ficha de compra com versão exata e alternativa, e contrato do que foi e não foi verificado. Use antes de escolher ou comprar peça e ao ler um dossiê."
version: "1.0"
updated: "2026-11-14"
---

# Robotics Component Research — datasheet, página e revisão, ou é palpite

Anúncio de marketplace erra tensão, inventa capacidade e copia foto de outro produto. Esta skill garante que todo número que chega a VOLTA (circuito) ou JAZARI (plataforma) tenha fonte localizável — e que quem lê saiba o que foi conferido e o que ficou de fora. HERON pesquisa; JAZARI e VOLTA decidem lendo este formato.

## 1. Princípios

1. **Fonte primária > secundária > memória.** Primária: datasheet do fabricante do chip, manual de referência, documentação oficial do core (Arduino, Espressif, Raspberry Pi, ST). Secundária (blog, fórum, vídeo, anúncio) é pista para achar a primária.
2. **Módulo ≠ chip.** O datasheet do TB6612FNG fala do CI; o módulo azul tem regulador, resistores e jumpers que o datasheet não cobre. Registre os dois níveis.
3. **Achado ≠ leitura.** Achado é o que a fonte diz. Leitura é a sua interpretação, marcada `leitura:`. Decisão não entra no dossiê.
4. **Sem fonte, marque.** `⚠ sem fonte` (valor de memória ou de anúncio) ou `⚠ datasheet não localizado` (clone sem documento). Nunca use o datasheet de "um parecido".
5. **Comparação tem ≥ 2 opções** com prós e contras; preço é coluna, não critério.

## 2. Ledger de afirmações

Todo dossiê em `research/{tema}.md` tem esta tabela; cada linha é uma afirmação conferível.

| # | Afirmação | Tipo | Fonte | Confiança |
|---|---|---|---|---|
| A1 | TB6612FNG: VM máx. 15 V; corrente média 1,2 A/canal, pico 3,2 A | achado | [datasheet Toshiba TB6612FNG rev {data}, p. {n}] | alta |
| A2 | Módulo X tem resistores de pull-down em STBY | achado | [esquema do fabricante do módulo, link] | média |
| A3 | Serve para 2 motores TT a 6 V no robô 2WD | leitura | A1 + corrente medida de TT em MED-04 | média |
| A4 | Corrente de stall do TT ~1 A a 6 V | achado | ⚠ sem fonte (anúncios variam) | baixa → medir |

Formato de citação: `[datasheet {peça} {fabricante} rev {x ou data}, p. {n}, tabela {t}]`. Link sozinho não serve: página muda, PDF é substituído.

## 3. Tabela de limites elétricos

Uma por componente crítico. Valor típico ≠ máximo absoluto — projete pelo máximo de operação recomendado, nunca pelo absoluto.

| Grandeza | Mín. | Típ. | Máx. | Fonte |
|---|---|---|---|---|
| Tensão de alimentação (operação recomendada) | | | | p. |
| Máximo absoluto | | | | p. |
| VIH / VIL de entrada (nível lógico) | | | | p. |
| VOH / VOL de saída | | | | p. |
| Corrente típica · de pico · de stall (motor travado) | | | | p. |
| Temperatura de operação | | | | p. |

Regra de nível lógico: saída de 3,3 V só aciona entrada de 5 V se o **VIH** dessa entrada for menor que ~3,0 V (ex.: entradas TTL/HCT com VIH 2,0 V aceitam; CMOS 5 V com VIH 0,7×VCC = 3,5 V não). Saída de 5 V em entrada 3,3 V nunca, sem conversão (`robotics-electrical-safety`).

## 4. Armadilhas conhecidas de peças comuns

Confira sempre no datasheet da versão comprada; os números abaixo são ponto de partida.

| Peça | Armadilha | O que registrar |
|---|---|---|
| HC-SR04 | Projetado para 5 V; o ECHO sai em 5 V e queima entrada de ESP32/Pico sem divisor | VCC 5 V, ECHO em 5 V → divisor (ex.: 1 kΩ/2 kΩ) ou conversor |
| HC-SR04P / "versão 3,3 V" | Aceita ~3–5,5 V e o ECHO segue o VCC; há várias placas vendidas com esse nome | Foto da placa e medição do ECHO com 3,3 V no VCC antes de ligar no GPIO |
| L298N | Driver bipolar: queda total de ~2 V a 1 A (pode passar de 3 V) → motor de 6 V recebe ~4 V; esquenta | Queda pela tabela do datasheet ST L298; jumper do regulador 5 V do módulo só com VS ≤ 12 V |
| TB6612FNG | Alternativa MOSFET, queda bem menor; mas VM máx. 15 V e 1,2 A contínuos por canal | Motor com stall > 3 A não serve; pino STBY precisa estar alto |
| Servo SG90 | Pico de ~650–750 mA no arranque/travado (medição comum, sem datasheet confiável); 2 servos pelo 5 V da placa causam reset | Fonte própria de 5–6 V, capacitor de 470–1000 µF perto dos servos, terra comum |
| Módulo de relé 5 V | Bobina de ~70–90 mA a 5 V; entrada costuma ser ativa em nível baixo com VCC 5 V — com GPIO 3,3 V em nível alto ainda sobra tensão no LED do optoacoplador e o relé pode não desligar | Módulo com acionamento 3,3 V ou transistor/MOSFET; contato "10 A 250 VAC" do rótulo não vale para a trilha da placa; rede 110/220 V: módulo fechado e certificado ou eletricista |
| Buck LM2596 (módulo) | Original: 3 A, 150 kHz. Módulos baratos com CI remarcado ou indutor pequeno aquecem acima de ~1–1,5 A | Use ≤ 50 % do nominal sem dissipador até medir; **ajuste a tensão sem carga antes de ligar a placa** |
| Célula 18650 | Capacidade real das melhores 18650 fica em ~3.500–3.600 mAh; rótulo com 5.000–9.900 mAh é falsa; célula reembalada de pack usado | Marca e modelo (ex.: Samsung, LG, Molicel, Sony/Murata), massa (~45–50 g; falsa costuma ser mais leve), teste de capacidade no carregador |
| ESP32 ADC2 | Não lê enquanto o Wi-Fi está ligado | Usar ADC1 (GPIO32–39) para sensor analógico com Wi-Fi |

## 5. Como reconhecer falsificação

- [ ] Preço muito abaixo da média das lojas que vendem o original
- [ ] Rótulo com número impossível (capacidade, corrente, "100 W" num módulo do tamanho de uma moeda)
- [ ] Marcação do CI borrada, fonte diferente do original, logo ausente, código de data incoerente
- [ ] Mesma foto em dezenas de vendedores; descrição sem datasheet ou com o datasheet de outro CI
- [ ] Massa diferente da especificada (bateria, motor)
- [ ] Comportamento fora do datasheet medido em bancada: aquecimento precoce, tensão de saída cai com carga

Suspeita → `leitura: possível falsificação` + o teste que confirma (capacidade, carga com medição de temperatura, frequência no osciloscópio). Peça de segurança (BMS, fusível, carregador) suspeita não entra na BOM.

## 6. Maturidade de biblioteca

| Critério | O que olhar | Sinal de alerta |
|---|---|---|
| Atividade | Data do último commit e da última release | > 2 anos sem commit e issues sem resposta |
| Issues | Abertas × fechadas, tempo de resposta | Bug crítico aberto há meses |
| Licença | Arquivo LICENSE | Sem licença; GPL num produto fechado que será vendido |
| Compatibilidade com o core | `library.properties` (`architectures=`), CI, issues da versão atual | Ex.: core Arduino-ESP32 3.x removeu `ledcSetup`/`ledcAttachPin` (passou a `ledcAttach`) — biblioteca antiga não compila |
| Exemplo oficial | Exemplo que compila na placa alvo | Só exemplo para outra placa |
| Alternativa oficial | Biblioteca do fabricante ou do core | Usar a de terceiro sem motivo |

Entregue a ADA: nome, versão exata a fixar (`lib_deps` com versão no PlatformIO), commit, licença e o exemplo que compila.

## 7. Ficha de compra

`research/compra-{AAAA-MM-DD}.md` — é a evidência do G1 (ASIMOV).

| BOM | Item e versão exata | Qtd | Onde (tipo de loja) | Preço consultado (data) | Prazo | Alternativa | Risco de falsificação · como conferir ao receber |
|---|---|---|---|---|---|---|---|
| BOM-04 | Módulo TB6612FNG (não L9110, não L298N) | 1 | loja nacional | R$ {valor} ({data}) | {dias} | DRV8833 (até 10,8 V) | baixo · marcação do CI |

Versão exata quer dizer o que o usuário digita na busca e confere na foto: "ESP32-DevKitC com WROOM-32E, 38 pinos", não "ESP32".

## 8. Fornecedores e prazos no Brasil

Sem inventar preço: todo valor vem de consulta datada; sem consulta, a coluna diz `consultar`.

| Origem | Prazo típico | Prós | Contras |
|---|---|---|---|
| Loja nacional de eletrônica | dias | Nota fiscal, troca fácil, suporte | Preço maior, estoque limitado de peças específicas |
| Marketplace nacional | dias | Variedade | Vendedor varia; mesma peça com versões diferentes |
| Importação direta | semanas | Preço por unidade menor, variedade | Tributos e regras de importação mudam — confira a regra vigente no dia; troca difícil; mais falsificação |

Peça de segurança e peça crítica para a próxima etapa: prefira loja com nota e troca. Módulo com rádio em produto que será vendido: verificar homologação Anatel.

## 9. Contrato de revisão

Todo dossiê termina com:

```markdown
### Verificado
- A1, A2: conferidos no datasheet citado (página aberta nesta pesquisa)
### Não verificado
- A4: corrente de stall sem fonte → pedir MED a FARADAY
- Esquema do módulo não localizado → regulador do módulo é `profile-gap`
### Falsos alarmes triados
- {alerta que parecia problema e não é, com o motivo}
```

Item pulado vira lacuna declarada, nunca silêncio. Alerta que parece problema é triado (é real? com qual fonte?) antes de virar bloqueio.

| Desculpa | Realidade |
|---|---|
| "Todo mundo usa assim" | Popularidade não é limite elétrico. Fonte com página. |
| "O anúncio diz 3 A" | Anúncio é secundária. Datasheet do CI e teste com carga. |
| "Achei num fórum de 2017" | Pista. Confirme na fonte primária e na versão atual. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de aklofas/kicad-happy (MIT, © 2025 Andrew Klofas, commit 7d9d4d9) — contrato de revisão; e de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e) — separação de limites do chip × placa e status `profile-gap`. Regra de VIH para 3,3 V → 5 V e ADC2 × Wi-Fi conferidas com ezrover/ESP32-AI-Agent-Skill (MIT, © 2026 Vibe Coder, commit 124d298).
