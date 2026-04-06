# WiFi Troubleshooter — Architecture

**Version:** 2.0
**Date:** 2026-03-30

---

## Core Concept

A Flutter Web app embedded in the router, accessed at `http://192.168.1.1/troubleshoot`. Two access modes on the same URL:

- **Customer mode** — no login, browser diagnostics, plain-language verdicts
- **Support agent mode** — router admin password, JNAP API access, all 6 flows, raw data visible

This follows the established hidden-URL pattern already shipping on this device (`/debug.html`, `/cpehelp.html`). No new infrastructure. No native app. No backend.

---

## What Already Exists on the Device

Confirmed live on M60CF (2026-03-30):

| Asset | Path | Relevance |
|---|---|---|
| lighttpd web server | Ports 80 + 443 | Already serves Flutter Web — our bundle drops into same server |
| Flutter Web runtime | `/www/flutter.js`, `/www/flutter_bootstrap.js` | Flutter runtime already present — troubleshooter reuses it |
| Router admin UI | `/www/main.dart.js` (`privacy_gui` v1.2.2) | Same framework, same team |
| JNAP API | `POST /JNAP/` | Calls router state — used by debug.html and cpehelp.html today |
| Debug page | `/www/debug.html` | Hidden URL pattern; uses `X-JNAP-Authorization` for privileged ops |
| CPE Help portal | `/www/cpehelp.html` | Hidden URL; access-controlled by JNAP `smart_mode`; tab portal for TR-069/369 |
| LAN IP | `192.168.1.1` | Gateway IP confirmed via UCI |

The troubleshooter is additive. It uses existing infrastructure, existing auth patterns, and existing JNAP data.

---

## Delivery

| Mode | URL | Auth | Capabilities |
|---|---|---|---|
| **Router embed — customer** | `http://192.168.1.1/troubleshoot` | None | Speed, DNS, gateway, latency. Flows 1, 2, 4. |
| **Router embed — support agent** | Same URL, login button | Router admin password (JNAP) | All customer capabilities + JNAP data. All 6 flows. |
| **Hosted web** | Linksys CDN support URL | None (customer mode only) | Same as customer mode. No JNAP. |

The hosted web version serves customers whose firmware does not yet include the router embed. Capability is browser-only. Support agent mode is only available from the router embed — JNAP cannot be proxied to an external host without a backend.

---

## Tech Stack

### Flutter Web

- `flutter build web` → static bundle → `/www/troubleshoot/` in firmware
- Single Dart codebase; same build artifact goes to router firmware and CDN
- Auth state determines which Dart services are instantiated (browser-only vs. browser + JNAP)
- No separate native build targets; no app store pipeline

### JNAP Integration (Support Agent Mode)

```
POST http://192.168.1.1/JNAP/
X-JNAP-Action: http://linksys.com/jnap/<action>
X-JNAP-Authorization: Basic <base64(admin:password)>
Content-Type: application/json
```

Same-origin from the router embed — no CORS issues. Existing pages use this today. JNAP calls planned for Phase 1:

| JNAP Action | Data Retrieved |
|---|---|
| `GetDeviceList` / `GetNetworkConnections` | Connected clients, IP, MAC, hostname |
| WiFi AP state | Channel, band, BSSID per AP |
| WiFi client stats | Per-client RSSI, TX/RX rate, band association |
| DHCP service | Lease table, pool size, utilization |
| WAN status | Link state, uptime, error counts |
| `GetDeviceInfo` | Router model, firmware version, uptime |

### Speed Test: LibreSpeed (self-hosted)

Open source, self-hosted on Linksys infrastructure. No licensing. Test data stays in Linksys systems. Measures download, upload, latency, jitter. Called from browser in both modes.

### No Backend

No cloud database, no report server, no analytics pipeline. All data is session-local. The only external network call is LibreSpeed (Linksys-hosted).

---

## Diagnostic Service Architecture

```
lib/
├── diagnostics/
│   ├── browser_service.dart      # Browser-level tests (speed, DNS, ping) — both modes
│   ├── jnap_service.dart         # JNAP API client — agent mode only
│   ├── diagnostic_engine.dart    # Flow logic — calls browser_service ± jnap_service
│   └── models/                   # Verdict, DiagnosticResult, JnapData schemas
├── ui/
│   ├── customer/                 # Customer mode screens + flow UX
│   ├── agent/                    # Support agent screens (raw data tables, all 6 flows)
│   └── shared/                   # Shared widgets (verdict card, progress steps)
└── main.dart                     # Auth state router → customer or agent UI tree
```

The diagnostic engine is auth-state-agnostic. It takes a `DiagnosticContext` that includes available data sources. In customer mode, `JnapService` is not initialized. In agent mode, it is. The flow logic is the same; the data richness differs.

---

## Authentication Flow

```
Customer arrives at /troubleshoot
         │
         ▼
   Consent screen (first run)
         │
         ▼
   Customer Mode UI
   [Support Login] button visible
         │
         ▼ (agent taps login)
   Password entry screen
         │
   POST /JNAP/ with test action
         ├── 200 OK → Agent Mode UI
         └── 401 → "Incorrect password"
```

- No session token stored — JNAP password is held in memory for the session only
- Agent mode is not persistent across browser tabs or sessions
- No new auth mechanism required — JNAP Basic auth is already the pattern

---

## Two-Mode UI Behavior

| Element | Customer Mode | Support Agent Mode |
|---|---|---|
| Verdict display | Plain language only | Plain language + raw data table |
| Flow selector | Flows 1, 2, 4 | All 6 flows |
| Connected device list | Not shown | Shown with RSSI, band, IP |
| DHCP table | Not shown | Shown with lease count, expiry |
| WAN status | Not shown | Shown |
| Speed test result | "Your speed is X" plain language | Mbps value + comparison to expected |
| Error/log data | Not shown | Shown if available via JNAP |

---

## Build & Distribution

### Router Embed

- `flutter build web --base-href /troubleshoot/`
- Output copied into router firmware at `/www/troubleshoot/`
- Served automatically by existing lighttpd at `http://192.168.1.1/troubleshoot`
- Update mechanism: firmware OTA — same as all other `/www/` content
- Firmware team includes bundle in production image (coordination required)

### Hosted Web (CDN)

- Same Flutter Web build, different base href
- Deployed to Linksys CDN / support URL via CI on release tag
- Update mechanism: instant CDN redeploy
- Customer mode only — no JNAP access

### CI/CD

- GitHub Actions on release tag
- Two build jobs: `build-router-embed` and `build-hosted-web`
- Router embed artifact attached to release for firmware team consumption
- Hosted web artifact deployed to CDN automatically

---

## Phase 1 Scope

**Ship this. Nothing else.**

- [ ] Flutter Web app — customer mode (Flows 1, 2, 4, LibreSpeed, consent screen)
- [ ] Flutter Web app — support agent mode (all 6 flows, JNAP integration, raw data views)
- [ ] Router embed build artifact (`/www/troubleshoot/` bundle) for firmware team
- [ ] Hosted web deployment (customer mode only)
- [ ] LibreSpeed integration (self-hosted)
- [ ] JNAP auth flow (password → session-memory token)
- [ ] Crash telemetry (no PII)

**Phase 2:**
- RBAC (roles beyond admin)
- Background drop monitoring
- Report export / share with support
- Customer mode Flows 3, 5, 6
- Localization (Arabic, UK English)

---

## Decision Log

| Decision | Choice | Rationale |
|---|---|---|
| Delivery | Router embed (hidden URL) | No install; precedent exists (`/debug.html`, `/cpehelp.html`); LAN-local |
| Framework | Flutter Web | Router already ships Flutter Web (`privacy_gui`); team owns it; single build |
| Support agent access | JNAP auth (existing pattern) | `debug.html` already uses `X-JNAP-Authorization`; no new mechanism needed |
| Native app | Not building | Router embed covers all devices via browser; no install friction; app stores not needed |
| Backend | None | Session-local data; JNAP is router-local; no cloud needed for Phase 1 |
| Speed test | LibreSpeed (self-hosted) | Open source, no licensing, data stays in Linksys infrastructure |
| SMS / PWA / Tier 0 | Removed | Overcomplicated; router embed solves the zero-install problem for LAN-connected customers |
| Support agent — hosted web | Customer mode only | JNAP cannot be proxied without backend; no backend = agent mode stays router-only |
