---
name: next-slice
description: >
  Merge the current PR, pull main, determine the next slice from PLAN.md,
  create a branch, then hand off to /manual with a random "your turn" phrase.
  Use when the user says "/next" or "next slice".
---

# /next — Advance to the next slice

## Steps

1. **Verify current PR merged**
   - Check if the current branch has an open PR via `gh pr view`
   - If open and merged → proceed.
   - If not merged, stop: "PR #[n] is not merged yet. Merge it first, then run /next again."

2. **Pull main**
   - `git checkout main && git pull origin main`

3. **Find the next slice**
   - Read PLAN.md
   - Find the first unchecked `- [ ]` item
   - Note its slice number and title
   - If none found, report all slices done and stop.

4. **Create branch**
   - Derive branch name from the slice: lowercase, replace spaces with hyphens
   - `git checkout -b <branch-name>`

5. **Pick a random phrase**
   Choose from:
   - "Now it's time for you to do the hard work."
   - "Your keyboard awaits."
   - "The plan is set — the rest is typing."
   - "Take it from here."
   - "This is where you earn your coffee."

6. **Hand off to /manual**
   - Load the `manual` skill and follow its guided implementation flow.
   - Tell the user the slice number and title before starting.
