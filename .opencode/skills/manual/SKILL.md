---
name: manual
description: >
  Guide the user through a slice one mission at a time. Present what to build,
  let them implement, verify, and commit. Use when the user says "/manual" or
  after /next hands off.
---

# /manual — Guided implementation

## Flow

Split the slice into **missions**. Each mission is one focused change:
a new file, a protocol, a method, a test case.

Present missions **one at a time**. Wait for the user to finish before advancing.

## Mission format

```
Mission N/M: <short title>

Files: <path, path>
Outcome: <one sentence — what success looks like>
Verify: <how to check — e.g. "make build passes", "the test passes">

Now it's your turn.
```

## User commands (interpret during conversation)

| Command | Response |
|---|---|
| `/hint` | Give a progressive hint. First call: suggest which file to touch. Second call: suggest the approach. Third call: sketch the code. |
| `/reveal` | Show the full reference implementation for the current mission. Last resort — the user wants to study, not type. |
| `/skip` | Mark the mission incomplete, commit what exists, move to the next. |
| `/verify` | Check the user's work. If correct → commit with message `mission-N: <title>` and advance. If wrong → explain what needs fixing and wait for another `/verify`. |

## Commit discipline

Every verified mission gets its own commit:
```
mission-N: <title>
```

No squashing. Each commit is a checkpoint the user can revert to if they
get lost later.

## Edge cases

- If `/verify` fails and the user is stuck after 3 hints, suggest `/reveal`.
- If the user makes changes but they don't compile, tell them the compiler error — don't fix it for them unless they ask.
- If a mission affects files that don't exist yet, mention them in the mission but let the user create them.
