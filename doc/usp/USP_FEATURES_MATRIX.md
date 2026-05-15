# USP Features Matrix
## PrivacyGUI Feature Coverage Analysis

**Document Version:** 2.0
**Last Updated:** May 12, 2026
**Purpose:** Feature implementation status tracking for JNAP → USP migration
**Reference:** [GitHub Issue #20 - Gap Analysis](https://github.com/linksys/feed_uspapi/issues/20)

---

## Executive Summary

### Current Implementation Status

| Metric | Count |
|--------|-------|
| **YAML Definitions** | 36 files |
| **Generated `.g.dart`** | 39 files (incl. transforms, subscriptions, tr181_paths, index) |
| **USP Service Files** | 28 services |
| **Feature Pages** | 29 pages |

### Migration Progress Overview

| Category | Total Features | USP Complete | USP Partial | Agent Only | GAP | Out of Scope |
|----------|----------------|--------------|-------------|------------|-----|--------------|
| **Core System** | 8 | 7 (88%) | 0 | 0 | 1 | 0 |
| **Network Management** | 10 | 10 (100%) | 0 | 0 | 0 | 0 |
| **Device Management** | 5 | 5 (100%) | 0 | 0 | 0 | 0 |
| **WiFi Configuration** | 8 | 7 (88%) | 0 | 1 | 0 | 0 |
| **Internet Settings** | 10 | 9 (90%) | 0 | 0 | 1 | 0 |
| **Security & Firewall** | 11 | 9 (82%) | 0 | 0 | 2 | 0 |
| **Advanced Features** | 7 | 4 (57%) | 0 | 1 | 2 | 0 |
| **Speed Test** | 3 | 0 (0%) | 0 | 0 | 3 | 0 |
| **PnP (Initial Setup)** | 3 | 0 (0%) | 0 | 0 | 3 | 0 |
| **Monitoring & Diagnostics** | 8 | 8 (100%) | 0 | 0 | 0 | 0 |
| **Out of Scope** | 11 | — | — | — | — | 11 |
| **Total (in scope)** | **73** | **59 (81%)** | **0 (0%)** | **2 (3%)** | **12 (16%)** | — |

### Status Legend

- ✅ **Complete** — YAML definition + UI implementation + tested
- 🟡 **Partial** — YAML exists, UI incomplete or limited functionality
- 🔵 **Agent Only** — TR-181 path exists in agent, no YAML definition
- ❌ **GAP** — Not supported by bbfdm agent (fault 9005) or no TR-181 mapping
- ⬜ **Out of Scope** — Intentionally excluded, remains JNAP-only

---

## Detailed Feature Matrix

### Core System Management ✅ 88% Complete (7/8 in-scope)

| Feature | YAML Definition | USP Implementation | Status | UI Component |
|---------|-----------------|-------------------|--------|--------------|
| **Device Information** | `system_info.yaml` | `SystemInfo.fetch()` | ✅ Complete | Dashboard cards |
| **System Status** | `system_info.yaml` | CPU/Memory/Uptime | ✅ Complete | `UspSystemStatusCard` |
| **Time Settings** | `time_settings.yaml` | `TimeSettings.fetch/save()` | ✅ Complete | Admin page |
| **Admin Password** | `admin_users.yaml` | `AdminUsers.update()` | ❌ GAP | bbfdm set succeeds but doesn't sync to usp-auth-cgi |
| **Firmware Information** | `firmware_images.yaml` | `FirmwareImages.fetch()` | ✅ Complete | Device info card |
| **Reboot** | Direct operate | `Device.Reboot()` | ✅ Complete | Admin page |
| **Factory Reset** | Direct operate | `Device.FactoryReset()` | ✅ Complete | Admin page |
| **System Log** | `vendor_log_files.yaml` | `VendorLogFiles.fetch()` | ✅ Complete | System log page |

---

### Network Management ✅ 100% Complete

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **WAN Status** | `wan_status.yaml` | `WanStatus.fetch()` | ✅ Complete | IP, subnet, gateway, DNS |
| **WAN DHCP** | `wan_dhcp.yaml` | `WanDhcp.fetch/save()` | ✅ Complete | DHCP client config |
| **WAN Static IP** | `wan_static_ip.yaml` | `WanStaticIp.fetch/save()` | ✅ Complete | Uses `X_LINKSYS_*` extensions |
| **WAN PPPoE** | `wan_pppoe.yaml` | `WanPppoe.fetch/save()` | ✅ Complete | Username/password config |
| **WAN Bridge** | `wan_bridge.yaml` | `WanBridge.fetch/save()` | ✅ Complete | Bridge mode |
| **WAN Operations** | `wan_operations.yaml` | `renewDhcpLease/v6Lease()` | ✅ Complete | DHCP renew via operate |
| **WAN Traffic Stats** | `wan_traffic_stats.yaml` | `WanTrafficStats.fetch()` | ✅ Complete | Bytes sent/received |
| **LAN Configuration** | `lan_network_info.yaml` | `LanNetworkInfo.fetch/save()` | ✅ Complete | IP, DHCP server, DNS |
| **Ethernet Interfaces** | `ethernet_interfaces.yaml` | `EthernetInterfaces.fetch()` | ✅ Complete | Port status + link speed |
| **IPv6 Settings** | `ipv6_settings.yaml` | `Ipv6Settings.fetch/save()` | ✅ Complete | 6rd prefix has known format issue (edge case) |

---

### Device Management ✅ 100% Complete

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Connected Devices** | `connected_devices.yaml` | `ConnectedDevices.fetch()` | ✅ Complete | Hosts + enrichment |
| **WiFi Clients** | `wifi_clients.yaml` | `WifiClients.fetch()` | ✅ Complete | RSSI, rate, band |
| **DHCP Clients** | `dhcp_clients.yaml` | `DhcpClients.fetch()` | ✅ Complete | Lease info |
| **DHCP Reservations** | `dhcp_reservations.yaml` | Full CRUD | ✅ Complete | Add/update/delete |
| **Network Topology** | `data_elements_network.yaml` | `DataElementsNetwork.fetch()` | ✅ Complete | Mesh topology (read-only) |

---

### WiFi Configuration ✅ 88% Complete (7/8 in-scope)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **WiFi Radio Control** | `wi_fi_radios.yaml` | `WiFiRadios.fetch/update()` | ✅ Complete | Enable, channel, bandwidth |
| **WiFi SSID Management** | `wi_fi_ssids.yaml` | `WiFiSsids.fetch/update()` | ✅ Complete | SSID name, enable |
| **WiFi Access Points** | `wi_fi_access_points.yaml` | `WiFiAccessPoints.fetch/update()` | ✅ Complete | Security, passphrase |
| **WiFi Password Change** | `wi_fi_access_points.yaml` | `KeyPassphrase` field | ✅ Complete | Via AccessPoints update |
| **Guest Network** | Multi-SSID (instances 4-6) | WiFi provider logic | ✅ Complete | `quickSetupGuest` in provider |
| **MAC Address Filter** | `mac_filter_access_points.yaml` | Full CRUD | ✅ Complete | Instant Privacy feature |
| **Channel Bonding** | `wi_fi_radios.yaml` | Dynamic calculation | ✅ Complete | IEEE 802.11 compliant, 20-320MHz |
| **WPS** | — | `Device.WiFi.AccessPoint.{i}.WPS.*` | 🔵 Agent Only | Paths exist, no YAML |
| **WiFi 6E/7 MLO** | — | — | ❌ GAP | Hardware-specific |
| **WiFi Scheduling** | — | — | ⬜ Out of Scope | No TR-181 scheduler model |
| **Smart Connect** | — | — | ⬜ Out of Scope | Linksys proprietary |
| **Channel Scanner** | — | — | ⬜ Out of Scope | Active scanning, hardware-specific |

---

### Internet Settings ✅ 90% Complete (9/10 in-scope)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Connection Status** | `wan_status.yaml` | `WanStatus.fetch()` | ✅ Complete | Full status display |
| **DHCP Configuration** | `wan_dhcp.yaml` | `WanDhcp.save()` | ✅ Complete | Auto/manual DNS |
| **Static IP Setup** | `wan_static_ip.yaml` | `WanStaticIp.save()` | ✅ Complete | Uses X_LINKSYS extensions |
| **PPPoE Configuration** | `wan_pppoe.yaml` | `WanPppoe.save()` | ✅ Complete | Service name issue resolved |
| **Bridge Mode** | `wan_bridge.yaml` | `WanBridge.save()` | ✅ Complete | Mode switching |
| **MTU Configuration** | `wan_settings.yaml` | `WanSettings.save()` | ✅ Complete | Interface MTU |
| **IPv6 WAN** | `wan_ipv6_addresses.yaml` | `WanIpv6Addresses.fetch()` | ✅ Complete | IPv6 status |
| **PPP Interface** | `ppp_interface.yaml` | `PppInterface.fetch()` | ✅ Complete | PPP status |
| **VLAN Tagging** | `vlan_termination.yaml` | `VlanTermination.fetch/save()` | ✅ Complete | Enable + VLANID (no ISP presets) |
| **DDNS** | — | — | ❌ GAP | Agent fault 9005 |

---

### Security & Firewall ✅ 82% Complete (9/11 in-scope)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Firewall Rules** | `firewall_chain_rules.yaml` | Full CRUD | ✅ Complete | SPI, VPN passthrough |
| **DMZ** | `dmz.yaml` | `Dmz.fetch/update/add/delete()` | ✅ Complete | Full CRUD |
| **Port Forwarding** | `port_forwarding.yaml` | Full CRUD | ✅ Complete | Single + range |
| **Port Triggering** | `port_triggering.yaml` | Full CRUD | ✅ Complete | Nested rules |
| **IPv6 Port Service** | `ipv6port_service.yaml` | Full CRUD | ✅ Complete | IPv6 firewall |
| **Static Routing** | `static_routing.yaml` | Full CRUD | ✅ Complete | Route management |
| **Safe Browsing** | DNS override | `LanNetworkInfo` DNS | ✅ Complete | Instant Safety feature |
| **Instant Privacy** | `mac_filter_access_points.yaml` | MAC filtering | ✅ Complete | Block device access |
| **Firewall Settings** | `firewall_chain_rules.yaml` | SPI, VPN passthrough, filters | ✅ Complete | Per-rule enable via Chain Rules |
| **UPnP Settings** | — | — | ❌ GAP | Agent fault 9005 |
| **ALG Settings** | — | — | ❌ GAP | Agent fault 9005 |
| **VPN Server** | — | — | ⬜ Out of Scope | No TR-181 spec, enterprise feature |

---

### Advanced Features ✅ 57% Complete (4/7 in-scope)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Multi-Interface Stats** | `multi_interface_traffic_stats.yaml` | Aggregated stats | ✅ Complete | LAN+WAN combined |
| **Traffic Analysis** | Multiple sources | Dashboard analytics | ✅ Complete | Real-time charts |
| **PDF Reports** | Multiple sources | Aggregated export | ✅ Complete | Network analysis |
| **System Monitoring** | `system_info.yaml` | CPU/Memory trends | ✅ Complete | Performance charts |
| **PPP Reset** | — | `PPP.Interface.{i}.Reset()` | 🔵 Agent Only | Path exists, no YAML |
| **Router LEDs** | — | — | ❌ GAP | Agent fault 9005 |
| **Mesh Configuration** | — | — | ❌ GAP | Complex topology |
| **Firmware Auto-Update** | — | — | ❌ GAP | No scheduling model |
| **Firmware Activate** | — | — | ⬜ Out of Scope | Manual bank switching, auto-handled |
| **QoS Basic** | — | — | ⬜ Out of Scope | Agent fault 9005, complex rules |
| **Remote Management** | — | — | ⬜ Out of Scope | Cloud auth required |
| **Dual WAN** | — | — | ⬜ Out of Scope | Not in TR-181, hardware-specific |
| **Parental Controls** | — | — | ⬜ Out of Scope | Cloud-based content filtering |
| **Backup & Restore** | — | — | ⬜ Out of Scope | Config file format proprietary |
| **Link Aggregation** | — | — | ⬜ Out of Scope | Hardware-specific, limited models |

---

### Speed Test ❌ USP Not Available

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Speed Test** | — | — | ❌ GAP | No TR-181 speed test model |
| **Health Check Results** | — | — | ❌ GAP | No TR-181 equivalent |
| **Speed Test History** | — | — | ❌ GAP | No TR-181 equivalent |

**Note:** Speed Test requires router-side bandwidth measurement which is not part of TR-181 standard. Current implementation uses JNAP (`runHealthCheck`, `getHealthCheckStatus`, `getHealthCheckResults`).

---

### PnP (Plug and Play / Initial Setup) ❌ USP Not Available

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **First Time Setup** | — | — | ❌ GAP | No TR-181 setup wizard model |
| **Internet Detection** | — | — | ❌ GAP | WAN type auto-detection |
| **Firmware Check on Setup** | — | — | ❌ GAP | Initial FW update flow |

**Note:** PnP (initial router setup wizard) requires orchestrated multi-step flow that is not standardized in TR-181. Current implementation uses JNAP for setup detection and WAN type probing. Admin Password issue (bbfdm/usp-auth-cgi desync) is tracked separately in Core System category.

---

### Monitoring & Diagnostics ✅ 100% Complete

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Ping Diagnostic** | `network_diagnostics.yaml` | `Device.IP.Diagnostics.IPPing()` | ✅ Complete | SSE + operation awaiter |
| **Traceroute** | `network_diagnostics.yaml` | `Device.IP.Diagnostics.TraceRoute()` | ✅ Complete | SSE + operation awaiter |
| **System Health** | `system_info.yaml` | CPU/Memory/Uptime | ✅ Complete | Dashboard metrics |
| **Network Performance** | Multiple sources | Aggregated analytics | ✅ Complete | Traffic monitor |
| **WiFi Analytics** | `wifi_clients.yaml` + `data_elements_network.yaml` | Signal quality | ✅ Complete | Per-client analysis |
| **Traffic Monitor** | `multi_interface_traffic_stats.yaml` | Real-time charts | ✅ Complete | WAN/LAN dual-line |
| **Connection Monitoring** | `connected_devices.yaml` | Real-time status | ✅ Complete | Device list |
| **Statistics Dashboard** | Multiple sources | 18 sections | ✅ Complete | `UspStatisticsView` |

---

## YAML Definition Inventory (36 files)

### By Category

| Category | YAML Files |
|----------|-----------|
| **admin** | `admin_users` |
| **core** | `system_info`, `time_settings`, `vendor_log_files`, `firmware_images` |
| **devices** | `connected_devices`, `wifi_clients` |
| **firewall** | `dmz`, `firewall_chain_rules`, `ipv6port_service`, `port_forwarding`, `port_triggering` |
| **network** | `dhcp_clients`, `dhcp_reservations`, `ethernet_interfaces`, `ipv6_settings`, `lan_network_info`, `multi_interface_traffic_stats`, `ppp_interface`, `static_routing`, `vlan_termination`, `wan_bridge`, `wan_dhcp`, `wan_ipv6_addresses`, `wan_operations`, `wan_pppoe`, `wan_settings`, `wan_static_ip`, `wan_status`, `wan_traffic_stats`, `network_diagnostics` |
| **wifi** | `data_elements_network`, `mac_filter_access_points`, `wi_fi_access_points`, `wi_fi_radios`, `wi_fi_ssids` |

---

## Agent-Only Features (Need YAML for UI)

These TR-181 paths are supported by the bbfdm agent but lack YAML definitions:

| Feature | TR-181 Path | Priority | Notes |
|---------|-------------|----------|-------|
| **Global Firewall Enable** | `Device.Firewall.Enable` | P1 | Simple boolean toggle |
| **WPS** | `Device.WiFi.AccessPoint.{i}.WPS.*` | P1 | Enable, ConfigMethods, Status |
| **Firmware Activate** | `Device.DeviceInfo.FirmwareImage.{i}.Activate()` | P1 | Operate command |
| **PPP Reset** | `Device.PPP.Interface.{i}.Reset()` | P2 | Operate command |
| **Router LEDs** | `Device.LEDs.*` | P2 | LED enable, brightness |
| **WiFi Scheduling** | Time-based radio control | P2 | Implementation TBD |

---

## Confirmed GAPs (Agent Does Not Support)

These features return fault 9005 or have no TR-181 mapping:

| Feature | TR-181 Path | Issue | Impact |
|---------|-------------|-------|--------|
| **DDNS** | `Device.DynamicDNS.*` | fault 9005 | Remote access limited |
| **UPnP** | `Device.UPnP.*` | fault 9005 | Auto port mapping unavailable |
| **ALG** | `Device.NAT.ALG.*` | fault 9005 | SIP/FTP passthrough unavailable |
| **Smart Connect** | — | Proprietary | Band steering unavailable |
| **MLO** | — | WiFi 7 specific | Latest WiFi features missing |
| **Mesh Node Management** | — | 96 JNAP actions | Full mesh control missing |
| **VPN Server** | — | No TR-181 spec | Enterprise VPN unavailable |
| **Parental Controls** | — | Content filtering | Family features missing |
| **Firmware Auto-Update** | — | No scheduling | Manual updates only |

---

## UI Component Coverage

### Dashboard Cards (15 total)

| Card | Data Source | Status |
|------|-------------|--------|
| Stats Panel | Multiple aggregated | ✅ Complete |
| Network Status | `WanStatus` | ✅ Complete |
| Device Info | `SystemInfo` | ✅ Complete |
| LAN Info | `LanNetworkInfo` | ✅ Complete |
| System Status | `SystemInfo` | ✅ Complete |
| Ethernet Ports | `EthernetInterfaces` | ✅ Complete |
| Connected Devices | `ConnectedDevices` + enrichment | ✅ Complete |
| WiFi Status | `WiFiRadios` + `WiFiAccessPoints` | ✅ Complete |
| Time Settings | `TimeSettings` | ✅ Complete |
| DHCP Reservations | `DhcpReservations` | ✅ Complete |
| Port Forwarding | `PortForwarding` + `PortTriggering` | ✅ Complete |
| Network Topology | `DataElementsNetwork` | ✅ Complete |
| Traffic Monitor | `MultiInterfaceTrafficStats` | ✅ Complete |
| Firewall | `FirewallChainRules` | ✅ Complete |
| DMZ | `Dmz` | ✅ Complete |

### Feature Pages (14 USP-enabled)

| Page | Primary Data Source | Status |
|------|---------------------|--------|
| Dashboard | Multiple sources | ✅ Complete |
| Admin Settings | `AdminUsers`, `TimeSettings` | ✅ Complete |
| DHCP Detail | `DhcpReservations`, `DhcpClients` | ✅ Complete |
| Port Forwarding | `PortForwarding`, `PortTriggering` | ✅ Complete |
| Device List | `ConnectedDevices` + enrichment | ✅ Complete |
| Network Topology | `DataElementsNetwork` | ✅ Complete |
| System Log | `VendorLogFiles` | ✅ Complete |
| Firewall Settings | `FirewallChainRules` | ✅ Complete |
| DMZ Configuration | `Dmz` | ✅ Complete |
| Local Network | `LanNetworkInfo` | ✅ Complete |
| Static Routing | `StaticRouting` | ✅ Complete |
| IPv6 Port Service | `Ipv6PortService` | ✅ Complete |
| Network Diagnostics | `NetworkDiagnostics` | ✅ Complete |
| WiFi Settings | `WiFiRadios`, `WiFiSsids`, `WiFiAccessPoints` | ✅ Complete |

---

## Features by Status

### ✅ Complete (59 features)

| Feature | Category | YAML | UI |
|---------|----------|------|-----|
| Device Information | Core System | `system_info.yaml` | Dashboard cards |
| System Status | Core System | `system_info.yaml` | `UspSystemStatusCard` |
| Time Settings | Core System | `time_settings.yaml` | Admin page |
| Firmware Information | Core System | `firmware_images.yaml` | Device info card |
| Reboot | Core System | Direct operate | Admin page |
| Factory Reset | Core System | Direct operate | Admin page |
| System Log | Core System | `vendor_log_files.yaml` | System log page |
| WAN Status | Network | `wan_status.yaml` | Network status card |
| WAN DHCP | Network | `wan_dhcp.yaml` | Internet settings |
| WAN Static IP | Network | `wan_static_ip.yaml` | Internet settings |
| WAN PPPoE | Network | `wan_pppoe.yaml` | Internet settings |
| WAN Bridge | Network | `wan_bridge.yaml` | Internet settings |
| WAN Operations | Network | `wan_operations.yaml` | DHCP renew button |
| WAN Traffic Stats | Network | `wan_traffic_stats.yaml` | Traffic monitor |
| LAN Configuration | Network | `lan_network_info.yaml` | Local network page |
| Ethernet Interfaces | Network | `ethernet_interfaces.yaml` | Ethernet ports card |
| IPv6 Settings | Network | `ipv6_settings.yaml` | Internet settings |
| Connected Devices | Device | `connected_devices.yaml` | Device list |
| WiFi Clients | Device | `wifi_clients.yaml` | Device enrichment |
| DHCP Clients | Device | `dhcp_clients.yaml` | DHCP detail page |
| DHCP Reservations | Device | `dhcp_reservations.yaml` | DHCP reservations card |
| Network Topology | Device | `data_elements_network.yaml` | Topology page |
| WiFi Radio Control | WiFi | `wi_fi_radios.yaml` | WiFi settings |
| WiFi SSID Management | WiFi | `wi_fi_ssids.yaml` | WiFi settings |
| WiFi Access Points | WiFi | `wi_fi_access_points.yaml` | WiFi settings |
| WiFi Password Change | WiFi | `wi_fi_access_points.yaml` | WiFi settings |
| Guest Network | WiFi | Multi-SSID instances | WiFi settings |
| MAC Address Filter | WiFi | `mac_filter_access_points.yaml` | Instant Privacy |
| Channel Bonding | WiFi | `wi_fi_radios.yaml` | WiFi settings |
| Connection Status | Internet | `wan_status.yaml` | Network status card |
| DHCP Configuration | Internet | `wan_dhcp.yaml` | Internet settings |
| Static IP Setup | Internet | `wan_static_ip.yaml` | Internet settings |
| PPPoE Configuration | Internet | `wan_pppoe.yaml` | Internet settings |
| Bridge Mode | Internet | `wan_bridge.yaml` | Internet settings |
| MTU Configuration | Internet | `wan_settings.yaml` | Internet settings |
| IPv6 WAN | Internet | `wan_ipv6_addresses.yaml` | Internet settings |
| PPP Interface | Internet | `ppp_interface.yaml` | Internet settings |
| VLAN Tagging | Internet | `vlan_termination.yaml` | Internet settings |
| Firewall Rules | Security | `firewall_chain_rules.yaml` | Firewall page |
| Firewall Settings | Security | `firewall_chain_rules.yaml` | Firewall page |
| DMZ | Security | `dmz.yaml` | DMZ page |
| Port Forwarding | Security | `port_forwarding.yaml` | Port forwarding page |
| Port Triggering | Security | `port_triggering.yaml` | Port forwarding page |
| IPv6 Port Service | Security | `ipv6port_service.yaml` | IPv6 port service page |
| Static Routing | Security | `static_routing.yaml` | Static routing page |
| Safe Browsing | Security | DNS override | Instant Safety |
| Instant Privacy | Security | `mac_filter_access_points.yaml` | Instant Privacy |
| Multi-Interface Stats | Advanced | `multi_interface_traffic_stats.yaml` | Statistics |
| Traffic Analysis | Advanced | Multiple sources | Dashboard |
| PDF Reports | Advanced | Multiple sources | Export feature |
| System Monitoring | Advanced | `system_info.yaml` | Dashboard |
| Ping Diagnostic | Diagnostics | `network_diagnostics.yaml` | Network diagnostics |
| Traceroute | Diagnostics | `network_diagnostics.yaml` | Network diagnostics |
| System Health | Diagnostics | `system_info.yaml` | Dashboard |
| Network Performance | Diagnostics | Multiple sources | Statistics |
| WiFi Analytics | Diagnostics | `wifi_clients.yaml` | Statistics |
| Traffic Monitor | Diagnostics | `multi_interface_traffic_stats.yaml` | Dashboard |
| Connection Monitoring | Diagnostics | `connected_devices.yaml` | Device list |
| Statistics Dashboard | Diagnostics | Multiple sources | Statistics page |

### 🟡 Partial (0 features)

None — all implemented features are complete.

### 🔵 Agent Only (2 features)

| Feature | TR-181 Path | Effort | Priority |
|---------|-------------|--------|----------|
| WPS | `Device.WiFi.AccessPoint.{i}.WPS.*` | Medium — needs UI | P1 |
| PPP Reset | `Device.PPP.Interface.{i}.Reset()` | Low — operate call | P2 |

### ❌ GAP (12 features)

| Feature | Category | Blocker | Resolution Path |
|---------|----------|---------|-----------------|
| Admin Password | Core System | bbfdm/usp-auth-cgi desync | [Issue #874](https://github.com/linksys/PrivacyGUI/issues/874) |
| DDNS | Internet | Agent fault 9005 | New bbfdm module |
| UPnP Settings | Security | Agent fault 9005 | New bbfdm module |
| ALG Settings | Security | Agent fault 9005 | New bbfdm module |
| Router LEDs | Advanced | Agent fault 9005 | New bbfdm module |
| WiFi 6E/7 MLO | WiFi | Hardware-specific | Vendor extension |
| Mesh Configuration | Advanced | Complex topology | Phase 4 planning |
| Firmware Auto-Update | Advanced | No scheduling model | Vendor extension |
| Speed Test | Speed Test | No TR-181 model | JNAP only |
| Health Check Results | Speed Test | No TR-181 model | JNAP only |
| Speed Test History | Speed Test | No TR-181 model | JNAP only |
| PnP (Initial Setup) | PnP | No TR-181 setup wizard | JNAP only (3 sub-features) |

### ⬜ Out of Scope (11 features)

These features are intentionally excluded from USP v2 scope. They remain JNAP-only or require separate architectural decisions.

| Feature | Category | Reason | Alternative |
|---------|----------|--------|-------------|
| VPN Server | Security | No TR-181 spec, enterprise feature | JNAP implementation |
| Dual WAN | Advanced | Not in TR-181, hardware-specific | JNAP implementation |
| Parental Controls | Advanced | Cloud-based content filtering | Linksys Shield / JNAP |
| Backup & Restore | Advanced | Config file format proprietary | JNAP implementation |
| Link Aggregation | Advanced | Hardware-specific, limited models | JNAP implementation |
| Remote Management | Advanced | Requires cloud authentication | Separate cloud architecture |
| Smart Connect | WiFi | Linksys proprietary band steering | JNAP implementation |
| Channel Scanner | WiFi | Active scanning, hardware-specific | JNAP implementation |
| Firmware Activate | Advanced | Manual bank switching, auto-handled | Automatic during update |
| QoS | Advanced | Agent fault 9005, complex rules | JNAP implementation |
| WiFi Scheduling | WiFi | No TR-181 scheduler model | JNAP implementation |

---

## Comparison with GitHub Issue #20

| Aspect | Issue #20 (2026-04-24) | Actual Implementation |
|--------|------------------------|----------------------|
| YAML count | 36 files | 36 files ✅ |
| Guest Network | "Covered (agent) - needs YAML" | **Already implemented** — UI exists |
| WiFi Password | "Investigation" | **Complete** — `KeyPassphrase` in codegen |
| Reboot/Factory Reset | "Covered (agent)" | **Complete** — Direct operate calls |
| WPS | "Covered (agent) - needs YAML" | **Agent only** — No UI yet |
| Firewall Enable | "Covered (agent) - needs YAML" | **Agent only** — No dedicated YAML |
| DDNS | "GAP" | **Confirmed GAP** ❌ |
| UPnP | "GAP" | **Confirmed GAP** ❌ |

---

## Recommended Next Steps

### Phase 1: Low-effort YAML additions (Agent-only → Complete)

1. **Firewall Enable YAML** — Simple boolean, high value
2. **WPS YAML** — Enable WPS button in UI
3. **Firmware Activate YAML** — Standardize operate call

### Phase 2: UI completion for partial features

1. **IPv6 Settings** — Fix 6rd prefix validation
2. **VLAN Tagging** — Add profile support
3. **Router LEDs** — Add night mode UI

### Phase 3: Backend work required (GAP resolution)

1. **DDNS** — Requires new bbfdm module
2. **UPnP** — Requires new bbfdm module
3. **ALG** — Requires new bbfdm module

---

*This matrix reflects the actual implementation state as of May 12, 2026.*
*Reference: [GitHub Issue #20](https://github.com/linksys/feed_uspapi/issues/20) for detailed JNAP vs USP gap analysis.*
