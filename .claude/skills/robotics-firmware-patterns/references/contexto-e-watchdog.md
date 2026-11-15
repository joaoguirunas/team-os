# Contexto de execução, watchdog e motivo do reset — exemplos por plataforma

Complemento dos §4 e §5 do `SKILL.md`. Trechos curtos; confirme a versão do core antes de copiar.

## ESP32 (Arduino-ESP32 3.x / ESP-IDF 5.x)

```cpp
#include <Arduino.h>
#include <esp_task_wdt.h>
#include <esp_system.h>
#include "pins.h"

volatile uint32_t pulsos = 0;                       // escrito na ISR, lido no loop
portMUX_TYPE muxPulsos = portMUX_INITIALIZER_UNLOCKED;

void IRAM_ATTR aoPulso() {                          // ISR: só conta, nada de Serial
  portENTER_CRITICAL_ISR(&muxPulsos);
  pulsos++;
  portEXIT_CRITICAL_ISR(&muxPulsos);
}

uint32_t lerEZerarPulsos() {                        // chamada no loop (task)
  portENTER_CRITICAL(&muxPulsos);
  uint32_t n = pulsos; pulsos = 0;
  portEXIT_CRITICAL(&muxPulsos);
  return n;
}

void taskTelemetria(void*) {                        // trabalho lento fora do loop de controle
  for (;;) { /* montar e enviar telemetria */ vTaskDelay(pdMS_TO_TICKS(200)); }
}

void setup() {
  // 1) estado seguro primeiro (motores parados) — ver §5
  Serial.begin(115200);
  Serial.printf("[%lu] I BOOT: reset_reason=%d\n", millis(), (int)esp_reset_reason());
  // ESP_RST_BROWNOUT = energia; ESP_RST_TASK_WDT = algo bloqueou; ESP_RST_PANIC = crash

  attachInterrupt(digitalPinToInterrupt(PIN_ENCODER_ESQ_A), aoPulso, RISING);
  xTaskCreatePinnedToCore(taskTelemetria, "telem", 4096 /* BYTES no ESP-IDF */, nullptr, 1, nullptr, 0);

  // O core 3.x já inicializa o watchdog de tasks: reconfigure em vez de init.
  esp_task_wdt_config_t cfg = { .timeout_ms = 3000, .idle_core_mask = 0, .trigger_panic = true };
  esp_task_wdt_reconfigure(&cfg);
  esp_task_wdt_add(nullptr);                        // inscreve a task do loop()
}

void loop() {
  esp_task_wdt_reset();                             // UM ponto de alimentação, no topo do loop
  uint32_t n = lerEZerarPulsos();
  (void)n;
}
```

- Diferença de API: no core 2.x / IDF 4.x era `esp_task_wdt_init(segundos, panic)`. No IDF 5.x a assinatura recebe `esp_task_wdt_config_t*`.
- ISR registrada no ESP-IDF com `gpio_install_isr_service(ESP_INTR_FLAG_IRAM)`: a ISR e tudo que ela chama em IRAM (`IRAM_ATTR`), constantes em DRAM (`DRAM_ATTR`). Uma função em flash chamada dali derruba a placa durante gravação de flash.
- Inicializadores designados em C++ precisam seguir a ordem da struct (`timeout_ms`, `idle_core_mask`, `trigger_panic`).

## Arduino AVR (Uno, Nano, Mega)

```cpp
#include <avr/wdt.h>
volatile uint16_t pulsos = 0;
void aoPulso() { pulsos++; }                        // pinos 2 e 3 no Uno

void setup() {
  uint8_t motivo = MCUSR; MCUSR = 0;                // leia cedo; alguns bootloaders zeram antes
  wdt_disable();
  // estado seguro primeiro...
  Serial.begin(115200);
  Serial.print(F("I BOOT: MCUSR=0x")); Serial.println(motivo, HEX);  // WDRF=0x08 BORF=0x04 EXTRF=0x02 PORF=0x01
  attachInterrupt(digitalPinToInterrupt(2), aoPulso, RISING);
  wdt_enable(WDTO_1S);
}

void loop() {
  wdt_reset();
  noInterrupts(); uint16_t n = pulsos; pulsos = 0; interrupts();   // 16 bits no AVR de 8 bits: proteja
  (void)n;
}
```

## RP2040 / Pico

- Arduino-Pico: `rp2040.wdt_begin(2000);` e `rp2040.wdt_reset();` no loop.
- Pico SDK: `watchdog_enable(2000, true);` / `watchdog_update();`; no boot, `watchdog_caused_reboot()` diz se foi o watchdog.

## MicroPython

```python
from machine import WDT, reset_cause, Pin
import time
print("I BOOT: reset_cause=", reset_cause())
wdt = WDT(timeout=3000)          # depois de ligado, não desliga
ultimo = time.ticks_ms()
while True:
    wdt.feed()
    agora = time.ticks_ms()
    if time.ticks_diff(agora, ultimo) >= 60:   # ticks_diff trata o estouro
        ultimo = agora
        # ler sensor...
```
Em MicroPython, use `time.ticks_ms()` + `time.ticks_diff()` (nunca subtração direta) e `micropython.schedule()` para tirar trabalho da ISR.
