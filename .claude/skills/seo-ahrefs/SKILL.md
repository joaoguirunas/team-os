---
name: seo-ahrefs
description: "Analista da API Ahrefs via MCP @ahrefs/mcp — referring domains, backlinks, keywords orgânicas e Content Explorer. Combina com seo-backlinks para ponderação de confiança multi-fonte. Use ao pedir dados Ahrefs, DR/UR ou backlinks ao vivo."
version: "2.3.1"
updated: "2026-09-25"
user-invocable: true
argument-hint: "[metrics|backlinks|organic|content] <url|topic>"
metadata:
  version: "2.3.1"
compatibility: "Testada com o MCP @ahrefs/mcp@0.0.11; exige o servidor MCP configurado com o token da Ahrefs (env API_KEY)."
---

# seo-ahrefs

Live Ahrefs data via the tested `@ahrefs/mcp@0.0.11` server.
Package check (2026-07-10): verify the current Ahrefs MCP package source before changing this tested version.

## Prerequisites

- An Ahrefs API token (https://ahrefs.com/api).
- Register the Ahrefs MCP server in the project's `.mcp.json` (or `claude mcp add ahrefs -e API_KEY=<token> -- npx -y @ahrefs/mcp@0.0.11`), passing the token through the `API_KEY` environment variable. No installer script ships with this pack.
- Node 18+ on `$PATH` for the MCP server.

Before calling any Ahrefs tool, verify the MCP is connected by checking
that any Ahrefs MCP tool is available in this session. If tools are
not available, tell the user the Ahrefs MCP server is not configured and
point to the `.mcp.json` / `claude mcp add` setup above.

## Routing

| Command | Action |
|---|---|
| `/seo ahrefs metrics <url>` | Domain / URL rating, referring domain count, organic traffic estimate |
| `/seo ahrefs backlinks <url>` | Top referring domains, anchor distribution, follow/nofollow ratio |
| `/seo ahrefs organic <url>` | Organic keywords, ranking distribution, traffic by country |
| `/seo ahrefs content <topic>` | Content Explorer top results, social shares, referring domains |

## Output conventions

- Cite the data source on every metric: "Ahrefs (live, confidence 1.00)".
- When Ahrefs and Moz disagree on the same metric, trust Ahrefs and note the discrepancy in the report.
- Toxic link assessment: combine Ahrefs backlink quality signals with the existing seo-backlinks Common Crawl + verify crawler signals.

## Cross-skill delegation

- For multi-source confidence weighting across Moz + Bing + Common Crawl + Ahrefs, hand back to `seo-backlinks`.
- For SERP-feature analysis where Ahrefs and DataForSEO overlap, prefer DataForSEO for live SERP data.

## Cost guardrails

Ahrefs API usage is metered per unit. Before running a batch (>= 50 URLs):

1. Estimate cost with `"${CLAUDE_PROJECT_DIR}/.claude/skills/seo/scripts/claude-seo" run dataforseo_costs.py` (the cost-tracker module is generic and supports Ahrefs unit accounting).
2. Surface the estimate to the orchestrator.
3. Log actual cost after each call.

This is the same workflow the seo-dataforseo skill uses.
