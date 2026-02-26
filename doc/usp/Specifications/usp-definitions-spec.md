# usp-definitions Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft (as usp-api-definitions, JSON format) |
| v2 | - | Added presets extension |
| v3 | - | Converted to YAML; merged transforms; renamed to usp-definitions |

---

## Overview

`usp-definitions` is a collection of YAML files that define USP parameter groupings for UI applications. These definitions are processed by `usp-codegen` to generate type-safe code in Dart, TypeScript, Swift, and other languages.

### Purpose

- Define logical groupings of TR-181 parameters
- Specify type information for code generation
- Define transforms for derived display values
- Define presets for controlled user input
- Enable subscription configuration
- Support turbo channel operations
- Maintain vendor-specific extensions separately

### Type

YAML definition files (no compiled code)

### Key Principle

**One source of truth, multiple platform outputs.** Definitions are written once in YAML and generate consistent code across all target languages.

---

## Directory Structure

```
usp-definitions/
├── schema/
│   ├── definition.schema.yaml    # YAML Schema for definitions
│   └── transform.schema.yaml     # YAML Schema for transforms
├── definitions/
│   ├── core/                     # Standard features (always included)
│   │   ├── hardware_info.yaml
│   │   ├── wifi_settings.yaml
│   │   ├── wifi_radio.yaml
│   │   ├── connected_devices.yaml
│   │   ├── wan_status.yaml
│   │   ├── dns_settings.yaml
│   │   └── packet_capture.yaml
│   ├── extensions/               # Optional features
│   │   ├── parental_controls.yaml
│   │   ├── guest_network.yaml
│   │   ├── port_forwarding.yaml
│   │   └── qos_settings.yaml
│   └── vendor/                   # Vendor-specific features
│       └── linksys/
│           ├── velop_nodes.yaml
│           └── smart_connect.yaml
└── transforms/                   # Optional transform files
    ├── core/
    │   ├── download_diagnostics.yaml
    │   └── wan_status.yaml
    └── vendor/
        └── linksys/
```

**Naming convention:** Transform filename must match definition filename (e.g., `transforms/core/wan_status.yaml` for `definitions/core/wan_status.yaml`).

---

## Definition Schema

### Structure

```yaml
# Required fields
name: string              # Unique identifier (camelCase)
type: get | set | add | delete | operate

# Optional fields
description: string       # Human-readable description
instance: string          # Base instance path (e.g., Device.WiFi.SSID.1)
multiInstance: boolean    # Whether this is a table/collection (default: false)
basePath: string          # Base path for multi-instance objects
turboRequired: boolean    # Requires turbo channel (default: false)

# Content
parameters: []            # List of parameter definitions
related: []               # Related objects from different paths
operations: []            # For type=operate, available operations
subscribe: {}             # Subscription configuration
presets: []               # Predefined configuration templates
```

### Parameter Definition

```yaml
parameters:
  - path: string          # TR-181 path (absolute or relative to instance)
    field: string         # Generated code field name (camelCase)
    type: string          # Data type (see Type Mapping)
    writable: boolean     # Can be modified (default: false)
    sensitive: boolean    # Sensitive data like passwords (default: false)
    required: boolean     # Must have a value (default: true)
    default: any          # Default value if not present
```

### Type Mapping

| YAML Type | TR-181 Type | Dart | TypeScript | Swift |
|-----------|-------------|------|------------|-------|
| `string` | string | String | string | String |
| `int` | int | int | number | Int |
| `unsignedInt` | unsignedInt | int | number | UInt |
| `long` | long | int | bigint | Int64 |
| `unsignedLong` | unsignedLong | int | bigint | UInt64 |
| `boolean` | boolean | bool | boolean | Bool |
| `dateTime` | dateTime | DateTime | Date | Date |
| `base64` | base64 | Uint8List | Uint8Array | Data |
| `hexBinary` | hexBinary | Uint8List | Uint8Array | Data |

---

## Definition Examples

### Read-Only Definition

**File:** `definitions/core/hardware_info.yaml`

```yaml
name: hardwareInfo
description: Basic hardware identification
type: get

parameters:
  - path: Device.DeviceInfo.ModelName
    field: modelName
    type: string

  - path: Device.DeviceInfo.ModelNumber
    field: modelNumber
    type: string

  - path: Device.DeviceInfo.SerialNumber
    field: serialNumber
    type: string

  - path: Device.DeviceInfo.HardwareVersion
    field: hardwareVersion
    type: string

  - path: Device.DeviceInfo.SoftwareVersion
    field: softwareVersion
    type: string

  - path: Device.DeviceInfo.UpTime
    field: uptime
    type: unsignedInt
```

### Writable Configuration

**File:** `definitions/core/wifi_settings.yaml`

```yaml
name: wifiSettings
description: Primary WiFi network configuration
type: get
instance: Device.WiFi.SSID.1

parameters:
  - path: .SSID
    field: ssid
    type: string
    writable: true

  - path: .Enable
    field: enabled
    type: boolean
    writable: true

  - path: .MACAddress
    field: macAddress
    type: string

related:
  - instance: Device.WiFi.AccessPoint.1.Security
    parameters:
      - path: .ModeEnabled
        field: securityMode
        type: string
        writable: true

      - path: .KeyPassphrase
        field: passphrase
        type: string
        writable: true
        sensitive: true

subscribe:
  enabled: true
  notifType: ValueChange
  id: wifi-settings-01
```

### Multi-Instance (Table)

**File:** `definitions/core/connected_devices.yaml`

```yaml
name: connectedDevices
description: Devices connected to the network
type: get
multiInstance: true
basePath: Device.Hosts.Host.

parameters:
  - path: .HostName
    field: hostName
    type: string

  - path: .IPAddress
    field: ipAddress
    type: string

  - path: .MACAddress
    field: macAddress
    type: string

  - path: .Active
    field: active
    type: boolean

  - path: .Layer1Interface
    field: interface
    type: string

  - path: .AddressSource
    field: addressSource
    type: string

subscribe:
  enabled: true
  notifType: ObjectCreation
  id: host-changes-01
```

### Turbo Channel Operation

**File:** `definitions/core/packet_capture.yaml`

```yaml
name: packetCapture
description: Network packet capture for diagnostics
type: operate
turboRequired: true

operations:
  - name: start
    path: Device.IP.Diagnostics.PacketCapture()
    async: true
    streaming: true
    inputs:
      - path: Interface
        field: interface
        type: string
        required: true

      - path: Duration
        field: durationSeconds
        type: unsignedInt
        required: false
        default: 60

      - path: PacketCount
        field: maxPackets
        type: unsignedInt
        required: false

      - path: FilterExpression
        field: filter
        type: string
        required: false

    streamEvent: PacketCaptureResult!
    streamOutput:
      path: Data
      field: packetData
      type: base64

  - name: stop
    path: Device.IP.Diagnostics.PacketCapture.Stop()
    async: false
```

### Add/Delete Operations

**File:** `definitions/extensions/port_forwarding.yaml`

```yaml
name: portForwarding
description: NAT port forwarding rules
type: add
multiInstance: true
basePath: Device.NAT.PortMapping.

parameters:
  - path: .Enable
    field: enabled
    type: boolean
    writable: true
    default: true

  - path: .Protocol
    field: protocol
    type: string
    writable: true
    required: true

  - path: .ExternalPort
    field: externalPort
    type: unsignedInt
    writable: true
    required: true

  - path: .InternalPort
    field: internalPort
    type: unsignedInt
    writable: true
    required: true

  - path: .InternalClient
    field: internalClient
    type: string
    writable: true
    required: true

  - path: .Description
    field: description
    type: string
    writable: true

subscribe:
  enabled: true
  notifType: ObjectCreation
  id: port-mapping-01
```

---

## Presets

Presets define **configuration templates** that expand user selections into TR-181 parameter sets. They enable a controlled user experience where users select from predefined options.

### Preset Schema

```yaml
presets:
  - field: string           # Logical field name (e.g., 'dnsProvider')
    description: string     # Human-readable description
    options:
      - id: string          # Unique option identifier
        label: string       # i18n key for display
        description: string # i18n key for description
        values:             # Fixed TR-181 values to apply
          - path: string
            value: any
            instance: int   # Optional instance number
        userInputs:         # Parameters requiring user input
          - field: string
            path: string
            type: string
            label: string
            placeholder: string
            validation: string  # Regex or type (ipv4, ipv6, hostname)
            instance: int
```

### Preset Types

| Type | `values` | `userInputs` | Example |
|------|----------|--------------|---------|
| **Fixed** | Yes | No | OpenDNS, Cloudflare DNS |
| **User Input** | No | Yes | Custom IP address |
| **Mixed** | Yes | Yes | WPA3 (mode fixed, passphrase from user) |

### DNS Provider Presets

**File:** `definitions/core/dns_settings.yaml`

```yaml
name: dnsSettings
description: DNS server configuration
type: get
instance: Device.DNS.Client

parameters:
  - path: .Server.1.DNSServer
    field: primaryDns
    type: string
    writable: true

  - path: .Server.2.DNSServer
    field: secondaryDns
    type: string
    writable: true

  - path: .Server.1.Enable
    field: primaryEnabled
    type: boolean
    writable: true

  - path: .Server.2.Enable
    field: secondaryEnabled
    type: boolean
    writable: true

presets:
  - field: dnsProvider
    description: DNS provider selection
    options:
      - id: isp
        label: dns_provider_isp
        description: dns_provider_isp_desc
        values:
          - path: .Server.1.Type
            value: DHCPv4
          - path: .Server.2.Type
            value: DHCPv4

      - id: opendns
        label: dns_provider_opendns
        description: dns_provider_opendns_desc
        values:
          - path: .Server.1.DNSServer
            value: "208.67.222.222"
          - path: .Server.1.Enable
            value: true
          - path: .Server.1.Type
            value: Static
          - path: .Server.2.DNSServer
            value: "208.67.220.220"
          - path: .Server.2.Enable
            value: true
          - path: .Server.2.Type
            value: Static

      - id: cloudflare
        label: dns_provider_cloudflare
        description: dns_provider_cloudflare_desc
        values:
          - path: .Server.1.DNSServer
            value: "1.1.1.1"
          - path: .Server.1.Enable
            value: true
          - path: .Server.1.Type
            value: Static
          - path: .Server.2.DNSServer
            value: "1.0.0.1"
          - path: .Server.2.Enable
            value: true
          - path: .Server.2.Type
            value: Static

      - id: dns4eu
        label: dns_provider_dns4eu
        description: dns_provider_dns4eu_desc
        values:
          - path: .Server.1.DNSServer
            value: "194.242.2.2"
          - path: .Server.1.Enable
            value: true
          - path: .Server.1.Type
            value: Static
          - path: .Server.2.DNSServer
            value: "194.242.2.3"
          - path: .Server.2.Enable
            value: true
          - path: .Server.2.Type
            value: Static

      - id: google
        label: dns_provider_google
        description: dns_provider_google_desc
        values:
          - path: .Server.1.DNSServer
            value: "8.8.8.8"
          - path: .Server.1.Enable
            value: true
          - path: .Server.1.Type
            value: Static
          - path: .Server.2.DNSServer
            value: "8.8.4.4"
          - path: .Server.2.Enable
            value: true
          - path: .Server.2.Type
            value: Static

      - id: custom
        label: dns_provider_custom
        description: dns_provider_custom_desc
        values:
          - path: .Server.1.Enable
            value: true
          - path: .Server.1.Type
            value: Static
          - path: .Server.2.Enable
            value: true
          - path: .Server.2.Type
            value: Static
        userInputs:
          - field: customPrimaryDns
            path: .Server.1.DNSServer
            type: string
            label: dns_primary_label
            placeholder: dns_primary_placeholder
            validation: ipv4

          - field: customSecondaryDns
            path: .Server.2.DNSServer
            type: string
            label: dns_secondary_label
            placeholder: dns_secondary_placeholder
            validation: ipv4
```

### WiFi Security Presets

**File:** `definitions/core/wifi_security.yaml`

```yaml
name: wifiSecurity
description: WiFi security configuration
type: get
instance: Device.WiFi.AccessPoint.1.Security

parameters:
  - path: .ModeEnabled
    field: securityMode
    type: string
    writable: true

  - path: .KeyPassphrase
    field: passphrase
    type: string
    writable: true
    sensitive: true

presets:
  - field: securityLevel
    description: WiFi security level selection
    options:
      - id: wpa3
        label: wifi_security_wpa3
        description: wifi_security_wpa3_desc
        values:
          - path: .ModeEnabled
            value: WPA3-Personal
        userInputs:
          - field: passphrase
            path: .SAEPassphrase
            type: string
            label: wifi_passphrase_label
            validation: "^.{8,63}$"

      - id: wpa2wpa3
        label: wifi_security_wpa2wpa3
        description: wifi_security_wpa2wpa3_desc
        values:
          - path: .ModeEnabled
            value: WPA3-Personal-Transition
        userInputs:
          - field: passphrase
            path: .KeyPassphrase
            type: string
            label: wifi_passphrase_label
            validation: "^.{8,63}$"

      - id: wpa2
        label: wifi_security_wpa2
        description: wifi_security_wpa2_desc
        values:
          - path: .ModeEnabled
            value: WPA2-Personal
        userInputs:
          - field: passphrase
            path: .KeyPassphrase
            type: string
            label: wifi_passphrase_label
            validation: "^.{8,63}$"

      - id: open
        label: wifi_security_open
        description: wifi_security_open_desc
        values:
          - path: .ModeEnabled
            value: None
```

---

## Transforms

Transforms define **derived values** computed from raw TR-181 parameters. They are processed by `usp-codegen` to generate extension classes with computed getters.

### Key Principle

**Transforms are optional.** If a definition doesn't need derived values, no transform file is needed. Codegen generates only the base class.

### Transform Schema

```yaml
# Each key is a derived field name
<fieldName>:
  inputs: [field1, field2, ...]   # Input fields from definition
  type: string | int | double | boolean  # Output type

  # Exactly ONE of:
  formula: <expression>           # Multi-input calculation
  map:                            # Value lookup
    "<value>": "<i18n_key>"
  converter: <function_name>      # Single-input conversion

  # Optional
  default: "<i18n_key>"           # Default for map (required if using map)
  display:
    formatter: <formatter_name>
    precision: <number>
```

### Transform Types

| Type | Key | When to Use |
|------|-----|-------------|
| **Formula** | `formula` | Math on multiple fields (throughput, percentages) |
| **Map** | `map` | Status codes → i18n keys |
| **Converter** | `converter` | Single-value format conversion (CIDR → netmask) |

### Transform Example

**File:** `transforms/core/download_diagnostics.yaml`

```yaml
# Derived values for speed test results

throughputMbps:
  inputs: [bytesReceived, startTime, endTime]
  type: double
  formula: (bytesReceived * 8) / durationSeconds(startTime, endTime) / 1_000_000
  display:
    formatter: bandwidth
    precision: 2

durationMs:
  inputs: [startTime, endTime]
  type: int
  formula: durationMs(startTime, endTime)

completionPercent:
  inputs: [bytesReceived, totalBytes]
  type: double
  formula: (bytesReceived / totalBytes) * 100
  display:
    formatter: percent
    precision: 1

stateLabel:
  inputs: [state]
  map:
    "None": speedtest_state_none
    "Requested": speedtest_state_requested
    "Completed": speedtest_state_completed
    "Error_InitConnectionFailed": speedtest_state_error_connection
    "Error_NoResponse": speedtest_state_error_timeout
  default: speedtest_state_unknown
```

### WAN Status Transforms

**File:** `transforms/core/wan_status.yaml`

```yaml
uptimeFormatted:
  inputs: [uptime]
  converter: formatDuration

ipAddressDisplay:
  inputs: [ipAddress, ipv6Address]
  type: string
  formula: ipAddress != "" ? ipAddress : ipv6Address

connectionStateLabel:
  inputs: [connectionStatus]
  map:
    "Connected": wan_connected
    "Disconnected": wan_disconnected
    "Connecting": wan_connecting
    "PendingDisconnect": wan_pending_disconnect
  default: wan_unknown

subnetMaskDotted:
  inputs: [subnetMaskCidr]
  converter: cidrToNetmask
```

### Built-in Functions

Available in formulas and converters:

| Function | Signature | Description |
|----------|-----------|-------------|
| `durationSeconds` | `(DateTime, DateTime) → double` | Time difference in seconds |
| `durationMs` | `(DateTime, DateTime) → int` | Time difference in milliseconds |
| `cidrToNetmask` | `(int) → String` | CIDR to dotted decimal |
| `formatBandwidth` | `(double) → String` | Human-readable bandwidth |
| `formatDuration` | `(int) → String` | Human-readable duration |
| `formatBytes` | `(int) → String` | Human-readable size |
| `formatPercent` | `(double) → String` | Percentage with symbol |

### Display Formatters

| Formatter | Options | Description |
|-----------|---------|-------------|
| `bandwidth` | `precision` | Format as Mbps/Gbps |
| `duration` | - | Format as h/m/s |
| `bytes` | - | Format as KB/MB/GB |
| `percent` | `precision` | Format as percentage |
| `number` | `precision`, `separator` | Formatted number |

---

## Generated Code

### Dart Output

From `definitions/core/dns_settings.yaml`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:usp_client/usp_client.dart';

/// DNS server configuration
class DnsSettings {
  final String primaryDns;
  final String secondaryDns;
  final bool primaryEnabled;
  final bool secondaryEnabled;

  const DnsSettings({
    required this.primaryDns,
    required this.secondaryDns,
    required this.primaryEnabled,
    required this.secondaryEnabled,
  });

  static Future<DnsSettings> fetch(UspClient client) async {
    final response = await client.get([
      'Device.DNS.Client.Server.1.DNSServer',
      'Device.DNS.Client.Server.2.DNSServer',
      'Device.DNS.Client.Server.1.Enable',
      'Device.DNS.Client.Server.2.Enable',
    ]);
    return DnsSettings._fromResponse(response);
  }

  // ... factory constructor, save method
}

// Generated preset enum
enum DnsProvider {
  isp,
  opendns,
  cloudflare,
  dns4eu,
  google,
  custom,
}

// Generated preset extension
extension DnsSettingsPresets on DnsSettings {
  static Future<void> applyPreset(
    UspClient client,
    DnsProvider provider, {
    String? customPrimaryDns,
    String? customSecondaryDns,
  }) async {
    switch (provider) {
      case DnsProvider.opendns:
        await client.set({
          'Device.DNS.Client.Server.1.DNSServer': '208.67.222.222',
          'Device.DNS.Client.Server.1.Enable': true,
          'Device.DNS.Client.Server.1.Type': 'Static',
          'Device.DNS.Client.Server.2.DNSServer': '208.67.220.220',
          'Device.DNS.Client.Server.2.Enable': true,
          'Device.DNS.Client.Server.2.Type': 'Static',
        });
        break;
      // ... other cases
    }
  }

  static List<PresetOption<DnsProvider>> get presetOptions => [
    PresetOption(DnsProvider.isp, 'dns_provider_isp', 'dns_provider_isp_desc'),
    PresetOption(DnsProvider.opendns, 'dns_provider_opendns', 'dns_provider_opendns_desc'),
    // ...
  ];
}
```

From `transforms/core/download_diagnostics.yaml`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

extension DownloadDiagnosticsTransforms on DownloadDiagnostics {
  double get throughputMbps {
    final duration = Transforms.durationSeconds(startTime, endTime);
    if (duration <= 0) return 0.0;
    return (bytesReceived * 8) / duration / 1000000;
  }

  String get throughputMbpsDisplay =>
      Transforms.formatBandwidth(throughputMbps, precision: 2);

  int get durationMs =>
      Transforms.durationMs(startTime, endTime);

  String get stateLabel {
    switch (state) {
      case "None": return tr("speedtest_state_none");
      case "Requested": return tr("speedtest_state_requested");
      case "Completed": return tr("speedtest_state_completed");
      default: return tr("speedtest_state_unknown");
    }
  }
}
```

---

## Validation

### Schema Validation

```bash
# Using yq for YAML validation
yq eval '.' definitions/core/wifi_settings.yaml

# Using a YAML schema validator
yamale -s schema/definition.schema.yaml definitions/core/*.yaml
yamale -s schema/transform.schema.yaml transforms/core/*.yaml
```

### Codegen Validation

When processing files, `usp-codegen` validates:

**Definitions:**
1. Required fields present (`name`, `type`)
2. Parameter paths are valid TR-181 format
3. Types are recognized
4. Subscription IDs are unique

**Transforms:**
1. File matches a definition
2. All inputs exist as fields in definition
3. Formula syntax is valid
4. Map has default value
5. Converter function is built-in

**Presets:**
1. Preset field names are unique
2. Option IDs are unique within preset
3. Value paths are valid
4. User input validations are valid regex or known types

### Error Messages

```bash
$ usp-codegen --input ./definitions --transforms ./transforms --output ./lib --lang dart

Error: definitions/core/wifi_settings.yaml
  - Line 15: Unknown type 'strng' (did you mean 'string'?)

Error: transforms/core/download_diagnostics.yaml
  - throughputMbps: Input 'byteReceived' not found (did you mean 'bytesReceived'?)

Warning: transforms/core/network_quality.yaml has no matching definition
```

---

## Core Definitions

| File | Description |
|------|-------------|
| `hardware_info.yaml` | Device model, serial, versions |
| `wifi_settings.yaml` | Primary WiFi SSID and security |
| `wifi_radio.yaml` | Radio settings (channel, bandwidth) |
| `connected_devices.yaml` | Host table |
| `wan_status.yaml` | WAN connection status |
| `firmware_info.yaml` | Firmware version, upgrade status |
| `system_time.yaml` | NTP and timezone settings |
| `dns_settings.yaml` | DNS server configuration with provider presets |
| `dhcp_settings.yaml` | DHCP server settings |
| `packet_capture.yaml` | Diagnostic packet capture |

---

## Extension Definitions

| File | Description |
|------|-------------|
| `parental_controls.yaml` | Content filtering, schedules |
| `guest_network.yaml` | Guest WiFi configuration |
| `port_forwarding.yaml` | NAT port mapping |
| `firewall_rules.yaml` | Firewall configuration |
| `qos_settings.yaml` | Quality of Service |
| `mesh_topology.yaml` | Mesh node information |

---

## Vendor Definitions

Vendor-specific definitions extend the standard data model.

**Location:** `definitions/vendor/<vendor_name>/`

**Example:** `definitions/vendor/linksys/velop_nodes.yaml`

```yaml
name: velopNodes
description: Linksys Velop mesh node information
type: get
multiInstance: true
basePath: Device.X_LINKSYS_MeshNode.

parameters:
  - path: .NodeID
    field: nodeId
    type: string

  - path: .Status
    field: status
    type: string

  - path: .ConnectedClients
    field: clientCount
    type: unsignedInt
```

---

## Build Integration

### Package Contents

```makefile
define Package/usp-definitions
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=USP Definition Files
  DEPENDS:=
endef

define Package/usp-definitions/install
	$(INSTALL_DIR) $(1)/usr/share/usp-definitions
	$(CP) ./files/definitions/* $(1)/usr/share/usp-definitions/definitions/
	$(CP) ./files/transforms/* $(1)/usr/share/usp-definitions/transforms/
endef
```

### Usage with usp-codegen

```bash
usp-codegen \
    --definitions /usr/share/usp-definitions/definitions \
    --transforms /usr/share/usp-definitions/transforms \
    --output ./lib/generated \
    --lang dart
```

---

## Best Practices

### Naming Conventions

- **Definition names**: camelCase (e.g., `wifiSettings`)
- **Field names**: camelCase (e.g., `macAddress`)
- **Subscription IDs**: kebab-case with suffix (e.g., `wifi-settings-01`)
- **i18n keys**: snake_case with prefix (e.g., `dns_provider_opendns`)
- **Preset IDs**: lowercase with underscores (e.g., `opendns_family`)

### Path Conventions

- Use relative paths (starting with `.`) when `instance` is defined
- Use absolute paths otherwise
- Reference related objects in `related` array

### When to Use Transforms

| Scenario | Use Transform? |
|----------|----------------|
| Raw value displayed directly | No |
| Calculation from multiple fields | Yes (formula) |
| Status code needs translation | Yes (map) |
| Format conversion (CIDR, duration) | Yes (converter) |
| Complex conditional logic | Consider UI code instead |

### When to Use Presets

| Scenario | Use Preset? |
|----------|-------------|
| User selects from known options | Yes |
| Multiple parameters change together | Yes |
| User enters free-form value | No (use writable parameter) |
| Options are device-dependent | Consider dynamic approach |
