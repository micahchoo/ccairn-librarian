#!/usr/bin/env bash
# hook-stdin.sh — read SessionStart-style hook JSON from stdin and expose session_id.
#
# All Claude Code hook events (including SessionStart) deliver JSON via stdin
# with a `session_id` field. Sourcing this lib captures it once and exports:
#   HOOK_INPUT       — raw JSON string (empty if stdin was a TTY or non-JSON)
#   HOOK_SESSION_ID  — extracted .session_id (empty if absent)
#
# Safe to source from scripts that may also be invoked manually (TTY stdin):
# the read is gated on `[[ ! -t 0 ]]`, and JSON parsing is best-effort.
#
# For scripts that already consume stdin for another purpose (e.g. a piped file
# list), do NOT source this lib — peek the first byte instead and route.

HOOK_INPUT=""
HOOK_SESSION_ID=""

if [[ ! -t 0 ]]; then
  HOOK_INPUT=$(cat 2>/dev/null || true)
  if [[ -n "$HOOK_INPUT" ]] && command -v jq >/dev/null 2>&1; then
    HOOK_SESSION_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  fi
fi

export HOOK_INPUT HOOK_SESSION_ID
