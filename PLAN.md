# Glint — Build Plan

## Slice 1 — Scaffold + Welcome screen

- [ ] 1a  Create Xcode project, `GlintApp.swift` with @main, empty window
- [ ] 1b  Add NSStatusBar menu bar icon
- [ ] 1c  Click icon → NSWindow with SwiftUI content view
- [ ] 1d  Window shows "Welcome to Glint" + "Get Started" button
- [ ] 1e  Quit menu item works

## Slice 2 — Git

- [ ] 2a  `git init` + `.gitignore` for Xcode/Swift
- [ ] 2b  First commit
- [ ] 2c  GitHub repo created (`glint/glint`), push

## Slice 3 — CI pipeline

- [ ] 3a  `.github/workflows/ci.yml` — builds on push
- [ ] 3b  Green checkmark on commit

## Slice 4 — Activity detection

- [ ] 4a  Listen for screen unlock (`NSWorkspace.didWakeNotification`)
- [ ] 4b  Track if this is the first unlock after 05:00–11:00 today
- [ ] 4c  Wait 1 minute, then open the popup window

## Slice 5 — Facebook OAuth

- [ ] 5a  Register Facebook app, configure OAuth redirect URI
- [ ] 5b  Implement OAuth flow: open browser → receive token
- [ ] 5c  Store token in Keychain
- [ ] 5d  UI: "Connect Facebook" button, connected/disconnected state

## Slice 6 — Facebook events

- [ ] 6a  Fetch upcoming group events via Graph API
- [ ] 6b  Parse into `Item` model
- [ ] 6c  Display events in the popup window

## Slice 7 — Rule-based filter

- [ ] 7a  Per-source config model (include/exclude lists)
- [ ] 7b  Basic filter: hide recurring meetings by title pattern
- [ ] 7c  Facebook filter: show events only from selected groups
- [ ] 7d  Filtered items → popup (no LLM needed)

## Slice 8 — Google Calendar

- [ ] 8a  Google Cloud project + Calendar API enabled + OAuth setup
- [ ] 8b  OAuth flow → token in Keychain
- [ ] 8c  Fetch today's events
- [ ] 8d  Display alongside Facebook events in popup

## Slice 9 — Outlook calendar

- [ ] 9a  Azure app registration + Microsoft Graph API + OAuth setup
- [ ] 9b  OAuth flow → token in Keychain
- [ ] 9c  Fetch today's events
- [ ] 9d  Display in popup

## Slice 10 — Gmail

- [ ] 10a  Google Cloud project + Gmail API + OAuth setup
- [ ] 10b  Fetch recent inbox (last 24h)
- [ ] 10c  Basic urgency keywords (deadline, urgent, EOD, etc.)
- [ ] 10d  Display in popup

## Slice 11 — LLM integration

- [ ] 11a  Detect Ollama running on localhost:11434
- [ ] 11b  Send items for classification via OpenAI-compatible API
- [ ] 11c  Parse response into urgent / important / noise
- [ ] 11d  Fallback gracefully if Ollama is not running

## Slice 12 — LLM narrative summary

- [ ] 12a  Send all items + classification to LLM for narrative
- [ ] 12b  Display "Here's what matters today" paragraph in popup

## Slice 13 — Popup polish

- [ ] 13a  Slide-in animation
- [ ] 13b  Auto-dismiss after N seconds (configurable)
- [ ] 13c  Snooze button (dismiss + retry in 10 min)
- [ ] 13d  Dark mode support

## Slice 14 — Preferences window

- [ ] 14a  Source connection management (add/remove/re-auth)
- [ ] 14b  Per-source filter settings
- [ ] 14c  LLM toggle + model selection
- [ ] 14d  Trigger time window configuration
- [ ] 14e  General settings bindings → persisted

## Slice 15 — SQLite cache

- [ ] 15a  GRDB setup
- [ ] 15b  Cache fetched items (dedup by source + id)
- [ ] 15c  Serve from cache if less than 15 min stale
- [ ] 15d  Clear cache on new day

## Slice 16 — Release pipeline

- [ ] 16a  Code signing setup (Developer ID Application)
- [ ] 16b  Notarization step in CI
- [ ] 16c  `.app.zip` artifact on GitHub Release
- [ ] 16d  Release workflow runs on `git tag v*`

## Slice 17 — Homebrew tap

- [ ] 17a  Create `glint/homebrew-tap` repo
- [ ] 17b  Write `Formula/glint.rb` with versioned URL + checksum
- [ ] 17c  CI auto-updates formula on new release
- [ ] 17d  `brew tap glint/tap && brew install glint` works
