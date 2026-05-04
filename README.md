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

| Component | What it does |
|---|---|
| `skills/librarian/` | The librarian skill — 8 duties (catalog, audit, split, migrate, prune, persist, path-gate, cross-reference). |
| `commands/librarian.md` | `/librarian` slash command. |

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

## Roadmap

The full version of this skill in standalone configs feeds off a SessionStart cache pipeline of observability scripts (orphan detection, metastructure audit, leverage drift, memory freshness, expertise vs anti-patterns, claude-md nudge). v1 of this plugin ships **manual mode** only — you invoke `/librarian` and it walks duties on demand.

v1.x candidates:
- **Bundle the observability suite** — ship the cached-signal scripts so librarian operates in signal-driven mode (auto-routes to specific duties based on cache content).
- **SessionStart hook** — detect "stale `.claude/`" condition (e.g., INDEX.md older than 30d, CLAUDE.md grew past threshold) and surface a one-liner.
- **Skill-recommendation triage** — process `.claude/SUGGESTED_SKILLS.md` produced by upstream automation.

These are deliberately deferred to keep v1 focused and shippable today.

## License

MIT
