# Ponte MCU ↔ ROS 2 e bringup — exemplos

Complemento dos §3 e §9 do `SKILL.md`. Instalar serviço, gravar MCU e mexer em `/etc` são passos do usuário; o agente escreve os arquivos e o roteiro.

## micro-ROS no MCU — máquina de estados com o agent

Biblioteca `micro_ros_platformio` (ou `micro_ros_arduino`) na versão da distribuição do computador (ex.: `jazzy`). Agent no computador: `ros2 run micro_ros_agent micro_ros_agent serial --dev /dev/robo_mcu -b 115200`.

```cpp
#include <Arduino.h>
#include <micro_ros_platformio.h>
#include <rcl/rcl.h>
#include <rclc/rclc.h>
#include <rclc/executor.h>
#include <rmw_microros/rmw_microros.h>
#include <geometry_msgs/msg/twist.h>
#include "motores.h"   // pedirVelocidade(v, w), motoresParar() — dono do motor

enum class Agente : uint8_t { ESPERANDO, DISPONIVEL, CONECTADO, DESCONECTADO };
Agente agente = Agente::ESPERANDO;
rclc_support_t support; rcl_allocator_t allocator; rcl_node_t node;
rcl_subscription_t subCmd; rclc_executor_t executor;
geometry_msgs__msg__Twist msgCmd;
uint32_t ultimoCmdMs = 0, ultimoPingMs = 0;
constexpr uint32_t TIMEOUT_CMD_MS = 300;

void aoCmd(const void* m) {
  auto* t = static_cast<const geometry_msgs__msg__Twist*>(m);
  pedirVelocidade(t->linear.x, t->angular.z);   // m/s e rad/s; o módulo de motor satura e aplica rampa
  ultimoCmdMs = millis();
}

bool criarEntidades() {
  allocator = rcl_get_default_allocator();
  if (rclc_support_init(&support, 0, nullptr, &allocator) != RCL_RET_OK) return false;
  if (rclc_node_init_default(&node, "robo_base", "", &support) != RCL_RET_OK) return false;
  if (rclc_subscription_init_default(&subCmd, &node,
        ROSIDL_GET_MSG_TYPE_SUPPORT(geometry_msgs, msg, Twist), "cmd_vel") != RCL_RET_OK) return false;
  executor = rclc_executor_get_zero_initialized_executor();
  if (rclc_executor_init(&executor, &support.context, 1, &allocator) != RCL_RET_OK) return false;
  if (rclc_executor_add_subscription(&executor, &subCmd, &msgCmd, &aoCmd, ON_NEW_DATA) != RCL_RET_OK) return false;
  rmw_uros_sync_session(1000);                  // relógio do computador para carimbar mensagens
  return true;
}

void destruirEntidades() {
  rmw_context_t* ctx = rcl_context_get_rmw_context(&support.context);
  (void)rmw_uros_set_context_entity_destroy_session_timeout(ctx, 0);   // não espera o agent que sumiu
  (void)rcl_subscription_fini(&subCmd, &node);
  (void)rclc_executor_fini(&executor);
  (void)rcl_node_fini(&node);
  (void)rclc_support_fini(&support);
}

void setup() {
  motoresParar();                               // estado seguro primeiro
  Serial.begin(115200);
  set_microros_serial_transports(Serial);       // a Serial passa a ser do micro-ROS: log vai por outra UART
}

void loop() {
  uint32_t agora = millis();
  switch (agente) {
    case Agente::ESPERANDO:
      if (agora - ultimoPingMs >= 500) { ultimoPingMs = agora;
        if (rmw_uros_ping_agent(100, 1) == RMW_RET_OK) agente = Agente::DISPONIVEL; }
      break;
    case Agente::DISPONIVEL:
      if (criarEntidades()) agente = Agente::CONECTADO;
      else { destruirEntidades(); agente = Agente::ESPERANDO; }
      break;
    case Agente::CONECTADO:
      if (agora - ultimoPingMs >= 200) { ultimoPingMs = agora;
        if (rmw_uros_ping_agent(100, 1) != RMW_RET_OK) { agente = Agente::DESCONECTADO; break; } }
      rclc_executor_spin_some(&executor, RCL_MS_TO_NS(5));
      break;
    case Agente::DESCONECTADO:
      destruirEntidades(); agente = Agente::ESPERANDO;
      break;
  }
  if (agente != Agente::CONECTADO || agora - ultimoCmdMs > TIMEOUT_CMD_MS) motoresParar();   // silêncio = parado
}
```
`rmw_uros_ping_agent` e `spin_some` bloqueiam até o timeout: no ESP32, rode a ponte numa task e o controle de motor (com o próprio timeout) em outra.

## Serial própria — quadro com CRC

Quadro: `0xA5 0x5A | tipo (1) | tam (1) | payload (tam ≤ 32) | CRC-16 (2, little-endian)`; CRC-16/CCITT-FALSE (polinômio 0x1021, início 0xFFFF) sobre `tipo + tam + payload`. Vetor de teste: `"123456789"` → `0x29B1`. No fio, inteiros escalados (ex.: `int16` em mm/s e mrad/s); no ROS, SI.

```cpp
uint16_t crc16(const uint8_t* d, size_t n) {
  uint16_t c = 0xFFFF;
  while (n--) {
    c ^= (uint16_t)(*d++) << 8;
    for (int i = 0; i < 8; i++) c = (c & 0x8000) ? (uint16_t)((c << 1) ^ 0x1021) : (uint16_t)(c << 1);
  }
  return c;
}

// Parser byte a byte, sem bloquear: chame com cada byte disponível na serial.
enum class Rx : uint8_t { SYNC1, SYNC2, TIPO, TAM, DADOS, CRC1, CRC2 };
struct Parser { Rx st = Rx::SYNC1; uint8_t buf[34]; uint8_t tam = 0, i = 0; uint16_t crc = 0; uint32_t ruins = 0; };

bool parserByte(Parser& p, uint8_t b) {        // true = quadro válido em p.buf (tipo, tam, payload)
  switch (p.st) {
    case Rx::SYNC1: if (b == 0xA5) p.st = Rx::SYNC2; break;
    case Rx::SYNC2: p.st = (b == 0x5A) ? Rx::TIPO : Rx::SYNC1; break;
    case Rx::TIPO:  p.buf[0] = b; p.st = Rx::TAM; break;
    case Rx::TAM:   if (b > 32) { p.ruins++; p.st = Rx::SYNC1; break; }
                    p.buf[1] = b; p.tam = b; p.i = 0; p.st = b ? Rx::DADOS : Rx::CRC1; break;
    case Rx::DADOS: p.buf[2 + p.i++] = b; if (p.i == p.tam) p.st = Rx::CRC1; break;
    case Rx::CRC1:  p.crc = b; p.st = Rx::CRC2; break;
    case Rx::CRC2:  p.crc |= (uint16_t)b << 8; p.st = Rx::SYNC1;
                    if (p.crc == crc16(p.buf, 2 + p.tam)) return true;
                    p.ruins++; break;
  }
  return false;
}
```

Lado do computador (Python, para o nó da ponte):
```python
import struct
def crc16(d: bytes) -> int:
    c = 0xFFFF
    for b in d:
        c ^= b << 8
        for _ in range(8):
            c = ((c << 1) ^ 0x1021) & 0xFFFF if c & 0x8000 else (c << 1) & 0xFFFF
    return c
def quadro_cmd(v_m_s: float, w_rad_s: float) -> bytes:
    corpo = struct.pack("<BBhh", 0x01, 4, int(v_m_s * 1000), int(w_rad_s * 1000))
    return b"\xA5\x5A" + corpo + struct.pack("<H", crc16(corpo))
```
Contador de quadros ruins vai para `/diagnostics`; taxa de erro > 1% é problema de fiação, terra ou baud.

## Bringup — udev, pré-checagem e unidade systemd

`/etc/udev/rules.d/99-robo.rules` (atributos de `udevadm info -a -n /dev/ttyUSB0`):
```
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", ATTRS{serial}=="0001", SYMLINK+="robo_mcu"
```

`/usr/local/bin/robo-checa-devices.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
for d in /dev/robo_mcu /dev/robo_lidar; do
  [ -e "$d" ] || { echo "dispositivo ausente: $d" >&2; exit 1; }
done
```

`/etc/systemd/system/robo-bringup.service`:
```ini
[Unit]
Description=Bringup ROS 2 do robo
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=robo
Environment=ROS_DOMAIN_ID=42
ExecStartPre=/usr/local/bin/robo-checa-devices.sh
ExecStart=/bin/bash -c 'source /opt/ros/jazzy/setup.bash && source /home/robo/ros2_ws/install/setup.bash && exec ros2 launch robo_bringup robo.launch.py'
KillSignal=SIGINT
TimeoutStopSec=20
Restart=on-failure
RestartSec=5
# WatchdogSec=30 e NotifyAccess=all SÓ se um nó chamar sd_notify("WATCHDOG=1") periodicamente
# (Python: from systemd import daemon; daemon.notify("WATCHDOG=1"), pacote python3-systemd)

[Install]
WantedBy=multi-user.target
```
Roteiro do usuário: `sudo udevadm control --reload && sudo udevadm trigger`, `sudo systemctl daemon-reload`, `sudo systemctl enable --now robo-bringup`, `journalctl -u robo-bringup -f` — e mandar a saída. Teste de queda: desconectar o MCU com o serviço rodando → o log deve mostrar a pré-checagem falhando no reinício, e o robô (suspenso) parado.
