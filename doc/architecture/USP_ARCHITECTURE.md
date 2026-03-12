# USP Architecture Documentation
## PrivacyGUI 2.1.0 Technical Architecture

**Document Version:** 1.0
**Last Updated:** March 12, 2026
**Target Audience:** Software Engineers, System Architects

---

## 🏗️ System Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (Flutter UI)              │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │  14 Dashboard   │   12 Feature    │    Responsive Layout    │ │
│ │     Cards       │     Pages       │   (Mobile/Desktop)      │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                      UI Model Layer                             │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │  21 Equatable   │ Cross-Reference │   Display Formatters    │ │
│ │   UI Models     │     Logic       │  + Business Logic      │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    Service Layer                                │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │ UspDeviceService│ Protocol-Aware  │ Feature-Specific        │ │
│ │ (13 Transform   │    Mutation     │   Services (8)          │ │
│ │    Methods)     │   Operations    │                         │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                 State Management (Riverpod)                     │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │UspDashboard     │ Sequential      │ Optimistic Updates +    │ │
│ │Notifier         │ Locking         │   Error Recovery        │ │
│ │(34 Mutations)   │ (_withLock)     │                         │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                     Data Layer                                  │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │  22 Codegen     │ Multi-Instance  │  Type-Safe TR-181       │ │
│ │    Models       │   + Nested      │    Path Mapping         │ │
│ │(CRUD Methods)   │   Children      │                         │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                   Protocol Layer                                │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │   USP Service   │  401 Auth Retry │  Concurrent Request     │ │
│ │ (WASM JS Interop│  (Two-Stage)    │     Protection          │ │
│ │ + Value Coercion│                 │                         │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                  Transport Layer                                │
│ ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│ │  usp-bridge     │ Server-Sent     │   WebAssembly Client    │ │
│ │  REST API       │ Events (SSE)    │   (Rust → JS)           │ │
│ │  Integration    │ Infrastructure  │                         │ │
│ └─────────────────┴─────────────────┴─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Protocol Architecture

### Dual-Protocol Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                            │
├─────────────────────────────────────────────────────────────────┤
│                 Protocol Resolver                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Feature → Protocol Mapping with Fallback Logic        │   │
│  │                                                         │   │
│  │  USP Available? → Use USP                              │   │
│  │  USP Failed? → Fallback to JNAP                       │   │
│  │  JNAP Only Features → Direct JNAP                     │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│            USP Protocol Stack              JNAP Stack          │
│  ┌─────────────────────────────────┐   ┌─────────────────────┐ │
│  │        USP Service              │   │     JNAP Service    │ │
│  │  ┌─────────────────────────┐   │   │  ┌─────────────────┐│ │
│  │  │    TR-181 Data Model    │   │   │  │  Linksys API    ││ │
│  │  │   Device.WiFi.*         │   │   │  │   Actions       ││ │
│  │  │   Device.Hosts.*        │   │   │  │                 ││ │
│  │  │   Device.Firewall.*     │   │   │  │                 ││ │
│  │  └─────────────────────────┘   │   │  └─────────────────┘│ │
│  │                                 │   │                     │ │
│  │  ┌─────────────────────────┐   │   │  ┌─────────────────┐│ │
│  │  │   HTTP/SSE + protobuf   │   │   │  │   HTTP/JSON     ││ │
│  │  └─────────────────────────┘   │   │  └─────────────────┘│ │
│  └─────────────────────────────────┘   └─────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                         Router Backend                          │
│  ┌─────────────────────────────────┐   ┌─────────────────────┐ │
│  │        usp-bridge               │   │      JNAP CGI       │ │
│  │  ┌─────────────────────────┐   │   │  ┌─────────────────┐│ │
│  │  │       OBUSPA            │   │   │  │  Router Logic   ││ │
│  │  │  (USP Agent)            │   │   │  │                 ││ │
│  │  └─────────────────────────┘   │   │  └─────────────────┘│ │
│  └─────────────────────────────────┘   └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Data Flow Architecture

### 1. Dashboard Data Flow

```
User loads USP Dashboard
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  UspDashboardNotifier.build()                  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              15 Parallel Future.wait()                  │   │
│  │                                                         │   │
│  │  SystemInfo.fetch(usp)           ┐                     │   │
│  │  ConnectedDevices.fetch(usp)     │                     │   │
│  │  WiFiRadios.fetch(usp)           │ Concurrent          │   │
│  │  WiFiSsids.fetch(usp)            │ Execution           │   │
│  │  WiFiAccessPoints.fetch(usp)     │                     │   │
│  │  TimeSettings.fetch(usp)         │                     │   │
│  │  DhcpClients.fetch(usp)          │                     │   │
│  │  DhcpReservations.fetch(usp)     │                     │   │
│  │  PortForwarding.fetch(usp)       │                     │   │
│  │  PortTriggering.fetch(usp)       │                     │   │
│  │  WifiClients.fetch(usp)          │ (WiFi Enricher)     │   │
│  │  DataElementsNetwork.fetch(usp)  │ (Mesh Enricher)     │   │
│  │  LanNetworkInfo.fetch(usp)       │                     │   │
│  │  EthernetInterfaces.fetch(usp)   │                     │   │
│  │  WanStatus.fetch(usp)            ┘                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Post-Processing                            │
│                                                                 │
│  • Build AP→SSID→Radio connection map                          │
│  • _fetchDefaultGateway() routing table query                  │
│  • Cross-reference WiFi client signal data                     │
│  • Mesh topology parent-child relationships                    │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                UspDeviceService Transform                       │
│                                                                 │
│  buildSystemInfoUIModel(systemInfo)                            │
│  buildDeviceUIModels(devices, wifiClients, mesh...)            │
│  buildWifiRadioUIModels(radios, ssids, aps)                    │
│  buildTimeSettingsUIModel(timeSettings)                        │
│  buildDhcpClientUIModels(clients, devices)                     │
│  buildDhcpReservationUIModels(reservations)                    │
│  buildPortForwardingRuleUIModels(forwarding)                   │
│  buildPortTriggeringRuleUIModels(triggering)                   │
│  buildLanInfoUIModel(lanInfo)                                  │
│  buildWanStatusUIModel(wan, gateway)                           │
│  buildEthernetPortUIModels(ethernet, devices)                  │
│  buildNodeUIModels(mesh, systemInfo, devices)                  │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              UspDashboardState (Immutable)                     │
│                                                                 │
│  Raw DTOs (for mutations) + UI Models (for rendering)          │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
       Render Dashboard with 14 cards + skeleton loading
```

### 2. Mutation Data Flow

```
User triggers mutation (toggle/add/delete/update)
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Notifier Mutation Method                     │
│                                                                 │
│  await _withLock('cardKey', () async {                          │
│    // 1. Call codegen update API                               │
│    await SomeModel.update(usp, SomeModelUpdate(...));          │
│                                                                 │
│    // 2. Re-fetch fresh data                                   │
│    final fresh = await SomeModel.fetch(usp);                   │
│                                                                 │
│    // 3. Transform to UI model                                 │
│    final models = service.buildSomeUIModels(fresh);            │
│                                                                 │
│    // 4. Update state via copyWith                             │
│    state = AsyncData(state.requireValue.copyWith(              │
│      someRaw: fresh,                                            │
│      someModels: models,                                        │
│    ));                                                          │
│  });                                                            │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
    UI automatically rebuilds with new state
```

---

## 🔒 Authentication Architecture

### 1. Dual-Protocol Authentication

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Authentication                          │
├─────────────────────────────────────────────────────────────────┤
│  Local Login → Password entered                                 │
├─────────────────────────────────────────────────────────────────┤
│                 AuthNotifier (JNAP)                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. checkAdminPassword(password)                         │   │
│  │  2. Store in SecureStorage                              │   │
│  │  3. Set JNAP session state                              │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│              UspAuthCoordinator (USP)                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. syncAfterLocalLogin(password)                       │   │
│  │  2. UspService.login(password)                          │   │
│  │  3. Store USP session token                             │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                    Session Restoration                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Page Reload/App Restart                                │   │
│  │  │                                                      │   │
│  │  ├─ UspAuthCoordinator.restoreSession()                │   │
│  │  │  ├─ Read password from SecureStorage                │   │
│  │  │  └─ UspService.login(password)                      │   │
│  │  │                                                      │   │
│  │  └─ AuthNotifier restoration (existing flow)            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2. 401 Auth Retry Mechanism

```
┌─────────────────────────────────────────────────────────────────┐
│                     HTTP Request                                │
├─────────────────────────────────────────────────────────────────┤
│  UspService.get/set/add/delete/operate()                        │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              _withAuthRetry()                            │   │
│  │                                                         │   │
│  │  try {                                                  │   │
│  │    return await action();                               │   │
│  │  } catch (e) {                                          │   │
│  │    if (!_isAuthError(e)) rethrow;                       │   │
│  │                                                         │   │
│  │    // Two-stage reauth                                  │   │
│  │    await reauth();                                      │   │
│  │    return await action(); // Retry once                │   │
│  │  }                                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                    Two-Stage Reauth                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Stage 1: refreshToken() (fast, no password)           │   │
│  │     └─ Success? → retry request                         │   │
│  │     └─ Fail? → Stage 2                                  │   │
│  │                                                         │   │
│  │  Stage 2: onReauthRequired()                           │   │
│  │     └─ UspAuthCoordinator.restoreSession()             │   │
│  │     └─ Read password from SecureStorage                │   │
│  │     └─ UspService.login(password)                      │   │
│  │     └─ retry request                                    │   │
│  └─────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                 Concurrent Protection                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Completer<void> _reauthInProgress                     │   │
│  │                                                         │   │
│  │  • Only one reauth at a time                           │   │
│  │  • Concurrent 401s wait for same Completer             │   │
│  │  • Prevents auth storm scenarios                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 State Management Pattern

### Riverpod AsyncNotifier Pattern

```dart
class UspDashboardNotifier extends AutoDisposeAsyncNotifier<UspDashboardState> {
  // Build method - initial data loading
  @override
  Future<UspDashboardState> build() async {
    // 1. Parallel fetch all data sources
    final results = await Future.wait([
      SystemInfo.fetch(usp),
      ConnectedDevices.fetch(usp),
      // ... 13 more parallel fetches
    ]);

    // 2. Post-processing & cross-referencing
    final gateway = await _fetchDefaultGateway();
    final connectionDetail = _buildConnectionDetail(wifiRadios, ssids, aps);

    // 3. Transform to UI models
    final systemInfoModel = service.buildSystemInfoUIModel(systemInfo);
    final deviceModels = service.buildDeviceUIModels(devices, wifiClients, mesh);
    // ... transform all data

    // 4. Return immutable state
    return UspDashboardState(
      // Raw DTOs (for mutations)
      systemInfo: systemInfo,
      connectedDevices: connectedDevices,
      // ... all raw data

      // UI Models (for rendering)
      systemInfoModel: systemInfoModel,
      deviceModels: deviceModels,
      // ... all UI models
    );
  }

  // Mutation pattern with sequential locking
  Future<void> toggleWifiRadio(String instancePath, bool enable) async {
    await _withLock('wifiCard', () async {
      // 1. Optimistic update (optional)

      // 2. Call server API
      await WiFiRadios.update(usp, WiFiRadioUpdate(
        instancePath: instancePath,
        enable: enable,
      ));

      // 3. Re-fetch fresh data
      final freshRadios = await WiFiRadios.fetch(usp);
      final freshSsids = await WiFiSsids.fetch(usp);
      final freshAps = await WiFiAccessPoints.fetch(usp);

      // 4. Transform to UI models
      final radioModels = service.buildWifiRadioUIModels(
        freshRadios, freshSsids, freshAps, connectionDetail
      );

      // 5. Update state immutably
      state = AsyncData(state.requireValue.copyWith(
        wifiRadios: freshRadios,
        wifiSsids: freshSsids,
        wifiAccessPoints: freshAps,
        wifiRadioModels: radioModels,
      ));
    });
  }

  // Sequential locking prevents concurrent mutations
  Future<T> _withLock<T>(String key, Future<T> Function() action) async {
    // Implementation ensures only one mutation per card at a time
    // Tracks loading state via uspMutationLoadingProvider
  }
}
```

---

## 🔀 Cross-Reference Logic

### Device WiFi Enrichment

```
ConnectedDevices (MAC, IP, hostname, active, Layer1Interface)
       │
       ├── JOIN by MAC ──→ WifiClients (signal, rates)
       │                      │
       │                      └─ SignalStrength → signalQuality (0.0-1.0)
       │                      └─ LastDataDownlinkRate/UplinkRate → speeds
       │
       ├── JOIN by Layer1Interface parsing ──→ WiFiAccessPoints
       │                                          │
       │                                          └─ SSIDReference ──→ WiFiSsids.SSID
       │                                          └─ Radio ← SSID.LowerLayers
       │                                                │
       │                                                └─ OperatingFrequencyBand → band
       │
       └── JOIN via AP → Radio → MeshNode ──→ DataElementsNetwork
                                                 │
                                                 └─ Parent node ID/name resolution
```

### WiFi Radio Cross-Reference

```
WiFiRadios.{i} ← WiFiSsids.{j}.LowerLayers ← WiFiAccessPoints.{k}.SSIDReference → WiFiSsids.{j}.SSID

Example:
Device.WiFi.Radio.1 ← Device.WiFi.SSID.3.LowerLayers ← Device.WiFi.AccessPoint.5.SSIDReference → Device.WiFi.SSID.3.SSID
                                                                                                      └─ "MyNetwork_5G"
```

### Ethernet Port Device Mapping

```
EthernetInterfaces (name, status, upstream, bitRate)
       │
       └── JOIN by Layer1Interface pattern matching ──→ ConnectedDevices
                                                            │
                                                            └─ Wired device assignment
                                                            └─ LAN port isUp = hasConnectedDevice || linkUp
                                                            └─ WAN port isUp = linkUp only
```

---

## 🛡️ Error Handling Strategy

### 1. Protocol Fallback Chain

```
User Action
    │
    ▼
Protocol Resolver
    │
    ├─ USP Available? ──→ Try USP
    │                      │
    │                      ├─ Success? ──→ Return USP result
    │                      │
    │                      └─ Failed? ──→ Mark USP unavailable
    │                                      │
    │                                      └─ Fallback to JNAP
    │
    └─ USP Unavailable? ──→ Use JNAP directly
                            │
                            ├─ Success? ──→ Return JNAP result
                            │
                            └─ Failed? ──→ Show error to user
```

### 2. USP Error Recovery

```
┌─────────────────────────────────────────────────────────────────┐
│                     Error Categories                            │
├─────────────────────────────────────────────────────────────────┤
│  HTTP 401 Unauthorized                                          │
│    └─ _withAuthRetry() → two-stage reauth → retry              │
│                                                                 │
│  HTTP 403 Forbidden                                             │
│    └─ Permission error → show user-friendly message            │
│                                                                 │
│  HTTP 404 Not Found                                             │
│    └─ TR-181 path not available → fallback to JNAP             │
│                                                                 │
│  HTTP 500 Internal Server Error                                │
│    └─ Backend issue → show retry button + error details        │
│                                                                 │
│  WebSocket/SSE Connection Lost                                  │
│    └─ Auto-reconnect with exponential backoff                  │
│                                                                 │
│  WASM Client Exception                                          │
│    └─ Log error + fallback to REST API if available            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📈 Performance Optimizations

### 1. Parallel Data Loading

```dart
// Before: Sequential loading (slow)
final systemInfo = await SystemInfo.fetch(usp);        // 200ms
final devices = await ConnectedDevices.fetch(usp);     // 300ms
final wifi = await WiFiRadios.fetch(usp);              // 250ms
// Total: 750ms

// After: Parallel loading (fast)
final [systemInfo, devices, wifi] = await Future.wait([
  SystemInfo.fetch(usp),        // ┐
  ConnectedDevices.fetch(usp),  // ├─ Concurrent execution
  WiFiRadios.fetch(usp),        // ┘
]);
// Total: max(200ms, 300ms, 250ms) = 300ms
```

### 2. Value Coercion Optimization

```dart
// Optimized type coercion for TR-181 responses
dynamic _coerceValue(String path, dynamic rawValue) {
  if (rawValue == null || rawValue == "") return null;

  // Fast string matching for boolean paths
  if (_booleanPaths.contains(path.split('.').last)) {
    return rawValue == "1" || rawValue == "true";
  }

  // Parse specific data types
  if (rawValue == "true" || rawValue == "false") {
    return rawValue == "true";
  }

  return rawValue; // Keep as string for display
}
```

### 3. State Update Optimization

```dart
// Immutable state updates with copyWith
state = AsyncData(currentState.copyWith(
  // Only update changed fields
  systemInfo: newSystemInfo,
  systemInfoModel: newSystemInfoModel,
  // Keep unchanged fields as-is (reference equality)
));

// UI automatically rebuilds only affected widgets
```

---

## 🔧 Code Generation Pipeline

### YAML → Dart Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                  Definition Phase                               │
│                                                                 │
│  doc/usp/definitions/                                           │
│  ├── core/system_info.yaml                                     │
│  ├── devices/connected_devices.yaml                            │
│  ├── wifi/wi_fi_radios.yaml                                    │
│  └── ... (22 total definitions)                                │
└─────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Code Generation                                 │
│                                                                 │
│  ./tools/usp-codegen                                            │
│    --definitions-dir doc/usp/definitions/                      │
│    --output-dir lib/generated/                                 │
│    --language dart                                              │
│    --client-import 'package:privacy_gui/usp/services/...'      │
└─────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                Generated Output                                 │
│                                                                 │
│  lib/generated/                                                 │
│  ├── system_info.g.dart                                        │
│  ├── connected_devices.g.dart                                  │
│  ├── wifi_radios.g.dart                                        │
│  └── ... (23 total generated files)                            │
│                                                                 │
│  Each file contains:                                            │
│  ├── Data transfer objects (DTOs)                              │
│  ├── Type-safe CRUD methods                                    │
│  ├── Validation logic                                          │
│  └── TR-181 path mappings                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Supported Generation Patterns

| Pattern | TR-181 Example | Generated API |
|---------|----------------|---------------|
| **Single-instance** | `Device.DeviceInfo.*` | `SystemInfo.fetch(client)` |
| **Multi-instance** | `Device.Hosts.Host.{i}.*` | `ConnectedDevices.fetch(client)` |
| **Scatter-gather** | Multiple absolute paths | `LanNetworkInfo.fetch(client)` |
| **Full CRUD** | `Device.NAT.PortMapping.{i}.*` | `fetch()`, `update()`, `add()`, `delete()` |
| **Nested children** | `Device.NAT.PortTrigger.{i}.Rule.{j}.*` | Parent + child CRUD methods |
| **Subscribe** | Any with subscription | `subscribe()` returning `Stream<T>` |

---

## 🚀 Deployment Architecture

### Build-Time Configuration

```dart
// Protocol selection at build time
const protocol = String.fromEnvironment('protocol', defaultValue: 'auto');

enum ProtocolMode {
  auto,      // USP first, fallback to JNAP
  uspFirst,  // USP preferred, JNAP backup
  jnapOnly,  // JNAP only (legacy mode)
  uspOnly,   // USP only (future mode)
}
```

### Runtime Protocol Detection

```dart
class ProtocolResolver {
  static bool get isUspAvailable {
    // Check if USP endpoint is reachable
    // Check if WASM client is loaded
    // Check if authentication is valid
  }

  static bool get isJnapAvailable {
    // Check if JNAP endpoint is reachable
    // Check if session is valid
  }

  static ProtocolChoice resolveForFeature(Feature feature) {
    switch (feature) {
      case Feature.systemInfo:
        return isUspAvailable ? ProtocolChoice.usp : ProtocolChoice.jnap;
      case Feature.vpnServer:
        return ProtocolChoice.jnap; // USP doesn't support VPN
      case Feature.meshSettings:
        return ProtocolChoice.jnap; // Linksys proprietary
      default:
        return isUspAvailable ? ProtocolChoice.usp : ProtocolChoice.jnap;
    }
  }
}
```

---

## 📋 File Structure

### USP-Related Files Organization

```
lib/
├── usp/
│   ├── services/
│   │   ├── usp_service.dart              # Core USP transport
│   │   └── usp_bridge_client.dart        # REST + SSE client
│   ├── providers/
│   │   ├── usp_auth_coordinator.dart     # Authentication coordination
│   │   └── protocol_resolver.dart        # Protocol selection logic
│   └── models/
│       └── usp_response_extensions.dart  # Response parsing helpers
├── generated/
│   ├── *.g.dart                         # 23 generated model files
│   └── transforms.g.dart                # Generated transforms
├── usp_page/
│   ├── dashboard/
│   │   ├── providers/                   # 7 dashboard providers
│   │   ├── services/                    # UspDeviceService + others
│   │   ├── models/                      # 21 UI model files
│   │   └── views/                       # Dashboard components
│   ├── */
│   │   ├── providers/                   # Feature-specific providers
│   │   ├── services/                    # Feature-specific services
│   │   ├── models/                      # Feature UI models
│   │   └── views/                       # Feature pages + dialogs
│   └── menu/
│       └── usp_menu_view.dart          # USP navigation menu
└── core/
    └── utils/
        └── protocol_resolver.dart       # Protocol resolution utilities
```

---

## 🔍 Monitoring & Observability

### Performance Metrics

```dart
class UspPerformanceMonitor {
  // Track request latency
  static void trackRequest(String operation, Duration latency) {
    logger.info('USP Request: $operation took ${latency.inMilliseconds}ms');
  }

  // Track protocol fallback rates
  static void trackProtocolFallback(String feature, String reason) {
    logger.warn('USP→JNAP fallback: $feature ($reason)');
  }

  // Track error rates
  static void trackError(String operation, String errorType) {
    logger.error('USP Error: $operation failed with $errorType');
  }
}
```

### Health Checks

```dart
class UspHealthCheck {
  // Verify USP endpoint availability
  static Future<bool> checkUspHealth() async {
    try {
      await usp.getSingle(['Device.DeviceInfo.Manufacturer']);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify authentication status
  static bool get isAuthenticated => usp.sessionToken != null;

  // Verify WASM client status
  static bool get isWasmReady => usp.wasmClient.isInitialized;
}
```

---

**Next Steps:**
- Review and optimize bottleneck operations
- Add comprehensive error logging and monitoring
- Implement automated protocol health checks
- Plan Phase 2 features (WiFi Settings, Internet Settings)

---

*This document serves as the definitive technical reference for the USP integration in PrivacyGUI 2.1.0.*