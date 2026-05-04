#!/usr/bin/env bash
# metastructure-audit.sh — standalone audit for multi-metastructure discipline
#
# Usage:   bash metastructure-audit.sh [ROOT]
# Default: ROOT = current working directory
#
# Checks (from CLAUDE.md → Multi-Metastructure Organization):
#   1. Top-level directory = catalog of worlds. Each top-level dir should
#      have a MANIFEST.md, README.md, or AGENT.md declaring its shape.
#   2. Depth budget: flag any directory deeper than 6 levels from its world root.
#   3. In-flux wings: drafts/, spikes/, *-next/ must declare an expiration
#      (EXPIRATION marker in the wing's README/manifest).
#   4. Derived material: generated/, build/, dist/, rendered/, exports/
#      should carry a GENERATOR marker documenting source + regeneration.
#   5. Shared-as-world: shared/, common/, reference/, utils/ must have their
#      own manifest — not be bare junk drawers.
#   6. Cross-world references: grep for "draws on", "see also", "based on"
#      without a version/reason provenance line nearby.
#
# Output: markdown report to stdout. Exit 0 always (audit is advisory).

set -euo pipefail

ROOT="${1:-$PWD}"
ROOT=$(realpath "$ROOT" 2>/dev/null || echo "$ROOT")

if [[ ! -d "$ROOT" ]]; then
  echo "error: $ROOT is not a directory" >&2
  exit 1
fi

cd "$ROOT"

# ─── helpers ──────────────────────────────────────────────────────────
has_manifest() {
  local dir="$1"
  for f in MANIFEST.md README.md AGENT.md CLAUDE.md manifest.yaml manifest.yml; do
    [[ -f "$dir/$f" ]] && return 0
  done
  return 1
}

has_marker() {
  local dir="$1" marker="$2"
  grep -rliE "$marker" "$dir" --include='*.md' --include='*.yaml' --include='*.yml' 2>/dev/null \
    | head -1 | grep -q .
}

# ─── collect findings ─────────────────────────────────────────────────
F_WORLDS=()
F_DEPTH=()
F_INFLUX=()
F_DERIVED=()
F_SHARED=()
F_XREF=()

# 1. Top-level worlds without manifests (skip dotdirs).
while IFS= read -r -d '' d; do
  name=$(basename "$d")
  [[ "$name" == .* ]] && continue
  [[ "$name" == node_modules || "$name" == .git ]] && continue
  has_manifest "$d" || F_WORLDS+=("$name")
done < <(find . -maxdepth 1 -mindepth 1 -type d -print0)

# 2. Depth budget. Measure depth from each top-level world root.
while IFS= read -r -d '' world; do
  wname=$(basename "$world")
  [[ "$wname" == .* || "$wname" == node_modules || "$wname" == .git ]] && continue
  while IFS= read -r deep; do
    rel=${deep#./}
    F_DEPTH+=("$rel")
  done < <(
    find "$world" -type d 2>/dev/null | awk -F/ -v base="$world" '
      {
        # depth = path components beyond world root
        n = split($0, parts, "/")
        m = split(base, baseparts, "/")
        if (n - m > 6) print $0
      }'
  )
done < <(find . -maxdepth 1 -mindepth 1 -type d -print0)

# 3. In-flux wings.
while IFS= read -r -d '' d; do
  rel=${d#./}
  if ! has_marker "$d" '\bEXPIRATION\b|\bexpires?\b.*[0-9]{4}-[0-9]{2}-[0-9]{2}|\bgraduates?\b'; then
    F_INFLUX+=("$rel")
  fi
done < <(find . -type d \( -name 'drafts' -o -name 'spikes' -o -name '*-next' -o -name 'wip' -o -name 'scratch' \) -print0 2>/dev/null)

# 4. Derived material.
while IFS= read -r -d '' d; do
  rel=${d#./}
  case "$rel" in
    *node_modules*|*.git*) continue ;;
  esac
  if ! has_marker "$d" '\bGENERATOR\b|\bDERIVED\b|regeneration|auto-generated|auto-learned'; then
    F_DERIVED+=("$rel")
  fi
done < <(find . -type d \( -name 'generated' -o -name 'build' -o -name 'dist' -o -name 'rendered' -o -name 'exports' -o -name '.cache' \) -print0 2>/dev/null)

# 5. Shared-as-world.
while IFS= read -r -d '' d; do
  rel=${d#./}
  has_manifest "$d" || F_SHARED+=("$rel")
done < <(find . -maxdepth 2 -type d \( -name 'shared' -o -name 'common' -o -name 'reference' -o -name 'utils' -o -name 'misc' \) -print0 2>/dev/null)

# 6. Cross-world references without provenance.
# Grep for referential phrases; flag lines where no version/reason is within 2 lines.
while IFS= read -r hit; do
  # hit format: file:line
  file=${hit%%:*}
  line=${hit##*:}
  # Look 2 lines ahead/behind for provenance markers.
  context=$(awk -v L="$line" 'NR>=L-2 && NR<=L+2' "$file" 2>/dev/null)
  if ! echo "$context" | grep -qiE 'version|v[0-9]|commit|sha|@|because|reason|why:'; then
    F_XREF+=("$file:$line")
  fi
done < <(grep -rnE '\b(draws on|based on|see also|depends on)\b' . \
          --include='*.md' --include='*.yaml' --include='*.yml' \
          --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null \
          | head -50 | awk -F: '{print $1":"$2}')

# ─── render report ────────────────────────────────────────────────────
total=$(( ${#F_WORLDS[@]} + ${#F_DEPTH[@]} + ${#F_INFLUX[@]} + ${#F_DERIVED[@]} + ${#F_SHARED[@]} + ${#F_XREF[@]} ))

cat <<HEADER
# Metastructure Audit — \`$ROOT\`

Checks from CLAUDE.md → Multi-Metastructure Organization.
**$total findings.**

HEADER

print_section() {
  local title="$1"; shift
  local -n arr=$1
  [[ ${#arr[@]} -eq 0 ]] && return
  echo "## $title (${#arr[@]})"
  echo
  for item in "${arr[@]}"; do
    echo "- \`$item\`"
  done
  echo
}

if [[ ${#F_WORLDS[@]} -gt 0 ]]; then
  echo "## Top-level worlds missing manifest (${#F_WORLDS[@]})"
  echo
  echo "Each top-level dir should be a lift-able world with a declared shape (MANIFEST.md / README.md / AGENT.md / CLAUDE.md)."
  echo
  for item in "${F_WORLDS[@]}"; do echo "- \`$item/\`"; done
  echo
fi

if [[ ${#F_DEPTH[@]} -gt 0 ]]; then
  echo "## Depth budget exceeded (${#F_DEPTH[@]})"
  echo
  echo "More than 6 layers inside one world → split or flatten."
  echo
  for item in "${F_DEPTH[@]}"; do echo "- \`$item\`"; done
  echo
fi

if [[ ${#F_INFLUX[@]} -gt 0 ]]; then
  echo "## In-flux wings without expiration (${#F_INFLUX[@]})"
  echo
  echo "Drafts / spikes / *-next wings must declare when they graduate, merge, or get deleted."
  echo
  for item in "${F_INFLUX[@]}"; do echo "- \`$item/\`"; done
  echo
fi

if [[ ${#F_DERIVED[@]} -gt 0 ]]; then
  echo "## Derived material without generator marker (${#F_DERIVED[@]})"
  echo
  echo "Source → transformation → output should be documented in one place. Regeneration = single repeatable action."
  echo
  for item in "${F_DERIVED[@]}"; do echo "- \`$item/\`"; done
  echo
fi

if [[ ${#F_SHARED[@]} -gt 0 ]]; then
  echo "## Shared-as-junk-drawer (${#F_SHARED[@]})"
  echo
  echo "'Shared' / 'common' / 'reference' / 'utils' are legitimate only with their own manifest and published interface."
  echo
  for item in "${F_SHARED[@]}"; do echo "- \`$item/\`"; done
  echo
fi

if [[ ${#F_XREF[@]} -gt 0 ]]; then
  echo "## Cross-world refs without provenance (${#F_XREF[@]})"
  echo
  echo "Mark crossings loudly: \"draws on X, version Y, reason Z.\""
  echo
  for item in "${F_XREF[@]}"; do echo "- \`$item\`"; done
  echo
fi

[[ $total -eq 0 ]] && echo "Clean. Archive is publish-or-audit ready."
