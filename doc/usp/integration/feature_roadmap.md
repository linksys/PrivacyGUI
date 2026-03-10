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

---

## Implementation Priority Matrix

```
                    High Impact
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    │  F-001 WiFi PW    │  F-011 Ping       │
    │                   │  F-007 Guest Net  │
    │                   │                   │
 Low├───────────────────┼───────────────────┤High
Cost│                   │                   │Cost
    │  F-004 CH Width   │                   │
    │                   │                   │
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
| **Next (4B)** | F-001 WiFi Password, F-004 Channel Width | Low cost daily-use WiFi management |
| **4C** | F-007 Guest Network, F-011 Ping (polling) | Medium cost, high value networking features |
