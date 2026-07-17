#!/usr/bin/env bash
# Headless runner for the distill-habits skill.
# Called by the scheduled job (launchd / cron), or run manually for testing:
#   ./skills/distill-habits/run.sh
#
# Optional: set HABIT_DISTILLER_WEBHOOK to a URL to POST the run summary
# (JSON {"text": "..."}) after each run. Leave unset to skip notification.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
LOG="$SKILL_DIR/run.log"
OUT="$SKILL_DIR/.last-summary.txt"
SKILL_MD="$SKILL_DIR/SKILL.md"

command -v claude >/dev/null 2>&1 || {
  echo "error: 'claude' CLI not found on PATH" >&2
  exit 127
}

echo "===== $(date '+%Y-%m-%d %H:%M:%S') distill start =====" >>"$LOG"

# -p headless mode; SKILL.md is the single source of instructions.
# Unattended, so skip interactive permission prompts.
# claude's final report goes to OUT for optional notification.
PROMPT="Read ${SKILL_MD} and follow its steps exactly: review conversations since \
the last run, distill my stable habits, update long-term memory and the habits \
block in the global CLAUDE.md, then update .last-run. Keep the report under 30 \
lines: how many sessions were scanned, which habits were added/updated/deleted, \
how many lines the CLAUDE.md block now has, and the strongest signal."

set +e
claude -p "$PROMPT" --dangerously-skip-permissions >"$OUT" 2>>"$LOG"
EXIT=$?
set -e

# Optional webhook notification.
if [[ -n "${HABIT_DISTILLER_WEBHOOK:-}" ]]; then
  if [[ -s "$OUT" ]]; then TEXT="$(cat "$OUT")"; else
    TEXT="distill-habits finished (exit=$EXIT) but produced no report; see $LOG"; fi
  HEADER="habit-distiller $(date '+%Y-%m-%d %H:%M')"
  python3 - "$HABIT_DISTILLER_WEBHOOK" "$HEADER" "$TEXT" >>"$LOG" 2>&1 <<'PY'
import json, sys, urllib.request
url, header, text = sys.argv[1], sys.argv[2], sys.argv[3]
payload = json.dumps({"text": f"{header}\n\n{text}"}).encode("utf-8")
req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
try:
    resp = urllib.request.urlopen(req, timeout=15)
    print("webhook result:", resp.read().decode("utf-8"))
except Exception as e:
    print("webhook failed:", e)
PY
fi

echo "===== $(date '+%Y-%m-%d %H:%M:%S') distill end (exit=$EXIT) =====" >>"$LOG"
echo >>"$LOG"
exit "$EXIT"
