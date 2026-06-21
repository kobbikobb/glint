# ADR 001: Drop direct Facebook integration — rely on email/calendar sources

**Status:** Accepted
**Date:** 2026-06-21

## Context

Glint needed Facebook events, specifically from a user's group (`341150139339505`). We built:

- `FacebookOAuthService` — ASWebAuthenticationSession OAuth flow, token in Keychain
- `FacebookCLI` — debug tool to probe Graph API endpoints
- Preferences UI for "Connect Facebook"

Facebook's Graph API returns empty `{ data: [] }` for every event endpoint:
- `GET /me/events` — requires killed `user_events` scope (removed 2019 after Cambridge Analytica)
- `GET /me/groups` — requires `groups_access_member_info` scope, which Facebook restricts to Marketing Partners
- `GET /{group_id}/events` — same restriction
- Page events endpoint removed September 2023

No OAuth approach (PKCE, implicit grant, FBSDK) changes this — the data is gone regardless of auth mechanism.

## Decision

**Remove all direct Facebook code.** No `FacebookSource`, no `FacebookOAuthService`, no Facebook references in UI or documentation.

Facebook events will be ingested indirectly through existing sources:

| Source | How Facebook events arrive |
|---|---|
| **Google Calendar** | Facebook Calendar sync (if user enabled it in Google → third-party bridges like IFTTT/Claap) |
| **Outlook Calendar** | Facebook Calendar sync (same pattern) |
| **Gmail** | Facebook sends structured email notifications for group event invites/updates — parse these |

This avoids maintaining dead API code and keeps Glint's architecture focused on accessible data.

## Consequences

- No native Facebook source — users with Facebook-only event workflows get no coverage
- Parsing Facebook event emails from Gmail is less reliable than API (format changes, opt-in only)
- Google Calendar / Outlook sources become higher priority — they serve as the catch-all calendar layer
- Removes ~400 lines of code, simplifies DI container, makes onboarding UI consistent
- Frees engineering time for Google Calendar source (next slice)

## Alternatives considered

1. **Facebook Calendar iCal feed** — `ical/b.php?gid={id}` only accepts user IDs, not group IDs. No accessible group ICS endpoint.
2. **EventKit** — macOS removed Facebook Calendar sync in Ventura+. No Facebook EK sources on modern macOS.
3. **Browser scraping** — fragile, against Facebook ToS, high maintenance cost. Rejected.
4. **Marketing Partner application** — months-long process, rejected for a single-user desktop app.
