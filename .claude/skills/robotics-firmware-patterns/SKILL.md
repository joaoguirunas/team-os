---
name: robotics-firmware-patterns
description: "Padrões de firmware para qualquer microcontrolador (AVR, ESP32, RP2040, STM32, MicroPython) — build reproduzível como evidência, pins.h gerado da pinagem FROZEN, loop não bloqueante com máquina de estados, ISR e tasks, failsafe, watchdog, recursos com limite, log e comentário no nível do usuário. Use ao estruturar, escrever ou revisar firmware."
version: "1.0"
updated: "2026-11-14"
---

# Firmware de robô — seguro, não bloqueante, compilado

Ordem de prioridade: **seguro > correto > legível > rápido**. O agente compila (L2); quem grava a placa e manda o log é o usuário. "Compilou" não prova hardware. Exemplos longos por plataforma em `references/contexto-e-watchdog.md` — leia ao escrever ISR, task FreeRTOS ou watchdog (§4, §5).

## 1. Framework e build por placa

Escolha pela placa e pelo nível do usuário; registre em `ADR-NN` com as versões. Sempre fixe versão exata — "a mais nova" quebra o build do mês que vem.

| Placa | Build recomendado | Comando que vira evidência (L2) |
|---|---|---|
| Arduino AVR (Uno, Nano, Mega) | PlatformIO `atmelavr` ou `arduino-cli` (`arduino:avr:uno`) | `pio run -e uno` · `arduino-cli compile --fqbn arduino:avr:uno firmware/` |
| ESP32 e variantes, Arduino | PlatformIO ou `arduino-cli` com `esp32:esp32@3.x` | `pio run -e esp32` · `arduino-cli compile --fqbn esp32:esp32:esp32 firmware/` |
| ESP32 nativo | ESP-IDF 5.x (`idf.py set-target esp32s3`) | `idf.py build` (versão em `idf.py --version` + `dependencies.lock`) |
| RP2040 / Pico | Arduino-Pico (`rp2040:rp2040:rpipico`) ou Pico SDK (CMake) | `arduino-cli compile ...` · `cmake --build build` |
| STM32 | PlatformIO `ststm32` (Arduino ou STM32Cube) ou STM32CubeIDE | `pio run` · build da IDE com log |
| Qualquer, MicroPython | firmware oficial da placa + `mpremote` | `mpy-cross main.py` (só sintaxe) + teste no host |

- **Arduino-ESP32 2.x → 3.x mudou API.** PWM: no 2.x era `ledcSetup(canal, freq, bits)` + `ledcAttachPin(pino, canal)` + `ledcWrite(canal, duty)`; no 3.x é `ledcAttach(pino, freq, bits)` + `ledcWrite(pino, duty)` (canal automático). Timer, watchdog e `analogWrite` também mudaram. Diga sempre para qual core o código foi escrito.
- **PlatformIO e core 3.x:** a plataforma oficial `espressif32` 6.x traz o core 2.x; o core 3.x costuma vir do fork comunitário pioarduino. Confira a situação vigente e registre a URL/versão no `platformio.ini`.
- Sem ferramenta de build no ambiente: marque `NÃO COMPILADO`, diga qual comando o usuário roda e qual saída esperar. Nunca escreva "compila".
- MicroPython não tem compilação real: `mpy-cross` pega erro de sintaxe; lógica pura testa no host com `python3`. `mpremote connect <porta> cp main.py :` é passo do usuário.

## 2. Estrutura do projeto

```
firmware/
  platformio.ini        # placa, framework, plataforma e bibliotecas com versão exata
  include/pins.h        # GERADO de electronics/pinout.md FROZEN vN — nunca editado à mão
  include/secrets.h     # fora do git (.gitignore) — senha, token
  include/secrets.example.h  # versionado, com valores falsos
  src/main.cpp          # setup/loop: só orquestra a máquina de estados
  src/motores.cpp|.h    # um módulo por responsabilidade (BROOKS entrega controle)
  src/rede.cpp|.h       # módulo de MARCONI
  test/                 # funções puras testadas no host (pio test -e native)
```

```cpp
// include/pins.h — GERADO de docs/smart-memory/agents/robotics/electronics/pinout.md
// Pinagem FROZEN v2 em 2026-11-10 · placa ESP32-DevKitC V4 (WROOM-32E)
// NÃO EDITE: pino novo = pinagem nova de VOLTA (robotics-electronics) + regerar.
#pragma once
#include <stdint.h>
constexpr uint8_t PIN_MOTOR_ESQ_PWM = 25;  // PIN-01 TB6612 PWMA
constexpr uint8_t PIN_MOTOR_ESQ_IN1 = 26;  // PIN-02 TB6612 AIN1
constexpr uint8_t PIN_MOTOR_ESQ_IN2 = 27;  // PIN-03 TB6612 AIN2
constexpr uint8_t PIN_DRIVER_STBY   = 33;  // PIN-04 TB6612 STBY (LOW = motores soltos)
constexpr uint8_t PIN_ULTRA_ECHO    = 34;  // PIN-07 HC-SR04 ECHO via divisor 5V→3,3V (só entrada)
```
Em MicroPython o equivalente é `pins.py` com `PIN_MOTOR_ESQ_PWM = 25  # PIN-01`. Diff de `pins.h` contra a pinagem entra no pedido de gate G3.

## 3. Loop não bloqueante e máquina de estados

`delay()` congela tudo: sensor, rede, botão de parada. O loop deve dar uma volta em poucos milissegundos.

- Tempo com `millis()` e **subtração unsigned**: `if (agora - ultimo >= PERIODO)` atravessa o estouro de 32 bits (49,7 dias; `micros()` estoura em ~71,6 min). `if (agora >= proximo)` quebra no estouro.
- Estado explícito com `enum class`, entrada registrada (`entrouMs`), saída por evento **ou por tempo** — todo estado de espera tem timeout.
- Nada escondido: `pulseIn` sem timeout, `while (!Serial)`, `WiFi.begin()` seguido de laço de espera são bloqueios.

```cpp
#include <Arduino.h>
#include "pins.h"
#include "motores.h"    // motoresParar(), motoresAndar(int pct), motoresGirar(int pct)
#include "distancia.h"  // lerDistanciaCm(): -1 = leitura inválida

enum class Estado : uint8_t { PARADO, ANDANDO, DESVIANDO, FALHA };
Estado estado = Estado::PARADO;
uint32_t entrouMs = 0, ultimaLeituraMs = 0;
int distanciaCm = -1;
constexpr uint32_t PERIODO_SENSOR_MS = 60, TEMPO_DESVIO_MS = 800;

void mudarPara(Estado novo) { estado = novo; entrouMs = millis(); }

void setup() {
  motoresParar();                 // estado seguro ANTES de qualquer outra coisa
  Serial.begin(115200);
  mudarPara(Estado::ANDANDO);
}

void loop() {
  uint32_t agora = millis();
  if (agora - ultimaLeituraMs >= PERIODO_SENSOR_MS) { ultimaLeituraMs = agora; distanciaCm = lerDistanciaCm(); }
  switch (estado) {
    case Estado::ANDANDO:
      if (distanciaCm < 0 || distanciaCm < 20) { motoresParar(); mudarPara(Estado::DESVIANDO); }  // inválida = obstáculo
      else motoresAndar(40);
      break;
    case Estado::DESVIANDO:
      motoresGirar(35);
      if (agora - entrouMs >= TEMPO_DESVIO_MS) mudarPara(Estado::ANDANDO);
      break;
    default: motoresParar(); break;  // PARADO e FALHA
  }
}
```

## 4. Contexto de execução

O contexto é parte do tipo: a mesma função não serve para ISR, task e `setup()`.

- **ISR curta:** marca flag, conta pulso, guarda timestamp. Nada de `Serial`, I2C/SPI, `malloc`/`new`, `delay`, `String` ou log dentro dela.
- Variável compartilhada com ISR é `volatile`; leitura de mais de 1 byte no AVR (8 bits) precisa de `noInterrupts()`/`interrupts()` em volta. No ESP32, ler-modificar-escrever pede `portENTER_CRITICAL` (task) / `portENTER_CRITICAL_ISR` (ISR) ou `std::atomic`.
- **ESP32 Arduino:** `loop()` já roda numa task FreeRTOS (core 1, prioridade 1). Task extra com `xTaskCreatePinnedToCore` — no ESP-IDF a pilha é em **bytes** (4096 = 4 KB), não em palavras como no FreeRTOS genérico. Comunicação entre tasks por fila (`xQueueSend`/`xQueueOverwrite`), não por global solta.
- `IRAM_ATTR` na ISR do ESP32. Com `ESP_INTR_FLAG_IRAM` a ISR roda mesmo com a flash desligada (gravação de NVS/OTA) — então **todo** o caminho chamado por ela precisa estar em IRAM e os dados em DRAM.
- Estouro de pilha não se resolve só aumentando: meça (`uxTaskGetStackHighWaterMark`) e ache o buffer grande.

## 5. Failsafe e estado seguro

- [ ] `setup()` começa pelo estado seguro: driver em standby, PWM 0, bomba/relé desligado — antes de Serial, Wi-Fi ou sensor.
- [ ] **O silêncio para o robô:** movimento é habilitado por comando/heartbeat recente; sem comando há mais de N ms (padrão 500 ms, story define) → parar. Nunca "continua o último comando".
- [ ] Sensor travado, fora de faixa ou sem resposta → estado `FALHA` com motor parado e log do motivo.
- [ ] Watchdog é **último recurso** (loop travado), não controle de fluxo: alimente num único ponto do loop, nunca dentro de laço de espera.
- [ ] No boot, leia e logue o motivo do reset (`esp_reset_reason()` no ESP32, `MCUSR` no AVR, `machine.reset_cause()` no MicroPython). Reset por brownout = problema de energia, não de código.
- [ ] Investigue a falha, não o sintoma: watchdog disparando → ache o bloqueio; timeout de I2C → fio, pull-up, endereço, não "espera mais".

## 6. Recursos com limite

Todo recurso tem teto e estado terminal observável: fila (tamanho + política quando enche: descarta o mais velho ou o novo, e conta), retry (backoff exponencial 1 s → 2 s → 4 s… com teto de 30–60 s e contador), payload (tamanho máximo checado antes de copiar), reconexão (nunca laço infinito que trava o loop). NVS/EEPROM/flash têm ~10 mil a 100 mil ciclos de escrita por setor: grave só quando o valor muda e com intervalo mínimo — nunca a cada volta do loop.

## 7. Dono único por atuador

Um atuador, um dono: só o módulo de movimento escreve PWM; rede, comportamento e painel **pedem** (fila ou variável de comando), o dono aplica rampa, limite e failsafe. Tarefas pesadas (log longo, gravação em flash, JSON grande, I2C lento, rede) ficam fora do laço de controle — em outra task ou em fatias pequenas na máquina de estados.

## 8. Log serial

Formato fixo para FARADAY filtrar: `[ms] NIVEL MODULO: mensagem chave=valor`. Ex.: `[12034] W MOTOR: timeout_cmd ms=512 -> PARADO`. Níveis `E` erro, `W` aviso, `I` info, `D` debug (desligável por `#define`). Logue toda mudança de estado, motivo de reset e falha de sensor; não logue a cada volta do loop (o próprio log bloqueia a 115200 baud: ~11,5 bytes/ms).

## 9. Comentário no nível do usuário

O nível vem de `project/conventions.md`. Iniciante → comentário linha a linha em português, dizendo o porquê:

```cpp
const uint8_t LED = PIN_LED_STATUS;  // PIN-09: o pino do LED vem do pins.h, nunca número solto
uint32_t ultimaTroca = 0;            // guarda QUANDO o LED mudou pela última vez (em ms)
bool ligado = false;                 // lembra se o LED está aceso agora

void loop() {
  uint32_t agora = millis();               // quantos ms se passaram desde que a placa ligou
  if (agora - ultimaTroca >= 500) {        // já passou meio segundo? (essa conta funciona mesmo quando millis() zera)
    ultimaTroca = agora;                   // anota o momento da troca
    ligado = !ligado;                      // inverte: aceso vira apagado e vice-versa
    digitalWrite(LED, ligado ? HIGH : LOW);// manda o pino ligar ou desligar
  }                                        // sem delay(): o loop continua livre para ler sensores
}
```
Avançado → comentário só no porquê não óbvio (unidade, origem do número, armadilha de hardware).

## 10. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "`delay(50)` é curtinho" | Continua bloqueando; soma com outros e o failsafe chega tarde. Meça a volta do loop. |
| "`millis()` não estoura" | Estoura em 49,7 dias. Subtração unsigned e teste na borda. |
| "O watchdog resolve o travamento" | Ele esconde. Ache o bloqueio; watchdog só reinicia em estado seguro. |
| "Serial.print na ISR só pra debugar" | Trava ou corrompe. Marque flag e logue no loop. |
| "Compilou, então funciona" | L2 ≠ L3. Funcionar exige o log do usuário com a placa rodando. |
| "Grava a configuração todo loop, é pequena" | Mata a flash em dias. Grave na mudança. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e), johnkozaris/jko-claude-plugins — esp32-cpp (MIT, © 2026 John, commit 47c0ec0) e ezrover/ESP32-AI-Agent-Skill (MIT, © 2026 Vibe Coder, commit 124d298).
