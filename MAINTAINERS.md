# Guia do mantenedor

Este arquivo é só para quem **mantém o pack oficial** (hoje, João Guirunas). Quem usa o pack não precisa dele: baixa com `git clone`, cria os próprios agentes e recebe as versões novas com `/team-os-creator *update` (veja o [README](./README.md#instalar-e-atualizar)). Quem quer contribuir com uma melhoria, veja o [CONTRIBUTING.md](./CONTRIBUTING.md).

## Quem é o mantenedor

O mantenedor é identificado pelo arquivo **`.team-os-maintainer`**, na raiz do repositório. Ele é ignorado pelo git (`.gitignore`), então só existe na máquina de quem mantém o pack. É esse arquivo que liga o ciclo desta página:

- **Commit, push, tag e CHANGELOG no CT são só do mantenedor.** Sem o arquivo, os scripts e as skills não fazem nem sugerem nada disso.
- Com o arquivo, o `*create` gera agentes **do pack** (registrados no preset da squad) em vez de agentes próprios (`origin: custom`), e o `*update --apply` é recusado nesta pasta (aqui o caminho é o release).
- O `release.sh` recusa rodar sem ele.

Para virar mantenedor numa máquina, basta criar o arquivo vazio: `touch .team-os-maintainer`.

## O ciclo do mantenedor

```
1. Editar agente/skill/hook AQUI (agentes via /team-os-creator; nunca direto num projeto destino)
2. validate-agent.sh            → 102/102 agentes do pack conformes (= *audit)
3. validate-agent.sh --skills   → lint das 112 skills
4. test-hooks.sh                → todos os casos dos hooks
   test-update.sh               → teste do *update (se mexeu em update/manifest/propagação)
   test-propagate.sh            → teste do *install/*propagate (precisa de rsync)
5. generate-agents-page.py      → regenera docs/agentes.html
6. pack-manifest.sh             → regenera pack-manifest.json (o CI confere com --check)
7. CHANGELOG.md                 → descrever em "## [Não lançado]" (Adicionado / Alterado / Corrigido)
8. commit no CT                 → Conventional Commits em português, um por assunto
9. /team-os-creator *propagate  → leva aos projetos destino (--match-target-squads); commit de cada projeto é feito na sessão dele
10. release.sh X.Y.Z            → fecha a versão (veja abaixo)
11. push MANUAL                 → o comando é impresso pelo release.sh; quem executa é o mantenedor
```

Todos os scripts ficam em `.claude/skills/team-os-creator/scripts/` (rode com `bash`, a partir da raiz). Os passos 2 a 6 se repetem no CI (`.github/workflows/audit.yml`), que ainda confere as contagens "102 agentes" e "112 skills" no `README.md` e no `CLAUDE.md` (contadas pelo manifest), zero caminho de máquina versionado e `docs/agentes.html` em dia.

## Como fazer um release

Pré-condições: arquivo `.team-os-maintainer` na raiz, branch `main`, tudo commitado (o release aceita alteração apenas em `VERSION`, `CHANGELOG.md`, `docs/agentes.html` e `pack-manifest.json`) e a seção `## [Não lançado]` do CHANGELOG com conteúdo.

```bash
# 1) ensaio — mostra o que faria e não altera nada
bash .claude/skills/team-os-creator/scripts/release.sh 2.5.0 --dry-run

# 2) de verdade
bash .claude/skills/team-os-creator/scripts/release.sh 2.5.0
```

O `release.sh` faz, nesta ordem:

1. recusa se faltar `.team-os-maintainer`, se não estiver na `main`, se a tag `vX.Y.Z` já existir, se a versão for menor que a atual ou se o `[Não lançado]` estiver vazio;
2. grava `VERSION`; converte `## [Não lançado]` em `## [X.Y.Z] — AAAA-MM-DD` e recria um `## [Não lançado]` vazio acima;
3. regera `docs/agentes.html` e o `pack-manifest.json`;
4. roda `validate-agent.sh`, `validate-agent.sh --skills`, `test-hooks.sh`, `test-update.sh` e `test-propagate.sh` sobre o resultado. Se algum falhar, devolve os 4 arquivos ao estado de antes e para (o `BACKUP_DIR=` impresso guarda as cópias);
5. cria o commit `release: vX.Y.Z` e a tag **anotada** `vX.Y.Z`, só localmente;
6. **imprime** o comando de publicação e para:

```bash
git push origin main vX.Y.Z
```

O script **nunca dá push**. Rode o comando impresso quando quiser publicar. É a tag `vX.Y.Z` publicada que o `*update` dos usuários procura (maior tag semver do repositório), e o `pack-manifest.json` daquela tag é o que eles conferem arquivo por arquivo antes de atualizar — por isso o release regera tudo antes da tag.

Se precisar desfazer um release **ainda não publicado**: `git tag -d vX.Y.Z` e `git reset --soft HEAD~1` (só se o último commit for o `release: vX.Y.Z`; o `--soft` desfaz o commit mas **mantém** as alterações no disco, então nada se perde).

## Como regerar o manifest

O `pack-manifest.json` (raiz) lista, com sha256, os arquivos que **são do pack**: `.claude/agents/*.md` (menos agentes `origin: custom`), `.claude/skills/**` (menos `presets/custom/` e lixo de runtime), `.claude/hooks/*.sh` e os documentos do pack (`README.md`, `CHANGELOG.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `MAINTAINERS.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `VERSION`). Tudo que não está nele é do usuário e o `*update` nunca toca.

```bash
bash .claude/skills/team-os-creator/scripts/pack-manifest.sh          # gera/atualiza
bash .claude/skills/team-os-creator/scripts/pack-manifest.sh --check  # só confere (é o que o CI roda)
```

Sempre que mudar qualquer arquivo do pack, regere o manifest antes do commit — senão o CI falha em "manifest em dia". Novo documento do pack? Acrescente-o à lista `DOCS` de **dois** lugares: `pack-manifest.sh` e `update-pack.py`.

## Regras que valem sempre

- O CT é a fonte da verdade: nada de editar agente direto num projeto destino; a partir do CT só se roda `*install`/`*propagate`.
- Nenhum script ou skill distribuído pode fazer `git commit`/`git push`, nem propor isso a um usuário comum.
- Nada específico de máquina em arquivo versionado (use `<raiz>/...`); o CI confere.
- Scripts compatíveis com bash 3.2 (macOS) e Linux: sem `mapfile`, `${x,,}`, `declare -A`, `grep -P`.
- Agente do pack novo passa por `*pressure-test` antes do `*propagate`.
