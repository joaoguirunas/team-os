# Fórmulas — referência rápida

Todas em pseudo-notação; copie para a aba `Cálculo` da planilha como fórmula, nunca como valor.

## Preço e desconto

```
equivalente_mensal      = SUM(tabela_entregas_recorrentes)
entregas_unicas         = SUM(tabela_entregas_unicas)
desconto_efetivo_pct    = 1 - cobrado_mensal / equivalente_mensal
desconto_mensal_reais   = equivalente_mensal - cobrado_mensal
desconto_acumulado      = desconto_mensal_reais * meses_com_desconto + entregas_unicas_incluidas
```

## Custo, margem e breakeven

```
custo_implantacao       = horas_implantacao * custo_hora_medio
investimento_inicial    = custo_implantacao + entregas_unicas_incluidas_sem_cobranca
margem_mensal           = cobrado_mensal - custo_operacao_mensal
breakeven_meses         = investimento_inicial / margem_mensal
exposicao_saida(m)      = investimento_inicial - margem_mensal * m      ; m = meses cumpridos
```
Alerta se `breakeven_meses > prazo_minimo_garantido`.

## Payback do cliente

```
; Conta A — receita
ganho_mensal_A          = volume_oportunidades_mes * (taxa_alvo - taxa_atual) * ticket_medio * margem_cliente
payback_A_meses         = cobrado_mensal / ganho_mensal_A
melhora_necessaria_pp   = cobrado_mensal / (volume_oportunidades_mes * ticket_medio * margem_cliente)   ; em pontos percentuais

; Conta B — horas
economia_mensal_B       = tarefas_mes * pct_automatizada * tempo_medio_h * custo_hora_cliente
payback_B_meses         = cobrado_mensal / economia_mensal_B
```

## Permuta

```
ref_nosso_lado_mensal   = SUM(tabela_entregas_nossas_recorrentes)
ref_nosso_lado_unico    = SUM(tabela_entregas_nossas_unicas)
ref_lado_deles_mensal   = SUM(tabela_veiculacoes_mensais)
equilibrio_mensal       = ref_lado_deles_mensal / ref_nosso_lado_mensal
equilibrio_acumulado(n) = (ref_lado_deles_mensal * n) / (ref_nosso_lado_mensal * n + ref_nosso_lado_unico)
```

## Captação

```
valuation_post_money    = aporte / participacao_entrada
valuation_no_degrau(k)  = aporte / participacao_degrau_k
multiplo_sobre_LTM      = valuation_post_money / receita_LTM

; Régua de valuation por EBITDA (serviço com recorrência)
valor_empresa           = EBITDA_LTM * multiplo_categoria           ; multiplo com fonte e faixa
valor_participacao      = valor_empresa * participacao_final
retorno_x               = (valor_participacao + dividendos_acumulados) / aporte

; Sensibilidade — margem normalizada
EBITDA_normalizado      = receita_LTM * margem_setor
valor_empresa_norm      = EBITDA_normalizado * multiplo_categoria
```

## Projeção por coorte (MRR)

```
MRR(t)                  = SUM_k [ novos_contratos(k) * ticket * retencao^(t-k) ]   ; k <= t
receita_mensal(t)       = MRR(t) + vendas_pontuais(t) * ticket_pontual
churn_mensal            = contratos_perdidos / contratos_inicio_mes
runway_meses            = caixa / burn_mensal
```

## Convenções de apresentação

- % com 0 ou 1 decimal, sempre arredondado para baixo; R$ sem centavos acima de R$ 1.000
- Escrever a **hipótese** ao lado de todo dado não verificado
- Placeholders: `R$ ____` e `[A LEVANTAR: dado]` — nunca número provisório
