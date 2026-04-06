# CS Agent Diagnostic Tool — Feature Design
**Version:** 1.1
**Date:** 2026-03-30
**Status:** Design — MVP Scoped, Ready for Implementation

---

## Design Decisions (Read First)

Four key findings from multi-agent analysis that shape all implementation decisions:

### 1. Integration: Route Inside PrivacyGUI, Not a Sibling App
The `/www/` ROM partition on M60CF is at **100% capacity** (43.3MB full). A second Flutter Web bundle cannot ship without the firmware team explicitly carving out flash space. The implementation path is:

> Add `/troubleshoot` as a new Dart route inside the **existing PrivacyGUI Flutter app**.

No new flash budget. No service worker conflict. No separate build pipeline. The CS diagnostic feature is a new screen module in the existing codebase.

### 2. Authentication: Admin Password Direct (MVP) — Diagnostic PIN Post-MVP

**MVP decision:** The agent authenticates using the router admin password directly — the same `X-JNAP-Authorization: Basic admin:PASSWORD` pattern already used by `debug.html` today. No new firmware JNAP action required. No new auth mechanism.

> `/troubleshoot` shows a "Support Login" button. Agent (on the customer's device) enters the admin password. The app calls a lightweight JNAP action to validate credentials. On success: agent dashboard loads.

The admin password is used once, held in memory for the session only, never stored. This is the debug.html pattern — established precedent on this device.

**Why the PIN matters (Post-MVP):** Asking a customer to type their admin password at an agent's request trains a phishing behavior. The long-term fix — `StartDiagnosticSession` generating a temporary 6-digit read-only PIN — is designed and ready but is deferred until after the firmware team validates the MVP integration. **Post-MVP:** firmware adds `StartDiagnosticSession`, agent mode switches to PIN-based auth, admin password is no longer typed at agent request.

### 3. Speed Test: Dual Local + WAN Test
A WAN speed test alone cannot distinguish ISP slowness from router slowness. Both tests run in sequence:
1. **Local test** — device to router (over LAN) — measures WiFi/LAN throughput
2. **WAN test** — device to LibreSpeed server — measures internet throughput

If local is fast + WAN is slow → ISP. If both are slow → WiFi or router. This is required for verdict accuracy.

### 4. CS Agent Mode: Runs in Customer's Browser

The agent cannot reach `192.168.1.1` directly — they're not on the customer's network. The agent mode runs **in the customer's browser**, guided by the agent over the phone or chat.

MVP flow:
- Customer navigates to `/troubleshoot` (unauthenticated customer view)
- Agent asks customer to tap "Support Login"
- Customer enters admin password (agent guides them; password stays on their device)
- Agent dashboard loads in the customer's browser
- Agent reads data from the dashboard while talking to the customer

This is the same flow used for `debug.html` today. Post-MVP: replace admin password entry with a PIN the customer reads aloud, eliminating the credential-sharing step.

---

## Implementation Path

### Where the Code Lives

```
PrivacyGUI (existing Flutter app)
├── lib/
│   ├── ... (existing screens)
│   └── features/
│       └── diagnostics/          ← NEW MODULE
│           ├── diagnostic_router.dart
│           ├── services/
│           │   ├── jnap_diagnostic_service.dart   ← JNAP calls (Basic auth)
│           │   ├── speed_test_service.dart         ← LibreSpeed + local test
│           │   └── [diagnostic_pin_service.dart]   ← POST-MVP: PIN auth
│           ├── models/
│           │   ├── diagnostic_session.dart
│           │   ├── network_client.dart             ← per-device WiFi data
│           │   └── diagnostic_result.dart
│           └── screens/
│               ├── customer/
│               │   ├── customer_home.dart          ← unauthenticated landing
│               │   ├── flow_slow_internet.dart
│               │   ├── flow_slow_device.dart
│               │   └── flow_cant_connect.dart
│               └── agent/
│                   ├── agent_dashboard.dart        ← main agent view
│                   ├── signal_strength_table.dart  ← core agent tool
│                   ├── flow_connectivity_drops.dart
│                   ├── flow_dead_spots.dart
│                   └── flow_router_offline.dart
```

### Route Registration

Add to PrivacyGUI's existing router (go_router or Navigator):
```dart
GoRoute(
  path: '/troubleshoot',
  builder: (context, state) => const DiagnosticRouter(),
  routes: [
    GoRoute(path: 'agent', builder: (_, __) => const AgentDashboard()),
  ],
),
```

The lighttpd SPA rewrite rule already routes all paths to `index.html` — no lighttpd config change needed.

### New JNAP Actions Required — MVP

**Zero new firmware JNAP actions needed for MVP.** The app authenticates using `X-JNAP-Authorization: Basic admin:PASSWORD` — the same header `debug.html` uses today. All JNAP read actions called by the diagnostic tool already exist.

```
POST /JNAP/
X-JNAP-Action: http://linksys.com/jnap/core/GetDeviceInfo   ← used to validate credentials
X-JNAP-Authorization: Basic admin:PASSWORD                   ← standard JNAP auth
```

On login, the app calls `GetDeviceInfo` (or any authenticated JNAP action) to validate credentials. 200 OK → authenticated; 401 → wrong password. The admin password is held in Dart memory for the session only and used as the `Authorization` header for all subsequent JNAP calls in that session.

**Post-MVP (Diagnostic PIN):** Firmware adds `StartDiagnosticSession` → returns a short-lived read-only session token + 6-digit PIN. Customer reads PIN to agent. Admin password is never typed at agent request. Design is ready — deferred until MVP validates the integration.

---

## JNAP Data Layer

### Actions Called in Diagnostic Session (read-only)

| JNAP Action | Auth | Data Retrieved | Used In |
|---|---|---|---|
| `core/GetDeviceInfo` | Basic (admin pw) | Model, firmware version, services list — also used to validate login | All flows |
| `networkconnections/GetNetworkConnections2` | Basic (admin pw) | Per-client: MAC, IP, hostname, RSSI, band, TX/RX rates | Signal table, Flows 1–5 |
| `wirelessap/GetRadios` | Basic (admin pw) | Channel, width, band, SSID, security mode per radio | Flows 1, 3, 4 |
| `router/GetWANStatus` | Basic (admin pw) | WAN link state, IP, DNS, gateway, connection type | Flows 1, 6 |
| `router/GetLANSettings` | Basic (admin pw) | LAN IP, DHCP pool start/limit | Flow 4 |
| `dhcpd/GetDHCPReservations` | Basic (admin pw) | Active leases, expiry, pool utilization | Flow 4 |
| `router/GetRouterStatus` | Basic (admin pw) | Uptime, memory, firmware version | Flow 6, dashboard |

**All 7 JNAP actions already exist in firmware — zero new firmware JNAP work required for MVP.**

**Read-only usage contract (app-layer):** The diagnostic feature only calls read actions. State-modifying actions (`Reboot`, `SetWiFiSettings`, `SetAdminPassword`) are never called from this feature. Post-MVP, when `StartDiagnosticSession` is added, the firmware-layer read-only enforcement becomes the guardrail instead.

### JNAP Service (Dart)

```dart
class JnapDiagnosticService {
  final String _sessionToken;
  final String _baseUrl = 'http://192.168.1.1/JNAP/';

  Future<List<NetworkClient>> getConnectedClients() async { ... }
  Future<WanStatus> getWanStatus() async { ... }
  Future<List<RadioInfo>> getRadios() async { ... }
  Future<DhcpPool> getDhcpPool() async { ... }
  Future<RouterHealth> getRouterHealth() async { ... }
}
```

All responses are parsed into typed models. Raw JNAP response strings (device names, hostnames, SSIDs) are treated as untrusted input — HTML-escaped before display, never interpolated into DOM.

---

## CS Agent Dashboard

### Layout — 4 Layers

```
┌─────────────────────────────────────────────────┐
│  HEALTH BAR                                      │
│  🟢 WiFi  🟢 WAN  🟡 DHCP (87%)  🟢 Router     │ ← 2 seconds to read
├─────────────────────────────────────────────────┤
│  ⚠ ALERT BANNER (if any)                        │
│  "3 devices have signal below -75 dBm"          │ ← surface top issue
├─────────────────────────────────────────────────┤
│  COMPLAINT SELECTOR                              │
│  [Slow Internet] [Slow Device] [Drops]          │
│  [Can't Connect] [Dead Spots]  [Offline]        │ ← tap to filter data
├─────────────────────────────────────────────────┤
│  DETAIL VIEW (tabs: Devices | WiFi | WAN | Router│
│  ... filtered to the selected complaint          │
└─────────────────────────────────────────────────┘
```

### Health Bar Thresholds

| Indicator | Green | Yellow | Red |
|---|---|---|---|
| WiFi | All AP radios enabled | 1+ radio with ≥10 clients on 2.4GHz only | AP radio down |
| WAN | Connected, 0 errors | Connected, errorCount > 0 | Disconnected |
| DHCP | Pool < 70% utilized | 70–89% utilized | ≥ 90% utilized |
| Router | Uptime > 2h, mem > 20% free | Uptime < 2h OR mem 10–20% | Uptime < 10min OR mem < 10% |

### Alert Banner Logic (auto-surfaced, no complaint selection needed)

- **Uptime < 7,200s (2h):** "Router rebooted recently — check logs and firmware version"
- **DHCP pool ≥ 80%:** "DHCP pool is X% full — can't add new devices if it reaches 100%"
- **WAN status != Connected:** "WAN link is down — ISP or modem issue"
- **3+ clients RSSI < -75 dBm:** "Multiple devices with poor signal — coverage gap likely"
- **All/most clients on 2.4 GHz only:** "Possible band steering issue — 5/6 GHz underutilized"

---

## Signal Strength Table (Core Agent View)

The highest-value view for CS agents. Shows every connected device with actionable signal data.

### Columns

| Column | JNAP Source | Notes |
|---|---|---|
| Device Name | `hostname` | OUI-decoded if hostname is MAC-like (see Device Identity Decoder) |
| IP Address | `ipAddress` | LAN IP |
| Band | `bandType` | 2.4 GHz / 5 GHz / 6 GHz — color coded |
| Signal | `signalDecibels` | dBm value + color bar |
| Air Rate ↓ | `rxRateMbps` | Labeled "Air Rate" not "Speed" — prevents misinterpretation |
| Air Rate ↑ | `txRateMbps` | Same |
| ⚠ Flag | Computed | See flag logic below |

### Signal Color Coding (RSSI)

| Range | Color | Label | Agent Guidance |
|---|---|---|---|
| ≥ -65 dBm | 🟢 Green | Excellent | No action |
| -66 to -75 dBm | 🟡 Yellow | Fair | May degrade under load |
| -76 to -85 dBm | 🟠 Orange | Weak | Move device closer |
| < -85 dBm | 🔴 Red | Very Weak | Device likely experiencing drops |

### ⚠ Flag Logic

A device is automatically flagged (⚠ shown in red) if:
- RSSI < -75 dBm
- Band is 2.4 GHz AND a 5/6 GHz radio is active AND device RSSI would be adequate at 5 GHz (i.e., signal isn't so weak it's forced to 2.4)
- TX or RX rate < 10 Mbps (suggests severe congestion or interference at the radio level)

### Sortable / Filterable

- Default sort: flagged devices first, then by RSSI ascending (worst first)
- Filter: "Show 2.4 GHz only" / "Show weak signal" / "Show flagged"

---

## Per-Complaint Investigation Flows

### Flow 1: Slow Internet

**Agent checks (in order):**
1. **Health bar** — WAN green? If not → ISP/modem issue immediately
2. **WAN status** → confirm link is up, note DNS servers (ISP default vs. custom)
3. **Run dual speed test** (agent triggers from dashboard):
   - Local: device → router → result displayed
   - WAN: device → LibreSpeed → result displayed
   - If local fast + WAN slow → verdict: **ISP problem**, give ISP contact script
   - If both slow → check WiFi signal of device running test
4. **WiFi radio** → channel congestion indicators (channel 1/6/11 overlap on 2.4GHz)
5. **Device signal** → is the test device showing weak signal?

**Agent action options:**
- ISP verdict → provide ISP contact + screenshot of WAN speed result
- Router verdict → escalate or guide reboot
- WiFi verdict → channel change guidance (admin UI), move device closer

---

### Flow 2: Slow Device (Others Fine)

**Agent checks:**
1. **Signal table** → find the reported device, check RSSI and band
2. **Flag check** → is it flagged? Why? (weak signal vs. stuck on 2.4 GHz)
3. **Air rate** → TX/RX rate for that device vs. other devices
4. **Band** → if device is on 2.4 GHz and others are on 5 GHz → band steering issue or device incompatibility
5. **Compare** → is anyone else on same channel/band showing same pattern?

**Decision tree:**
- RSSI < -75 dBm → device too far, move or add mesh node
- RSSI OK, band 2.4 GHz only → device can't do 5 GHz or band steering failing
- RSSI OK, low air rate → local interference on that channel
- RSSI OK, air rate OK → device-side issue (driver, background process)

---

### Flow 3: Connectivity Drops

**Agent checks:**
1. **Router uptime** → < 2 hours? Router is rebooting — firmware or power issue
2. **WAN error count** → > 0? ISP line quality issue
3. **DHCP pool** → near full? Lease renewal failures cause apparent drops
4. **Device RSSI** → borderline signal (-70 to -80 dBm) causes intermittent drops as device roams between APs or loses marginal signal
5. **Radio channel** → 2.4 GHz channel congestion (neighbors on same channel) causes interference-driven drops

**Decision tree:**
- Uptime < 2h → guide reboot investigation, check firmware version
- WAN errors > 0 → ISP modem/line issue, bypass router to confirm
- DHCP > 80% → pool exhaustion causing non-renewal, guide DHCP limit change
- RSSI borderline → move device or router, enable mesh
- Channel congestion → auto-channel change guidance

---

### Flow 4: Can't Connect New Device

**Agent checks:**
1. **DHCP pool** → is it full (100%)? Device can connect to WiFi but can't get an IP → this is the issue
2. **WiFi radios** → what security mode? WPA3-only? Some devices can't connect
3. **Active SSIDs** → is 6 GHz band steering enabled? Old devices can't see 6 GHz SSID
4. **Device appears in connection table?** → if it appears with no IP → DHCP issue; if it doesn't appear → auth failure (wrong password, WPA mismatch)

**Decision tree:**
- Device in table, no IP → DHCP full or conflict
- Device not in table → wrong password or WPA3 incompatibility
- WPA3-only → guide to add WPA2/WPA3 mixed mode in admin UI
- 6 GHz-only band → guide to enable 2.4/5 GHz fallback SSID

---

### Flow 5: Dead Spots / Weak Signal

**Agent checks:**
1. **Signal table** → identify all devices with RSSI < -70 dBm
2. **Are they clustered?** (multiple devices with poor signal → coverage gap in that zone)
3. **Band distribution** → devices in weak zones tend to fall back to 2.4 GHz
4. **Single device** vs. **multiple devices** → single = device issue; multiple = coverage gap

**Agent action:**
- Coverage gap (multiple weak devices) → recommend router relocation or mesh node
- Single weak device → move device closer or switch band manually
- All devices in one room → identify physical obstruction pattern (concrete walls, appliances)

---

### Flow 6: Router Offline / Rebooting

**Agent checks (pre-JNAP — verbal, before tool loads):**
- Can customer see router admin page at all? If no → router not powered, hardware issue
- Are router lights on? What pattern?

**Agent checks (JNAP — if router responds):**
1. **Uptime** → very short (< 600s = < 10 minutes)? Router rebooted recently
2. **WAN status** → up or down? Confirms whether internet is the issue
3. **Router memory** → free memory < 10%? OOM-triggered reboot pattern
4. **Firmware version** → is it current? Older builds have known stability issues

**Decision tree:**
- WAN down, router up → ISP issue
- Uptime very short, WAN was up → router rebooted (power event, firmware crash)
- Memory < 10% → OOM issue, contact engineering with model + firmware
- All healthy → intermittent issue, can't confirm in session

---

## CS-Only Features (Beyond the 6 Flows)

### 1. Network Complexity Score

A single number (1–10) computed on load to help agents calibrate their approach before asking questions:

```
Score components:
+ 1 per 10 connected devices (max 4)
+ 2 if DHCP pool > 70%
+ 1 if 3+ unnamed/unknown devices
+ 1 if multiple radios with different security modes
+ 2 if uptime < 1 hour (unstable)
```

Display: "Network Complexity: 7/10 — This is a complex home network. Expect more nuanced issues."

A score ≥ 7 triggers a "this may need escalation" note in the agent UI.

---

### 2. Call-Back Risk Indicator

Predicts whether the customer is likely to call back within 7 days, based on session data:

| Signal | Risk Contribution |
|---|---|
| Router uptime < 48h | High |
| DHCP pool > 80% | Medium |
| 2+ flagged devices | Medium |
| WAN errorCount > 0 | High |
| Firmware not current | Medium |

If risk is High: UI shows "⚠ High Call-Back Risk" + auto-generates a CRM note the agent can copy:
> "Home network shows: uptime 1.2h, 3 devices RSSI < -75 dBm, DHCP pool 84%. Recommend follow-up in 48h if not resolved."

---

### 3. Device Identity Decoder

JNAP returns hostnames like `android-4f2a89bc` or MAC addresses like `A4:C3:F0:xx:xx:xx`. Agents waste 3–5 minutes per call asking "which device is yours?" This feature reduces it to 10 seconds:

- **MAC OUI lookup** (offline table bundled with app) → "Apple device", "Samsung device", "Nest device"
- **Hostname pattern matching** → `android-*` → Android, `iPhone` / `iPad` → iOS, `DESKTOP-*` → Windows PC
- **Combined label** → displayed as "Samsung Galaxy (likely)" or "Apple iPhone/iPad"

The customer is then asked one question: "Do you have a Samsung device on your WiFi?" rather than "Can you tell me every device on your network?"

---

## What Is NOT Built (Scope Boundary)

These will be requested. The answer is no:

| Request | Why Not |
|---|---|
| Historical graphs / trend data | No persistent storage — session data only. Adding storage = backend = major scope change |
| Standalone speed test tab | Wrong tool for CS context; creates confusion between air rate and internet speed |
| Packet capture | Privacy/liability; requires OS privileges not available in browser; out of scope permanently |
| "Reboot router" button | Modifying router state is not a diagnostic function; session token is read-only by design |
| Customer-facing data export / report | Phase 2. Requires decisions on data format, privacy, and potential backend |
| Parental controls / firewall / VPN status | Admin UI already shows this; duplicating it creates maintenance burden |

**The scope rule (written, enforced):**
> This tool surfaces read-only diagnostic state to answer: "Why is the customer's network not working right now?" Any feature that modifies router state or duplicates the admin UI is out of scope.

---

## Security Requirements

### Auth Model — MVP

```
Customer's browser (/troubleshoot):
  → Lands in unauthenticated customer mode (Flows 1, 2, 4 — browser APIs only)
  → Taps "Support Login" button
  → Admin password prompt appears with label:
    "Enter your router admin password to enable support diagnostics."
  → App calls: POST /JNAP/
                X-JNAP-Action: http://linksys.com/jnap/core/GetDeviceInfo
                X-JNAP-Authorization: Basic admin:[entered password]
  → 200 OK → admin password held in memory → agent dashboard loads
  → 401 → "Incorrect password — check your router admin password"
  → Password is never stored, never transmitted to any external server
```

This is the exact pattern used by `debug.html` on this device today. No new auth mechanism. No new firmware work.

**Post-MVP auth model (Diagnostic PIN):** Firmware adds `StartDiagnosticSession`. Customer taps "Get Support PIN" on unauthenticated screen → app calls `StartDiagnosticSession` with admin password → router returns 6-digit PIN + read-only session token → customer reads PIN to agent → agent mode loads in customer's browser using session token. Admin password is used once internally; customer never reads it aloud. Design is documented above in Section 2 — ready to implement after MVP validation.

### JNAP Call Safeguards

- All JNAP strings rendered as Flutter `Text()` widget only — never HTML interpolation
- Session token stored in `sessionStorage` (not `localStorage`) — cleared on tab close
- No JNAP write actions callable with diagnostic session token — enforced firmware-side
- Verify CORS policy on JNAP returns `Access-Control-Allow-Origin: http://192.168.1.1` before shipping

### Speed Test: ISP vs Router Attribution

Mandatory dual test sequence:

```
1. Local test: fetch timing against http://192.168.1.1/localtest_blob (served by router)
   → Measures: device ↔ router throughput (WiFi + LAN only)

2. WAN test: LibreSpeed against Linksys-hosted server
   → Measures: device ↔ internet throughput (WiFi + LAN + WAN + ISP)

Verdict logic:
  local fast (> 80% of theoretical max) + WAN slow  → ISP/modem issue
  local slow + WAN slow                             → WiFi or router issue
  local fast + WAN fast                             → no throughput issue (other cause)
  local test failed                                 → cannot reach router (serious connectivity)
```

The router needs to serve a static binary blob at `/localtest_blob` (lighttpd config: serve a pre-seeded file of known size for timing). This is a one-line lighttpd addition.

---

## LibreSpeed: Resilience Design

- Configure **3 LibreSpeed endpoints** in different regions/CDN zones
- Client tries them in order, falls back on timeout (5s per server)
- "Test server unreachable" is its own verdict: "We couldn't reach the speed test server — your internet connection may be down. Try connecting to a website to confirm."
- Never produce a speed verdict when the test server was unreachable

---

## Phase 1 Deliverables — MVP

| Deliverable | Owner | Notes |
|---|---|---|
| `/troubleshoot` Dart route in PrivacyGUI | Frontend team | Route in existing app — no new build artifact |
| Admin password login flow ("Support Login" button) | Frontend team | JNAP Basic auth — same as debug.html pattern |
| `JnapDiagnosticService` (Dart) with 7 JNAP calls | Frontend team | All 7 actions already exist in firmware |
| `SpeedTestService` — dual local + WAN | Frontend team | Requires /localtest_blob from firmware team |
| Customer mode: Flows 1, 2, 4 | Frontend team | Browser APIs only, no JNAP |
| Agent mode dashboard: health bar, alert banner, complaint selector | Frontend team | JNAP-powered |
| Signal strength table (9 columns, color coding, flag logic) | Frontend team | Core agent view |
| Agent flows: all 6 complaints | Frontend team | Flows 3, 5, 6 agent-only |
| CS-only features: Complexity Score, Call-Back Risk, Device Decoder | Frontend team | Post-MVP if timeline tight |
| `/localtest_blob` static endpoint in lighttpd | Firmware team | One lighttpd config line — serve a static blob |
| LibreSpeed server (3 endpoints, multi-region) | DevOps / Infrastructure | UAE + UK minimum |

**Firmware team ask for MVP: one deliverable** — `/localtest_blob`. No new JNAP actions. No auth changes. The diagnostic tool calls only existing JNAP read actions with existing Basic auth.

**Post-MVP firmware ask:** `StartDiagnosticSession` JNAP action + session token read-only scope enforcement.

---

## Roadmap Items

### MAC Address Device Lookup (Post-MVP)
For "Slow Device" and "Can't Connect" flows, add a MAC address input field where the agent can enter a specific device's MAC. The system then:
1. Checks the client table for that MAC's current connection status, signal, band, TX/RX
2. Searches router log files (via new JNAP action) for that MAC to find historical association/disassociation events, auth failures, DHCP issues
3. Returns a timeline of events for that device

**Requires:** New JNAP action to search syslogs by MAC (firmware team), or SSH-based log grep (not browser-compatible — native app only for Tier 3).

### Real Speed Test Integration (Phase 1.5)
Replace placeholder speed test with actual dual-test: local (device→router) + WAN (device→LibreSpeed). See Speed Test section above. Blocked on: `/localtest_blob` endpoint from firmware team, LibreSpeed server provisioning.

---

## Open Questions

| Question | Impact | Status |
|---|---|---|
| Does PrivacyGUI use go_router or Navigator 1.0? | Determines route registration code | Unresolved — 1 grep in PrivacyGUI repo answers this |
| Is `/localtest_blob` acceptable to firmware/lighttpd team? | Required for local speed test | Unresolved — low-risk ask (one config line) |
| What LibreSpeed server regions are needed? | Infrastructure decision | UAE + UK minimum assumed |
| What is the exact overlay space available for new Dart code? | Sets hard limit on feature set size | Unresolved — overlay has 76.9MB available, 640KB used; new Dart code unlikely to be the constraint |

`StartDiagnosticSession` feasibility is no longer a Phase 1 question — it is deferred to post-MVP by design.
