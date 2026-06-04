# Claude Agent Teams

A complete configuration package for [Claude Code](https://claude.ai/code) with **Agent Teams** — **49 pre-built agents** organized into 5 squads (Dev, Sites, Social, Traffic, PM), 50+ skills, and the `team-os` orchestration system — with built-in **Graphify knowledge graph** integration for structural project awareness.

> Built on top of Claude Code's experimental Agent Teams feature. Drop `.claude/` into any project, run `/team-os-creator *install`, and get a full multi-agent squad working immediately.

---

## What's inside

```
.claude/
├── agents/                  # 49 teammate agents (5 squads)
│   ├── dev-*.md             # Dev squad (12 agents)
│   ├── sites-*.md           # Sites squad (10 agents)
│   ├── social-*.md          # Social squad (7 agents)
│   ├── traffic-*.md         # Traffic squad (10 agents)
│   └── pm-*.md              # PM squad — Kaelthari (10 agents)
│
├── skills/                  # 50+ skills (slash commands)
│   ├── team-os/             # Lead orchestrator (/team-os)  ← smart-memory owner
│   ├── team-os-creator/     # Agent factory + installer (/team-os-creator)
│   ├── dev-*/               # Dev skills (TypeScript, API design, testing, etc.)
│   ├── sites-*/             # Sites skills (SEO, CRO, Tailwind, shadcn/ui, scroll-motion, etc.)
│   ├── social-*/            # Social skills (copywriting, video, analytics, etc.)
│   ├── traffic-*/           # Traffic skills (TikTok, paid ads)
│   ├── ui-ux-pro-max/       # Design system (161 palettes, 57 fonts, 99 UX guidelines)
│   ├── accessibility/       # WCAG 2.2 AA (Addy Osmani patterns)
│   └── web-design-guidelines/
│
├── hooks/                   # Automation hooks (squad-filtered on install)
│   ├── block-git-push.sh    # Blocks direct pushes (only devops agents can push)
│   ├── check-story-progress.sh
│   └── check-social-progress.sh
│
└── settings.json            # Enables CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

> **Note on skills dependencies:** Skills installed via `npx skills add` are stored as symlinks in `.claude/skills/` pointing to `.agents/skills/`. After cloning, restore them with:
> ```bash
> npx skills experimental_install
> ```

---

## Prerequisites

- **Claude Code** — latest version ([download](https://claude.ai/code))
- **Claude Pro or Team plan** — Agent Teams requires API access
- macOS, Linux, or Windows (WSL2)
- **Graphify** (optional, for knowledge graph) — `uv tool install graphifyy`

---

## Install into a project

### Option A — Use `/team-os-creator` (recommended)

Clone this repo as your Centro de Treinamento, open Claude Code inside it, and run:

```
/team-os-creator *install
```

The skill will:
1. Scan sibling projects automatically
2. Let you choose the target project and which squads to install
3. Copy the right agents + skills (always includes `team-os` as a core dependency)
4. Create `.claude/settings.json` with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
5. Filter hooks to only include what's relevant for the selected squads

Then open Claude Code **inside the target project** and run `/team-os`.

### Option B — Clone directly

```bash
cd your-project
git clone https://github.com/joaoguirunas/claude-agent-teams.git /tmp/cat
cp -R /tmp/cat/.claude .
```

### Option C — Symlink (stays updated)

```bash
git clone https://github.com/joaoguirunas/claude-agent-teams.git ~/claude-agent-teams
cd your-project
ln -s ~/claude-agent-teams/.claude .claude
```

After installing via B or C, reload Claude Code in the project directory and run `/team-os`.

---

## Quick start

```
/team-os
```

Claude Code detects the project state and routes automatically:

- **New project** (`docs/smart-memory/` absent) → proposes a full bootstrap: Graphify scan + parallel discovery team populates smart-memory with real data
- **Existing smart-memory** with active stories → resumes in-progress work
- **Ready state** → asks for your objective and assembles the minimum viable team

---

## Key concepts

### Agent Teams (not subagents)

This package uses Claude Code's native Agent Teams: agents run in parallel, communicate via `SendMessage`, and share a task list. The team lead (`/team-os` skill) is always the main session — nested orchestration is not used.

### Separation of responsibilities

| Responsibility | Owner |
|---|---|
| Create agents, install squads, wire settings | `/team-os-creator` |
| Initialize smart-memory, run discovery, orchestrate work | `/team-os` |
| Writing code, research, QA, deploys | Agents |

**`/team-os-creator` never touches `docs/smart-memory/`** — if it did, `team-os`'s state detection would see the structure as existing and skip the real bootstrap. Smart-memory is initialized with actual project data when the user first runs `/team-os`.

### Smart-memory

A shared `docs/smart-memory/` directory (Obsidian-compatible) acts as the source of truth between agents. Created and owned exclusively by `/team-os`. It holds:
- Project modules, architecture, tech stack — enriched with **God Nodes** (high-impact files)
- Story backlog and active stories
- Delegation log and team history

### Graphify knowledge graph (3-layer integration)

At bootstrap, `team-os` runs [Graphify](https://github.com/safishamsi/graphify) (`uv tool install graphifyy`) against the project to build a structural knowledge graph using AST parsing — zero API cost, pure static analysis.

**Layer 1 — Discovery:** `graphify` outputs `graphify-out/GRAPH_REPORT.md` with god nodes (highest-connectivity files), dependency clusters, and module boundaries. `dev-architect` and `dev-analyst` consume this before creating the smart-memory. Then `graphify-out/` is deleted (transient, not persisted).

**Layer 2 — Implementation:** Every dev agent has a **step 1.5** that checks god nodes in `modules.md` before touching any code. If the story intersects a god node: coverage ≥ 80% mandatory, formal QA required.

**Layer 3 — Maintenance:** After each merge, `dev-devops` / `sites-devops` checks if > 10 files changed and runs `graphify update` to refresh the graph, notifying team-os so `modules.md` stays current.

**God Nodes in `modules.md`:**
```markdown
## ⚡ God Nodes
| Arquivo | Conexões | Impacto |
|---|---|---|
| src/lib/auth.ts | 14 | autenticação, sessões, middleware |
```

### Team naming

Teams are named `{project-folder}-{objective-slug}` (e.g. `myapp-refactor-auth`) to avoid collisions in `~/.claude/teams/`.

### Push control

Only `dev-devops` (or `sites-devops`) can run `git push` and create PRs. The `block-git-push.sh` hook prevents other agents from pushing directly.

---

## Agents

### Dev Squad

| Agent | Role |
|---|---|
| `dev-analyst` | Research, library comparison, CVE investigation |
| `dev-architect` | Architecture decisions, ADRs, story creation (exclusive) |
| `dev-ux` | UX research, wireframes, component specs |
| `dev-dev-alpha` | Frontend (React, Next.js, Tailwind) |
| `dev-dev-beta` | Backend (APIs, services, business logic) |
| `dev-dev-gamma` | Fullstack / cross-layer integration |
| `dev-dev-delta` | Hardening and resilience (runs after features are built) |
| `dev-qa` | Quality gates — issues formal PASS / CONCERNS / FAIL verdicts |
| `dev-devops` | Git push, PR creation, CI/CD (exclusive authority) |
| `dev-data-engineer` | Schema design, migrations, RLS, query optimization |
| `dev-bi` | Kairo — SELECT-only DB queries, analytics engineering, metric dictionary, KPIs, OKRs, dashboard specs, Big Data strategy |
| `dev-data-performance` | Sigma — performance insights, anomaly detection, trend forecasting, EDA, ML on-demand, strategic recommendations |

### Sites Squad

Mirror of the Dev squad but tuned for website/marketing projects (Next.js, Vercel, SEO, CRO, accessibility).

| Agent | Role |
|---|---|
| `sites-analyst` | Keyword research, competitor analysis, SEO research |
| `sites-architect` | Page structure, tech stack, story creation |
| `sites-ux` | UX research, visual design, interaction patterns |
| `sites-dev-alpha` | Frontend (React, Next.js, shadcn/ui, landing pages) |
| `sites-dev-beta` | Backend (CMS integrations, server-side, APIs) |
| `sites-dev-gamma` | Fullstack / CRO / analytics wiring |
| `sites-dev-delta` | Performance hardening, Core Web Vitals, edge cases |
| `sites-qa` | QA gates, accessibility checks, SEO validation |
| `sites-devops` | Vercel/Netlify deployments, CI/CD, releases |
| `sites-data` | Database schema, migrations, RLS |

### Social Squad

| Agent | Role |
|---|---|
| `social-strategist` | VERA — editorial validator, must approve before publishing |
| `social-content` | LYRIS — research via Apify + captions, scripts, hashtags |
| `social-analyst` | Trend research, competitor analysis, platform analytics |
| `social-design` | AEON — carousels, Key Visuals via Google Stitch |
| `social-photo` | IRIS — AI photo generation via Freepik |
| `social-video` | FLUX — Reels, TikToks, Shorts via ffmpeg |
| `social-publisher` | PULSE — publishes via Meta API after VERA approves |

### Traffic Squad

Cross-platform paid traffic squad (Google Ads, Meta Ads, TikTok Ads). Strategy-first flow: `traffic-strategist` creates the brief, `traffic-qa` must PASS before any campaign goes live.

| Agent | Role |
|---|---|
| `traffic-strategist` | Campaign strategy, budget allocation, KPIs, briefings (exclusive story authority) |
| `traffic-analyst` | Market intelligence — audiences, competitors, benchmarks, diagnosis |
| `traffic-qa` | Pre-campaign QA — UTMs, pixels, compliance, creatives (PASS/FAIL exclusive) |
| `traffic-bi` | BI & attribution — ROAS, LTV, CPA, multi-touch (official metrics source) |
| `traffic-copywriter` | Ad copy — headlines, descriptions, CTAs, A/B variants per platform |
| `traffic-designer` | Ad creatives — banners, carousels, video assets, Stories |
| `traffic-google` | Google Ads — Search, Performance Max, Shopping, YouTube, Display |
| `traffic-meta` | Meta Ads — Facebook + Instagram, Advantage+, retargeting, lookalike, CAPI |
| `traffic-tiktok` | TikTok Ads — Spark Ads, In-Feed, TopView, Brand Takeover |
| `traffic-automation` | Bulk ops scripts, Google/Meta/TikTok API integrations, data pipelines |

### PM Squad — Kaelthari

Project Management squad built for any company and any PM system. Discovers all context dynamically from the database — no hardcoded team or company names. Implements the strategic triangle: **PEOPLE** (capacity) ↔ **DELIVERIES** (commitments) ↔ **DEMANDS** (incoming), with Lean and Scrum natively embedded.

| Agent | Persona | Role |
|---|---|---|
| `pm-analyst` | **Serak** | Portfolio intelligence — workload per person, delay risk, overload detection, 7 Lean wastes |
| `pm-planner` | **Zynath** | Sprint planning with capacity verification, Heijunka load leveling |
| `pm-engineer` | **Faelor** | Process template engine — creates task sets, templates, subtasks, DoR embedded |
| `pm-ops` | **Varek** | Daily operations — processes standup summaries, updates task status, detects blockers |
| `pm-reporter` | **Lyrith** | Meeting intelligence — PRIMARY entry point for all meetings (daily, planning, client, retro) |
| `pm-demand` | **Draketh** | Demand intake — structures and creates tasks, checks capacity, detects duplicates |
| `pm-data` | **Nexar** | Data layer — sole Supabase CLI access, multi-tenant, full schema knowledge |
| `pm-client` | **Eshara** | Client layer — companies, people, access permissions, risk detection |
| `pm-qa` | **Thyron** | Quality audit — formal verdicts APROVADO/PENDÊNCIAS/REPROVADO, DoD enforcement |
| `pm-coach` | **Aevon** | Scrum Master — all ceremonies, data-driven retrospectives, dysfunction detection, Kaizen |

**How the PM squad operates:**
- Drop any meeting summary (daily standup, sprint planning, client call, retrospective) to `pm-reporter` (Lyrith) and it routes to the right agents automatically
- All context (teams, projects, people, clients) is discovered dynamically from the database — no hardcoded data in the agents
- Lean natively embedded: 7-waste detection, value stream, standardized work, Jidoka quality stops
- Scrum natively embedded: velocity, burndown, WIP limits, DoR/DoD, sprint ceremonies with real data
- Works with any PM system that exposes a REST API (default integration with WorkOS/Supabase schema)

---

## Skills (slash commands)

### `/team-os` — Lead orchestrator

The main skill. Detects project state and manages the full agent team lifecycle. **Exclusive owner of `docs/smart-memory/`.**

| Command | Description |
|---|---|
| `/team-os` | Smart detection — routes to bootstrap / resume / new team |
| `/team-os *bootstrap` | Full init + discovery team (new projects) |
| `/team-os *init` | Creates empty `docs/smart-memory/` structure only |
| `/team-os *discover` | Runs discovery audit on existing project |
| `/team-os *plan "objective"` | Breaks objective into stories, populates backlog |
| `/team-os *dispatch` | Forms team and starts work on active stories |
| `/team-os *status` | Shows current tasks, stories, agents, blockers |
| `/team-os *audit` | Validates smart-memory integrity and agent compliance |
| `/team-os *resume` | Reads smart-memory and resumes in-progress work |
| `/team-os *close` | Archives smart-memory and closes the team |

### `/team-os-creator` — Agent factory + installer

Creates agents following validated patterns and installs squads into other projects. **Never touches smart-memory.**

| Command | Description |
|---|---|
| `/team-os-creator` | Menu: create team / propagate updates / install in project |
| `/team-os-creator *install` | Install squads + skills into a target project |
| `/team-os-creator *propagate` | Update agents across all projects in the Centro de Treinamento |
| `/team-os-creator *create <role>` | Create a single agent interactively |
| `/team-os-creator *squad <preset>` | Create a full preset squad (dev/sites/social/custom) |
| `/team-os-creator *audit` | Validate compliance of all installed agents |

**What `*install` always does:**
- Copies `team-os` skill (required for `/team-os` to appear in the command menu)
- Creates `settings.json` with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Filters hooks to the selected squads only

**Internal scripts** (`skills/team-os-creator/scripts/`):
- `install-to-project.sh` — copies agents/skills/hooks/settings to a target project
- `scan-ct-projects.sh` — discovers all projects in the Centro de Treinamento root
- `diff-agents.sh` — compares agent versions between source and target
- `detect-project-signals.sh` — detects stack and archetype for squad suggestions
- `validate-agent.sh` — validates agent compliance after creation

### Dev skills

`/dev-api-design` · `/dev-database-patterns` · `/dev-error-handling` · `/dev-testing-strategy` · `/dev-typescript-patterns` · `/dev-git-workflow` · `/dev-security-patterns` · `/dev-technical-writing` · `/dev-defuddle`

#### BI & Data Science skills (for `dev-bi` and `dev-data-performance`)

`/data-analytics-engineering` · `/data-sql-optimization` · `/data-lake-platform` · `/ai-ml-data-science` · `/ai-ml-timeseries`

| Skill | Used by | Purpose |
|---|---|---|
| `/data-analytics-engineering` | Kairo | Metric dictionary, semantic layer, dbt/SQLMesh, data contracts, governance |
| `/data-sql-optimization` | Kairo | Analytical query tuning, EXPLAIN/ANALYZE, anti-patterns, indexing |
| `/data-lake-platform` | Kairo | Medallion architecture, data mesh, Iceberg/Delta, ClickHouse, Dagster |
| `/ai-ml-data-science` | Sigma | EDA, feature engineering, LightGBM, model evaluation, MLOps (CI/CD/CT/CM) |
| `/ai-ml-timeseries` | Sigma | Forecasting, backtesting, lag features, seasonality, drift detection |

### Sites skills

`/sites-seo-technical` · `/sites-seo-keywords` · `/sites-frontend-design` · `/sites-ux-interaction` · `/sites-copywriting` · `/sites-page-cro` · `/sites-content-strategy` · `/sites-deployment` · `/sites-shadcn-ui` · `/sites-tailwind-design-system` · `/sites-canvas-design` · `/sites-copy-editing` · `/sites-web-accessibility` · `/sites-scroll-motion`

#### `/sites-scroll-motion` — Cinematic scroll, parallax and 3D

10-section reference for scroll-driven animation on the web, from CSS to Three.js WebGPU. Used by `sites-ux`, `sites-dev-alpha`, and `sites-dev-gamma`.

| Section | Topics |
|---|---|
| 1. IntersectionObserver + CSS | `data-visible`, transition classes, staggered reveals |
| 2. CSS Scroll Snap | `scroll-snap-type`, mandatory vs proximity, mobile behaviour |
| 3. Dual-ref scroll (no re-render) | `scrollRef` + `progressRef` via `useRef` — zero React re-renders |
| 4. Framer Motion | `useScroll`, `useTransform`, `useSpring`, `MotionValue` pipes |
| 5. Keyframe camera path | 3D camera positions, `smoothstep`/`lerp`, normalised progress |
| 6. Per-stage interpolation | Ranges, `mapRange`, multi-stop value curves |
| 7. Three.js / R3F setup | `<Canvas>`, `useFrame`, `ScrollControls`, `useScroll` (R3F) |
| 8. Three.js WebGPU + TSL | Compute shaders, DoF post-processing, sky gradient node materials |
| 9. Performance rules | 11 rules — GPU budget, `will-change`, passive listeners, RAF |
| 10. Decision guide | When to use each technique; complexity vs. impact matrix |

### Social skills

`/social-copywriting` · `/social-scriptwriting` · `/social-carousel-design` · `/social-video-editing` · `/social-analytics` · `/social-key-visual` · `/social-format-specs` · `/social-editorial-validation` · `/social-apify-research` · `/social-freepik-generation` · `/social-stitch-workflow` · `/social-meta-publishing` · `/social-cinematic-composition`

### Traffic skills

`/tiktok-marketing`

### PM skills

`/supabase` · `/supabase-postgres-best-practices` · `/to-prd` · `/to-issues` · `/grill-me` · `/triage` · `/handoff`

| Skill | Used by | Purpose |
|---|---|---|
| `/supabase` | Nexar, all PM agents | Supabase REST API patterns, RLS, Auth, Edge Functions |
| `/supabase-postgres-best-practices` | Nexar | PostgreSQL query optimization, schema design, indexing |
| `/to-prd` | Draketh, Zynath | Converts demand briefs into structured PRD / task definition |
| `/to-issues` | Draketh | Converts meeting notes and PRDs into structured task lists |
| `/grill-me` | Zynath, Aevon | Adversarial requirement review — finds edge cases before sprint starts |
| `/triage` | Serak, Draketh | Priority scoring, demand classification, backlog health |
| `/handoff` | Varek, Lyrith | Standardized handoff format between agents and sprint cycles |

### Design / Accessibility

`/ui-ux-pro-max` · `/accessibility` · `/web-design-guidelines`

---

## How it works end-to-end

```
You                   team-os (skill)            Agents (in parallel)
 │                          │                          │
 ├─ /team-os ──────────────►│                          │
 │                          ├─ detect state            │
 │                          ├─ graphify (AST scan)     │  ← builds knowledge graph
 │                          ├─ TeamCreate()             │
 │                          ├─ Agent(dev-architect) ───►│ maps modules + god nodes
 │                          ├─ Agent(dev-analyst) ─────►│ maps tech stack
 │                          │  rm -rf graphify-out/    │  ← transient, not persisted
 │◄─────────────────────────┤◄─── SendMessage ──────────┤ (agents report back)
 │                          │                          │
 ├─ /team-os *plan ─────────►│                          │
 │  "add auth module"        ├─ SendMessage ────────────►│ dev-architect creates stories
 │                          │◄─── stories created ──────┤
 │                          │                          │
 ├─ /team-os *dispatch ──────►│                          │
 │                          ├─ Agent(dev-dev-beta) ─────►│ checks god nodes (step 1.5)
 │                          │                          │  implements
 │                          ├─ Agent(dev-qa) ───────────►│ expanded checklist if god node
 │                          ├─ Agent(dev-devops) ───────►│ pushes PR + graphify update
```

---

## Configuration

`settings.json` sets the required env var (created automatically by `/team-os-creator *install`):

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

`settings.local.json` is gitignored — use it for machine-specific permissions.

---

## Contributing

Pull requests welcome. When adding a new agent, run `/team-os-creator` to generate it following the validated patterns. When adding a new skill, follow the structure in `.claude/skills/team-os/SKILL.md` as reference.

---

## License

MIT
