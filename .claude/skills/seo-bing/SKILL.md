---
name: seo-bing
description: "Bing Webmaster Tools + IndexNow — visibilidade no Bing (que alimenta as citações do Microsoft Copilot), dados de links e submissão de URLs via IndexNow. Use para indexação fora do Google (Bing, Yandex, Naver) ou citação no Copilot."
version: "2.3.1"
updated: "2026-09-25"
user-invocable: true
argument-hint: "[links|compare|submit|submit-batch|verify-indexnow] <url>"
metadata:
  version: "2.3.1"
compatibility: "Exige BING_WEBMASTER_API_KEY e, opcionalmente, INDEXNOW_KEY e INDEXNOW_KEY_LOCATION como variáveis de ambiente (ex.: bloco env do ~/.claude/settings.json)."
---

# seo-bing

The non-Google indexing surface. Google still rejects IndexNow (per
Gary Illyes, multiple SOTR episodes 2024-2025), so this skill is
specifically for **Amazon/Bing/Naver/Seznam.cz/Yandex/Yep indexing** and
**Microsoft Copilot AI citation** (which pulls from the Bing index).

## Prerequisites

- A Bing Webmaster Tools API key exported as `BING_WEBMASTER_API_KEY` (environment variable, e.g. in the `env` block of `~/.claude/settings.json`). The scripts read it directly; there is no installer script in this pack.
- Optional: an IndexNow host key (32+ chars) published at the URL
  declared as `INDEXNOW_KEY_LOCATION`.

## Routing

| Command | Underlying script |
|---|---|
| `/seo bing links <url>` | `"${CLAUDE_PROJECT_DIR}/.claude/skills/seo/scripts/claude-seo" run bing_webmaster.py links <url>` |
| `/seo bing compare <urlA> <urlB>` | `"${CLAUDE_PROJECT_DIR}/.claude/skills/seo/scripts/claude-seo" run bing_webmaster.py compare <urlA> <urlB>`; both properties must be registered to the API account |
| `/seo bing submit <url>` (single URL) | `"${CLAUDE_PROJECT_DIR}/.claude/skills/seo/scripts/claude-seo" run indexnow_submit.py --host ... --urls <url>` |
| `/seo bing submit-batch <file>` | `"${CLAUDE_PROJECT_DIR}/.claude/skills/seo/scripts/claude-seo" run indexnow_submit.py --host ... --urls-file <file>` |
| `/seo bing verify-indexnow` | `"${CLAUDE_PROJECT_DIR}/.claude/skills/seo/scripts/claude-seo" run indexnow_submit.py --host ... --verify-only` |

## When this skill applies

- The user is publishing new pages and wants Microsoft Copilot
  citation eligibility (Bing index ingestion).
- The user wants to nudge Amazon/Bing/Naver/Seznam.cz/Yandex/Yep indexing for fresh
  URLs.
- The user manages both properties and wants to compare their Bing link data.
  For an arbitrary competitor, route to DataForSEO, Moz, or Common Crawl.

## Cross-skill delegation

- For Google indexing (very different model, sitemap-driven, no
  IndexNow), use `seo-google indexing`.
- For multi-source backlink confidence weighting, fall back to
  `seo-backlinks` which already integrates Bing + Moz + CC.
