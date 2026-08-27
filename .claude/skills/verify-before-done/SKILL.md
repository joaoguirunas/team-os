---
name: verify-before-done
description: Verificação obrigatória antes de declarar qualquer trabalho como concluído — evidência antes de afirmação. Use SEMPRE antes de dizer que algo "está pronto", "funciona", "passa nos testes", "está corrigido" ou antes de commit/marcar story como done. Gatilhos - concluir tarefa, fechar story, reportar sucesso, emitir veredicto de QA, dar bug como resolvido.
version: "1.0"
updated: "2026-08-26"
---

# Verify Before Done

Skill de disciplina de verificação destilada do verification-before-completion do Superpowers (obra/superpowers). Aplica-se a **todos os agentes do team-os** — em especial implementers (**dev-dev-\*, sites-dev-\*, social-video**) antes de marcar tasks/stories como concluídas, **dev-qa / sites-qa / traffic-qa / pm-qa** antes de emitir veredictos, e o lead antes de reportar progresso ao usuário.

## Princípio central

**Evidence before claims, always.** Nenhuma afirmação sobre estado de trabalho, qualidade de código ou conclusão de tarefa sem evidência fresca que a suporte.

## The Gate — 5 passos antes de qualquer claim de sucesso

1. **IDENTIFY** — qual comando/checagem prova a afirmação?
2. **RUN** — execute-o por completo, AGORA (evidência fresca, não de 20 minutos atrás).
3. **READ** — leia o output inteiro e o exit code, não só a última linha.
4. **VERIFY** — o output realmente suporta a afirmação? (0 failures? exit 0? sintoma original sumiu?)
5. **CLAIM** — só então afirme, citando a evidência.

Pular qualquer passo = verificação falsa. "Rodei antes do último edit" não conta — qualquer mudança invalida a evidência anterior.

## Red flags — linguagem que denuncia claim prematuro

Se você está prestes a escrever qualquer uma destas frases SEM ter acabado de rodar a verificação, pare e rode:

```
❌ "should work now"        ❌ "deve funcionar agora"
❌ "probably passes"        ❌ "provavelmente está ok"
❌ "I believe this fixes"   ❌ "isso deve resolver"
❌ "the tests should pass"  ❌ "acredito que está pronto"
```

Outras red flags:
- Satisfação antecipada ("Perfeito!", "Pronto!") antes de rodar o check.
- Confiar em verificação parcial (rodou 1 teste, afirma que a suíte passa).
- **Confiar no report de um subagente** sem verificar o resultado real (agentes reportam sucesso com trabalho incompleto — verifique arquivos/testes você mesmo).
- Afirmar com base em leitura de código ("o código parece certo") em vez de execução.

## Tabela de claims → evidência exigida

| Claim | Evidência mínima |
|---|---|
| "Testes passam" | Output fresco da suíte com **0 failures**, exit 0 |
| "Lint/typecheck limpo" | Output do linter/tsc com **0 errors** |
| "Build funciona" | Build completo com **exit code 0** |
| "Bug corrigido" | Reprodução do sintoma original → confirmado ausente |
| "Regression test cobre o bug" | Ciclo **red-green documentado**: teste falha sem o fix, passa com o fix |
| "Feature completa" | Todos os critérios de aceite da story checados um a um contra o comportamento real |
| "Migration segura" | Dry-run + smoke-test executados (protocolo do data engineer) |
| "Campanha pronta" | Checklist pré-launch + conversão de teste real (squad traffic) |
| "Story done" | Tudo acima que se aplique + `check-story-progress.sh` verde |

## Bloqueio de racionalizações

Toda desculpa recebe a mesma resposta — a evidência importa, nada mais:

- *"Estou cansado / é só desta vez"* → rode o check.
- *"Tenho certeza que funciona"* → confiança não é evidência. Rode o check.
- *"É uma mudança trivial"* → mudanças triviais quebram builds todos os dias. Rode o check.
- *"O usuário está com pressa"* → reportar sucesso falso custa mais tempo do que verificar. Rode o check.
- *"Já rodei há pouco"* → houve edit depois? Então a evidência expirou. Rode de novo.

## Quando aplicar

**Sempre**, antes de:
- Qualquer expressão de sucesso ou satisfação com o trabalho
- Marcar task/story/todo como concluído (TaskList nativo incluído)
- Fazer commit (e antes de o devops fazer push)
- Emitir veredicto de QA (PASS/CONCERNS/FAIL — um PASS sem evidência fresca é FAIL do próprio QA)
- Reportar progresso ao lead ou ao usuário
- Encerrar a sessão com entregas "prontas"

## Formato do report com evidência

```
✅ Suíte completa: 142 passed, 0 failed (npx vitest run — exit 0)
✅ Typecheck: 0 errors (tsc --noEmit)
✅ Bug #231: reproduzi o sintoma no commit anterior, ausente após o fix
→ Story pronta para QA.
```

Nunca:

```
❌ "Implementei tudo, deve estar funcionando. Marquei a story como done."
```

---

Adaptado de obra/superpowers → verification-before-completion (skills.sh) — 2026-08-26.
