---
name: web-design-guidelines
description: Review de código UI contra as Vercel Web Interface Guidelines — carrega as guidelines (remoto ou cache local) e reporta violações em formato file:line. Use ao "revisar minha UI", "audit design", "review UX" ou checar o site contra as guidelines da Vercel. Para acessibilidade/WCAG, use a skill accessibility.
version: "1.0"
updated: "2026-09-04"
argument-hint: <file-or-pattern>
---

# Web Interface Guidelines

Review files for compliance with Web Interface Guidelines.

## How It Works

1. Carregar guidelines (remoto com fallback local — ver abaixo)
2. Ler os arquivos especificados (ou perguntar ao usuário)
3. Checar contra todas as regras das guidelines
4. Output findings no formato terse `file:line`

## Guidelines Source

**Estratégia: remoto primeiro, cache local como fallback**

```
Fonte remota: https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
Cache local:  .claude/skills/web-design-guidelines/guidelines-cache.md
```

**Fluxo de carregamento:**
1. Tentar WebFetch da URL remota
2. Se fetch falhar (timeout, 404, GitHub indisponível): usar cache local (`guidelines-cache.md`)
3. Se cache local também falhar: informar usuário e continuar com conhecimento interno

O cache local foi gerado em 2026-05-03 e cobre a versão atual. Para atualizar o cache manualmente:
```bash
curl -s https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md \
  > .claude/skills/web-design-guidelines/guidelines-cache.md
```

## Usage

Quando o usuário fornecer arquivo ou padrão como argumento:
1. Carregar guidelines (remoto ou cache local)
2. Ler os arquivos especificados
3. Aplicar todas as regras das guidelines
4. Output no formato especificado nas guidelines

Se nenhum arquivo especificado, perguntar ao usuário quais arquivos revisar.
