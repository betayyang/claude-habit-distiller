# Privacy

`claude-habit-distiller` is designed to be **local-first and network-silent**.

## What it reads
- Your Claude Code conversation transcripts: `~/.claude/projects/<project>/*.jsonl`
- Your input history: `~/.claude/history.jsonl`
- Your existing memory files and `CLAUDE.md`

These are files you already have on your own machine. The tool reads them to find
recurring habits and preferences.

## What it writes
- Per-habit memory files under your Claude memory directory
- A sentinel-managed "My Habits" block inside your global `CLAUDE.md`
- Its own `.last-run`, `run.log`, and `.last-summary.txt` inside the skill directory

It only rewrites the region between the `<!-- BEGIN habit-distiller -->` and
`<!-- END habit-distiller -->` markers in `CLAUDE.md`; the rest of that file is
never touched.

## Network
- The distillation itself makes **no network requests** beyond the normal Claude
  Code model calls that Claude Code already makes on your behalf.
- The **only** outbound request this project can make is the optional webhook
  notification, and only if you explicitly set `HABIT_DISTILLER_WEBHOOK`. It is
  unset by default.

## Your responsibility
Because the tool reads your **entire** recent conversation history, those logs may
contain secrets, client data, or other sensitive material you discussed with
Claude Code. Distilled habits are stored in plaintext in your memory files and
`CLAUDE.md`. Review what lands there, and use `exclude_projects` in the config to
skip sensitive repos. You are responsible for the sensitivity of your own local
logs and for where your `CLAUDE.md` ends up (e.g. if you commit it to a repo).
