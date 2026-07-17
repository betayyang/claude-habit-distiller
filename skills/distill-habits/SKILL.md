---
name: distill-habits
description: Review recent Claude Code conversations, distill the user's stable habits and preferences, persist them into long-term memory, and maintain a "My Habits" block in the global CLAUDE.md. The more you use Claude Code, the more it knows you. Trigger manually with /distill-habits, or on a schedule via the installed cron/launchd job.
---

# distill-habits — automatic habit distillation

Goal: extract the **stable habits / preferences / feedback** a user shows across
sessions, turn them into a durable asset, and make every future conversation
understand them better. Do **not** persist one-off task details — keep only
reusable patterns.

This skill is a **reflection job over your own local Claude Code logs**. It reads
nothing but local files and makes **no network requests**.

## Configuration

Read config from the first file that exists, else use built-in defaults:

1. `~/.config/claude-habit-distiller/config.toml`
2. `<repo>/config.toml` (next to this skill's install)

```toml
language        = "en"    # language for distilled habits and the summary
window_days     = 7       # look-back window when .last-run is absent
min_occurrences = 2       # how many times a signal must appear to count as a habit
max_habits      = 16      # max lines in the CLAUDE.md habits block
write_global_claude_md = true   # maintain the global habits block
exclude_projects = []     # project directory names to skip
memory_dir      = "auto"  # "auto" = detect; else an absolute path
```

If no config file exists, use the defaults shown above.

## Path conventions

Detect the Claude home as `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. All paths below
are relative to it unless absolute.

- Conversation transcripts: `projects/<project-dir>/*.jsonl` (one file per session, across all projects)
- User input history: `history.jsonl` (each line has `display` / `timestamp` (ms) / `project` / `sessionId`)
- Long-term memory dir: resolved from `memory_dir`. When `"auto"`, use
  `projects/<home-project-dir>/memory/` where `<home-project-dir>` is the entry
  matching the user's home path (the encoded `$HOME`, e.g. `-Users-alice`). One
  `.md` per habit, plus a `MEMORY.md` index.
- Global habits block: the sentinel-managed region inside `CLAUDE.md` (loaded into every session)
- Last-run timestamp: `<this-skill-dir>/.last-run` (Unix seconds; if absent, assume `window_days` ago)

## Steps

### 1. Determine the time window
Read `.last-run` (Unix seconds). If absent, window start = `window_days` ago.
Window end = now.

### 2. Collect conversation material for the window
- Find **all** `*.jsonl` transcripts under every project dir modified after the
  window start (use `ls -t` or mtime). Skip any project in `exclude_projects`.
- Read them: focus on **user messages**, the user's **corrections / feedback** to
  the AI, **preferences** the user repeats, and approaches the AI was praised for.
- Also scan `history.jsonl` `display` fields in-window: what the user says often,
  which language they use, what they care about.
- With lots of material, prioritize the most recent and strongest signals — no
  need to read every file word for word.

### 3. Distill (this is the core judgment)
Only distill **stable, reusable** things, in four categories matching the memory `type`:
- `user`: who the user is — language, tech-stack preferences, role, communication style.
- `feedback`: how the user wants the AI to work — corrections made, good approaches confirmed. **Must include Why + How to apply.**
- `project`: cross-session goals / constraints. Convert relative dates to absolute.
- `reference`: pointers to external resources (URLs, dashboards, docs).

**Threshold**: a signal must appear at least `min_occurrences` times, or the user
must explicitly say "always do this / remember this", to count as a habit.
One-off items, pure task details, and things already recorded in code/git are **skipped**.

### 4. Write to long-term memory (with provenance)
For each distilled habit, in the memory dir:
- **Dedup first**: if an existing file already covers it, **update** that file
  (accumulate evidence, raise confidence) — don't create a duplicate. Delete old
  memories that new evidence **overturns**.
- File format:
  ```markdown
  ---
  name: <kebab-case-slug>
  description: <one line, used to judge relevance on recall>
  metadata:
    type: user | feedback | project | reference
  ---

  <the fact itself. For feedback/project, append **Why:** and **How to apply:** lines. Link related memories with [[other-name]].>
  ```
- Add/update a pointer line in `MEMORY.md`: `- [Title](file.md) — hook`.

### 5. Maintain the global CLAUDE.md habits block
Only if `write_global_claude_md = true`. Write the **currently most useful habits**
(about `max_habits` lines, concise imperatives) into `CLAUDE.md` between the
sentinels below. **Only rewrite the content between the two markers**; leave the
rest of the file untouched. If the file doesn't exist, create it with just this block.

```
<!-- BEGIN habit-distiller (auto-managed · do not edit this block by hand) -->
## My Habits (auto-distilled · last updated <YYYY-MM-DD>)

- <habit, imperative, so the AI can just follow it>
- ...
<!-- END habit-distiller -->
```
Order by impact on day-to-day collaboration, high to low. Use `language` from
config. Make each line actionable ("Default to Python for scripts" beats "likes Python").

### 6. Wrap up
- Write the current Unix seconds into `.last-run` (`date +%s`).
- Report briefly (in `language`): how many sessions were scanned, which habits
  were added / updated / deleted, and how many lines the CLAUDE.md block now has.

## Principles
- Prefer fewer, higher-confidence entries: unsure whether it's a stable habit? Skip it; wait for more evidence next time.
- Traceable: CLAUDE.md is the concise view; memory is the detailed ledger with the Why.
- Idempotent: re-running over the same window must not produce duplicates.
- Private: read only the user's own local records; send nothing over the network.
