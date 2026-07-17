#!/usr/bin/env bash
# Install claude-habit-distiller:
#   1. link the skill into ~/.claude/skills/
#   2. schedule the daily run via launchd (macOS) or cron (Linux)
#
# Usage:
#   ./install/install.sh [--hour H] [--minute M] [--no-schedule]
#
# Env:
#   CLAUDE_CONFIG_DIR   override the Claude home (default: ~/.claude)

set -euo pipefail

HOUR=21
MINUTE=17
SCHEDULE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hour)   HOUR="$2"; shift 2 ;;
    --minute) MINUTE="$2"; shift 2 ;;
    --no-schedule) SCHEDULE=0; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_HOME/skills"
SKILL_SRC="$REPO_DIR/skills/distill-habits"
SKILL_DST="$SKILLS_DIR/distill-habits"

command -v claude >/dev/null 2>&1 || {
  echo "error: 'claude' CLI not found on PATH. Install Claude Code first." >&2
  exit 127
}

# 1. Link the skill into the Claude skills dir.
mkdir -p "$SKILLS_DIR"
if [[ -e "$SKILL_DST" && ! -L "$SKILL_DST" ]]; then
  echo "error: $SKILL_DST exists and is not a symlink; move it aside first." >&2
  exit 1
fi
ln -sfn "$SKILL_SRC" "$SKILL_DST"
chmod +x "$SKILL_SRC/run.sh"
echo "linked skill: $SKILL_DST -> $SKILL_SRC"

# Seed a user config if none exists.
CONF_DIR="$HOME/.config/claude-habit-distiller"
if [[ ! -f "$CONF_DIR/config.toml" && ! -f "$REPO_DIR/config.toml" ]]; then
  mkdir -p "$CONF_DIR"
  cp "$REPO_DIR/config.example.toml" "$CONF_DIR/config.toml"
  echo "seeded config: $CONF_DIR/config.toml (edit to taste)"
fi

if [[ "$SCHEDULE" -eq 0 ]]; then
  echo "done (skill installed; scheduling skipped)."
  echo "run manually anytime: $SKILL_SRC/run.sh"
  exit 0
fi

RUN_SH="$SKILL_SRC/run.sh"
BIN_PATH="$(dirname "$(command -v claude)"):/usr/local/bin:/usr/bin:/bin"

case "$(uname -s)" in
  Darwin)
    PLIST_DST="$HOME/Library/LaunchAgents/com.claude.habit-distiller.plist"
    sed -e "s|__RUN_SH__|$RUN_SH|g" \
        -e "s|__HOUR__|$HOUR|g" \
        -e "s|__MINUTE__|$MINUTE|g" \
        -e "s|__PATH__|$BIN_PATH|g" \
        -e "s|__SKILL_DIR__|$SKILL_SRC|g" \
        "$REPO_DIR/install/com.claude.habit-distiller.plist.tpl" >"$PLIST_DST"
    launchctl unload "$PLIST_DST" 2>/dev/null || true
    launchctl load "$PLIST_DST"
    echo "scheduled via launchd at $HOUR:$(printf '%02d' "$MINUTE") daily -> $PLIST_DST"
    ;;
  Linux)
    LINE="$(sed -e "s|__RUN_SH__|$RUN_SH|g" \
                -e "s|__HOUR__|$HOUR|g" \
                -e "s|__MINUTE__|$MINUTE|g" \
                -e "s|__PATH__|$BIN_PATH|g" \
                -e "s|__SKILL_DIR__|$SKILL_SRC|g" \
                "$REPO_DIR/install/crontab.tpl" | grep -v '^#')"
    ( crontab -l 2>/dev/null | grep -v 'claude-habit-distiller\|distill-habits/run.sh'; \
      echo "# claude-habit-distiller"; echo "$LINE" ) | crontab -
    echo "scheduled via cron at $HOUR:$(printf '%02d' "$MINUTE") daily"
    ;;
  *)
    echo "unsupported OS for auto-scheduling; run manually: $RUN_SH" >&2
    ;;
esac

echo "done. Test now with: $RUN_SH"
