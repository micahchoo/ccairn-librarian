#!/usr/bin/env bash
# ccairn-librarian-bus.sh — single SessionStart dispatcher for ccairn-librarian.
# Runs all three observability checks in one bash invocation to keep the
# SessionStart latency tax flat (one bash spawn instead of three).
#
# Each check writes to stdout if it has a finding. The bus prefixes any output
# with a header so users can tell which family/plugin is talking.
#
# Quiet flag: if .claude/.ccairn-quiet exists in the project, the bus emits
# nothing — checks still run, but findings are dropped. This lets users opt
# out per-project without uninstalling the plugin.

set +e

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"

# --- Quiet-flag gate ---
# Fall back to PWD when not in a git repo so the flag works in any directory.
PROJ_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [[ -f "$PROJ_ROOT/.claude/.ccairn-quiet" ]]; then
  exit 0
fi

# --- Run checks, capture each script's output ---
out_stale=$(bash "$PLUGIN_ROOT/hooks/scripts/detect-stale-claude.sh" 2>/dev/null)
out_memory=$(bash "$PLUGIN_ROOT/scripts/check-memory-freshness.sh" 2>/dev/null)
out_claudemd=$(bash "$PLUGIN_ROOT/scripts/claude-md-nudge.sh" 2>/dev/null)

combined=""
[[ -n "$out_stale" ]]    && combined+="${out_stale}"$'\n'
[[ -n "$out_memory" ]]   && combined+="${out_memory}"$'\n'
[[ -n "$out_claudemd" ]] && combined+="${out_claudemd}"$'\n'

if [[ -n "$combined" ]]; then
  printf '%s' "$combined"
fi

exit 0
