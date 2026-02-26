# USP Definition YAML Specification

This document describes the YAML format supported by `usp-codegen`, based on the current implementation (parser, AST, generators).

---

## Table of Contents

- [1. Definition File](#1-definition-file)
  - [1.1 Top-Level Fields](#11-top-level-fields)
  - [1.2 Parameters](#12-parameters)
  - [1.3 Presets](#13-presets)
  - [1.4 Subscribe](#14-subscribe)
  - [1.5 Multi-Instance Definitions](#15-multi-instance-definitions)
- [2. Extension File](#2-extension-file)
  - [2.1 Top-Level Fields](#21-top-level-fields)
  - [2.2 Formula Transform](#22-formula-transform)
  - [2.3 Mapping Transform](#23-mapping-transform)
- [3. Type Mapping](#3-type-mapping)
- [4. Path Conventions](#4-path-conventions)
- [5. Naming Conventions](#5-naming-conventions)
- [6. CLI Options](#6-cli-options)
- [7. Full Examples](#7-full-examples)

---

## 1. Definition File

A definition file describes a set of USP parameters and their properties. File naming: `{name}.yaml`.

### 1.1 Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Module name (camelCase or PascalCase). The generator auto-converts to PascalCase for class names |
| `description` | string | **Yes** | Module description |
| `parameters` | array | **Yes** | Array of parameter definitions |
| `version` | string | No | Semantic version (e.g., `1.0.0`) |
| `instance` | string | No | TR-181 single-instance path (e.g., `Device.WiFi.SSID.1`). Generates a data class with `fetch()` and `save()` methods |
| `basePath` | string | No | TR-181 multi-instance base path (e.g., `Device.Hosts.Host.`). Used with `multiInstance: true` |
| `multiInstance` | boolean | No | Set to `true` to generate a data class + collection class pattern (default: `false`). Alias: `multi_instance` |
| `singularName` | string | No | Override the auto-derived singular name for multi-instance definitions. Alias: `singular_name` |
| `type` | string | No | Definition type hint (e.g., `get`, `set`, `add`). Accepted by schema validator but not parsed into AST or used for code generation |
| `category` | string | No | Category tag (e.g., `core`, `extensions`, `vendor`). Accepted by schema validator but not parsed into AST or used for code generation |
| `presets` | array | No | Preset configuration groups |
| `subscribe` | object | No | Subscription configuration |

```yaml
name: DNSSettings
version: 1.0.0
instance: Device.DNS.Client
category: core
description: DNS client configuration

parameters: [...]
presets: [...]
subscribe: {...}
```

### 1.2 Parameters

Each parameter describes a single USP data model parameter.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | string | **Yes** | TR-181 relative path or parameter name |
| `field_name` | string | No | Field name in generated code. Falls back to `path` when omitted |
| `type` | string | No | Parameter type (default: `string`) |
| `description` | string | No | Parameter description, generated as doc comment |
| `writable` | boolean | No | Whether the parameter is writable (default: `false` = read-only) |
| `sensitive` | boolean | No | Whether the parameter contains sensitive data (default: `false`) |
| `default_value` | string \| number \| boolean | No | Default value |

#### Supported `type` Values

| type | Description | Dart | TypeScript | Swift |
|------|-------------|------|------------|-------|
| `string` | String (default) | `String` | `string` | `String` |
| `int` | Signed integer | `int` | `number` | `Int` |
| `uint` | Unsigned integer | `int` | `number` | `UInt` |
| `long` | Long integer | `int` | `number` | `Int64` |
| `ulong` | Unsigned long integer | `int` | `number` | `UInt64` |
| `boolean` | Boolean | `bool` | `boolean` | `Bool` |
| `datetime` | Date/time | `String` | `string` | `String` |
| `base64` | Base64-encoded | `String` | `string` | `String` |
| `hexbinary` | Hex binary | `String` | `string` | `String` |
| `decimal` / `float` / `double` | Floating point | `double` | `number` | `Double` |

#### Access Modes

- `writable: false` (default) — generates getter methods only, no setter/save
- `writable: true` — generates both getter and setter/save methods

```yaml
parameters:
  - field_name: ssid
    path: SSID
    type: string
    writable: true
    description: Network name
    default_value: "Linksys"

  - path: MACAddress
    type: string
    writable: false
    sensitive: false
    description: Hardware address
```

### 1.3 Presets

Presets define predefined configuration templates. The top level is an **array of groups**, each group containing multiple options.

#### Preset Group

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `field` | string | **Yes** | Group identifier (camelCase), used to generate enum name |
| `description` | string | No | Group description |
| `options` | array | **Yes** | Array of preset options |

#### Preset Option

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | **Yes** | Option identifier (e.g., `google`, `cloudflare`) |
| `label` | string | No | i18n display key (e.g., `dns_provider_google`) |
| `description` | string | No | Option description |
| `values` | array | No | Array of fixed parameter settings |
| `userInputs` | array | No | Array of user input field definitions |

#### Preset Value

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | string | **Yes** | Relative TR-181 path (starting with `.`) |
| `value` | string \| number \| boolean | **Yes** | Value to set |
| `instance` | integer | No | Instance number (0 = not set) |

#### User Input

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `field` | string | **Yes** | Input field name (e.g., `customPrimaryDns`) |
| `path` | string | **Yes** | Relative TR-181 path (starting with `.`) |
| `type` | string | No | Type (e.g., `string`) |
| `label` | string | No | i18n label key |
| `placeholder` | string | No | i18n placeholder key |
| `validation` | string | No | Validation rule (e.g., `ipv4`) |
| `instance` | integer | No | Instance number |

```yaml
presets:
  - field: dnsProvider
    description: DNS provider selection
    options:
      - id: google
        label: dns_provider_google
        description: Google Public DNS
        values:
          - path: .Server.1.DNSServer
            value: "8.8.8.8"
          - path: .Server.2.DNSServer
            value: "8.8.4.4"

      - id: custom
        label: dns_provider_custom
        description: Custom DNS servers
        userInputs:
          - field: customPrimaryDns
            path: .Server.1.DNSServer
            type: string
            label: custom_primary_dns
            placeholder: enter_primary_dns
            validation: ipv4
```

#### Generated Output

- **Dart**: top-level `{GroupPascal}Preset` enum + `apply{GroupPascal}Preset()` method
- **TypeScript**: top-level `{GroupPascal}Preset` enum + `apply{GroupPascal}Preset()` function
- **Swift**: nested `{GroupPascal}Preset` enum + `apply{GroupPascal}Preset()` method

### 1.4 Subscribe

Subscription configuration. When `enabled: true`, the generator produces subscription methods.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `enabled` | boolean | **Yes** | Must be `true` to generate subscription code |
| `id` | string | No | Subscription identifier (e.g., `wifi-settings-01`) |
| `notifType` | string | No | Notification type |
| `paths` | array | No | Subscription path array (currently only the first element is used) |
| `description` | string | No | Description |

#### Supported `notifType` Values

| Value | Description |
|-------|-------------|
| `ValueChange` | Parameter value changed |
| `ObjectCreation` | Object created |
| `ObjectDeletion` | Object deleted |
| `OperationComplete` | Operation completed |
| `Event` | Event notification |

```yaml
subscribe:
  enabled: true
  notifType: ValueChange
  id: wifi-settings-01
```

### 1.5 Multi-Instance Definitions

When `multiInstance: true` is set, the generator produces **two classes** instead of one:

1. **Singular data class** (immutable) — represents a single instance row with an `instancePath` field plus all parameter fields
2. **Collection class** — holds a `List`/array of singular instances, with a `fetch()` method that uses `getInstances()` to enumerate all instances

When the definition also contains **writable parameters** (`writable: true`), the generator additionally produces:

3. **Update class** — carries optional writable field values for a single instance (read-only fields are excluded)
4. **`update()` method** — updates a single instance's writable fields in one USP Set call
5. **`updateMany()` method** — updates multiple instances in a single atomic USP Set call, with `allowPartial` control

The singular name is derived automatically by stripping the trailing `s` from `name`. Use `singularName` to override this when the auto-derivation is incorrect (e.g., plurals that don't end in `s`, or irregular plurals).

#### Path Resolution

- Use `basePath` with `multiInstance: true` for dynamic collections (e.g., `Device.Hosts.Host.`)
- Do **not** use `instance` with `multiInstance: true`; `instance` is reserved for single-instance data class generation

#### Example

```yaml
name: connectedDevices
description: Connected devices on the network
multiInstance: true
basePath: Device.Hosts.Host.
singularName: connectedDevice  # optional override

parameters:
  - field_name: hostName
    path: .HostName
    type: string
    writable: true
    description: Device hostname

  - field_name: ipAddress
    path: .IPAddress
    type: string
    description: IP address

  - field_name: active
    path: .Active
    type: boolean
    writable: true
    description: Whether the device is currently active
```

#### Generated Output (Dart)

```dart
class ConnectedDevice {
  final String instancePath;
  final String hostName;
  final String ipAddress;
  final bool active;

  const ConnectedDevice({
    required this.instancePath,
    required this.hostName,
    required this.ipAddress,
    required this.active,
  });
}

/// Only writable fields (hostName, active); read-only fields (ipAddress) excluded
class ConnectedDeviceUpdate {
  final String instancePath;
  final String? hostName;
  final bool? active;

  const ConnectedDeviceUpdate({
    required this.instancePath,
    this.hostName,
    this.active,
  });
}

class ConnectedDevices {
  final List<ConnectedDevice> items;

  const ConnectedDevices({required this.items});

  static Future<ConnectedDevices> fetch(UspService client) async {
    final response = await client.get(['Device.Hosts.Host.']);
    return ConnectedDevices._fromResponse(response);
  }

  factory ConnectedDevices._fromResponse(Map<String, dynamic> response) { ... }

  /// Update a single instance via USP Set
  static Future<void> update(UspService client, ConnectedDeviceUpdate update) async {
    final params = <String, dynamic>{};
    if (update.hostName != null) params['${update.instancePath}HostName'] = update.hostName;
    if (update.active != null) params['${update.instancePath}Active'] = update.active;
    if (params.isNotEmpty) await client.set(params);
  }

  /// Update multiple instances in a single USP Set
  static Future<void> updateMany(UspService client, List<ConnectedDeviceUpdate> updates, {bool allowPartial = false}) async {
    final params = <String, dynamic>{};
    for (final update in updates) {
      if (update.hostName != null) params['${update.instancePath}HostName'] = update.hostName;
      if (update.active != null) params['${update.instancePath}Active'] = update.active;
    }
    if (params.isNotEmpty) await client.set(params, allowPartial: allowPartial);
  }
}
```

#### Generated Output (TypeScript)

```typescript
export interface ConnectedDevice {
  readonly instancePath: string;
  readonly hostName: string;
  readonly ipAddress: string;
  readonly active: boolean;
}

export interface ConnectedDevices {
  readonly items: ConnectedDevice[];
}

/// Only writable fields; read-only fields (ipAddress) excluded
export interface ConnectedDeviceUpdate {
  readonly instancePath: string;
  hostName?: string;
  active?: boolean;
}

export async function fetchConnectedDevices(client: UspClient): Promise<ConnectedDevices> {
  const response = await client.get(['Device.Hosts.Host.']);
  const instances = response.getInstances('Device.Hosts.Host.');
  const items: ConnectedDevice[] = instances.map(instance => ({ ... }));
  return { items };
}

export async function updateConnectedDevice(client: UspClient, update: ConnectedDeviceUpdate): Promise<void> {
  const params: Record<string, any> = {};
  if (update.hostName !== undefined) params[`${update.instancePath}HostName`] = update.hostName;
  if (update.active !== undefined) params[`${update.instancePath}Active`] = update.active;
  if (Object.keys(params).length > 0) await client.setMultiple(params, false);
}

export async function updateConnectedDevices(client: UspClient, updates: ConnectedDeviceUpdate[], allowPartial = false): Promise<void> {
  const params: Record<string, any> = {};
  for (const update of updates) {
    if (update.hostName !== undefined) params[`${update.instancePath}HostName`] = update.hostName;
    if (update.active !== undefined) params[`${update.instancePath}Active`] = update.active;
  }
  if (Object.keys(params).length > 0) await client.setMultiple(params, allowPartial);
}
```

#### Generated Output (Swift)

```swift
public struct ConnectedDevice {
    public let instancePath: String
    public let hostName: String
    public let ipAddress: String
    public let active: Bool
}

/// Only writable fields; read-only fields (ipAddress) excluded
public struct ConnectedDeviceUpdate {
    public let instancePath: String
    public var hostName: String?
    public var active: Bool?

    public init(instancePath: String, hostName: String? = nil, active: Bool? = nil) {
        self.instancePath = instancePath
        self.hostName = hostName
        self.active = active
    }
}

public class ConnectedDevices {
    public let items: [ConnectedDevice]

    public static func fetch(client: UspClient) async throws -> ConnectedDevices { ... }

    public static func update(client: UspClient, _ update: ConnectedDeviceUpdate) async throws {
        var params: [String: Any] = [:]
        if let hostName = update.hostName { params["\(update.instancePath)HostName"] = hostName }
        if let active = update.active { params["\(update.instancePath)Active"] = active }
        guard !params.isEmpty else { return }
        try await client.set(params)
    }

    public static func updateMany(client: UspClient, _ updates: [ConnectedDeviceUpdate], allowPartial: Bool = false) async throws {
        var params: [String: Any] = [:]
        for update in updates {
            if let hostName = update.hostName { params["\(update.instancePath)HostName"] = hostName }
            if let active = update.active { params["\(update.instancePath)Active"] = active }
        }
        guard !params.isEmpty else { return }
        try await client.set(params, allowPartial: allowPartial)
    }
}
```

---

## 2. Extension File

Extension files define computed properties, generated as `extension` blocks (Dart/Swift) or standalone functions (TypeScript).

### File Matching Rules

- Definition file: `{name}.yaml`
- Extension file: `{name}_ext.yaml`
- Matched by the `name` field

### 2.1 Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Must exactly match the definition file's `name` |
| `transforms` | array \| object | **Yes** | Computed property definitions |

When `transforms` is an object, each key is used as the property name.

### 2.2 Formula Transform

Computes a derived value from multiple parameters.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Property name (camelCase) |
| `type` | string | **Yes** | Must be `formula` |
| `formula` | string | **Yes** | Computation formula string |
| `inputs` | array | **Yes** | Array of input parameter names (must match definition `path` values) |
| `output_type` | string | No | Output type (e.g., `double`, `int`, `string`) |
| `description` | string | No | Description |

```yaml
transforms:
  - name: throughputMbps
    type: formula
    description: Download throughput in Mbps
    formula: "(TestBytesReceived * 8) / (TestDuration * 1000)"
    inputs:
      - TestBytesReceived
      - TestDuration
    output_type: double
```

### 2.3 Mapping Transform

Maps a single parameter value to a display string.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Property name (camelCase) |
| `type` | string | **Yes** | Must be `mapping` |
| `input` | string | **Yes** | Input parameter name (must match definition `path`) |
| `mappings` | object | **Yes** | Key-value mapping pairs |
| `description` | string | No | Description |

```yaml
transforms:
  - name: diagnosticsStateDisplay
    type: mapping
    description: Human-readable diagnostic state
    input: DiagnosticsState
    mappings:
      None: "Not started"
      Requested: "Test in progress..."
      Complete: "Test completed successfully"
      Error_InitConnectionFailed: "Connection failed"
```

#### Generated Output

- **Dart**: `extension {Name}Ext on {Name} { ... }` block with synchronous getters (e.g., `double get throughputMbps`)
- **Swift**: `extension {Name} { ... }` block with computed properties (e.g., `public var throughputMbps: Double`)
- **TypeScript**: standalone functions taking the data object (e.g., `export function throughputMbps(data: SpeedTest): number`)

---

## 3. Type Mapping

### Definition Parameter Types

| YAML `type` | Dart | TypeScript | Swift |
|-------------|------|------------|-------|
| `string` | `String` | `string` | `String` |
| `int` | `int` | `number` | `Int` |
| `uint` | `int` | `number` | `UInt` |
| `long` | `int` | `number` | `Int64` |
| `ulong` | `int` | `number` | `UInt64` |
| `boolean` | `bool` | `boolean` | `Bool` |
| `datetime` | `String` | `string` | `String` |
| `base64` | `String` | `string` | `String` |
| `hexbinary` | `String` | `string` | `String` |
| `decimal` / `float` / `double` | `double` | `number` | `Double` |

### Transform Output Types

| `output_type` | Dart | TypeScript | Swift |
|---------------|------|------------|-------|
| `double` | `double` | `number` | `Double` |
| `int` | `int` | `number` | `Int` |
| `string` | `String` | `string` | `String` |
| `boolean` | `bool` | `boolean` | `Bool` |

---

## 4. Path Conventions

- When `instance` or `basePath` is defined, preset values/userInputs `path` fields use **relative paths** (starting with `.`)
- The generator concatenates the full path: `{instance}{path}` -> `Device.DNS.Client.Server.1.DNSServer`
- Concatenation only occurs when `path` starts with `.`; otherwise `path` is used as the full path
- Parameter `path` fields do not include the instance/basePath prefix; the generator handles prefix concatenation

```
instance:  Device.DNS.Client
path:      .Server.1.DNSServer
full path: Device.DNS.Client.Server.1.DNSServer
```

---

## 5. Naming Conventions

| Usage | Convention | Example |
|-------|-----------|---------|
| `name` (module) | camelCase or PascalCase | `connectedDevices`, `DNSSettings` |
| `field` (preset group) | camelCase | `dnsProvider`, `securityMode` |
| `id` (preset option) | lowercase / camelCase | `google`, `openDns` |
| `label` | snake_case with prefix | `dns_provider_google` |
| subscribe `id` | kebab-case with suffix | `wifi-settings-01` |
| `field_name` (parameter) | camelCase | `errorCount` |
| transform `name` | camelCase | `throughputMbps` |

### Output Filename Conventions

| Language | Convention | Example |
|----------|-----------|---------|
| Dart | snake_case | `connected_devices.g.dart`, `dns_settings.g.dart` |
| TypeScript | module_name as-is | `connectedDevices.g.ts`, `DNSSettings.g.ts` |
| Swift | module_name as-is | `connectedDevices.g.swift`, `DNSSettings.g.swift` |

Dart filenames are automatically converted from camelCase/PascalCase to snake_case to follow [Dart file naming conventions](https://dart.dev/effective-dart/style#do-name-libraries-and-source-files-using-lowercase_with_underscores).

---

## 6. CLI Options

```
usp-codegen [OPTIONS]
```

### Required Options

| Option | Description |
|--------|-------------|
| `--definitions-dir DIR` | Directory containing YAML definition files |
| `--output-dir DIR` | Output directory for generated code |
| `--language LANG` | Target language: `dart` \| `typescript` \| `swift` |

### Optional Options

| Option | Description |
|--------|-------------|
| `--client-import PATH` | Custom import path for the client library |
| `--client-class CLASS` | Custom client class name |
| `--validate-paths` | Enable TR-181 path validation |
| `--json` | Output errors in JSON format (for tooling integration) |
| `--help` | Show help message |

### Default Import Paths Per Language

| Language | Default Import |
|----------|---------------|
| Dart | `package:usp_test/services/usp_service.dart` |
| TypeScript | `@usp/client` |
| Swift | `UspClient` |

---

## 7. Full Examples

### Read-Only Definition (single-instance)

```yaml
name: DeviceInfo
version: 1.0.0
instance: Device.DeviceInfo
description: Device information parameters (read-only)

parameters:
  - path: Manufacturer
    type: string
    description: Device manufacturer name

  - path: SoftwareVersion
    type: string
    description: Currently running firmware version

  - path: UpTime
    type: int
    description: Time in seconds since last reboot
```

### Writable Definition with Subscription (using `instance`)

```yaml
name: WiFiBasicSettings
version: 1.0.0
instance: Device.WiFi.SSID.1    # pinned single-instance path
description: Basic WiFi network settings

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: Enable or disable this WiFi network

  - path: SSID
    type: string
    writable: true
    description: Network name (SSID)

  - path: Status
    type: string
    description: Current operational status (Up, Down, Error, etc.)

subscribe:
  enabled: true
  notifType: ValueChange
  id: wifi-settings-01
```

### Preset Definition (single-instance)

```yaml
name: DNSSettings
version: 1.0.0
instance: Device.DNS.Client
description: DNS client configuration with provider presets

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: Enable DNS client

presets:
  - field: dnsProvider
    description: DNS provider selection
    options:
      - id: google
        label: dns_provider_google
        description: Google Public DNS
        values:
          - path: .Server.1.DNSServer
            value: "8.8.8.8"
          - path: .Server.2.DNSServer
            value: "8.8.4.4"

      - id: cloudflare
        label: dns_provider_cloudflare
        description: Cloudflare DNS
        values:
          - path: .Server.1.DNSServer
            value: "1.1.1.1"
          - path: .Server.2.DNSServer
            value: "1.0.0.1"

      - id: custom
        label: dns_provider_custom
        description: Custom DNS servers
        userInputs:
          - field: customPrimaryDns
            path: .Server.1.DNSServer
            type: string
            label: custom_primary_dns
            placeholder: enter_primary_dns
            validation: ipv4
          - field: customSecondaryDns
            path: .Server.2.DNSServer
            type: string
            label: custom_secondary_dns
            placeholder: enter_secondary_dns
            validation: ipv4
```

### Extension File (Computed Properties)

**Definition file: `SpeedTest.yaml`**

```yaml
name: SpeedTest
version: 1.0.0
instance: Device.IP.Diagnostics.DownloadDiagnostics
description: Download speed test results

parameters:
  - path: TestBytesReceived
    type: int
    description: Total bytes received during test

  - path: TestDuration
    type: int
    description: Test duration in milliseconds

  - path: DiagnosticsState
    type: string
    writable: true
    description: Test state
```

**Extension file: `SpeedTest_ext.yaml`**

```yaml
name: SpeedTest
transforms:
  - name: throughputMbps
    type: formula
    description: Download throughput in megabits per second
    formula: "(TestBytesReceived * 8) / (TestDuration * 1000)"
    inputs:
      - TestBytesReceived
      - TestDuration
    output_type: double

  - name: diagnosticsStateDisplay
    type: mapping
    description: Human-readable diagnostic state
    input: DiagnosticsState
    mappings:
      None: "Not started"
      Requested: "Test in progress..."
      Complete: "Test completed successfully"
```

### Multi-Instance Definition with Writable Fields

```yaml
name: connectedDevices
description: Connected devices on the network
multiInstance: true
basePath: Device.Hosts.Host.

parameters:
  - field_name: hostName
    path: .HostName
    type: string
    writable: true
    description: Device hostname

  - field_name: ipAddress
    path: .IPAddress
    type: string
    description: IP address

  - field_name: active
    path: .Active
    type: boolean
    writable: true
    description: Whether the device is currently active
```

---

## Appendix: Schema Validation

The codegen validates definition file structure before parsing. Current required fields:

- `name` (string)
- `description` (string)
- `parameters` (array)

All other fields are optional. Type mismatches produce errors. Unknown fields produce warnings but do not block generation.
