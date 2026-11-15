# Painel web, reconexão e ESPHome — exemplos completos

Complemento dos §2, §4 e §7 do `SKILL.md`. Versões de biblioteca abaixo são exemplo: fixe a que você conferiu no registry e registre em `ADR-NN`.

## platformio.ini

```ini
[env:esp32]
platform = espressif32@6.9.0        ; plataforma oficial = core 2.x; para core 3.x, release fixo do pioarduino
board = esp32dev
framework = arduino
board_build.filesystem = littlefs
monitor_speed = 115200
lib_deps =
    ESP32Async/AsyncTCP @ 3.3.2
    ESP32Async/ESPAsyncWebServer @ 3.6.0
```

## Firmware — AP + WebSocket + timeout (ESP32, Arduino)

```cpp
#include <Arduino.h>
#include <WiFi.h>
#include <LittleFS.h>
#include <ESPAsyncWebServer.h>
#include "secrets.h"        // AP_SSID, AP_SENHA — fora do git; ver secrets.example.h
#include "motores.h"        // motoresParar(), motoresAplicar(int v, int w) — dono do motor (BROOKS)

struct Comando { int8_t v; int8_t w; uint32_t t; };
constexpr uint32_t TIMEOUT_CMD_MS = 500;
QueueHandle_t filaCmd;                     // tamanho 1: guarda só o comando mais recente
Comando ultimo{0, 0, 0};
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

void onWs(AsyncWebSocket*, AsyncWebSocketClient*, AwsEventType tipo, void* arg, uint8_t* data, size_t len) {
  if (tipo != WS_EVT_DATA) return;         // roda na task do AsyncTCP, não no loop
  AwsFrameInfo* info = (AwsFrameInfo*)arg;
  if (!info->final || info->index != 0 || info->len != len || info->opcode != WS_TEXT || len > 32) return;
  char buf[33]; memcpy(buf, data, len); buf[len] = '\0';
  int v = 0, w = 0;
  if (strcmp(buf, "STOP") != 0 && (sscanf(buf, "M %d %d", &v, &w) != 2 || abs(v) > 100 || abs(w) > 100)) return;
  Comando c{ (int8_t)v, (int8_t)w, millis() };
  xQueueOverwrite(filaCmd, &c);
}

void setup() {
  motoresParar();                                        // estado seguro primeiro
  Serial.begin(115200);
  filaCmd = xQueueCreate(1, sizeof(Comando));
  if (!LittleFS.begin()) Serial.println("[0] E WEB: littlefs_falhou (rode uploadfs)");
  if (!WiFi.softAP(AP_SSID, AP_SENHA)) Serial.println("[0] E REDE: softap_falhou (senha >= 8?)");
  ws.onEvent(onWs);
  server.addHandler(&ws);
  server.serveStatic("/", LittleFS, "/").setDefaultFile("index.html");
  server.begin();
}

void loop() {
  Comando c;
  if (xQueueReceive(filaCmd, &c, 0) == pdTRUE) ultimo = c;
  if (millis() - ultimo.t > TIMEOUT_CMD_MS) motoresParar();   // o silêncio para o robô
  else motoresAplicar(ultimo.v, ultimo.w);                    // rampa e limite ficam no módulo de motor
  ws.cleanupClients();                                        // limita clientes esquecidos
}
```

## data/index.html (mínimo)

```html
<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{font-family:sans-serif;margin:0;padding:16px}#parar{position:fixed;bottom:16px;left:16px;right:16px;
height:80px;font-size:28px;background:#c00;color:#fff;border:0;border-radius:12px}.b{width:30%;height:70px;font-size:22px}</style>
<p id="st">desconectado</p>
<button class="b" data-v="60" data-w="0">Frente</button>
<button class="b" data-v="0" data-w="50">Girar</button>
<button class="b" data-v="-40" data-w="0">Ré</button>
<button id="parar">PARAR</button>
<script>
const st = document.getElementById("st"), parar = document.getElementById("parar");
let ws, atual = "M 0 0";
function abrir(){ ws = new WebSocket(`ws://${location.host}/ws`);
  ws.onopen = () => st.textContent = "conectado"; ws.onclose = () => { st.textContent = "desconectado"; setTimeout(abrir, 1000); }; }
abrir();
setInterval(() => { if (ws.readyState === 1) ws.send(atual); }, 100);      // heartbeat a 10 Hz
document.querySelectorAll(".b").forEach(b => {
  b.onpointerdown = () => atual = `M ${b.dataset.v} ${b.dataset.w}`;
  b.onpointerup = b.onpointerleave = () => atual = "M 0 0"; });
parar.onpointerdown = () => { atual = "M 0 0"; if (ws.readyState === 1) ws.send("STOP"); };
</script>
```

## Reconexão STA com backoff (sem bloquear)

```cpp
enum class Rede : uint8_t { DESCONECTADO, CONECTANDO, CONECTADO };
Rede rede = Rede::DESCONECTADO;
uint32_t redeMs = 0, atrasoMs = 1000;
uint16_t tentativas = 0;

void redeCiclo() {                                  // chamada a cada volta do loop
  uint32_t agora = millis();
  switch (rede) {
    case Rede::DESCONECTADO:
      if (agora - redeMs >= atrasoMs) {
        WiFi.begin(WIFI_SSID, WIFI_SENHA);          // não bloqueia
        rede = Rede::CONECTANDO; redeMs = agora; tentativas++;
        Serial.printf("[%lu] I REDE: tentativa=%u atraso_ms=%lu\n", agora, tentativas, atrasoMs);
      }
      break;
    case Rede::CONECTANDO:
      if (WiFi.status() == WL_CONNECTED) { rede = Rede::CONECTADO; atrasoMs = 1000; tentativas = 0; }
      else if (agora - redeMs >= 10000) {           // desistiu desta tentativa
        WiFi.disconnect(); rede = Rede::DESCONECTADO; redeMs = agora;
        atrasoMs = (atrasoMs >= 30000) ? 60000 : atrasoMs * 2;   // 1, 2, 4… até o teto de 60 s
      }
      break;
    case Rede::CONECTADO:
      if (WiFi.status() != WL_CONNECTED) { rede = Rede::DESCONECTADO; redeMs = agora; }
      break;
  }
}
```
No `setup()`: `WiFi.mode(WIFI_STA); WiFi.setAutoReconnect(false);` para a máquina acima ser a única dona da reconexão.

## ESPHome — dispositivo da casa (bomba de irrigação com limite de tempo)

```yaml
# robo-jardim.yaml — segredos em secrets.yaml (fora do git)
esphome:
  name: jardim-bomba
esp32:
  board: esp32dev
  framework:
    type: esp-idf
logger:
api:
  encryption:
    key: !secret api_chave        # base64 de 32 bytes
  on_client_disconnected:
    - switch.turn_off: bomba
ota:
  - platform: esphome
    password: !secret ota_senha
wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_senha
  ap:
    password: !secret ap_reserva_senha   # AP de reserva também com senha
captive_portal:
switch:
  - platform: gpio
    pin: GPIO26                   # PIN-05 relé da bomba (via módulo com transistor)
    id: bomba
    name: "Bomba"
    restore_mode: ALWAYS_OFF      # liga a placa sempre com a bomba desligada
    on_turn_on:
      - delay: 5min               # limite no próprio dispositivo, não só na automação
      - switch.turn_off: bomba
```
Para comando contínuo (tipo heartbeat), use `script` com `mode: restart` contendo `delay: 500ms` + desligar, executado a cada comando recebido.

Automação no Home Assistant (exemplo):
```yaml
automation:
  - alias: "Regar ao amanhecer"
    triggers:
      - trigger: sun
        event: sunrise
    actions:
      - action: switch.turn_on
        target:
          entity_id: switch.jardim_bomba_bomba
```
A sintaxe de automações mudou ao longo das versões do Home Assistant (`trigger:`/`platform:` → `triggers:`/`trigger:`, `service:` → `action:`); confira a da instalação do usuário.
