---
name: robotics-mechanical-build
description: "Método mecânico da squad Robotics — orçamento de massa e centro de massa, torque por roda com margem 2×, fixação por carga e vibração, impressão 3D (material, folgas, orientação, OpenSCAD paramétrico), umidade e poeira, cabos e guia de montagem passo a passo para o usuário. Use ao projetar chassi, suporte ou caixa, dimensionar motor e roda junto com o controle e escrever o guia de montagem."
version: "1.0"
updated: "2026-11-14"
---

# Robotics Mechanical Build — medida real, massa no lugar certo, passo que o usuário executa

A eletrônica pode estar perfeita e o robô ainda empinar, patinar, soltar a bateria na primeira curva ou molhar a placa. Esta skill é o método de LEONARDO (robotics-mechanics) para o que é físico e não é circuito. O agente não tem mãos: toda medida vem do usuário, e todo passo diz o que ele faz e o que deve ver.

## 1. Princípios

1. **Medida do usuário > tabela > suposição.** Peça em mãos é medida com paquímetro ou régua antes de qualquer desenho. Motor TT, servo e bateria de clones variam milímetros.
2. **Folga é escolhida, não sobra.** Toda peça impressa registra a medida de origem e a folga aplicada.
3. **Massa tem posição.** Todo item entra no orçamento com gramas e coordenadas.
4. **Nunca prometer vedação pela geometria.**
5. **Separar encaixe de impressão** antes de redesenhar (§9).

## 2. Orçamento de massa e centro de massa

`mechanics/mass-budget.md`. Origem dos eixos: centro do eixo das rodas motrizes, no chão; x para frente, y para a esquerda, z para cima.

| Item | Massa (g) | Origem | x (mm) | y (mm) | z (mm) |
|---|---|---|---|---|---|
| Pack 2× 18650 + suporte | 110 | balança | -10 | 0 | 25 |
| Chassi impresso | 180 | fatiador | 20 | 0 | 20 |
| 2 motores TT + rodas | 140 | balança | 0 | ±60 | 33 |
| ESP32 + driver + fios | 60 | estimado | 40 | 0 | 50 |

Centro de massa: `x_cm = Σ(mᵢ·xᵢ) / Σmᵢ` (idem y e z). Massa "estimada" vira "balança" quando a peça chega.

Estabilidade — o robô tomba quando a força passa do apoio:
- Em rampa de ângulo θ: tomba se `tan θ > d / h`, com `d` = distância horizontal do CM à linha de apoio no sentido da descida e `h` = altura do CM.
- Freando ou acelerando com `a`: empina se `a / g > d / h`.
- Regra prática: bateria (o item mais pesado) baixa e perto do eixo motriz; robô de 2 rodas + rodízio com CM entre o eixo e o rodízio, mais perto do eixo, para dar tração.

## 3. Torque e roda

Força para mover o robô (junto com BROOKS, que escolhe o motor):

```
F = m·g·(sen θ + Crr·cos θ) + m·a
T_roda_total = F · r          T_por_motor = T_roda_total / n_motores
T_exigido = 2 × T_por_motor   (margem 2×)
rpm = v / (2π·r) × 60
```

`Crr` (resistência ao rolamento): ~0,01–0,03 roda de borracha em piso liso; ~0,1 ou mais em carpete/grama — medir se for crítico.

Exemplo — robô 2WD: m = 1,2 kg, roda de 66 mm (r = 0,033 m), rampa de 10°, a = 0,5 m/s², Crr = 0,03.
- m·g = 11,77 N · sen 10° = 0,174 → 2,04 N · Crr·cos θ·m·g = 0,35 N · m·a = 0,60 N → **F ≈ 2,99 N**
- T total = 2,99 × 0,033 = 0,099 N·m → por motor 0,049 N·m (≈ 0,50 kgf·cm) → **com margem: ≈ 1,0 kgf·cm por motor**
- Velocidade 0,5 m/s → 0,5 / (2π × 0,033) × 60 ≈ **145 rpm**

Leitura: TT 1:48 tem torque anunciado de ~0,8 a ~1,5 kgf·cm conforme vendedor e tensão — e esse número costuma ser de stall. O exigido com margem precisa caber no torque **de operação**, não no de stall: perto do stall o motor puxa a corrente de stall e esquenta. Aqui o TT fica no limite; opções: rampa máxima menor, robô mais leve, redução maior ou outro motor. Confira também tração: `μ · N_roda > F / n_motores`, senão a roda patina antes de faltar torque. Corrente de stall do motor escolhido vai para VOLTA dimensionar driver e bateria.

## 4. Fixação por carga e vibração

| Situação | Fixação | Evite |
|---|---|---|
| Motor, suporte estrutural | Parafuso M3 + porca autotravante (nylon) ou inserto roscado a quente | Parafuso direto no plástico desmontado várias vezes (espana) |
| Bateria | Suporte com encosto + cinta ou velcro industrial + batente | Só fita dupla face — vibração solta |
| Placa de circuito | Espaçadores M2,5/M3 nos furos da placa | Placa apoiada direto em metal (curto) |
| Sensor leve, sem esforço | Parafuso M2/M3 ou encaixe com trava | Cola quente como única fixação perto de motor (amolece com calor) |
| Metal com metal sob vibração | Trava-rosca de média resistência | Trava-rosca anaeróbico em plástico — pode trincar ABS/PC/PLA |

Vibração do motor solta tudo o que depende de atrito. Quem vibra (motor, bomba) pode ganhar coxim de TPU.

## 5. Impressão 3D

| Material | Quando usar | Limite |
|---|---|---|
| PLA | Protótipo, interno, pouco esforço | Amolece ~55–60 °C (sol, carro, perto de regulador); deforma sob carga constante |
| PETG | Padrão para robô: mais tenaz, aguenta ~75–80 °C e umidade | Fios finos (stringing); um pouco menos rígido |
| ABS / ASA | Calor e esforço; ASA ao ar livre (UV) | Empena; precisa impressora fechada e ventilação (vapores) |
| TPU | Pneu, para-choque, coxim, junta | Não é vedação certificada; difícil em extrusora bowden |

Folgas típicas em FDM (calibre com uma peça de teste — cada impressora difere):

| Encaixe | Folga por lado |
|---|---|
| Prensado (não sai à mão) | 0–0,1 mm |
| Deslizante (entra e sai) | 0,2–0,3 mm |
| Folgado (tampa, gaveta) | 0,4–0,5 mm |
| Furo passante M3 | desenhar 3,3–3,4 mm |
| Alojamento de porca M3 (5,5 mm entre faces) | desenhar 5,7–5,8 mm |
| Inserto roscado | diâmetro do fabricante do inserto |

Orientação — decida **antes** de fechar o desenho: a peça é mais fraca entre camadas (eixo Z), então a carga deve correr ao longo das camadas; furos verticais saem mais redondos; balanço acima de ~45° pede suporte; na face da mesa, chanfro em vez de arredondado. Resistência vem mais de 3–4 perímetros que de preenchimento alto.

OpenSCAD paramétrico — variáveis no topo, medida do usuário:

```openscad
// Suporte de motor TT — medidas do paquímetro do usuário (2026-11-14)
motor_l  = 22.4;  // largura medida do corpo
motor_h  = 18.8;  // altura medida
folga    = 0.25;  // encaixe deslizante
parede   = 3;     // 3 mm = ~7 perímetros de 0,42 mm
furo_m3  = 3.4;
largura  = 12;
aba      = 8;     // aba lateral para parafusar no chassi
L = motor_l + 2*(parede + folga);
difference() {
  union() {
    cube([L, largura, motor_h + parede + folga]);                 // corpo em U
    translate([-aba, 0, 0]) cube([L + 2*aba, largura, parede]);   // base com abas
  }
  translate([parede, -1, parede]) cube([motor_l + 2*folga, largura + 2, motor_h + folga + 1]);
  for (x = [-aba/2, L + aba/2])
    translate([x, largura/2, -1]) cylinder(d = furo_m3, h = parede + 2, $fn = 32);
}
// Orientação: imprimir com a base na mesa; carga do motor corre ao longo das camadas.
```

## 6. Umidade e poeira

| A geometria ajuda contra | A geometria NÃO garante contra |
|---|---|
| Respingo e gota de cima (tampa com aba, beiral) | Imersão e jato d'água |
| Poeira grossa (labirinto, tampa sobreposta) | Poeira fina e umidade sem junta |
| Água escorrendo pelo cabo (laço de gotejamento) | Condensação interna |

Peça FDM é porosa: água atravessa parede fina e frestas entre camadas. Resistência real pede junta (TPU, EPDM ou silicone), prensa-cabo, parafusos com passagem vedada — e mesmo assim só se declara grau IP com caixa certificada ou teste. Escreva o limite: "protege de respingo; não pode ser lavado com mangueira". Furo de dreno no ponto mais baixo para água não acumular.

Robô que usa água (pano úmido, bomba, reservatório):
- [ ] Eletrônica e bateria **acima** e fora da projeção vertical do reservatório, das mangueiras e do pano
- [ ] Reservatório no ponto mais baixo, com tampa que não fica sobre a eletrônica
- [ ] Mangueiras com abraçadeira em toda conexão; caminho que não passa sobre a placa
- [ ] Teste de vazamento só com água e eletrônica desconectada: papel-toalha embaixo, 30 min, foto do papel seco
- [ ] Massa da água cheia × vazia no orçamento (o CM se move conforme esvazia)

## 7. Cabos

- Alívio de tensão: abraçadeira ancorada no chassi antes do conector; o puxão vai para o chassi, não para a solda. Cola quente segura posição, não alivia tração repetida.
- Caminho: longe de rodas, engrenagens e bordas cortantes; laço de serviço onde há movimento (servo, tampa).
- Conectores: travados e polarizados (JST-XH/PH para sinal; XT30/XT60 para potência). Jumper Dupont solto sai com vibração — só na bancada.
- Etiqueta com o `W-NN` de VOLTA nas duas pontas; bitola e cor seguem `wiring.md`.
- Chave geral e porta de carga acessíveis sem desmontar.

## 8. Guia de montagem

`mechanics/assembly-guide.md`, no nível do usuário em `project/conventions.md`. Formato de cada passo:

```markdown
### Passo 7 — Fixar o suporte da bateria
- **Ação:** encaixe o suporte no chassi e aperte os 2 parafusos M3×10 com porca autotravante, até não girar com a mão.
- **Ferramenta:** chave Phillips nº 1, alicate de bico. · **Tempo:** 5 min
- **Resultado esperado:** suporte não balança ao empurrar com o dedo; bateria entra sem forçar e não sai com o robô de cabeça para baixo.
- **Foto:** de cima, mostrando os 2 parafusos e a bateria encaixada.
```

Um passo = uma ação verificável. Passo que depende de medida diz qual (`mass-budget`, folga) e o que fazer se não bater.

## 9. Problema de encaixe × problema de impressão

| Sintoma | Primeiro confira | É de |
|---|---|---|
| Peça não entra, dimensões externas certas | Medida de origem e folga no arquivo | Encaixe → redesenhar |
| Furos menores em todas as peças | Peça de teste de folga; compensação no fatiador | Impressão (ou calibrar folga) |
| Primeira camada larga ("pé de elefante") | Nivelamento, altura do bico, chanfro na base | Impressão |
| Quebra entre camadas | Orientação × direção da carga, temperatura | Impressão/orientação |
| Empenou nas pontas | Material, adesão, temperatura da mesa | Impressão |
| Encaixa, mas folgado | Folga escolhida grande demais | Encaixe |

Meça a peça impressa com paquímetro e compare com o arquivo: diferença em todas as cotas → impressão; só na cota de encaixe → desenho.

| Desculpa | Realidade |
|---|---|
| "O anúncio diz 70 × 22 mm" | Medida do usuário com paquímetro. Anúncio é chute. |
| "PLA serve para tudo" | Ao sol ou perto do regulador, PLA deforma. PETG como padrão. |
| "Caixa fechada é à prova d'água" | Geometria protege de respingo, não de imersão. Declare o limite. |

## Origem

Método adaptado (reescrito em pt-BR, sem copiar texto) de wedsamuel1230/embedded-engineering-skills (MIT, © 2026 Samuel F., commit 869710e) — `enclosure-designer` (medida do usuário vence tabela, folga deliberada, encaixe × impressão, sem promessa de estanqueidade, orientação antes de fechar).
