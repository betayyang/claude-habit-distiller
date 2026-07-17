#!/usr/bin/env bash
# Remove the scheduled job and the skill symlink. Leaves your memory files,
# CLAUDE.md, and config untouched.
#
# Usage: ./install/uninstall.sh

set -euo pipefail

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILL_DST="$CLAUDE_HOME/skills/distill-habits"

case "$(uname -s)" in
  Darwin)
    PLIST_DST="$HOME/Library/LaunchAgents/com.claude.habit-distiller.plist"
    if [[ -f "$PLIST_DST" ]]; then
      launchctl unload "$PLIST_DST" 2>/dev/null || true
      rm -f "$PLIST_DST"
      echo "removed launchd job: $PLIST_DST"
    fi
    ;;
  Linux)
    if crontab -l 2>/dev/null | grep -q 'claude-habit-distiller\|distill-habits/run.sh'; then
      crontab -l 2>/dev/null | grep -v 'claude-habit-distiller\|distill-habits/run.sh' | crontab -
      echo "removed cron entry"
    fi
    ;;
esac

if [[ -L "$SKILL_DST" ]]; then
  rm -f "$SKILL_DST"
  echo "removed skill symlink: $SKILL_DST"
fi

echo "done. Your habits memory and CLAUDE.md block were left in place."
echo "To also wipe the habits block, delete the region between the"
echo "  <!-- BEGIN habit-distiller --> ... <!-- END habit-distiller --> markers in $CLAUDE_HOME/CLAUDE.md"
