# Glint — Architecture Vision

## Overview

Native macOS app (menu bar + popup window). No server. Everything runs locally.

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language | Swift | Native macOS, first-class Apple API access |
| UI | SwiftUI + AppKit (NSWindow for popup) | SwiftUI for prefs, AppKit for the floating popup |
| Local storage | SQLite (GRDB) | Lightweight, no server, persistent cache |
| LLM client | HTTP to Ollama | OpenAI-compatible API, local |
| Keychain | Security framework | OAuth tokens, credentials |

## Components

```
┌─────────────────────────────────────────────────────┐
│  Glint (menu bar app)                                │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ Scheduler │  │ Source   │  │ LLM Engine        │  │
│  │           │  │ Manager  │  │ (optional)        │  │
│  └─────┬─────┘  └─────┬────┘  └────────┬──────────┘  │
│        │              │                 │             │
│  ┌─────┴──────────────┴─────────────────┴──────────┐ │
│  │  Gleaner (orchestrator)                          │ │
│  │  fetches → caches → classifies → assembles       │ │
│  └───────────────────┬──────────────────────────────┘ │
│                      │                                │
│  ┌───────────────────┴──────────────────────────────┐ │
│  │  Popup Window (NSWindow / NSPanel)                │ │
│  └──────────────────────────────────────────────────┘ │
│                                                       │
│  ┌──────────────────────────────────────────────────┐ │
│  │  Preferences Window (SwiftUI)                     │ │
│  │  • Source connections & OAuth                     │ │
│  │  • Per-source filters                             │ │
│  │  • LLM on/off & model selection                   │ │
│  └──────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Data sources (adapters)

Each source implements a shared protocol:

```swift
protocol Source {
    var id: String { get }
    func fetch() async throws -> [Item]
}
```

| Source | API | Auth | Notes |
|---|---|---|---|---|
| Google Calendar | Google Calendar API (REST) | OAuth 2.0 | Read-only events for today |
| Outlook / Office 365 | Microsoft Graph API (REST) | OAuth 2.0 | Calendar + mail |
| Gmail | Gmail API (REST) | OAuth 2.0 | Fetch recent inbox, classify urgency |
| Facebook | Graph API (REST) | OAuth 2.0 | Group events only |
| (future) Slack | Slack API | OAuth | Highlights |

## Data flow — principle

**Popup never calls external APIs.** Fetching and display are decoupled. The popup reads exclusively from local storage.

### Configure (once)

```
User sets up sources in Settings
  ├─ Facebook (OAuth)
  ├─ Google Calendar (OAuth)
  ├─ Outlook (OAuth)
  └─ Gmail (OAuth)
        │
        ▼
Source configs + tokens persisted to Storage protocol
(UserDefaultsStorage → later SQLiteStorage)
```

### Run (daily, background)

```
Scheduler fires (activity trigger or time-based)
       │
       ▼
JobRunner iterates configured Sources
  ├─ FacebookSource.fetch()  ──► Items
  ├─ GoogleCalendarSource.fetch() ──► Items
  ├─ OutlookSource.fetch()   ──► Items
  └─ GmailSource.fetch()     ──► Items
       │
       ▼
Items stored in Storage (dedup by source + id)
       │
       ▼
If LLM enabled → classify items via Ollama (optional enhancement)
```

### Display (instant)

```
Popup opens
       │
       ▼
Read Items from Storage (today's items, already cached)
       │
       ▼
Apply rule-based filters (recurring, group prefs)
       │
       ▼
Group by urgency / category
       │
       ▼
Show NSWindow popup (auto-dismiss after N seconds)
```

## Detection for "morning activity"

- Listen to `NSWorkspace.didWakeNotification` (screen unlock)
- Track last active time per day — if first unlock after 05:00–11:00 window, trigger
- Configurable trigger window

## Key architectural decisions

1. **Fetch/display decoupling** — popup never calls APIs. Sources run as background jobs. Popup reads from cache. Instant, offline-capable.
2. **Storage protocol** — data access behind an interface. Use `UserDefaultsStorage` for prototyping, swap to `SQLiteStorage` later with zero code changes.
3. **Plugin sources via protocol** — adding a new source means writing one struct implementing `Source`. No core changes.
4. **Rule-based fallback** — app works fully without an LLM. LLM is a quality-of-life upgrade.
5. **No cloud** — everything runs on-device. Future optional cloud-LLM is an upgrade path.
6. **OAuth tokens in Keychain** — standard macOS security practice.

## File layout (projected)

```
Glint/
├── Sources/
│   ├── App/
│   │   ├── GlintApp.swift          # @main, menu bar setup
│   │   └── AppDelegate.swift       # NSApplicationDelegate
│   ├── Gleaner/
│   │   ├── Gleaner.swift           # orchestrator
│   │   └── Scheduler.swift         # activity detection + trigger
│   ├── Sources/
│   │   ├── Source.swift            # protocol
│   │   ├── CalendarSource.swift
│   │   ├── GmailSource.swift
│   │   └── FacebookSource.swift
│   ├── LLM/
│   │   ├── LLMEngine.swift         # Ollama HTTP client
│   │   └── Prompts.swift           # classification prompts
│   ├── Storage/
│   │   ├── Cache.swift             # SQLite via GRDB
│   │   └── Keychain.swift          # token storage
│   ├── UI/
│   │   ├── PopupWindow.swift       # floating popup (AppKit)
│   │   ├── PopupView.swift         # popup content (SwiftUI)
│   │   └── PreferencesView.swift   # settings (SwiftUI)
│   └── Models/
│       ├── Item.swift              # unified data model
│       ├── Classification.swift    # urgent / important / noise
│       └── SourceConfig.swift      # per-source settings
├── Resources/
│   └── Assets.xcassets
└── Package.swift                   # (or .xcodeproj)
```
