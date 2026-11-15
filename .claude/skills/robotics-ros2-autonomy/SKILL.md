---
name: robotics-ros2-autonomy
description: "Autonomia com computador embarcado e ROS 2 — quando subir (e quando não), distribuição LTS em ADR, MCU com failsafe próprio + ponte micro-ROS ou serial, nós/tópicos/QoS/launch, TF e URDF com medidas reais, odometria e fusão, SLAM, Nav2, visão, simulação primeiro, bag em todo teste, bringup com systemd e parada fora do ROS. Use em robô com Linux, câmera, mapa ou ROS 2."
version: "1.0"
updated: "2026-11-14"
---

# ROS 2 e autonomia — simulação primeiro, parada fora do Linux

Ordem: **simulação > robô suspenso > robô no chão** (área livre, velocidade limitada). O microcontrolador para os motores sozinho quando o comando deixa de chegar, mesmo com o computador travado. Código da ponte micro-ROS, protocolo serial e unidade systemd em `references/ponte-e-bringup.md` — leia ao implementar §3 ou §9.

## 1. Quando subir para ROS 2 (e quando não)

| Sobe para computador + ROS 2 | Fica no microcontrolador |
|---|---|
| câmera com processamento (seguir objeto, detectar pessoa) | desviar de obstáculo com ultrassom/ToF |
| mapa do ambiente e ir até um ponto | seguir linha, bate-e-volta, espiral |
| LiDAR, câmera de profundidade, vários sensores pesados | controle remoto pelo celular |
| usuário pediu ROS 2 para aprender | automação da casa (ESPHome/MQTT) |

ROS 2 custa: Linux para manter, energia (2–3 A estáveis só para o computador), cartão SD que corrompe com queda de tensão, tempo de boot. Cabe no MCU → devolva a JAZARI (robotics-architect) com o motivo.

## 2. Distribuição e sistema

Distribuição **LTS** compatível com o sistema da placa, fixada em `ADR-NN` junto com a versão do SO e do JetPack (se houver):

| Distribuição | Ubuntu | Fim do suporte | Uso típico |
|---|---|---|---|
| Humble (LTS) | 22.04 | mai/2027 | Jetson com JetPack 6 (Ubuntu 22.04); ecossistema mais maduro |
| Jazzy (LTS) | 24.04 | mai/2029 | Raspberry Pi 5 / mini PC com Ubuntu 24.04 — padrão para projeto novo |
| Lyrical (LTS) | 26.04 | — | lançada em mai/2026: confira se Nav2, slam_toolbox e micro-ROS já têm pacote antes de adotar |

Raspberry Pi OS não é plataforma Tier 1: use Ubuntu Server na placa ou ROS 2 em contêiner. Distribuição não LTS só com motivo escrito no ADR.

## 3. Arquitetura MCU + computador

- **MCU:** PWM, encoder, PID de roda, rampa, leitura de para-choque e **failsafe próprio** (sem `cmd_vel` há mais de 200–500 ms → para). Nunca o Linux gera PWM ou decide a parada.
- **Computador:** percepção, mapa, planejamento; manda velocidade (`geometry_msgs/Twist` em SI: m/s, rad/s) e recebe odometria.
- **Ponte micro-ROS** (ESP32, RP2040, STM32, Teensy — não cabe em AVR de 2 KB de RAM): `micro_ros_agent` no computador (serial ou UDP). No MCU, máquina de estados `ESPERANDO_AGENTE → DISPONIVEL → CONECTADO → DESCONECTADO` com `rmw_uros_ping_agent()` periódico; ao perder o agente, motores parados e entidades destruídas/recriadas. Memória estática: número de publicadores, assinantes e tamanho de mensagem fixados no build — orce RAM antes. Tempo: `rmw_uros_sync_session()` para carimbar mensagens com o relógio do computador.
- **Serial própria** (qualquer MCU): quadro com cabeçalho, tipo, tamanho, payload e CRC-16; taxa fixa (ex.: comando a 20–50 Hz, odometria a 50 Hz); quadro com CRC errado é descartado e contado; timeout de comando no MCU. Documente em `autonomy/stack.md` e `connectivity/interfaces.md` (mensagens, unidades, taxa, o que acontece na perda) — combinado com ADA por escrito.

## 4. Pacotes, nós, tópicos, QoS

- Workspace `ros2_ws/src/` com pacotes pequenos: `robo_description` (URDF), `robo_bringup` (launch + params), `robo_base` (ponte com o MCU), `robo_percepcao`.
- Parâmetros em YAML (`config/*.yaml`), nunca no código; launch em Python carregando o YAML.
- **QoS:** sensor (scan, imagem, IMU) = `SensorDataQoS` (best effort, profundidade pequena); comando e estado = reliable. Publicador best effort + assinante reliable não conectam — confira com `ros2 topic info -v <tópico>`.
- Um único publicador final em `cmd_vel` do robô (mux de prioridade: parada > teleop > navegação); verifique com `ros2 topic info /cmd_vel`.
- Build e teste: `colcon build --symlink-install` e `colcon test` são evidência L2/L1 — rodar no robô é outra prova.

## 5. TF e URDF com medidas reais

Árvore padrão (REP-105): `map → odom → base_link → laser`, `camera_link`, `imu_link`. Eixos (REP-103): x para frente, y para a esquerda, z para cima, metros e radianos.

- `odom → base_link`: publicado pela odometria (MCU/ponte **ou** EKF — nunca os dois).
- `map → odom`: publicado pelo SLAM ou pela localização.
- Sensores: transformações fixas do URDF via `robot_state_publisher`, com as medidas de LEONARDO (`mechanics/`) — sensor 3 cm fora vira mapa torto. Confira com `ros2 run tf2_ros tf2_echo base_link laser` e no RViz.

## 6. Odometria, fusão, SLAM e Nav2

- **Fusão:** `robot_localization` (`ekf_node`) com velocidade da roda + giroscópio da IMU, `two_d_mode: true`; quando o EKF publica `odom → base_link`, desligue a TF da ponte.
- **SLAM:** `slam_toolbox` em modo online assíncrono para mapear dirigindo devagar; salve o mapa (`map_saver_cli`) e registre o arquivo.
- **Nav2 mínimo para diferencial:** mapa + localização (AMCL ou slam_toolbox em localização), planejador global (NavFn ou Smac 2D), controlador (Regulated Pure Pursuit ou DWB), costmaps com `robot_radius`/footprint real, `velocity_smoother` e `collision_monitor`. Velocidade máxima baixa nos parâmetros (ex.: 0,2 m/s) até o G4.

## 7. Visão

- Câmera USB: `v4l2_camera` ou `usb_cam`; câmera CSI no Pi com Ubuntu: `camera_ros` (libcamera). Fixe resolução e taxa (640×480 a 15–30 fps costuma bastar).
- OpenCV clássico (cor, contorno, ArUco) roda folgado num Pi 4/5. Detecção com rede neural na CPU do Pi fica em poucos quadros por segundo; acima disso, acelerador (Hailo no Pi 5, GPU do Jetson com TensorRT). Meça CPU e fps (`top`, `ros2 topic hz`) e registre.
- Processe imagem reduzida e só na taxa que a decisão precisa.

## 8. Simulação primeiro e gravação

- Gazebo (Harmonic com Jazzy; Fortress com Humble) com o **mesmo URDF** do robô real e `ros_gz_bridge`. Navegação só vai ao robô real depois de rodar na simulação com registro em `autonomy/{etapa}-notas.md`.
- Todo teste real grava bag: `ros2 bag record -o E4-teste3 /scan /odom /cmd_vel /tf /tf_static /diagnostics` — FARADAY analisa a partir dela; o nome entra no `MED-NN`.

## 9. Bringup com systemd

- Nomes estáveis de dispositivo por regra udev (`/dev/robo_mcu`, `/dev/robo_lidar`); pré-checagem em `ExecStartPre` falha cedo se faltar algum.
- `Restart=on-failure`, `RestartSec=5`, `StartLimitBurst` (na seção `[Unit]`) para não reiniciar em laço eterno; `KillSignal=SIGINT` para o launch encerrar limpo.
- `WatchdogSec` só funciona se um processo do serviço mandar `WATCHDOG=1` (`sd_notify`) — sem isso o systemd mata o serviço a cada intervalo.
- `ROS_DOMAIN_ID` único por robô na rede (0–101); com vários robôs ou rede compartilhada, restrinja a descoberta (`ROS_AUTOMATIC_DISCOVERY_RANGE`).
- Alimentação do computador por regulador dedicado (VOLTA); desligar pelo `shutdown`, não puxando o cabo.

## 10. Segurança

- **E-stop fora do ROS:** botão físico que corta a energia dos motores; a cadeia nunca passa pelo Linux nem pelo DDS. Software não é safety-rated.
- **`cmd_vel` zero não prova parada:** prova é o motor parado (encoder, observação), com o tempo medido.
- **Heartbeat habilita:** o MCU só move com comando recente; silêncio = parado. Reset do e-stop devolve **permissão**, não movimento — exige comando novo.
- Falhas provocadas (matar o nó da ponte, puxar o cabo/rádio, travar o computador) são roteiro de FARADAY com robô contido e operador presente; o agente escreve, nunca executa.
- SROS2 (noção): `ros2 security create_keystore`, um enclave por nó, `ROS_SECURITY_ENABLE=true` e `ROS_SECURITY_STRATEGY=Enforce` — vale quando o robô está em rede que não é só sua. Nunca exponha DDS ou rosbridge à internet sem pedido e revisão.

## 11. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "O Pi controla o motor direto" | Linux não é tempo real e trava. PWM e parada ficam no MCU. |
| "Publiquei zero no cmd_vel, parou" | Parou quando o encoder disser. Zero num tópico é intenção. |
| "TF eu ajusto depois" | Mapa torto e navegação errática agora. Medida real no URDF desde o início. |
| "Instalo a última de tudo" | Distribuição LTS fixa, compatível com o SO, em ADR. |
| "Pula a simulação, a sala é pequena" | Simulação, suspenso, área livre devagar. Nessa ordem. |
| "Sem bag, eu lembro o que aconteceu" | Sem bag não há análise. Grave todo teste real. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de dbwls99706/ros2-engineering-skills (Apache-2.0, © 2025 dbwls99706, v1.8.1 commit d569707) e arpitg1304/robotics-agent-skills (Apache-2.0, © 2026 robotics-agent-skills contributors, commit f9bc546).
