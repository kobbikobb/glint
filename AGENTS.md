# Glint — Agent Workflow

Every change goes through: **Plan → Challenge → Implement → Validate**

## The loop

```
┌──────────────────────────────────────────────────┐
│  1. Plan                                          │
│     Write or update the milestone in PLAN.md      │
│     Include clear DoD for each step               │
├──────────────────────────────────────────────────┤
│  2. Challenge                                     │
│     Read existing code + docs.                    │
│     Stress-test the plan before writing code:     │
    │     • Does this contradict ARCHITECTURE.md?       │
    │     • Does every new type connect to something —  │
    │       no dead-code islands?                       │
    │     • Are there edge cases not handled?           │
    │     • Is there a simpler way?                     │
    │     • Does the DoD actually prove completion?     │
    │       ("build passes" is not proof for logic)     │
│     Raise issues. Resolve before moving on.       │
├──────────────────────────────────────────────────┤
│  3. Implement                                     │
│     Write the code. Follow code style rules.      │
│     • Lean. No comments unless WHY is non-obvious │
│     • Match existing patterns in the repo         │
│     • One conceptual change per PR                │
├──────────────────────────────────────────────────┤
│  4. Validate                                      │
│     • Build: make build passes                    │
│     • Test: make test passes (or add tests)       │
│     • CI: green check on the PR                   │
│     • Demo-able: can you run it and see it work?  │
│     • DoD: every checkbox in the milestone is ✓   │
└──────────────────────────────────────────────────┘
```

## Milestone DoD requirements

Every milestone step must define **how you know it's done**:

| Step type | DoD example |
|---|---|
| Code | `make build` passes, runs without crash |
| UI | Window appears with correct content |
| Integration | OAuth flow completes, token in Keychain |
| Data | Job fetches items, stored in DB, visible in popup |
| Pipeline | CI is green, artifact is signed |

If you can't describe how to validate a step, the plan isn't complete.

## Rules

- **Never skip Challenge phase** — if you're about to implement, first challenge.
- **One PR per slice** — keep changes small and reviewable.
- **Update PLAN.md as you go** — check off items, note blockers.
- **Documentation changes are code changes** — VISION, ARCHITECTURE, PLAN are part of the source.
- **Every change goes through a human.** Create a PR, push it, link it. A human reviews it. A human merges it. The AI never merges.
- **PRs must follow the template** at `.github/PULL_REQUEST_TEMPLATE.md` — fill in Problem, Solution, Files of note sections.
- **PRs must add a label**: `bug`, `enhancement`, or `upgrade`.
- **No comments unless WHY is non-obvious** — never restate code, never narrate plans.
- **Lean over clever** — less code is better than more abstraction.
- **Match existing patterns** — naming, file structure, imports, idioms.
