#!/usr/bin/env bash
# Install PostPal skills for Claude Code, Codex, and Cursor.
#
# Usage:
#   ./install.sh                       # user-level install for Claude Code + Codex
#   ./install.sh --project <dir>       # also install into a project (.claude, .codex, .cursor)
#   ./install.sh --skill postpal-reddit  # install one skill only (default: all)
#
# One-liner (no clone needed):
#   curl -fsSL https://raw.githubusercontent.com/zadahmed/postpal-skills/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/zadahmed/postpal-skills/main"
ALL_SKILLS=(postpal-reddit postpal-content)

PROJECT_DIR=""
ONLY_SKILL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --skill) ONLY_SKILL="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

SKILLS=("${ALL_SKILLS[@]}")
if [[ -n "$ONLY_SKILL" ]]; then
  SKILLS=("$ONLY_SKILL")
fi

# Source: local checkout if run from the repo, otherwise fetch from GitHub
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

fetch_skill() {
  local skill="$1" dest="$2"
  mkdir -p "$dest"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/skills/$skill/SKILL.md" ]]; then
    cp "$SCRIPT_DIR/skills/$skill/SKILL.md" "$dest/SKILL.md"
  else
    curl -fsSL "$REPO_RAW/skills/$skill/SKILL.md" -o "$dest/SKILL.md"
  fi
  echo "installed: $dest"
}

cursor_rule() {
  local skill="$1" src="$2" dest_dir="$3"
  mkdir -p "$dest_dir"
  local desc
  desc=$(awk -F': ' '/^description:/ {print $2; exit}' "$src")
  {
    printf -- '---\ndescription: %s\nalwaysApply: false\n---\n\n' "$desc"
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$src"
  } > "$dest_dir/$skill.mdc"
  echo "installed: $dest_dir/$skill.mdc"
}

for skill in "${SKILLS[@]}"; do
  # User-level: available in every project
  fetch_skill "$skill" "$HOME/.claude/skills/$skill"   # Claude Code
  fetch_skill "$skill" "$HOME/.codex/skills/$skill"    # Codex

  if [[ -n "$PROJECT_DIR" ]]; then
    fetch_skill "$skill" "$PROJECT_DIR/.claude/skills/$skill"
    fetch_skill "$skill" "$PROJECT_DIR/.codex/skills/$skill"
    cursor_rule "$skill" "$PROJECT_DIR/.claude/skills/$skill/SKILL.md" "$PROJECT_DIR/.cursor/rules"
  fi
done

cat <<'EOF'

Done. Next steps:
  1. Create a PostPal API key: https://postpal.live → Settings → API Keys (available on all plans).
  2. Export it where your agent runs:  export POSTPAL_API_KEY=ppk_live_...
  3. For Reddit features, connect Reddit in PostPal: Settings → Social Accounts.
  4. Ask your agent things like:
     - "research r/SaaS for pain points around scheduling tools"
     - "generate a launch post for all my platforms and schedule it for Friday 9am"

Cursor note: rules are installed per-project. Re-run with --project <dir> for each project.
EOF
