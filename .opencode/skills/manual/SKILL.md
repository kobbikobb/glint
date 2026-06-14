---
name: manual
description: >
  Guide the user through a slice one mission at a time. Present what to build,
  let them implement, verify, and commit. Use when the user says "/manual" or
  after /next hands off.
---

# /manual — Guided implementation

## Restraint rule (critical)

After presenting a mission, say **only** `Now it's your turn.` Do not suggest approaches, offer to pair, or propose code. Silence is the goal — the user learns by typing.

If they ask you to write the code, remind them this is their mission. If they're genuinely stuck after 3 hints, offer `/reveal`.

## Mission sizing

A mission should fit in **one file or one concept** (≤3 files, 1 abstraction boundary). If the slice step looks bigger, split it into multiple missions. Roughly 5-15 minutes of work per mission.

## Mission format

```
Mission N/M: <short title>

Files: <path, path>
Outcome: <one sentence — what success looks like>
Verify: <how to check — e.g. "make build passes", "the test compiles">

Now it's your turn.
```

## User commands

| Command | Response |
|---|---|
| `/hint` | Progressive: first → which file, second → approach, third → code sketch. |
| `/reveal` | Show the full reference implementation. Does NOT verify or commit — the user studies it, then calls `/verify` to proceed. |
| `/skip` | Mark mission incomplete, discard unstaged changes (revert if committed), move to next. |
| `/abort` | Cancel the entire slice. Drop the branch, `git checkout main`, ask what next. |
| `/status` | Print the current slice, current mission, completed missions, and remaining missions. |
| `/restart` | Reset the current mission: revert working-tree changes or the last commit so the user can start fresh. |
| `/verify` | Review the user's work. If correct → commit with message `mission-N: <title>` and advance. If not → explain what needs fixing and wait for another `/verify`. |

## Commit discipline

Each verified mission gets its own commit:
```
mission-N: <short title>
```

No squashing. Each commit is a checkpoint.

## Conversation state (no file-based state)

Track the following in conversation context:

- Current slice number and title
- Current mission index (N of M)
- Completed missions list
- Current branch name

If the user calls `/verify` when no mission is active, refuse: "There is no active mission. Call `/status` to see where we are."

## Edge cases

- If `/verify` fails and the user is stuck after 3 hints, suggest `/reveal`.
- If changes don't compile, report the compiler error — don't fix it for them.
- Missing files: name them in the mission, let the user create them.
- Branch switch mid-session: detect via `git branch --show-current`. If it doesn't match the tracked branch, warn and refuse commands until resolved.
