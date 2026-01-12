# Master Project Analysis Report

## Project Overview

The Master project is the **Linksys Smart WiFi Router Web UI**, a web-based router management interface for managing Linksys routers (including Velop Mesh systems).

---

## Directory Structure

```
master/
├── backend/           # Backend static resources
│   ├── images/
│   └── ustatic/      # USB drivers and user static files
│
└── rainier/          # Main web application
    ├── dynamic/      # Dynamic pages (HTML templates)
    ├── static/       # Static resources (JS, CSS, images)
    ├── ustatic/      # User static resources
    ├── hdk2/         # HDK2 related files
    ├── root/         # Root directory related
    └── tools/        # Build tools
```

---

## Main Functional Modules (Applets) - Detailed Analysis

The project contains **18 main functional modules**. Below are the detailed sub-features for each module:

---

### 1. Connectivity (Network Connection Settings)
**File**: connectivity.js (4,598 lines)

#### Sub-Feature Tabs:
| Tab | Description |
|-----|-------------|
| **Internet Settings** | IPv4/IPv6 connection type configuration |
| **Local Network** | LAN settings (IP, DHCP) |
| **VLAN Tagging** | VLAN tagging configuration |
| **Advanced Routing** | Advanced routing table settings |
| **Administration** | Administrative settings |
| **Power Modem** | DSL Modem settings |

#### Supported Internet Connection Types:
- `DHCP` - Automatic IP assignment
- `Static` - Static IP
- `PPPoE` - PPPoE dial-up
- `PPTP` - PPTP VPN
- `L2TP` - L2TP VPN
- `Bridge` - Bridge mode
- `WirelessRepeater` - Wireless repeater
- `WirelessBridge` - Wireless bridge

#### Other Features:
- Firmware update (automatic/manual)
- Timezone settings
- Router password management
- MAC Address Clone
- MTU settings
- Activity Lights toggle

---

### 2. Device List
**File**: device-list.js

#### Sub-Features:
- **My Network** - Connected device list
- **Guest Network** - Guest network devices
- **Device Info Editing** - Name, icon customization
- **WPS Device Addition** - Push Button / PIN method
- **Add Computer/Other Devices** - Display WiFi connection info
- **USB Printer Setup** - VUSB software download
- **Clear Device List** - Reset all device information

#### Supported Device Icons (55+ types):
Desktop, Laptop, Smartphone, Tablet, Game Console, Smart TV, Smart Speaker, Camera, Drone, Robot, Smart Watch, VR Headset, 3D Printer, etc.

---

### 3. Device Map
**File**: smartmap.js

#### Sub-Features:
- Network topology visualization
- Node connection status display
- Interactive device information viewing
- MVC architecture (Models/Views)

---

### 4. Wireless (WiFi Settings)
**File**: wireless.js

#### Sub-Feature Tabs:
| Tab | Description |
|-----|-------------|
| **Wireless** | Basic WiFi settings |
| **WiFi Protected Setup** | WPS settings |
| **MAC Filtering** | MAC address filtering |
| **SimpleTap** | NFC connection feature |
| **Wireless Scheduler** | WiFi scheduling |
| **Advanced** | Advanced wireless settings |

#### Basic Wireless Settings:
- SSID (WiFi name)
- WiFi password
- Security mode (WPA2/WPA3)
- Band Steering
- Channel selection
- Bandwidth settings

#### WPS Features:
- Push Button connection
- Router PIN
- Device PIN registration

#### Advanced Settings:
- **Airtime Fairness (ATF)** - Fair bandwidth allocation
- **Dynamic Frequency Selection (DFS)** - Dynamic frequency selection
- **Multi-Link Operation (MLO)** - Multi-link operation
- **Client Steering** - Client steering
- **Node Steering** - Node steering
- **IPTV Configuration** - IPTV settings

---

### 5. Guest Access (Guest Network)
**File**: guest-access.js (337 lines)

#### Sub-Features:
- Guest network toggle
- Guest SSID settings
- Guest password settings
- Maximum simultaneous guests
- 2.4GHz / 5GHz band selection

---

### 6. Parental Controls
**File**: parental-controls.js (706 lines)

#### Sub-Features:
- **Device Selection** - Select devices to control
- **Internet Access Time Scheduling** - Set online hours
  - Never (always blocked)
  - Always (always allowed)
  - Custom (custom schedule)
- **Website Blocking** - Block specific websites
- **Weekly Schedule** - Visual time selector

---

### 7. Media Prioritization
**File**: media-prioritization.js (2,161 lines)

#### Sub-Features:
- **QoS Toggle** - Enable/disable Quality of Service
- **High Priority Group** - Set priority devices
- **Device Priority** - Drag-and-drop device ordering
- **Application Priority** - Set application rules
- **Game Priority** - Online gaming optimization

#### QoS Parameters:
- Bandwidth settings (auto/manual)
- Priority levels: Background, Generic, Voice, Video
- WMM settings
- LVVP (LAN Voice and Video Prioritization)

---

### 8. Speed Test
**File**: speed-test.js (409 lines)

#### Sub-Features:
- Server selection
- Download speed test
- Upload speed test
- Test progress animation
- Test results display

---

### 9. Security Settings
**File**: security.js (1,755 lines)

#### Sub-Feature Tabs:
| Tab | Description |
|-----|-------------|
| **Firewall** | Firewall settings |
| **IPv6 Firewall Rules** | IPv6 firewall rules |
| **DMZ** | DMZ host settings |
| **Single Port Forwarding** | Single port forwarding |
| **Port Range Forwarding** | Port range forwarding |
| **Port Range Triggering** | Port triggering |
| **DDNS** | Dynamic DNS settings |

#### Firewall Settings:
- Firewall toggle
- VPN Passthrough
- Filter rules

#### Port Forwarding Settings:
- Application name
- External port
- Internal port
- Protocol (TCP/UDP/Both)
- Destination IP

---

### 10. Troubleshooting
**File**: troubleshooting.js (2,171 lines)

#### Sub-Feature Tabs:
| Tab | Description |
|-----|-------------|
| **Status** | System status display |
| **Diagnostics** | Diagnostic tools |
| **Logs** | System logs |

#### Status Information:
- Router info (model, firmware version, serial number)
- WAN status (IP, connection type, MAC)
- WiFi status (all band information)
- DHCP Client table
- IPv6 information

#### Diagnostic Tools:
- Ping test
- Traceroute test
- Configuration backup/restore
- Restore previous firmware
- Restart router
- Factory reset
- Scheduled restart settings

---

### 11. External Storage
**File**: external_storage.js (435 lines)

#### Sub-Features:
- Storage device list display
- Disk partition information
- Secure access settings
- SMB server settings
- Safe device removal
- Refresh storage list

---

### 12. USB Storage
**File**: usb_storage.js

#### Sub-Features:
- USB device list
- FTP server settings
- Media server settings
- Access permission management

---

### 13. OpenVPN
**File**: openvpn.js

#### Sub-Features:
- OpenVPN server toggle
- VPN profile download
- Connection information display

---

### 14. Diagnostics
**File**: diagnostics.js

#### Sub-Features:
- System diagnostics execution
- Diagnostic report generation

---

### 15. My Account
**File**: my_account.js

#### Sub-Features:
- Account information display
- Account settings management

---

### 16. Network Health
**File**: widget.js

#### Sub-Features:
- Network health status widget
- Connection quality display

---

### 17. LSWF Info (Smart WiFi Info)
**File**: widget.js

#### Sub-Features:
- Linksys Smart WiFi version information
- Router information widget

---

## Page Categories

### 1. Authentication & Account Management Pages

| Page | Description |
|------|-------------|
| `login.html` / `login-simple.html` | Login page |
| `create-account.html` / `create-account-simple.html` | Create account |
| `password-reset.html` / `password-reset-simple.html` | Password reset |
| `change-password.html` / `change-password-simple.html` | Change password |
| `change-admin-password.html` | Change admin password |
| `account-verification.html` / `account-verification-simple.html` | Account verification |
| `account-lockout.html` / `account-lockout-simple.html` | Account lockout |
| `account-security-lock.html` | Security lock |
| `mfa-challenge.html` | Multi-factor authentication |
| `recovery-pin.html` | Recovery PIN |
| `agent-login.html` | Agent login |
| `guest-login.html` | Guest login |

### 2. Main Navigation Pages

| Page | Description |
|------|-------------|
| `index.html` | Entry page |
| `home.html` | Home dashboard (Widget container) |
| `welcome.html` | Welcome page |
| `help.html` | Help page |
| `components.html` | UI component library |

### 3. Error & Status Pages

| Page | Description |
|------|-------------|
| `404.html` | 404 error page |
| `502.html` | 502 error page |
| `internet-down.html` | Internet down |
| `internet-blocked.html` | Internet blocked |
| `site-blocked.html` | Site blocked |
| `browser-unsupported.html` | Browser unsupported |
| `cookies-disabled.html` | Cookies disabled |
| `script-disabled.html` | JavaScript disabled |
| `unsecured.html` | Unsecured connection |

### 4. Setup Flow Pages (`dynamic/setup/`)

| Page | Description |
|------|-------------|
| `welcome.html` | Setup welcome |
| `account_intro.html` | Account introduction |
| `check_internet.html` | Check internet connection |
| `check_router_settings.html` | Check router settings |
| `change_radio_settings.html` | Change wireless settings |
| `change_router_password.html` | Change router password |
| `powercycle_modem.html` | Restart modem |
| `update.html` | Firmware update |
| `congratulations.html` | Setup complete |
| `pm_dsl_*.html` | DSL related settings pages |

### 5. Advanced Wireless Settings

File: `advanced-wireless.html`

Provides complete advanced wireless configuration features.

### 6. Velop Specific Pages (`dynamic/velop/`)

| Page | Description |
|------|-------------|
| `blocking.html` | Blocking page |
| `cf/` | Content Filtering related pages |

---

## Core JavaScript Architecture

### Main JS Files

| File | Size | Function |
|------|------|----------|
| globals.js | 70KB | Global settings, network initialization, application building |
| ui.js | 156KB | UI components, dialogs, form handling |
| jnap.js | 23KB | JNAP API communication layer |
| devices.js | 46KB | Device management logic |
| connect.js | 27KB | Connection management |
| account.js | 43KB | Account management |
| login.js | 22KB | Login logic |
| widget-manager.js | 24KB | Widget manager |
| applet-manager.js | 9KB | Applet manager |
| wireless-util.js | 26KB | Wireless network utility functions |

### Utility Functions

| File | Function |
|------|----------|
| `util.js` | Common utility functions |
| `validation.js` | Form validation |
| `data-bind.js` | Data binding |
| `session.js` | Session management |
| `language.js` | Internationalization |
| `browser.js` | Browser detection |

### Third-Party Libraries (`static/js/lib/`)

The project uses multiple JavaScript libraries for frontend functionality.

---

## Supported Router Models

From `globals.js`, supported models include:

- **EA Series**: EA7200, EA7300, EA7400, EA7500, EA8100, EA8250, EA8300, EA8500, EA9200, EA9350, EA9500
- **WRT Series**: WRT1200AC, WRT1900AC, WRT1900ACS, WRT3200ACM
- **Velop Series**: Supported through Mesh-related features

---

## Main UI Features

### Device List Features
- Device list display (online/offline status)
- Device icon customization (55+ device icons)
- Device name editing
- WPS device addition
- USB printer setup
- Clear device list

### Wireless Settings Features
- Multi-band settings (2.4GHz / 5GHz / 6GHz)
- Band Steering options
- WPS settings (Push Button / Router PIN / Device PIN)
- MAC Filtering
- Wireless Scheduler
- Advanced settings:
  - Airtime Fairness (ATF)
  - Dynamic Frequency Selection (DFS)
  - Multi-Link Operation (MLO)
  - Client Steering
  - Node Steering
  - IPTV Configuration

---

## Internationalization Support

- `dynamic/localized/` - Dynamic page localization
- `dynamic/setup/localized/` - Setup flow localization
- `dynamic/velop/localized/` - Velop specific localization
- Each applet has its own `localized/` directory

Pages use `{{key}}` format for translatable strings.

---

## Technical Features

1. **JNAP API**: Uses Linksys JNAP protocol for router communication
2. **Widget Architecture**: Homepage uses configurable widget system
3. **Applet Architecture**: Modular design, each feature is an independent applet
4. **Responsive Design**: Supports different screen sizes
5. **Local/Remote Mode**: Supports local access and cloud remote access

---

## Build System

- Uses `Makefile` and `Makefile.build` for building
- `tools/` directory contains build tools
- Static resources are cached to `/ui/static/cache/` path

---

## JNAP API Complete Reference

JNAP (JSON Network Access Protocol) is the core communication protocol for Linksys routers. Below are the main JNAP APIs used by each functional module:

### Core APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/core/GetDeviceInfo` | Get device information |
| `/jnap/core/SetAdminPassword` | Set admin password |
| `/jnap/core/SetAdminPassword2` | Set admin password (with hint) |
| `/jnap/core/Reboot` | Reboot router |
| `/jnap/core/FactoryReset` | Factory reset |
| `/jnap/core/SetUnsecuredWiFiWarning` | Set unsecured WiFi warning |
| `/jnap/core/Transaction` | Batch transaction call |
| `/jnap/core/CheckAdminPassword` | Verify admin password |
| `/jnap/core/IsAdminPasswordDefault` | Check if password is default |

---

### Router Settings APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/router/GetLANSettings` | Get LAN settings |
| `/jnap/router/SetLANSettings` | Set LAN settings |
| `/jnap/router/GetWANSettings` | Get WAN settings |
| `/jnap/router/SetWANSettings` | Set WAN settings |
| `/jnap/router/GetWANStatus` | Get WAN status |
| `/jnap/router/GetDHCPClientLeases` | Get DHCP client leases |
| `/jnap/router/SetDHCPReservation` | Set DHCP reservation |
| `/jnap/router/GetRoutingSettings` | Get routing settings |
| `/jnap/router/SetRoutingSettings` | Set routing settings |
| `/jnap/router/GetExpressForwarding` | Get CTF settings |
| `/jnap/router/SetExpressForwarding` | Set CTF settings |

---

### Wireless AP APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/wirelessap/GetRadioInfo` | Get radio information |
| `/jnap/wirelessap/SetRadioSettings` | Set radio settings |
| `/jnap/wirelessap/GetAdvancedRadioInfo` | Get advanced radio info |
| `/jnap/wirelessap/SetAdvancedRadioSettings` | Set advanced radio settings |
| `/jnap/wirelessap/StartWPSServerSession` | Start WPS server |
| `/jnap/wirelessap/StopWPSServerSession` | Stop WPS server |
| `/jnap/wirelessap/GetWPSServerSessionStatus` | Get WPS status |
| `/jnap/wirelessap/IsWPSServerAvailable` | Check if WPS is available |
| `/jnap/wirelessap/GetAirtimeFairnessSettings` | Get ATF settings |
| `/jnap/wirelessap/SetAirtimeFairnessSettings` | Set ATF settings |

#### Chipset-Specific APIs

| Chipset | API Path Prefix |
|---------|-----------------|
| **Broadcom** | `/jnap/wirelessap/broadcom/GetAdvancedSettings`, `SetAdvancedSettings`, `GetTxBFSettings` |
| **Marvell** | `/jnap/wirelessap/marvell/GetAdvancedSettings`, `SetTxBFSettings` |
| **Qualcomm** | `/jnap/wirelessap/qualcomm/GetAdvancedRadioSettings` |
| **MediaTek** | `/jnap/wirelessap/mediatek/GetAdvancedSettings`, `SetAdvancedSettings2` |

---

### Device List APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/devicelist/GetDevices` | Get device list |
| `/jnap/devicelist/GetDevices3` | Get device list v3 |
| `/jnap/devicelist/SetDeviceProperties` | Set device properties |
| `/jnap/devicelist/DeleteDevice` | Delete device |
| `/jnap/devicelist/ClearDeviceList` | Clear device list |

---

### Guest Network APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/guestnetwork/GetGuestNetworkSettings` | Get guest network settings |
| `/jnap/guestnetwork/GetGuestNetworkSettings2` | Get guest network settings v2 |
| `/jnap/guestnetwork/SetGuestNetworkSettings` | Set guest network settings |
| `/jnap/guestnetwork/GetGuestRadioSettings` | Get guest radio settings |
| `/jnap/guestnetwork/SetGuestRadioSettings` | Set guest radio settings |
| `/jnap/guestnetwork/GetGuestNetworkClients` | Get guest network clients |
| `/jnap/guestnetwork/Authenticate` | Guest authentication |

---

### Firewall & Security APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/firewall/GetFirewallSettings` | Get firewall settings |
| `/jnap/firewall/SetFirewallSettings` | Set firewall settings |
| `/jnap/firewall/GetDMZSettings` | Get DMZ settings |
| `/jnap/firewall/SetDMZSettings` | Set DMZ settings |
| `/jnap/firewall/GetSinglePortForwardingRules` | Get single port forwarding rules |
| `/jnap/firewall/SetSinglePortForwardingRules` | Set single port forwarding |
| `/jnap/firewall/GetPortRangeForwardingRules` | Get port range forwarding |
| `/jnap/firewall/SetPortRangeForwardingRules` | Set port range forwarding |
| `/jnap/firewall/GetPortRangeTriggeringRules` | Get port triggering rules |
| `/jnap/firewall/SetPortRangeTriggeringRules` | Set port triggering |
| `/jnap/firewall/GetIPv6FirewallRules` | Get IPv6 firewall rules |

---

### MAC Filter APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/macfilter/GetMACFilterSettings` | Get MAC filter settings |
| `/jnap/macfilter/SetMACFilterSettings` | Set MAC filter settings |

---

### Parental Control APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/parentalcontrol/GetParentalControlSettings` | Get parental control settings |
| `/jnap/parentalcontrol/SetParentalControlSettings` | Set parental control settings |

---

### QoS / Media Prioritization APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/qos/GetQoSSettings` | Get QoS settings |
| `/jnap/qos/SetQoSSettings` | Set QoS settings |
| `/jnap/qos/GetWLANQoSSettings` | Get WLAN QoS settings |
| `/jnap/qos/SetWLANQoSSettings` | Set WLAN QoS settings |
| `/jnap/qos/calibration/BeginDownloadCalibration` | Begin download calibration |
| `/jnap/qos/calibration/EndDownloadCalibration` | End download calibration |
| `/jnap/lvvp/GetLVVPSettings` | Get voice/video prioritization settings |
| `/jnap/lvvp/SetLVVPSettings` | Set voice/video prioritization settings |

---

### Speed Test (Health Check) APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/healthcheck/GetCloseHealthCheckServers` | Get nearby speed test servers |
| `/jnap/healthcheck/RunHealthCheck` | Run health check |
| `/jnap/healthcheck/GetHealthCheckResults` | Get health check results |

---

### Storage APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/storage/GetFTPServerSettings` | Get FTP server settings |
| `/jnap/storage/SetFTPServerSettings` | Set FTP server settings |
| `/jnap/storage/GetSMBServerSettings` | Get SMB server settings |
| `/jnap/storage/SetSMBServerSettings` | Set SMB server settings |
| `/jnap/nodes/storage/GetNodesPartitions` | Get node partitions |
| `/jnap/nodes/storage/GetStorageCapabilities` | Get storage capabilities |
| `/jnap/nodes/storage/RemoveStorageDevice` | Remove storage device |

---

### Firmware Update APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/firmwareupdate/GetFirmwareUpdateSettings` | Get firmware update settings |
| `/jnap/firmwareupdate/SetFirmwareUpdateSettings` | Set firmware update settings |
| `/jnap/firmwareupdate/UpdateFirmwareNow` | Update firmware now |
| `/jnap/firmwareupdate/GetFirmwareUpdateStatus` | Get firmware update status |

---

### OpenVPN APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/openvpn/GetOpenVPNSettings` | Get OpenVPN settings |
| `/jnap/openvpn/SetOpenVPNSettings` | Set OpenVPN settings |
| `/jnap/openvpn/DownloadClientConnectionProfile` | Download client profile |

---

### DDNS APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/ddns/GetDDNSSettings` | Get DDNS settings |
| `/jnap/ddns/SetDDNSSettings` | Set DDNS settings |
| `/jnap/ddns/GetDDNSStatus` | Get DDNS status |

---

### HomeKit Integration APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/homekit/GetHomeKitSettings` | Get HomeKit settings |
| `/jnap/homekit/SetHomeKitSettings` | Set HomeKit settings |

---

### Node Management APIs

| API Endpoint | Description |
|--------------|-------------|
| `/jnap/nodes/setup/SetAdminPassword` | Set node admin password |
| `/jnap/nodes/networkconnections/GetNetworkConnections` | Get network connections |
| `/jnap/nodes/topologyoptimization/GetTopologyOptimizationSettings` | Get topology optimization settings |
| `/jnap/nodes/topologyoptimization/SetTopologyOptimizationSettings` | Set topology optimization settings |

---

### Other APIs

| Category | API Examples |
|----------|--------------|
| **VLAN** | `/jnap/vln/GetVLANTaggingSettings`, `SetVLANTaggingSettings` |
| **Time Settings** | `/jnap/locale/GetTimeSettings`, `SetTimeSettings` |
| **Diagnostics** | `/jnap/diagnostics/StartPing`, `StartTraceroute`, `GetPingStatus` |
| **Configuration Backup** | `/jnap/core/GetConfigurationBackup`, `RestoreConfiguration` |
| **Mesh** | `/jnap/nodes/bluetooth/StartBluetoothClientSession` |
| **DFS** | `/jnap/wirelessap/GetDFSSettings`, `SetDFSSettings` |
| **MLO** | `/jnap/wirelessap/GetMLOSettings`, `SetMLOSettings` |

---

## Summary

The Master project is a mature router management web application with:

- **18 functional modules** covering all router management features
- **40+ HTML pages** providing complete user interface
- **Complete authentication flow** including login, MFA, account management
- **Setup Wizard** guiding users through initial configuration
- **Internationalization support** for global deployment
- **Modular architecture** for easy maintenance and extension
