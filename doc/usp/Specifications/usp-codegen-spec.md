# usp-codegen Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |
| v2 | - | Renamed computations → transforms; transform → converter |
| v3 | - | Unified on YAML format; definitions now YAML (was JSON) |
| v4 | - | Clarified usp-client integration via `--client-import` |

---

## Overview

`usp-codegen` is a code generator that translates YAML definition files into type-safe source code for various languages. It produces classes with getter/setter methods, fetch operations, preset appliers, and transform extensions.

### Purpose

- Parse YAML definition files from `usp-definitions`
- Parse YAML transform files (optional)
- Generate type-safe Dart classes for Flutter
- Generate TypeScript interfaces for web
- Generate Swift classes for iOS
- Validate paths against TR-181 schema (optional)

### Language

C (for portability across build environments)

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              usp-codegen                                      │
│                                                                               │
│  ┌─────────────────┐      ┌─────────────────┐                                 │
│  │  YAML Parser    │      │  YAML Parser    │                                 │
│  │                 │      │                 │                                 │
│  │◄── definitions/ │      │◄── transforms/  │                                 │
│  │    *.yaml       │      │    *.yaml       │                                 │
│  └────────┬────────┘      └────────┬────────┘                                 │
│           │                        │                                          │
│           ▼                        ▼                                          │
│  ┌─────────────────┐      ┌─────────────────┐                                 │
│  │ Definition      │      │ Transform       │                                 │
│  │ Validator       │      │ Validator       │                                 │
│  └────────┬────────┘      └────────┬────────┘                                 │
│           │                        │                                          │
│           ▼                        ▼                                          │
│  ┌─────────────────────────────────────────┐                                  │
│  │           Merged Internal AST           │                                  │
│  │  (definitions + optional transforms)    │                                  │
│  └────────────────────┬────────────────────┘                                  │
│                       │                                                       │
│           ┌───────────┼───────────┐                                           │
│           ▼           ▼           ▼                                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                              │
│  │    Dart     │ │     TS      │ │    Swift    │                              │
│  │  Generator  │ │  Generator  │ │  Generator  │                              │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘                              │
│         │               │               │                                     │
│         ▼               ▼               ▼                                     │
│    *.dart           *.ts           *.swift                                    │
│  (class +         (interface +    (class +                                    │
│   extension)       functions)      extension)                                 │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Key insight**: Transforms are optional. If no YAML file exists for a definition, codegen generates only the base class with raw parameters.

---

## Command Line Interface

### Usage

```bash
usp-codegen [OPTIONS]
```

### Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `--definitions` | path | Yes | Input directory with YAML definition files |
| `--transforms` | path | No | Input directory with YAML transform files |
| `--output` | path | Yes | Output directory for generated code |
| `--lang` | string | Yes | Target language (dart, ts, swift) |
| `--client-import` | string | No | Override default import path for usp-client package |
| `--def-schema` | path | No | YAML schema for definition validation |
| `--transform-schema` | path | No | YAML schema for transform validation |
| `--tr181` | path | No | BBF TR-181 data model XML for path validation |
| `--package` | string | No | Package/module name for generated code exports |
| `--verbose` | flag | No | Enable verbose output |

### Default Client Imports

Each target language has a default usp-client import path. Use `--client-import` only to override:

| Language | Default Import |
|----------|----------------|
| `dart` | `package:usp_client/usp_client.dart` |
| `ts` | `@anthropic/usp-client` |
| `swift` | `UspClient` |

### Examples

```bash
# Generate Dart code (uses default import: package:usp_client/usp_client.dart)
usp-codegen \
    --definitions ./definitions \
    --output ./lib/generated \
    --lang dart

# Generate Dart code with transforms
usp-codegen \
    --definitions ./definitions \
    --transforms ./transforms \
    --output ./lib/generated \
    --lang dart

# Generate TypeScript code for web app
usp-codegen \
    --definitions ./definitions \
    --transforms ./transforms \
    --output ./src/generated \
    --lang ts

# Generate Swift code for iOS app
usp-codegen \
    --definitions ./definitions \
    --output ./Sources/Generated \
    --lang swift

# Override client import (e.g., for a custom or local package)
usp-codegen \
    --definitions ./definitions \
    --output ./lib/generated \
    --lang dart \
    --client-import "package:my_custom_usp_client/client.dart"

# With TR-181 validation (BBF data model compatibility check)
usp-codegen \
    --definitions ./definitions \
    --transforms ./transforms \
    --output ./lib/generated \
    --lang dart \
    --tr181 ./tr-181-2-18-0.xml
```

---

## Generated Code Structure

### Dart Output

```
lib/generated/
├── core/
│   ├── hardware_info.dart
│   ├── wifi_settings.dart
│   ├── connected_devices.dart
│   └── ...
├── extensions/
│   ├── parental_controls.dart
│   └── ...
├── vendor/
│   └── linksys/
│       └── velop_nodes.dart
├── core.dart           # Barrel export
├── extensions.dart     # Barrel export
└── all.dart            # Combined export
```

### TypeScript Output

```
src/generated/
├── core/
│   ├── hardwareInfo.ts
│   ├── wifiSettings.ts
│   └── ...
├── extensions/
│   └── ...
├── index.ts            # Barrel export
└── types.ts            # Shared types
```

---

## usp-client Integration

The generated code depends on a `usp-client` package that provides the actual USP communication layer. Each target language has a **default binding package** that codegen uses automatically. The `--client-import` option allows overriding this default if needed.

### Why This Design?

The `usp-client` library is written in Rust and compiled to:
- **Native libraries** (via FFI) for iOS, Android, macOS, Windows, Linux
- **WASM modules** for web browsers

Each target platform has a language-specific **binding package** that wraps the Rust library. Codegen knows about these defaults:

| Language | Default Package | Default Import |
|----------|-----------------|----------------|
| `dart` | `usp_client` | `package:usp_client/usp_client.dart` |
| `ts` | `@anthropic/usp-client` | `@anthropic/usp-client` |
| `swift` | `UspClient` | `UspClient` |

The generated code imports the binding package and calls its methods. **No manual wiring required** — the generated code is immediately usable with the default plugin.

### Required Exports

The usp-client binding package must export these types and methods. This is the **contract** that codegen generates against:

```
UspClient
├── get(paths: string[]) → GetResponse
├── set(params: Map<string, any>) → void
├── add(path: string, params: Map<string, any>) → string (instance path)
├── delete(path: string) → void
├── operate(path: string, inputs: Map<string, any>) → OperateResponse
├── subscribe<T>(config: SubscriptionConfig) → Subscription<T>
└── acquireTurboChannel(operation: string) → TurboChannel

GetResponse
├── getString(path: string) → string
├── getInt(path: string) → int
├── getBool(path: string) → bool
├── getDateTime(path: string) → DateTime
├── getBase64(path: string) → bytes
└── getInstances(basePath: string) → List<Instance>

Instance
├── path: string
├── getString(relativePath: string) → string
├── getInt(relativePath: string) → int
└── ... (same getters as GetResponse)

Subscription<T>
├── stream: Stream<T>
├── cancel() → void
└── refresh() → void

TurboChannel
├── operate(path: string, inputs: Map) → void
├── events: Stream<UspEvent>
└── close() → void

NotifType (enum)
├── valueChange
├── objectCreation
├── objectDeletion
└── operationComplete
```

### Generated Import Statement

The `--client-import` value is inserted directly into the generated code:

**Dart:**
```dart
// Generated with: --client-import "package:usp_client/usp_client.dart"
import 'package:usp_client/usp_client.dart';
```

**TypeScript:**
```typescript
// Generated with: --client-import "@anthropic/usp-client"
import { UspClient, GetResponse } from '@anthropic/usp-client';
```

**Swift:**
```swift
// Generated with: --client-import "UspClient"
import UspClient
```

### Relationship to usp-client Rust Core

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Generated Code (per language)                       │
│                                                                              │
│  HardwareInfo.fetch(client)  →  client.get([...])  →  parse response        │
│  WifiSettings.save(client)   →  client.set({...})                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ calls
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Language Binding Package (per language)                   │
│                                                                              │
│  Dart: package:usp_client     │  TS: @anthropic/usp-client  │  Swift: ...   │
│  - UspClient class            │  - UspClient class          │               │
│  - Type conversions           │  - Type conversions         │               │
│  - Async handling             │  - Promise handling         │               │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ FFI / WASM
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         usp-client Core (Rust)                               │
│                                                                              │
│  - Protobuf encoding/decoding                                                │
│  - HTTP/SSE transport                                                        │
│  - WebSocket (turbo channel)                                                 │
│  - Session management                                                        │
│  - JWT refresh                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key insight:** The generated code only depends on the binding package API. It doesn't know or care about the Rust implementation underneath. This allows:
1. Swapping the Rust core for a different implementation
2. Testing with mock UspClient implementations
3. Using the same definitions across all platforms

---

## Dart Code Generation

### Read-Only Class

**Input:** `hardware_info.yaml`

**Output:** `hardware_info.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generator: usp-codegen v1.0.0
// Source: core/hardware_info.yaml

import 'package:usp_client/usp_client.dart';

/// Basic hardware identification
class HardwareInfo {
  final String modelName;
  final String modelNumber;
  final String serialNumber;
  final String hardwareVersion;
  final String softwareVersion;
  final int uptime;

  const HardwareInfo({
    required this.modelName,
    required this.modelNumber,
    required this.serialNumber,
    required this.hardwareVersion,
    required this.softwareVersion,
    required this.uptime,
  });

  /// Fetch hardware info from device
  static Future<HardwareInfo> fetch(UspClient client) async {
    final response = await client.get([
      'Device.DeviceInfo.ModelName',
      'Device.DeviceInfo.ModelNumber',
      'Device.DeviceInfo.SerialNumber',
      'Device.DeviceInfo.HardwareVersion',
      'Device.DeviceInfo.SoftwareVersion',
      'Device.DeviceInfo.UpTime',
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
      uptime: response.getInt('Device.DeviceInfo.UpTime'),
    );
  }

  @override
  String toString() => 'HardwareInfo(model: $modelName, serial: $serialNumber)';
}
```

### Writable Class with Subscription

**Input:** `wifi_settings.yaml`

**Output:** `wifi_settings.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:usp_client/usp_client.dart';

/// Primary WiFi network configuration
class WifiSettings {
  final String ssid;
  final bool enabled;
  final String macAddress;
  final String securityMode;
  final String passphrase;

  const WifiSettings({
    required this.ssid,
    required this.enabled,
    required this.macAddress,
    required this.securityMode,
    required this.passphrase,
  });

  static const _paths = [
    'Device.WiFi.SSID.1.SSID',
    'Device.WiFi.SSID.1.Enable',
    'Device.WiFi.SSID.1.MACAddress',
    'Device.WiFi.AccessPoint.1.Security.ModeEnabled',
    'Device.WiFi.AccessPoint.1.Security.KeyPassphrase',
  ];

  /// Fetch WiFi settings from device
  static Future<WifiSettings> fetch(UspClient client) async {
    final response = await client.get(_paths);
    return WifiSettings._fromResponse(response);
  }

  factory WifiSettings._fromResponse(GetResponse response) {
    return WifiSettings(
      ssid: response.getString('Device.WiFi.SSID.1.SSID'),
      enabled: response.getBool('Device.WiFi.SSID.1.Enable'),
      macAddress: response.getString('Device.WiFi.SSID.1.MACAddress'),
      securityMode: response.getString('Device.WiFi.AccessPoint.1.Security.ModeEnabled'),
      passphrase: response.getString('Device.WiFi.AccessPoint.1.Security.KeyPassphrase'),
    );
  }

  /// Update WiFi settings on device
  Future<void> save(
    UspClient client, {
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
    if (params.isNotEmpty) {
      await client.set(params);
    }
  }

  /// Subscribe to WiFi settings changes
  static Future<Subscription<WifiSettings>> subscribe(UspClient client) async {
    return client.subscribe<WifiSettings>(
      id: 'wifi-settings-01',
      notifType: NotifType.valueChange,
      paths: _paths,
      parser: WifiSettings._fromResponse,
    );
  }
}
```

### Multi-Instance Class

**Input:** `connected_devices.yaml`

**Output:** `connected_devices.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:usp_client/usp_client.dart';

/// Single connected device
class ConnectedDevice {
  final String instancePath;
  final String hostName;
  final String ipAddress;
  final String macAddress;
  final bool active;
  final String interface_;
  final String addressSource;

  const ConnectedDevice({
    required this.instancePath,
    required this.hostName,
    required this.ipAddress,
    required this.macAddress,
    required this.active,
    required this.interface_,
    required this.addressSource,
  });
}

/// Devices connected to the network
class ConnectedDevices {
  final List<ConnectedDevice> devices;

  const ConnectedDevices({required this.devices});

  /// Fetch all connected devices
  static Future<ConnectedDevices> fetch(UspClient client) async {
    final response = await client.get(['Device.Hosts.Host.']);
    return ConnectedDevices._fromResponse(response);
  }

  factory ConnectedDevices._fromResponse(GetResponse response) {
    final devices = <ConnectedDevice>[];
    final instances = response.getInstances('Device.Hosts.Host.');

    for (final instance in instances) {
      devices.add(ConnectedDevice(
        instancePath: instance.path,
        hostName: instance.getString('.HostName'),
        ipAddress: instance.getString('.IPAddress'),
        macAddress: instance.getString('.MACAddress'),
        active: instance.getBool('.Active'),
        interface_: instance.getString('.Layer1Interface'),
        addressSource: instance.getString('.AddressSource'),
      ));
    }

    return ConnectedDevices(devices: devices);
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

  /// Subscribe to device changes
  static Future<Subscription<ConnectedDevices>> subscribe(UspClient client) async {
    return client.subscribe<ConnectedDevices>(
      id: 'host-changes-01',
      notifType: NotifType.objectCreation,
      paths: ['Device.Hosts.Host.'],
      parser: ConnectedDevices._fromResponse,
    );
  }
}
```

### Turbo Channel Operation

**Input:** `packet_capture.yaml`

**Output:** `packet_capture.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'dart:typed_data';
import 'package:usp_client/usp_client.dart';

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
    required String interface_,
    int durationSeconds = 60,
    int? maxPackets,
    String? filter,
  }) async* {
    final channel = await _client.acquireTurboChannel(
      operation: 'packet_capture',
    );

    try {
      await channel.operate(
        'Device.IP.Diagnostics.PacketCapture()',
        inputs: {
          'Interface': interface_,
          'Duration': durationSeconds,
          if (maxPackets != null) 'PacketCount': maxPackets,
          if (filter != null) 'FilterExpression': filter,
        },
      );

      await for (final event in channel.events) {
        if (event.name == 'PacketCaptureResult!') {
          yield PacketData._fromEvent(event);
        }
      }
    } finally {
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

  const PacketData({required this.data, required this.timestamp});

  factory PacketData._fromEvent(UspEvent event) {
    return PacketData(
      data: event.getBase64('Data'),
      timestamp: DateTime.now(),
    );
  }
}
```

---

## TypeScript Code Generation

### Example Output

**Input:** `hardware_info.yaml`

**Output:** `hardwareInfo.ts`

```typescript
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generator: usp-codegen v1.0.0
// Source: core/hardware_info.yaml

import { UspClient, GetResponse } from 'usp-client';

/** Basic hardware identification */
export interface HardwareInfo {
  readonly modelName: string;
  readonly modelNumber: string;
  readonly serialNumber: string;
  readonly hardwareVersion: string;
  readonly softwareVersion: string;
  readonly uptime: number;
}

const PATHS = [
  'Device.DeviceInfo.ModelName',
  'Device.DeviceInfo.ModelNumber',
  'Device.DeviceInfo.SerialNumber',
  'Device.DeviceInfo.HardwareVersion',
  'Device.DeviceInfo.SoftwareVersion',
  'Device.DeviceInfo.UpTime',
] as const;

/** Fetch hardware info from device */
export async function fetchHardwareInfo(client: UspClient): Promise<HardwareInfo> {
  const response = await client.get([...PATHS]);
  return parseHardwareInfo(response);
}

function parseHardwareInfo(response: GetResponse): HardwareInfo {
  return {
    modelName: response.getString('Device.DeviceInfo.ModelName'),
    modelNumber: response.getString('Device.DeviceInfo.ModelNumber'),
    serialNumber: response.getString('Device.DeviceInfo.SerialNumber'),
    hardwareVersion: response.getString('Device.DeviceInfo.HardwareVersion'),
    softwareVersion: response.getString('Device.DeviceInfo.SoftwareVersion'),
    uptime: response.getInt('Device.DeviceInfo.UpTime'),
  };
}
```

---

## Transform Processing

### YAML Transform Schema

Transform files use YAML format with the following structure:

```yaml
# File: transforms/core/download_diagnostics.yaml
# Filename must match the definition name (download_diagnostics.yaml)

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

### Transform Types

| Type | Key | Description |
|------|-----|-------------|
| **Formula** | `formula` | Expression using inputs and built-in functions |
| **Map** | `map` | Key-value lookup returning i18n keys |
| **Converter** | `converter` | Single-input conversion function |

### Formula Transform

```yaml
throughputMbps:
  inputs: [bytesReceived, startTime, endTime]
  type: double
  formula: (bytesReceived * 8) / durationSeconds(startTime, endTime) / 1_000_000
  display:
    formatter: bandwidth      # Optional display formatter
    precision: 2              # Formatter-specific options
```

**Generated Dart:**

```dart
extension DownloadDiagnosticsTransforms on DownloadDiagnostics {
  double get throughputMbps {
    final duration = Transforms.durationSeconds(startTime, endTime);
    if (duration <= 0) return 0.0;
    return (bytesReceived * 8) / duration / 1000000;
  }

  String get throughputMbpsDisplay =>
      Transforms.formatBandwidth(throughputMbps, precision: 2);
}
```

### Map Transform

```yaml
qualityLabel:
  inputs: [qualityCode]
  map:
    "0": "network_quality_high"
    "1": "network_quality_medium"
    "2": "network_quality_low"
    "3": "network_quality_poor"
  default: "network_quality_unknown"
```

**Generated Dart:**

```dart
extension NetworkQualityTransforms on NetworkQuality {
  String get qualityLabel {
    switch (qualityCode) {
      case "0": return tr("network_quality_high");
      case "1": return tr("network_quality_medium");
      case "2": return tr("network_quality_low");
      case "3": return tr("network_quality_poor");
      default: return tr("network_quality_unknown");
    }
  }
}
```

**Note:** Map values are i18n keys, not display strings. The `tr()` function is the UI's translation function.

### Converter

```yaml
subnetMaskDotted:
  inputs: [subnetMaskCidr]
  converter: cidrToNetmask
```

**Generated Dart:**

```dart
extension IpSettingsTransforms on IpSettings {
  String get subnetMaskDotted =>
      Transforms.cidrToNetmask(subnetMaskCidr);
}
```

### Built-in Functions

Codegen includes implementations for these functions in each target language:

| Function | Signature | Description |
|----------|-----------|-------------|
| `durationSeconds` | `(DateTime, DateTime) → double` | Time difference in seconds |
| `durationMs` | `(DateTime, DateTime) → int` | Time difference in milliseconds |
| `cidrToNetmask` | `(int) → String` | CIDR to dotted decimal |
| `formatBandwidth` | `(double, precision?) → String` | Human-readable bandwidth |
| `formatDuration` | `(int) → String` | Human-readable duration |
| `formatBytes` | `(int) → String` | Human-readable size |

**Generated Transforms Library (Dart):**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// File: lib/generated/transforms.dart

class Transforms {
  static double durationSeconds(DateTime start, DateTime end) {
    return end.difference(start).inMilliseconds / 1000.0;
  }

  static int durationMs(DateTime start, DateTime end) {
    return end.difference(start).inMilliseconds;
  }

  static String cidrToNetmask(int cidr) {
    if (cidr < 0 || cidr > 32) return "0.0.0.0";
    final mask = cidr == 0 ? 0 : ~((1 << (32 - cidr)) - 1);
    return "${(mask >> 24) & 0xFF}.${(mask >> 16) & 0xFF}.${(mask >> 8) & 0xFF}.${mask & 0xFF}";
  }

  static String formatBandwidth(double mbps, {int precision = 2}) {
    if (mbps >= 1000) {
      return "${(mbps / 1000).toStringAsFixed(precision)} Gbps";
    }
    return "${mbps.toStringAsFixed(precision)} Mbps";
  }

  static String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return "${h}h ${m}m ${s}s";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  static String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return "${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}";
  }
}
```

### Validation Rules

When processing transform files, codegen validates:

1. **Input references**: All inputs must exist as fields in the corresponding definition
2. **Type compatibility**: Input types must be compatible with the transform
3. **Formula syntax**: Formulas must use valid operators and function calls
4. **Map keys**: Map keys must be string literals
5. **Converter functions**: Converter function names must be built-in or registered

### Error Handling

```bash
$ usp-codegen --input ./definitions --transforms ./transforms --output ./lib --lang dart

Error: transforms/core/download_diagnostics.yaml
  - throughputMbps: Input 'byteReceived' not found in definition (did you mean 'bytesReceived'?)
  - unknownField: Input 'foo' not found in definition

Error: transforms/core/network_quality.yaml
  - qualityLabel: Unknown converter function 'customConverter'
```

---

## Internal Data Model

### Definition AST

```c
typedef enum {
    DEF_TYPE_GET,
    DEF_TYPE_SET,
    DEF_TYPE_ADD,
    DEF_TYPE_DELETE,
    DEF_TYPE_OPERATE
} def_type_t;

typedef struct {
    char* path;
    char* field;
    char* type;
    bool writable;
    bool sensitive;
    bool required;
    char* default_value;
} parameter_t;

typedef struct {
    char* name;
    char* description;
    def_type_t type;
    char* instance;
    bool multi_instance;
    char* base_path;
    parameter_t* parameters;
    int param_count;
    // ... related, operations, subscribe
} definition_t;
```

### Transform AST

```c
typedef enum {
    TRANSFORM_TYPE_FORMULA,
    TRANSFORM_TYPE_MAP,
    TRANSFORM_TYPE_CONVERTER
} transform_type_t;

typedef struct {
    char* key;
    char* value;
} map_entry_t;

typedef struct {
    char* formatter;
    int precision;
    // ... other formatter options
} display_t;

typedef struct {
    char* field;              // Generated getter name
    transform_type_t type;    // formula, map, or converter
    char** inputs;            // Input field names from definition
    int input_count;
    char* result_type;        // Output type (double, int, string)

    // For TRANSFORM_TYPE_FORMULA
    char* formula;            // Expression string

    // For TRANSFORM_TYPE_MAP
    map_entry_t* map_entries;
    int map_count;
    char* default_value;

    // For TRANSFORM_TYPE_CONVERTER
    char* converter_func;     // Built-in function name

    // Optional display formatting
    display_t* display;
} transform_t;

typedef struct {
    char* definition_name;    // Matches YAML definition filename
    transform_t* transforms;
    int transform_count;
} transform_file_t;
```

---

## Validation

### YAML Schema Validation

```c
bool validate_definition(const char* yaml_content, const char* schema_path) {
    // Load YAML schema
    yaml_document_t schema;
    if (!yaml_load_file(schema_path, &schema)) return false;

    // Parse definition YAML
    yaml_document_t def;
    if (!yaml_parse(yaml_content, &def)) {
        yaml_document_delete(&schema);
        return false;
    }

    // Validate against schema
    // (using libyaml or similar library)

    yaml_document_delete(&schema);
    yaml_document_delete(&def);
    return true;
}
```

### TR-181 Path Validation

**Purpose:** Validate that definition paths remain compatible with updated BBF TR-181 data model versions. This is a **compatibility check**, not a runtime validation.

**Input:** BBF official TR-181 XML file (e.g., `tr-181-2-18-0.xml` from [Broadband Forum](https://cwmp-data-models.broadband-forum.org/))

**Behavior:**
- Standard paths (e.g., `Device.WiFi.SSID.1.SSID`) are validated against BBF XML
- Vendor extension paths (e.g., `Device.X_LINKSYS_*`) are **skipped** (vendor-specific by definition)
- Warnings for deprecated paths
- Errors for non-existent standard paths

```c
bool validate_tr181_path(const char* path, xml_doc_t* tr181_model) {
    // Skip vendor extensions (X_*)
    if (is_vendor_extension(path)) return true;

    // Parse BBF XML and check if path exists
    xml_node_t* node = find_path_in_model(tr181_model, path);
    if (!node) {
        log_error("Path not found in TR-181 model: %s", path);
        return false;
    }

    // Check if deprecated
    if (is_deprecated(node)) {
        log_warning("Path is deprecated in TR-181: %s", path);
    }

    return true;
}
```

**Example output:**
```bash
$ usp-codegen --definitions ./definitions --tr181 ./tr-181-2-18-0.xml --lang dart

Validating against TR-181 2.18.0...
  ✓ Device.DeviceInfo.ModelName
  ✓ Device.WiFi.SSID.1.SSID
  ⚠ Device.DNS.Client.Server.1.DNSServer (deprecated in 2.16, use Device.DNS.SD.*)
  ✗ Device.WiFi.Radio.1.ChannelBandwidth (not found - did you mean .CurrentOperatingChannelBandwidth?)
  ○ Device.X_LINKSYS_MeshNode.1.NodeID (vendor extension, skipped)

Errors: 1, Warnings: 1, Skipped: 1
```

---

## Build & Deployment

### Build Dependencies

- libyaml-dev (YAML parsing)
- libxml2-dev (BBF TR-181 XML parsing, optional)
- Build tools (make, gcc)

### Makefile

```makefile
CC = gcc
CFLAGS = -Wall -O2
LDFLAGS = -lyaml

# Optional: TR-181 validation support
ifdef WITH_TR181_VALIDATION
CFLAGS += -DWITH_TR181_VALIDATION $(shell pkg-config --cflags libxml-2.0)
LDFLAGS += $(shell pkg-config --libs libxml-2.0)
endif

usp-codegen: main.c parser.c dart_gen.c ts_gen.c swift_gen.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

install: usp-codegen
	install -m 755 usp-codegen /usr/bin/

clean:
	rm -f usp-codegen
```

### OpenWRT Package

```makefile
define Package/usp-codegen
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=USP API Code Generator
  DEPENDS:=+libyaml +libxml2
endef
```

Note: `libxml2` is only needed if TR-181 validation is enabled.

---

## Testing

### Test Cases

**Definition processing:**
1. Parse valid definition files
2. Reject invalid YAML
3. Validate schema compliance
4. Generate correct Dart output
5. Generate correct TypeScript output
6. Handle multi-instance definitions
7. Handle turbo channel operations
8. Handle related instances

**Transform processing:**
9. Parse valid transform YAML files
10. Reject invalid YAML syntax
11. Validate input references against definition
12. Generate formula transforms correctly
13. Generate map transforms with i18n keys
14. Generate converters correctly
15. Generate display formatters
16. Handle missing transform file (generate base class only)
17. Report clear errors for invalid input references

### Test Command

```bash
# Run unit tests
make test

# Generate and compile test output (without transforms)
usp-codegen --input test/definitions --output test/output --lang dart
cd test/output && dart analyze

# Generate and compile test output (with transforms)
usp-codegen \
    --input test/definitions \
    --transforms test/transforms \
    --output test/output \
    --lang dart
cd test/output && dart analyze
```
