# Glint — Build Plan

## Architecture principle

```
Configure (settings UI)    Run (background jobs)       Display (from cache)
─────────────────────      ──────────────────────      ─────────────────────
  ● Add source               Scheduler fires             Popup reads local DB
  ● OAuth auth               ├─ Source A fetch job       shows today's items
  ● Set filters              ├─ Source B fetch job
                             └─ Source C fetch job
                                    │
                                    ▼
                               Local DB
                            (single source of truth)
```

Popups never call APIs. Everything is pre-fetched and cached.

## ✅ Slice 1–4 — Done

Scaffold, menu bar, welcome screen, git, CI, morning unlock detection.

## Slice 5 — Storage abstraction

- [x] 5a  Define `Storage` protocol (save/load Items, source configs)
- [x] 5b  `UserDefaultsStorage` implementation (zero setup, fast iteration)
- [x] 5c  Wire up so all data access goes through the protocol

## Slice 6 — Guided onboarding (first-run UX)

- [x] 6a  First launch → full-screen welcome wizard (not empty window)
- [x] 6b  Step 1: "Glint helps you start your day informed"
- [x] 6c  Step 2: "Connect your first source" (choose Google/Outlook/etc.)
- [x] 6d  Step 3: Set trigger time / preferences
- [x] 6e  Step 4: "All set — see you tomorrow morning"
- [x] 6f  Subsequent launches → normal menu bar app (no wizard)

## Slice 7 — Source protocol + job runner

- [x] 7a  Refine `Source` protocol: `func fetch() async throws -> [Item]`
- [x] 7b  `JobRunner` — runs each configured source, stores results in DB
- [x] 7c  Scheduler calls `JobRunner` on morning trigger (instead of showing popup directly)
- [x] 7d  Popup reads from DB after jobs complete

## Slice 7.5 — Architecture cleanup (seams)

_Establish correct seams before adding real sources._

- [x] 7.5a  Split `Storage` into `ItemStore` + `ConfigStore` protocols, separate implementations
- [x] 7.5b  Extract `AppDelegate` from `GlintApp.swift` into `App/AppDelegate.swift`
- [x] 7.5c  Extract `Scheduler` from `AppDelegate` into `Gleaner/Scheduler.swift`
- [x] 7.5d  Create `Services/DigestService.swift` — UI-facing load/classify/group (ContentView stops importing Storage)
- [x] 7.5e  Create `Agent/Classifier.swift` protocol + `Agent/NoopClassifier.swift` placeholder
- [x] 7.5f  Add CI guardrails: import-boundary checks, directory-structure check, dead-symbol detection (DoD: introduce deliberate violation, verify CI failure, revert)
- [x] 7.5g  Move `ContentView.swift` → `UI/PopupView.swift`, restructure directories to match target layout

## Slice 8 — Google Calendar

- [ ] 8a  Google Cloud project + Calendar API enabled + OAuth setup
- [ ] 8b  OAuth flow → token in Keychain
- [ ] 8c  `GoogleCalendarSource` implements `Source`
- [ ] 8d  Display in popup

## Slice 9 — Outlook calendar

- [ ] 9a  Azure app registration + Microsoft Graph API + OAuth setup
- [ ] 9b  OAuth flow → token in Keychain
- [ ] 9c  `OutlookCalendarSource` implements `Source`
- [ ] 9d  Display in popup

## Slice 10 — Gmail

- [ ] 10a  Google Cloud project + Gmail API + OAuth setup
- [ ] 10b  Fetch recent inbox (last 24h)
- [ ] 10c  Basic urgency keywords (deadline, urgent, EOD, etc.)
- [ ] 10d  Display in popup

## Slice 11 — Rule-based filters

- [ ] 11a  Per-source filter config model (include/exclude lists)
- [ ] 11b  Basic filter: hide recurring meetings by title pattern
- [ ] 11c  Filtered items → popup (no LLM needed)

## Slice 12 — LLM integration

- [ ] 12a  Detect Ollama running on localhost:11434
- [ ] 12b  Send items for classification via OpenAI-compatible API
- [ ] 12c  Parse response into urgent / important / noise
- [ ] 12d  Fallback gracefully if Ollama is not running (DoD: items displayed as .unclassified, no error UI, silent fallback to NoopClassifier)

## Slice 13 — LLM narrative summary

- [ ] 13a  Add `loadSummary() -> String?` to `DigestService` for narrative, send items + classification to LLM
- [ ] 13b  Display "Here's what matters today" paragraph in popup (requires UI slot in PopupView)

## Slice 14 — Popup polish

- [ ] 14a  Slide-in animation
- [ ] 14b  Auto-dismiss after N seconds (configurable via ConfigStore, Timer in AppDelegate/PopupView closes window)
- [ ] 14c  Snooze button (dismiss + retry in 10 min)
- [ ] 14d  Dark mode support

## Slice 15 — SQLite (GRDB)

- [ ] 15a  Add GRDB dependency
- [ ] 15b  `SQLiteStorage` implements `Storage` protocol
- [ ] 15c  Migrate from `UserDefaultsStorage` (DoD: seed UserDefaults, run migration, SQLite store has matching data)
- [ ] 15d  Add change notifications / hooks for downstream consumers

## Slice 16 — Release pipeline

- [ ] 16a  Code signing (Developer ID Application)
- [ ] 16b  Notarization in CI
- [ ] 16c  `.app.zip` artifact on GitHub Release
- [ ] 16d  Release workflow on `git tag v*`

## Slice 17 — Homebrew tap

- [ ] 17a  Create `glint/homebrew-tap` repo
- [ ] 17b  Write `Formula/glint.rb` with versioned URL + checksum
- [ ] 17c  CI auto-updates formula on new release
- [ ] 17d  `brew tap glint/tap && brew install glint` works
