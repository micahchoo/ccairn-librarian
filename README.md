# ccairn-librarian

> *Cairns are stone markers left by previous travelers showing the way through unfamiliar terrain. The librarian tends the trail map between trips.*

**A `.claude/` directory steward for Claude Code.** Catalog, audit, split bloated CLAUDE.md files, migrate user→project content, prune dead skills, persist reference docs, path-gate rules. The home base between trips — not the trip itself.

## Who this is for

You have a `.claude/` directory that's grown organically — skills you forget you installed, a CLAUDE.md that's drifted past 200 lines, reference docs scattered across `~/.claude/` and the project, rules that fire on every file because they don't have `paths:` frontmatter. You want a structured way to clean it up and keep it clean.

## Companion plugin

This is the sibling of **[ccairn-handoff](https://github.com/micahchoo/ccairn-handoff)** — the session-continuity plugin (`/handoff`, `/check-handoff`, `/triage`). Together they cover the full session lifecycle:

- **ccairn-handoff** — wrap up cleanly, resume cleanly, close the loop on auto-created issues. *Markers for the next traveler.*
- **ccairn-librarian** — between sessions, keep the home base organized. *The trail map.*

Install both for the complete cycle.

## Quick start

After install:

1. **Type `/librarian`** in any project with a `.claude/` directory. The skill walks you through an audit and recommends which duty to run first based on what it finds.
2. **Or invoke a specific duty:** *"Audit .claude/"* / *"Split CLAUDE.md"* / *"Persist this decision as a reference doc"*.

## Install

```bash
ln -s /path/to/ccairn-librarian ~/.claude/plugins/installed/ccairn-librarian
```

Or add via your Claude Code marketplace flow once published.

## What you get

### User surface

| Command | Use when |
|---|---|
| `/librarian` | You want to audit `.claude/`, run a specific duty, or address a SessionStart finding. |

The bundled SessionStart hooks will surface stale-`.claude/` conditions, missing CLAUDE.md, stale memory files, etc. — when they fire with findings, the natural next step is `/librarian`.

### Under the hood

| Component | What it does |
|---|---|
| `skills/librarian/SKILL.md` | The librarian skill — 8 duties (catalog, audit, split, migrate, prune, persist, path-gate, cross-reference). Operates in **manual** or **signal-driven** mode depending on whether SessionStart hooks have populated caches. |
| `commands/librarian.md` | `/librarian` slash command. |
| `hooks/hooks.json` + `hooks/scripts/detect-stale-claude.sh` | SessionStart hook — detects stale INDEX.md, bloated CLAUDE.md, untouched `.claude/`, gitignore gaps. Quiet on success. |
| `scripts/check-memory-freshness.sh` | SessionStart hook — flags Claude Code memory files past their `ttl-days`. |
| `scripts/claude-md-nudge.sh` | SessionStart hook — flags missing or stale project CLAUDE.md. |
| `scripts/metastructure-audit.sh` | On-demand audit — depth budgets, MANIFEST/EXPIRATION/GENERATOR markers, cross-world reference provenance. Run via `bash ${CLAUDE_PLUGIN_ROOT}/scripts/metastructure-audit.sh [ROOT]`. |
| `scripts/lib/hook-stdin.sh` | Shared utility — captures `session_id` from SessionStart JSON for hooks that need it. |

## The 8 duties (summary)

| Duty | What | When to run |
|---|---|---|
| 1. Catalog & Index | Rebuild `.claude/INDEX.md` from filesystem | Periodically, especially after adding/removing skills |
| 2. Audit & Diagnose | CLAUDE.md size, gitignore coverage, path-gating gaps | When you sense `.claude/` has drifted |
| 3. Split CLAUDE.md | Decompose bloated CLAUDE.md (>80 lines) into `rules/` | When CLAUDE.md is unwieldy |
| 4. Migrate Personal → Project | Move project knowledge from `~/.claude/` → `.claude/` | When project-specific content is hiding at user level |
| 5. Prune & Archive | Move unused skills/rules to `.claude/archive/` with datestamp | Quarterly or when adding new content |
| 6. Persist Reference Docs | Write timestamped `ref-YYYY-MM-DD-<slug>.md` snapshots | When a session surfaces something worth keeping |
| 7. Path-Gate Rules | Add `paths:` frontmatter to directory-specific rules | When a rule fires in irrelevant contexts |
| 8. Cross-Reference | `@`-include from `docs/` instead of duplicating content | When you're about to write something that already exists |

Full procedures and decision tables in `skills/librarian/SKILL.md`.

## Success criteria

A working install of this plugin should produce these outcomes over time:

- **Single source of truth:** every fact in your `.claude/` lives in exactly one place — the rest are `@`-includes.
- **Bounded CLAUDE.md:** root CLAUDE.md stays under 80 lines (under 40 after a Duty 3 split).
- **Live INDEX.md:** `.claude/INDEX.md` matches what's actually on disk; no orphans, no dangling references.
- **Bounded user-level:** `~/.claude/` contains only personal-tone, cross-project shortcuts, personal MCP servers — nothing project-specific.
- **Path-gated rules:** every rule file mentioning a specific directory has `paths:` frontmatter.

If your `.claude/` doesn't move toward these over time, the plugin needs tuning, not patience.

## Operating modes

**Manual mode** — invoke `/librarian` explicitly; the skill walks duties on demand. Works in any project, no setup beyond install.

**Signal-driven mode** — SessionStart hooks (bundled) surface findings before any user prompt. The skill reads the cached signals and routes directly to the relevant duty, citing the cache and finding line. No setup; activates whenever the hooks have something to report.

The skill's [Cached Signals section](skills/librarian/SKILL.md) maps each bundled producer to the duty it should route to.

## Roadmap

Bundled in v1.x:
- ✅ **SessionStart "stale `.claude/`" hook** — INDEX.md staleness, CLAUDE.md bloat, `.claude/` activity drift, gitignore gaps.
- ✅ **Memory freshness hook** — flags Claude Code memory files past TTL.
- ✅ **CLAUDE.md nudge hook** — flags missing or stale project CLAUDE.md.
- ✅ **Metastructure audit script** — on-demand depth/MANIFEST/EXPIRATION audits.

Deferred (need refactoring or external pipelines this plugin doesn't ship):
- **`observability-scan.sh`** — orphan/drift detection. Overfits to one user's `~/.claude/` conventions; would need a portable rewrite to be useful in arbitrary projects.
- **`measure-leverage.sh`** — router recall scorecard. Currently uses hardcoded test prompts for a specific skill set; would need a per-project test-prompt registry to generalize.
- **`expertise-vs-antipatterns.sh`** — flags mulch domains where anti-pattern density exceeds pattern density. Needs an anti-pattern report pipeline that isn't bundled here.
- **Skill-recommendation triage** — would consume `.claude/SUGGESTED_SKILLS.md` produced by upstream automation; that aggregator script isn't bundled.

If you have these scripts available locally and want their signals, point the librarian at their stdout manually before deciding which duty to enter — see the skill's "Deferred scripts" note.

## License

MIT
