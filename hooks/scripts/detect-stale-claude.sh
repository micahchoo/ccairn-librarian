#!/usr/bin/env bash
# detect-stale-claude.sh — SessionStart hook for ccairn-librarian
# Detects stale or unhealthy .claude/ conditions and surfaces librarian duties.
# Quiet on success (no findings = no output). Non-blocking. Skips projects
# without a .claude/ directory.
set +e

PROJ_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CLAUDE_DIR="$PROJ_ROOT/.claude"
[[ -d "$CLAUDE_DIR" ]] || exit 0

# Cross-platform stat helper
_mtime() {
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f %m "$1" 2>/dev/null
  else
    stat -c %Y "$1" 2>/dev/null
  fi
}

now=$(date +%s)
findings=()

# --- Check 1: INDEX.md missing or stale (>30d) ---
INDEX="$CLAUDE_DIR/INDEX.md"
if [[ ! -f "$INDEX" ]]; then
  count=$(find "$CLAUDE_DIR" -type f -not -path "*/archive/*" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${count:-0}" -gt 5 ]]; then
    findings+=("INDEX.md missing — ${count} files in .claude/. Duty 1: catalog & index.")
  fi
else
  index_mtime=$(_mtime "$INDEX")
  if [[ -n "$index_mtime" ]]; then
    age=$(( (now - index_mtime) / 86400 ))
    [[ "$age" -gt 30 ]] && findings+=("INDEX.md is ${age}d stale. Duty 1: rebuild from filesystem.")
  fi
fi

# --- Check 2: CLAUDE.md bloat (>80 lines triggers Duty 3) ---
for cmd_path in "$PROJ_ROOT/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"; do
  if [[ -f "$cmd_path" ]]; then
    lines=$(wc -l < "$cmd_path" | tr -d ' ')
    if [[ "${lines:-0}" -gt 80 ]]; then
      rel=$(realpath --relative-to="$PROJ_ROOT" "$cmd_path" 2>/dev/null || echo "$cmd_path")
      findings+=("${rel} is ${lines} lines (>80). Duty 3: split into rules/.")
    fi
    break
  fi
done

# --- Check 3: .claude/ untouched while project is active ---
if git -C "$PROJ_ROOT" rev-parse HEAD >/dev/null 2>&1; then
  last_claude=$(git -C "$PROJ_ROOT" log -1 --format=%ct -- ".claude/" 2>/dev/null || echo 0)
  last_repo=$(git -C "$PROJ_ROOT" log -1 --format=%ct 2>/dev/null || echo 0)
  if [[ "$last_claude" -gt 0 && "$last_repo" -gt 0 ]]; then
    age_diff=$(( (last_repo - last_claude) / 86400 ))
    [[ "$age_diff" -gt 60 ]] && findings+=(".claude/ untouched for ${age_diff}d while project active. Duty 2: audit & diagnose.")
  fi
fi

# --- Check 4: Common gitignore gaps ---
GI="$CLAUDE_DIR/.gitignore"
if [[ -f "$GI" ]]; then
  if ! grep -q "settings.local.json" "$GI" 2>/dev/null; then
    findings+=(".claude/.gitignore does not exclude settings.local.json. Duty 2: gitignore audit.")
  fi
fi

# --- Emit findings ---
if [[ ${#findings[@]} -gt 0 ]]; then
  echo "[ccairn-librarian] .claude/ stewardship signals (${#findings[@]}):"
  for f in "${findings[@]}"; do
    echo "  - $f"
  done
  echo "[ccairn-librarian] Run /librarian to address."
fi

exit 0
