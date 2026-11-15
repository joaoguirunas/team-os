---
name: robotics-iot-connectivity
description: "Conectividade de robôs e dispositivos IoT — escolha do canal (Wi-Fi AP/STA, BLE, ESP-NOW, MQTT, LoRa), painel web local com WebSocket e botão de parada, failsafe quando a conexão cai, reconexão com backoff, MQTT com LWT, OTA com senha e rollback, ESPHome e Home Assistant, segurança do dispositivo. Use ao ligar robô ao celular, à casa ou à rede."
version: "1.0"
updated: "2026-11-14"
---

# Conectividade — perder o sinal é o caso normal

Ordem: **seguro > previsível > responsivo > bonito**. Todo comando remoto tem timeout que para o atuador; nenhum segredo vai para o repositório. Código completo do painel (firmware + HTML) e o YAML do ESPHome em `references/painel-e-esphome.md` — leia ao implementar §2 ou §7.

## 1. Escolha do canal

| Canal | Quando usar | Cuidado |
|---|---|---|
| Wi-Fi AP (a placa cria a rede) | controle pelo celular em qualquer lugar, sem roteador; IP fixo 192.168.4.1 | celular perde a internet enquanto conectado; poucos clientes (~4 por padrão) |
| Wi-Fi STA (rede da casa) | Home Assistant, MQTT, telemetria, OTA | depende do roteador; IP por DHCP — reserve no roteador ou use mDNS (`robo.local`) |
| AP+STA | painel local de reserva quando a rede da casa some | mesmo canal de rádio nos dois; mais consumo |
| BLE | controle de perto com app/celular, baixo consumo | ~10 m; ESP32-S2 não tem BLE; no ESP32 clássico, Classic BT só se precisar de controle de videogame antigo |
| ESP-NOW | controle remoto ESP32 ↔ ESP32 sem roteador, baixa latência | 250 bytes por pacote (ESP-NOW v1; a v2 do ESP-IDF recente aceita mais — confira os dois lados); criptografia própria com PMK/LMK; sem IP |
| MQTT (sobre STA) | casa conectada, vários dispositivos, Home Assistant | precisa de broker; não serve para joystick de baixa latência |
| LoRa | sensor longe (centenas de m a km), poucos bytes por minuto | não serve para controle em tempo real; regras de ciclo de trabalho e banda (AU915, 915–928 MHz, no Brasil) |

Registre a escolha, endereços, portas e tópicos em `connectivity/interfaces.md` e a decisão em `ADR-NN`.

## 2. Painel web local

- Arquivos (`index.html`, `app.js`) servidos da flash (LittleFS) — sem internet, sem CDN. Envio da pasta `data/` é passo do usuário (`pio run -t uploadfs`).
- Comando por **WebSocket** (latência de dezenas de ms); HTTP por clique é lento e não detecta queda.
- **Botão PARAR sempre visível**, grande, fora de qualquer aba; soltar o joystick manda zero.
- O painel manda o comando atual a 5–10 Hz enquanto houver toque (é o heartbeat); o firmware valida e entrega ao dono do motor por fila de 1 posição.
- Bibliotecas: `ESPAsyncWebServer` + `AsyncTCP` — o repositório original (me-no-dev) parou; use o fork mantido (ESP32Async) com versão fixada e compatível com o core em uso. Alternativa síncrona: `WebServer` do core + `WebSockets` (links2004) na porta 81. Callbacks do servidor assíncrono rodam em **outra task**: nada de mexer no motor dali.

Trecho central (o completo está na referência):
```cpp
void onWs(AsyncWebSocket*, AsyncWebSocketClient*, AwsEventType tipo, void* arg, uint8_t* data, size_t len) {
  if (tipo != WS_EVT_DATA) return;
  AwsFrameInfo* info = (AwsFrameInfo*)arg;
  if (!info->final || info->index != 0 || info->len != len || info->opcode != WS_TEXT || len > 32) return;
  char buf[33]; memcpy(buf, data, len); buf[len] = '\0';
  int v = 0, w = 0;
  if (strcmp(buf, "STOP") != 0 && (sscanf(buf, "M %d %d", &v, &w) != 2 || abs(v) > 100 || abs(w) > 100)) return;
  Comando c{ (int8_t)v, (int8_t)w, millis() };
  xQueueOverwrite(filaCmd, &c);     // só o mais recente; o loop aplica com rampa e timeout
}
```

## 3. Failsafe de conexão

- Timeout de comando padrão **500 ms** (story pode mudar): `millis() - ultimoCmd.t > 500` → motor parado. Com envio a 10 Hz, são ~5 pacotes perdidos seguidos.
- O silêncio para o robô: cliente fechou a aba, Wi-Fi caiu, celular bloqueou a tela → para. Nunca "mantém o último comando".
- Reconectar **não** retoma o movimento: exige comando novo do usuário.
- Indicador de estado (LED ou painel): ex. LED piscando lento = sem rede, rápido = conectado sem cliente, aceso = cliente ativo. Documente em `interfaces.md`.
- [ ] Teste registrado: desligar o Wi-Fi do celular com o robô suspenso e motor girando → parou em ≤ timeout (MED-NN).

## 4. Reconexão sem bloquear

Máquina de estados de rede chamada a cada volta do loop (ou task própria): `DESCONECTADO → CONECTANDO (WiFi.begin, guarda o instante) → CONECTADO`; se não conectar em 10 s, volta a `DESCONECTADO` e espera `atraso` antes de tentar de novo, com `atraso` dobrando de 1 s até o teto de 60 s e zerado ao conectar. Logue cada tentativa com o contador. Nunca `while (WiFi.status() != WL_CONNECTED) delay(500);` — isso trava o failsafe.

## 5. MQTT

- Broker **local** (Mosquitto no Home Assistant ou num Pi) com usuário e senha. Nunca broker público com dado real ou comando: tudo ali é legível e publicável por qualquer um.
- Tópicos: `casa/robo/{id}/cmd`, `casa/robo/{id}/estado`, `casa/robo/{id}/telemetria`, `casa/robo/{id}/disponibilidade`.
- QoS 0 para telemetria frequente; QoS 1 para comando/estado que não pode sumir (pode chegar repetido: comando idempotente).
- **Retain com cuidado:** sim para `estado` e `disponibilidade`; **nunca** em `cmd` — um "andar" retido move o robô sozinho na próxima reconexão.
- LWT: conectar com última vontade `disponibilidade = offline` (retida, QoS 1) e publicar `online` logo após conectar.
- Saiu da rede local → TLS (porta 8883) com certificado da CA conferido (`setCACert`), nunca `setInsecure()` fora de teste.
- `PubSubClient`: publica só QoS 0, pacote padrão de 256 bytes (`setBufferSize`), `connect()` bloqueia durante a tentativa TCP — chame na máquina de rede, não no laço de controle. No ESP-IDF, `esp-mqtt` é assíncrono.

## 6. OTA

- `ArduinoOTA` com senha (`setPassword` ou `setPasswordHash`), senha em `secrets.h`.
- **Nunca OTA no meio do movimento:** só chame `ArduinoOTA.handle()` quando o estado for `PARADO`; em `onStart`, force o estado seguro (driver em standby). Gravação de flash pausa o código que roda dela.
- ESP32: tabela de partições com dois slots de app (`ota_0`/`ota_1`). Com rollback habilitado no bootloader, o firmware novo sobe como "pendente": rode o autoteste (sensores respondem, rede sobe, motores parados) e só então `esp_ota_mark_app_valid_cancel_rollback()`; falhou → `esp_ota_mark_app_invalid_rollback_and_reboot()`. No Arduino-ESP32, defina `bool verifyRollbackLater() { return true; }` para o core não validar sozinho; confirme no `sdkconfig` do core que o rollback está ativo.
- O firmware novo precisa manter o caminho de OTA vivo; senão a próxima atualização é por USB. Guarde sempre um caminho físico de recuperação.

## 7. ESPHome e Home Assistant

- **ESPHome substitui firmware próprio** quando o dispositivo é sensor, relé, LED, tomada, cortina ou automação simples da casa. **Não substitui** quando há laço de controle rápido (PID, odometria), painel próprio ou lógica de robô móvel — aí firmware próprio + MQTT/API.
- YAML mínimo com `wifi`, `api` com `encryption.key`, `ota` com `platform: esphome` e senha, `logger`; todo segredo via `!secret` em `secrets.yaml` (fora do git). Pino com comentário `# PIN-NN`.
- API nativa criptografada (chave base64 de 32 bytes) é o padrão com Home Assistant; MQTT com `discovery: true` quando o broker já é o centro da casa.
- Validação: `esphome config robo.yaml` (L0) e `esphome compile robo.yaml` (L2). `esphome run` grava — é do usuário.
- Failsafe em ESPHome: comando de motor por `script` com `mode: restart` que desliga após X ms sem novo comando; `api: on_client_disconnected` desliga atuador.
- Automações do Home Assistant (YAML ou interface) chamam entidades; atuador perigoso (bomba, aquecedor, motor) tem limite de tempo também no dispositivo, não só na automação.

## 8. Segurança do dispositivo

- [ ] Senha própria do AP com ≥ 8 caracteres (menos que isso o `softAP` falha) — nunca a padrão, nunca vazia.
- [ ] Nenhuma credencial padrão (painel, OTA, broker, API).
- [ ] `secrets.h` / `secrets.yaml` no `.gitignore`; `secrets.example.h` versionado com valores falsos. Senha nunca em log, smart-memory ou mensagem.
- [ ] Toda mensagem recebida validada: tamanho, formato, faixa e tipo antes de virar comando; o resto é descartado e contado.
- [ ] Nada exposto à internet (porta aberta no roteador, túnel, DDNS) sem pedido explícito do usuário e revisão de segurança (`/dev-security-patterns` ou a squad security).

## 9. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "O celular está do lado, não cai" | Cai. Teste a queda de propósito e registre o tempo de parada. |
| "AP aberto é mais prático" | Qualquer vizinho dirige o robô. Senha própria ≥ 8. |
| "Retain no comando garante entrega" | Garante que o robô ande sozinho ao reconectar. Retain só em estado. |
| "Reconecta num while, é rapidinho" | Sem rede, o while é eterno e o failsafe não roda. |
| "OTA sem senha agiliza" | Qualquer um na rede grava firmware. Senha + rollback. |
| "Broker público só para testar" | O teste vira produção. Broker local. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e), johnkozaris/jko-claude-plugins — esp32-cpp (MIT, © 2026 John, commit 47c0ec0) e ezrover/ESP32-AI-Agent-Skill (MIT, © 2026 Vibe Coder, commit 124d298). ESPHome e Home Assistant a partir da documentação oficial (esphome.io, home-assistant.io).
