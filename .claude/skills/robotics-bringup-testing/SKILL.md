---
name: robotics-bringup-testing
description: "Energização e teste de robôs na squad Robotics — escada de verificação L0–L6 com a evidência de cada nível, pedido de ação física ao usuário, roteiro de energização em 7 passos, tabela MED-NN, suspenso → chão → velocidade final, falhas provocadas com operador, teste de resistência, simulação antes do físico e análise de falha. Use ao escrever ou executar roteiro de bancada e ao julgar o G4."
version: "1.0"
updated: "2026-11-14"
---

# Robotics Bring-up & Testing — reporte o nível alcançado, não o tentado

O agente não tem mãos. Quem liga, mede e grava é o usuário; FARADAY (robotics-bench) escreve o roteiro, pede **uma ação por vez**, compara medido × esperado e declara o nível alcançado. ASIMOV (robotics-qa) usa este documento no G4; BROOKS, MORAVEC e LEONARDO, para testar controle, autonomia e montagem sem machucar ninguém.

## 1. Escada de verificação L0–L6

| Nível | O que é | Conta como evidência | Não conta |
|---|---|---|---|
| **L0** | Estático / revisão | Pinagem × `pins.h` linha a linha, conta do orçamento refeita, esquema revisado | "Parece certo" |
| **L1** | Unidade / função pura | Teste automatizado passando (cinemática, PID, parser) com a saída colada; simulação | Teste que nunca falhou (sem red) |
| **L2** | Build | Saída real do compilador com versão do toolchain, placa-alvo e tamanho do binário | "Compila na minha cabeça" |
| **L3** | Gravado e rodando, **sem atuação** | Log serial do boot (reset reason, versão), sensores lidos com valor plausível | Upload aceito sem log |
| **L4** | Hardware ligado, **atuador suspenso ou contido** | `MED-NN` medidas: trilhos com carga, corrente de regime e de arranque, failsafe disparando | "Girou" sem número |
| **L5** | Movimento controlado no ambiente real | Chão em velocidade baixa, área livre, operador na chave; vídeo ou log + falhas provocadas (§6) | Uma volta feliz |
| **L6** | Uso real / resistência | Soak de 20–30 min ou mais (§7) com temperatura, bateria e reconexão registrados | Teste de 2 minutos |

- **Reporte o nível alcançado, não o tentado.** Tentou L4 e o motor não mediu? A etapa está em L3.
- Provas não se herdam: build ≠ gravação ≠ hardware ≠ sistema ≠ uso real.
- **Permissão ≠ prova.** "Pode testar" do usuário autoriza a ação; o nível só sobe com a observação.
- O critério de aceite da story diz o nível exigido; G4 só passa com esse nível alcançado e medido.

## 2. Physical gate — o pedido ao usuário

Um pedido = **uma ação física**, com o valor esperado e o limite de parada. Formato:

```text
Ação (uma só): {o que fazer, onde, com qual estado da energia}
Meça/observe: {grandeza} com a ponta vermelha em {ponto} e a preta em {GND do trilho}
Esperado: {valor ± tolerância}
Pare se: {condição} → desligue a chave geral e responda com o que viu
Responda com o valor lido (ou o que viu/ouviu/cheirou), ou `bloqueado: {motivo}`.
```

"Sim, funcionou" sem observação **não é evidência** — peça o número. Nunca peça ação perigosa: rede 110/220V, bateria danificada, curto proposital.

## 3. Roteiro padrão de energização (7 passos)

1. **Inspeção e foto**: cada fio contra `electronics/wiring.md` (`W-NN`), polaridade de bateria, driver e capacitores eletrolíticos; foto da montagem registrada.
2. **Continuidade e curto**, tudo desligado: V+ ↔ GND de cada trilho sem curto (`robotics-electrical-safety` §8); GND de todas as fontes em comum.
3. **Energizar sem carga**: só bateria/fonte → regulador, sem placa nem motor. Fonte de bancada com **limite de corrente baixo (~50–100 mA)**; sem fonte de bancada, fusível pequeno. Medir cada trilho (ex.: 5,0 V ± 5%). Buck ajustável é ajustado aqui.
4. **Placa sozinha**: limite em ~300–500 mA (o pico de Wi-Fi do ESP32 derruba um limite de 100 mA). Esperado: L3 — log de boot, consumo em repouso dentro do orçamento.
5. **Uma carga por vez**: sensor, depois driver sem motor, depois cada atuador. Mede o trilho a cada carga nova.
6. **Motor suspenso** (rodas no ar, robô sobre um suporte): corrente em **regime** e no **arranque** (multímetro em MIN/MAX — o modo comum é lento para o pico), tensão da lógica durante o arranque, failsafe ao cortar o comando.
7. **Falhas provocadas** com operador presente (§6) — e, na etapa final, resistência (§7).

## 4. Tabela de medições MED-NN

Vai em `bench/E{n}-bringup.md`. O esperado vem do projeto de VOLTA (`electronics/power-budget.md`); medido acima da margem → devolve a VOLTA.

| Id | O que medir | Pontas (vermelha → preta) | Esperado | Limite de parada | Medido | ok |
|---|---|---|---|---|---|---|
| MED-01 | Curto V+ ↔ GND, desligado | + bateria → GND | sem bipe contínuo | bipe contínuo | | |
| MED-02 | Saída do buck sem carga | OUT+ → OUT− | 5,00 V ± 0,10 | > 5,25 V | | |
| MED-03 | 3V3 da placa com Wi-Fi conectando | 3V3 → GND (MIN) | ≥ 3,20 V | < 3,0 V | | |
| MED-04 | Corrente de um motor, suspenso, em regime | amperímetro em série no VM | 0,15–0,30 A | > 0,6 A | | |
| MED-05 | Pico de arranque do motor | idem, modo MAX | < 1,5 A | > 2,0 A | | |

Linha sem "medido" = não medida. ASIMOV devolve "MED-04 sem valor medido".

## 5. Suspenso → chão lento → velocidade final

1. **Suspenso**: rodas no ar; sentido de cada roda confere com o comando; failsafe para em ≤ timeout (ex.: 500 ms sem comando → motores em zero).
2. **Chão lento**: PWM ≤ 30%, área livre de ~2 × 2 m sem degrau, operador com a mão na chave geral, cabo de USB desligado ou folgado.
3. **Velocidade final**: só depois de §6 passar em velocidade baixa. Subir em degraus (50%, 75%, 100%), repetindo parada e failsafe a cada degrau.

## 6. Falhas provocadas (operador presente)

| Falha | Como provocar (usuário) | Comportamento exigido |
|---|---|---|
| Comando perdido | Fechar o app / desligar o controle | Motores em zero em ≤ timeout definido |
| Wi-Fi caindo | Desligar o roteador por 30 s | Para; reconecta com espera crescente e teto; não retoma movimento antigo |
| Roda bloqueada 1 s | Segurar uma roda com luva, suspenso | Corrente sobe a ~stall e cai: firmware/driver corta; sem cheiro, sem reset |
| Bateria baixa | Fonte de bancada descendo devagar (ou bateria no fim) | Aviso no limiar; parada no corte; sem reset em loop |
| Reset no meio do movimento | Botão EN/RESET com motores girando | Após o boot, atuadores parados até comando novo |
| E-stop com software travado | Firmware de teste preso num laço + chave física | A **chave física corta a energia dos atuadores**; software não é parada de emergência |

- **Nunca executadas pelo agente**: o agente escreve o roteiro; o usuário provoca, com o robô contido e alguém na chave.
- **Nunca afrouxe o limite porque o teste falhou.** Falhou → a etapa volta ao dono do módulo (ADA, BROOKS, MARCONI ou VOLTA) e o teste se repete igual.

## 7. Teste de resistência (soak)

20–30 min no mínimo (80 min se o código usa `micros()` no AVR: ele vira a cada ~71,6 min). Registrar no início, no meio e no fim:
- [ ] Temperatura de regulador, driver e motores (termômetro infravermelho; não aguenta segurar o dedo 3 s ≈ acima de 60 °C → anote e investigue).
- [ ] Tensão da bateria sob carga e queda total; autonomia × prevista.
- [ ] Reconexão: Wi-Fi cortado e devolvido pelo menos uma vez durante o soak.
- [ ] Contadores: resets, reconexões, fila cheia, deadlines perdidos (vêm do log).
- [ ] **Rollover de `millis()`** (49,7 dias) não dá para esperar: exige L1 com o relógio adiantado no teste e subtração sem sinal no código.
- [ ] **OTA interrompido** (se houver OTA): cortar o Wi-Fi no meio da atualização → a placa volta no firmware anterior.

## 8. Simulação antes do físico

- **Wokwi** (Arduino Uno/Nano/Mega, ESP32 e variantes, Pico; STM32 parcial): vale para lógica, máquina de estados, pinos, serial e sensores simulados antes de a peça chegar. **Não mostra** corrente, queda de tensão, ruído de motor nem calor.
- **Gazebo** (ou Webots) para ROS 2: navegação, Nav2, sensores e comportamentos antes do robô real (MORAVEC).
- Simulação passando = **evidência L1**. Nunca sobe para L3 ou acima: o físico ainda precisa da sua escada.

## 9. Análise de falha

1. Reproduza e descreva o sintoma com número (tensão, tempo, log).
2. Uma hipótese e o teste que a derruba. **Uma mudança por iteração** — duas mudanças e não se sabe qual resolveu.
3. Causa raiz, não sintoma: watchdog disparando → por que travou; reset → leia o reset reason antes de mexer.
4. Registre em `bench/falhas.md`:

```markdown
## F-{nn} · E{n} · {data}
Sintoma: {o que se viu, com número} · Reprodução: {passos}
Hipóteses testadas: {h1 → resultado} · Causa raiz: {…}
Correção: {…} por {agente} · Verificação: MED-{nn} refeita → {valor} · Nível depois: L{n}
```

## 10. Template de `bench/E{n}-bringup.md`

```markdown
# E{n} — {nome da etapa} · bring-up
**Pinagem:** FROZEN v{n} · **Firmware:** {commit/versão} · **Critério de aceite:** L{n}
**Nível de verificação alcançado:** L{n} · **Data:** {AAAA-MM-DD}

## Pré-condições
- [ ] G2 PASS · [ ] G3 PASS (se move atuador) · [ ] fonte com limite ou fusível · [ ] chave geral acessível

## Roteiro (§3) — passo · ação pedida · resposta do usuário
## Medições — tabela MED-NN (§4)
## Falhas provocadas (§6) — falha · comportamento observado · ok
## Resistência (§7) — se etapa final
## Fotos e logs citados — caminho de cada arquivo
## Pendências e o que não foi verificado
```

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de dbwls99706/ros2-engineering-skills (Apache-2.0, © 2025 dbwls99706, commit d569707) — escada L0–L6, falhas injetadas só com operador e permissão ≠ prova; de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e) — physical gate e uma mudança por iteração; e de johnkozaris/jko-claude-plugins, plugin esp32-cpp (MIT, © 2026 John, commit 47c0ec0) — soak test.
