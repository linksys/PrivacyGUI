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
  - [1.6 Add/Delete Operations](#16-adddelete-operations)
  - [1.7 Related Parameters](#17-related-parameters)
  - [1.8 Operate Definitions](#18-operate-definitions)
- [2. Extension File](#2-extension-file)
  - [2.1 Top-Level Fields](#21-top-level-fields)
  - [2.2 Formula Transform](#22-formula-transform)
  - [2.3 Mapping Transform](#23-mapping-transform)
  - [2.4 Converter Transform](#24-converter-transform)
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
| `instance` | string | No | TR-181 single-instance path (e.g., `Device.WiFi.SSID.1`). Used as path prefix for parameters with relative paths. See [Path Modes](#path-modes) |
| `basePath` | string | No | TR-181 multi-instance base path (e.g., `Device.Hosts.Host.`). Used with `multiInstance: true`. See [Path Modes](#path-modes) |
| `multiInstance` | boolean | No | Set to `true` to generate a data class + collection class pattern (default: `false`). Alias: `multi_instance` |
| `singularName` | string | No | Override the auto-derived singular name for multi-instance definitions. Alias: `singular_name` |
| `type` | string | No | Controls add/delete code generation. `"add"` generates both `add()` and `delete()` methods. `"delete"` generates only `delete()`. See [1.6 Add/Delete Operations](#16-adddelete-operations) |
| `category` | string | No | Category tag (`core`, `extensions`, `vendor`). When `--categorize` is enabled, files are output into matching subdirectories |
| `presets` | array | No | Preset configuration groups |
| `subscribe` | object | No | Subscription configuration |
| `related` | array | No | Cross-instance related parameters. See [1.7 Related Parameters](#17-related-parameters) |

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

#### Path Modes

定義檔有三種路徑模式，決定 parameter 的 `path` 如何解析成完整 TR-181 路徑：

**模式 A：`instance` — 單實例，相對路徑**

使用 `instance` 提供路徑前綴，parameter 用相對路徑（以 `.` 開頭）。適用於對應單一 TR-181 物件的定義。

```yaml
name: DNSSettings
instance: Device.DNS.Client        # 路徑前綴
parameters:
  - path: .Server.1.DNSServer      # 相對路徑 → Device.DNS.Client.Server.1.DNSServer
  - path: .Server.2.DNSServer      # 相對路徑 → Device.DNS.Client.Server.2.DNSServer
```

**模式 B：`basePath` + `multiInstance` — 多實例，相對路徑**

使用 `basePath` 提供路徑前綴（尾部自動補 `.`），搭配 `multiInstance: true` 生成 collection 類別 + `getInstances()`。

```yaml
name: connectedDevices
multiInstance: true
basePath: Device.Hosts.Host.       # 路徑前綴（多實例表）
parameters:
  - path: .HostName                # 相對路徑 → Device.Hosts.Host.{i}.HostName
  - path: .IPAddress               # 相對路徑 → Device.Hosts.Host.{i}.IPAddress
```

**模式 C：無 `instance` / 無 `basePath` — 絕對路徑聚合**

不指定路徑前綴，parameter 的 `path` 必須是完整的 TR-181 絕對路徑。適用於從多個不同 TR-181 物件聚合參數的「API 服務」場景。

```yaml
name: NetworkOverview
description: Aggregated network status from multiple TR-181 objects
parameters:
  - path: Device.DeviceInfo.ModelName            # 絕對路徑
  - path: Device.IP.Interface.1.IPv4Address.1.IPAddress
  - path: Device.Hosts.HostNumberOfEntries
  - path: Device.WiFi.SSID.1.SSID
    writable: true
```

> 三種模式的生成結果（data class + `fetch()` + `save()`）結構相同，差異僅在路徑組裝方式。

#### `instance` vs `basePath` vs `related` 比較

| | `instance` | `basePath` + `multiInstance` | 無前綴（絕對路徑） | `related` |
|---|---|---|---|---|
| **用途** | 單一 TR-181 物件 | 多實例表（可有 N 筆） | 跨物件聚合 | 單實例中引用其他物件的參數 |
| **parameter `path`** | 相對（`.XXX`） | 相對（`.XXX`） | 絕對 | 相對（以 related 的 `instance` 為前綴） |
| **生成差異** | data class | data class + collection + `getInstances()` | data class | 參數合併入主 data class |
| **範例** | `Device.WiFi.SSID.1` | `Device.Hosts.Host.` | `Device.DeviceInfo.ModelName` | WiFi SSID + AccessPoint Security |

`related` 是模式 A 的延伸——當單實例定義需要從**另一個** TR-181 物件拉參數時，用 `related` 指定該物件的 `instance` 路徑，其下的 parameter 同樣使用相對路徑。功能上等價於模式 C 的絕對路徑寫法，但語意更清晰且避免重複書寫長路徑前綴。

```yaml
# 使用 related（推薦：語意清晰、路徑不重複）
name: wifiSettings
instance: Device.WiFi.SSID.1
parameters:
  - path: .SSID
  - path: .Enable
related:
  - instance: Device.WiFi.AccessPoint.1.Security
    parameters:
      - path: .ModeEnabled
      - path: .KeyPassphrase

# 等價的絕對路徑寫法（功能相同）
name: wifiSettings
parameters:
  - path: Device.WiFi.SSID.1.SSID
  - path: Device.WiFi.SSID.1.Enable
  - path: Device.WiFi.AccessPoint.1.Security.ModeEnabled
  - path: Device.WiFi.AccessPoint.1.Security.KeyPassphrase
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
| `required` | boolean | No | Whether the parameter is required for `add()` (default: `false`). Required params are non-nullable in `add()` signatures |
| `sensitive` | boolean | No | Whether the parameter contains sensitive data (default: `false`) |
| `default_value` | string \| number \| boolean | No | Default value |

#### Supported `type` Values

| type | Description | Dart | TypeScript | Swift |
|------|-------------|------|------------|-------|
| `string` | String (default) | `String` | `string` | `String` |
| `int` | Signed integer | `int` | `number` | `Int` |
| `uint` | Unsigned integer | `int` | `number` | `UInt` |
| `long` | Long integer | `int` | `bigint` | `Int64` |
| `ulong` | Unsigned long integer | `int` | `bigint` | `UInt64` |
| `boolean` | Boolean | `bool` | `boolean` | `Bool` |
| `datetime` | Date/time | `DateTime` | `Date` | `Date` |
| `base64` | Base64-encoded | `Uint8List` | `Uint8Array` | `Data` |
| `hexbinary` | Hex binary | `Uint8List` | `Uint8Array` | `Data` |
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

Subscription configuration. When `enabled: true`, the generator produces **typed** subscription methods that return `Subscription<ClassName>` instead of untyped streams.

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

#### Generated Output

The subscribe feature generates:

1. **`_paths` constant** — shared between `fetch()` and `subscribe()` (DRY)
2. **`_fromResponse` / `parseXxx` / `fromResponse`** — shared parser for typed response parsing
3. **Typed `subscribe()` method** — returns `Subscription<ClassName>` with parser reference

**Dart (single-instance):**
```dart
static const _paths = ['Device.WiFi.SSID.1.SSID', ...];

static Future<Subscription<WifiSettings>> subscribe(UspService client) async {
  return client.subscribe<WifiSettings>(
    id: 'wifi-settings-01',
    notifType: NotifType.valueChange,
    paths: _paths,
    parser: WifiSettings._fromResponse,
  );
}
```

**TypeScript:**
```typescript
const PATHS = ['Device.WiFi.SSID.1.SSID', ...] as const;
function parseWifiSettings(response: Record<string, any>): WifiSettings { ... }

export function subscribeWifiSettings(client: UspClient): Subscription<WifiSettings> {
  return client.subscribe({
    id: 'wifi-settings-01',
    notifType: 'ValueChange',
    paths: [...PATHS],
    parser: parseWifiSettings,
  });
}
```

**Swift:**
```swift
private static let paths = ["Device.WiFi.SSID.1.SSID", ...]

public static func subscribe(client: UspClient) async throws -> Subscription<WifiSettings> {
  return try await client.subscribe(
    id: "wifi-settings-01",
    notifType: .valueChange,
    paths: paths,
    parser: WifiSettings.fromResponse
  )
}
```

### 1.5 Multi-Instance Definitions

When `multiInstance: true` is set, the generator produces **two classes** instead of one:

1. **Singular data class** (immutable) — represents a single instance row with an `instancePath` field plus all parameter fields
2. **Collection class** — holds a `List`/array of singular instances, with a `fetch()` method that uses `getInstances()` to enumerate all instances

When the definition also contains **writable parameters** (`writable: true`), the generator additionally produces:

3. **Update class** — carries optional writable field values for a single instance (read-only fields are excluded)
4. **`update()` method** — updates a single instance's writable fields in one USP Set call
5. **`updateMany()` method** — updates multiple instances in a single atomic USP Set call, with `allowPartial` control

The singular name is derived automatically by stripping the trailing `s` from `name`. Use `singularName` to override this when the auto-derivation is incorrect (e.g., plurals that don't end in `s`, or irregular plurals). If the derived singular name collides with the collection name (e.g., `PortForwarding` → singular `PortForwarding`), the generator will **error out** and prompt you to add `singularName` to the YAML definition.

#### Path Resolution

- Use `basePath` with `multiInstance: true` for dynamic collections (e.g., `Device.Hosts.Host.`). A trailing `.` is **auto-appended** if omitted — both `Device.Hosts.Host` and `Device.Hosts.Host.` are accepted
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

  @override
  String toString() {
    return 'ConnectedDevice('
      'instancePath: $instancePath, '
      'hostName: $hostName, '
      'ipAddress: $ipAddress, '
      'active: $active'
    ')';
  }
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

> **Dart-only**: All generated Dart data classes include an `@override String toString()` method listing all fields for debug output. TypeScript and Swift do not generate equivalent methods.

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

### 1.6 Add/Delete Operations

For multi-instance definitions that need to create or remove USP instances (e.g., Port Forwarding rules), use the `type` field.

| `type` value | `add()` generated | `delete()` generated | Use case |
|-------------|-------------------|---------------------|----------|
| `"add"` | Yes | Yes | Create and remove instances (e.g., Port Forwarding) |
| `"delete"` | No | Yes | Remove-only (e.g., clearing log entries) |
| _(omitted)_ | No | No | Read/update only (default) |

The `type` field is **additive** — it does not replace `fetch`/`update` generation. A definition with `type: "add"` will generate `fetch`, `update`, `add`, and `delete` methods.

#### YAML Example

```yaml
name: portForwardingRules
description: NAT port forwarding rules
multiInstance: true
basePath: Device.NAT.PortMapping.
singularName: PortForwardingRule
type: add

parameters:
  - field_name: protocol
    path: .Protocol
    type: string
    writable: true
    required: true

  - field_name: externalPort
    path: .ExternalPort
    type: int
    writable: true
    required: true

  - field_name: enabled
    path: .Enable
    type: boolean
    writable: true

  - field_name: status
    path: .Status
    type: string
```

#### Generated `add()` Method

Only **writable** parameters are included in the `add()` method signature. Read-only fields (e.g., `status`) are excluded. Parameters marked `required: true` are non-nullable and placed first in the signature; optional parameters are nullable.

**Dart:**
```dart
static Future<String> add(UspService client, {
  required String protocol,
  required int externalPort,
  bool? enabled,
}) async {
  final params = <String, dynamic>{};
  params['Protocol'] = protocol;
  params['ExternalPort'] = externalPort;
  if (enabled != null) params['Enable'] = enabled;
  return await client.add('Device.NAT.PortMapping.', params);
}

static Future<void> delete(UspService client, String instancePath) async {
  await client.delete(instancePath);
}
```

**TypeScript:**
```typescript
export async function addPortForwardingRule(client: UspClient, params: {
  protocol: string;
  externalPort: number;
  enabled?: boolean;
}): Promise<string> {
  const setParams: Record<string, any> = {};
  setParams['Protocol'] = params.protocol;
  setParams['ExternalPort'] = params.externalPort;
  if (params.enabled !== undefined) setParams['Enable'] = params.enabled;
  return await client.add('Device.NAT.PortMapping.', setParams);
}

export async function deletePortForwardingRule(client: UspClient, instancePath: string): Promise<void> {
  await client.delete(instancePath);
}
```

**Swift:**
```swift
public static func add(client: UspClient, protocol: String, externalPort: Int, enabled: Bool? = nil) async throws -> String {
    var params: [String: Any] = [:]
    params["Protocol"] = `protocol`
    params["ExternalPort"] = externalPort
    if let enabled = enabled { params["Enable"] = enabled }
    return try await client.add("Device.NAT.PortMapping.", params)
}

public static func delete(client: UspClient, instancePath: String) async throws {
    try await client.delete(instancePath)
}
```

### 1.7 Related Parameters

For single-instance definitions that need parameters from **multiple TR-181 instance paths**, use the `related` array. This is common in WiFi settings where SSID and Security parameters live under different paths. `related` 是 [Path Mode A](#path-modes) 的延伸，功能上等價於使用絕對路徑（Path Mode C），但語意更明確。詳見 [比較表](#instance-vs-basepath-vs-related-比較)。

**Constraints:**
- Only supported for single-instance definitions (those using `instance:`)
- Related parameters are appended to the main parameter list and treated identically in the generated code
- Each related group specifies its own `instance` path, which overrides the definition's `instance` for path resolution

#### YAML Example

```yaml
name: wifiSettings
instance: Device.WiFi.SSID.1
description: WiFi settings with security

parameters:
  - path: .SSID
    field_name: ssid
    type: string
    writable: true
  - path: .Enable
    field_name: enabled
    type: boolean
    writable: true

related:
  - instance: Device.WiFi.AccessPoint.1.Security
    parameters:
      - path: .ModeEnabled
        field_name: securityMode
        type: string
        writable: true
      - path: .KeyPassphrase
        field_name: passphrase
        type: string
        writable: true
```

#### Generated Output (Dart)

```dart
class WifiSettings {
  final String ssid;
  final bool enabled;
  final String securityMode;
  final String passphrase;

  const WifiSettings({
    required this.ssid,
    required this.enabled,
    required this.securityMode,
    required this.passphrase,
  });

  static Future<WifiSettings> fetch(UspService client) async {
    final response = await client.get([
      'Device.WiFi.SSID.1.SSID',
      'Device.WiFi.SSID.1.Enable',
      'Device.WiFi.AccessPoint.1.Security.ModeEnabled',      // from related
      'Device.WiFi.AccessPoint.1.Security.KeyPassphrase',    // from related
    ]);
    return WifiSettings._fromResponse(response);
  }

  static Future<void> save(UspService client, {
    String? ssid,
    bool? enabled,
    String? securityMode,
    String? passphrase,
  }) async {
    final params = <String, dynamic>{};
    if (ssid != null) params['Device.WiFi.SSID.1.SSID'] = ssid;
    if (enabled != null) params['Device.WiFi.SSID.1.Enable'] = enabled;
    if (securityMode != null) params['Device.WiFi.AccessPoint.1.Security.ModeEnabled'] = securityMode;
    if (passphrase != null) params['Device.WiFi.AccessPoint.1.Security.KeyPassphrase'] = passphrase;
    if (params.isNotEmpty) await client.set(params);
  }
}
```

### 1.8 Operate Definitions

Operate definitions generate wrapper methods for USP Operate commands. Instead of `parameters`, they use an `operations` array that maps to `client.operate()` calls.

#### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Module name |
| `description` | string | **Yes** | Module description |
| `type` | string | **Yes** | Must be `"operate"` |
| `operations` | array | **Yes** | Array of operation definitions |

> **Note**: Operate definitions do not use `parameters`, `instance`, `basePath`, or `subscribe`.

#### Operation

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Method name (camelCase) |
| `path` | string | **Yes** | Full USP command path (e.g., `Device.IP.Diagnostics.DownloadDiagnostics()`) |
| `description` | string | No | Operation description |
| `inputs` | array | No | Array of input parameter definitions |

#### Operation Input

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | string | **Yes** | TR-181 input parameter name (e.g., `DownloadURL`) |
| `field` | string | **Yes** | Generated field name (camelCase) |
| `type` | string | No | Input type (default: `string`) |
| `required` | boolean | No | Whether the input is required (default: `false`) |
| `default` | string \| number \| boolean | No | Default value |

#### YAML Example

```yaml
name: speedTest
description: Download speed test diagnostics
type: operate

operations:
  - name: start
    path: Device.IP.Diagnostics.DownloadDiagnostics()
    description: Start download speed test
    inputs:
      - path: DownloadURL
        field: downloadUrl
        type: string
        required: true
      - path: NumberOfConnections
        field: connections
        type: int
        required: false
        default: 4

  - name: stop
    path: Device.IP.Diagnostics.DownloadDiagnostics.Stop()
    description: Stop speed test
```

#### Generated Output (Dart)

```dart
/// Download speed test diagnostics
class DiagnosticsOperate {
  /// Start download speed test
  static Future<Map<String, dynamic>> start(UspService client, {
    required String downloadUrl,
    int? connections,
  }) async {
    final inputs = <String, String>{};
    inputs['DownloadURL'] = downloadUrl;
    if (connections != null) inputs['NumberOfConnections'] = connections.toString();
    return await client.operate('Device.IP.Diagnostics.DownloadDiagnostics()', args: inputs);
  }

  /// Stop speed test
  static Future<Map<String, dynamic>> stop(UspService client) async {
    return await client.operate('Device.IP.Diagnostics.DownloadDiagnostics.Stop()');
  }
}
```

#### Generated Output (TypeScript)

```typescript
/** Start download speed test */
export async function startSpeedTest(client: UspClient, params: {
  downloadUrl: string;
  connections?: number;
}): Promise<Record<string, any>> {
  const inputs: Record<string, any> = {};
  inputs['DownloadURL'] = params.downloadUrl;
  if (params.connections !== undefined) inputs['NumberOfConnections'] = params.connections;
  return await client.operate('Device.IP.Diagnostics.DownloadDiagnostics()', inputs);
}

/** Stop speed test */
export async function stopSpeedTest(client: UspClient): Promise<Record<string, any>> {
  return await client.operate('Device.IP.Diagnostics.DownloadDiagnostics.Stop()', {});
}
```

#### Generated Output (Swift)

```swift
/// Download speed test diagnostics
public class SpeedTest {
    /// Start download speed test
    public static func start(client: UspClient, downloadUrl: String, connections: Int? = nil) async throws -> [String: Any] {
        var inputs: [String: Any] = [:]
        inputs["DownloadURL"] = downloadUrl
        if let connections = connections { inputs["NumberOfConnections"] = connections }
        return try await client.operate("Device.IP.Diagnostics.DownloadDiagnostics()", inputs)
    }

    /// Stop speed test
    public static func stop(client: UspClient) async throws -> [String: Any] {
        return try await client.operate("Device.IP.Diagnostics.DownloadDiagnostics.Stop()", [:])
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
| `display` | object | No | Display formatter for human-readable output |
| `display.formatter` | string | **Yes** (if `display`) | Formatter name: `bandwidth`, `duration`, `bytes`, `percent`, `number`, or `speed` |
| `display.precision` | int | No | Precision parameter (formatter-specific) |
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
    display:
      formatter: bandwidth
      precision: 2
```

#### Display Formatter

When `display` is specified, an additional `*Display` getter/function (returning `String`) is generated alongside the formula getter. It calls `Transforms.format*()` with the formula result.

| `display.formatter` | Transforms function | Description |
|---------------------|---------------------|-------------|
| `bandwidth` | `formatBandwidth` | Human-readable bandwidth (e.g., "150.00 Mbps") |
| `duration` | `formatDuration` | Human-readable duration (e.g., "1h 30m 45s") |
| `bytes` | `formatBytes` | Human-readable file size (e.g., "1.5 GB") |
| `percent` | `formatPercent` | Percentage with symbol (e.g., "85.6%") |
| `number` | `formatNumber` | Thousand-separated number (e.g., "1,234,567") |
| `speed` | `formatSpeed` | Auto-scaled speed in Kbps/Mbps/Gbps (SI 1000) |

**Dart:**
```dart
double get throughputMbps { ... }

String get throughputMbpsDisplay =>
    Transforms.formatBandwidth(throughputMbps, precision: 2);
```

**TypeScript:**
```typescript
export function throughputMbps(data: SpeedTest): number { ... }

export function throughputMbpsDisplay(data: SpeedTest): string {
  return Transforms.formatBandwidth(throughputMbps(data), 2);
}
```

**Swift:**
```swift
public var throughputMbps: Double { ... }

public var throughputMbpsDisplay: String {
    return Transforms.formatBandwidth(throughputMbps, precision: 2)
}
```

### 2.3 Mapping Transform

Maps a single parameter value to an i18n key, wrapped in `tr()` for localization.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Property name (camelCase) |
| `type` | string | **Yes** | Must be `mapping` |
| `input` | string | **Yes** | Input parameter name (must match definition `path`) |
| `mappings` | object | **Yes** | Key-value pairs: TR-181 value → i18n key |
| `default` | string | No | Default i18n key when no mapping matches. If omitted, falls back to `value.toString()` |
| `description` | string | No | Description |

```yaml
transforms:
  - name: diagnosticsStateDisplay
    type: mapping
    description: Human-readable diagnostic state
    input: DiagnosticsState
    default: speedtest_state_unknown
    mappings:
      None: speedtest_state_none
      Requested: speedtest_state_requested
      Complete: speedtest_state_complete
      Error_InitConnectionFailed: speedtest_state_conn_failed
```

#### Generated Output

Mapping values are wrapped in `tr()` for i18n support. If `default` is specified, the `default:` branch uses `tr(default)` instead of a raw string fallback.

**Dart:**
```dart
String get diagnosticsStateDisplay {
    final value = diagnosticsState;
    switch (value) {
      case 'None': return tr('speedtest_state_none');
      case 'Requested': return tr('speedtest_state_requested');
      default: return tr('speedtest_state_unknown');
    }
}
```

**TypeScript:**
```typescript
export function diagnosticsStateDisplay(data: SpeedTest): string {
  const value = data.diagnosticsState;
  switch (value) {
    case 'None': return tr('speedtest_state_none');
    case 'Requested': return tr('speedtest_state_requested');
    default: return tr('speedtest_state_unknown');
  }
}
```

**Swift:**
```swift
public var diagnosticsStateDisplay: String {
    let value = diagnosticsState
    switch value {
    case "None": return tr("speedtest_state_none")
    case "Requested": return tr("speedtest_state_requested")
    default: return tr("speedtest_state_unknown")
    }
}
```

- **Dart**: `extension {Name}Ext on {Name} { ... }` block with synchronous getters
- **Swift**: `extension {Name} { ... }` block with computed properties
- **TypeScript**: standalone functions taking the data object

### 2.4 Converter Transform

Calls a named transform function on a single input parameter. Use this for reusable conversion utilities (e.g., CIDR to dotted notation, duration formatting).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | **Yes** | Property name (camelCase) |
| `type` | string | **Yes** | Must be `converter` |
| `input` | string | **Yes** | Input parameter name (must match definition `path`). Also accepts `inputs` array (first element used) |
| `converter` | string | **Yes** | Function name to call (e.g., `cidrToNetmask`) |
| `output_type` | string | No | Return type (`string`, `int`, `double`). Defaults to `string` |
| `description` | string | No | Description |

```yaml
transforms:
  - name: subnetMaskDotted
    type: converter
    description: Subnet mask in dotted notation
    input: subnetMaskCidr
    converter: cidrToNetmask
    output_type: string

  - name: uptimeFormatted
    type: converter
    description: Human-readable uptime
    input: uptime
    converter: formatDuration
    output_type: string
```

#### Generated Output

- **Dart**: `String get subnetMaskDotted => Transforms.cidrToNetmask(subnetMaskCidr);`
- **TypeScript**: `export function subnetMaskDotted(data: WanStatus): string { return Transforms.cidrToNetmask(data.subnetMaskCidr); }`
- **Swift**: `public var subnetMaskDotted: String { return Transforms.cidrToNetmask(subnetMaskCidr) }`

> **Note**: The `Transforms` library is auto-generated by codegen alongside definition files (see §2.5).

### 2.5 Built-in Transforms Library

Codegen automatically generates a `Transforms` utility class/module containing 9 built-in functions used by converter and display formatter transforms.

**Output files:**
- Dart: `transforms.g.dart` — `class Transforms` with static methods
- TypeScript: `Transforms.g.ts` — exported functions
- Swift: `Transforms.g.swift` — `public enum Transforms` with static functions

#### Built-in Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `durationSeconds` | `(DateTime, DateTime) → double` | Time difference in seconds |
| `durationMs` | `(DateTime, DateTime) → int` | Time difference in milliseconds |
| `cidrToNetmask` | `(int) → String` | CIDR prefix to dotted decimal notation |
| `formatBandwidth` | `(double, precision?) → String` | Human-readable bandwidth (Mbps/Gbps) |
| `formatDuration` | `(int) → String` | Human-readable duration (e.g., "2h 30m 15s") |
| `formatBytes` | `(int) → String` | Human-readable file size (e.g., "1.5 GB") |
| `formatPercent` | `(double, precision?) → String` | Percentage with symbol (e.g., "85.6%") |
| `formatNumber` | `(double, precision?) → String` | Thousand-separated number (e.g., "1,234,567") |
| `formatSpeed` | `(double, precision?) → String` | Auto-scaled speed from Kbps (SI 1000: Kbps/Mbps/Gbps) |

The Transforms library is generated once per codegen run, regardless of how many definition files exist.

---

## 3. Type Mapping

### Definition Parameter Types

| YAML `type` | Dart | TypeScript | Swift |
|-------------|------|------------|-------|
| `string` | `String` | `string` | `String` |
| `int` | `int` | `number` | `Int` |
| `uint` | `int` | `number` | `UInt` |
| `long` | `int` | `bigint` | `Int64` |
| `ulong` | `int` | `bigint` | `UInt64` |
| `boolean` | `bool` | `boolean` | `Bool` |
| `datetime` | `DateTime` | `Date` | `Date` |
| `base64` | `Uint8List` | `Uint8Array` | `Data` |
| `hexbinary` | `Uint8List` | `Uint8Array` | `Data` |
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

路徑解析規則（詳見 [Path Modes](#path-modes)）：

- **相對路徑**（以 `.` 開頭）：generator 自動拼接 `{instance 或 basePath}{path}`
- **絕對路徑**（不以 `.` 開頭）：直接作為完整 TR-181 路徑使用
- 此規則適用於 `parameters`、`presets`、`related` 中所有的 `path` 欄位

```
# 相對路徑拼接
instance:  Device.DNS.Client
path:      .Server.1.DNSServer
full path: Device.DNS.Client.Server.1.DNSServer

# 絕對路徑直接使用
path:      Device.DeviceInfo.ModelName
full path: Device.DeviceInfo.ModelName
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
| `--dart-tr PATH` | Dart import path for `tr()` function used by mapping transforms. When specified, files containing mapping transforms will include this import. Example: `--dart-tr 'package:easy_localization/easy_localization.dart'` |
| `--package NAME` | Package/module name for generated barrel exports (e.g., `--package my_usp_models`). Used as Dart `library` name and TS export prefix |
| `--verbose` | Print processing details (file names, parameter/transform counts) to stderr |
| `--categorize` | Output generated files into `core/`, `extensions/`, `vendor/` subdirectories based on definition `category` field. Default is flat output |
| `--def-schema PATH` | External JSON schema file path for definition validation (overrides embedded schema) |
| `--transform-schema PATH` | External JSON schema file path for transform validation (overrides embedded schema) |
| `--validate-paths` | Enable TR-181 path validation |
| `--json` | Output errors in JSON format (for tooling integration) |
| `--version` | Display version number and exit |
| `--help` | Show help message |

### Default Import Paths Per Language

| Language | Default Import | Default Client Class |
|----------|---------------|---------------------|
| Dart | `package:usp_test/services/usp_service.dart` | `UspService` |
| TypeScript | `usp-client` | `UspClient` |
| Swift | `UspClient` | `UspClient` |

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
    default: speedtest_state_unknown
    mappings:
      None: speedtest_state_none
      Requested: speedtest_state_requested
      Complete: speedtest_state_complete
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

For non-operate definitions, `parameters` (array) is expected. For operate definitions (`type: "operate"`), `operations` (array) is used instead.

All other fields are optional. Type mismatches produce errors. Unknown fields produce warnings but do not block generation.
