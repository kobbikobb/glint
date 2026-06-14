# Glint — Product Vision

> A glint of clarity before your day begins.

## Problem

Every morning you open 4+ apps (calendar, email, Facebook, Slack) to figure out what actually matters today. Most of it is noise — recurring standups, irrelevant group events, FYI emails. The signal is buried.

## Solution

A macOS app that lives in the background, connects to your data sources, and shows a single popup 1 minute after you become active each morning: your day's highlights, filtered and prioritized.

## Key features

- **Multi-source aggregation** — Calendar (iCloud/Google), Gmail, Facebook events, more later
- **Per-source noise filters** — e.g. "only show events from these Facebook groups", "hide recurring meetings"
- **Smart triage** — classifies items as urgent / important / noise
- **Optional local LLM** (Ollama + Qwen3:8B) — intelligently summarizes your day, explains why things matter
- **Activity-triggered popup** — 1 min after you unlock / become active in the morning
- **Native macOS popup** — not a notification center banner, a proper heads-up window
- **Privacy-first** — LLM runs locally, no cloud dependency
- **One-off meeting detection** — flags non-recurring meetings as signal, not noise

## Installation

```bash
brew install glint
```

## Target audience

Mac users with busy digital lives who want to spend 15 fewer minutes context-switching every morning.

## Non-goals

- Mobile apps (v1)
- Replacing calendar / email clients
- Cloud-based processing (optional upgrade later)
- Collaboration / team features

## Monetization (TBD)

Free tier with local LLM + core integrations. Optional cloud-LLM upgrade for users without a local model or who want deeper summarization.
