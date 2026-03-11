# USP Dashboard Feature Roadmap

> Date: 2026-03-06 | Updated: 2026-03-11 | Branch: `feat/usp-protocol-integration`
> Last feature: F-024 WiFi Performance Analytics (2026-03-11)
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
| 12 | Mesh Topology | NetworkTopologyCard (+ distance factor, coverage rings) | — | Read-only + RSSI viz |
| 13 | Admin (Password/Reboot) | Admin page (Menu) | changePassword, reboot, factoryReset | Write |
| 14 | Safe Browsing | Instant Safety page (Menu) | toggle OpenDNS | Write |
| 15 | CPU/Memory Monitoring | SystemStatusCard (merged gauge+chart, 30s auto) | — | Read-only + auto-refresh |
| 16 | System Logs | SystemLogView (Menu) | — | Read-only (metadata) |
| 17 | Firewall Settings | Firewall page (Menu) | toggle per-feature rules | Read + Write |
| 18 | DMZ Configuration | DMZ page (Menu) | enable, add, update, delete | Full CRUD |
| 19 | Firmware Dual Image | DeviceInfoCard (Active/Boot badge) | — | Read-only |
| 20 | Local Network Settings | Local Network page (Menu) | save (IP, DHCP, hostname) | Read + Write (dirty guard) |
| 21 | Static Routing | Static Routing page (Menu) | add, update, toggle, delete | Full CRUD |
| 22 | IPv6 Port Service | IPv6 Port Service page (Menu + Firewall link) | add, update, toggle, delete | Full CRUD |
| 23 | Multi-IF Traffic Analysis | TrafficAnalysisCard (4 tabs: Monitor, Comparison, Distribution, Trends) | — | Read-only + polling |
| 24 | Device Connection Analytics | DeviceAnalyticsCard (4 tabs: Distribution, Trend, Activity, Signal) | — | Read-only + persistence |
| 25 | Network Health Monitoring | NetworkHealthCard (3 tabs: Health, Errors, Loss) | — | Read-only (shared traffic timer) |
| 26 | Firewall Config Overview | FirewallOverviewCard (2 tabs: Rules, Ports) | — | Read-only (static config viz) |
| 27 | WiFi Performance Analytics | WifiPerformanceCard (3 tabs: Signal, Speed, Channels) | — | Read-only (per-client metrics) |

**Total: 24 YAML definitions, 24 .g.dart files, 19 dashboard cards, 12 menu pages, 30+ mutation methods**

### Infrastructure

| Feature | Description | Status |
|---------|-------------|--------|
| 401 Auth Retry | Auto reauth on token expiry — two-stage (refreshToken → re-login), Completer lock, transparent to notifiers | Active |

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
| F-013: Firmware Dual Image | FirmwareImages codegen + DeviceInfoCard dual image section (Active/Boot badge), graceful fallback | 2026-03-09 |
| F-005: Firewall Settings Page | Standalone firewall page with chain rules toggle (Menu entry) | 2026-03-09 |
| F-006: DMZ Configuration | Standalone DMZ page — enable/disable, dest IP, source CIDR, add/update/delete multi-instance | 2026-03-09 |
| UI: System Status + Monitor Merge | Merged two cards into one; gauge synced with chart data; 30s default auto-refresh; removed sample count | 2026-03-09 |
| Bugfix: YAML format migration | Fixed 7 YAML definitions from old `base_path` format to modern `instance:`/`multiInstance:` | 2026-03-09 |
| Bugfix: LAN port detection | Fixed Layer1Interface mismatch → fallback to `port.status` + non-WiFi device assignment | 2026-03-09 |
| F-016: Local Network Settings | Standalone page — router IP, subnet mask (prefix-locked octets), hostname, DHCP server (enable, pool start/end, lease time, DNS), dirty guard + cascade validation | 2026-03-10 |
| F-003: DHCP Pool Edit | Subsumed by F-016 — DHCP pool settings integrated into Local Network page | 2026-03-10 |
| F-015: Static Routing | Standalone page — route CRUD (add/edit/toggle/delete), Origin filter (Static only), interface mapping (LAN/Internet). No NAT/RIP (RIP unsupported, NAT per-interface) | 2026-03-10 |
| F-017: IPv6 Port Service | Standalone page — IPv6 inbound port rules CRUD (add/edit/toggle/delete), IANA protocol mapping (TCP/UDP/Both), CreationDate-based system rule filtering, Menu + Firewall page link | 2026-03-10 |
| Infra: 401 Auth Retry | `UspService._withAuthRetry()` wraps all 11 CRUD methods + `UspBridgeClient` REST/SSE endpoints. Two-stage reauth (refreshToken → restoreSession), Completer lock for concurrent 401s. `UspAuthCoordinator` registers callback | 2026-03-10 |
| F-018: Real-Time Traffic Monitor | WAN traffic polling (2s default), delta-based rate calc, ring buffer (60 max), dual-line CustomPainter chart (upload/download), interval selector (Off/2s/5s/10s), cumulative totals. Daily/monthly stats deferred to F-025 | 2026-03-10 |
| F-019: Multi-Interface Traffic Analysis | Unified 4-tab traffic card (Monitor: `AppLineChart` dual-line + gradient, Comparison: `AppBarChart` stacked WAN vs LAN, Distribution: `AppPieChart` donut + per-IF breakdown bars, Trends: dual-axis CustomPainter bytes/packets). WAN+LAN delta-based rate calc, `MultiInterfaceSnapshot` model, 60-point ring buffer, interval selector | 2026-03-11 |
| F-020: Device Connection Analytics | 4-tab analytics card (Distribution: `AppPieChart` donut WiFi/Wired + band bars, Trend: `AppBarChart` stacked 24h hourly, Activity: `AppHeatmapChart` 12 devices × 24h, Signal: `AppRadarChart` / `AppBarChart` fallback per-band quality). `DeviceAnalyticsState` with hourly persistence, `HourlyAggregate` MAC tracking, `WifiClients` enricher with fallback fetch | 2026-03-11 |
| UI: Topology Enhancement | `MeshLink.distanceFactor` (RSSI → 0.0–1.0 visual distance), `MeshNode.coverageRings` (Gateway 2 rings, Extender 2 rings), node spacing 1.4× multiplier, auto-expand for <8 clients | 2026-03-11 |
| UI: UI Kit Chart Migration | Migrated all dashboard charts from CustomPainter to UI Kit library (`AppLineChart`, `AppBarChart`, `AppPieChart`, `AppRadarChart`, `AppHeatmapChart`). Discovered `AppBarChart` horizontal mode RotatedBox rendering bug — workaround: use vertical mode | 2026-03-11 |
| Bugfix: WiFi Client Enricher | Added fallback fetch for `WifiClients` — if selective-get nested wildcards return empty, falls back to parent-path `Device.WiFi.AccessPoint.*.AssociatedDevice.` with manual parse | 2026-03-11 |
| F-022: Network Health Monitoring | 3-tab card (Health gauge + WAN/LAN traffic lights, Errors area chart, Packet Loss line chart). Composite health score (0-100) from packet loss + error/discard rates. Shares polling timer with `uspTrafficAnalysisProvider` — no separate fetch. Files: `network_health_helpers.dart` + `usp_network_health_card.dart` | 2026-03-11 |
| F-023: Firewall Config Overview | 2-tab card (Rules: target distribution `AppPieChart` donut + active rule count; Ports: top-5 port forwarding list + DMZ entries + protocol distribution `AppBarChart`). Descoped from "Activity Visualization" — TR-181 `FirewallChainRule` has no hit count/timestamp/event log. Extended `UspDashboardState` with `FirewallChainRules` + `Dmz` raw data. Files: `usp_firewall_overview_card.dart` | 2026-03-11 |
| F-024: WiFi Performance Analytics | 3-tab card (Signal: per-client RSSI `AppBarChart` with tier coloring, Speed: DL/UL grouped `AppBarChart` per client, Channels: per-radio info + band distribution `AppPieChart` donut). Uses `WifiClient` signal/noise/speed + `connectionDetailMap` for AP→Radio band mapping. Files: `wifi_performance_helpers.dart` + `usp_wifi_performance_card.dart` | 2026-03-11 |
| Bugfix: SliverDashboard crash | Fixed "Unexpected null value" at `sliver_dashboard.dart:621` — removed `optimizeLayout()` calls that mutated DashboardController after widget tree was built. Added stale layout validation (saved 15-item layout vs new 17-item spec). Files: `usp_layout_controller.dart` | 2026-03-11 |

### Blocked Features (Phase 2C)

| Feature | Blocker |
|---------|---------|
| Ping/Traceroute OPERATE | BUG-003 (SSE) + BUG-004 (async OperateResp) — polling alternative available |
| Subscribe (real-time) | BUG-005 (bridge doesn't forward OBUSPA Notify → SSE) |
| Turbo Channel | BUG-003 (SSE transport) |

### Known Router Limitations

| Issue | Detail |
|-------|--------|
| VendorLogFile not supported | Router's USP agent (obuspa) does not implement `Device.DeviceInfo.VendorLogFile.{i}.` — syslog available via SSH (`logread`) but no HTTP/USP access |

---

## Pending Features

### F-001: WiFi SSID / Password Management

**Priority:** P0 | **Effort:** Small | **Status:** Not started

- **Feasibility:** `Device.WiFi.AccessPoint.{i}.Security.KeyPassphrase` validated as SET-able on router
- **Current state:** `WiFiAccessPoints` codegen + `WifiAccessPointUIModel` exist, but only display security mode (no password edit)
- **Implementation:**
  - Add `keyPassphrase` field to `wi_fi_access_points.yaml` with `writable: true`
  - Re-run codegen → `WiFiAccessPointUpdate` gains `keyPassphrase`
  - New dialog: WiFi password edit (per AP or per SSID)
  - New mutation: `updateWifiPassword()` in notifier

### F-004: WiFi Channel Width Edit

**Priority:** P1 | **Effort:** Small | **Status:** Not started

- **Feasibility:** `OperatingChannelBandwidth` available in `WiFiRadios` codegen
- **Implementation:**
  - Mark `operatingChannelBandwidth` as `writable` in `wi_fi_radios.yaml`
  - Expand `wifi_channel_dialog.dart` to include bandwidth selector (20/40/80/160 MHz)

### F-007: Guest Network Management

**Priority:** P1 | **Effort:** Medium | **Status:** Not started

- **Feasibility:** BUG-001 fixed, WiFi SSID enumerates correctly. AP indices 3/4 are typically guest networks
- **Implementation:**
  - Guest AP identification logic (AP index-based or SSIDAdvertisementEnabled heuristic)
  - Dedicated guest network card: SSID name display, enable/disable toggle, password edit

### F-011: Network Diagnostics (Ping / Traceroute)

**Priority:** P1 | **Effort:** Large | **Status:** Not started

- **Feasibility:** `Device.IP.Diagnostics.IPPing()` verified (3/3 success, avg 6ms on router)
- **Approach:** Polling-based (no SSE dependency)
  ```
  1. usp.operate('Device.IP.Diagnostics.IPPing()', args: {'Host': '...', ...})
  2. Poll: usp.get(['Device.IP.Diagnostics.IPPing.']) every 1s
  3. Stop when DiagnosticsState == 'Complete'
  ```
- **TR-181 paths:**
  ```
  Device.IP.Diagnostics.IPPing()                    → OPERATE
  Device.IP.Diagnostics.IPPing.DiagnosticsState     → Complete/Error/Requested
  Device.IP.Diagnostics.IPPing.AverageResponseTime  → result (ms)
  Device.IP.Diagnostics.TraceRoute()                → OPERATE
  Device.IP.Diagnostics.TraceRoute.RouteHops.{i}.*  → hop results
  ```

### ~~F-018: Real-Time Traffic Monitor~~ ✅ Done — 2026-03-10

**Priority:** P0 | **Effort:** Medium | **Status:** ✅ Done

- **Implemented:** WAN traffic polling (2s default), delta-based rate calculation, ring buffer (60 max), dual-line CustomPainter chart (upload/download), interval selector (Off/2s/5s/10s), cumulative totals
- **Deferred to F-025:** Daily/monthly cumulative statistics, Hive data persistence for historical tracking
- **Files:** `wan_traffic_stats.yaml` → codegen → `traffic_monitor_state.dart` + `usp_traffic_monitor_notifier.dart` + `usp_traffic_monitor_card.dart`
- **Future enhancement:** When BUG-005 (Subscribe) is fixed, migrate to ValueChange notifications for sub-second updates

---

## Advanced Chart & Analytics Features

### ~~F-019: Multi-Interface Traffic Analysis~~ ✅ Done — 2026-03-11

**Priority:** P1 | **Effort:** Medium | **Status:** ✅ Done

- **Implemented:** Unified 4-tab traffic card extending F-018:
  - **Monitor:** `AppLineChart` dual-line (upload/download) with gradient fill, speed tiles
  - **Comparison:** `AppBarChart` stacked WAN vs LAN rate comparison over time
  - **Distribution:** `AppPieChart` donut with cumulative WAN/LAN proportion + per-interface breakdown bars
  - **Trends:** Dual-axis CustomPainter (solid: Bytes/s, dashed: Packets/s)
- **Data model:** `TrafficInterface` enum (wan/lan), `MultiInterfaceSnapshot`, 60-point ring buffer, delta-based rate calc
- **Files:** `traffic_analysis_state.dart` + `usp_traffic_analysis_notifier.dart` + `usp_traffic_analysis_card.dart`

### ~~F-020: Device Connection Analytics~~ ✅ Done — 2026-03-11

**Priority:** P1 | **Effort:** Medium | **Status:** ✅ Done

- **Implemented:** 4-tab analytics card:
  - **Distribution:** `AppPieChart` donut (WiFi vs Wired) + band breakdown bars
  - **Trend:** `AppBarChart` stacked 24h hourly device count
  - **Activity:** `AppHeatmapChart` (12 devices × 24h per-device activity matrix)
  - **Signal:** `AppRadarChart` (≥3 bands) or `AppBarChart` fallback per-band quality %
- **Data model:** `DeviceDistribution`, `HourlyAggregate` with MAC tracking, `DeviceAnalyticsState` with SharedPreferences persistence
- **Enrichment:** `WifiClients` enricher with nested-wildcard selective-get + parent-path fallback
- **Files:** `device_analytics_state.dart` + `device_analytics_persistence.dart` + `usp_device_analytics_notifier.dart` + `usp_device_analytics_card.dart`
- **Known issue:** `AppBarChart(horizontal: true)` RotatedBox rendering bug — workaround: vertical bar chart for Signal tab

### F-021: System Performance Dashboard

**Priority:** P1 | **Effort:** Small | **Status:** Not started

- **USP Verification:** ✅ Verified — system metrics fully available (from existing implementation)
- **Verified data sources:**
  ```bash
  Device.DeviceInfo.ProcessStatus.CPUUsage   → CPU percentage ✅
  Device.DeviceInfo.MemoryStatus.Total/Free  → Memory usage ✅
  Device.DeviceInfo.UpTime                   → System uptime ✅
  ```
- **Chart types:**
  - **Multi-gauge dashboard:** CPU, Memory, Temperature (if available)
  - **Time series:** Resource usage trends (extend existing SystemStatusCard)
  - **Correlation chart:** Traffic peaks vs CPU usage relationship
- **Implementation:** Enhance existing `UspSystemMonitorNotifier` with multiple chart types

### ~~F-022: Network Health Monitoring~~ ✅ Done — 2026-03-11

**Priority:** P2 | **Effort:** Medium | **Status:** ✅ Done

- **Implemented:** 3-tab card sharing `uspTrafficAnalysisProvider` (no separate poll):
  - **Health:** Composite score gauge (0-100) + WAN/LAN traffic light indicators + error/discard/loss summary
  - **Errors:** Error/discard rate `AppLineChart` area chart over time
  - **Loss:** Packet loss % `AppLineChart` over time
- **Data model:** `HealthTier` enum (excellent/good/fair/critical), `NetworkHealthHelpers` with score computation from packet loss + error/discard rates
- **Files:** `network_health_helpers.dart` + `usp_network_health_card.dart`

### ~~F-023: Firewall Configuration Overview~~ ✅ Done — 2026-03-11

**Priority:** P2 | **Effort:** Medium | **Status:** ✅ Done

- **Descoped from "Activity Visualization":** TR-181 `FirewallChainRule` has no hit count, timestamp, or event log — activity timeline / rule effectiveness charts not feasible
- **Implemented:** 2-tab Firewall Configuration Overview card:
  - **Rules:** Target distribution `AppPieChart` donut (Accept/Drop/Reject) + active/total rule count + port forward + DMZ stats
  - **Ports:** Top-5 port forwarding rules with protocol badge + external→internal mapping + DMZ section + protocol distribution `AppBarChart`
- **Dashboard state extension:** Added `FirewallChainRules` + `Dmz` raw data fields to `UspDashboardState`, fetched in `_fetchAll()`
- **Files:** `usp_firewall_overview_card.dart` (new), `usp_dashboard_state.dart` (extended), `usp_dashboard_notifier.dart` (extended)

### ~~F-024: WiFi Performance Analytics~~ ✅ Done — 2026-03-11

**Priority:** P2 | **Effort:** Medium | **Status:** ✅ Done

- **Implemented:** 3-tab card using existing `uspDashboardProvider` + `uspDeviceAnalyticsProvider`:
  - **Signal:** Per-client RSSI `AppBarChart` with tier coloring (Excellent ≥-50, Good ≥-60, Fair ≥-70, Weak <-70 dBm)
  - **Speed:** Per-client DL/UL grouped `AppBarChart` (kbps → Mbps/Gbps auto-format)
  - **Channels:** Per-radio info (band + channel + bandwidth + client count) + band distribution `AppPieChart` donut
- **Data sources:** `WifiClient.signalStrength/noise/lastDataDownlinkRate/lastDataUplinkRate`, `connectionDetailMap[mac].band` for AP→Radio mapping, `WifiRadioUIModel` for channel info
- **Files:** `wifi_performance_helpers.dart` + `usp_wifi_performance_card.dart`
- **Resolved:** AP-level stats (fault 9005) bypassed — uses per-client `AssociatedDevice` data instead of AP Stats

### F-025: Historical Trend Analysis

**Priority:** P2 | **Effort:** Large | **Status:** Not started

- **USP Verification:** ⚠️ Data collection required — no built-in historical storage in TR-181
- **Data approach:** Client-side data collection and storage
- **Chart types:**
  - **Weekly/monthly trend charts:** Traffic, device count, error rate changes
  - **Seasonal analysis:** Usage pattern identification
  - **Comparison charts:** Current month vs previous month performance
- **Implementation:**
  - Hive-based local storage for historical data
  - Background data collection service
  - Statistical analysis algorithms
- **Note:** Requires long-term data collection — no immediate USP source

---

## Implementation Priority Matrix

```
                    High Impact
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    │  F-001 WiFi PW    │ F-018 ✅ Done     │
    │  F-021 Sys Perf   │ F-019 ✅ Done     │
    │                   │  F-011 Ping       │
    │                   │  F-007 Guest Net  │
 Low├───────────────────┼───────────────────┤High
Cost│                   │                   │Cost
    │  F-004 CH Width   │ F-020 ✅ Done     │
    │  F-022 ✅ Done    │  F-023 ✅ Done   │
    │                   │  F-024 ✅ Done   │
    │                   │  F-025 Historical │
    └───────────────────┼───────────────────┘
                        │
                    Low Impact
```

## Recommended Execution Order

| Phase | Features | Rationale |
|-------|----------|-----------|
| ~~**4A**~~ | ~~F-016 Local Network Settings~~ | ~~Done~~ ✅ 2026-03-10 |
| ~~**4A**~~ | ~~F-015 Static Routing~~ | ~~Done~~ ✅ 2026-03-10 |
| ~~**4A**~~ | ~~F-003 DHCP Pool Edit~~ | ~~Subsumed by F-016~~ ✅ |
| ~~**4A**~~ | ~~F-017 IPv6 Port Service~~ | ~~Done~~ ✅ 2026-03-10 |
| ~~**4A**~~ | ~~401 Auth Retry~~ | ~~Done~~ ✅ 2026-03-10 |
| ~~**4B**~~ | ~~F-018 Real-Time Traffic Monitor~~ | ~~Done~~ ✅ 2026-03-10 (daily/monthly stats → F-025) |
| **4B** | F-021 System Performance Dashboard | **✅ USP Verified** — Extend existing SystemStatusCard |
| **4B** | F-001 WiFi Password, F-004 Channel Width | **✅ USP Verified** — Low cost daily-use WiFi management |
| ~~**4C**~~ | ~~F-019 Multi-Interface Traffic Analysis~~ | ~~Done~~ ✅ 2026-03-11 |
| ~~**4C**~~ | ~~F-020 Device Connection Analytics~~ | ~~Done~~ ✅ 2026-03-11 |
| ~~**4C**~~ | ~~F-022 Network Health Monitoring~~ | ~~Done~~ ✅ 2026-03-11 |
| ~~**4D**~~ | ~~F-023 Firewall Configuration Overview~~ | ~~Done~~ ✅ 2026-03-11 (descoped from Activity Viz — no TR-181 event data) |
| ~~**4D**~~ | ~~F-024 WiFi Performance Analytics~~ | ~~Done~~ ✅ 2026-03-11 (uses per-client AssociatedDevice, bypasses AP Stats fault) |
| **4D** | F-007 Guest Network, F-011 Ping (polling) | **✅ USP Verified** — Medium cost, high value networking features |
| **4E** | F-025 Historical Trend Analysis | **⚠️ Client-side Only** — Requires data collection, no USP historical storage |

---

## USP Data Model Verification Summary

### ✅ **Fully Verified & Implemented**

| Feature | TR-181 Data Sources | Status |
|---------|---------------------|--------|
| **F-018 Real-Time Traffic Monitor** | `Device.IP.Interface.2.Stats.*` | ✅ Done 2026-03-10 |
| **F-019 Multi-Interface Traffic** | `Device.IP.Interface.{1,2}.Stats.*`<br>`Device.Ethernet.Interface.*.Stats.*` | ✅ Done 2026-03-11 |
| **F-020 Device Connection Analytics** | `Device.Hosts.Host.{i}.*`<br>`Device.WiFi.AccessPoint.{i}.AssociatedDevice.{j}.*` | ✅ Done 2026-03-11 |
| **F-022 Network Health Monitoring** | `Device.IP.Interface.{1,2}.Stats.Errors*`<br>`Device.IP.Interface.{1,2}.Stats.DiscardPackets*` | ✅ Done 2026-03-11 |
| **F-023 Firewall Config Overview** | `Device.Firewall.Chain.1.Rule.{i}.*`<br>`Device.NAT.PortMapping.{i}.*`<br>`Device.Firewall.DMZ.{i}.*` | ✅ Done 2026-03-11 (descoped: no activity data) |
| **F-024 WiFi Performance Analytics** | `WifiClient.signalStrength/noise/lastData*Rate`<br>`Device.WiFi.Radio.{i}.Channel/Band/Bandwidth` | ✅ Done 2026-03-11 (AP Stats bypassed) |

### ✅ **Fully Verified Features** (Ready for Implementation)

| Feature | TR-181 Data Sources | Live Test Results |
|---------|---------------------|-------------------|
| **F-021 System Performance Dashboard** | `Device.DeviceInfo.ProcessStatus.*`<br>`Device.DeviceInfo.MemoryStatus.*` | From existing SystemStatusCard implementation |

### ⚠️ **Client-Side Implementation Required**

| Feature | Limitation | Implementation Approach |
|---------|------------|-------------------------|
| **F-025 Historical Trend Analysis** | No TR-181 historical storage | Hive local storage + background data collection |

### ❌ **Not Supported in Current Firmware**

| Feature | TR-181 Path | Status |
|---------|-------------|--------|
| Advanced WiFi AP Statistics | `Device.WiFi.AccessPoint.{i}.Stats.*` | fault 9005 (Invalid parameter name) |

---

## Recommended Chart Implementation Sequence

### **Phase 4B: Core Analytics** (Immediate — 1-2 weeks)
1. ~~**F-018 Real-Time Traffic Monitor**~~ — ✅ Done 2026-03-10
2. **F-021 System Performance Dashboard** — Multi-gauge display, extend existing SystemStatusCard

### **Phase 4C: Extended Analytics** — ✅ All Done 2026-03-11
3. ~~**F-019 Multi-Interface Traffic Analysis**~~ — ✅ Done (AppLineChart, AppBarChart stacked, AppPieChart donut, dual-axis CustomPainter)
4. ~~**F-020 Device Connection Analytics**~~ — ✅ Done (AppPieChart, AppBarChart stacked, AppHeatmapChart, AppRadarChart)
5. ~~**F-022 Network Health Monitoring**~~ — ✅ Done (AppGauge + traffic lights, AppLineChart area charts)

### **Phase 4D: Advanced Visualizations** — ✅ F-023/F-024 Done 2026-03-11
6. ~~**F-023 Firewall Configuration Overview**~~ — ✅ Done (AppPieChart donut rules, AppBarChart protocol distribution)
7. ~~**F-024 WiFi Performance Analytics**~~ — ✅ Done (AppBarChart signal/speed, AppPieChart band distribution)

### **Phase 4E: Long-term Analytics** (Future — 2+ months)
8. **F-025 Historical Trend Analysis** — Weekly/monthly trends, seasonal analysis
