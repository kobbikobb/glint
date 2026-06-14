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
- [x] 6c  Step 2: "Connect your first source" (choose Facebook/Google/etc.)
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
- [ ] 7.5b  Extract `AppDelegate` from `GlintApp.swift` into `App/AppDelegate.swift`
- [ ] 7.5c  Extract `Scheduler` from `AppDelegate` into `Gleaner/Scheduler.swift`
- [ ] 7.5d  Create `Services/DigestService.swift` — UI-facing load/classify/group (ContentView stops importing Storage)
- [ ] 7.5e  Create `Agent/Classifier.swift` protocol + `Agent/NoopClassifier.swift` placeholder
- [ ] 7.5f  Add CI guardrails: import-boundary checks, directory-structure check, dead-symbol detection
- [ ] 7.5g  Move `ContentView.swift` → `UI/PopupView.swift`, restructure directories to match target layout

## Slice 8 — Facebook OAuth

- [ ] 8a  Register Facebook app, configure OAuth redirect URI
- [ ] 8b  OAuth flow: open browser → receive token → store in Keychain
- [ ] 8c  "Connect Facebook" UI in settings, connected/disconnected state
- [ ] 8d  Token stored via Keychain (Storage protocol for secrets)

## Slice 9 — Facebook events (first real data)

- [ ] 9a  `FacebookSource` implements `Source` protocol
- [ ] 9b  Fetch upcoming group events via Graph API
- [ ] 9c  Parse into `Item` model
- [ ] 9d  Stored in DB → displayed in popup
- [ ] 9e  Milestone: first end-to-end flow (Facebook → DB → popup)

## Slice 10 — Google Calendar

- [ ] 10a  Google Cloud project + Calendar API enabled + OAuth setup
- [ ] 10b  OAuth flow → token in Keychain
- [ ] 10c  `GoogleCalendarSource` implements `Source`
- [ ] 10d  Display alongside Facebook in popup

## Slice 11 — Outlook calendar

- [ ] 11a  Azure app registration + Microsoft Graph API + OAuth setup
- [ ] 11b  OAuth flow → token in Keychain
- [ ] 11c  `OutlookCalendarSource` implements `Source`
- [ ] 11d  Display in popup

## Slice 12 — Gmail

- [ ] 12a  Google Cloud project + Gmail API + OAuth setup
- [ ] 12b  Fetch recent inbox (last 24h)
- [ ] 12c  Basic urgency keywords (deadline, urgent, EOD, etc.)
- [ ] 12d  Display in popup

## Slice 13 — Rule-based filters

- [ ] 13a  Per-source filter config model (include/exclude lists)
- [ ] 13b  Basic filter: hide recurring meetings by title pattern
- [ ] 13c  Facebook filter: show events only from selected groups
- [ ] 13d  Filtered items → popup (no LLM needed)

## Slice 14 — LLM integration

- [ ] 14a  Detect Ollama running on localhost:11434
- [ ] 14b  Send items for classification via OpenAI-compatible API
- [ ] 14c  Parse response into urgent / important / noise
- [ ] 14d  Fallback gracefully if Ollama is not running

## Slice 15 — LLM narrative summary

- [ ] 15a  Send all items + classification to LLM for narrative
- [ ] 15b  Display "Here's what matters today" paragraph in popup

## Slice 16 — Popup polish

- [ ] 16a  Slide-in animation
- [ ] 16b  Auto-dismiss after N seconds (configurable)
- [ ] 16c  Snooze button (dismiss + retry in 10 min)
- [ ] 16d  Dark mode support

## Slice 17 — SQLite (GRDB)

- [ ] 17a  Add GRDB dependency
- [ ] 17b  `SQLiteStorage` implements `Storage` protocol
- [ ] 17c  Migrate from `UserDefaultsStorage`
- [ ] 17d  Add change notifications / hooks for downstream consumers

## Slice 18 — Release pipeline

- [ ] 18a  Code signing (Developer ID Application)
- [ ] 18b  Notarization in CI
- [ ] 18c  `.app.zip` artifact on GitHub Release
- [ ] 18d  Release workflow on `git tag v*`

## Slice 19 — Homebrew tap

- [ ] 19a  Create `glint/homebrew-tap` repo
- [ ] 19b  Write `Formula/glint.rb` with versioned URL + checksum
- [ ] 19c  CI auto-updates formula on new release
- [ ] 19d  `brew tap glint/tap && brew install glint` works
