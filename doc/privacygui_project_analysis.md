# PrivacyGUI Project Analysis Report

## Project Overview

PrivacyGUI is the **Linksys Router Management Application (Flutter)**, a modern cross-platform (iOS, Android, Web) router management app for managing Linksys routers (including Velop Mesh systems).

---

## Technical Architecture

### Technology Stack
| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.x |
| **State Management** | Riverpod |
| **Routing** | go_router |
| **API Communication** | JNAP (JSON Network Access Protocol) |
| **Cloud Services** | Linksys Cloud API |
| **Dependency Injection** | Riverpod + GetIt |
| **Local Storage** | SharedPreferences |
| **UI Component Library** | Custom ui_kit_library |

### Directory Structure
```
lib/
├── ai/                    # AI Assistant features
├── constants/             # Constant definitions
├── core/                  # Core service layer
│   ├── bluetooth/         # Bluetooth (for node pairing)
│   ├── cache/             # Cache management
│   ├── cloud/             # Cloud services (Linksys Cloud API)
│   ├── http/              # HTTP client
│   ├── jnap/              # JNAP API layer (core)
│   └── usp/               # USP protocol support
├── page/                  # Page modules (21)
├── providers/             # Global Providers
├── route/                 # Route definitions
├── theme/                 # Theme settings
├── util/                  # Utility functions
└── validator_rules/       # Validation rules
```

---

## Main Feature Modules

### 1. Login & Authentication

**Directory**: `lib/page/login/`

| Feature | Description |
|---------|-------------|
| **Cloud Login** | Login with Linksys account (phone/email) |
| **Local Login** | Login with router admin password |
| **Remote Access** | Manage router remotely via cloud |
| **Router Recovery** | Password recovery flow |
| **OTP Verification** | Two-factor authentication support |

---

### 2. Dashboard

**Directory**: `lib/page/dashboard/`

| Component | Description |
|-----------|-------------|
| **Home View** | Main page showing network status, WiFi info, connected devices |
| **Menu View** | Feature menu with entry points to all modules |
| **Support View** | Support page with FAQ, customer service |
| **AI Assistant** | AI assistant feature (in development) |

#### Dashboard Components:
- **Network Status Card** - Shows network connection status
- **WiFi Info Panel** - Displays WiFi name, password
- **Port Status** - Shows WAN/LAN connection status
- **Speed Test Shortcut** - Quick access to speed test
- **Device Count** - Shows number of connected devices

---

### 3. Instant* Feature Series

#### 3.1 Instant Verify (Network Diagnostics)
**Directory**: `lib/page/instant_verify/`

| Feature | Description |
|---------|-------------|
| **Speed Test** | Measure upload/download speeds |
| **Connection Diagnostics** | Check network connection status |
| **Port Status Detection** | Check all port connections |

#### 3.2 Instant Devices (Device Management)
**Directory**: `lib/page/instant_device/`

| Feature | Description |
|---------|-------------|
| **Device List** | Display all connected devices |
| **Device Details** | View device info (IP, MAC, connection type) |
| **Device Editing** | Modify device name, icon |
| **Connection Restrictions** | Set device access permissions |

#### 3.3 Instant Topology (Network Topology)
**Directory**: `lib/page/instant_topology/`

| Feature | Description |
|---------|-------------|
| **Topology Visualization** | Display network node connections |
| **Node Information** | View each node's status |
| **Connection Quality** | Show inter-node connection quality |

#### 3.4 Instant Admin (Administration)
**Directory**: `lib/page/instant_admin/`

| Feature | Description |
|---------|-------------|
| **Account Info** | Display Linksys account information |
| **Two-Factor Auth** | Configure 2FA |
| **Timezone Settings** | Set router timezone |
| **Notification Settings** | Configure push notifications |

#### 3.5 Instant Safety (Network Security)
**Directory**: `lib/page/instant_safety/`

| Feature | Description |
|---------|-------------|
| **Safe Browsing** | Safe Browsing configuration |
| **Parental Control** | Device access time control |

#### 3.6 Instant Privacy (Privacy Settings)
**Directory**: `lib/page/instant_privacy/`

| Feature | Description |
|---------|-------------|
| **Guest Access** | Guest network settings |
| **Privacy Settings** | Various privacy configurations |

---

### 4. WiFi Settings

**Directory**: `lib/page/wifi_settings/`

| Tab | Description |
|-----|-------------|
| **Main** | Basic WiFi settings (SSID, password, security) |
| **Share** | WiFi sharing (QR Code, text sharing) |
| **Advanced** | Advanced settings (channel, bandwidth, power) |
| **MAC Filter** | MAC address filtering |
| **Channel Finder** | Best channel search |

#### WiFi Configuration Items:
- **SSID** - WiFi name
- **Password** - WiFi password
- **Security Mode** - WPA2/WPA3
- **Band Steering** - Band steering
- **Channel** - Channel selection
- **Bandwidth** - 20/40/80/160 MHz
- **Transmission Power** - TX power

---

### 5. Node Management

**Directory**: `lib/page/nodes/`

| Feature | Description |
|---------|-------------|
| **Node Details** | View node status, connected devices |
| **Node Name** | Modify node name |
| **Node Light** | Configure node LED light |
| **Add Nodes** | Pair new nodes via Bluetooth |
| **Firmware Update** | Node firmware updates |

---

### 6. Advanced Settings

**Directory**: `lib/page/advanced_settings/`

#### 6.1 Internet Settings
| Feature | Description |
|---------|-------------|
| **Connection Type** | DHCP, Static IP, PPPoE, PPTP, L2TP, Bridge |
| **IPv4 Settings** | IPv4 address configuration |
| **IPv6 Settings** | IPv6 address configuration |
| **MAC Clone** | MAC address cloning |
| **MTU** | MTU settings |

#### 6.2 Local Network Settings
| Feature | Description |
|---------|-------------|
| **Router IP** | Set router IP address |
| **DHCP Server** | DHCP server settings |
| **DHCP Reservation** | DHCP IP reservation |
| **Subnet Mask** | Subnet mask configuration |

#### 6.3 Firewall
| Feature | Description |
|---------|-------------|
| **Firewall Toggle** | Enable/disable firewall |
| **VPN Passthrough** | VPN passthrough (IPSec, L2TP, PPTP) |
| **IPv6 Firewall** | IPv6 firewall rules |
| **Filter Settings** | Packet filter settings |

#### 6.4 DMZ
| Feature | Description |
|---------|-------------|
| **DMZ Toggle** | Enable/disable DMZ |
| **DMZ Host** | Set DMZ host IP |
| **Source Restrictions** | Set allowed sources |

#### 6.5 Apps and Gaming (Port Forwarding)
| Feature | Description |
|---------|-------------|
| **Single Port Forwarding** | Single port forwarding |
| **Port Range Forwarding** | Port range forwarding |
| **Port Range Triggering** | Port triggering |
| **IPv6 Port Service** | IPv6 port services |
| **DDNS** | Dynamic DNS settings |
| **UPnP** | UPnP settings |

#### 6.6 Static Routing
| Feature | Description |
|---------|-------------|
| **Static Route List** | Display all static routes |
| **Add Route** | Add static routing rules |
| **Edit/Delete** | Modify or delete routes |

#### 6.7 Administration
| Feature | Description |
|---------|-------------|
| **Admin Password** | Change router admin password |
| **Remote Management** | Enable/disable remote management |
| **Express Forwarding** | CTF settings |
| **Admin Port** | Set management interface port |

---

### 7. VPN Settings

**Directory**: `lib/page/vpn/`

| Feature | Description |
|---------|-------------|
| **OpenVPN Server** | OpenVPN server configuration |
| **VPN Profile** | Download VPN connection profile |
| **Connection Info** | Display VPN connection info |

---

### 8. Speed Test (Health Check)

**Directory**: `lib/page/health_check/`

| Feature | Description |
|---------|-------------|
| **Server Selection** | Select speed test server |
| **Speed Test** | Run upload/download speed test |
| **Results Display** | Show test results |
| **History** | View test history |

---

### 9. Firmware Update

**Directory**: `lib/page/firmware_update/`

| Feature | Description |
|---------|-------------|
| **Update Check** | Check for firmware updates |
| **Auto Update** | Configure auto updates |
| **Manual Update** | Upload firmware manually |
| **Update Progress** | Show update progress |

---

### 10. PnP Setup (Plug and Play)

**Directory**: `lib/page/instant_setup/`

#### Setup Flow:
1. **pnp** - Start page
2. **pnpConfig** - Basic configuration
3. **pnpNoInternetConnection** - Handle no internet
4. **pnpUnplugModem** - Unplug modem
5. **pnpModemLightsOff** - Wait for modem lights
6. **pnpWaitingModem** - Wait for modem connection
7. **pnpIspTypeSelection** - ISP type selection
8. **pnpPPPOE** - PPPoE configuration
9. **pnpStaticIp** - Static IP configuration
10. **pnpIspAuth** - ISP authentication
11. **pnpAddNodes** - Add nodes

---

### 11. Support

**Directory**: `lib/page/support/`

| Feature | Description |
|---------|-------------|
| **FAQ List** | Frequently asked questions |
| **Phone Support** | Regional customer service numbers |
| **Callback Booking** | Schedule customer service callback |

---

## Core Service Layer

### JNAP API Layer
**Directory**: `lib/core/jnap/`

#### Data Models (55):
| Category | Models |
|----------|--------|
| **Device** | device.dart, device_info.dart |
| **Network** | wan_settings.dart, wan_status.dart, lan_settings.dart |
| **Wireless** | radio_info.dart, guest_radio_settings.dart |
| **Firewall** | firewall_settings.dart, dmz_settings.dart |
| **Port Forwarding** | single_port_forwarding_rule.dart, port_range_forwarding_rule.dart |
| **DHCP** | dhcp_lease.dart, set_lan_settings.dart |
| **Firmware** | firmware_update_settings.dart, firmware_update_status.dart |
| **Routing** | get_routing_settings.dart, advanced_routing_rule.dart |
| **Other** | health_check_result.dart, ddns_settings_model.dart, timezone.dart |

#### Main Services:
- `router_repository.dart` - Router data access layer
- `jnap_command_queue.dart` - JNAP command queue
- `jnap_command_executor_mixin.dart` - JNAP command executor

### Cloud API Layer
**Directory**: `lib/core/cloud/`

| Service | Description |
|---------|-------------|
| **linksys_cloud_repository.dart** | Cloud API access layer |
| **linksys_device_cloud_service.dart** | Device cloud service |

---

## Global Providers

**Directory**: `lib/providers/`

| Provider | Description |
|----------|-------------|
| **auth/** | Authentication state management |
| **connectivity/** | Connection state management |
| **app_settings/** | Application settings |
| **redirection/** | Route redirection |

---

## Route Definitions

**Directory**: `lib/route/`

### Main Route Blocks:

| Block | Routes |
|-------|--------|
| **Login** | cloudLoginAccount, localLoginPassword, otpStart |
| **Dashboard** | dashboardHome, dashboardMenu, dashboardSupport, dashboardAiAssistant |
| **Menu Features** | menuInstantVerify, menuInstantDevices, menuIncredibleWiFi, menuInstantTopology, menuInstantAdmin, menuInstantSafety, menuInstantPrivacy, menuAdvancedSettings |
| **Settings** | settingsLocalNetwork, settingsAppsGaming, settingsFirewall, settingsDMZ, settingsAdministration, settingsStaticRouting, settingsVPN |
| **WiFi** | wifiSettingsReview, wifiShare, wifiShareDetails, wifiAdvancedSettings |
| **Node** | nodeDetails, nodeLight, addNodes, firmwareUpdateDetail |
| **PnP** | pnp, pnpConfig, pnpNoInternetConnection... |

---

## Testing Architecture

**Directory**: `test/`

- **Unit Tests** - Core logic tests
- **Widget Tests** - UI component tests
- **Golden Tests** - Visual regression tests
- **Integration Tests** - End-to-end tests

---

## Custom Packages

**Directory**: `packages/`

| Package | Description |
|---------|-------------|
| **ui_kit_library** | Custom UI component library |
| **generative_ui** | Generative UI components |
| **jnap_api** | JNAP API client |

---

## Summary

PrivacyGUI is a complete, well-architected Flutter cross-platform router management application:

- **21 page modules** covering all router management features
- **55 JNAP data models** supporting complete API communication
- **Local and cloud mode support** for flexible access
- **Modular architecture** using Riverpod for state management
- **Complete setup flow (PnP)** guiding users through router setup
- **AI assistant feature** providing smart support (in development)

### Correspondence with Master Project

| PrivacyGUI Feature | Master Project Equivalent |
|-------------------|--------------------------|
| Instant Devices | Device List Applet |
| Incredible WiFi | Wireless Applet |
| Instant Topology | Device Map Applet |
| Speed Test | Speed Test Applet |
| Advanced Settings | Connectivity Applet |
| Firewall/DMZ/Ports | Security Applet |
| VPN | OpenVPN Applet |
