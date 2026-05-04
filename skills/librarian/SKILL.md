---
name: librarian
description: >-
  Steward the project .claude/ directory — catalog, audit, split CLAUDE.md, migrate
  user→project, prune, archive, persist reference docs, path-gate rules.
  Triggers on: "librarian", "/librarian", "organize claude", "audit .claude",
  "split CLAUDE.md", "catalog", "archive context", "persist this", "save reference",
  "index the docs", "clean up .claude".

  Do NOT use for: ~/.claude/ personal config management, git operations, or
  project code organization outside .claude/.
metadata:
  version: "1.0.0"
  domain: workflow
  triggers: librarian, organize .claude, audit .claude, split CLAUDE.md, catalog, persist reference, path-gate rules
  role: specialist
  scope: analysis
  output-format: analysis
  related-skills: handoff, check-handoff, triage
---

# Librarian

Steward this project's `.claude/` directory. Mandate: maximize what lives in **project `.claude/`** (committed, team-shared); minimize what leaks into **`~/.claude/`** (personal only).

**Decision test:** *"Would a new teammate benefit?"* → project `.claude/`. Otherwise → personal.

Two operating modes: **manual** (you invoke the skill, it walks duties on demand) and **signal-driven** (SessionStart hooks surface findings; you act on cited evidence). The signal-driven mode activates when the bundled observability scripts run at SessionStart — no setup needed beyond installing the plugin.

---

## Cached Signals (check before acting)

When operating in signal-driven mode, the bundled SessionStart hooks emit findings before any user prompt. Read these before deciding what duty to enter — don't re-derive from scratch. Cite the cache and finding line in any recommendation you make to the user.

| Cache / producer | Finding shape | Maps to duty |
|---|---|---|
| `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/detect-stale-claude.sh` (SessionStart) | INDEX.md missing or >30d stale · CLAUDE.md >80 lines · `.claude/` untouched while project active · `.gitignore` doesn't exclude `settings.local.json` | Duty 1, 3, 2, 2 (respectively) |
| `${CLAUDE_PLUGIN_ROOT}/scripts/check-memory-freshness.sh` (SessionStart) | memory files past their `ttl-days` (default 30d) without verification | Duty 5 (prune/freshen) |
| `${CLAUDE_PLUGIN_ROOT}/scripts/claude-md-nudge.sh` (SessionStart) | project CLAUDE.md absent, or stale (>30d) | Duty 3 (split — bootstrap from nudge if missing) |
| `${CLAUDE_PLUGIN_ROOT}/scripts/metastructure-audit.sh` (on-demand: `bash <path> [ROOT]`) | top-level dirs missing MANIFEST · depth >6 · `drafts/`/`spikes/` without EXPIRATION · `generated/` without GENERATOR · `shared/` without manifest · cross-world refs missing provenance | Duty 3 (split), Duty 8 (cross-ref) |

Gate: only act on a signal if its cache exists for this session (absence ≠ clean — producer may have failed or skipped). When a hook fires with findings, your first action should be to address them before unrelated work.

**Deferred scripts (not bundled in v1.x):** `observability-scan.sh` (orphan/drift detection — overfits user-specific conventions), `measure-leverage.sh` (router recall — hardcoded test prompts), `expertise-vs-antipatterns.sh` (mulch density vs anti-pattern density — needs anti-pattern report pipeline). If you have these locally and want their signals, point this skill at their stdout manually before deciding which duty to enter.

---

## Duties

### 1. Catalog & Index

Maintain `.claude/INDEX.md` — manifest of every file in `.claude/`, its purpose, and last-updated date.

```bash
find .claude/ -type f | sort
```

Reconcile against INDEX.md. Flag:
- **Orphaned** — file exists, not referenced anywhere
- **Stale** — not updated in 30+ days (`git log --since=30.days .claude/`)
- **Duplicate** — same content in two places

### 2. Audit & Diagnose

- **CLAUDE.md size:** if >80 lines, recommend split into `rules/` (see Duty 3).
- **Personal-content leak:** check `~/.claude/` for project-specific content hiding at user level — offer migration (see Duty 4).
- **Gitignore coverage:** verify `.claude/.gitignore` covers `settings.local.json` and optionally `agent-memory/`.
- **Path-gate gaps:** rules missing `paths:` frontmatter that mention specific directories → recommend path-gating (see Duty 7).
- **Duplication:** repeated content across skills/rules → extract to `docs/`.

### 3. Split CLAUDE.md

When CLAUDE.md is bloated, decompose by content type:

| Content type | Destination |
|---|---|
| Code style / naming | `rules/code-style.md` |
| Architecture / layers | `rules/architecture.md` |
| Test conventions | `rules/testing.md` |
| Path-specific guidance | `rules/<topic>.md` with `paths:` frontmatter |
| Build / test / lint commands | Keep in root CLAUDE.md (target <40 lines after split) |

Goal: root CLAUDE.md reads as identity + stack + commands only. Everything else is `@`-included or auto-loaded by path.

### 4. Migrate Personal → Project

Move project knowledge from `~/.claude/` → `.claude/`:

1. Copy to project equivalent.
2. Verify the project version is reachable (via `/memory` or `/skills`, or by reading the file).
3. Delete the original from `~/.claude/` only with explicit user approval.

Common targets: project-specific skills hiding under user-level skills/, project memory files in user-level memory/.

### 5. Prune & Archive

- **Identify unused:** rules/skills not invoked in project history. Use `git log --oneline -- .claude/<path>` per file as a starting signal.
- **Archive before delete:** move to `.claude/archive/` with datestamp prefix (`2026-04-09_old-rule.md`). Never `rm` directly.
- **Doc pruning:** entries in `docs/` not referenced by any skill → archive candidates.

### 6. Persist Reference Docs

When the conversation surfaces something worth keeping beyond this session — a decision, an API gotcha, an architecture conclusion, a research finding — write a timestamped snapshot:

```
.claude/docs/ref-YYYY-MM-DD-<slug>.md
```

Format:
```markdown
---
created: 2026-04-09
source: conversation / web search / file analysis
tags: [api-design, migration]
---
# <Descriptive Title>

<Compressed, actionable content. No filler. Bullet points fine.>
```

Rules:
- **Max 60 lines per doc.** Split by topic if longer.
- **Compress aggressively** — strip examples unless they're the point, remove hedging.
- **Add to INDEX.md immediately** after writing.
- **Tags must be grep-able:** skills use `@.claude/docs/ref-YYYY-MM-DD-slug.md` to reference.

**Proactive triggers** (don't wait to be asked):
- User states a design decision or constraint verbally → persist.
- Research yields critical API behavior or non-obvious gotcha → persist.
- Debugging session reveals root cause that isn't obvious from the code → persist.
- Architecture discussion produces conclusions → persist.

### 7. Path-Gate Rules

Any rule mentioning specific directories needs `paths` frontmatter:

```yaml
---
paths: src/frontend/**
---
```

Prevents wasting context tokens when Claude works elsewhere in the codebase. Audit existing `rules/` for this gap.

### 8. Cross-Reference

- Check existing `docs/` before embedding content in a new rule/skill — `@`-include instead of duplicating.
- One source of truth per topic. If you're about to write something that already exists, edit the existing one instead.

---

## Target Structure

```
project/
├── CLAUDE.md                    # <40 lines: identity, stack, commands only
├── .mcp.json                    # Team MCP servers
├── .claude/
│   ├── INDEX.md                 # Manifest of everything below (Duty 1)
│   ├── settings.json            # Permissions, hooks, env vars
│   ├── settings.local.json      # Personal overrides (gitignored)
│   ├── .gitignore
│   ├── rules/                   # Auto-loaded; path-gated where applicable (Duty 7)
│   ├── commands/                # /project:name slash commands
│   ├── skills/                  # Multi-file workflows
│   ├── agents/                  # Subagent definitions
│   ├── docs/                    # On-demand reference (not auto-loaded)
│   │   └── ref-YYYY-MM-DD-*.md  # Timestamped context snapshots (Duty 6)
│   ├── output-styles/           # Custom formatting
│   └── archive/                 # Datestamped retired files (Duty 5)
```

## What Stays in ~/.claude/

Only: personal tone preferences, cross-project shortcuts, personal MCP servers, personal permission overrides. **Nothing project-specific.**

If you find project-specific content in `~/.claude/`, route it through Duty 4 (Migrate Personal → Project).

---

## Diffusion Triggers

When other workflows complete, route here to capture what they learned:

| Upstream skill | When to route here |
|---|---|
| `hybrid-research` (or any research skill) | After synthesis — persist key findings as reference docs (Duty 6) |
| `brainstorming` | After design doc written — catalog it in INDEX.md (Duty 1) |
| `handoff` (from ccairn-handoff plugin) | Before writing HANDOFF.md — persist context that outlasts the session (Duty 6) |
| `executing-plans` | After plan completion — archive the plan, update INDEX.md (Duty 5 + Duty 1) |
| `codebase-diagnostics` | After analysis — persist architecture findings as ref docs (Duty 6) |

---

## Roadmap (advanced cached-signal integrations)

The full version of this skill in standalone configs reads from a SessionStart cache pipeline producing signals that auto-route to specific duties:

- `readme-seam-check.sh` (already bundled in **ccairn-handoff**) → §6 persist, §1 catalog, §5 prune
- `observability-scan.sh` → §1 orphan detection, §5 prune (write-only outputs, doc↔code drift)
- `metastructure-audit.sh` → §3 split, §8 cross-ref (depth/MANIFEST/EXPIRATION violations)
- `measure-leverage.sh` → §1 catalog, §4 migrate (deprecated refs, memory TTL)
- `check-memory-freshness.sh` → §5 prune/freshen (memory files >30d without verification)
- `expertise-vs-antipatterns.sh` → §6 persist (mulch domains where anti-pattern density > pattern density)

These scripts are not bundled in v1 of `ccairn-librarian`. Without them, the librarian operates in **manual mode** — you invoke it explicitly, it walks duties on demand. With them, it would operate in **signal-driven mode** — SessionStart caches surface what needs attention and the librarian acts on cited evidence.

If you have these scripts available locally and want the auto-signal flow, point this skill at them by reading their stdout before deciding which duty to enter. v1.x candidate: bundle a default observability suite.

`[eval: cataloged]` After Duty 1 runs, `.claude/INDEX.md` reflects current filesystem state — no orphans uncataloged, no entries pointing at deleted files.
`[eval: split-target-met]` After Duty 3 runs, root CLAUDE.md is <80 lines and content was distributed by type, not chunked arbitrarily.
`[eval: ref-docs-grepable]` Reference docs persisted via Duty 6 use the `ref-YYYY-MM-DD-<slug>.md` naming convention and have `tags:` frontmatter that grep can find.
