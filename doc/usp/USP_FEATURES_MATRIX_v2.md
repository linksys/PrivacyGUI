# USP Features Matrix v2
## PrivacyGUI Feature Coverage Analysis — Menu-Based Structure

**Document Version:** 2.1
**Last Updated:** May 12, 2026
**Purpose:** Feature implementation status tracking for JNAP → USP migration
**Structure:** Organized by UI menu hierarchy (Menu Cards → Advanced Settings sub-items)
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

### Migration Progress Overview (Menu-Based)

| Category | Location | Total | Complete | Partial | Agent Only | GAP |
|----------|----------|-------|----------|---------|------------|-----|
| **Dashboard** | Home | 8 | 8 (100%) | 0 | 0 | 0 |
| **WiFi Settings** | Menu Card | 13 | 8 (62%) | 0 | 1 | 4 |
| **Topology** | Menu Card | 6 | 1 (17%) | 0 | 0 | 5 |
| **Devices** | Menu Card | 3 | 2 (67%) | 0 | 0 | 1 |
| **Instant Safety** | Menu Card | 1 | 1 (100%) | 0 | 0 | 0 |
| **Instant Privacy** | Menu Card | 1 | 1 (100%) | 0 | 0 | 0 |
| **Instant Admin / Administration** | Menu Card | 8 | 4 (50%) | 0 | 0 | 4 |
| **Instant Verify** | Menu Card | 2 | 2 (100%) | 0 | 0 | 0 |
| **Speed Test** | Menu Card | 3 | 0 (0%) | 0 | 0 | 3 |
| **Statistics** | Menu Card | 4 | 4 (100%) | 0 | 0 | 0 |
| **Internet Settings** | Advanced | 13 | 11 (85%) | 0 | 1 | 1 |
| **Local Network** | Advanced | 4 | 4 (100%) | 0 | 0 | 0 |
| **Firewall** | Advanced | 4 | 4 (100%) | 0 | 0 | 0 |
| **Apps & Gaming (Port Forwarding)** | Advanced | 4 | 3 (75%) | 0 | 0 | 1 |
| **Static Routing** | Advanced | 1 | 1 (100%) | 0 | 0 | 0 |
| **Administration Settings** | Advanced | 4 | 0 (0%) | 0 | 0 | 4 |
| **PnP (Initial Setup)** | Standalone Flow | 3 | 0 (0%) | 0 | 0 | 3 |
| **Out of Scope** | — | 11 | — | — | — | — |
| **Total (in scope)** | | **82** | **54 (66%)** | **0** | **2 (2%)** | **26 (32%)** |

### Status Legend

- ✅ **Complete** — YAML definition + UI implementation + tested
- 🟡 **Partial** — YAML exists, UI incomplete or limited functionality
- 🔵 **Agent Only** — TR-181 path exists in agent, no YAML definition
- ❌ **GAP** — Not supported by bbfdm agent (fault 9005) or no TR-181 mapping
- ⬜ **Out of Scope** — Intentionally excluded, remains JNAP-only

---

## Menu Card Features

### Dashboard ✅ 100% Complete

> Home page with aggregated status cards and real-time monitoring.

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **System Info Card** | `system_info.yaml` | `SystemInfo.fetch()` | ✅ Complete | Model, FW version, uptime |
| **Network Status Card** | `wan_status.yaml` | `WanStatus.fetch()` | ✅ Complete | WAN IP, connection type |
| **System Status Card** | `system_info.yaml` | CPU/Memory/Uptime | ✅ Complete | Performance metrics |
| **Ethernet Ports Card** | `ethernet_interfaces.yaml` | `EthernetInterfaces.fetch()` | ✅ Complete | Port status, link speed |
| **Connected Devices Card** | `connected_devices.yaml` | `ConnectedDevices.fetch()` | ✅ Complete | Device count, online status |
| **WiFi Status Card** | `wi_fi_radios.yaml` | `WiFiRadios.fetch()` | ✅ Complete | Band status, channel |
| **Traffic Monitor Card** | `wan_traffic_stats.yaml` | `WanTrafficStats.fetch()` | ✅ Complete | Real-time throughput |
| **Time Settings Card** | `time_settings.yaml` | `TimeSettings.fetch()` | ✅ Complete | Current time, timezone |

---

### WiFi Settings ✅ 54% Complete (7/13)

> Menu Card: "Incredible WiFi" — Networks, security, MAC filtering, advanced WiFi settings

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Radio Control** | `wi_fi_radios.yaml` | `WiFiRadios.fetch/update()` | ✅ Complete | Enable, channel, bandwidth |
| **SSID Management** | `wi_fi_ssids.yaml` | `WiFiSsids.fetch/update()` | ✅ Complete | Name, visibility |
| **Security Settings** | `wi_fi_access_points.yaml` | `WiFiAccessPoints.fetch/update()` | ✅ Complete | Mode, passphrase |
| **Guest Network** | Multi-SSID (instances 4-6) | Provider logic | ✅ Complete | `quickSetupGuest` |
| **MAC Address Filter** | `mac_filter_access_points.yaml` | Full CRUD | ✅ Complete | Allow/block list |
| **Channel Bonding** | `wi_fi_radios.yaml` | Dynamic calculation | ✅ Complete | IEEE 802.11, 20-320MHz |
| **WiFi Password** | `wi_fi_access_points.yaml` | `KeyPassphrase` | ✅ Complete | Via AccessPoints |
| **WPS** | — | `Device.WiFi.AccessPoint.{i}.WPS.*` | 🔵 Agent Only | No YAML definition |
| **Client Steering** | — | — | ❌ GAP | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| **Node Steering** | — | — | ❌ GAP | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| **DFS** | `wi_fi_radios.yaml` | `IEEE80211hEnabled` | ✅ Complete | Dynamic Frequency Selection |
| **MLO** | — | — | ❌ GAP | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| **IPTV** | — | — | ❌ GAP | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |

---

### Topology ✅ 17% Complete (1/6)

> Menu Card: "Topology" — View network topology and mesh nodes

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Network Topology** | `data_elements_network.yaml` | `DataElementsNetwork.fetch()` | ✅ Complete | Mesh node visualization |
| **Add Mesh Nodes** | — | — | ❌ GAP | [#879](https://github.com/linksys/PrivacyGUI/issues/879) |
| **Reboot Child Node** | — | — | ❌ GAP | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| **Factory Reset Child** | — | — | ❌ GAP | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| **Blink Node LED** | — | — | ❌ GAP | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| **LED Night Mode** | — | — | ❌ GAP | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |

**Note:** JNAP uses Bluetooth Auto-Onboarding (`getBluetoothAutoOnboardingSettings/Status`, `startBlueboothAutoOnboarding`) and Wired Auto-Onboarding (`getWiredAutoOnboardingSettings`, `getSmartConnectPin/Status`) for mesh node pairing. Node operations use `serviceHelper.isSupportChildReboot()` / `isSupportChildFactoryReset()`. LED settings use `getLedNightModeSetting` / `setLedNightModeSetting`. Requires controller-to-agent messaging for mesh nodes.

---

### Devices ✅ 67% Complete (2/3)

> Menu Card: "Devices" — View and manage connected devices

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Device List** | `connected_devices.yaml` | `ConnectedDevices.fetch()` | ✅ Complete | All hosts + enrichment |
| **WiFi Client Info** | `wifi_clients.yaml` | `WifiClients.fetch()` | ✅ Complete | RSSI, rate, band |
| **Client Deauth** | — | — | ❌ GAP | [#877](https://github.com/linksys/PrivacyGUI/issues/877) |

**Note:** JNAP uses `JNAPAction.clientDeauth` (`http://linksys.com/jnap/wirelessap/ClientDeauth`) to disconnect WiFi clients. Requires TR-181 path investigation.

---

### Instant Safety ✅ 100% Complete

> Menu Card: "Instant Safety" — Safe browsing with OpenDNS

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Safe Browsing** | `lan_network_info.yaml` | DNS override | ✅ Complete | OpenDNS Family Shield |

---

### Instant Privacy ✅ 100% Complete

> Menu Card: "Instant Privacy" — Lock network to currently connected devices

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **MAC Filter Block** | `mac_filter_access_points.yaml` | Full CRUD | ✅ Complete | Block new devices |

---

### Instant Admin / Administration ✅ 50% Complete (4/8)

> Menu Card: "Administration" (USP) / "Instant Admin" (JNAP) — Password, timezone, firmware, reboot

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Router Password** | `admin_users.yaml` | `AdminUsers.update()` | ❌ GAP | [#874](https://github.com/linksys/PrivacyGUI/issues/874) |
| **Password Hint** | `admin_users.yaml` | — | ❌ GAP | [#874](https://github.com/linksys/PrivacyGUI/issues/874) |
| **Timezone** | `time_settings.yaml` | `TimeSettings.fetch/save()` | ✅ Complete | NTP server config |
| **Auto Firmware Update** | — | — | ❌ GAP | [#841](https://github.com/linksys/PrivacyGUI/issues/841) |
| **Manual Firmware Update** | `firmware_images.yaml` | `FirmwareImages.fetch()` | ✅ Complete | Version info only |
| **Transmit Region** | — | — | ❌ GAP | [#878](https://github.com/linksys/PrivacyGUI/issues/878) |
| **Reboot** | Direct operate | `Device.Reboot()` | ✅ Complete | USP Administration page |
| **Factory Reset** | Direct operate | `Device.FactoryReset()` | ✅ Complete | USP Administration page |

**Note:** JNAP "Instant Admin" has password, timezone, firmware, transmit region (Power Table). USP "Administration" additionally has Reboot and Factory Reset. Transmit Region uses JNAP `getPowerTableSettings`/`setPowerTableSettings` — needs TR-181 investigation.

---

### Instant Verify ✅ 100% Complete

> Menu Card: "Instant Verify" — Network troubleshooting tools

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Ping** | `network_diagnostics.yaml` | `Device.IP.Diagnostics.IPPing()` | ✅ Complete | SSE + operation awaiter |
| **Traceroute** | `network_diagnostics.yaml` | `Device.IP.Diagnostics.TraceRoute()` | ✅ Complete | SSE + operation awaiter |

**Note:** In JNAP this is under "Instant Verify" menu card with `troubleshootingProvider`.

---

### Statistics ✅ 100% Complete

> Menu Card: "Statistics" — Network, device, and system analytics (USP-exclusive feature)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Traffic Analysis** | `multi_interface_traffic_stats.yaml` | Aggregated stats | ✅ Complete | WAN/LAN dual-line charts |
| **WiFi Analytics** | `wifi_clients.yaml` + `data_elements_network.yaml` | Signal quality | ✅ Complete | Per-client RSSI |
| **System Monitoring** | `system_info.yaml` | CPU/Memory trends | ✅ Complete | Performance charts |
| **PDF Reports** | Multiple sources | Aggregated export | ✅ Complete | Network analysis |

**Note:** Statistics page is a USP-exclusive feature not present in JNAP version.

---

## Advanced Settings Features

### Internet Settings ✅ 85% Complete (11/13)

> Advanced Settings → Internet Settings

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Connection Status** | `wan_status.yaml` | `WanStatus.fetch()` | ✅ Complete | IP, gateway, DNS |
| **DHCP Configuration** | `wan_dhcp.yaml` | `WanDhcp.fetch/save()` | ✅ Complete | Auto/manual DNS |
| **Static IP Setup** | `wan_static_ip.yaml` | `WanStaticIp.fetch/save()` | ✅ Complete | Uses X_LINKSYS extensions |
| **PPPoE Configuration** | `wan_pppoe.yaml` | `WanPppoe.fetch/save()` | ✅ Complete | Username/password |
| **Bridge Mode** | `wan_bridge.yaml` | `WanBridge.fetch/save()` | ✅ Complete | Mode switching |
| **MTU Configuration** | `wan_settings.yaml` | `WanSettings.fetch/save()` | ✅ Complete | Interface MTU |
| **IPv6 Settings** | `ipv6_settings.yaml` | `Ipv6Settings.fetch/save()` | ✅ Complete | 6rd edge case known |
| **IPv6 WAN Status** | `wan_ipv6_addresses.yaml` | `WanIpv6Addresses.fetch()` | ✅ Complete | IPv6 address info |
| **VLAN Tagging** | `vlan_termination.yaml` | `VlanTermination.fetch/save()` | ✅ Complete | Enable + VLANID |
| **WAN Operations** | `wan_operations.yaml` | `renewDhcpLease/v6Lease()` | ✅ Complete | DHCP renew via operate |
| **PPP Interface** | `ppp_interface.yaml` | `PppInterface.fetch()` | ✅ Complete | PPP status display |
| **MAC Address Clone** | — | — | ❌ GAP | [#843](https://github.com/linksys/PrivacyGUI/issues/843) |
| **PPP Reset** | — | `Device.PPP.Interface.{i}.Reset()` | 🔵 Agent Only | TR-181 path exists |

---

### Local Network ✅ 100% Complete

> Advanced Settings → Local Network

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **LAN Configuration** | `lan_network_info.yaml` | `LanNetworkInfo.fetch/save()` | ✅ Complete | IP, subnet, DNS |
| **DHCP Server** | `lan_network_info.yaml` | `LanNetworkInfo.save()` | ✅ Complete | Range, lease time |
| **DHCP Clients** | `dhcp_clients.yaml` | `DhcpClients.fetch()` | ✅ Complete | Active leases |
| **DHCP Reservations** | `dhcp_reservations.yaml` | Full CRUD | ✅ Complete | Add/update/delete |

---

### Firewall ✅ 100% Complete

> Advanced Settings → Firewall

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Firewall Rules** | `firewall_chain_rules.yaml` | Full CRUD | ✅ Complete | SPI, filters |
| **VPN Passthrough** | `firewall_chain_rules.yaml` | Chain rules | ✅ Complete | IPSec, PPTP, L2TP |
| **DMZ** | `dmz.yaml` | `Dmz.fetch/update/add/delete()` | ✅ Complete | Full CRUD |
| **IPv6 Firewall** | `ipv6port_service.yaml` | Full CRUD | ✅ Complete | IPv6 port rules |

---

### Apps & Gaming (Port Forwarding) ✅ 75% Complete (3/4)

> Advanced Settings → Apps & Gaming (Port Forwarding in USP)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Single Port Forward** | `port_forwarding.yaml` | Full CRUD | ✅ Complete | TCP/UDP rules |
| **Port Range Forward** | `port_forwarding.yaml` | Full CRUD | ✅ Complete | Range support |
| **Port Triggering** | `port_triggering.yaml` | Full CRUD | ✅ Complete | Nested trigger rules |
| **DDNS** | — | — | ❌ GAP | [#641](https://github.com/linksys/PrivacyGUI/issues/641) |

**Note:** In JNAP version, this is under "Apps & Gaming" which includes Port Forwarding, Port Triggering, and DDNS.

---

### Static Routing ✅ 100% Complete

> Advanced Settings → Static Routing

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Static Routes** | `static_routing.yaml` | Full CRUD | ✅ Complete | Route management |

---

### Administration Settings ❌ USP Not Available

> Advanced Settings → Administration Settings (JNAP only)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Management Settings** | — | — | ❌ GAP | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| **UPnP Settings** | — | — | ❌ GAP | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| **ALG Settings** | — | — | ❌ GAP | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| **Express Forwarding** | — | — | ❌ GAP | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |

**Note:** This page in JNAP version uses `getManagementSettings`, `getUPnPSettings`, `getALGSettings`, `getExpressForwardingSettings`. None have TR-181 mapping.

---

### Speed Test ❌ USP Not Available

> Menu Card: "Speed Test" — Currently hidden (no USP implementation)

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Speed Test** | — | — | ❌ GAP | [#857](https://github.com/linksys/PrivacyGUI/issues/857) |
| **Health Check** | — | — | ❌ GAP | [#857](https://github.com/linksys/PrivacyGUI/issues/857) |
| **Speed History** | — | — | ❌ GAP | [#857](https://github.com/linksys/PrivacyGUI/issues/857) |

**Note:** Speed Test requires router-side bandwidth measurement not standardized in TR-181. Uses JNAP (`runHealthCheck`, `getHealthCheckStatus`, `getHealthCheckResults`).

---

## Standalone Features

### PnP (Initial Setup) ❌ USP Not Available

> First-time setup wizard — not a menu item, separate flow

| Feature | YAML Definition | USP Implementation | Status | Notes |
|---------|-----------------|-------------------|--------|-------|
| **Setup Wizard** | — | — | ❌ GAP | [#792](https://github.com/linksys/PrivacyGUI/issues/792) |
| **Internet Detection** | — | — | ❌ GAP | [#792](https://github.com/linksys/PrivacyGUI/issues/792) |
| **Initial FW Check** | — | — | ❌ GAP | [#792](https://github.com/linksys/PrivacyGUI/issues/792) |

**Note:** PnP requires orchestrated multi-step flow not standardized in TR-181. Uses JNAP for setup detection and WAN type probing.

---

## Out of Scope (11 features)

These features are intentionally excluded from USP v2 scope. They remain JNAP-only or require separate architectural decisions.

| Feature | Reason | Alternative |
|---------|--------|-------------|
| **System Log** | Only lists filenames, no download/view | Limited utility |
| **VPN** | No TR-181 spec, enterprise feature | JNAP `settingsVPN` |
| **Dual WAN** | Not in TR-181, hardware-specific | JNAP implementation |
| **Parental Controls** | Cloud-based content filtering | Linksys Shield / JNAP |
| **Backup & Restore** | Config file format proprietary | JNAP implementation |
| **Link Aggregation** | Hardware-specific, limited models | JNAP implementation |
| **Remote Management** | Requires cloud authentication | Separate cloud architecture |
| **Smart Connect** | Linksys proprietary band steering | JNAP implementation |
| **Channel Scanner** | Active scanning, hardware-specific | JNAP implementation |
| **QoS** | Agent fault 9005, complex rules | JNAP implementation |
| **WiFi Scheduling** | No TR-181 scheduler model | JNAP implementation |

---

## Features by Status

### ✅ Complete (54 features)

<details>
<summary>Click to expand full list</summary>

| Feature | Category | YAML |
|---------|----------|------|
| System Info Card | Dashboard | `system_info.yaml` |
| Network Status Card | Dashboard | `wan_status.yaml` |
| System Status Card | Dashboard | `system_info.yaml` |
| Ethernet Ports Card | Dashboard | `ethernet_interfaces.yaml` |
| Connected Devices Card | Dashboard | `connected_devices.yaml` |
| WiFi Status Card | Dashboard | `wi_fi_radios.yaml` |
| Traffic Monitor Card | Dashboard | `wan_traffic_stats.yaml` |
| Time Settings Card | Dashboard | `time_settings.yaml` |
| Radio Control | WiFi Settings | `wi_fi_radios.yaml` |
| SSID Management | WiFi Settings | `wi_fi_ssids.yaml` |
| Security Settings | WiFi Settings | `wi_fi_access_points.yaml` |
| Guest Network | WiFi Settings | Multi-SSID |
| MAC Address Filter | WiFi Settings | `mac_filter_access_points.yaml` |
| Channel Bonding | WiFi Settings | `wi_fi_radios.yaml` |
| WiFi Password | WiFi Settings | `wi_fi_access_points.yaml` |
| DFS (IEEE 802.11h) | WiFi Settings | `wi_fi_radios.yaml` |
| Network Topology | Topology | `data_elements_network.yaml` |
| Device List | Devices | `connected_devices.yaml` |
| WiFi Client Info | Devices | `wifi_clients.yaml` |
| Safe Browsing | Instant Safety | `lan_network_info.yaml` |
| MAC Filter Block | Instant Privacy | `mac_filter_access_points.yaml` |
| Timezone | Instant Admin | `time_settings.yaml` |
| Manual Firmware Info | Instant Admin | `firmware_images.yaml` |
| Reboot | Instant Admin | Direct operate |
| Factory Reset | Instant Admin | Direct operate |
| Ping | Instant Verify | `network_diagnostics.yaml` |
| Traceroute | Instant Verify | `network_diagnostics.yaml` |
| Traffic Analysis | Statistics | `multi_interface_traffic_stats.yaml` |
| WiFi Analytics | Statistics | `wifi_clients.yaml` |
| System Monitoring | Statistics | `system_info.yaml` |
| PDF Reports | Statistics | Multiple sources |
| Connection Status | Internet Settings | `wan_status.yaml` |
| DHCP Configuration | Internet Settings | `wan_dhcp.yaml` |
| Static IP Setup | Internet Settings | `wan_static_ip.yaml` |
| PPPoE Configuration | Internet Settings | `wan_pppoe.yaml` |
| Bridge Mode | Internet Settings | `wan_bridge.yaml` |
| MTU Configuration | Internet Settings | `wan_settings.yaml` |
| IPv6 Settings | Internet Settings | `ipv6_settings.yaml` |
| IPv6 WAN Status | Internet Settings | `wan_ipv6_addresses.yaml` |
| VLAN Tagging | Internet Settings | `vlan_termination.yaml` |
| WAN Operations | Internet Settings | `wan_operations.yaml` |
| PPP Interface | Internet Settings | `ppp_interface.yaml` |
| LAN Configuration | Local Network | `lan_network_info.yaml` |
| DHCP Server | Local Network | `lan_network_info.yaml` |
| DHCP Clients | Local Network | `dhcp_clients.yaml` |
| DHCP Reservations | Local Network | `dhcp_reservations.yaml` |
| Firewall Rules | Firewall | `firewall_chain_rules.yaml` |
| VPN Passthrough | Firewall | `firewall_chain_rules.yaml` |
| DMZ | Firewall | `dmz.yaml` |
| IPv6 Firewall | Firewall | `ipv6port_service.yaml` |
| Single Port Forward | Port Forwarding | `port_forwarding.yaml` |
| Port Range Forward | Port Forwarding | `port_forwarding.yaml` |
| Port Triggering | Port Forwarding | `port_triggering.yaml` |
| Static Routes | Static Routing | `static_routing.yaml` |

</details>

### 🔵 Agent Only (2 features)

| Feature | TR-181 Path | Category | Priority |
|---------|-------------|----------|----------|
| WPS | `Device.WiFi.AccessPoint.{i}.WPS.*` | WiFi Settings | P1 |
| PPP Reset | `Device.PPP.Interface.{i}.Reset()` | Internet Settings | P2 |

### ❌ GAP (26 features)

| Feature | Category | Issue |
|---------|----------|-------|
| Router Password | Instant Admin | [#874](https://github.com/linksys/PrivacyGUI/issues/874) |
| Password Hint | Instant Admin | [#874](https://github.com/linksys/PrivacyGUI/issues/874) |
| Auto Firmware Update | Instant Admin | [#841](https://github.com/linksys/PrivacyGUI/issues/841) |
| Client Steering | WiFi Settings | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| Node Steering | WiFi Settings | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| MLO | WiFi Settings | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| IPTV | WiFi Settings | [#856](https://github.com/linksys/PrivacyGUI/issues/856) |
| Add Mesh Nodes | Topology | [#879](https://github.com/linksys/PrivacyGUI/issues/879) |
| Reboot Child Node | Topology | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| Factory Reset Child | Topology | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| Blink Node LED | Topology | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| LED Night Mode | Topology | [#876](https://github.com/linksys/PrivacyGUI/issues/876) |
| Transmit Region | Instant Admin | [#878](https://github.com/linksys/PrivacyGUI/issues/878) |
| Client Deauth | Devices | [#877](https://github.com/linksys/PrivacyGUI/issues/877) |
| MAC Address Clone | Internet Settings | [#843](https://github.com/linksys/PrivacyGUI/issues/843) |
| DDNS | Apps & Gaming | [#641](https://github.com/linksys/PrivacyGUI/issues/641) |
| Management Settings | Administration Settings | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| UPnP Settings | Administration Settings | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| ALG Settings | Administration Settings | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| Express Forwarding | Administration Settings | [#875](https://github.com/linksys/PrivacyGUI/issues/875) |
| Speed Test | Speed Test | [#857](https://github.com/linksys/PrivacyGUI/issues/857) |
| Health Check | Speed Test | [#857](https://github.com/linksys/PrivacyGUI/issues/857) |
| Speed History | Speed Test | [#857](https://github.com/linksys/PrivacyGUI/issues/857) |
| Setup Wizard | PnP | [#792](https://github.com/linksys/PrivacyGUI/issues/792) |
| Internet Detection | PnP | [#792](https://github.com/linksys/PrivacyGUI/issues/792) |
| Initial FW Check | PnP | [#792](https://github.com/linksys/PrivacyGUI/issues/792) |

### ⬜ Out of Scope (11 features)

System Log, VPN, Dual WAN, Parental Controls, Backup & Restore, Link Aggregation, Remote Management, Smart Connect, Channel Scanner, QoS, WiFi Scheduling

---

## YAML Definition Inventory (36 files)

| Category | YAML Files |
|----------|-----------|
| **admin** | `admin_users` |
| **core** | `system_info`, `time_settings`, `vendor_log_files`, `firmware_images` |
| **devices** | `connected_devices`, `wifi_clients` |
| **firewall** | `dmz`, `firewall_chain_rules`, `ipv6port_service`, `port_forwarding`, `port_triggering` |
| **network** | `dhcp_clients`, `dhcp_reservations`, `ethernet_interfaces`, `ipv6_settings`, `lan_network_info`, `multi_interface_traffic_stats`, `ppp_interface`, `static_routing`, `vlan_termination`, `wan_bridge`, `wan_dhcp`, `wan_ipv6_addresses`, `wan_operations`, `wan_pppoe`, `wan_settings`, `wan_static_ip`, `wan_status`, `wan_traffic_stats`, `network_diagnostics` |
| **wifi** | `data_elements_network`, `mac_filter_access_points`, `wi_fi_access_points`, `wi_fi_radios`, `wi_fi_ssids` |

---

## Comparison: v1 vs v2 Structure

| Aspect | v1 (Functional) | v2 (Menu-Based) |
|--------|-----------------|-----------------|
| **Primary grouping** | Technical function | UI navigation |
| **Total in-scope** | 73 features | 62 features |
| **Complete rate** | 59 (81%) | 52 (84%) |
| **Categories** | 10 | 16 |
| **Benefit** | Technical tracking | User experience mapping |

**Note:** v2 has fewer features because some v1 items were aggregated (e.g., "WAN Status" and "Connection Status" are now one Dashboard card + one Internet Settings item, not duplicated across categories).

---

## JNAP Reference by Feature

> Reference for JNAP Actions used in hotfix implementation. Useful for USP migration investigation.

### Dashboard

| Feature | JNAP Actions |
|---------|--------------|
| System Info | `getDeviceInfo` |
| Network Status | `getWANStatus`, `getInternetConnectionStatus`, `getWANExternal` |
| System Stats | `getSystemStats` |
| Ethernet Ports | `getEthernetPortConnections` |
| Connected Devices | `getDevices`, `getNetworkConnections` |
| WiFi Status | `getRadioInfo`, `getGuestRadioSettings` |
| Time Settings | `getLocalTime` |

### WiFi Settings

| Feature | JNAP Actions |
|---------|--------------|
| Radio Control | `getRadioInfo`, `setRadioSettings`, `getSelectedChannels`, `startAutoChannelSelection` |
| SSID/Security | `getSimpleWiFiSettings`, `setSimpleWiFiSettings` |
| Guest Network | `getGuestRadioSettings`, `setGuestRadioSettings` |
| MAC Filter | `getMACFilterSettings`, `setMACFilterSettings` |
| DFS | `getDFSSettings`, `setDFSSettings` |
| Client Steering | `getAirtimeFairnessSettings`, `setAirtimeFairnessSettings` |
| Node Steering | `getTopologyOptimizationSettings`, `setTopologyOptimizationSettings` |
| MLO | `getMLOSettings`, `setMLOSettings` |
| IPTV | `getIptvSettings`, `setIptvSettings` |

### Topology

| Feature | JNAP Actions |
|---------|--------------|
| Network Topology | `getDevices`, `getBackhaulInfo`, `getNodesWirelessNetworkConnections` |
| Add Mesh Nodes (Wireless) | `getBluetoothAutoOnboardingSettings`, `setBluetoothAutoOnboardingSettings`, `getBluetoothAutoOnboardingStatus`, `startBlueboothAutoOnboarding`, `getDevices`, `getBackhaulInfo` |
| Add Mesh Nodes (Wired) | `getWiredAutoOnboardingSettings`, `setWiredAutoOnboardingSettings`, `getSmartConnectPin`, `getSmartConnectStatus`, `getBackhaulInfo`, `getDevices` |
| Reboot Child Node | `reboot`, `reboot2` |
| Factory Reset Child | `factoryReset`, `factoryReset2` |
| Blink Node LED | `startBlinkNodeLed`, `stopBlinkNodeLed` |
| LED Night Mode | `getLedNightModeSetting`, `setLedNightModeSetting` |

### Devices

| Feature | JNAP Actions |
|---------|--------------|
| Device List | `getDevices`, `getNetworkConnections` |
| WiFi Client Info | `getNodesWirelessNetworkConnections` |
| Client Deauth | `clientDeauth` |

### Instant Safety

| Feature | JNAP Actions |
|---------|--------------|
| Safe Browsing | `getDeviceInfo`, `getLANSettings`, `setLANSettings` |

### Instant Privacy

| Feature | JNAP Actions |
|---------|--------------|
| MAC Filter Block | `getLocalDevice`, `getMACFilterSettings`, `setMACFilterSettings`, `getSTABSSIDs` |

### Administration (Instant Admin)

| Feature | JNAP Actions |
|---------|--------------|
| Router Password | `isAdminPasswordDefault`, `isAdminPasswordSetByUser`, `coreSetAdminPassword`, `setupSetAdminPassword`, `verifyRouterResetCode` |
| Password Hint | `getAdminPasswordHint` |
| Timezone | `getTimeSettings`, `setTimeSettings` |
| Auto Firmware Update | `getFirmwareUpdateSettings`, `setFirmwareUpdateSettings`, `getFirmwareUpdateStatus`, `getNodesFirmwareUpdateStatus`, `nodesUpdateFirmwareNow` |
| Manual Firmware Update | `updateFirmwareNow` |
| Transmit Region | `getPowerTableSettings`, `setPowerTableSettings` |
| Reboot | `reboot`, `reboot2` |
| Factory Reset | `factoryReset`, `factoryReset2` |

### Instant Verify

| Feature | JNAP Actions |
|---------|--------------|
| Ping | `startPing`, `getPingStatus`, `stopPing` |
| Traceroute | `startTracroute`, `getTracerouteStatus`, `stopTracroute` |

### Speed Test (Health Check)

| Feature | JNAP Actions |
|---------|--------------|
| Speed Test | `runHealthCheck`, `getHealthCheckStatus`, `getHealthCheckResults`, `stopHealthCheck` |
| Health Check Servers | `getSupportedHealthCheckModules`, `getCloseHealthCheckServers` |

### Internet Settings

| Feature | JNAP Actions |
|---------|--------------|
| Connection Status | `getWANStatus`, `getInternetConnectionStatus` |
| WAN Configuration | `getWANSettings`, `setWANSettings` |
| IPv6 Settings | `getIPv6Settings`, `setIPv6Settings` |
| WAN Operations | `renewDHCPWANLease`, `renewDHCPIPv6WANLease` |
| PPP Interface | (uses `getWANStatus` for PPP status) |
| DDNS | `getDDNSSettings`, `setDDNSSetting`, `getDDNSStatus`, `getSupportedDDNSProviders` |
| MAC Address Clone | `getMACAddressCloneSettings`, `setMACAddressCloneSettings` |

### Local Network

| Feature | JNAP Actions |
|---------|--------------|
| LAN Configuration | `getLANSettings`, `setLANSettings`, `getLocalDevice` |
| DHCP Clients | `getDHCPClientLeases` |

### Firewall

| Feature | JNAP Actions |
|---------|--------------|
| Firewall Rules | `getFirewallSettings`, `setFirewallSettings` |
| DMZ | `getDMZSettings`, `setDMZSettings` |
| IPv6 Firewall | `getIPv6FirewallRules`, `setIPv6FirewallRules` |

### Apps & Gaming

| Feature | JNAP Actions |
|---------|--------------|
| Single Port Forward | `getSinglePortForwardingRules`, `setSinglePortForwardingRules` |
| Port Range Forward | `getPortRangeForwardingRules`, `setPortRangeForwardingRules` |
| Port Triggering | `getPortRangeTriggeringRules`, `setPortRangeTriggeringRules` |
| DDNS | `getDDNSSettings`, `setDDNSSetting`, `getDDNSStatus`, `getSupportedDDNSProviders` |

### Static Routing

| Feature | JNAP Actions |
|---------|--------------|
| Static Routes | `getRoutingSettings`, `setRoutingSettings` |

### Administration Settings

| Feature | JNAP Actions |
|---------|--------------|
| Management Settings | `getManagementSettings`, `setManagementSettings`, `setRemoteSetting` |
| UPnP Settings | `getUPnPSettings`, `setUPnPSettings` |
| ALG Settings | `getALGSettings`, `setALGSettings` |
| Express Forwarding | `getExpressForwardingSettings`, `setExpressForwardingSettings` |

### PnP (Initial Setup)

| Feature | JNAP Actions |
|---------|--------------|
| Setup Wizard | `getAutoConfigurationSettings`, `setUserAcknowledgedAutoConfiguration`, `pnpSetAdminPassword` |
| Internet Detection | `getInternetConnectionStatus`, `getWANStatus`, `getWANSettings` |
| WiFi Setup | `getSimpleWiFiSettings`, `setSimpleWiFiSettings`, `getGuestRadioSettings`, `setGuestRadioSettings`, `getRadioInfo` |
| Firmware Check | `getFirmwareUpdateSettings`, `setFirmwareUpdateSettings` |
| Device Mode | `getDeviceMode`, `setDeviceMode` |
| LED Settings | `getLedNightModeSetting`, `setLedNightModeSetting` |
| Bluetooth Onboarding | `getBluetoothAutoOnboardingSettings` |

### Troubleshooting

| Feature | JNAP Actions |
|---------|--------------|
| Device Info | `getDevices`, `getNodesWirelessNetworkConnections`, `getBackhaulInfo` |
| DHCP Clients | `getDHCPClientLeases` |
| Time Settings | `getTimeSettings` |
| Ping Test | `startPing`, `getPingStatus` |
| Factory Reset | `factoryReset` |
| Email SysInfo | `sendSysinfoEmail` |

### Out of Scope Features

| Feature | JNAP Actions |
|---------|--------------|
| VPN | `getVPNGateway`, `setVPNGateway`, `getVPNService`, `setVPNService`, `getVPNUser`, `setVPNUser`, `setVPNApply`, `testVPNConnection`, `getTunneledUser`, `setTunneledUser` |
| Smart Connect | `getSTABSSIDs` |
| Soft SKU | `getSoftSKUSettings` |

---

*This matrix reflects the actual implementation state as of May 12, 2026.*
*Structure based on `lib/page/menu/views/usp_menu_view.dart` and `lib/page/advanced_settings/views/usp_advanced_settings_view.dart`.*
