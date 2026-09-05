---
name: social-analytics
description: Análise de métricas de redes sociais — KPIs por objetivo, benchmarks por plataforma, templates de relatório e otimização baseada em dados. Use ao analisar performance de campanhas sociais, montar relatório de métricas, comparar resultados com benchmarks ou decidir ajustes de conteúdo com base em dados.
version: "1.0"
updated: "2026-09-04"
---

# Social Analytics — Métricas e Relatórios

> Skill injetada no agente PULSE (social-publisher).

## KPIs por objectivo de campanha

### Awareness
- **Reach:** Contas únicas alcançadas
- **Impressions:** Total de visualizações
- **Brand mentions:** Menções espontâneas

### Engagement
- **Engagement Rate:** (likes + comments + shares + saves) / reach × 100
- **Comments:** Qualidade (positivos/negativos) e volume
- **Saves:** Indicador forte de valor percebido
- **Shares:** Amplificação orgânica

### Conversão
- **Click-through Rate (CTR):** Cliques / impressões × 100
- **Link clicks:** Cliques no link da bio ou CTA
- **Story swipe-ups:** (se conta verificada)

### Vídeo específico
- **Video completion rate:** Viram até ao fim / iniciaram × 100
- **Average watch time:** Segundos médios vistos
- **Replays:** Viram mais de uma vez

## Benchmarks por plataforma

| Plataforma | ER bom | ER excelente | CTR médio |
|---|---|---|---|
| Instagram | 1-3% | > 5% | 0.22% |
| TikTok | 5-10% | > 15% | — |
| Facebook | 0.5-1% | > 3% | 0.9% |
| LinkedIn | 0.5-2% | > 5% | 0.4% |

## Template de relatório

```markdown
## Relatório de Performance — [Campanha]
**Período:** [data início] → [data fim]
**Plataformas:** ...

---

### Métricas de Alcance
| Métrica | Resultado | vs Benchmark | Tendência |
|---|---|---|---|
| Reach | X | +/-X% | ↑↓→ |
| Impressions | X | — | — |

### Métricas de Engagement
| Métrica | Resultado | vs Benchmark |
|---|---|---|
| ER | X% | +/-X% |
| Saves | X | — |
| Comments | X | — |

### Insights
1. **Melhor performing:** [post/formato/horário]
2. **Pior performing:** [post/formato/horário]
3. **Padrão identificado:** ...

### Recomendações para próxima campanha
1. ...
2. ...
```

## Frequência de reporting
- **Semanal:** Quick check de métricas principais
- **Mensal:** Relatório completo com tendências
- **Por campanha:** Relatório fechado após fim da campanha

## Skills relacionadas
- UTMs, atribuição e GA4 → carregue a skill `/traffic-analytics-tracking`.
