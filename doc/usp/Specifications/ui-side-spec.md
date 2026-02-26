# USP-Driven UI Specification — UI Side

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

This specification defines the UI-side architecture for a USP (User Services Platform, TR-369) driven web and mobile application for OpenWRT-based WiFi routers. The UI communicates with the router's USP Agent (OBUSPA) through a USP Bridge daemon.

### Design Principles

1. **USP-native**: All configuration read/write operations use USP messages (protobuf-encoded)
2. **Security-first**: TLS-only external communications, JWT-based authentication
3. **Stateless backend**: USP Bridge holds only transient session state; OBUSPA is the source of truth for device configuration
4. **Standard-compliant**: No vendor extensions to USP data model; session routing handled at transport layer
5. **Extensible**: Micro-frontend architecture for UI extensions
6. **Developer-friendly**: Backend handles transport complexity; UI works with USP abstractions
7. **Cross-platform**: Same architecture for web browser and mobile apps
8. **Dual-transport**: HTTP/SSE for normal operations; WebSocket turbo channel for high-bandwidth streaming

---

## Technology Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Framework | Flutter/Dart | Cross-platform (web, iOS, Android) |
| Base project | [linksys/PrivacyGUI](https://github.com/linksys/PrivacyGUI) | Existing codebase, not starting from scratch |
| USP Client | Rust | Single codebase for native + WASM; see below |
| Normal Transport | HTTPS + SSE | Multi-tab/multi-device support via USP Bridge |
| Turbo Transport | WebSocket | Direct to OBUSPA for high-bandwidth streaming |
| USP encoding | Protobuf | Native USP wire format |

### Why Rust for usp-client

The `usp-client` library handles protobuf encoding and transport. It must work on:
- Native platforms (iOS, Android) via Dart FFI
- Web browsers (Flutter Web, future TypeScript UIs) via WASM

**Alternatives considered:**

| Language | Verdict |
|----------|---------|
| **Pure Dart** | Only works for Flutter; would need separate TypeScript implementation for future non-Flutter web UIs |
| **C** | Universal FFI, but WASM support requires emscripten (awkward); manual memory management |
| **Go** | GC runtime adds overhead; WASM bundle includes GC; CGO for FFI is awkward |
| **Rust** | Memory safe, first-class WASM target, C ABI for FFI, single codebase for all platforms |

**Why not pure Dart?** Future UIs may not use Flutter (e.g., TypeScript web apps). A single Rust codebase avoids duplicating protobuf and transport logic across languages.

**Learning curve:** Rust has a steeper learning curve than C, but the strict compiler helps catch mistakes early. Modern AI assistants significantly reduce the barrier to entry, making Rust accessible to developers with C background.

### Platform Parity

Web browser and mobile apps share the same architecture:

| Aspect | Web Browser | Mobile App |
|--------|-------------|------------|
| Normal transport | HTTP/SSE via USP Bridge | HTTP/SSE via USP Bridge |
| Turbo channel | WebSocket direct to OBUSPA | WebSocket direct to OBUSPA |
| Multi-instance | Multiple tabs | Multiple devices |
| Session management | USP Bridge | USP Bridge |
| Authentication | Cookie-based | Header-based |
| Code sharing | Flutter web | Flutter iOS/Android |

**Key insight**: A mobile app is architecturally equivalent to "another browser tab"—both use the same USP Bridge for session management and notification routing.

### Session-Per-Device Model

Each login creates an independent session:

- **Phone and laptop**: Separate sessions (each authenticates independently)
- **Multiple browser tabs**: Share the same session (same cookie)
- **No cross-device session sharing**: This is intentional

This simplifies:
- Subscription ownership tracking
- Turbo channel coordination
- Session cleanup on disconnect

---

## Design Goals

1. **Developers should not work with TR-181 paths directly**: Application developers call high-level Dart functions; TR-181 complexity is hidden in libraries
2. **Developers should not work with protobuf directly**: USP message construction/parsing is handled by generated code
3. **Extensibility via definitions**: New functionality added through JSON definition files, not code changes
4. **Single source of truth**: OBUSPA owns all device state; UI caches for performance only

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                            │
│         (UI screens, business logic, state management)          │
│                                                                 │
│    - Network settings screens                                   │
│    - Device management views                                    │
│    - Diagnostics and monitoring                                 │
└─────────────────────────────────────────────────────────────────┘
                                      │ High-level API calls
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Definition-Driven Layer                       │
│         (Generated from JSON definition files)                  │
│                                                                 │
│    - WifiSettings.get(), WifiSettings.set()                     │
│    - DeviceInfo.get()                                           │
│    - Subscription helpers                                       │
└─────────────────────────────────────────────────────────────────┘
                                      │ USP operations
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Domain Model Layer                           │
│         (Strongly-typed Dart classes)                           │
│                                                                 │
│    class HardwareInfo { ... }                                   │
│    class WifiNetwork { ... }                                    │
│    class ConnectedDevice { ... }                                │
└─────────────────────────────────────────────────────────────────┘
                                      │ USP operations
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     USP Client Layer                            │
│         (Session, transport, message handling)                  │
│                                                                 │
│    - Authentication & JWT management                            │
│    - Proactive JWT refresh                                      │
│    - HTTP/SSE connection for normal operations                  │
│    - WebSocket connection for turbo channel                     │
│    - Protobuf encoding/decoding                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Definition System

Application developers define data model groupings in JSON files. A code generator produces type-safe Dart classes.

### Why Code Generation (not Runtime Interpretation)

An alternative approach would be to ship the JSON definition files with the UI and interpret them at runtime. We chose build-time code generation for three reasons:

| Concern | Code Generation | Runtime Interpretation |
|---------|-----------------|------------------------|
| **Security** | Paths baked into compiled binary; behavior is immutable | JSON files on device could be modified by attacker to access sensitive paths |
| **Storage** | Only compiled code ships; no JSON files in UI bundle | JSON files must be included in deployed bundle |
| **Type safety** | Compile-time checking; IDE autocomplete | Runtime errors; `Map<String, dynamic>` access |

**Security detail**: With runtime interpretation, an attacker who gains filesystem access could modify definition files to redirect API calls to sensitive parameters (e.g., `Device.Users.Password`) without modifying the application binary. With compiled code, changing behavior requires replacing the signed binary—a much higher bar.

**Note**: The dynamic call system (for AI-generated requests) intentionally uses runtime JSON interpretation because paths are not known at build time. This is secured by router-side validation and whitelisting in `usp-llm-proxy`.

### Definition File Format

**Location**: `lib/api/definitions/`

**Schema**:

```json
{
  "name": "string",
  "description": "string (optional)",
  "type": "get | set | add | delete | operate",
  "parameters": [ ],
  "returns": { },
  "subscribe": { },
  "turboRequired": false
}
```

### Example: Read-Only Data Group

**File**: `definitions/core/hardware_info.json`

```json
{
  "name": "hardwareInfo",
  "description": "Basic hardware identification",
  "type": "get",
  "parameters": [
    {
      "path": "Device.DeviceInfo.ModelName",
      "field": "modelName",
      "type": "string"
    },
    {
      "path": "Device.DeviceInfo.ModelNumber",
      "field": "modelNumber",
      "type": "string"
    },
    {
      "path": "Device.DeviceInfo.SerialNumber",
      "field": "serialNumber",
      "type": "string"
    },
    {
      "path": "Device.DeviceInfo.HardwareVersion",
      "field": "hardwareVersion",
      "type": "string"
    },
    {
      "path": "Device.DeviceInfo.SoftwareVersion",
      "field": "softwareVersion",
      "type": "string"
    }
  ]
}
```

**Generated Dart**:

```dart
/// Basic hardware identification
class HardwareInfo {
  final String modelName;
  final String modelNumber;
  final String serialNumber;
  final String hardwareVersion;
  final String softwareVersion;

  const HardwareInfo({
    required this.modelName,
    required this.modelNumber,
    required this.serialNumber,
    required this.hardwareVersion,
    required this.softwareVersion,
  });

  /// Fetch hardware info from device
  static Future<HardwareInfo> fetch(UspClient client) async {
    final response = await client.get([
      'Device.DeviceInfo.ModelName',
      'Device.DeviceInfo.ModelNumber',
      'Device.DeviceInfo.SerialNumber',
      'Device.DeviceInfo.HardwareVersion',
      'Device.DeviceInfo.SoftwareVersion',
    ]);
    return HardwareInfo._fromResponse(response);
  }

  factory HardwareInfo._fromResponse(GetResponse response) {
    return HardwareInfo(
      modelName: response.getString('Device.DeviceInfo.ModelName'),
      modelNumber: response.getString('Device.DeviceInfo.ModelNumber'),
      serialNumber: response.getString('Device.DeviceInfo.SerialNumber'),
      hardwareVersion: response.getString('Device.DeviceInfo.HardwareVersion'),
      softwareVersion: response.getString('Device.DeviceInfo.SoftwareVersion'),
    );
  }
}
```

**Application usage**:

```dart
final info = await HardwareInfo.fetch(client);
print('Model: ${info.modelName}');
print('Serial: ${info.serialNumber}');
```

### Example: Writable Configuration

**File**: `definitions/core/wifi_settings.json`

```json
{
  "name": "wifiSettings",
  "description": "Primary WiFi network configuration",
  "type": "get",
  "instance": "Device.WiFi.SSID.1",
  "parameters": [
    {
      "path": ".SSID",
      "field": "ssid",
      "type": "string",
      "writable": true
    },
    {
      "path": ".Enable",
      "field": "enabled",
      "type": "boolean",
      "writable": true
    }
  ],
  "related": [
    {
      "instance": "Device.WiFi.AccessPoint.1.Security",
      "parameters": [
        {
          "path": ".ModeEnabled",
          "field": "securityMode",
          "type": "string",
          "writable": true
        },
        {
          "path": ".KeyPassphrase",
          "field": "passphrase",
          "type": "string",
          "writable": true,
          "sensitive": true
        }
      ]
    }
  ],
  "subscribe": {
    "enabled": true,
    "notifType": "ValueChange",
    "id": "wifi-settings-01"
  }
}
```

**Generated Dart**:

```dart
/// Primary WiFi network configuration
class WifiSettings {
  final String ssid;
  final bool enabled;
  final String securityMode;
  final String passphrase;

  // ... constructor, fetch() ...

  /// Update WiFi settings on device
  Future<void> save(UspClient client, {
    String? ssid,
    bool? enabled,
    String? securityMode,
    String? passphrase,
  }) async {
    final params = <String, dynamic>{};
    if (ssid != null) params['Device.WiFi.SSID.1.SSID'] = ssid;
    if (enabled != null) params['Device.WiFi.SSID.1.Enable'] = enabled;
    if (securityMode != null) {
      params['Device.WiFi.AccessPoint.1.Security.ModeEnabled'] = securityMode;
    }
    if (passphrase != null) {
      params['Device.WiFi.AccessPoint.1.Security.KeyPassphrase'] = passphrase;
    }
    await client.set(params);
  }

  /// Subscribe to changes
  static Future<Subscription<WifiSettings>> subscribe(UspClient client) async {
    return client.subscribe<WifiSettings>(
      id: 'wifi-settings-01',
      notifType: NotifType.valueChange,
      paths: [
        'Device.WiFi.SSID.1.SSID',
        'Device.WiFi.SSID.1.Enable',
        'Device.WiFi.AccessPoint.1.Security.ModeEnabled',
      ],
      parser: WifiSettings._fromResponse,
    );
  }
}
```

**Application usage**:

```dart
// Read
final wifi = await WifiSettings.fetch(client);
print('SSID: ${wifi.ssid}');

// Write
await wifi.save(client, ssid: 'NewNetworkName', passphrase: 'secret123');

// Subscribe to changes
final subscription = await WifiSettings.subscribe(client);
subscription.onUpdate((newSettings) {
  print('WiFi changed: ${newSettings.ssid}');
});
```

### Example: Multi-Instance (Tables)

**File**: `definitions/core/connected_devices.json`

```json
{
  "name": "connectedDevices",
  "description": "Devices connected to the network",
  "type": "get",
  "multiInstance": true,
  "basePath": "Device.Hosts.Host.",
  "parameters": [
    {
      "path": ".HostName",
      "field": "hostName",
      "type": "string"
    },
    {
      "path": ".IPAddress",
      "field": "ipAddress",
      "type": "string"
    },
    {
      "path": ".MACAddress",
      "field": "macAddress",
      "type": "string"
    },
    {
      "path": ".Active",
      "field": "active",
      "type": "boolean"
    },
    {
      "path": ".Layer1Interface",
      "field": "interface",
      "type": "string"
    }
  ],
  "subscribe": {
    "enabled": true,
    "notifType": "ObjectCreation",
    "id": "host-changes-01"
  }
}
```

**Generated Dart**:

```dart
/// Single connected device
class ConnectedDevice {
  final String instancePath;
  final String hostName;
  final String ipAddress;
  final String macAddress;
  final bool active;
  final String interface_;

  // ... constructor ...
}

/// Devices connected to the network
class ConnectedDevices {
  final List<ConnectedDevice> devices;

  /// Fetch all connected devices
  static Future<ConnectedDevices> fetch(UspClient client) async {
    final response = await client.get(['Device.Hosts.Host.']);
    return ConnectedDevices._fromResponse(response);
  }

  /// Get only active devices
  List<ConnectedDevice> get active => 
    devices.where((d) => d.active).toList();

  /// Find device by MAC address
  ConnectedDevice? findByMac(String mac) =>
    devices.cast<ConnectedDevice?>().firstWhere(
      (d) => d?.macAddress.toLowerCase() == mac.toLowerCase(),
      orElse: () => null,
    );
}
```

**Application usage**:

```dart
final devices = await ConnectedDevices.fetch(client);
print('${devices.active.length} devices online');

for (final device in devices.active) {
  print('${device.hostName} - ${device.ipAddress}');
}
```

### Example: Turbo Channel Operation (Packet Capture)

**File**: `definitions/core/packet_capture.json`

```json
{
  "name": "packetCapture",
  "description": "Network packet capture for diagnostics",
  "type": "operate",
  "turboRequired": true,
  "operations": [
    {
      "name": "start",
      "path": "Device.IP.Diagnostics.PacketCapture()",
      "async": true,
      "streaming": true,
      "inputs": [
        {
          "path": "Interface",
          "field": "interface",
          "type": "string",
          "required": true
        },
        {
          "path": "Duration",
          "field": "durationSeconds",
          "type": "unsigned int",
          "required": false,
          "default": 60
        },
        {
          "path": "PacketCount",
          "field": "maxPackets",
          "type": "unsigned int",
          "required": false
        },
        {
          "path": "FilterExpression",
          "field": "filter",
          "type": "string",
          "required": false
        }
      ],
      "streamEvent": "PacketCaptureResult!",
      "streamOutput": {
        "path": "Data",
        "field": "packetData",
        "type": "base64"
      }
    },
    {
      "name": "stop",
      "path": "Device.IP.Diagnostics.PacketCapture.Stop()",
      "async": false
    }
  ]
}
```

**Generated Dart**:

```dart
/// Network packet capture for diagnostics
/// 
/// This operation requires the turbo channel for high-bandwidth streaming.
class PacketCapture {
  final UspClient _client;

  PacketCapture(this._client);

  /// Start packet capture
  /// 
  /// Returns a stream of captured packets. The turbo channel will be
  /// automatically acquired and released.
  /// 
  /// Throws [TurboChannelBusyException] if another operation is using
  /// the turbo channel.
  Stream<PacketData> start({
    required String interface,
    int durationSeconds = 60,
    int? maxPackets,
    String? filter,
  }) async* {
    // Acquire turbo channel
    final channel = await _client.acquireTurboChannel(
      operation: 'packet_capture',
    );
    
    try {
      // Send Operate via WebSocket
      await channel.operate(
        'Device.IP.Diagnostics.PacketCapture()',
        inputs: {
          'Interface': interface,
          'Duration': durationSeconds,
          if (maxPackets != null) 'PacketCount': maxPackets,
          if (filter != null) 'FilterExpression': filter,
        },
      );
      
      // Yield streaming results
      await for (final event in channel.events) {
        if (event.name == 'PacketCaptureResult!') {
          yield PacketData._fromEvent(event);
        }
      }
    } finally {
      // Release turbo channel (closes WebSocket)
      await channel.close();
    }
  }

  /// Stop an in-progress packet capture
  Future<void> stop() async {
    await _client.operate('Device.IP.Diagnostics.PacketCapture.Stop()');
  }
}

class PacketData {
  final Uint8List data;
  final DateTime timestamp;
  
  // ... constructor, factory ...
}
```

**Application usage**:

```dart
final capture = PacketCapture(client);

try {
  await for (final packet in capture.start(
    interface: 'Device.IP.Interface.1.',
    durationSeconds: 30,
    filter: 'tcp port 80',
  )) {
    // Process each packet
    print('Captured ${packet.data.length} bytes');
    pcapWriter.write(packet.data);
  }
} on TurboChannelBusyException {
  showError('Packet capture in progress elsewhere');
}
```

---

## Definition File Organization

```
lib/api/definitions/
├── core/                          # Standard features (always included)
│   ├── hardware_info.json
│   ├── wifi_settings.json
│   ├── connected_devices.json
│   ├── firmware_upgrade.json
│   ├── wan_status.json
│   ├── packet_capture.json        # Turbo channel operation
│   └── ...
├── extensions/                    # Optional features
│   ├── parental_controls.json
│   ├── guest_network.json
│   ├── mesh_topology.json
│   └── ...
└── vendor/                        # Vendor-specific features
    └── linksys/
        ├── velop_nodes.json
        └── ...
```

**Core definitions**: Ship with every build. Provide baseline router management functionality.

**Extension definitions**: Optional features that may not be available on all devices. UI should check capability before using.

**Vendor definitions**: Vendor-specific extensions to the data model. Isolated to prevent pollution of core APIs.

---

## Transform Layer

### Why a Separate Transform Layer?

The YAML definition files (`usp-definitions`) map TR-181 parameters to typed fields. However, UIs often need to:
- **Convert values**: CIDR notation "24" → dotted decimal "255.255.255.0"
- **Compute derived values**: throughput = bytes / duration
- **Map codes to labels**: "0" → "network_quality_high" (i18n key)

These transformations could be embedded in the definitions, but that would:
1. Make definitions complex and hard to maintain
2. Mix data model concerns with presentation concerns

Instead, we use a **separate transform layer** (optional YAML files in `usp-definitions/transforms/`) that:
- Keeps definition files pure (raw TR-181 parameter mapping + presets only)
- Defines derived values in separate YAML files
- Gets processed by codegen to generate computed getters/extensions

### Architecture

```
usp-definitions/
├── definitions/              ← Pure data model mapping (YAML)
│   └── core/
│       ├── download_diagnostics.yaml
│       └── wan_status.yaml
└── transforms/               ← Derived values (YAML, optional)
    └── core/
        ├── download_diagnostics.yaml    ← Only for definitions that need it
        └── wan_status.yaml
```

**Key principle**: If a definition doesn't need transforms, no transform file is required. Raw parameters flow through unchanged.

### Transform Types

The YAML transform files support three types:

#### 1. Formula (calculations from multiple fields)

```yaml
# download_diagnostics.yaml
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
```

#### 2. Map (value translations with i18n)

```yaml
# network_quality.yaml
qualityLabel:
  inputs: [qualityCode]
  map:
    "0": "network_quality_high"
    "1": "network_quality_medium"
    "2": "network_quality_low"
    "3": "network_quality_poor"
  default: "network_quality_unknown"
```

The map values are **i18n keys**, not display strings. The generated code uses a translation function:

```dart
String get qualityLabel {
  switch (qualityCode) {
    case "0": return tr("network_quality_high");
    case "1": return tr("network_quality_medium");
    // ...
  }
}
```

#### 3. Converter (single-value conversion)

```yaml
# ip_settings.yaml
subnetMaskDotted:
  inputs: [subnetMaskCidr]
  converter: cidrToNetmask
```

### Generated Code Structure

For a definition with transforms, codegen generates:

```dart
// From YAML definition: raw data class
class DownloadDiagnostics {
  final int bytesReceived;
  final DateTime startTime;
  final DateTime endTime;
  final String state;

  // ... constructor, fetch() ...
}

// From YAML transforms: extension with derived values
extension DownloadDiagnosticsTransforms on DownloadDiagnostics {
  double get throughputMbps =>
      Transforms.throughputMbps(bytesReceived, startTime, endTime);

  int get durationMs =>
      endTime.difference(startTime).inMilliseconds;

  String get throughputDisplay =>
      Transforms.formatBandwidth(throughputMbps, precision: 2);
}
```

**Benefits:**
- Raw values remain accessible (`bytesReceived`, `startTime`, `endTime`)
- Derived values are discoverable via IDE autocomplete (`throughputMbps`)
- Extension pattern keeps the base class clean
- All UIs get consistent transform logic

### Built-in Functions

Codegen includes a library of built-in transform functions:

| Function | Description | Example |
|----------|-------------|---------|
| `durationSeconds(start, end)` | Time difference in seconds | Speed tests |
| `durationMs(start, end)` | Time difference in milliseconds | Timing displays |
| `cidrToNetmask(cidr)` | CIDR → dotted decimal | "24" → "255.255.255.0" |
| `formatBandwidth(mbps, precision)` | Human-readable bandwidth | 1500 → "1.5 Gbps" |
| `formatDuration(seconds)` | Human-readable duration | 3665 → "1h 1m 5s" |
| `formatBytes(bytes)` | Human-readable size | 1536 → "1.5 KB" |

### Integration with i18n

For `map` transforms, the generated code outputs translation keys, not hardcoded strings. The UI's localization system handles the actual translation:

```
# Localization files
en.json: { "network_quality_high": "Network quality: Excellent" }
fr.json: { "network_quality_high": "Qualité réseau : Excellente" }
de.json: { "network_quality_high": "Netzwerkqualität: Ausgezeichnet" }
```

This ensures:
- Semantic transformations (code → key) are defined once in YAML
- Display strings are managed in the standard i18n workflow
- Translations can be updated without rebuilding the transform layer

---

## Code Generation

**Build-time generation**: Definition files are processed during the build to produce Dart source files.

```bash
# Generate API classes from definitions
flutter pub run build_runner build

# Watch for changes during development
flutter pub run build_runner watch
```

**Generated output location**: `lib/api/generated/`

**Generator responsibilities**:

1. Parse JSON definition files
2. Validate paths against known TR-181 schema (optional, for early error detection)
3. Generate type-safe Dart classes with:
   - Immutable data classes with named constructors
   - Static `fetch()` methods for reads
   - Instance `save()` methods for writes (where applicable)
   - Static `subscribe()` methods (where applicable)
   - Turbo channel handling for streaming operations
   - Response parsing from USP GetResponse/SetResponse
4. Generate barrel exports for easy importing

**Import in application code**:

```dart
import 'package:app/api/generated/core.dart';
import 'package:app/api/generated/extensions.dart';
```

---

## Authentication

### Platform-Specific Authentication

| Platform | Mechanism | Token Storage |
|----------|-----------|---------------|
| Web Browser | HttpOnly cookie | Browser manages automatically |
| Mobile App | Authorization header | Secure storage (Keychain/Keystore) |

### Login Flow (Web Browser)

```dart
Future<void> login(String password) async {
  final response = await http.post(
    '$_baseUrl/api/auth/login',
    body: jsonEncode({'password': password}),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 401) {
    throw UspAuthException('Invalid password');
  }

  final data = jsonDecode(response.body);
  _controllerEndpointId = data['controller_endpoint_id'];
  _turboControllerEndpointId = data['turbo_controller_endpoint_id'];
  _agentEndpointId = data['agent_endpoint_id'];
  
  // Cookie is set automatically by the browser
  // session_id will be discovered via SSE connected event
  _authenticated = true;
}
```

### Login Flow (Mobile App)

```dart
Future<void> login(String password) async {
  final response = await http.post(
    '$_baseUrl/api/auth/login',
    body: jsonEncode({'password': password}),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 401) {
    throw UspAuthException('Invalid password');
  }

  final data = jsonDecode(response.body);
  _controllerEndpointId = data['controller_endpoint_id'];
  _turboControllerEndpointId = data['turbo_controller_endpoint_id'];
  _agentEndpointId = data['agent_endpoint_id'];
  
  // Mobile apps must store the token explicitly
  _token = data['token'];
  await _secureStorage.write(key: 'usp_token', value: _token);
  
  _authenticated = true;
}
```

### JWT Refresh

The UI must refresh the JWT before it expires. Schedule refresh at 80% of token lifetime.

```dart
void _scheduleTokenRefresh() {
  // JWT expiry is typically 1 hour; refresh at ~48 minutes
  final refreshDelay = Duration(minutes: 48);
  
  _refreshTimer?.cancel();
  _refreshTimer = Timer(refreshDelay, () async {
    await _refreshToken();
    _scheduleTokenRefresh(); // Schedule next refresh
  });
}

Future<void> _refreshToken() async {
  final response = await http.post(
    '$_baseUrl/api/auth/refresh',
    headers: _authHeaders,  // Cookie (web) or Authorization header (mobile)
  );

  if (response.statusCode == 401) {
    // Token expired beyond grace period
    _onAuthRequired?.call();
    return;
  }

  // For mobile apps, update stored token
  if (!kIsWeb) {
    final data = jsonDecode(response.body);
    _token = data['token'];
    await _secureStorage.write(key: 'usp_token', value: _token);
  }
  // For web, cookie is updated automatically
}
```

---

## SSE Connection and Session Discovery

### Connecting to SSE

Web browsers use `withCredentials: true` to include the cookie:

```dart
Future<void> connectNotifications() async {
  _sseConnection = EventSource(
    '$_baseUrl/api/events',
    withCredentials: true,  // Required for cookie-based auth in browsers
  );

  _sseConnection!.addEventListener('connected', (event) {
    final data = jsonDecode(event.data);
    _sessionId = data['session_id'];  // Discover session_id here
    print('SSE connected, session: $_sessionId');
  });

  _sseConnection!.addEventListener('notification', (event) {
    final data = jsonDecode(event.data);
    final subId = data['subscription_id'] as String;
    final record = base64Decode(data['record'] as String);
    _handleNotification(subId, record);
  });

  _sseConnection!.addEventListener('turbo_channel', (event) {
    final data = jsonDecode(event.data);
    _handleTurboChannelEvent(data);
  });

  _sseConnection!.onError.listen((_) => _handleSseError());
}
```

For mobile apps, use the Authorization header:

```dart
Future<void> connectNotifications() async {
  _sseConnection = EventSource(
    '$_baseUrl/api/events',
    headers: {'Authorization': 'Bearer $_token'},
  );
  
  // ... same event listeners as above
}
```

### Session ID Usage

The `session_id` is discovered from the SSE `connected` event (not extracted from the JWT, which is HttpOnly). It's used for:

1. **Subscription ID prefixing**: `${_sessionId}-wifi-status`
2. **Turbo channel ownership checks**: Compare with `event.session_id`
3. **Cross-tab coordination**: Identify "own session" vs "other session"

```dart
String _prefixSubscriptionId(String shortId) {
  if (_sessionId == null) {
    throw StateError('Not connected - session_id unknown');
  }
  return '$_sessionId-$shortId';
}
```

---

## Multi-Tab / Multi-Device Handling

### Notification Fan-Out

When multiple browser tabs share a session, each receives a copy of every notification (fan-out from USP Bridge). The UI handles this appropriately:

**For state updates** (ValueChange, ObjectCreation, ObjectDeletion):
- Each tab independently applies the state change
- No deduplication needed—applying the same state multiple times is idempotent

**For event-driven side effects** (user-visible alerts, sounds, logging):
- UI should deduplicate to avoid duplicate toasts/alerts across tabs
- Recommended pattern: Use BroadcastChannel API where available (Chrome, Firefox, Safari 15.4+). For broader compatibility, fall back to localStorage change events for cross-tab coordination. Mobile apps do not require deduplication as each device has its own session.

### Notification Deduplication

```dart
class NotificationDeduplicator {
  final _processedIds = <String>{};
  final _channel = html.BroadcastChannel('usp-notifications');
  
  NotificationDeduplicator() {
    _channel.onMessage.listen((event) {
      _processedIds.add(event.data as String);
    });
  }
  
  /// Returns true if this tab should process the side effect
  bool shouldProcess(String subscriptionId, Uint8List payload) {
    // Generate deduplication key from subscription + payload hash
    final hash = sha256.convert(payload).toString().substring(0, 16);
    final dedupeKey = '$subscriptionId:$hash';
    
    if (_processedIds.contains(dedupeKey)) {
      return false;
    }
    _processedIds.add(dedupeKey);
    _channel.postMessage(dedupeKey);
    
    // Clean up old keys periodically
    if (_processedIds.length > 1000) {
      _processedIds.clear();
    }
    
    return true;
  }
}
```

**Usage**:
```dart
void _handleNotification(String subscriptionId, Uint8List record) {
  // Always apply state updates (idempotent)
  _applyStateUpdate(subscriptionId, record);
  
  // Deduplicate side effects
  if (_deduplicator.shouldProcess(subscriptionId, record)) {
    _showToast('WiFi settings changed');
  }
}
```

**Note**: This deduplication is for browser tabs only. Multiple devices have separate sessions and don't need cross-device deduplication.

### Turbo Channel SSE Events

When turbo channel state changes, all SSE clients receive a `turbo_channel` event:

```dart
void _handleTurboChannelEvent(Map<String, dynamic> data) {
  final available = data['available'] as bool;
  
  if (!available) {
    final state = data['state'] as String;  // "pending" or "in_use"
    final ownerSessionId = data['session_id'] as String?;
    final isOurs = ownerSessionId == _sessionId;
    
    _turboAvailability.add(TurboAvailabilityEvent(
      available: false,
      state: state,
      isOwnSession: isOurs,
      operation: data['operation'] as String?,
    ));
  } else {
    _turboAvailability.add(TurboAvailabilityEvent(available: true));
  }
}
```

**UI behavior**:
- `available: false`, `state: "pending"`: Someone is acquiring the channel
- `available: false`, `state: "in_use"`, `isOwnSession: true`: Another tab in this session is using turbo
- `available: false`, `state: "in_use"`, `isOwnSession: false`: Another device/session is using turbo
- `available: true`: Turbo channel is available for use

### Turbo Channel Coordination

```dart
client.turboAvailability.listen((event) {
  if (!event.available) {
    setState(() => _turboAvailable = false);
    if (event.state == 'pending') {
      showInfo('${event.operation} is starting...');
    } else if (event.isOwnSession) {
      showInfo('${event.operation} running in another tab');
    } else {
      showInfo('${event.operation} running on another device');
    }
  } else {
    setState(() => _turboAvailable = true);
  }
});
```

### Multi-Tab Turbo Channel Behavior

Within a session (multiple browser tabs):

- **First-come-first-served**: The first tab to call `acquireTurboChannel()` gets the channel
- **Other tabs see busy**: Subsequent tabs calling `getTurboStatus()` will see `in_use` with their own `session_id`
- **No sharing**: Tabs cannot join an existing turbo WebSocket; each tab must wait for the channel to be released

**Recommended UI pattern**:
```dart
final status = await client.getTurboStatus();

if (status.state == 'pending') {
  // Someone is in the process of acquiring - wait briefly
  showInfo('Please wait, channel is being acquired...');
} else if (!status.available && status.sessionId == _sessionId) {
  // Our session owns the channel - another tab is using it
  showInfo('Packet capture is running in another tab');
} else if (!status.available) {
  // Different session owns the channel
  showInfo('Packet capture in use by another device');
} else {
  // Available - proceed with acquisition
  final channel = await client.acquireTurboChannel(operation: 'packet_capture');
  // ...
}
```

---

## Subscriptions

### Creating Subscriptions

```dart
Future<String> createSubscription({
  required String shortId,
  required String notifType,
  required List<String> paths,
  int ttlSeconds = 3600,
}) async {
  final fullId = _prefixSubscriptionId(shortId);
  
  // Step 1: Check if subscription already exists
  final exists = await _checkSubscriptionExists(fullId);
  
  // Step 2: Create if not exists
  if (!exists) {
    await _createSubscriptionInObuspa(
      id: fullId,
      notifType: notifType,
      paths: paths,
      ttlSeconds: ttlSeconds,
    );
  }
  
  // Step 3: Register mapping with USP Bridge (always)
  await _registerSubscriptionMapping(fullId);
  
  // Track for TTL refresh
  _subscriptions[fullId] = _SubscriptionState(
    id: fullId,
    notifType: notifType,
    paths: paths,
    ttlSeconds: ttlSeconds,
  );
  
  return fullId;
}
```

**Multi-Tab Subscription Ownership**: Each tab independently creates and refreshes subscriptions for the data it needs. When a new tab opens, it should establish its own subscriptions rather than assuming another tab is maintaining them. 
The check-then-create pattern ensures no duplicates are created in OBUSPA, and multiple tabs refreshing the same subscription TTL is harmless (idempotent). This guarantees subscriptions remain active as long as at least one tab needs them.

### TTL Refresh

```dart
static const subscriptionTtl = 3600;        // 1 hour
static const ttlRefreshInterval = Duration(minutes: 30);
static const ttlRetryInterval = Duration(minutes: 2);

Future<void> _refreshTtlWithRetry(String subscriptionId) async {
  final state = _subscriptions[subscriptionId];
  if (state == null) return;
  
  try {
    await set({
      'Device.LocalAgent.Subscription.[ID=="$subscriptionId"].TimeToLive': 
          subscriptionTtl,
    });
    // Success - reset to normal refresh interval
    state.nextRefresh = DateTime.now().add(ttlRefreshInterval);
    state.inRetryMode = false;
  } catch (e) {
    // TTL refresh failed - schedule faster retry
    state.nextRefresh = DateTime.now().add(ttlRetryInterval);
    state.inRetryMode = true;
    
    print('Warning: TTL refresh failed for $subscriptionId, '
        'retrying in ${ttlRetryInterval.inSeconds}s');
  }
}
```

---

## Turbo Channel

### Acquiring the Turbo Channel

The turbo channel WebSocket connection is managed entirely by the `usp-client` library (Rust). The Dart binding provides a simple wrapper that delegates to the native library via FFI.

```dart
/// Dart binding (delegates to usp-client via FFI)
Future<TurboChannel> acquireTurboChannel({
  required String operation,
}) async {
  // Call into usp-client (Rust) which handles:
  // 1. POST /api/turbo/start to acquire channel
  // 2. WebSocket connection with TR-369 protocol header
  // 3. WebSocketConnectRecord exchange
  // 4. First heartbeat to transition PENDING → IN_USE
  final handlePtr = await _ffi.usp_client_turbo_acquire(
    _clientHandle,
    operation.toNativeUtf8(),
  );

  if (handlePtr == nullptr) {
    final error = _ffi.usp_client_get_last_error(_clientHandle);
    throw TurboChannelException(error.toDartString());
  }

  final channel = TurboChannel._(
    handle: handlePtr,
    ffi: _ffi,
  );

  _activeTurboChannel = channel;
  return channel;
}
```

**Why usp-client handles WebSocket:**
- Keeps all transport logic in one place (Rust library)
- Language plugins don't need WebSocket implementations
- Consistent behavior across Dart, TypeScript, Swift, etc.
- TR-369 compliance (protocol headers, ConnectRecord) implemented once

### TurboChannel Class

The `TurboChannel` class is a thin Dart wrapper around an opaque handle managed by usp-client.

```dart
class TurboChannel {
  final Pointer<Void> _handle;
  final UspClientFfi _ffi;
  final _events = StreamController<UspEvent>.broadcast();

  bool _closed = false;

  TurboChannel._({
    required Pointer<Void> handle,
    required UspClientFfi ffi,
  }) : _handle = handle,
       _ffi = ffi {
    // Register callback for events from usp-client
    _ffi.usp_client_turbo_set_callback(_handle, _onEvent);
  }

  void _onEvent(Pointer<Utf8> eventJson) {
    final data = jsonDecode(eventJson.toDartString());
    _events.add(UspEvent.fromJson(data));
  }

  /// Stream of USP events (notifications) from OBUSPA
  Stream<UspEvent> get events => _events.stream;

  /// Send USP Operate command via turbo channel
  Future<OperateResponse> operate(
    String command, {
    Map<String, dynamic>? inputs,
  }) async {
    final inputsJson = inputs != null ? jsonEncode(inputs) : null;

    // Delegate to usp-client which sends via WebSocket
    final resultPtr = await _ffi.usp_client_turbo_operate(
      _handle,
      command.toNativeUtf8(),
      inputsJson?.toNativeUtf8() ?? nullptr,
    );

    return OperateResponse.fromJson(
      jsonDecode(resultPtr.toDartString()),
    );
  }

  /// Close the turbo channel and release it
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    // usp-client handles:
    // 1. Stop heartbeat timer
    // 2. Close WebSocket
    // 3. POST /api/turbo/release
    _ffi.usp_client_turbo_close(_handle);

    await _events.close();
  }
}
```

### usp-client Turbo Channel C ABI

The Rust `usp-client` exposes these functions for turbo channel management:

```c
// Acquire turbo channel (blocks until WebSocket connected)
// Internally: POST /api/turbo/start, WebSocket connect, handshake, first heartbeat
void* usp_client_turbo_acquire(UspClient* client, const char* operation);

// Send Operate command via WebSocket
const char* usp_client_turbo_operate(void* channel, const char* command, const char* inputs_json);

// Register callback for incoming events
void usp_client_turbo_set_callback(void* channel, void (*callback)(const char* event_json));

// Close channel (WebSocket close + POST /api/turbo/release)
void usp_client_turbo_close(void* channel);

// Check turbo channel status (does not acquire)
const char* usp_client_turbo_status(UspClient* client);
```

**Internal behavior** (in Rust):
- WebSocket connection uses `v1.usp` protocol header per TR-369
- Automatic `WebSocketConnectRecord` exchange before returning handle
- Background thread for periodic heartbeats (`/api/turbo/heartbeat`)
- Automatic cleanup on close or error

### Turbo Channel Usage Pattern

```dart
Stream<PacketData> capturePackets() async* {
  final channel = await client.acquireTurboChannel(operation: 'packet_capture');
  
  try {
    // Heartbeats are sent automatically by TurboChannel
    yield* channel.events.map((e) => PacketData._fromEvent(e));
  } finally {
    // Always close to stop heartbeats and release channel promptly
    await channel.close();
  }
}
```

---

## Connection Lifecycle

### Initial Connection

```dart
final client = UspClient('https://192.168.1.1');

// Set up auth callback
client.onAuthRequired = () {
  Navigator.pushReplacementNamed(context, '/login');
};

// 1. Authenticate (cookie set automatically for web)
await client.login(password);

// 2. Connect SSE for notifications (discovers session_id)
await client.connectNotifications();

// 3. Set up subscriptions (uses session_id for prefixing)
final wifiSub = await WifiSettings.subscribe(client);

// 4. Ready for normal operations
final settings = await WifiSettings.get(client);
```

### Reconnection

On SSE disconnect or network failure:

```dart
void _handleSseError() async {
  // 1. Attempt to reconnect SSE (cookie still valid)
  await _reconnectWithBackoff();
  
  // 2. session_id rediscovered from connected event
  
  // 3. Recreate all subscriptions (check existence first)
  for (final sub in _subscriptions.values) {
    await _recreateSubscription(sub);
  }
  
  // 4. Refresh cached state
  await _refreshAllCachedState();
}
```

### Turbo Channel Cleanup

Turbo channel is released when any of the following occur:
- `channel.close()` called (sends explicit release to USP Bridge)
- Operation completes and UI closes the channel
- Browser tab is closed (WebSocket closes, then heartbeat timeout)
- **Heartbeat timeout** (5 minutes of no heartbeats received by USP Bridge)
- Maximum duration exceeded (30 minutes)

**Important**: Always call `channel.close()` when done to release the channel immediately.

---

## Error Handling

### Transport Errors

```dart
try {
  await client.set({'Device.WiFi.SSID.1.SSID': 'NewName'});
} on UspTransportException catch (e) {
  if (e.statusCode == 401) {
    showError('Session expired, please log in again');
  } else if (e.statusCode == 503) {
    showError('Router agent unavailable, please wait');
  }
}
```

### USP Errors

```dart
try {
  await client.set({'Device.Invalid.Path': 'value'});
} on UspErrorException catch (e) {
  switch (e.code) {
    case 7012:
      showError('Configuration path not found');
      break;
    case 7010:
      showError('Permission denied');
      break;
    default:
      showError('Error ${e.code}: ${e.message}');
  }
}
```

### Turbo Channel Errors

```dart
try {
  final channel = await client.acquireTurboChannel(operation: 'packet_capture');
} on TurboChannelBusyException catch (e) {
  showError('${e.operation} in progress. Please wait.');
} on TurboChannelException catch (e) {
  showError(e.message);
} on WebSocketException catch (e) {
  showError('Connection failed: ${e.message}');
}
```

---

## Mobile App Considerations

### Lifecycle Management

Mobile apps have unique constraints that browsers don't:

| Event | Action |
|-------|--------|
| App backgrounded | Close SSE connection, let subscriptions survive via TTL |
| App foregrounded | Reconnect SSE, verify subscriptions, refresh state |
| Turbo operation + background | Release channel if operation is interruptible |

```dart
void _handleAppLifecycle(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
      // App going to background
      _sseConnection?.close();
      if (_activeTurboChannel != null) {
        // Consider releasing if operation is interruptible
        _activeTurboChannel?.close();
      }
      break;
      
    case AppLifecycleState.resumed:
      // App returning to foreground
      _reconnectIfNeeded();
      break;
      
    default:
      break;
  }
}
```

### Token Management

Mobile apps must handle token storage and refresh explicitly:

```dart
class MobileTokenManager {
  final FlutterSecureStorage _storage;
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'usp_token');
  }
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'usp_token', value: token);
  }
  
  Future<void> clearToken() async {
    await _storage.delete(key: 'usp_token');
  }
}
```

---

## Appendix A: Error Codes

### HTTP-Level Errors

| Status | Meaning | UI Action |
|--------|---------|-----------|
| 400 | Bad Request | Bug in client code |
| 401 | Unauthorized | Re-authenticate |
| 503 | Service Unavailable | Retry with backoff |
| 504 | Gateway Timeout | Retry operation |

### USP-Level Errors

| Code | Meaning | UI Action |
|------|---------|-----------|
| 7000 | Message failed | Show generic error |
| 7001 | Message not supported | Feature not available |
| 7004 | Invalid arguments | Bug in client code |
| 7010 | Request denied | Permission error |
| 7012 | Invalid path | Path doesn't exist |
| 7022 | Command failure | Operation failed |
| 7026 | Invalid value | Validation error |

---

## Appendix B: Subscription Parameters

Required parameters when creating subscriptions:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `ID` | `${session_id}-${short_id}` | Prefixed for uniqueness |
| `NotifType` | `ValueChange`, etc. | Event type |
| `ReferenceList` | Path expression | What to monitor |
| `Recipient` | Controller path | Target controller |
| `TimeToLive` | 3600 (recommended) | Auto-delete timeout |

---

## Appendix C: Turbo Channel Operations

Operations requiring turbo channel:

| Operation | USP Command | Description |
|-----------|-------------|-------------|
| Packet Capture | `Device.IP.Diagnostics.PacketCapture()` | Real-time streaming |
| Log Export | `Device.DeviceInfo.VendorLogFile.*.Upload()` | Large file transfer |

**UI behavior**:
1. Check `client.getTurboStatus()` before starting
2. If `state: "pending"`, wait briefly and retry
3. If `state: "in_use"`, show status and offer to wait
4. Acquire channel with `client.acquireTurboChannel()`
5. WebSocket handshake completes automatically (wait for OBUSPA's ConnectRecord)
6. First heartbeat sent automatically to confirm connection (PENDING → IN_USE)
7. Perform operation via returned `TurboChannel`
8. **Periodic heartbeats sent automatically** by TurboChannel
9. Always close channel in `finally` block to release promptly

**TR-369 Compliance Notes**:
- WebSocket connection includes `Sec-WebSocket-Protocol: v1.usp` header
- Endpoint ID is passed in URL query parameter (`?eid=...`)
- URL is provided by `/api/turbo/start` response with proper encoding
- `WebSocketConnectRecord` exchange must complete before sending USP Records

---

## Appendix D: Data Types

```dart
class TurboStatus {
  final bool available;
  final String? state;  // "pending" or "in_use"
  final String? currentOperation;
  final String? sessionId;
  final DateTime? startedAt;

  TurboStatus._fromJson(Map<String, dynamic> json)
      : available = json['available'] ?? true,
        state = json['state'],
        currentOperation = json['current']?['operation'],
        sessionId = json['current']?['session_id'],
        startedAt = json['current']?['started_at'] != null
            ? DateTime.parse(json['current']['started_at'])
            : null;
}

class TurboAvailabilityEvent {
  final bool available;
  final String? state;  // "pending" or "in_use"
  final bool isOwnSession;
  final String? operation;

  TurboAvailabilityEvent({
    required this.available,
    this.state,
    this.isOwnSession = false,
    this.operation,
  });
}

class TurboChannelBusyException implements Exception {
  final String operation;
  final String sessionId;

  TurboChannelBusyException({
    required this.operation,
    required this.sessionId,
  });

  @override
  String toString() => 'Turbo channel busy: $operation (session: $sessionId)';
}

class TurboChannelException implements Exception {
  final String message;

  TurboChannelException(this.message);

  @override
  String toString() => 'TurboChannelException: $message';
}

class UspAuthException implements Exception {
  final String message;
  UspAuthException(this.message);
  
  @override
  String toString() => 'UspAuthException: $message';
}

class UspTransportException implements Exception {
  final int statusCode;
  final String body;
  
  UspTransportException(this.statusCode, this.body);
  
  @override
  String toString() => 'UspTransportException: $statusCode - $body';
}

class UspErrorException implements Exception {
  final int code;
  final String message;
  
  UspErrorException(this.code, this.message);
  
  @override
  String toString() => 'UspErrorException: $code - $message';
}
```
