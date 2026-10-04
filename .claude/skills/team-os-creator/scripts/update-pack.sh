#!/usr/bin/env bash
# update-pack.sh — `/team-os-creator *update`: atualiza o pack team-os nesta pasta
# SEM perder o que você criou ou editou. Nunca faz git commit/pull/push/checkout e
# não mexe no índice git: trabalha arquivo por arquivo.
#
# Uso:
#   update-pack.sh [--check]                 o que mudaria (padrão; não grava nada no CT)
#   update-pack.sh --apply [--yes]           baixa, confere (sha256 de cada arquivo) e aplica
#   update-pack.sh --status                  versão instalada, arquivos editados, pendências
#   update-pack.sh --resolve <arquivo>=keep  mantém o seu e descarta o <arquivo>.new (Lixeira)
#   update-pack.sh --resolve <arquivo>=new   usa o novo; o seu vai para .team-os/backups/
#   update-pack.sh --undo                    desfaz o último --apply (ou --resolve new)
# Opções:
#   --to vX.Y.Z       versão alvo (padrão: a maior tag vX.Y.Z do upstream)
#   --from <pasta>    usa uma cópia local do pack como fonte (offline / testes)
#   --upstream <url>  outro repositório (padrão: o `upstream` do pack-manifest.json local)
#   --root <pasta>    pasta do team-os (padrão: 4 pastas acima deste script)
#
# Como decide, arquivo por arquivo (novo manifest × .team-os/installed.json × disco):
#   do pack, sem edição sua, mudou no novo ......... substitui (cópia em .team-os/backups/<ts>/)
#   do pack, editado por você, mudou no novo ....... NÃO sobrescreve: grava <arquivo>.new (CONFLICT)
#   do pack, editado por você, pack não mudou ...... mantém
#   novo no pack ................................... adiciona (já existe um seu com o nome → CONFLICT)
#   saiu do pack ................................... move para .team-os/removed/<ts>/
#   fora do manifest (seus agentes/skills/presets) . nunca toca
# Depois: grava installed.json, reinjeta o bloco Native Teams Protocol nos agentes
# `origin: custom`, roda o validate-agent.sh e escreve .team-os/update-report.md.
# Backups: guarda os 3 mais recentes; os antigos vão para a Lixeira (trash.sh).
#
# Saída KEY=value (ROOT, CURRENT_VERSION, LATEST_VERSION, UPDATE_AVAILABLE, FILES_*,
# UPDATE/ADD/REMOVE/CONFLICT=<arquivo>, CHANGELOG_FILE, CHANGED=<arquivo>, PENDING, ERROR…).
# Exit: 0 ok · 1 erro · 2 há conflitos pendentes (só aviso).
# Requer python3 (já exigido pelo team-os-creator). Bash 3.2-safe.

HERE="$(cd "$(dirname "$0")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR=python3 não encontrado — instale o Python 3 para usar o *update"
  exit 1
fi
if [ ! -f "$HERE/update-pack.py" ]; then
  echo "ERROR=update-pack.py não encontrado em $HERE"
  exit 1
fi
# exec: o bash sai de cena — trocar este arquivo durante o update é seguro
exec python3 "$HERE/update-pack.py" "$@"
