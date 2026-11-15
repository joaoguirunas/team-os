---
name: robotics-motion-control
description: "Movimento e percepção no microcontrolador — interface única com saturação e rampa, motores DC/servo/stepper e drivers, sensores (ultrassom, ToF, IR, IMU, linha, encoder), PID com anti-windup e sintonia com log, cinemática diferencial e odometria, laço de controle com prazos, comportamentos em camadas e hierarquia de parada. Use ao escrever controle, sensores ou modo autônomo."
version: "1.0"
updated: "2026-11-14"
---

# Controle de movimento — do PWM ao comportamento

Ordem: **seguro > estável > preciso > rápido**. Todo comportamento novo começa suspenso (rodas sem tocar o chão), depois chão em velocidade baixa, depois velocidade final. Ganho não se adivinha: sai de teste com log. Detalhe de drivers, sensores e encoder com PCNT em `references/drivers-e-sensores.md` — leia ao escolher driver, ligar sensor ou contar encoder (§2, §3).

## 1. Interface única de movimento

O resto do firmware nunca toca PWM. Uma função recebe o pedido, satura e aplica rampa; só ela escreve no driver (dono único).

```cpp
// Chamada a cada tick de controle (ex.: 20 ms). Valores em % de -100 a 100.
void setMotores(float alvoEsq, float alvoDir, float dtS) {
  static float esq = 0, dir = 0;
  const float MAX = 80.0f, RAMPA_PCT_S = 150.0f;      // limite e aceleração vêm de control/tuning.md
  alvoEsq = constrain(alvoEsq, -MAX, MAX);
  alvoDir = constrain(alvoDir, -MAX, MAX);
  float passo = RAMPA_PCT_S * dtS;                    // quanto pode mudar neste tick
  esq += constrain(alvoEsq - esq, -passo, passo);
  dir += constrain(alvoDir - dir, -passo, passo);
  driverAplicar(esq, dir);                            // módulo do driver: sentido + duty
}
```
Parada de segurança **não** passa pela rampa: `driverParar()` zera na hora.

## 2. Motores e drivers

Corrente de motor travado (stall) e tensão decidem o driver — dimensionamento é de VOLTA (robotics-electronics); o datasheet manda nos números abaixo, que são típicos.

| Driver | Tensão do motor | Corrente por canal | Observação |
|---|---|---|---|
| TB6612FNG | 4,5–13,5 V | 1,2 A contínua, 3,2 A pico | MOSFET, pouca perda, PWM até 100 kHz, lógica 2,7–5,5 V, pino STBY |
| L298N | 5–35 V (módulo) | ~2 A | bipolar: perde ~2 V ou mais, esquenta; PWM baixo (1–5 kHz); regulador 5 V do módulo só até ~12 V |
| DRV8833 | 2,7–10,8 V | 1,5 A RMS, 2 A pico | ótimo para motor TT 3–6 V; lógica 3,3 V ok; nSLEEP |
| BTS7960 (IBT-2) | 5,5–27 V | dezenas de A | motor grande; alguns módulos têm buffer 74HC a 5 V (entrada alta ≥ ~3,5 V) e pedem conversão de nível vindo de 3,3 V |

- **PWM:** 20 kHz tira o chiado em drivers MOSFET; no ESP32, `frequência × 2^bits ≤ 80 MHz` (20 kHz com 10 bits cabe). AVR com `analogWrite` fica em ~490/980 Hz (audível, funciona).
- **Freio × roda livre:** IN1=IN2=alto (TB6612) curto-circuita o motor e freia; ambos baixos solta. Parada de emergência = freio + depois standby.
- **Servo:** pulso de 1–2 ms (muitos aceitam 0,5–2,5 ms) a 50 Hz; alimentação separada de 5–6 V com terra comum — um MG996R travado puxa ~2,5 A, nunca pelo 5 V da placa ou do USB.
- **Stepper:** A4988 (até 1/16), DRV8825 (até 1/32), TMC2209 (silencioso, UART). Limite de corrente pelo Vref **antes** de ligar o motor: A4988 `I = Vref / (8 × Rsense)` (Rsense de 0,05 a 0,2 Ω conforme o módulo — leia o resistor). Capacitor ≥ 100 µF no VMOT; nunca desconecte o motor com o driver energizado.

## 3. Sensores

Cada sensor tem taxa própria, timeout e valor **inválido explícito**; inválido = obstáculo, nunca caminho livre.

- **Ultrassom HC-SR04:** 5 V, ECHO de 5 V → divisor para 3,3 V em ESP32/RP2040. `pulseIn(echo, HIGH, 30000)` → 0 = sem eco = inválido. `cm = us / 58`. Uma leitura a cada ≥ 60 ms; mediana de 3–5. `pulseIn` bloqueia até o timeout — no laço de controle use leitura por interrupção.
- **ToF VL53L0X (~2 m) / VL53L1X (~4 m):** I2C, endereço padrão 0x29 nos dois. Vários sensores: pino XSHUT de cada um e endereço trocado no boot, um por vez (não fica gravado).
- **IR:** Sharp GP2Y0A21 analógico e não linear (10–80 cm, use tabela); TCRT5000 para linha/borda, sensível à luz ambiente.
- **IMU:** MPU6050 (0x68/0x69) tem deriva no yaw — calibre o bias do giroscópio parado no boot. BNO055 (0x28/0x29) faz a fusão a bordo e informa calibração 0–3 por sensor; registre o estado de calibração no log.
- **Seguidor de linha:** calibre mínimo/máximo por sensor na superfície real; posição = média ponderada.
- **Encoder:** canal A por interrupção e B para sentido (AVR Uno: só pinos 2 e 3), ou contador de hardware PCNT no ESP32. Registre pulsos por volta da **roda** (encoder × redução × 4 se quadratura).

## 4. PID e sintonia

Sem encoder ou sensor de velocidade não há PID de velocidade: use malha aberta com rampa e registre a diferença entre os motores medida no chão.

```cpp
struct Pid { float kp, ki, kd, integral, medidaAnt, uMin, uMax; bool primeiro; };

float pidPasso(Pid& p, float alvo, float medida, float dtS) {
  if (dtS <= 0.0f || dtS > 0.2f) { p.primeiro = true; return 0.0f; }  // dt real; tick perdido → reinicia
  float erro = alvo - medida;
  float deriv = p.primeiro ? 0.0f : -(medida - p.medidaAnt) / dtS;      // derivada na MEDIDA: sem chute ao mudar o alvo
  p.medidaAnt = medida; p.primeiro = false;
  float iNovo = p.integral + p.ki * erro * dtS;
  float u = p.kp * erro + iNovo + p.kd * deriv;
  bool presoAlto = u > p.uMax && erro > 0, presoBaixo = u < p.uMin && erro < 0;
  if (!presoAlto && !presoBaixo) p.integral = iNovo;                    // anti-windup: não integra empurrando a saturação
  return constrain(u, p.uMin, p.uMax);
}
```

Sintonia prática (robô suspenso, log `t,alvo,medida,u` a cada tick, CSV para o usuário mandar):
1. `ki = kd = 0`. Suba `kp` até responder rápido com leve oscilação; volte ~50%.
2. Suba `kd` até amortecer o sobressinal (se a medida for ruidosa, filtre antes de derivar).
3. Suba `ki` devagar até zerar o erro em regime sem criar oscilação lenta.
4. Repita no chão em velocidade baixa. Mudou roda, bateria ou carga → sintonize de novo.

Registro em `control/tuning.md` (nota viva):
```
| Malha | kp | ki | kd | dt | limite | Teste de origem | Resultado |
| vel_esq | 0.8 | 2.0 | 0.02 | 20 ms | ±80% | MED-14 (suspenso, degrau 0→0,3 m/s) | sobressinal 8%, regime ±2% |
```

## 5. Cinemática diferencial e odometria

`v` (m/s), `ω` (rad/s), `L` = distância entre rodas (m), `r` = raio da roda (m), `N` = pulsos por volta da roda.

- Rodas: `vEsq = v − ω·L/2`, `vDir = v + ω·L/2`. Se uma passar do limite, escale as duas pelo mesmo fator (mantém a curva).
- Odometria por tick: `dEsq = 2πr·ΔpEsq/N`, `dDir = 2πr·ΔpDir/N`, `d = (dDir + dEsq)/2`, `Δθ = (dDir − dEsq)/L`, `x += d·cos(θ + Δθ/2)`, `y += d·sin(θ + Δθ/2)`, `θ += Δθ`.

```cpp
struct Pose { float x, y, th; };
Pose odometria(Pose p, long dPulsosEsq, long dPulsosDir, float r, float L, float N) {
  const float k = 2.0f * 3.14159265f * r / N;
  float dE = k * dPulsosEsq, dD = k * dPulsosDir, d = 0.5f * (dD + dE), dth = (dD - dE) / L;
  return { p.x + d * cosf(p.th + 0.5f * dth), p.y + d * sinf(p.th + 0.5f * dth), p.th + dth };
}
```
Função pura: teste no host (`pio test -e native` ou `g++`) — ex.: 1 volta em cada roda com r=0,033 m → `x ≈ 0,2073 m`, `th = 0`. Erro cresce com escorregamento; para correção de longo prazo, IMU ou fusão (MORAVEC).

## 6. Laço de controle em tempo real

Antes de sintonizar, preencha a tabela e defina o comportamento de falha:

| Atividade | Período | Prazo | Pior tempo medido | Se falhar |
|---|---|---|---|---|
| Controle de motor (PID + rampa) | 20 ms | 5 ms | medir (`micros()` antes/depois) | tick perdido → reinicia D e I, mantém saída limitada |
| Encoder | evento | — | ISR < 10 µs | contagem com `volatile` + seção crítica |
| Ultrassom/ToF | 60 ms | 60 ms | medir | leitura velha > 200 ms → inválida → parar |
| Comando remoto | evento | — | — | sem comando > 500 ms → parar |

I2C lento, log, rede e gravação em flash ficam **fora** do tick de controle (outra task ou fatia da máquina de estados). Meça com Wi-Fi e motores ligados, não só no USB.

## 7. Comportamentos em camadas

Subsunção: cada camada pode suprimir as de baixo. **Segurança (parar) > desviar > objetivo > vagar**. Registre em `control/behaviors.md` a condição de entrada e saída de cada camada; a camada de segurança roda sempre, em todo tick.

Cobertura de área (robô de limpeza):

| Padrão | Como | Prós | Contras |
|---|---|---|---|
| Bate-e-volta aleatório | anda reto; no obstáculo gira ângulo aleatório (90–180°) | só precisa de para-choque/distância; robusto | cobre devagar, repete áreas, deixa cantos |
| Espiral | raio crescente a partir do ponto inicial | cobre bem área aberta local | perde a forma no primeiro obstáculo |
| Zigue-zague (boustrofédon) | faixas paralelas com deslocamento de uma largura | cobertura mais rápida e sistemática | exige rumo confiável (encoder + IMU); deriva sem isso |

Combinação comum: espiral no início → bate-e-volta → seguir parede por um tempo para pegar bordas.

## 8. Hierarquia de parada

1. **E-stop físico que corta a energia dos motores** (botão com contato NF + relé/contator ou chave no positivo do motor) — obrigatório quando o robô tem força para machucar; não depende de software.
2. **Failsafe do MCU:** timeout de comando, sensor inválido, estado `FALHA` → driver parado.
3. **Watchdog/heartbeat:** MCU travado reinicia em estado seguro; sem heartbeat do comando, não anda.
4. **Limites de aplicação:** velocidade máxima, área, inclinação, tempo de operação.

Uma camada não substitui a de cima. Parada só por software em robô com força para machucar fere o piso de segurança.

## 9. Desculpa | Realidade

| Desculpa | Realidade |
|---|---|
| "Kp=1, Ki=0, Kd=0 serve" | Ganho sai de sintonia com log e vai para `tuning.md` com o teste de origem. |
| "Sem eco é porque não tem nada na frente" | Sem eco é leitura inválida. Parar. |
| "Rampa deixa lento" | Arranque a 100% puxa o pico de corrente e reinicia a placa por queda de tensão. |
| "O integrador se ajeita" | Sem anti-windup ele acumula enquanto satura e o robô dispara depois. |
| "Odometria dá a posição" | Dá estimativa que escorrega. Registre o erro medido em percurso conhecido. |
| "Ligo o stepper e ajusto o Vref depois" | Driver e motor queimam antes. Vref primeiro, com o motor desligado. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e), arpitg1304/robotics-agent-skills (Apache-2.0, © 2026 robotics-agent-skills contributors, commit f9bc546) e dbwls99706/ros2-engineering-skills (Apache-2.0, © 2025 dbwls99706, commit d569707).
