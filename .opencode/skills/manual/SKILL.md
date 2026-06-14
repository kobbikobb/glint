---
name: manual
description: >
  Guide the user through a slice one mission at a time. Present what to build,
  let them implement, verify, and commit. Use when the user says "/manual" or
  after /next hands off.
---

# /manual — Guided implementation

## Philosophy

The user learns by solving the puzzle — looking at the codebase, figuring out where a change goes, and structuring the solution themselves. The AI's job is to point at the right puzzle, then get out of the way.

**Never give** code snippets unprompted. **Never suggest** approach, syntax, or implementation details in the mission. Focus on *why* and *where* — the *how* is the user's puzzle.

## Restraint rule (critical)

After presenting a mission, say **only** `Now it's your turn.` Then stop. No suggestions, no "you could", no approach hints.

If the user asks you to write code, remind them this is their mission: "I can point you at the right file or explain why this exists, but the implementation is yours."

## Mission format

```
Mission N/M: <title>

Files: <path, path>
Context: <why this exists — architecture rationale, not implementation>
Verify: <how to check — "make build passes", "the test compiles">

Now it's your turn.
```

`Context` is the key field. It explains the architectural decision that motivates the mission — why `ItemStore` and `ConfigStore` are separate protocols, why the scheduler lives in `Gleaner/`, etc. This is what the user needs to orient themselves.

No `Outcome` field — the mission title + context already say what to build.

## Mission sizing

One file or one concept (≤3 files, 1 abstraction boundary). If a step is bigger, split it. Roughly 5-15 minutes of work.

## User commands

| Command | Response |
|---|---|
| `/hint` | Tell the user which file or area to look at, or point at existing code that does something similar. No code snippets unless asked. |
| `/reveal` | Show the full reference implementation. Last resort — the user wants to study. Does NOT verify or commit; user calls `/verify` after. |
| `/skip` | Discard unstaged changes (revert if committed), move to next mission. |
| `/abort` | Cancel the entire slice. Drop the branch, `git checkout main`. |
| `/status` | Print current mission, completed, remaining. |
| `/restart` | Reset current mission: revert working-tree changes or last commit so the user can start fresh. |
| `/verify` | Review the user's work. If correct → commit `mission-N: <title>` and advance. If not → explain what to fix. User fixes and calls `/verify` again. |

## Conversation state

Track in conversation (no file-based state):

- Current slice number and title
- Current mission index (N of M)
- Completed missions
- Current branch name

If `/verify` with no active mission: "There is no active mission. Try `/status`."

## Edge cases

- 3 hints used and still stuck → suggest `/reveal`.
- Compiler error → report it verbatim, don't fix.
- Missing files → name them in the mission, user creates them.
- Branch mismatch → warn and refuse commands until resolved.
