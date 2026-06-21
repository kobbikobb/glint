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

## Seams

The architecture is organised around five seams that isolate concerns. Each seam maps to a directory in the source tree.

| Seam | Directory | Responsibility | Talks to |
|---|---|---|---|
| **Fetch** | `Sources/` | Implement `Source` protocol, call external APIs | `ItemStore` |
| **Orchestrate** | `Gleaner/` | Schedule and run fetch jobs | `Sources/`, `ItemStore` |
| **Store** | `Storage/` | Persist items and config behind protocols | nothing (protocol) |
| **Service** | `Services/` | UI-facing logic: load, classify, group | `ItemStore`, `Agent/` |
| **Agent** | `Agent/` | Classify/summarise items (LLM or no-op) | nothing (protocol) |

UI talks only to **Service**. Service talks to **Store** and **Agent**. Fetch talks to **Store**. This prevents circular dependencies and makes each seam testable in isolation.

## Components

```
┌──────────────────────────────────────────────────────────┐
│  Glint (menu bar app)                                     │
│                                                           │
│  ┌──────────────────┐  ┌──────────────┐                  │
│  │  Scheduler        │  │  JobRunner   │                  │
│  │  (screen wake)    │──│  (actor)     │                  │
│  └──────────────────┘  └──────┬───────┘                  │
│                               │                           │
│                     ┌─────────┼──────────┐               │
│                     │         │          │               │
│              ┌──────▼──┐  ┌──▼──────┐   │               │
│              │ Source A│  │ Source B│   │   Source prot. │
│              └──────┬──┘  └──┬──────┘   │               │
│                     │         │          │               │
│                     └─────────┼──────────┘               │
│                               │ Items                     │
│                     ┌─────────▼──────────┐               │
│                     │  ItemStore          │  ◄── protocol │
│                     │  (SQLite/UserDef)   │               │
│                     └────────────────────┘               │
│                               ▲                           │
│                               │ today's items             │
│  ┌────────────────────────────┼────────────────────────┐ │
│  │  Services                  │                         │ │
│  │  ┌─────────────────────────▼─────────────────┐      │ │
│  │  │  DigestService                             │      │ │
│  │  │  load(group:) → classified → grouped       │      │ │
│  │  └─────────────────────────┬─────────────────┘      │ │
│  │                            │                          │ │
│  │  ┌─────────────────────────▼─────────────────┐      │ │
│  │  │  Classifier (agent seam)                   │      │ │
│  │  │  NoopClassifier (pass-through)              │      │ │
│  │  └───────────────────────────────────────────┘      │ │
│  └────────────────────────────────────────────────────┘ │
│                            │ view model                   │
│  ┌─────────────────────────▼────────────────────────┐   │
│  │  UI (PopupView, PreferencesView)                  │   │
│  │  reads from DigestService only — never Storage    │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│  ┌──────────────────────────────────────────────────────┐│
│  │  ConfigStore (separate from ItemStore)                ││
│  │  SourceConfig, authState, preferences                 ││
│  └──────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘
```

## Data flow

**Configure (once):**
```
User sets up sources in Preferences
  → ConfigStore.saveSourceConfig()
  → OAuth token → Keychain (future)
```

**Run (daily, background):**
```
Scheduler fires (didWakeNotification)
  → JobRunner.runAll()
    → for each enabled SourceConfig:
      → Source.fetch() → [Item]
      → ItemStore.saveItems()
```

**Display (instant):**
```
Popup opens
  → DigestService.load()
    → ItemStore.items(for: today) → [Item]
    → Classifier.classify([Item]) → [Item] with urgency
    → Group by urgency / source
    → Return view model
  → PopupView renders view model
  → Auto-dismiss after N seconds
```

## Key architectural decisions

1. **Fetch/display decoupling** — popup never calls APIs. Sources run as background jobs. Popup reads from cache. Instant, offline-capable.
2. **ItemStore + ConfigStore** — data access behind two protocols. `ItemStore` for daily digest (ephemeral, date-keyed). `ConfigStore` for app configuration (persistent, stable keys). Different storage implementations can differ per seam.
3. **Plugin sources via protocol** — adding a new source means writing one struct implementing `Source`. No core changes.
4. **Services layer** — `DigestService` sits between UI and Storage. UI never imports Storage. Makes the popup testable: mock ItemStore + mock Classifier → verify grouping.
5. **Agent seam** — `Classifier` protocol with a `NoopClassifier` pass-through. The LLM implementation slots in later. UI doesn't know which classifier it's using.
6. **Rule-based fallback** — app works fully without an LLM. LLM is a quality-of-life upgrade.
7. **No cloud** — everything runs on-device. Future optional cloud-LLM is an upgrade path.
8. **OAuth tokens in Keychain** — standard macOS security practice.
9. **No direct Facebook integration** — Facebook Graph API event endpoints are dead. See `Docs/adr/001-drop-facebook-direct-integration.md`.

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
| — | — | — | — |

## Data flow — principle

**Popup never calls external APIs.** Fetching and display are decoupled. The popup reads exclusively from local storage.

### Configure (once)

```
User sets up sources in Settings
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

## File layout (target)

```
Sources/Glint/
├── App/
│   ├── GlintApp.swift          # @main
│   └── AppDelegate.swift       # NSApplicationDelegate, menu bar, lifecycle
├── Gleaner/
│   ├── Scheduler.swift         # screen wake detection + trigger
│   └── JobRunner.swift         # runs sources, stores results
├── Sources/
│   ├── Source.swift            # protocol
│   ├── GoogleCalendarSource.swift
│   ├── GmailSource.swift
│   └── OutlookSource.swift
├── Services/
│   └── DigestService.swift     # UI-facing: load → classify → group
├── Agent/
│   ├── Classifier.swift        # protocol: classify([Item]) -> [Item]
│   └── NoopClassifier.swift   # pass-through (placeholder)
├── Storage/
│   ├── ItemStore.swift         # protocol: daily digest CRUD
│   ├── ConfigStore.swift       # protocol: app config CRUD
│   ├── UserDefaultsItemStore.swift
│   ├── UserDefaultsConfigStore.swift
│   └── Keychain.swift          # (future)
├── UI/
│   ├── PopupView.swift         # popup content (SwiftUI), reads DigestService
│   ├── OnboardingView.swift    # first-run wizard (pure UI)
│   └── PreferencesView.swift   # settings (future)
└── Models/
    ├── Item.swift              # unified data model
    ├── Classification.swift    # urgent / important / noise (future)
    └── SourceConfig.swift      # per-source settings
