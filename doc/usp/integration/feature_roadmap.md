# USP Dashboard Feature Roadmap

> Date: 2026-03-06 | Updated: 2026-03-10 | Branch: `feat/usp-protocol-integration`
> Last feature: F-017 IPv6 Port Service + 401 Auth Retry (2026-03-10)
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

**Total: 23 YAML definitions, 23 .g.dart files, 15 dashboard cards, 12 menu pages, 30+ mutation methods**

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

### F-018: Real-Time Traffic Monitor

**Priority:** P0 | **Effort:** Medium | **Status:** Not started

- **Feasibility:** ✅ Fully verified — complete traffic statistics available on router
- **Verified data sources:**
  ```bash
  # WAN Interface Statistics (primary monitoring point)
  Device.IP.Interface.2.Stats.BytesSent      → WAN upload total
  Device.IP.Interface.2.Stats.BytesReceived  → WAN download total
  Device.IP.Interface.2.Stats.PacketsSent    → WAN upload packets
  Device.IP.Interface.2.Stats.PacketsReceived → WAN download packets

  # LAN Interface Statistics
  Device.IP.Interface.1.Stats.*              → LAN traffic stats

  # Ethernet Port Statistics
  Device.Ethernet.Interface.*.Stats.*        → Per-port traffic stats

  # WiFi Radio Statistics
  Device.WiFi.Radio.*.Stats.*                → WiFi traffic stats
  ```
- **Live testing results:**
  - WAN download: 2.1 GB accumulated
  - WAN upload: 705 MB accumulated
  - Real-time sampling: 19,902 bytes in 5 seconds (≈ 3.9 KB/s)
- **Implementation approach:** Polling-based (1-2 second intervals)
- **UI components:**
  - Real-time speed tiles (upload/download KB/s or MB/s)
  - Dynamic line chart showing last 60 seconds of traffic
  - Daily/monthly cumulative statistics
  - Data persistence using Hive for historical tracking
- **Dashboard integration:** New `TrafficMonitorCard` in dashboard layout (high priority position)
- **Future enhancement:** When BUG-005 (Subscribe) is fixed, migrate to ValueChange notifications for sub-second updates

---

## Advanced Chart & Analytics Features

### F-019: Multi-Interface Traffic Analysis

**Priority:** P1 | **Effort:** Medium | **Status:** Not started

- **USP Verification:** ✅ Verified — all interface statistics available
- **Verified data sources:**
  ```bash
  Device.IP.Interface.1.Stats.*              → LAN: 2.1GB sent, 705MB received ✅
  Device.IP.Interface.2.Stats.*              → WAN: 705MB sent, 2.1GB received ✅
  Device.Ethernet.Interface.1.Stats.*        → ETH1: 969MB sent, 303MB received ✅
  Device.Ethernet.Interface.2.Stats.*        → ETH2: (additional ports) ✅
  Device.WiFi.Radio.1.Stats.*               → 2.4GHz: available but currently 0 ✅
  Device.WiFi.Radio.2.Stats.*               → 5GHz: available but currently 0 ✅
  ```
- **Chart types:**
  - **Stacked bar chart:** WAN vs LAN upload/download comparison
  - **Donut chart:** Per-port traffic distribution
  - **Dual-axis line chart:** Bytes vs packets trends
- **Implementation:** Extend F-018 with multi-source data aggregation

### F-020: Device Connection Analytics

**Priority:** P1 | **Effort:** Medium | **Status:** Not started

- **USP Verification:** ✅ Verified — comprehensive device data available (from existing implementation)
- **Verified data sources:**
  ```bash
  Device.Hosts.Host.{i}.Active               → Online/offline status ✅
  Device.Hosts.Host.{i}.Layer1Interface      → WiFi vs wired detection ✅
  Device.WiFi.AccessPoint.{i}.AssociatedDevice.{j}.SignalStrength → WiFi quality ✅
  ```
- **Chart types:**
  - **Pie chart:** WiFi vs wired device distribution
  - **Stacked column chart:** Hourly device count changes
  - **Heatmap:** 24-hour device activity patterns
  - **Radar chart:** WiFi signal quality per AP
- **Implementation:** Leverage existing `ConnectedDevices` + `WifiClients` codegen

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

### F-022: Network Health Monitoring

**Priority:** P2 | **Effort:** Medium | **Status:** Not started

- **USP Verification:** ✅ Verified — error statistics available
- **Verified data sources:**
  ```bash
  Device.IP.Interface.2.Stats.ErrorsSent     → WAN TX errors: 0 ✅
  Device.IP.Interface.2.Stats.ErrorsReceived → WAN RX errors: 0 ✅
  Device.IP.Interface.2.Stats.DiscardPacketsSent     → Discarded packets: 0 ✅
  Device.IP.Interface.2.Stats.DiscardPacketsReceived → Discarded packets: 12 ✅
  ```
- **Chart types:**
  - **Area chart:** Error packets vs normal packets ratio
  - **Traffic light indicators:** Error rate threshold warnings
  - **Composite health score:** Network reliability metric (0-100%)
- **Implementation:** New `NetworkHealthService` with error rate calculations

### F-023: Firewall Activity Visualization

**Priority:** P2 | **Effort:** Large | **Status:** Not started

- **USP Verification:** ✅ Verified — firewall rules data available
- **Verified data sources:**
  ```bash
  Device.Firewall.Chain.1.Rule.{i}.*        → 29 firewall rules available ✅
  Device.NAT.PortMapping.{i}.*               → Port forwarding rules ✅
  Device.Firewall.DMZ.{i}.*                 → DMZ configuration ✅
  ```
- **Chart types:**
  - **Activity timeline:** Blocked events distribution
  - **Network topology diagram:** Visual port usage status
  - **Rule effectiveness chart:** Most/least triggered rules
- **Implementation:** Extend existing `FirewallUIModel` with activity tracking
- **Note:** Requires event logging capability (not verified if available via USP)

### F-024: WiFi Performance Analytics

**Priority:** P2 | **Effort:** Medium | **Status:** Not started

- **USP Verification:** ⚠️ Partially verified — some WiFi stats unavailable
- **Verified data sources:**
  ```bash
  Device.WiFi.Radio.{i}.Stats.*              → Basic radio stats ✅ (but values = 0)
  Device.WiFi.AccessPoint.{i}.Stats.*        → ❌ Not supported (fault 9005)
  Device.WiFi.AccessPoint.{i}.AssociatedDevice.{j}.SignalStrength → ✅ Available
  Device.WiFi.Radio.{i}.Channel              → Current channel ✅
  Device.WiFi.Radio.{i}.Stats.Noise          → Noise level ✅
  ```
- **Chart types:**
  - **Radar chart:** Multi-AP signal quality comparison
  - **Bar chart:** Channel usage distribution
  - **Scatter plot:** Signal strength vs connection speed correlation
- **Implementation:** Requires investigation of why WiFi Radio.Stats values are 0
- **Limitation:** AP-level statistics not available in current firmware

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
    │  F-001 WiFi PW    │ F-018 Traffic Mon │
    │  F-021 Sys Perf   │  F-019 Multi-IF  │
    │                   │  F-011 Ping       │
    │                   │  F-007 Guest Net  │
 Low├───────────────────┼───────────────────┤High
Cost│                   │                   │Cost
    │  F-004 CH Width   │  F-020 Dev Conn  │
    │  F-022 Net Health │  F-023 Firewall  │
    │                   │  F-024 WiFi Perf │
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
| **Next (4B)** | F-018 Real-Time Traffic Monitor | **✅ USP Verified** — High impact, complete data sources |
| **4B** | F-021 System Performance Dashboard | **✅ USP Verified** — Extend existing SystemStatusCard |
| **4B** | F-001 WiFi Password, F-004 Channel Width | **✅ USP Verified** — Low cost daily-use WiFi management |
| **4C** | F-019 Multi-Interface Traffic Analysis | **✅ USP Verified** — Extend F-018 with multi-source data |
| **4C** | F-020 Device Connection Analytics | **✅ USP Verified** — Leverage existing ConnectedDevices codegen |
| **4C** | F-022 Network Health Monitoring | **✅ USP Verified** — Error statistics available |
| **4D** | F-007 Guest Network, F-011 Ping (polling) | **✅ USP Verified** — Medium cost, high value networking features |
| **4D** | F-023 Firewall Activity Visualization | **✅ USP Verified** — Firewall rules data available, needs event logging investigation |
| **4E** | F-024 WiFi Performance Analytics | **⚠️ Partially Verified** — Radio stats available but AP stats unsupported |
| **4E** | F-025 Historical Trend Analysis | **⚠️ Client-side Only** — Requires data collection, no USP historical storage |

---

## USP Data Model Verification Summary

### ✅ **Fully Verified Features** (Ready for Implementation)

| Feature | TR-181 Data Sources | Live Test Results |
|---------|---------------------|-------------------|
| **F-018 Real-Time Traffic Monitor** | `Device.IP.Interface.2.Stats.*` | WAN: 2.1GB↓ 705MB↑, real-time sampling confirmed |
| **F-019 Multi-Interface Traffic** | `Device.IP.Interface.{1,2}.Stats.*`<br>`Device.Ethernet.Interface.*.Stats.*` | LAN: 2.1GB↑ 705MB↓<br>ETH1: 969MB↑ 303MB↓ |
| **F-020 Device Connection Analytics** | `Device.Hosts.Host.{i}.*`<br>`Device.WiFi.AccessPoint.{i}.AssociatedDevice.{j}.*` | From existing ConnectedDevices implementation |
| **F-021 System Performance Dashboard** | `Device.DeviceInfo.ProcessStatus.*`<br>`Device.DeviceInfo.MemoryStatus.*` | From existing SystemStatusCard implementation |
| **F-022 Network Health Monitoring** | `Device.IP.Interface.2.Stats.Errors*`<br>`Device.IP.Interface.2.Stats.DiscardPackets*` | WAN errors: 0, discarded: 12 packets |
| **F-023 Firewall Activity** | `Device.Firewall.Chain.1.Rule.{i}.*` | 29 firewall rules available |

### ⚠️ **Partially Verified Features** (Requires Investigation)

| Feature | Available Data | Missing Data | Workaround |
|---------|----------------|--------------|------------|
| **F-024 WiFi Performance Analytics** | `Device.WiFi.Radio.{i}.Stats.*`<br>`Device.WiFi.Radio.{i}.Channel`<br>`Device.WiFi.Radio.{i}.Stats.Noise` | `Device.WiFi.AccessPoint.{i}.Stats.*`<br>(fault 9005) | Use Radio-level stats + AssociatedDevice signal strength |

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
1. **F-018 Real-Time Traffic Monitor** — Dynamic line charts, speed tiles
2. **F-021 System Performance Dashboard** — Multi-gauge display, extend existing SystemStatusCard

### **Phase 4C: Extended Analytics** (Short-term — 2-3 weeks)
3. **F-019 Multi-Interface Traffic Analysis** — Stacked bar charts, donut charts
4. **F-020 Device Connection Analytics** — Pie charts, heatmaps
5. **F-022 Network Health Monitoring** — Area charts, traffic light indicators

### **Phase 4D: Advanced Visualizations** (Medium-term — 4-6 weeks)
6. **F-023 Firewall Activity Visualization** — Network topology, activity timelines
7. **F-024 WiFi Performance Analytics** — Radar charts, channel usage bars

### **Phase 4E: Long-term Analytics** (Future — 2+ months)
8. **F-025 Historical Trend Analysis** — Weekly/monthly trends, seasonal analysis
