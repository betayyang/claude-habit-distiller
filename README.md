# claude-habit-distiller

**The more you use Claude Code, the more it knows you. 100% local — no server, no API, no data leaves your machine.**

`claude-habit-distiller` is a scheduled *reflection job* for [Claude Code](https://claude.com/claude-code).
Once a day it reads your own local conversation logs, distills the **stable habits
and preferences** you've shown across sessions, and writes them back into:

- a **"My Habits" block** in your global `CLAUDE.md` (loaded into every future session), and
- a set of **per-habit memory files** with the *why* behind each one.

You don't teach it your preferences. It notices them.

## What makes it different

Most "AI memory" projects are **memory infrastructure** — SDKs + vector DBs you
wire into an agent *you* build. This is the opposite: zero infrastructure, pure
files, aimed at Claude Code itself.

| | This tool | Mem0 / Zep / Letta | Claude Code native auto-memory |
|---|---|---|---|
| What it is | Offline **reflection / profiler** | Runtime memory **store** | In-session note-taking |
| Runs | On a schedule, batch | On every agent turn | Opportunistically mid-session |
| Scope | **Cross-project, about *you*** | Per-app, about anything | Per-project, about the repo |
| Infra | None (local files) | Vector DB / server / SDK | Built-in |
| Output | Human-editable `CLAUDE.md` + memory | API-queried embeddings | `MEMORY.md` notebook |

It's a *reflector*, not a *store*. It answers "who is this person and how do they
like to work" — then hands Claude a concise, hand-editable habits list.

## How it works

1. Determine the window since the last run (`.last-run`, or `window_days` on first run).
2. Scan every project's `*.jsonl` transcripts and `history.jsonl` in that window.
3. Distill only **stable, reusable** signals (default: seen ≥ 2 times) into four
   categories — `user`, `feedback`, `project`, `reference`.
4. Write per-habit memory files (dedup + overturn old ones).
5. Rewrite the sentinel-managed **habits block** in `CLAUDE.md` (leaving the rest untouched).
6. Update `.last-run` and print a short summary.

See [`docs/how-it-works.md`](docs/how-it-works.md) for the full design and
[`examples/`](examples/) for a before/after `CLAUDE.md`.

## Install (30 seconds)

```bash
git clone https://github.com/<you>/claude-habit-distiller.git
cd claude-habit-distiller
cp config.example.toml ~/.config/claude-habit-distiller/config.toml   # optional; edit to taste
./install/install.sh                 # links the skill + schedules a daily run
```

- **macOS**: schedules via `launchd`. **Linux**: via `cron`.
- Pick a time: `./install/install.sh --hour 21 --minute 30`
- Skip scheduling (skill only): `./install/install.sh --no-schedule`
- Requires the `claude` CLI on your `PATH`.

Run it manually anytime:

```bash
~/.claude/skills/distill-habits/run.sh        # headless, updates everything
# or, inside an interactive Claude Code session:
/distill-habits
```

Uninstall (leaves your memory + habits block in place):

```bash
./install/uninstall.sh
```

## Configuration

All knobs live in `~/.config/claude-habit-distiller/config.toml` (see
[`config.example.toml`](config.example.toml)): language, look-back window,
stability threshold, max habits, whether to write the global block, project
exclusions, and memory location.

## Optional: notify on each run

Set `HABIT_DISTILLER_WEBHOOK` to a URL and the runner will POST a
`{"text": "..."}` summary after each run (Slack/Discord/Feishu-compatible).
Unset by default — nothing is sent anywhere.

## Privacy

This tool reads **only your local files** under `~/.claude` and makes **no network
requests** (unless you opt into the webhook above). It never uploads your
conversations. Because it reads your entire conversation history, review
[`PRIVACY.md`](PRIVACY.md) and decide how sensitive your local logs are before use.

## License

MIT — see [LICENSE](LICENSE).
