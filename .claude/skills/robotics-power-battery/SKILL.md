---
name: robotics-power-battery
description: "Energia e bateria na squad Robotics — orçamento de energia com pico e travamento, químicas (alcalina, NiMH, Li-ion 18650, LiPo, LiFePO4), Li-ion/LiPo com BMS e carregador certo, regulação LDO × buck × boost com conta de dissipação, picos de motor, triagem 'funciona no USB e não na bateria' e sono profundo real. Use ao escolher bateria e regulador, montar o power-budget ou investigar queda."
version: "1.0"
updated: "2026-11-14"
---

# Robotics Power & Battery — o pico decide, não a média

Metade dos "bugs" de robô amador é energia: reset quando o motor arranca, Wi-Fi que cai na bateria, regulador quente, autonomia que não bate. Esta skill dá o método para VOLTA projetar (`electronics/power-budget.md`) e FARADAY medir. Números são **típicos — o datasheet da peça exata manda**, e a medição na bancada vence os dois.

## 1. Orçamento de energia

Uma linha por carga, em cada trilho:

| Carga | Trilho | Típica | Pico | Travamento (stall) | Ciclo de uso | Fonte do número |
|---|---|---|---|---|---|---|
| ESP32 com Wi-Fi | 3V3 | 100–130 mA | ~240 mA na transmissão (mais o resto: ~350 mA) | — | 100% | datasheet Espressif |
| Motor TT 3–6 V | VM | 150–250 mA | arranque ≈ stall | ~0,8–1,5 A a 6 V | 50% | medir |

- **Média ponderada** = Σ (típica × ciclo de uso) → dá a autonomia.
- **Pico simultâneo** = soma dos picos que podem coincidir (motores arrancando + Wi-Fi transmitindo) → dimensiona regulador, fio, fusível, BMS e conector.
- **Regulador com 30–50% de margem** sobre o pico do trilho (pico 0,36 A → regulador de ≥ 0,5 A real, não "nominal de anúncio").
- **Autonomia** ≈ capacidade útil (Ah × 0,8) ÷ corrente média na bateria. Com regulador chaveado, converta pela potência: I_bat = (V_saída × I_saída) ÷ (V_bat × eficiência ~0,85).
- **Não some o máximo por pino como orçamento da placa.** 40 mA × 20 pinos não é capacidade de nada; o orçamento é o que as cargas realmente puxam.
- Células em série **somam tensão, não capacidade**: 2 × 18650 de 2500 mAh em série = 7,4 V e 2500 mAh.

## 2. Químicas

| Química | Nominal | Cheia | Mínima (corte) | Cuidados e riscos |
|---|---|---|---|---|
| Alcalina AA | 1,5 V | ~1,6 V | ~0,9–1,0 V | Resistência interna alta: cai muito com motor. Vaza. 4 × AA nova = 6,4 V — não ligue direto em entrada de 5 V |
| NiMH AA | 1,2 V | ~1,4 V | 1,0 V | Segura, aguenta corrente. Prefira baixa autodescarga. 4 × NiMH = 4,8 V nominal, ~5,6 V cheia |
| Li-ion 18650 (NMC/NCA) | 3,6–3,7 V | 4,20 V | 2,5–3,0 V (use 3,0 V) | Fogo se furada, curto-circuitada ou sobrecarregada. Corrente máxima varia muito por modelo — datasheet da célula |
| LiPo (bolsa) | 3,7 V | 4,20 V (LiHV: 4,35 V) | 3,0 V | Estufa com abuso. A classificação "C" do anúncio costuma ser otimista. Armazene a ~3,8 V |
| LiFePO4 | 3,2 V | 3,60–3,65 V | 2,5 V | A mais segura das lítio, curva plana. **Carregador de LiFePO4**: um de Li-ion (4,2 V) sobrecarrega |

## 3. Li-ion e LiPo com segurança (piso de segurança)

- [ ] **Proteção (BMS) para a configuração exata**: 1S (3,7 V), 2S (7,4 V, cheia 8,4 V), 3S (11,1 V, cheia 12,6 V). Corrente contínua do BMS acima do pico do robô. Placa 1S comum (DW01 + FS8205) corta só em ~2,4–2,5 V — o firmware deve parar antes (§8).
- [ ] **Balanceamento** em pacote série: BMS com balanceamento ou carregador balanceador pelo conector de balanço (LiPo de aeromodelo).
- [ ] **Carregador próprio para a química e para o número de células.** **TP4056 é só 1S** (4,2 V, 1 A com R_PROG de 1,2 kΩ; reduza para ≤ 0,5–1C da célula). **Nunca carregue células em série sem BMS/balanceador** — e nunca com dois TP4056 na mesma fonte USB ligados a células em série: os terras em comum curto-circuitam uma célula.
- [ ] **Fusível no positivo e chave geral** (`robotics-electrical-safety` §6).
- [ ] Não solde direto na célula (calor danifica): suporte ou pacote soldado a ponto com fita de níquel.
- [ ] Carregar sempre à vista, sobre superfície não inflamável (bolsa anti-chama para LiPo), nunca abaixo de 0 °C. Armazenar a 3,7–3,85 V por célula, em lugar fresco.
- [ ] **Célula estufada, amassada, com capa rasgada ou que esquenta parada = descarte** em ponto de coleta de pilhas. Não furar, não "testar mais uma vez".
- [ ] **Células falsas**: 18650 de verdade vai até ~3500 mAh; "9900 mAh" é golpe. Célula genuína pesa ~45–50 g — muito leve é suspeita. Compre de fonte conhecida (HERON registra o dossiê).

## 4. Regulação

| Tipo | Quando | Limite que importa |
|---|---|---|
| **LDO** (linear) | Pouca diferença de tensão e pouca corrente; menor ruído | Precisa de V_in ≥ V_out + dropout. Dissipa **P = (V_in − V_out) × I** em calor |
| **Buck** (abaixa) | Bateria bem acima da saída (2S → 5 V) | Eficiência 80–92%; ainda tem dropout próprio (LM2596 ~1,5–2 V) |
| **Boost** (eleva) | 1S → 5 V | Sem desligamento: com o boost parado a bateria passa pelo diodo para a saída. Corrente de saída bem menor que o limite da chave (MT3608 "2 A" entrega ~0,5–0,8 A a 5 V partindo de 3,7 V) |
| **Buck-boost** | Bateria cruza a tensão de saída (LiPo 1S 3,0–4,2 V → 3,3 V) | Mais caro; usa toda a carga da célula |

- **Conta de dissipação**: 2S cheia (8,4 V) → 5 V com LDO a 0,5 A: (8,4 − 5) × 0,5 = **1,7 W**. Um TO-220 sem dissipador tem ~65 °C/W → ~110 °C acima do ambiente → desliga por temperatura. Use buck. Um 7805 ainda pede ~2 V de folga: com 2S perto do fim (6,4 V) ele já sai de regulação.
- **LiPo 1S NÃO vai direto em 3,3 V.** Cheia ela tem 4,2 V e o ESP32 aceita no máximo 3,6 V no VDD. Opções: **LDO de baixa queda** com corrente para os picos (AP2112K-3.3 ou ME6211 para ESP32 com Wi-Fi; MCP1700 é de 250 mA, pouco para Wi-Fi) — funciona até a bateria cair a ~3,4–3,5 V; ou **buck-boost** (família TPS63020) para usar até 3,0 V. Exceção: placa com regulador próprio na entrada — a Pico aceita 1,8–5,5 V no VSYS porque tem buck-boost na placa. A regra vale para o pino do chip.
- Ligar LiPo no pino 5V/VIN de uma DevKit passa pelo LDO da placa: com AMS1117 (dropout ~1,1 V) sobra ~3,0 V e caindo — reset no primeiro pico de Wi-Fi.
- **Buck ajustável (LM2596, MP1584, XL4015): ajuste a saída com o multímetro ANTES de ligar a carga.** Módulo novo pode sair de fábrica com qualquer tensão. Depois de ajustar, trave o trimpot (cola) — vibração mexe nele. Se existir versão de saída fixa, prefira.
- Corrente realista: LM2596 "3 A" segura ~1,5–2 A sem dissipador; MP1584 ~2 A contínuo (3 A de pico, entrada até 28 V); XL4015 até 5 A com dissipador (entrada até 36 V).

## 5. Motores e picos

- Motor DC no arranque puxa perto da **corrente de travamento** por dezenas de milissegundos; roda presa puxa isso sem parar. Dimensione driver, fio, fusível e BMS por isso.
- **Capacitor de reserva** na entrada do driver: 470–1000 µF, tensão ≥ 1,5–2× a da bateria, perto do driver.
- **Fonte dos motores separada da lógica**, terra comum. Lógica atrás de um buck próprio; motor direto da bateria pelo driver. Nunca motor, bomba ou servo pelo regulador da placa ou pelo USB (USB 2.0 entrega 500 mA; USB 3.0, 900 mA).
- Servo: fonte de 5–6 V com ≥ 1 A por servo pequeno (SG90 passa de 0,6 A travado) e 2–3 A por MG996R (~2,5 A travado). Vários servos movendo juntos = soma dos picos.
- Motor acima da tensão nominal (TT de 6 V em 2S de 8,4 V): limite o PWM (≤ ~70%) ou use buck para o motor — e lembre que o travamento a 8,4 V é maior.

## 6. Triagem: "funciona no USB e não na bateria"

"Funciona no USB" é evidência sobre o **caminho de energia**, não sobre o código. Na ordem:

1. **Pico de Wi-Fi** (~240 mA no ESP32 transmitindo) é o primeiro suspeito: regulador fraco, LDO sem folga, fio fino ou bateria fraca derrubam o 3V3 na hora de conectar.
2. **Meça na fase que falha**, não em repouso: 3V3 e entrada do regulador enquanto conecta no Wi-Fi e enquanto o motor arranca (multímetro no modo MIN/MAX ou osciloscópio).
3. **Leia o reset reason** no boot (`esp_reset_reason()` no ESP32; `BROWNOUT_RST` = queda; registro de causa de reset no AVR/STM32). Brownout → energia. Watchdog → firmware travou (ou queda parcial).
4. Ordem de suspeitos: tensão da bateria sob carga → dropout do regulador → fio/conector (queda em mV × corrente) → motor e lógica no mesmo trilho → capacitores ausentes.
5. Uma mudança por vez; registre em `bench/falhas.md`.

## 7. Sono profundo: chip × placa de desenvolvimento

O "10 µA em deep sleep" do ESP32 é **do chip** (RTC ligado). Uma DevKit dorme em **5–15 mA**: LDO AMS1117 (~5 mA quiescente), ponte USB-serial, LED de energia. Arduino Uno idem (~30–50 mA "dormindo"; o ATmega328P sozinho em power-down fica abaixo de 1 µA). Para bateria de meses: módulo sem placa ou placa feita para baixo consumo, LDO de baixa corrente quiescente (MCP1700 ~1,6 µA, HT7333 ~4 µA), sem LED, sensores desligados por MOSFET, divisor de bateria de alto valor (100 kΩ + 100 kΩ em 8,4 V = 42 µA contínuos). **Meça a corrente de sono na placa real** antes de prometer autonomia.

## 8. Exemplo completo: robô 2WD

Peças: 2 × 18650 em série (2500 mAh) + **BMS 2S** com balanceamento (≥ 5 A contínuo) + fusível de 5 A + chave geral → TB6612FNG (VM direto da bateria, 6,0–8,4 V) + 2 motores TT; buck MP1584 ajustado em 5,0 V → pino 5V da ESP32 DevKit; HC-SR04P e lógica do TB6612 no 3V3 (eco já sai em 3,3 V, sem divisor).

| Carga | Trilho | Típica | Pico | Ciclo |
|---|---|---|---|---|
| ESP32 DevKit com Wi-Fi | 5V (LDO da placa) | 130 mA | 350 mA | 100% |
| HC-SR04P | 3V3 | ~3 mA (varia por versão) | 15 mA | 100% |
| TB6612 lógica + LED | 3V3 | 5 mA | 5 mA | 100% |
| 2 × motor TT (PWM ≤ 70%) | bateria | 2 × 0,25 A | 2 × ~1,5 A (stall) | 50% |

- Trilho 5V: ~140 mA típico, ~370 mA pico → MP1584 (~2 A real) tem margem de sobra. Na bateria: 5 × 0,14 ÷ (7,4 × 0,85) ≈ **0,11 A**.
- Motores: 0,5 A × 50% = **0,25 A** médios; pico ~3 A + lógica → fusível de 5 A e BMS ≥ 5 A; fio de 20 AWG na bateria e nos motores. Travamento de 1,5 A passa do contínuo do TB6612 (1,2 A): o firmware detecta roda presa e corta (BROOKS).
- Média na bateria ≈ 0,36 A. Capacidade útil 2,5 Ah × 0,8 = 2,0 Ah → **~5,5 h** a 50% de movimento; **~3,3 h** andando o tempo todo (0,61 A). Aproximado: confirme com a medição de FARADAY.
- Corte por firmware: aviso a 7,0 V (3,5 V/célula sob carga), parada a 6,6 V (3,3 V/célula). O BMS é a última linha. Leitura por divisor 100 kΩ/33 kΩ no ADC1: 8,4 V → 2,08 V no pino.
- Capacitores: 470 µF/16 V no VM do TB6612, 100 nF em cada motor, 100 nF no HC-SR04P.

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e) — orçamento de energia, triagem de energia em campo e escolha de bateria (com o erro do LiPo 1S direto em 3,3 V corrigido); e de johnkozaris/jko-claude-plugins, plugin esp32-cpp (MIT, © 2026 John, commit 47c0ec0) — energia medida na placa real e reset reason antes de mexer em watchdog.
