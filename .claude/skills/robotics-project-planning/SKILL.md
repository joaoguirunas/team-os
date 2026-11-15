---
name: robotics-project-planning
description: "Planejamento da squad Robotics — o agente não tem mãos (physical gate), resolução exata da placa antes de qualquer pino, matriz de plataforma, plano em etapas E1…En testáveis na bancada, convenções de ids e arquivos, checklist de 5 pontos da story, controle de mudança da pinagem FROZEN e provas por estágio. Use ao começar um projeto de robótica, automação ou IoT, validar story ou mudar pinagem."
version: "1.0"
updated: "2026-11-14"
---

# Robotics Project Planning — etapa pequena, prova física, id em tudo

Robô que falha com seis peças novas ligadas ao mesmo tempo não diz qual delas falhou. Esta skill organiza o projeto para que cada etapa acrescente **uma** variável, tenha um critério que o usuário vê ou mede, e deixe rastro com id. Vale para qualquer placa: Arduino AVR, ESP32 e variantes, RP2040/Pico, STM32, Raspberry Pi e Jetson.

## 1. O agente não tem mãos — physical gate

Quem compra, monta, mede, liga e grava é o usuário. O agente prepara e confere o que está em arquivo (plano, pinagem, build); evidência física só existe quando o usuário a devolve.

Formato obrigatório de todo pedido físico:

```text
Ação física (E{n}, passo {k}): na placa {modelo exato}, com a energia {desligada|ligada na fonte limitada a {x} A},
faça {UMA ação}. Meça/observe {grandeza} em {ponto exato}, com {instrumento}.
Esperado: {valor ou faixa, com unidade | o que deve ver/ouvir}.
Pare se: {limite — ex.: corrente > 0,5 A, cheiro, aquecimento, LED apagado} → desligue a chave geral.
Responda com o valor/observação (foto se ajudar) ou `bloqueado: {motivo}`.
```

- Uma ação por pedido. Três ligações de uma vez = três pedidos.
- "Sim, funcionou" sem valor, log ou foto não é evidência; registre como `não verificado` e repita o pedido.
- Pedido de energia diz onde medir (ex.: "entre VIN do driver e GND, com o motor arrancando"), unidade e mínimo/máximo vistos.
- Falha de gravação: peça a porta exata, a placa selecionada na ferramenta e o log de upload (sem senhas).

## 2. Resolução da placa e escolha de plataforma

**Sem placa `resolved`, ninguém escolhe pino.** Antes de VOLTA abrir `pinout.md`, a placa recebe um registro em `architecture/system.md`:

| Campo | Exemplo |
|---|---|
| Nome exato + revisão | ESP32-DevKitC V4 |
| Módulo/chip | ESP32-WROOM-32E (não WROVER: WROVER usa GPIO16/17 para PSRAM) |
| Core/framework e versão | Arduino-ESP32 3.x · PlatformIO `espressif32` · ESP-IDF 5.x |
| Nível lógico · fonte | 3,3 V · datasheet do módulo, p. {n} |
| Status | `resolved` · `needs-disambiguation` · `unsupported` · `profile-gap` |

| Status | Quando | O que fazer |
|---|---|---|
| `resolved` | Identidade exata confirmada (foto da placa ou link do produto) e fonte primária para o que se vai usar | Liberar pinagem |
| `needs-disambiguation` | Família reconhecida, variante não: "Arduino Nano" pode ser Nano clássico (ATmega328P, 5 V), Nano Every (ATmega4809, 5 V), Nano 33 IoT (3,3 V, **não** tolera 5 V) ou Nano ESP32 | Pedir foto/marcação ao usuário; não chutar a mais comum |
| `unsupported` | Sem documentação pública confiável (clone sem esquema, placa obscura) | Propor troca por placa documentada ou registrar o risco em ADR |
| `profile-gap` | Identidade certa, mas o fato pedido não tem fonte (ex.: corrente máxima do regulador de um clone com CH340) | Marcar `⚠ sem fonte`, projetar pelo pior caso, pedir dossiê a HERON |

Matriz de plataforma (pesos por projeto, decisão em `ADR-NN`):

| Critério | Uno/Nano AVR (5 V) | ESP32 / S3 / C3 / C6 (3,3 V) | RP2040/Pico (3,3 V) | STM32 (3,3 V) | Raspberry Pi / Jetson (Linux) |
|---|---|---|---|---|---|
| Wi-Fi/BLE | ✗ | ✓ (C6: também Thread/Zigbee; H2 sem Wi-Fi) | só Pico W | ✗ (módulo) | ✓ |
| Tempo real, PWM, encoder | ✓ simples | ✓ | ✓ (PIO) | ✓✓ | ✗ sozinho (MCU junto) |
| Visão, mapa, ROS 2 completo | ✗ | ✗ (micro-ROS como nó) | ✗ | ✗ | ✓ |
| 5 V nativo | ✓ | ✗ | ✗ | só pinos FT | ✗ |
| Consumo | baixo | pico de ~240–350 mA no TX de Wi-Fi | baixo | baixo | alto (Pi 4/5: fonte de 3–5 A) |
| Iniciante | ✓✓ | ✓ | ✓ | – | ✓ |

ESP32 clássico só quando precisa de Bluetooth Classic; C3 para nó barato; S3 para câmera/USB nativo. Linux entra quando há câmera, mapa ou ROS 2 pedido — abaixo disso, microcontrolador.

## 3. Plano em etapas E1…En

Cada `E{n}` em `architecture/system.md`: objetivo · `BOM-NN` que entram · `PIN-NN` que entram · **o que o usuário faz + tempo** · **o que deve ver** · critério de aceite físico · gate · nível L alvo · story.

Regra: **uma variável nova por etapa.** Se E3 junta sensor novo e código novo de motor, divida.

Ordem padrão — robô móvel:

| Etapa | Entra | Usuário faz (tempo) | Deve ver |
|---|---|---|---|
| E1 | Alimentação + placa | Liga bateria com chave e fusível, mede trilhos, grava blink + serial (40 min) | 5,0 V ±5 % e 3,3 V ±5 % nos trilhos; "boot ok" no serial |
| E2 | Driver + motores, robô suspenso | Monta driver, grava teste de motor (60 min) | Rodas giram 2 s para frente, 2 s para trás, param; corrente de arranque anotada |
| E3 | Sensores no serial | Liga um sensor por vez (30 min cada) | Leitura coerente (ex.: 20 cm medidos com régua → 19–21 cm no serial) |
| E4 | Comportamento autônomo | Robô no chão, área livre (45 min) | Para a ≥ 15 cm do obstáculo em 10 de 10 tentativas |
| E5 | Conectividade | Conecta ao Wi-Fi/app (30 min) | Comando do celular chega; sem rede por 1 s → robô para |
| E6 | Integração e atuadores extras | (varia) | Critério de cada atuador, um por vez |
| E7 | Resistência | Uso contínuo até a bateria acabar (30–60 min) | Sem reset, sem aquecimento > 60 °C nos drivers, autonomia anotada |

Ordem padrão — automação fixa / IoT: E1 placa + alimentação · E2 sensores lidos no serial · E3 atuador com carga simulada (LED no lugar do relé ou da bomba) · E4 lógica local sem rede · E5 conectividade (MQTT, Home Assistant, painel) · E6 instalação no local final (caixa, umidade, cabos) · E7 resistência de 24–72 h com queda provocada de Wi-Fi e de energia.

## 4. Convenções de ids e arquivos da squad

Base: `docs/smart-memory/agents/robotics/<área>/`.

| Id / artefato | Dono | Arquivo | Status / formato |
|---|---|---|---|
| `E1…En` (etapas) | JAZARI | `architecture/system.md` | pendente · em bancada · L{n} alcançado · pronta (G4) |
| `ADR-NN` | JAZARI | `architecture/decisions.md` | contexto · opções · decisão · consequência |
| `PIN-NN` | VOLTA | `electronics/pinout.md` | `DRAFT` → `FROZEN v{n}` (após PASS no G2) |
| `W-NN` (fios) | VOLTA | `electronics/wiring.md` | de → para · bitola · cor |
| `BOM-NN` | VOLTA | `electronics/bom.md` | `planejada · comprada · em mãos · testada` |
| Orçamento de energia | VOLTA | `electronics/power-budget.md` | típico · pico · autonomia · margem |
| `MED-NN` | FARADAY | `bench/E{n}-bringup.md` | esperado · medido · ok/falha |
| Falhas | FARADAY | `bench/falhas.md` | sintoma · causa raiz · correção |
| Massa | LEONARDO | `mechanics/mass-budget.md` | item · g · posição (x, y, z) |
| Guia de montagem | LEONARDO | `mechanics/assembly-guide.md` | passos numerados |
| Interfaces | MARCONI | `connectivity/interfaces.md` | tópico/rota · payload · direção |
| Ganhos | BROOKS | `control/tuning.md` · comportamentos em `control/behaviors.md` | |
| Stack | MORAVEC | `autonomy/stack.md` | |
| Dossiês | HERON | `research/{tema}.md` · `research/compra-{AAAA-MM-DD}.md` | |
| Stories | JAZARI | `docs/smart-memory/stories/{backlog,active,in-review,done}/<id>-<slug>.md` | índice `stories/BACKLOG.md` |

Firmware: `pins.h`/`pins.py` **gerado** da pinagem FROZEN, uma linha por `PIN-NN`; nunca número de pino solto. Segredos em `secrets.h` fora do git + `secrets.example.h`. Código em `firmware/` (ou o que `project/conventions.md` disser), com comentário no nível registrado ali.

## 5. Checklist de 5 pontos para validar story

- [ ] **1. Critério de aceite físico mensurável** — o que o usuário vê, mede ou ouve, com número e unidade. "Funciona" reprova.
- [ ] **2. Peças `em mãos`** — todo `BOM-NN` da story está `em mãos` (ou a story diz explicitamente "simulação/bancada sem a peça").
- [ ] **3. Pinos citados da pinagem vigente** — cada pino como `PIN-NN` da versão `FROZEN v{n}` atual (ou `DRAFT` declarado, se a etapa ainda não passou do G2).
- [ ] **4. Roteiro de FARADAY + gate de ASIMOV previstos** — path de `bench/E{n}-bringup.md` e o gate (G1 compra · G2 energização · G3 gravação com atuador · G4 etapa pronta).
- [ ] **5. Nível L alvo declarado** — L0–L6 (`robotics-bringup-testing`); a story fecha no nível alcançado e medido, não no tentado.

Faltou um ponto → a story volta para `backlog/` com o item faltante escrito.

## 6. Template de story

```markdown
# {id} — {título curto}
**Etapa:** E{n} · **Status:** backlog | active | in-review | done · **Dono:** {agente}
**Nível L alvo:** L{n} · **Gate:** G{n} · **Roteiro:** bench/E{n}-bringup.md

## Objetivo (1 frase)
## Peças: BOM-03 (em mãos), BOM-07 (em mãos)
## Pinos (pinagem FROZEN v2): PIN-04, PIN-05
## O que o usuário faz: {passos} · tempo estimado: {min}
## Critério de aceite físico
- [ ] {ex.: roda esquerda gira 2 s para frente com o robô suspenso; corrente de regime < 0,4 A (MED-06)}
## Failsafe exigido: {comando perdido > 500 ms → motores parados}
## QA Results
```

## 7. Controle de mudança da pinagem FROZEN

Pinagem congelada pode ter fio soldado. Mudar sem processo faz o usuário seguir documento errado.

1. VOLTA abre o pedido: `PIN-NN` afetados, motivo, `W-NN` que mudam, se há solda a refazer, impacto no firmware.
2. JAZARI aprova ou nega (registro em `ADR-NN` se a causa for de arquitetura).
3. VOLTA publica `FROZEN v{n+1}` com changelog no topo de `pinout.md`; a v{n} fica no histórico, não é apagada.
4. ADA regenera `pins.h`/`pins.py` e cita a versão no cabeçalho.
5. Mudou ligação → G2 de novo antes de energizar; o usuário recebe um pedido físico por fio alterado, com conferência de continuidade.

## 8. Provas por estágio

| Estágio | Prova exigida | Nível | Não prova |
|---|---|---|---|
| Revisão | Pinagem × datasheet, conta refeita | L0 | Que funciona |
| Função pura | Teste de unidade (cinemática, filtro, parser) | L1 | Hardware |
| Build | Saída real do compilador, sem erro | L2 | Que gravou |
| Gravação | Upload aceito na porta certa + log serial do boot, sem atuação | L3 | Hardware externo |
| Hardware | `MED-NN` com atuador suspenso ou contido | L4 | Sistema no ambiente |
| Sistema | Cenário integrado no ambiente real, com carga representativa | L5 | Durabilidade |
| Uso real | Resistência: bateria até o fim, 24–72 h para fixo | L6 | — |

| Desculpa | Realidade |
|---|---|
| "Compilou, marca E2 como pronta" | Build é L2. E2 pede L4 com corrente medida. |
| "O usuário autorizou, então está verificado" | Permissão não é prova. O nível sobe com medição. |
| "Duas mudanças juntas economizam uma rodada" | Se piorar, não se sabe qual. Uma mudança causal por iteração. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e) — `embedded-project-loop` e `board-support` — e de dbwls99706/ros2-engineering-skills (Apache-2.0, © 2025 dbwls99706, commit d569707) — escada L0–L6.
