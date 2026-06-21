---
name: next-slice
description: >
  Verify the current PR is merged, pull main, determine the next slice from
  PLAN.md, create a branch, then run the guided implementation flow with a
  random "your turn" phrase. Use when the user says "/next" or "next slice".
---

# /next — Advance to the next slice

## Steps

1. **Verify current PR is merged**
   - Check if the current branch has an open PR via `gh pr view`
   - If the PR state is `MERGED` → proceed.
   - If the PR is still open, stop: "PR #[n] is not merged yet. Merge it on GitHub, then run /next again."

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

5. **Decide mode (~10% manual, ~90% direct)**
   - Roll a random number 1–100: `echo $(( RANDOM % 100 + 1 ))`.
   - If ≤ 10: drop into **manual mode** (step 6).
   - Otherwise: **direct mode** — implement the slice yourself, commit, push, create PR with the template, add label, and report the URL. Skip step 6.
   - Exception: if the slice involves real credentials, API keys, or external account setup (e.g. "Register Google Cloud project"), always pick manual mode.

6. **Manual mode (guided implementation)**
   - Pick a random phrase:
     - "Now it's time for you to do the hard work."
     - "Your keyboard awaits."
     - "The plan is set — the rest is typing."
     - "Take it from here."
     - "This is where you earn your coffee."
   - Follow the workflow defined in `.opencode/skills/manual/SKILL.md` — split into missions, present one at a time, wait for `/verify`, etc.
   - Do NOT ask the user to load `/manual` as a skill. The manual flow is part of this session now.
   - Tell the user the slice number and title, then present the first mission.
