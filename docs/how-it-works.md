# How it works

`claude-habit-distiller` is a **reflection job**, not a memory store. It runs on a
schedule, reads your own Claude Code logs, and produces a curated, human-editable
profile of how you like to work.

## The pipeline

```
last run ──► scan transcripts + history ──► distill (≥ N occurrences)
                                                   │
                        ┌──────────────────────────┴───────────────────────┐
                        ▼                                                    ▼
          per-habit memory files                            "My Habits" block in CLAUDE.md
          (detailed, with Why)                              (concise, ~16 imperatives)
```

### 1. Window
The skill reads `.last-run` (Unix seconds). On first run it looks back
`window_days` (default 7). Everything modified since then is in scope. This makes
runs **incremental and idempotent** — re-running the same window won't duplicate.

### 2. Collect
It finds every `*.jsonl` transcript across **all** project directories modified in
the window, plus in-window entries from `history.jsonl`. It weights **user
messages, corrections, repeated preferences, and praised approaches** most heavily.

### 3. Distill — the core judgment
A signal only becomes a habit if it appears at least `min_occurrences` times, or
you explicitly said "always do this / remember this". One-off task details and
anything already captured in code/git are dropped. Each survivor is filed under
one of four types:

| type | captures | extra fields |
|---|---|---|
| `user` | who you are — language, stack, role, style | — |
| `feedback` | how you want the AI to work | **Why** + **How to apply** |
| `project` | cross-session goals / constraints | absolute dates |
| `reference` | external resources (URLs, dashboards) | — |

### 4. Memory files (the ledger)
Each habit is one markdown file with frontmatter (`name`, `description`, `type`)
and a body. The skill **dedups against existing files** — updating and raising
confidence rather than duplicating — and **deletes memories that new evidence
overturns**. A `MEMORY.md` index carries one pointer line per habit.

### 5. CLAUDE.md habits block (the view)
The most useful ~`max_habits` habits are rendered as concise imperatives between:

```
<!-- BEGIN habit-distiller (auto-managed · do not edit this block by hand) -->
...
<!-- END habit-distiller -->
```

Only this region is rewritten; the rest of your `CLAUDE.md` is preserved. Because
it's plaintext, you can hand-edit or delete it anytime.

## Design principles
- **Prefer fewer, higher-confidence entries.** Unsure it's stable? Skip it; wait for more evidence.
- **Two layers.** `CLAUDE.md` is the concise view Claude loads every session; the memory files are the detailed ledger with the *why*.
- **Idempotent.** Re-running over the same window produces no duplicates.
- **Private.** Reads only local records; sends nothing over the network.

## Why not just use native auto-memory?
Claude Code's built-in auto-memory records useful facts *opportunistically during a
session*, scoped to *the project* ("the build command that works here"). This tool
is complementary: it runs *between* sessions, looks *across all projects*, and
builds a profile of *you* — communication style, recurring corrections, standing
preferences — that no single session would surface.
