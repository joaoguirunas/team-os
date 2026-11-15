---
name: robotics-electrical-safety
description: "Régua elétrica da squad Robotics para qualquer placa (Arduino, ESP32, RP2040, STM32, Raspberry Pi) — contrato antes de energizar, níveis lógicos 3.3V ↔ 5V, pinos proibidos por placa, cargas e flyback, desacoplamento, proteção, limite da rede 110/220V e conferência com multímetro. Use ao desenhar ligação, conferir pins.h ou julgar os gates G1–G3."
version: "1.0"
updated: "2026-11-14"
---

# Robotics Electrical Safety — confira o contrato elétrico antes de ligar

O agente não tem mãos: o usuário monta, mede e liga. Por isso cada ligação sai daqui com o nível lógico dos dois lados, o pino permitido na placa, a proteção e **como conferir com o multímetro antes de energizar**. Valores abaixo são típicos — **o datasheet da peça exata manda**; sem datasheet, projete pelo pior caso.

Referência de pinos completa por placa: `references/pinos-por-placa.md` — leia ao montar ou revisar `electronics/pinout.md` e ao conferir o `pins.h`.

## 1. Contrato antes de energizar

- [ ] **Mapa de trilhos e terra**: cada trilho (bateria, VM do motor, 5V, 3V3, USB/VIN/VSYS) com quem o gera, quem consome e corrente de pico. Todas as fontes com **terra comum** (exceto onde há isolamento óptico de propósito).
- [ ] **Cada sinal checado nos dois sentidos**: quem envia, quem recebe, tensão alta de cada lado, VIH/VIL e máximo de entrada do receptor. Alimentar o sensor com 5V **não** diz nada sobre o nível do pino de dados — leia o datasheet ou meça.
- [ ] **Estado seguro no reset**: durante o boot os GPIO flutuam ou ficam em pull interno. Toda saída que aciona motor, relé, bomba ou MOSFET tem **pull-down/pull-up externo que mantém a carga desligada** (ex.: 10–100 kΩ gate→source no MOSFET; pino STBY do driver em LOW por resistor).
- [ ] Cada ligação vira `W-NN` em `electronics/wiring.md` e cada pino `PIN-NN` em `electronics/pinout.md`, com a restrição da placa anotada.
- [ ] Placa resolvida: modelo e revisão exatos (ESP32-WROOM-32 ≠ WROVER ≠ S3 ≠ C3; Pico ≠ Pico W ≠ Pico 2). Sem a placa resolvida não se escolhe pino.

## 2. Níveis lógicos 3.3V ↔ 5V

ESP32 (todas), RP2040, Raspberry Pi e a maioria dos pinos analógicos do STM32 **não são tolerantes a 5V**. Terra comum é necessária, mas **não muda o limiar lógico**.

| Situação | Solução | Valores e cuidados |
|---|---|---|
| Saída 5V → entrada 3.3V, sinal lento e unidirecional | **Divisor resistivo** | Eco do HC-SR04: 1 kΩ em série do ECHO até o GPIO, 2 kΩ do GPIO ao GND → 5 × 2/(1+2) = **3,33 V**. Alternativa 10 k/20 k. Não serve para I2C nem para sinal rápido/bidirecional |
| I2C, UART ou sinal lento bidirecional | **MOSFET BSS138** (módulo de 2/4 canais) | Pull-up de 10 kΩ de cada lado (3V3 e 5V). Bom até I2C 400 kHz em fio curto |
| Barramento rápido, unidirecional, vários bits | **CI dedicado** | 5V → 3.3V: **74LVC245** alimentado em 3,3 V (entradas aceitam 5 V). 3.3V → 5V: **74AHCT125/74HCT125** alimentado em 5 V (VIH TTL = 2,0 V) — padrão para dados de WS2812 |
| Auto-direção | **TXS0108E** sim para I2C (tem pull-ups internos e foi feito para dreno aberto); **TXB0108 não** — saída fraca, só push-pull, não funciona com pull-up de I2C |
| 3.3V acionando entrada 5V | Às vezes direto | Só se o **VIH mínimo do receptor** ficar bem abaixo do VOH mínimo do MCU 3.3V (ESP32: 0,8 × VDD ≈ 2,64 V). Entrada TTL (VIH 2,0 V) aceita. ATmega328P a 5 V pede 0,6 × VCC = 3,0 V → fora de garantia; WS2812B pede 0,7 × VDD = 3,5 V → falha. Na dúvida, 74AHCT125 |
| Sensor existe em 3.3V | **Versão 3.3V** é a melhor solução | HC-SR04P ou RCWL-1601 (3–5,5 V) alimentados em 3,3 V; módulos I2C com regulador — mas **meça SDA/SCL em repouso** com o módulo ligado e o MCU desligado: pull-up para 5 V no módulo = precisa conversor |

## 3. Pinos proibidos ou restritos por placa (resumo)

| Placa | Nunca / evite | Restrito | Corrente por pino |
|---|---|---|---|
| **ESP32 clássico** (WROOM/WROVER) | **6–11** (flash SPI); 16–17 no WROVER (PSRAM); 1/3 (UART0 do USB) | Strapping **0, 2, 5, 12, 15**: GPIO12 alto no boot escolhe flash 1,8 V e a placa não inicia (recuperável, não "queimou"); 0 em LOW = modo gravação. **34–39 só entrada, sem pull interno.** **ADC2** inutilizável com Wi-Fi → use ADC1 (32–39) | ~20 mA recomendado (força configurável até ~40 mA; datasheet) |
| **ESP32-S3** | 26–32 (flash/PSRAM); **33–37 também** em módulos com PSRAM/flash octal (ex.: N8R8); 19/20 (USB) | Strapping 0, 3, 45, 46. Prefira ADC1 (GPIO 1–10) | ~20 mA |
| **ESP32-C3** | 12–17 (flash SPI); 18/19 (USB) | Strapping 2, 8, 9 (9 em LOW = gravação). ADC1 = GPIO 0–4; evite ADC2 (GPIO 5) | ~20 mA |
| **Arduino Uno/Nano** (ATmega328P, 5V) | 0/1 (serial do USB — atrapalha gravação) | 13 tem LED; A6/A7 do Nano só analógico; A4/A5 = I2C | **20 mA recomendado, 40 mA máximo absoluto**; ~200 mA no total do chip |
| **RP2040 / Pico** | Nada de 5V — **não é tolerante**. Pico: 23, 24, 25, 29 usados na placa (Pico W: ligados ao chip sem fio) | ADC só em 26–28 | 2–12 mA configurável (padrão 4 mA); ~50 mA somando todos |
| **STM32 Blue Pill** (F103C8) | PA13/PA14 (SWD), PA11/PA12 (USB), PC14/PC15 (cristal 32 kHz) | Pinos **FT** aceitam 5 V só em modo digital; PA0–PA7, PB0, PB1 (analógicos), PB5 e PC13–15 **não são FT**. PC13 (LED) fraco: ~3 mA. Clones (CS32, APM32) — confira | ~8 mA para nível garantido; 25 mA absoluto |
| **Raspberry Pi** | 5V em qualquer GPIO; GPIO 0/1 (EEPROM de HAT) | GPIO 2/3 com pull-up fixo de 1,8 kΩ (I2C) | **~16 mA por pino**, ~50 mA somando |

Variantes (S2, C6, H2, Pico 2/RP2350, Jetson) mudam as regras: **confira a folha da variante exata** antes de congelar a pinagem.

## 4. Cargas: corrente, chave, flyback e relé

- GPIO só aciona LED (com resistor) e entrada lógica. LED vermelho em 3,3 V: (3,3 − 2,0) / 0,010 A = 130 Ω → use **150 Ω**. Em 5 V a 15 mA: 200 Ω → **220 Ω**.
- Carga acima de ~10 mA: **transistor ou MOSFET**. NPN (BC337, 2N2222) para até ~300 mA com resistor de base (3,3 V, Ib ≈ 10 mA → 270 Ω). MOSFET canal N **de nível lógico com RDS(on) especificado em VGS = 2,5 V** quando o MCU é 3.3V (AO3400A sim; IRLZ44N é especificado em 4–5 V, em 3,3 V confira a curva). Resistor de gate 100–220 Ω e pull-down 10–100 kΩ.
- Motor DC e passo: **driver** (TB6612FNG: 1,2 A contínuo e 3,2 A de pico por canal, VM até 13,5 V; DRV8833: ~1,5 A RMS, até 10,8 V). L298N funciona, mas perde ~2 V ou mais em calor.
- **Carga indutiva** (motor, relé, bomba, solenoide) chaveada por transistor: **diodo de roda-livre** reverso em paralelo com a carga (1N4007 para relé; Schottky 1N5819 para PWM). Drivers de motor já trazem os diodos.
- **Relé**: prefira módulo com **optoacoplador** e jumper JD-VCC removido, para alimentar a bobina por fonte separada. Módulo "5V ativo em LOW" ligado a MCU 3.3V pode não desligar e injetar corrente no pino — use módulo com disparo em 3,3 V ou transistor. Bobina típica de 5 V: ~70–90 mA, nunca direto no GPIO.
- Servo: alimentação própria de 5–6 V (SG90 passa de 0,6 A travado; MG996R ~2,5 A). Sinal do GPIO, terra comum.

## 5. Desacoplamento e ruído de motor

- [ ] **100 nF cerâmico** entre VCC e GND de cada CI, a menos de 1 cm do pino.
- [ ] **100 nF cerâmico soldado nos terminais de cada motor DC** (escova gera ruído de RF).
- [ ] **Eletrolítico na entrada do driver**: 100–470 µF, tensão nominal ≥ 1,5–2× a da bateria (2S 8,4 V → 16 V ou 25 V).
- [ ] Fios do motor trançados e longe de sinais; terra do motor volta à bateria por caminho próprio (estrela), não pela placa.
- Sintoma clássico: placa reinicia quando o motor arranca = **brownout** (queda abaixo do limite do detector). No ESP32 aparece `BROWNOUT_RST` no reset reason. Corrija a energia (capacitores acima, fonte separada para o motor — `robotics-power-battery` §5 e §6), nunca desligando o detector de brownout.

## 6. Proteção

- [ ] **Fusível no positivo da bateria**, o mais perto possível dela: ~1,25–1,5× a corrente normal máxima e abaixo do que o fio aguenta (lâmina automotiva ou cartucho; PTC é lento, serve só de reforço).
- [ ] **Chave geral** com capacidade em **corrente contínua** (DC) acima do pico; corta motores e eletrônica.
- [ ] **Polaridade invertida**: diodo Schottky em série (simples, perde 0,3–0,5 V) ou **MOSFET P no lado positivo** (quase sem perda). Conectores polarizados (XT30/XT60, JST) que não encaixam invertidos.
- [ ] TVS opcional no trilho do motor, com tensão de standoff acima da tensão da bateria cheia.

## 7. Rede 110/220V — limite da squad

A squad **não orienta montagem com circuito de rede aberto**. Relé de placa hobby "10 A 250 VAC" não tem isolação nem distância de isolamento adequadas para uso real. Caminhos permitidos: **módulo fechado e certificado** (tomada ou interruptor inteligente com certificação, controlado por rede ou por contato seco de baixa tensão) ou **eletricista** fazendo a parte de rede. Fonte de rede só fechada e certificada. Piso de segurança — nunca WAIVED.

## 8. Conferência com multímetro antes de ligar

1. Tudo desligado: **continuidade entre V+ e GND de cada trilho** → apitou contínuo = curto, pare. (Capacitor grande dá um bipe curto e a resistência sobe — normal.)
2. Polaridade do conector da bateria e do driver: vermelho no +, medido, não suposto.
3. Regulador ajustável: **ajuste e meça a saída sem carga antes de ligar qualquer placa**.
4. Primeira energização com **fonte de bancada com limite de corrente** (ou fusível baixo) e só o trilho; meça cada trilho.
5. Nível de sinal: meça a tensão de repouso do pino de dados do módulo (pull-up de I2C, saída TX) **antes** de ligar ao MCU 3.3V.
6. Medir corrente: ponta no borne de A **em série**. Voltou a medir tensão? **Volte a ponta para o borne de V** — esquecer no borne de A causa curto.

O roteiro completo e a tabela `MED-NN` estão em `robotics-bringup-testing`.

## 9. Anti-racionalização

| Desculpa | Realidade |
|---|---|
| "Terra comum resolve o 5V no ESP32" | Terra comum é referência, não muda limiar. 5 V no pino de 3,3 V continua fora do máximo absoluto. |
| "Liguei e não queimou" | Sobreviver não é prova. Dano parcial aparece depois (ADC torto, pino morto). Meça. |
| "O pino aguenta 40 mA, então a placa aguenta 10 pinos × 40 mA" | Máximo por pino não é orçamento da placa. Existe limite total do chip e do regulador. |
| "Todo mundo liga o relé direto no GPIO" | Bobina pede 70–90 mA e devolve pico indutivo. Transistor + diodo ou módulo com opto. |
| "O motor é pequeno, não precisa de capacitor" | Pequeno ainda arranca perto da corrente de travamento e gera ruído. 100 nF no motor, eletrolítico no driver. |
| "Uso o GPIO 12, está livre" | Strapping: alto no boot e a placa não inicia. Use pino da coluna livre (§3). |
| "Desligo o brownout e para de resetar" | Esconde a queda; o chip passa a rodar com tensão errada. Corrija a energia. |
| "É só um teste rápido na tomada" | Rede 110/220V aberta não tem teste rápido. Módulo certificado ou eletricista (§7). |

## 10. Piso de segurança dos gates (nunca WAIVED)

ASIMOV usa esta lista em G1 (compra), G2 (energização) e G3 (gravação com atuador). Achou um → **FAIL**:

1. Li-ion/LiPo sem placa de proteção (BMS), sem fusível no positivo ou sem chave geral; ou carga sem carregador próprio para a química.
2. Sinal de 5V entrando em pino 3.3V sem conversão (§2).
3. Motor, bomba ou servo alimentado pelo regulador da placa ou pelo USB.
4. Firmware que move atuador sem failsafe (comando perdido, sensor inválido ou reset → atuador parado).
5. Rede 110/220V com circuito aberto ou montado pelo usuário sem eletricista (§7).
6. Parada de emergência só por software quando o robô tem força para machucar ou derrubar coisas — precisa de chave física que corta a energia dos atuadores.

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e) — contrato de ligação, anti-racionalização; de ezrover/ESP32-AI-Agent-Skill (MIT, © 2026 Vibe Coder, commit 124d298) — pinos restritos do ESP32 e conversão de nível; e de dbwls99706/ros2-engineering-skills (Apache-2.0, © 2025 dbwls99706, commit d569707) — parada física fora do software.
