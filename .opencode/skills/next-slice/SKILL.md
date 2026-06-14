---
name: next-slice
description: >
  Merge the current PR, pull main, determine the next slice from PLAN.md,
  create a branch, and report what to implement. Use when the user says
  "/next" or "next slice" or "merge and start next".
---

# /next — Advance to the next slice

## Steps

1. **Verify current PR merged**
   - Check if the current branch has an open PR via `gh pr view`
   - If open, check if CI is green and merged. If merged → proceed.
   - If not merged, stop and tell the user: "PR #[n] is not merged yet. Merge it first, then run /next again."

2. **Pull main**
   - `git checkout main && git pull origin main`

3. **Find the next slice**
   - Read PLAN.md
   - Find the first unchecked `- [ ]` item
   - Note its slice number and title (e.g. `7.5a  Split Storage into ItemStore + ConfigStore`)
   - If none found, report all slices done and stop.

4. **Create branch**
   - Derive branch name from the slice: lowercase, replace spaces with hyphens, e.g. `slice-7.5a-split-storage`
   - `git checkout -b <branch-name>`

5. **Report**
   - Tell the user the slice number, title, and what the implementation involves.
   - Ask if they want to proceed, or start implementing directly.
