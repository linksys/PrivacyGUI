# USP Dashboard Feature Roadmap

> Date: 2026-03-06 | Updated: 2026-03-06 | Branch: `feat/usp-protocol-integration`
> Based on: Phase 1 Validation Report + Current Implementation Inventory

---

## Current State Summary

### Implemented Features (Phase 2A-2B + Phase 3)

| # | Feature | Cards / Pages | Mutations | Status |
|---|---------|---------------|-----------|--------|
| 1 | Device Info (SystemInfo) | DeviceInfoCard, SystemStatusCard | — | Read-only |
| 2 | Connected Devices | ConnectedDevicesCard (online/offline counts) | — | Read-only + WiFi/Mesh enrichment |
| 3 | WiFi Radio/AP/SSID | WifiStatusCard | toggleRadio, updateChannel | Read + Write |
| 4 | Time Settings | TimeSettingsCard | toggleNTP, updateNTPServers | Read + Write |
| 5 | DHCP Reservations | DhcpReservationsCard | toggle, add, update, delete | Full CRUD |
| 6 | DHCP Clients | (in DHCP detail page) | — | Read-only |
| 7 | Port Forwarding | PortForwardingCard + Detail Page | toggle, add, update, delete | Full CRUD |
| 8 | Port Triggering | (in Detail Page Tab 3) | toggle, add, update, delete + child CRUD | Full CRUD |
| 9 | Ethernet Interfaces | EthernetPortsCard | — | Read-only + device mapping |
| 10 | LAN Network Info | LanInfoCard (+ IPv6) | — | Read-only |
| 11 | WAN Status | NetworkStatusCard (+ IPv6, DHCP Renew) | renewWanLease | Read + Write |
| 12 | Mesh Topology | NetworkTopologyCard | — | Read-only |
| 13 | Admin (Password/Reboot) | (Admin page) | changePassword, reboot, factoryReset | Write |
| 14 | Safe Browsing | (Instant Safety page) | toggle OpenDNS | Write |
| 15 | CPU/Memory Monitoring | SystemMonitorCard (chart + timer) | — | Read-only + auto-refresh |
| 16 | System Logs | SystemLogView (Menu page) | — | Read-only (metadata) |

**Total: 17 YAML definitions, 18 .g.dart files, 15 dashboard cards, 22 mutation methods, 8 menu pages**

### Completed Feature Work (Phase 3)

| Feature | What was done | Date |
|---------|---------------|------|
| F-002: WAN DHCP Lease Renewal | "Renew Lease" button on NetworkStatusCard via OPERATE | 2026-03-06 |
| F-008: IPv6 Status Display | IPv6 addresses on WAN + LAN info cards, graceful fallback | 2026-03-06 |
| F-009: Device WiFi Quality Viz | `UspSignalStrengthIndicator` (4-bar widget), used in list tile, dashboard card, detail view | 2026-03-06 |
| F-010: Codegen Transforms | `Transforms.formatBytes()` for memory display in SystemStatusCard | 2026-03-06 |
| F-012: System Log Viewer | VendorLogFile metadata page (Menu entry); router doesn't support VendorLogFile data model — page shows empty/graceful state | 2026-03-06 |
| F-014: CPU/Memory Monitoring | SystemMonitorCard with CustomPainter chart, Timer.periodic, ring buffer (60 max), interval selector | 2026-03-06 |
| UI: Stats Panel | Online/Offline device counts, unified color scheme | 2026-03-06 |
| UI: Connected Devices Card | Header shows "X Online · Y Offline" with status dots | 2026-03-06 |

### Blocked Features (Phase 2C)

| Feature | Blocker |
|---------|---------|
| Ping/Traceroute OPERATE | BUG-003 (SSE) + BUG-004 (async OperateResp) |
| Subscribe (real-time) | BUG-003 (SSE not sending data) |
| Turbo Channel | BUG-003 (SSE transport) |

### Known Router Limitations

| Issue | Detail |
|-------|--------|
| VendorLogFile not supported | Router's USP agent (obuspa) does not implement `Device.DeviceInfo.VendorLogFile.{i}.` — syslog available via SSH (`logread`) but no HTTP/USP access |

---

## Tier 1: Low Cost, High Impact

These features leverage existing codegen infrastructure and require minimal new code.

### F-001: WiFi SSID / Password Management

**Priority:** P0
**Effort:** Small (1 dialog + 1 mutation)

- **Feasibility:** `Device.WiFi.AccessPoint.{i}.Security.KeyPassphrase` validated as SET-able on router
- **Current state:** `WiFiAccessPoints` codegen + `WifiAccessPointUIModel` exist, but only display security mode (no password edit)
- **Implementation:**
  - Add `keyPassphrase` field to `wi_fi_access_points.yaml` with `writable: true`
  - Re-run codegen → `WiFiAccessPointUpdate` gains `keyPassphrase`
  - New dialog: WiFi password edit (per AP or per SSID)
  - New mutation: `updateWifiPassword()` in notifier
- **Files:**
  - Modify: `wi_fi_access_points.yaml`, `usp_wifi_status_card.dart`, `usp_dashboard_notifier.dart`
  - New: `wifi_password_dialog.dart`

### F-002: WAN DHCP Lease Renewal

**Priority:** P0
**Effort:** Minimal (1 button + 1 operate call)

- **Feasibility:** `Device.DHCPv4.Client.{i}.Renew()` OPERATE verified successful on router
- **Current state:** NetworkStatusCard is read-only
- **Implementation:**
  - Add "Renew Lease" action button to `UspNetworkStatusCard`
  - Call `usp.operate('Device.DHCPv4.Client.1.Renew()')` → re-fetch WAN status
  - Also available: `Device.DHCPv6.Client.{i}.Renew()` for IPv6
- **Files:**
  - Modify: `usp_network_status_card.dart`, `usp_dashboard_notifier.dart`

### F-003: DHCP Pool Settings Edit

**Priority:** P0
**Effort:** Small (YAML expand + 1 dialog + 1 mutation)

- **Feasibility:** `LanNetworkInfo.dnsServers` already marked `writable`; `MinAddress`/`MaxAddress` paths verified
- **Current state:** LAN Info Card displays DHCP pool info read-only
- **Implementation:**
  - Expand `lan_network_info.yaml`: mark `minAddress`, `maxAddress`, `dhcpEnabled` as `writable`
  - Re-run codegen → `LanNetworkInfo.save()` gains new fields
  - New dialog: DHCP pool edit (IP range, DNS, enable toggle)
  - New mutation: `updateLanSettings()` in notifier
- **Files:**
  - Modify: `lan_network_info.yaml`, `usp_lan_info_card.dart`, `usp_dashboard_notifier.dart`
  - New: `lan_settings_dialog.dart`

### F-004: WiFi Channel Width Edit

**Priority:** P1
**Effort:** Small (YAML expand + dialog expand)

- **Feasibility:** `OperatingChannelBandwidth` available in `WiFiRadios` codegen
- **Current state:** WiFi Card can edit channel number and auto-channel, but not bandwidth
- **Implementation:**
  - Mark `operatingChannelBandwidth` as `writable` in `wi_fi_radios.yaml`
  - Re-run codegen → `WiFiRadioUpdate` gains `operatingChannelBandwidth`
  - Expand `wifi_channel_dialog.dart` to include bandwidth selector (20/40/80/160 MHz)
- **Files:**
  - Modify: `wi_fi_radios.yaml`, `wifi_channel_dialog.dart`, `usp_dashboard_notifier.dart`

---

## Tier 2: Medium Cost, New Features

### F-005: Firewall Settings Page

**Priority:** P1
**Effort:** Medium (1 YAML + 1 card + mutations)

- **Feasibility:** `Device.Firewall.Enable` GET/SET verified; `Device.Firewall.Level.{i}.` has 8 per-feature toggle entries
- **Limitation:** BUG-002 — top-level `Device.Firewall.` GET returns empty, must query sub-objects individually
- **Implementation:**
  - New YAML: `firewall/firewall_settings.yaml` (scatter-gather pattern, query Enable + Level.{i} separately)
  - New card or dedicated page: firewall master toggle + per-feature toggles
  - Mutations: toggle individual firewall features
- **TR-181 paths:**
  ```
  Device.Firewall.Enable              → master toggle
  Device.Firewall.Level.{i}.Name      → feature name
  Device.Firewall.Level.{i}.Chain     → associated chain reference
  ```
- **Note:** Workaround for BUG-002 — use explicit path list in scatter-gather pattern

### F-006: DMZ Configuration

**Priority:** P2
**Effort:** Medium (1 YAML + 1 card + 1 dialog)

- **Feasibility:** `Device.Firewall.DMZ.{i}.` schema registered; ADD available; currently empty (no DMZ configured)
- **Implementation:**
  - New YAML: `firewall/dmz.yaml` (multi-instance with add)
  - New card/section: DMZ enable + host IP input
  - Mutations: enable DMZ, set host IP, disable DMZ
- **TR-181 paths:**
  ```
  Device.Firewall.DMZ.{i}.Enable     → toggle
  Device.Firewall.DMZ.{i}.Host       → DMZ host IP
  ```

### F-007: Guest Network Management

**Priority:** P1
**Effort:** Medium (UI logic + 1 card + 1 dialog)

- **Feasibility:** BUG-001 fixed, WiFi SSID enumerates correctly. AP indices 3/4 are typically guest networks
- **Current state:** WiFi Status Card shows all radios/APs without distinguishing guest
- **Implementation:**
  - Guest AP identification logic (AP index-based or SSIDAdvertisementEnabled heuristic)
  - Dedicated guest network card: SSID name display, enable/disable toggle, password edit
  - Reuse existing `WiFiAccessPoints.update()` for mutations
- **Files:**
  - New: `usp_guest_network_card.dart`, `guest_network_dialog.dart`
  - Modify: `usp_device_service.dart` (guest AP identification), `usp_dashboard_notifier.dart`

### F-008: IPv6 Status Display

**Priority:** P2
**Effort:** Small-Medium (1 YAML + card expansion)

- **Feasibility:** `Device.IP.Interface.{i}.IPv6Address.*` verified readable
- **Implementation:**
  - New YAML: `network/ipv6_status.yaml` (scatter-gather from Interface.1 + Interface.2 IPv6 addresses)
  - Expand NetworkStatusCard and LanInfoCard to show IPv6 addresses when available
- **TR-181 paths:**
  ```
  Device.IP.Interface.1.IPv6Address.{i}.IPAddress    → LAN IPv6
  Device.IP.Interface.2.IPv6Address.{i}.IPAddress    → WAN IPv6
  Device.IP.Interface.{i}.IPv6Enable                 → IPv6 enabled state
  ```

### F-009: Device WiFi Quality Visualization

**Priority:** P1
**Effort:** Medium (UI only, no new codegen)

- **Feasibility:** `WifiClients` already fetched (signalStrength, noise, downlink/uplink rates); `DeviceUIModel` has `signalQuality` (0.0-1.0)
- **Current state:** Connected Devices Card shows text only, no signal visualization
- **Implementation:**
  - Signal strength bar/gauge in device list tiles
  - Device detail view: signal quality indicator + throughput display
  - Optional: WiFi vs Ethernet connection type icon
- **Files:**
  - Modify: device list tile, device detail view
  - Consider: Use `transforms.g.dart` `formatBandwidth()` / `formatSpeed()` for display

### F-010: Codegen Transforms Integration

**Priority:** P3 (Refactoring)
**Effort:** Small

- **Current state:** `transforms.g.dart` generated with `formatBandwidth`, `formatDuration`, `formatBytes`, `formatSpeed`, `formatPercent`, `cidrToNetmask` — all **unused**
- **Implementation:**
  - Replace hand-written format logic in UI models with codegen transform calls
  - Example: `SystemInfoUIModel.formattedUptime` → `Transforms.formatDuration(uptime)`
  - Example: `EthernetPortUIModel.speedLabel` → `Transforms.formatSpeed(currentBitRate)`
- **Files:**
  - Modify: various `*_ui_model.dart` files

---

## Tier 3: Higher Cost / External Dependencies

### F-011: Network Diagnostics (Ping / Traceroute)

**Priority:** P1
**Effort:** Large (new page + polling logic)
**Dependency:** BUG-003/BUG-004 blocks SSE-based result delivery

- **Feasibility:** `Device.IP.Diagnostics.IPPing()` verified (3/3 success, avg 6ms on router)
- **Alternative approach (no SSE):** Polling-based — OPERATE to start, then periodically GET result fields
  ```
  1. usp.operate('Device.IP.Diagnostics.IPPing()', args: {'Host': '8.8.8.8', 'NumberOfRepetitions': '4'})
  2. Poll: usp.get(['Device.IP.Diagnostics.IPPing.']) every 1s
  3. Read: DiagnosticsState, SuccessCount, FailureCount, AverageResponseTime, MinimumResponseTime, MaximumResponseTime
  4. Stop when DiagnosticsState == 'Complete'
  ```
- **Implementation:**
  - New page: diagnostics with Ping + Traceroute tabs
  - Polling timer for result collection
  - Menu entry: "Network Diagnostics"
- **TR-181 paths:**
  ```
  Device.IP.Diagnostics.IPPing()                    → OPERATE
  Device.IP.Diagnostics.IPPing.DiagnosticsState     → Complete/Error/Requested
  Device.IP.Diagnostics.IPPing.SuccessCount         → result
  Device.IP.Diagnostics.IPPing.AverageResponseTime  → result (ms)
  Device.IP.Diagnostics.TraceRoute()                → OPERATE
  Device.IP.Diagnostics.TraceRoute.RouteHops.{i}.*  → hop results
  ```

### F-012: System Log Viewer

**Priority:** P3
**Effort:** Medium-Large (new page)

- **Feasibility:** `Device.DeviceInfo.VendorLogFile.*` path exists (needs router verification for data volume)
- **Implementation:**
  - New YAML: `core/vendor_log.yaml`
  - New page: scrollable log viewer with search/filter
  - Consider pagination for large logs
- **Risk:** Log format and size unknown until tested

### F-013: Firmware Information / Dual Image Status

**Priority:** P3
**Effort:** Small-Medium

- **Feasibility:** `Device.DeviceInfo.FirmwareImage.*` provides current image info (active/inactive partitions)
- **Limitation:** No update availability check via TR-181 (Linksys proprietary)
- **Implementation:**
  - Expand `system_info.yaml` or new YAML for FirmwareImage data
  - Display in DeviceInfoCard: active image, boot partition, image dates
  - Optional: `Device.FirmwareImage.{i}.Activate()` for partition switch

### F-014: CPU / Memory Real-Time Monitoring

**Priority:** P1
**Effort:** Medium (UI chart + local history buffer)

- **Feasibility:** `cpuUsage`, `totalMemory`, `freeMemory` already fetched every refresh
- **Limitation:** No SSE/subscribe for push updates; relies on manual refresh or periodic polling
- **Implementation:**
  - Local history ring buffer (last N data points with timestamps)
  - Line chart in SystemStatusCard (CPU% and Memory% over time)
  - Optional: auto-refresh timer (configurable interval, e.g. 10s/30s/60s)
  - Persist history in-memory only (lost on page navigation)
- **Data available per refresh:**
  ```
  cpuUsage:    0-100 (integer percentage)
  totalMemory: KB (e.g., 1048576)
  freeMemory:  KB (e.g., 524288)
  uptime:      seconds since boot
  ```
- **Chart design:**
  ```
  ┌──────────────────────────────────────────────┐
  │  CPU & Memory Usage                    [⟳]  │
  │                                              │
  │  100% ┤                                      │
  │   80% ┤        ╭──╮                          │
  │   60% ┤   ╭────╯  ╰──╮     ╭──╮  ← CPU     │
  │   40% ┤───╯          ╰─────╯  ╰──           │
  │   20% ┤  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ← Memory │
  │    0% ┤────────────────────────────          │
  │       └──┬──┬──┬──┬──┬──┬──┬──┬──           │
  │         -8m -7m -6m -5m -4m -3m -2m -1m now │
  │                                              │
  │  CPU: 42%  Memory: 78% (384/512 MB)  ↑30s   │
  └──────────────────────────────────────────────┘
  ```
- **Auto-refresh options:**
  - No auto-refresh (manual only, current behavior)
  - Timer-based: `Timer.periodic` calling `ref.invalidate(uspDashboardProvider)` at chosen interval
  - Lightweight option: fetch only `SystemInfo` (not full 15-category refresh) for monitoring updates
- **Files:**
  - New: `usp_system_monitor_card.dart` (or expand `usp_system_status_card.dart`)
  - New: `system_monitor_history.dart` (ring buffer + data model)
  - Modify: `usp_dashboard_notifier.dart` (optional: lightweight SystemInfo-only refresh)
  - Modify: `usp_dashboard_view.dart` (add/replace card)

---

## Implementation Priority Matrix

```
                    High Impact
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    │  F-001 WiFi PW    │  F-011 Ping       │
    │  F-002 DHCP Renew │  F-014 Monitoring │
    │  F-003 DHCP Edit  │  F-007 Guest Net  │
    │                   │  F-005 Firewall   │
 Low├───────────────────┼───────────────────┤High
Cost│                   │                   │Cost
    │  F-004 CH Width   │  F-006 DMZ        │
    │  F-010 Transforms │  F-008 IPv6       │
    │                   │  F-012 Logs       │
    │                   │  F-013 Firmware   │
    │                   │  F-009 WiFi Viz   │
    └───────────────────┼───────────────────┘
                        │
                    Low Impact
```

## Recommended Execution Order

| Phase | Features | Rationale |
|-------|----------|-----------|
| **Next (3A)** | F-014 CPU/Memory Monitoring | User interest; data already available |
| **3A batch** | F-001 WiFi Password, F-002 DHCP Renew, F-003 DHCP Pool Edit | Low cost, high daily-use value |
| **3B** | F-005 Firewall, F-007 Guest Network | Important networking features |
| **3C** | F-011 Ping (polling approach), F-009 WiFi Quality Viz | Medium cost, high diagnostic value |
| **3D** | F-004 Channel Width, F-006 DMZ, F-008 IPv6 | Incremental enhancements |
| **Backlog** | F-010 Transforms, F-012 Logs, F-013 Firmware | Lower priority refinements |
