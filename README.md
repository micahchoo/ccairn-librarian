# ccairn-librarian

> Part of the **ccairn** family of Claude Code plugins for session lifecycle.
> Companions: [ccairn-handoff](https://github.com/micahchoo/ccairn-handoff) (session boundaries) · ccairn-librarian (this — `.claude/` stewardship).
> Family overview: [github.com/micahchoo/ccairn](https://github.com/micahchoo/ccairn).

> *Cairns are stone markers left by previous travelers showing the way through unfamiliar terrain. The librarian tends the trail map between trips.*

**A `.claude/` directory steward for Claude Code.** Catalog, audit, split bloated CLAUDE.md files, migrate user→project content, prune dead skills, persist reference docs, path-gate rules.

**State-driven, not event-driven.** Where ccairn-handoff fires when there is a specific *artifact* to act on (a HANDOFF.md), ccairn-librarian fires when the directory has *drifted* — INDEX.md gone stale, CLAUDE.md bloated, memory files past TTL. Conditions, not triggers.

## Who this is for

You have a `.claude/` directory that's grown organically — skills you forget you installed, a CLAUDE.md that's drifted past 200 lines, reference docs scattered across `~/.claude/` and the project, rules that fire on every file because they don't have `paths:` frontmatter. You want a structured way to clean it up and keep it clean.

## Install order & what changes when both plugins are present

Either order works — neither plugin depends on the other. Common sequencing:

1. **Install ccairn-handoff first** if your immediate pain is *running out of context mid-session*. You'll get `/handoff`, `/check-handoff`, `/triage`, and a SessionStart hook that detects HANDOFF.md.
2. **Install ccairn-librarian second** when you notice `.claude/` rot — bloated CLAUDE.md, mystery skills, stale reference docs.

When both are installed:

| Surface | Owns | Doesn't overlap because |
|---|---|---|
| `HANDOFF.md` lifecycle | ccairn-handoff | librarian doesn't touch session artifacts. |
| `.claude/INDEX.md`, `rules/`, `docs/`, `archive/` | ccairn-librarian | handoff doesn't reorganize the directory. |
| SessionStart "you have a HANDOFF.md, run /check-handoff" | ccairn-handoff (`detect-handoff.sh`) | Single artifact, single nudge. |
| SessionStart "your .claude/ has drifted" | ccairn-librarian (`ccairn-librarian-bus.sh`) | Composite directory state, single dispatcher (one bash spawn). |
| Architectural snapshot of `.claude/` (hooks/skills/plugins) | ccairn-handoff (`config-lens-structural.sh`) — used to populate HANDOFF.md's Infrastructure Delta section. | librarian's `metastructure-audit.sh` is *meta*structure (depth budgets, MANIFEST/EXPIRATION markers) — orthogonal lens on the same substrate. |
| Quieting nudges per project | Both honor `.claude/.ccairn-quiet` | Shared family flag silences both plugins' SessionStart output. |

Family overview repo: **[github.com/micahchoo/ccairn](https://github.com/micahchoo/ccairn)** — manifest of plugins, design philosophy, and the family axes (boundary / steward / future learning loop).

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
| `hooks/hooks.json` + `hooks/scripts/ccairn-librarian-bus.sh` | **Single SessionStart dispatcher** — runs all three observability checks in one bash spawn (keeps SessionStart latency flat instead of 3× the cost). Honors `.claude/.ccairn-quiet` to silence per project. |
| `hooks/scripts/detect-stale-claude.sh` | Detection script — INDEX.md staleness, bloated CLAUDE.md, untouched `.claude/`, gitignore gaps. Invoked by the bus; also runnable standalone. |
| `scripts/check-memory-freshness.sh` | Detection script — Claude Code memory files past their `ttl-days`. Invoked by the bus; also runnable standalone. |
| `scripts/claude-md-nudge.sh` | Detection script — missing or stale project CLAUDE.md. Invoked by the bus; also runnable standalone. |
| `scripts/metastructure-audit.sh` | On-demand audit (not in the bus) — depth budgets, MANIFEST/EXPIRATION/GENERATOR markers, cross-world reference provenance. Run via `bash ${CLAUDE_PLUGIN_ROOT}/scripts/metastructure-audit.sh [ROOT]`. |
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

## Extension points (BYO signal sources)

The librarian skill operates on cached signals — read from stdout, route to a duty, cite the cache and finding line. Bundled producers cover the common cases. Three additional signal sources are deliberately **out-of-band** because they require project-specific test corpora or external pipelines this plugin does not ship; they are documented as extension points, not missing features:

| Signal source | What it produces | Why out-of-band | How to wire your own |
|---|---|---|---|
| **Orphan / doc↔code drift** | `[HIGH] orphan: <file> — write-only output` lines | Detection rules over-fit to one `~/.claude/` convention set; portability requires a rewrite. | Write a script that emits findings on stdout in `[SEVERITY] <class>: <message>` format; run it before invoking `/librarian`; the skill consumes it identically to bundled producers. |
| **Router recall scorecard** | `M1 PASS: 18/24 (75%)` style metric lines | Current implementation has hardcoded test prompts for a specific skill set; needs a per-project test-prompt registry. | Maintain `.claude/.test-prompts.json`, wrap a recall test against your `/skills/`, emit `M1 PASS|FAIL` lines. |
| **Expertise vs anti-pattern density** | `expertise-gap: <domain>` per-domain ratios | Needs a `mulch` install and an anti-pattern report pipeline (e.g. `anti-pattern-report.txt`) the plugin doesn't bundle. | If you run the [mulch](https://github.com/jayminwest/mulch) CLI plus an anti-pattern scanner, pipe the comparison into stdout and route to Duty 6 (persist). |

The contract is intentionally minimal: emit findings on stdout, one per line, prefixed by something the user can read. The librarian skill treats any such producer the same as bundled ones — read, route to a duty, act.

## Roadmap

- **Skill-recommendation triage** — consume `.claude/SUGGESTED_SKILLS.md` produced by an upstream aggregator (out-of-scope for v1; the aggregator script isn't bundled).
- **First-run config wizard** — instead of always-on nudges, prompt once per project: "watch this `.claude/` for drift? (y/n)". Would replace the current opt-out via `.ccairn-quiet` with explicit opt-in. Requires SessionStart hooks that can prompt interactively, which the plugin runtime currently doesn't expose.
- **Pluggable signal-source registry** — formalize the BYO contract above into a config file (`.claude/.ccairn-librarian-signals.json`) listing extra producers to invoke from the bus.

## License

MIT
