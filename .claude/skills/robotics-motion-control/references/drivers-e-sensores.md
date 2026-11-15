# Drivers e sensores — trechos de referência

Complemento dos §2 e §3 do `SKILL.md`. Pinos sempre de `pins.h` (com `PIN-NN`); confirme a versão do core antes de copiar.

## TB6612FNG no ESP32 (Arduino-ESP32 3.x)

```cpp
#include <Arduino.h>
#include "pins.h"
constexpr uint32_t PWM_FREQ = 20000;   // 20 kHz: fora da faixa audível
constexpr uint8_t  PWM_BITS = 10;      // duty de 0 a 1023

void driverIniciar() {
  pinMode(PIN_DRIVER_STBY, OUTPUT);   digitalWrite(PIN_DRIVER_STBY, LOW);   // motores soltos até o fim do setup
  pinMode(PIN_MOTOR_ESQ_IN1, OUTPUT); pinMode(PIN_MOTOR_ESQ_IN2, OUTPUT);
  ledcAttach(PIN_MOTOR_ESQ_PWM, PWM_FREQ, PWM_BITS);   // core 3.x; no 2.x: ledcSetup + ledcAttachPin
  ledcWrite(PIN_MOTOR_ESQ_PWM, 0);                     // core 3.x escreve pelo PINO; no 2.x, pelo canal
}

void motorEsq(float pct) {             // -100..100
  bool frente = pct >= 0;
  digitalWrite(PIN_MOTOR_ESQ_IN1, frente ? HIGH : LOW);
  digitalWrite(PIN_MOTOR_ESQ_IN2, frente ? LOW : HIGH);
  uint32_t duty = (uint32_t)(fabsf(pct) * ((1u << PWM_BITS) - 1) / 100.0f);
  ledcWrite(PIN_MOTOR_ESQ_PWM, duty);
}

void driverFrear() {                    // IN1=IN2=HIGH com PWM alto = freio
  digitalWrite(PIN_MOTOR_ESQ_IN1, HIGH); digitalWrite(PIN_MOTOR_ESQ_IN2, HIGH);
  ledcWrite(PIN_MOTOR_ESQ_PWM, (1u << PWM_BITS) - 1);
}
```
No AVR, troque `ledcAttach/ledcWrite` por `analogWrite(pino, 0..255)` em pino com PWM (Uno: 3, 5, 6, 9, 10, 11).

## Ultrassom sem bloquear (por interrupção)

```cpp
#ifndef IRAM_ATTR
#define IRAM_ATTR            // AVR e outros não usam
#endif
volatile uint32_t ecoInicioUs = 0, ecoDuracaoUs = 0;
volatile bool ecoPronto = false;

void IRAM_ATTR aoEco() {                    // attachInterrupt(..., aoEco, CHANGE)
  if (digitalRead(PIN_ULTRA_ECHO)) ecoInicioUs = micros();
  else { ecoDuracaoUs = micros() - ecoInicioUs; ecoPronto = true; }
}

// Chamada a cada 60 ms pela máquina de estados. Devolve cm ou -1 (inválido).
int ultrassomCiclo() {
  noInterrupts(); bool pronto = ecoPronto; uint32_t dur = ecoDuracaoUs; ecoPronto = false; interrupts();
  digitalWrite(PIN_ULTRA_TRIG, HIGH); delayMicroseconds(10); digitalWrite(PIN_ULTRA_TRIG, LOW);  // dispara o próximo
  if (!pronto || dur == 0 || dur > 25000) return -1;   // sem eco ou além de ~4 m = inválido
  return (int)(dur / 58);
}
```
A leitura devolvida é a do disparo anterior (60 ms de atraso): registre esse atraso em `control/tuning.md`. Mediana de 3 para filtrar.

## Vários VL53L0X no mesmo barramento

Todos nascem em 0x29. No `setup()`: todos os XSHUT em LOW → sobe o XSHUT do 1º, espera ~10 ms, inicializa e troca o endereço (biblioteca Pololu: `setAddress(0x30)`) → repete com o 2º (`0x31`)… O endereço novo some ao desligar, então a sequência roda em todo boot. Defina `setTimeout(...)` e trate `timeoutOccurred()` como leitura inválida.

## Encoder de quadratura com PCNT (ESP-IDF 5.x, vale no Arduino-ESP32 3.x)

```cpp
#include "driver/pulse_cnt.h"
pcnt_unit_handle_t encEsq = nullptr;

void encoderIniciar(int pinoA, int pinoB) {
  pcnt_unit_config_t uc = { .low_limit = -30000, .high_limit = 30000 };
  ESP_ERROR_CHECK(pcnt_new_unit(&uc, &encEsq));
  pcnt_glitch_filter_config_t fc = { .max_glitch_ns = 1000 };          // ignora ruído < 1 µs
  ESP_ERROR_CHECK(pcnt_unit_set_glitch_filter(encEsq, &fc));
  pcnt_chan_config_t ca = { .edge_gpio_num = pinoA, .level_gpio_num = pinoB };
  pcnt_chan_config_t cb = { .edge_gpio_num = pinoB, .level_gpio_num = pinoA };
  pcnt_channel_handle_t chA = nullptr, chB = nullptr;
  ESP_ERROR_CHECK(pcnt_new_channel(encEsq, &ca, &chA));
  ESP_ERROR_CHECK(pcnt_new_channel(encEsq, &cb, &chB));
  pcnt_channel_set_edge_action(chA, PCNT_CHANNEL_EDGE_ACTION_DECREASE, PCNT_CHANNEL_EDGE_ACTION_INCREASE);
  pcnt_channel_set_level_action(chA, PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE);
  pcnt_channel_set_edge_action(chB, PCNT_CHANNEL_EDGE_ACTION_INCREASE, PCNT_CHANNEL_EDGE_ACTION_DECREASE);
  pcnt_channel_set_level_action(chB, PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE);
  ESP_ERROR_CHECK(pcnt_unit_enable(encEsq));
  ESP_ERROR_CHECK(pcnt_unit_clear_count(encEsq));
  ESP_ERROR_CHECK(pcnt_unit_start(encEsq));
}

int encoderDelta() {                         // a cada tick: lê e zera (4 contagens por ciclo)
  int n = 0; pcnt_unit_get_count(encEsq, &n); pcnt_unit_clear_count(encEsq); return n;
}
```
O contador volta a zero nos limites: leia a cada tick (20 ms) bem antes de chegar lá, ou use `flags.accum_count` com watch points nos limites. No Arduino, a biblioteca ESP32Encoder faz o mesmo por cima do PCNT; confira se a versão dela suporta o core 3.x. Encoder de 5 V em ESP32 precisa de conversão de nível.

## IMU — calibração mínima do giroscópio

No boot, robô parado: média de 500 leituras do giroscópio (≈1 s) = bias; subtraia em toda leitura. Se o desvio padrão durante a média for alto, o robô estava se mexendo: repita e logue `W IMU: calib_instavel`. Yaw só por giroscópio deriva alguns graus por minuto — registre a deriva medida.
