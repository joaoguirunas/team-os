# Pinos por placa — referência detalhada

Complementa o §3 do `SKILL.md`. Use ao montar `electronics/pinout.md` (VOLTA), ao gerar e conferir o `pins.h`/`pins.py` (ADA) e no gate G2/G3 (ASIMOV). Valores típicos de placa de desenvolvimento comum; **a folha de dados do módulo e o esquema da placa exata mandam**. Placa não listada ou variante diferente = status `profile-gap`: pesquise (HERON) antes de escolher pino.

## ESP32 clássico (ESP32-WROOM-32 / WROVER, DevKitC, DOIT DevKit v1)

| Categoria | GPIO | Regra |
|---|---|---|
| Livres para quase tudo | 4, 13, 14, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33 | 16/17 só no WROOM (no WROVER são da PSRAM). 4, 13, 14, 25–27 são ADC2 |
| Flash SPI | 6, 7, 8, 9, 10, 11 | **Nunca.** Usar trava o chip na hora |
| Strapping | 0, 2, 5, 12, 15 | Podem ser usados depois do boot, **sem carga que force o nível durante o boot** |
| GPIO0 | — | Pull-up interno; LOW no boot = modo gravação. Botão BOOT da placa |
| GPIO2 | — | Precisa ficar LOW ou solto para gravar; muitas placas têm LED nele |
| GPIO12 (MTDI) | — | **Alto no boot seleciona flash de 1,8 V** → módulo com flash de 3,3 V não inicia. Recuperável: tire o que puxa o pino para cima. (Queimar eFuse fixando 3,3 V é irreversível — só com decisão registrada) |
| GPIO15 (MTDO) | — | LOW no boot silencia o log de inicialização |
| Ativos no boot | 1, 3, 5, 14, 15 | Emitem nível alto ou PWM durante o boot — **não use para acionar atuador** sem pull que segure a carga desligada |
| UART0 | 1 (TX), 3 (RX) | Ligados ao conversor USB; usar atrapalha gravação e log |
| Só entrada | 34, 35, 36 (VP), 39 (VN) | Não têm saída nem pull-up/pull-down interno → botão precisa de resistor externo |
| ADC1 | 32–39 | Funciona com Wi-Fi ligado. Faixa útil com atenuação 11 dB ≈ 0,15–2,45 V (linear); calibre |
| ADC2 | 0, 2, 4, 12–15, 25–27 | **Indisponível com Wi-Fi ativo** |
| I2C padrão | 21 (SDA), 22 (SCL) | Remapeável pela matriz de GPIO |

## ESP32-S3 (DevKitC-1, módulos N8, N8R2, N8R8, N16R8)

| Categoria | GPIO | Regra |
|---|---|---|
| Flash/PSRAM | 26–32 | Nunca |
| Flash/PSRAM octal | 33–37 | Ocupados nos módulos com PSRAM ou flash octal (R8, N8R8, N16R8) — confira o sufixo do módulo |
| Strapping | 0, 3, 45, 46 | 0 LOW = gravação; 45 alto escolhe 1,8 V para o VDD_SPI (como o GPIO12 do clássico); 46 sem carga no boot |
| USB nativo | 19 (D−), 20 (D+) | Reservados se usar USB nativo/JTAG |
| UART0 | 43 (TX), 44 (RX) | Log e gravação pela ponte serial |
| LED RGB da DevKitC-1 | 48 (v1.0) ou 38 (v1.1) | Confira a revisão |
| ADC1 | 1–10 | Prefira; ADC2 (11–20) disputa com Wi-Fi |

## ESP32-C3 (DevKitM-1, SuperMini, XIAO ESP32C3)

| Categoria | GPIO | Regra |
|---|---|---|
| Flash SPI | 12–17 | Nunca (inclusive nos chips com flash interna) |
| Strapping | 2, 8, 9 | 9 LOW no boot = gravação (botão BOOT); mantenha 2 e 8 sem carga puxando para LOW no boot. 8 costuma ter LED |
| USB nativo | 18 (D−), 19 (D+) | Reservados |
| UART0 | 20 (RX), 21 (TX) | Log |
| ADC1 | 0–4 | Use estes; ADC2 (GPIO 5) é pouco confiável |

## Arduino Uno R3 / Nano (ATmega328P, lógica 5 V)

- 0/1: serial do USB — ocupá-los atrapalha gravação e o Serial Monitor.
- 13: LED da placa (no Nano ligado direto, afeta leitura como entrada).
- Interrupção externa só em 2 e 3. PWM em 3, 5, 6, 9, 10, 11. A biblioteca Servo desliga o PWM de 9 e 10; `tone()` usa o timer de 3 e 11.
- 10 (SS) precisa ser saída quando a placa é mestre SPI. A4/A5 = I2C. Nano: A6/A7 só leitura analógica.
- Corrente: **20 mA recomendado, 40 mA máximo absoluto por pino**, ~200 mA total no VCC/GND do chip.
- Lógica 5 V: o problema aqui é o sentido inverso — saída 5 V do Uno entrando em módulo 3,3 V precisa de conversão (§2).
- Uno R4 (Renesas RA4M1), Mega, Leonardo têm pinagem e limites diferentes — confira.

## RP2040 / Raspberry Pi Pico e Pico W

- GPIO 3,3 V, **não tolerante a 5 V** (máximo absoluto ≈ IOVDD + 0,5 V).
- Pico: GP23 (modo do regulador), GP24 (detecção de VBUS), GP25 (LED), GP29 (ADC de VSYS/3) — internos, não expostos.
- Pico W: GP23, 24, 25 e 29 ligados ao chip sem fio; o LED fica no chip sem fio (`WL_GPIO0`).
- ADC em GP26–28, referência de 3,3 V.
- Corrente: força de saída configurável 2/4/8/12 mA (padrão 4 mA); ~50 mA somando todos os pinos.
- VSYS aceita 1,8–5,5 V (regulador buck-boost na placa); o pino 3V3 é saída, não entrada de bateria.
- Pico 2 (RP2350): GPIO tolerante a 5 V só com IOVDD ligado e errata nos pull-downs internos (E9) — confira a folha antes de reaproveitar regras do RP2040.

## STM32F103C8 "Blue Pill"

- 3,3 V. Pinos **FT** aceitam 5 V **apenas em modo digital**; PA0–PA7, PB0, PB1, PB5 e PC13–PC15 não são FT.
- Reservados: PA13/PA14 (SWD — perder = gravação só com BOOT0), PA11/PA12 (USB), PC14/PC15 (cristal de 32 kHz), PB2 (BOOT1).
- PA15, PB3, PB4 começam como JTAG; só ficam livres desabilitando o JTAG (mantendo o SWD).
- PC13 (LED): corrente baixa (~3 mA), velocidade máxima 2 MHz.
- Corrente: ~8 mA para manter o nível garantido; 25 mA máximo absoluto por pino.
- Muitas placas vêm com chip clone (CS32F103, APM32F103) — o ID do chip muda e algumas ferramentas recusam. Registre qual chegou.

## Raspberry Pi (3, 4, 5) e Jetson

- GPIO 3,3 V, **nada de 5 V**. ~16 mA por pino, ~50 mA somando (orientação histórica da fundação).
- GPIO 0/1: EEPROM de identificação de HAT — evite. GPIO 2/3: I2C com pull-up fixo de 1,8 kΩ para 3,3 V. GPIO 14/15: UART (console serial por padrão).
- Pino 5V do header vem direto da alimentação da placa: nunca motor ou servo por ele.
- Pi 5: GPIO passa pelo chip RP1 — `RPi.GPIO` não funciona; use `gpiozero`/`lgpio`.
- Jetson (Nano, Orin Nano): header de 3,3 V com corrente baixa; função de cada pino configurada pelo Jetson-IO — use buffer/driver para qualquer carga e confira o manual da carrier board.
