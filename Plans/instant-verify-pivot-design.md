# Instant-Verify Pivot — Feature Design

**Version:** 2.0 (Loop 10: Customer-first redesign of Overview)
**Date:** 2026-04-06
**Status:** DRAFT — major audience clarification applied

---

## The Pivot

**Before:** "What's going on?" → customer picks a complaint → runs specific tests.
**After:** Take over `menuInstantVerify` inside authenticated PrivacyGUI. ALL tests run automatically on page load. Single headline verdict + actionable tips. Agent tabs for deep diagnostics.

**Key decision:** This is the admin UI instant-verify page, NOT the unauthenticated `/troubleshoot` route. All users are logged in. All JNAP calls available. Follow PrivacyGUI design system exactly.

---

## Audience Architecture (Loop 10 — CRITICAL CLARIFICATION)

The page serves two audiences but **Overview is CUSTOMER-FIRST**:

| Tab | Primary Audience | Design Goal |
|-----|-----------------|-------------|
| **Overview** | **End customer** (self-service) | Fix your own problem without calling support |
| Clients & Wireless | Technical customer / agent | WiFi quality analysis, per-device signal data |
| Network & Connectivity | Technical customer / agent | WAN, IP stack, DNS, routing details |
| Tools | Agent / Tier 2 | Restart, logs, Ookla speed test, sysinfo email |

**Customer self-service rule:** On the Overview tab, ONLY show a finding if:
1. There is a clear plain-language explanation the customer can understand, AND
2. There is an actionable fix — either auto-launchable by the UI, or a concrete instruction the customer can execute themselves

**If there is no fix → don't show it.** A customer seeing "DHCP utilization 87%" or "CPU: 62%" with no action to take is confusion, not help.

**Build order suggestion:** Build Overview-only first as a standalone deliverable. Prove the customer self-service model works. Then layer in the agent tabs.

---

## Design Principles

1. **One answer first** — headline verdict, not a dashboard of numbers
2. **Actions, not just findings** — every verdict includes what to do
3. **Progressive disclosure** — summary → detailed → raw data
4. **Device health, not just count** — good / at-risk / issues with color-coded scores
5. **Native to PrivacyGUI** — StyledAppPageView, AppCard, ResponsiveLayout, AppText, LinksysIcons
6. **Instant data, background tests** — JNAP data renders immediately from polling cache; browser speed tests run in background
7. **Graceful degradation** — every card handles missing data with "—" fallback, never crashes
8. **Density for agents** — minimize scrolling and tab-switching to find critical info

---

## Tab Structure

```
┌──────────────────────────────────────────────────────────────┐
│  StyledAppPageView: title = "Instant Verify"                 │
│  tabs: [Overview, Clients & Wireless, Network, Tools]        │
│  actions: [Refresh]                                          │
├──────────┬──────────────────┬─────────────┬──────────────────┤
│ Overview │ Clients &        │ Network &   │ Tools            │
│          │ Wireless         │ Connectivity│                  │
└──────────┴──────────────────┴─────────────┴──────────────────┘
```

Route config: `LinksysRouteConfig(column: ColumnGrid(column: 12), noNaviRail: false)`

---

## Tab 1: Overview (Customer Self-Service — Loop 10 Redesign)

**Purpose:** Run all diagnostics automatically. Surface ONLY actionable problems. Launch fixes. Guide the customer to resolution without calling support.

**Customer self-service rule (Loop 10):** Every finding shown on this page must have either:
- An **auto-fix** the UI can launch (restart router, trigger firmware update), OR
- A **concrete instruction** the customer can follow (move device, restart modem, call ISP with case number)

Technical metrics with no customer action (CPU%, memory%, DHCP pool usage, bottleneck type) are **not shown on Overview**. They appear in the agent tabs.

---

### Data Loading Strategy

**Two-phase loading** (unchanged from Loop 4, still valid for customer context):

| Phase | What loads | When visible | Time |
|-------|-----------|-------------|------|
| **Phase 1: Instant** | All JNAP data from polling cache | Immediately | <1s |
| **Phase 2: Background** | Browser speed tests (gateway, DNS, speed, throughput) | Cards update as tests complete | 20-30s |

Phase 1 gives the customer: WAN status, firmware status, device signal quality — enough to surface most actionable issues in under 1 second. Speed-related findings fill in during Phase 2.

---

### Actionable Findings Catalog (Updated — Loop 11 deliberation)

This is the **complete list** of findings the Overview page can show. Each entry has a fix path. Nothing outside this catalog appears on Overview.

**Critical addition (Loop 11):** WAN outage vs. LAN distinction is the highest-value finding — it stops unnecessary router restarts and is the #1 driver of support calls. Channel congestion and DNS failure also added per 4/5 model consensus.

| Finding | Condition | Fix Path | Auto-launchable? |
|---------|-----------|----------|-----------------|
| **Router can't be reached** | Gateway ping failed | "Try refreshing. If this persists, your router may need a restart." [Restart Now] | ✅ Restart |
| **Internet service appears down** | WAN disconnected AND gateway ping succeeds | "Your router is on, but your internet service isn't working. This is not a router problem — contact your internet provider." | ❌ ISP escalation — do NOT offer restart (doesn't help) |
| **Internet is not working** | WAN connected but DNS failed | "Your router can reach the internet but websites won't load. Try restarting your router first." [Restart Now] "If it continues, try restarting your modem." | ✅ Restart |
| **Internet is very slow** | Download < 5 Mbps | "Getting about X Mbps. Try restarting your router first." [Restart Now] "If still slow, restart your modem, then contact your internet provider." | ✅ Restart |
| **Internet is slower than expected** | Download 5-25 Mbps (or < 50% of plan if plan known) | "Getting about X Mbps. Restarting your router often helps with slowdowns." [Restart Now] | ✅ Restart |
| **High internet latency** | Ping > 100ms | "Your connection has high lag (X ms), which can cause delays in video calls and online games. Try restarting your modem." | ❌ Instruction only |
| **WiFi congestion on your channel** | Channel utilization high OR neighbor scan shows >6 networks on same channel | "Other nearby WiFi networks are on the same channel as yours, which can slow things down. Switching to a less crowded channel may help." [Switch Channel] | ✅ Auto-channel-switch via JNAP |
| **Weak WiFi — devices may be too far** | 1+ devices score < 40, signal < -75dBm | "These devices may be too far from your router: [device list]. Moving your router to a more central location could help." | ❌ Instruction only |
| **Weak WiFi — possible interference** | 1+ devices score < 40, signal OK but link rate low | "These devices have a weak WiFi connection even though they're nearby: [device list]. Check for thick walls, microwaves, or metal objects between them and your router." | ❌ Instruction only |
| **Firmware update available** | GetFirmwareUpdateStatus = update available | "A software update is available (v2.0.12). Updates improve performance and security." [Update Now — see safety notes below] | ✅ Trigger firmware update (with pre-flight) |
| **Router has been running a long time** | Uptime > 30 days | "Your router has been running for X days without a restart. A restart can clear up slowdowns." [Restart Now] | ✅ Restart |
| **Everything looks good** | No findings above triggered | "Your connection looks healthy — X checks passed. If you're still having trouble, use the help options below." | ✅ None needed |

**"Still having issues?" state (Loop 11 — critical UX gap):**
When "Everything looks good" but the customer still has a problem, the page cannot just be a dead end. Required:
- "Still having trouble?" section below the green state
- Offer: "Try restarting your router" [Restart Now] — the universal first step
- Offer: "Check which devices are affected" → link to Clients tab
- Offer: "Contact support" with a case # pre-filled if possible

**Hide from Overview (agent tabs only):**
- CPU%, memory%, DHCP pool usage
- Exact bottleneck classification (WAN vs WiFi vs Router)
- Port status, firewall config, MAC filtering
- Debug logs, sysinfo
- Raw ping/traceroute output
- Device MAC addresses
- Technical speed test metrics (gateway latency ms, DNS ms, router throughput Mbps)

---

### Layout (Desktop — 12-column grid)

```
┌─────────────────────────────────────────────────────────┐
│  ── Compact header (always visible) ──────────────────  │
│  Linksys M60 • Connected • FW: 2.0.11    [🔄 Refresh]  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────── Status Card (full width) ──────────┐  │
│  │                                                    │  │
│  │  🟡  Your internet is slower than expected         │  │
│  │                                                    │  │
│  │  Getting about 12 Mbps. Restarting your router    │  │
│  │  often fixes slowdowns.                            │  │
│  │                                                    │  │
│  │  ┌─────────────────────────┐                      │  │
│  │  │  🔄  Restart Router     │  ← primary action    │  │
│  │  └─────────────────────────┘                      │  │
│  │                                                    │  │
│  │  ─── Also found ──────────────────────────────   │  │
│  │  🟡  3 devices have weak WiFi (see below)         │  │
│  │  ℹ️  Software update available (v2.0.12)          │  │
│  │      [Update Now]                                  │  │
│  │                                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──── Devices with Issues ──────────────────────────┐  │
│  │  These devices have a weak WiFi connection:        │  │
│  │                                                    │  │
│  │  🔴 John's iPhone    2.4 GHz  Weak signal          │  │
│  │  🟡 Samsung TV        5 GHz   Moderate signal      │  │
│  │  🔴 Ring Doorbell     2.4 GHz Weak signal          │  │
│  │                                                    │  │
│  │  Try moving these devices closer to your router,  │  │
│  │  or move your router to a more central spot.      │  │
│  │                                                    │  │
│  │  [View All Devices ▸]  ← links to Clients tab    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  [🔄 Run Tests Again]                                    │
└─────────────────────────────────────────────────────────┘
```

**"Everything looks good" state:**
```
┌─────────────── Status Card ────────────────────────────┐
│                                                         │
│  ✅  Your connection looks healthy                      │
│      8 checks passed                                    │
│                                                         │
│  Internet speed, WiFi signal, and your router          │
│  all look normal.                                       │
│                                                         │
│  ─── Still having trouble? ────────────────────────   │
│  [🔄 Restart Router]  [View Device Details]            │
│  [Contact Support ▸]                                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Speed test running state:**
```
┌─────────────── Status Card ────────────────────────────┐
│                                                         │
│  ⏳  Checking your connection...                        │
│                                                         │
│  ████████░░░░░░░░░  Testing internet speed             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Mobile Layout

Same sections, stacked. Status card full width. Device issues card below. No horizontal scroll. Ping/traceroute moved to bottom sheet if needed. Header collapses to single line.

---

### Auto-Fix Flows

#### Restart Router
1. Customer taps [Restart Router]
2. Confirmation dialog: "This will restart your router. All devices will disconnect for about 2 minutes. Continue?"
3. On confirm: JNAP Reboot → "Router is restarting..." with countdown timer (120s)
4. At ~30s before reconnect: "Your router is almost back. Reconnect to your WiFi if needed."
5. Auto-refresh page after reconnect window

#### Firmware Update (with pre-flight — Loop 11)
Pre-flight checks required before showing [Update Now]:
- WAN connection must be stable (detected, not assumed)
- Warn: "Do not unplug your router during the update (~5 min). All devices will lose internet access."
- Disable [Restart Router] button while update is in progress
- If WAN is unstable: hide [Update Now], show "Update available — connect to stable internet to install"

Flow:
1. Customer taps [Update Now]
2. Pre-flight dialog: "This will install v2.0.12. Your router will restart and devices will disconnect for about 5 minutes. Make sure your router stays plugged in. Continue?"
3. On confirm: JNAP trigger firmware update → progress indicator
4. Page monitors update status; restart button disabled throughout

---

### Verdict Engine (Customer-Language)

**Plain language rules:**
- No "bottleneck", "throughput", "latency" — use "slow", "delay", "lag"
- No exact Mbps unless it adds meaning ("Getting 12 Mbps" is meaningful; "Router throughput: 180 Mbps" is not)
- No device scores, MAC addresses, or technical identifiers
- Device names = hostname (or "Unknown device [manufacturer]")

**Priority order (first match wins — same logic, customer language):**

```
CRITICAL (red):
  "Your router can't be reached"       → gateway ping failed
  "Your internet is not working"       → WAN down OR DNS failed
  "Your internet is very slow (X Mbps)"→ download < 5 Mbps

WARNING (orange):
  "Your internet is slower than expected" → download 5-25 Mbps (or < 50% of plan)
  "Your connection has high lag"          → latency > 100ms
  "X devices have weak WiFi"             → devices scoring < 40
  "Your router may need a restart"        → uptime > 30 days OR CPU > 80%

INFO (blue):
  "Software update available"             → firmware update pending

ALL CLEAR (green):
  "Your connection looks healthy"         → no findings triggered
```

**Causation in plain language:**
- Slow internet + weak devices → "Your internet is slow. Several devices also have weak WiFi, which could be making things worse."
- High latency → "High lag detected. This can cause problems in video calls and online games."

**Progressive loading:**
- Phase 1 (<1s): Can already show WAN-down, firmware update, device signal findings
- Phase 2 (20-30s): Speed findings fill in; verdict updates if speed tests change the picture
- Phase 1 verdict labeled "Checking speed..." if speed tests still running
- Transition animated (not a page reload)

### Device Connection Score (Signal + Link Rate Combo)

```dart
int connectionScore(DiagnosticClient client) {
  if (!client.isWireless) return 100; // Wired = perfect
  
  final signal = client.signalDecibels ?? -90;
  final txRate = client.txRateMbps ?? 0;
  
  // Signal component (0-50 points)
  // -30 dBm = 50pts, -65 = 35pts, -75 = 20pts, -85 = 5pts, -90+ = 0pts
  final signalScore = ((signal + 90) / 60 * 50).clamp(0, 50).toInt();
  
  // Link rate component (0-50 points)
  // 0 Mbps = 0pts, 100 = 15pts, 400 = 30pts, 866 = 45pts, 1200+ = 50pts
  final rateScore = (txRate / 1200 * 50).clamp(0, 50).toInt();
  
  return signalScore + rateScore;
}

// Buckets:
// Score >= 70 → Good (green)
// Score 40-69 → At Risk (orange)  
// Score < 40  → Issue (red)
```

### Test Result Cards

Each card is an AppCard with:
- Status icon: ✅ (green) / ⚠️ (orange) / ❌ (red) using `LinksysIcons.checkCircleFilled` / warning / error
- Test name: `AppText.labelMedium`
- Value + unit: `AppText.titleSmall`
- Loading state: shimmer or `Spinner()` during test execution

---

## Tab 2: Clients & Wireless

**Purpose:** Full device table + radio configuration + local speed test.

### Client Table (DataTable or custom)

| Column | Source | Notes |
|--------|--------|-------|
| Score | Computed | Color-coded circle (green/orange/red) + number |
| Device | hostname or OUI manufacturer | Bold if flagged |
| Band | 2.4/5/6 GHz or Wired | Color chip |
| Signal | dBm | Color-coded |
| TX Rate | Mbps | From JNAP |
| RX Rate | Mbps | From JNAP |
| IP | IPv4 address | |
| MAC | MAC address | Copyable |

Sort by score ascending (worst first) by default. Search/filter by name.

### Band Summary Row

```
2.4 GHz: 4 devices │ 5 GHz: 7 devices │ 6 GHz: 0 │ Wired: 1
```

### Radio Configuration (AppCard per radio)

Per radio (2.4 / 5 / 6 GHz):
- SSID, Security mode
- Channel (auto/selected), Channel width
- Band steering status
- Guest network: enabled/disabled, SSID

Source: JNAP GetRadioInfo, GetGuestNetworkSettings, GetSelectedChannels

### Mesh/Backhaul (if applicable)

From GetBackhaulInfo — show node connection type and quality.

### Local Network Speed Test

Button: "Test WiFi Speed to This Device"
- Runs browser-based router throughput test (existing `runRouterSpeedTest`)
- Shows: measured throughput vs client's TX link rate
- "Measured: 180 Mbps | Link Rate: 866 Mbps | Signal: -42 dBm"

---

## Tab 3: Network & Connectivity

**Purpose:** WAN, IP stack, DNS, firewall, ports, ping/traceroute, site latency.

### WAN Status (AppCard)

- Connection type (DHCP/Static/PPPoE)
- WAN IP (v4), Gateway, DNS 1/2/3
- WAN MAC, MTU
- IPv6: enabled/disabled, address if available (from GetIPv6Settings)

### Connectivity Tests (AppCard — auto-run results)

| Test | Target | Result | Latency |
|------|--------|--------|---------|
| Gateway ping | 192.168.1.1 | ✅/❌ | X ms |
| Internet (IPv4) | 8.8.8.8 | ✅/❌ | X ms |
| DNS resolution | 1.1.1.1 | ✅/❌ | X ms |
| Internet (IPv6) | 2001:4860:4860::8888 | ✅/❌ | X ms |

### Custom Ping (inline, not modal)

- IP/hostname input + Execute button
- Uses JNAP StartPing / GetPingStatus (reuse existing logic)
- Results displayed inline in scrollable text

### Custom Traceroute (inline)

- IP/hostname input + Execute button
- Uses JNAP StartTracroute / GetTracerouteStatus
- Results displayed inline as hop list

### Site Latency Tests (AppCard)

Pre-configured targets using JNAP StartPing:

| Target | IP/Host | Latency | Status |
|--------|---------|---------|--------|
| Google DNS | 8.8.8.8 | X ms | ✅/⚠️/❌ |
| Cloudflare | 1.1.1.1 | X ms | ✅/⚠️/❌ |
| Steam | (research needed) | X ms | ✅/⚠️/❌ |
| Xbox Live | (research needed) | X ms | ✅/⚠️/❌ |
| PlayStation | (research needed) | X ms | ✅/⚠️/❌ |
| Nintendo | (research needed) | X ms | ✅/⚠️/❌ |

Button: "Run Latency Tests" — pings all targets sequentially via JNAP.

Gaming DNS entries to be researched separately.

### Firewall & Security (AppCard)

- MAC filter: mode (Allow/Deny/Disabled) + entry count
- Security mode (from GetNetworkSecuritySettings)
- Parental controls: enabled/disabled
- Wireless schedule: enabled/disabled
- IPv6 firewall rules summary

### Port Status (AppCard)

From GetEthernetPortConnections:
- LAN 1-4: connected/disconnected, speed, connected device
- WAN: status, speed

---

## Tab 4: Tools

**Purpose:** Actions and exports for support workflow.

### Restart Router (AppCard)

- Button with confirmation dialog (use `showSimpleAppDialog`)
- "This will restart the router. All devices will disconnect for ~2 minutes. Continue?"
- Uses JNAP Reboot
- After trigger: "Router is restarting..." with auto-refresh timer

### Speed Test — Ookla (AppCard)

- Reuse existing `SpeedTestWidget` from instant_verify
- JNAP RunHealthCheck with SpeedTest module
- Shows animated meter gauge, download/upload/latency results
- More accurate than browser-based test

### Debug Logs (AppCard)

- "Download System Info" button
- JNAP GetSysinfoData
- Display in scrollable monospace text area
- Copy to clipboard button

### Email Report (AppCard)

- Email address input field + Send button
- JNAP SendSysinfoEmail
- Success/failure feedback
- "Sends full system diagnostic info to this email address"

### Diagnostic Report (AppCard)

- "Generate Support Report" button
- Plain-text report: all test results, router info, device list, findings
- Copy to clipboard
- Timestamp + router ID for ticket correlation

---

## Verdict Thresholds

| Metric | ✅ Good | ⚠️ Warning | ❌ Critical |
|--------|---------|------------|------------|
| Internet download | ≥ 25 Mbps | 5-25 Mbps | < 5 Mbps |
| Internet upload | ≥ 5 Mbps | 1-5 Mbps | < 1 Mbps |
| Internet latency | ≤ 50 ms | 50-100 ms | > 100 ms |
| Jitter | ≤ 10 ms | 10-30 ms | > 30 ms |
| Router throughput | ≥ 50 Mbps | 25-50 Mbps | < 25 Mbps |
| Gateway ping | ≤ 10 ms | 10-50 ms | Unreachable |
| CPU utilization | ≤ 60% | 60-80% | > 80% |
| Memory utilization | ≤ 70% | 70-85% | > 85% |
| Device score | ≥ 70 | 40-69 | < 40 |
| DHCP utilization | ≤ 70% | 70-90% | > 90% |
| Gaming latency | ≤ 50 ms | 50-100 ms | > 100 ms |

---

## Data Flow

```
Page Load (all authenticated)
    │
    ├─ Browser tests (parallel) ──────────────────
    │   ├─ Gateway ping
    │   ├─ DNS check
    │   ├─ Internet speed (Cloudflare)
    │   └─ Router throughput
    │
    ├─ JNAP calls (parallel via transaction) ─────
    │   ├─ GetDeviceInfo
    │   ├─ GetWANStatus
    │   ├─ GetSystemStats
    │   ├─ GetNodesWirelessNetworkConnections
    │   ├─ GetNetworkConnections
    │   ├─ GetDHCPClientLeases
    │   ├─ GetDevices (device names)
    │   ├─ GetRadioInfo
    │   ├─ GetGuestNetworkSettings
    │   ├─ GetFirmwareUpdateStatus
    │   ├─ GetBackhaulInfo
    │   ├─ GetMACFilterSettings
    │   ├─ GetNetworkSecuritySettings
    │   ├─ GetParentalControlSettings
    │   ├─ GetSelectedChannels
    │   ├─ GetEthernetPortConnections
    │   ├─ GetIPv6Settings
    │   └─ GetWirelessSchedulerSettings
    │
    ├─ Results → Verdict Engine → Summary Card
    ├─ Results → Device Score Engine → Device List
    └─ Results → Populate all 4 tabs
```

---

## PrivacyGUI Integration Patterns

### Page Container
```dart
StyledAppPageView(
  title: loc(context).instantVerify,
  scrollable: true,
  tabController: _tabController,
  tabs: [
    Tab(text: 'Overview'),
    Tab(text: 'Clients & Wireless'),
    Tab(text: 'Network'),
    Tab(text: 'Tools'),
  ],
  actions: [AnimatedRefreshContainer(...)],
  child: ...,
)
```

### Cards
```dart
AppCard(
  padding: EdgeInsets.all(Spacing.large2),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.titleSmall('Section Title'),
      AppGap.medium(),
      // Content
    ],
  ),
)
```

### Responsive Layout
```dart
ResponsiveLayout(
  desktop: IntrinsicHeight(
    child: Row(children: [
      SizedBox(width: 4.col, child: card1),
      AppGap.gutter(),
      SizedBox(width: 4.col, child: card2),
      AppGap.gutter(),
      SizedBox(width: 4.col, child: card3),
    ]),
  ),
  mobile: Column(children: [card1, AppGap.medium(), card2, ...]),
)
```

### Status Colors
```dart
final green = Theme.of(context).colorSchemeExt.green;
final error = Theme.of(context).colorScheme.error;
final warning = Colors.orange; // or colorSchemeExt equivalent
final inactive = Theme.of(context).colorScheme.surfaceVariant;
```

---

## Provider Architecture

### New provider: `instantVerifyPivotProvider`

Extends existing `cs_diagnostic_provider` pattern:
- Watches `pollingProvider` for JNAP data
- Manages browser diagnostic tests independently
- Computes: verdict, device scores, findings list
- Exposes: all state needed by all 4 tabs

### State model: `InstantVerifyPivotState`

Extends existing `CsDiagnosticState` with:
- Browser test results (gateway, DNS, speed, throughput)
- Computed verdict (priority, message, actions)
- Device scores (per-client score + bucket counts)
- Site latency results
- Ping/traceroute output

---

## Migration Plan

### Replace in PrivacyGUI:
- `instant_verify_view.dart` → new tabbed view
- `instant_verify_provider.dart` → new unified provider
- `instant_verify_state.dart` → new expanded state
- Keep `speed_test_widget.dart` (reuse in Tools tab)
- Keep `ping_network_modal.dart` logic (inline in Network tab)
- Keep `traceroute_modal.dart` logic (inline in Network tab)

### Reuse from cs_diagnostic:
- `browser_diagnostic_service.dart` — all browser tests
- `diagnostic_client.dart` — OUI lookup, signal analysis
- Device scoring logic (new)
- Verdict engine (new)

### New files to create:
- `views/instant_verify_pivot_view.dart` — main 4-tab page
- `views/overview_tab.dart` — summary/verdict/test cards
- `views/clients_wireless_tab.dart` — device table + radio config
- `views/network_tab.dart` — WAN/connectivity/firewall/ping/traceroute
- `views/tools_tab.dart` — restart/speedtest/logs/email/report
- `providers/instant_verify_pivot_provider.dart` — unified state
- `providers/instant_verify_pivot_state.dart` — state model
- `models/verdict.dart` — verdict engine
- `models/device_score.dart` — scoring model

---

## Graceful Degradation (from Loop 5)

Every card must handle missing data. No test failure should break the page.

| Scenario | Behavior |
|----------|----------|
| JNAP call fails | Card shows "—" for that metric, does not crash |
| Browser speed test timeout | Card shows "Test failed — check internet connection" |
| GetSystemStats unavailable | System Health card shows "CPU: —, Memory: —" |
| No wireless clients | Device summary shows "0 wireless devices" with wired count |
| Mesh nodes present | Device connections attributed to correct node |
| GetSysinfoData returns huge log | Show first 500 lines + "Load more" button |
| HealthCheck (Ookla) not supported | Tools tab hides Ookla section gracefully |
| IPv6 not enabled | IPv6 test shows "IPv6 not configured" (not an error) |
| Ping to gaming site unreachable | Show "Unreachable" with ❌, not an error state |

### Loading States

| State | Visual |
|-------|--------|
| JNAP data loading | Shimmer placeholders in all cards |
| JNAP loaded, tests running | Cards filled with JNAP data, speed test cards show Spinner |
| Individual test complete | Card fills in with result (animated transition) |
| All complete | Verdict card appears/updates with final assessment |
| Refresh triggered | Subtle loading indicator, existing data stays visible |

### Verdict Card Timing

- **Before any tests:** Verdict card shows "Running diagnostics..." with progress
- **After JNAP loads (Phase 1):** Verdict can already flag: CPU overloaded, devices with issues, firmware update, WAN down
- **After speed tests (Phase 2):** Verdict updates with speed/latency findings (may change priority)

This means the agent sees USEFUL information in <1 second, with the verdict refining over the next 20-30 seconds as speed tests complete.

---

## Iteration Log

| Loop | Lens | Key Changes |
|------|------|-------------|
| 1 | Initial design | 5-tab layout, dashboard of test cards |
| 2 | Customer simplification | Single verdict + action tips, reduced tabs |
| 3 | Agent efficiency | 4 tabs, inline ping/traceroute, gaming latency |
| 4 | Agent workflow | Two-phase loading, technical verdict language, "copy for ticket" button |
| 5 | Data availability | Graceful degradation for every card, loading states, Ookla feature check |
| 6 | Cognitive load | Router info → header, test cards collapsed, device summary → bucket chips |
| 7 | Multi-model deliberation | Headline + badge chips + expandable list; scoring engine as prerequisite; "wrong diagnosis?" feedback; causation hints in headline |
| 8 | UX critique (external) | Verdict marked "Preliminary" until speed tests done; top 2 findings always visible; device score as tooltip not primary; mobile → card list; missing interaction states flagged |
| 9 | Support Ops critique (external) | ISP plan speed is foundational; Call Context section (symptom + ticket#); two-language verdict (technical + customer script); CRM copy template defined; callback risk stays Low/Medium/High |
| 10 | Customer-first redesign | MAJOR: Overview = customer self-service only. Only show findings with fix paths. Auto-launch fixes (restart, firmware update). Remove technical jargon, CPU%, memory%, bottleneck analysis from Overview. Agent tools → other tabs. Plain-language verdict engine. Actionable findings catalog defined. |
| 11 | Multi-model deliberation (5 models, 2 rounds) | Confirmed: hold firm on actionable-only, no collapsed technical details on Overview. Added: WAN outage vs LAN distinction (highest-value missing finding), channel congestion with auto-switch, DNS failure with guided fix. Firmware update requires pre-flight (stable WAN, power warning, disable restart during update). "X checks passed" trust count added. "Still having issues?" escape hatch designed as first-class UX. |

---

## UX Critique Findings (Loop 8)

### HIGH — Verdict Bait-and-Switch
Phase 1 verdict must be visually marked "Preliminary" until speed tests complete. An agent who reads "Everything looks good" and tells the customer, then watches the verdict flip to "Internet very slow" 25 seconds later, looks incompetent and destroys trust in the tool.

- Phase 1 verdict: show with "Preliminary" badge and "Speed test in progress..." subtext
- If verdict priority changes on Phase 2: animated transition (border flash), not silent re-render
- If agent is on another tab when verdict changes: notification dot on Overview tab

### HIGH — Show Top 2 Findings Without Expansion
First-match-wins consistently surfaces symptoms over causes. CPU overload causes slow internet — but CPU shows as a warning, internet shows as critical, so headline = "Internet slow" and CPU is buried behind expand. Agents miss the root cause.

- Always show top 2 findings without requiring expansion
- Root cause promotion: if WARNING finding causally explains CRITICAL finding, surface it in headline body
- Expansion only needed for findings 3+

### MEDIUM — Device Score as Tooltip, Not Primary
"Score: 47" means nothing to Tier 1 agents. They understand color + label ("At Risk"). They understand signal bars. They do not know if 47 is almost-fine or almost-broken.

- Primary: color circle + label (Good / At Risk / Issue)
- Secondary: dBm value in smaller text, score as tooltip on hover
- Add device type heuristic: IoT on 2.4 GHz with low link rate is expected, not flagged

### HIGH — Missing Interaction States (to be spec'd before build)
The design is architecturally complete but interaction-incomplete. Before implementation:
- Every button: hover / active / disabled / confirmation / feedback states
- Empty states: zero clients, all tests pass, no mesh, first-load shimmer
- Error recovery: JNAP auth expiry mid-session, multiple calls fail, browser blocks speed test
- "Copy findings" needs one-click feedback (snackbar, not dialog)

### MEDIUM — Mobile: Table → Card List
DataTable with 8 columns on mobile = unusable nested scroll trap.
- Mobile client view: card per device (name, color, signal, band), tap to expand
- Persistent header: collapse to "M60 · 2.0.11 · WAN: Up" on mobile, tap to expand
- Ping/traceroute results on mobile: bottom sheet, not inline scroll

---

## Support Ops Critique Findings (Loop 9)

### CRITICAL — ISP Plan Speed is Foundational
"12 Mbps download" means nothing without knowing the customer's plan. An agent can't give a verdict without it. "Internet slow" on a 15 Mbps plan is acceptable. "Internet slow" on a 500 Mbps plan is a major incident.

**Add a "Call Context" card at the top of Overview:**
- Customer symptom (free text): "Netflix buffering in bedroom"
- ISP plan speed (input): "100 Mbps / 10 Mbps"
- Ticket / Case # (input): "CS-2024-xxxxx"
- These fields populate into the copied report template

**Verdict language changes when plan speed is entered:**
- Without: "Internet slow — 12 Mbps download"
- With: "Getting 12 of your 100 Mbps plan (88% below expected)"

### Two-Language Verdict
Agents do not read diagnostic output to customers verbatim. Design needs both:
- **Technical (always shown):** "Bottleneck: WAN. Router and WiFi healthy. Issue upstream."
- **Customer script (toggle):** "Your router and WiFi are fine. The slowdown is coming from your internet connection before it reaches your router. Let's try restarting your modem — unplug it for 30 seconds."

### CRM Copy Template (defined — implement this exactly)

```
== INSTANT VERIFY DIAGNOSTIC ==
Date: [timestamp]
Ticket: [from agent input]
Router: [Model] | SN: [serial] | FW: [version]
WAN: [type] | IP: [ip] | Uptime: [uptime]
Customer Plan Speed: [from agent input]

-- VERDICT --
[headline]
Bottleneck: [WAN / WiFi / Router / Unknown]
Download: [X] Mbps (expected ≥ [plan] Mbps)
Upload: [X] Mbps | Latency: [X] ms | Jitter: [X] ms

-- DEVICES --
Total: [N] | Wireless: [N] | Wired: [N]
Good: [N] | At Risk: [N] | Issue: [N]
Worst: "[device name]" ([dBm], [band], Score: [N])

-- ACTIONS TAKEN --
[x] Ran diagnostic suite
[ ] Restarted router
[ ] Restarted modem
[ ] Escalated to ISP

-- ADDITIONAL FINDINGS --
[finding 1]
[finding 2]

-- SYSTEM --
CPU: [N]% | Memory: [N]% | DHCP: [N]% pool used
Gateway: [N]ms | DNS: [N]ms | Router throughput: [N] Mbps
```

Key: plain text (not markdown), "Actions Taken" checkable before copying, ticket # at top.

### Tools Tab: Split Common / Advanced
**Common (Tier 1 agents use):** Restart router, Ookla speed test, firmware update trigger, generate/copy report
**Advanced (Tier 2 / engineers):** Debug logs (GetSysinfoData), email raw sysinfo

Add: Channel change (or deep link to radio settings), device rename, device disconnect.

### Callback Risk: Keep, Simplify
Show as Low / Medium / High badge on verdict card with one-line explanation.
Do NOT show a numeric score. "Callback Risk: HIGH — download well below plan speed, root cause unresolved" is actionable. "Risk: 73" is not.

Signals:
- Download < 50% of plan speed → High
- 3+ devices score < 40 → High
- CPU > 60% sustained → Medium
- Firmware update available, not applied → Medium
- Uptime < 24 hours → Medium
- No corrective actions taken during call → elevates by one tier

---

## Open Items (to research later)

- [ ] Gaming platform DNS entries (Steam, Xbox, PlayStation, Nintendo)
- [ ] GetSysinfoData response format — verify it's human-readable
- [ ] IPv6 ping feasibility via JNAP StartPing
- [ ] Firmware update JNAP trigger action (confirm which JNAP action)
- [ ] Network/technical accuracy audit (agent running — findings pending)
- [ ] Session localStorage for last 3 diagnostic snapshots (callback support)
