# LSWF vs PrivacyGUI Feature Comparison Report

## Overview

This report compares the features between **LSWF (Linksys Smart WiFi Router Web UI)** and **PrivacyGUI (Flutter App)**.

| Item | LSWF (Master Project) | PrivacyGUI |
|------|----------------------|------------|
| **Type** | Web Application | Flutter Cross-platform App |
| **Tech Stack** | jQuery + Vanilla JS | Flutter + Riverpod |
| **Platform** | Browser (Desktop/Mobile) | iOS, Android, Web |
| **API** | JNAP (HTTP) | JNAP + Linksys Cloud API |
| **Feature Modules** | 18 | 21 |

---

## Feature Completeness Comparison

### ✅ Features Available in Both

| Feature Category | LSWF | PrivacyGUI | Notes |
|-----------------|------|------------|-------|
| **Login/Authentication** | ✅ Complete | ✅ Complete | Both support cloud and local login |
| **Dashboard** | ✅ Widget system | ✅ Dashboard | Different architecture, similar function |
| **Device List** | ✅ Device List | ✅ Instant Devices | Similar functionality |
| **Network Topology** | ✅ Device Map | ✅ Instant Topology | Visualization |
| **WiFi Settings** | ✅ Wireless | ✅ Incredible WiFi | Core features same |
| **WiFi Advanced Settings** | ✅ Advanced | ✅ WiFi Advanced Settings | **Both have it** |
| **Guest Network** | ✅ Guest Access | ✅ Instant Privacy | Similar functionality |
| **Speed Test** | ✅ Speed Test | ✅ Health Check | Same functionality |
| **Firewall** | ✅ Security/Firewall | ✅ Firewall | Same functionality |
| **DMZ** | ✅ Security/DMZ | ✅ DMZ | Same functionality |
| **Port Forwarding** | ✅ Security | ✅ Apps & Gaming | Same functionality |
| **VPN** | ✅ OpenVPN | ✅ VPN Settings | Same functionality |
| **Firmware Update** | ✅ Connectivity | ✅ Firmware Update | Same functionality |
| **Node Management** | ✅ Velop pages | ✅ Nodes | Mesh node management |
| **DDNS** | ✅ Security/DDNS | ✅ DDNS Settings | Same functionality |
| **Static Routing** | ✅ Advanced Routing | ✅ Static Routing | Same functionality |
| **DHCP Settings** | ✅ Local Network | ✅ Local Network | Same functionality |
| **Timezone** | ✅ Connectivity | ✅ Instant Admin | Same functionality |
| **MAC Filtering** | ✅ Wireless/MAC Filtering | ✅ MAC Filter | Same functionality |

---

## 🔴 LSWF-Only Features (Missing in PrivacyGUI)

### 1. Parental Controls

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **Device Access Scheduling** | ✅ Complete | ❌ Not implemented |
| **Website Blocking** | ✅ Complete | ❌ Not implemented |
| **Weekly Schedule** | ✅ Visual selector | ❌ Not implemented |

---

### 2. Media Prioritization / QoS

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **QoS Toggle** | ✅ | ❌ Not implemented |
| **Device Priority** | ✅ Drag-drop sorting | ❌ Not implemented |
| **Application Priority** | ✅ | ❌ Not implemented |
| **Gaming Priority** | ✅ | ❌ Not implemented |
| **Bandwidth Settings** | ✅ Auto/Manual | ❌ Not implemented |
| **WMM Settings** | ✅ | ❌ Not implemented |
| **LVVP** | ✅ | ❌ Not implemented |

---

### 3. External Storage / USB Storage

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **Storage Device List** | ✅ | ❌ Not implemented |
| **FTP Server Settings** | ✅ | ❌ Not implemented |
| **SMB Server Settings** | ✅ | ❌ Not implemented |
| **Media Server** | ✅ | ❌ Not implemented |
| **USB Printer** | ✅ VUSB | ❌ Not implemented |
| **Safe Removal** | ✅ | ❌ Not implemented |

---

### 4. WPS (WiFi Protected Setup)

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **Push Button** | ✅ | ❌ Not implemented |
| **Router PIN** | ✅ | ❌ Not implemented |
| **Device PIN** | ✅ | ❌ Not implemented |

---

### 5. Wireless Scheduler

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **WiFi On/Off Schedule** | ✅ | ❌ Not implemented |
| **Weekly Schedule** | ✅ | ❌ Not implemented |

---

### 6. SimpleTap (NFC)

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **NFC WiFi Connection** | ✅ | ❌ Not implemented |

---

### 7. VLAN Tagging

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **Independent VLAN Settings Page** | ✅ Dedicated page | ❌ No dedicated page |
| **PPPoE over VLAN** | ✅ | ✅ **Implemented** (PnP Flow) |
| **VLAN API Support** | ✅ | ✅ `getVLANTaggingSettings`/`setVLANTaggingSettings` available |

> **Confirmation**: PrivacyGUI has `SinglePortVLANTaggingSettings` model in `wan_settings.dart` and supports VLAN ID in the PnP setup flow for PPPoE. However, it lacks a dedicated VLAN settings page like LSWF.

---

### 8. Power Modem (DSL)

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **DSL Modem Settings** | ✅ | ❌ Not implemented |
| **DSL Firmware Update** | ✅ | ❌ Not implemented |

---

### 9. Advanced Wireless Settings

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **Airtime Fairness (ATF)** | ✅ | ❌ Not implemented |
| **Dynamic Frequency Selection (DFS)** | ✅ | ✅ **Implemented** |
| **Multi-Link Operation (MLO)** | ✅ | ✅ **Implemented** |
| **Client Steering** | ✅ | ✅ **Implemented** |
| **Node Steering** | ✅ | ✅ **Implemented** |
| **IPTV Configuration** | ✅ | ✅ **Implemented** |

> **Confirmation**: PrivacyGUI's `wifi_advanced_settings_view.dart` implements Client Steering, Node Steering, DFS, MLO, and IPTV configuration. Only ATF is missing.

---

### 10. Troubleshooting Tools

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **System Status Page** | ✅ Complete | ❌ Not implemented |
| **Ping Test** | ✅ | ⚠️ API defined (`PingStatus`), UI partial |
| **Traceroute Test** | ✅ | ⚠️ API defined (`TracerouteStatus`), UI partial |
| **Configuration Backup/Restore** | ✅ | ❌ Not implemented |
| **Restore Previous Firmware** | ✅ | ❌ Not implemented |
| **System Logs** | ✅ | ❌ Not implemented |
| **Scheduled Reboot** | ✅ | ❌ Not implemented |

> **Confirmation**: PrivacyGUI has `PingStatus` and `TracerouteStatus` JNAP models and APIs, but the UI is only partially utilized in the PnP troubleshooter.

---

### 11. HomeKit Integration

| Feature | LSWF | PrivacyGUI Status |
|---------|------|-------------------|
| **HomeKit Settings** | ✅ | ❌ Not implemented |

---

## 🔵 PrivacyGUI-Only Features (Not in LSWF)

### 1. AI Assistant

| Feature | PrivacyGUI | LSWF Status |
|---------|------------|-------------|
| **AI Assistant** | ✅ (In development) | ❌ None |

---

### 2. Channel Finder

| Feature | PrivacyGUI | LSWF Status |
|---------|------------|-------------|
| **Best Channel Search** | ✅ channelFinderOptimize | ❌ No standalone feature |

---

### 3. WiFi Sharing

| Feature | PrivacyGUI | LSWF Status |
|---------|------------|-------------|
| **QR Code Sharing** | ✅ wifiShare | ❌ None |
| **Text Sharing** | ✅ | ❌ None |

---

### 4. Node Light Settings

| Feature | PrivacyGUI | LSWF Status |
|---------|------------|-------------|
| **LED Light Control** | ✅ nodeLightSettings | ⚠️ Activity Lights toggle only |

---

### 5. Notification Settings

| Feature | PrivacyGUI | LSWF Status |
|---------|------------|-------------|
| **Push Notification Settings** | ✅ settingsNotification | ❌ None (Web has no native push) |

---

### 6. Bluetooth Node Pairing

| Feature | PrivacyGUI | LSWF Status |
|---------|------------|-------------|
| **Bluetooth Pairing Flow** | ✅ core/bluetooth | ⚠️ Indirect support via JNAP |

---

## Feature Coverage Comparison

### LSWF Coverage

```
Total Feature Modules: 18
Implemented: 18 (100%)
```

### PrivacyGUI Coverage (Relative to LSWF)

```
LSWF Total Features: 18
PrivacyGUI Covered: 11 (61%)
PrivacyGUI Missing: 7 (39%)
```

### Major Missing Modules:

1. ⚠️ **Parental Controls**
2. ⚠️ **Media Prioritization / QoS**
3. ⚠️ **External Storage / USB Storage**
4. ⚠️ **Troubleshooting**
5. ⚠️ **WPS**
6. ⚠️ **Wireless Scheduler**
7. ⚠️ **VLAN Tagging**

---

## JNAP API Usage Comparison

### JNAP APIs Used by PrivacyGUI (55 models)

| Category | API Usage |
|----------|-----------|
| Core | ✅ GetDeviceInfo, SetAdminPassword, Reboot |
| Router | ✅ LANSettings, WANSettings, WANStatus, DHCPClientLeases |
| Wireless | ✅ RadioInfo, RadioSettings |
| Device List | ✅ GetDevices, SetDeviceProperties |
| Firewall | ✅ FirewallSettings, DMZSettings, PortForwarding |
| Health Check | ✅ HealthCheckResults |
| Firmware | ✅ FirmwareUpdateSettings, FirmwareUpdateStatus |

### JNAP APIs Not Used by PrivacyGUI

| Category | Missing APIs |
|----------|--------------|
| **QoS** | GetQoSSettings, SetQoSSettings, LVVP |
| **Parental Control** | GetParentalControlSettings, SetParentalControlSettings |
| **Storage** | FTPServerSettings, SMBServerSettings, MediaServer |
| **WPS** | StartWPSServerSession, GetWPSServerSessionStatus |
| **VLAN** | GetVLANTaggingSettings, SetVLANTaggingSettings |
| **HomeKit** | GetHomeKitSettings, SetHomeKitSettings |
| **Diagnostics** | StartPing, StartTraceroute, GetPingStatus |
| **Configuration** | GetConfigurationBackup, RestoreConfiguration |
| **ATF/DFS/MLO** | Advanced wireless settings APIs |

---

## Recommended Implementation Priority

### High Priority (Common User Needs)

| Priority | Feature | Reason |
|----------|---------|--------|
| 1 | **Parental Controls** | Commonly used, competitors have it |
| 2 | **QoS / Media Prioritization** | High demand from advanced users |
| 3 | **Troubleshooting Tools** | Reduces support burden |

### Medium Priority (Specific Scenarios)

| Priority | Feature | Reason |
|----------|---------|--------|
| 4 | **USB Storage** | Needed for routers with USB ports |
| 5 | **WPS** | Simplifies device connection |
| 6 | **Wireless Scheduler** | Energy saving/control needs |

### Low Priority (Advanced Features)

| Priority | Feature | Reason |
|----------|---------|--------|
| 7 | **VLAN Tagging** | Enterprise/advanced users |
| 8 | **Advanced Wireless (ATF/DFS/MLO)** | Professional users |
| 9 | **HomeKit** | Apple ecosystem integration |
| 10 | **SimpleTap (NFC)** | Specific hardware support |

---

## Summary

| Metric | LSWF | PrivacyGUI |
|--------|------|------------|
| **Feature Completeness** | 100% | ~61% |
| **Platform Support** | Web Only | iOS, Android, Web |
| **User Experience** | Traditional Web UI | Modern App |
| **Offline Support** | ❌ | ⚠️ Partial |
| **Cloud Integration** | ⚠️ Limited | ✅ Complete |
| **AI Features** | ❌ | ✅ In development |

### Key Gaps

PrivacyGUI lacks the following feature categories compared to LSWF:

1. **Control Features**: Parental Controls, QoS
2. **Hardware Features**: USB Storage, WPS
3. **Diagnostic Features**: Troubleshooting Tools
4. **Advanced Features**: VLAN, Advanced Wireless Settings

These features are fully implemented in LSWF and should be progressively added to PrivacyGUI to achieve feature parity.
