# Devices, Nodes & Topology Architecture

This document describes the data architecture for connected devices, mesh nodes, and network topology visualization in PrivacyGUI.

## Overview

The system fetches device and mesh topology data from TR-181 via USP, transforms it into presentation-layer models, and renders an interactive network topology visualization.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  1. SERVICE LAYER — Data Fetching & Transformation                           │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   UspDevicesDataService.fetch()                                              │
│         │                                                                    │
│         ├─── USP Get ──► Device.Hosts.Host.*                                 │
│         │                      │                                             │
│         │                      ▼                                             │
│         │               ConnectedDevices (codegen)                           │
│         │                      │                                             │
│         │                      ▼                                             │
│         │               ┌──────────────────┐                                 │
│         │               │ List<DeviceUIModel> │ ◄─ Transform: Host → Model   │
│         │               │ List<NodeUIModel>   │ ◄─ Filter: role=master/slave │
│         │               └──────────────────┘                                 │
│         │                                                                    │
│         └─── USP Get ──► Device.WiFi.DataElements.Network.*                  │
│                                │                                             │
│                                ▼                                             │
│                          MeshTopologyInfo                                    │
│                          ├─ nodes: List<NodeUIModel>                         │
│                          └─ clientToNodeMap                                  │
│                                                                              │
│   Returns: DevicesFetchResult(deviceModels, nodeModels, meshTopology)        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  2. PROVIDER LAYER — State Management                                        │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   devicesDataProvider (AsyncNotifier)                                        │
│         │                                                                    │
│         ├─── build() calls service.fetch()                                   │
│         │                                                                    │
│         └─── Stores result in DevicesData state                              │
│                    │                                                         │
│                    ▼                                                         │
│              ┌─────────────────────────┐                                     │
│              │  DevicesData            │                                     │
│              │  ├─ deviceModels        │  ◄─ List<DeviceUIModel>             │
│              │  ├─ nodeModels          │  ◄─ List<NodeUIModel>               │
│              │  └─ meshTopology        │  ◄─ MeshTopologyInfo                │
│              └─────────────────────────┘                                     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ ref.watch(devicesDataProvider)
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  3. VIEW LAYER — UI Rendering                                                │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   UspNetworkTopologyCard / UspTopologyView                                   │
│         │                                                                    │
│         ├─── Reads DevicesData from Provider                                 │
│         │                                                                    │
│         └─── Calls UspTopologyBuilder.build()                                │
│                    │                                                         │
│                    │  Input:                                                 │
│                    │  ├─ info: SystemInfoUIModel (from systemInfoProvider)   │
│                    │  ├─ devices: List<DeviceUIModel>                        │
│                    │  └─ nodeModels: List<NodeUIModel>                       │
│                    │                                                         │
│                    ▼                                                         │
│              ┌─────────────────────────┐                                     │
│              │  MeshTopology           │  ◄─ UI Kit model                    │
│              │  ├─ nodes: [MeshNode]   │     (different from PrivacyGUI)     │
│              │  └─ links: [MeshLink]   │                                     │
│              └───────────┬─────────────┘                                     │
│                          │                                                   │
│                          ▼                                                   │
│              ┌─────────────────────────┐                                     │
│              │  AppTopology            │  ◄─ UI Kit widget                   │
│              │  (topology: meshTopo)   │                                     │
│              └─────────────────────────┘                                     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Key Points:**

1. **Service Layer** — Fetches USP data and transforms it into `DeviceUIModel`, `NodeUIModel`, `MeshTopologyInfo`
2. **Provider Layer** — Calls Service and stores result in `DevicesData` state
3. **View Layer** — Reads data from Provider, uses `UspTopologyBuilder` to convert to UI Kit's `MeshTopology`, then passes to `AppTopology` widget for rendering

`UspTopologyBuilder` is a pure function helper that converts PrivacyGUI's domain models into UI Kit's view models.

---

## Data Models

### DeviceUIModel

Presentation-layer model for connected devices (clients).

**Location:** `lib/page/_shared/models/device_ui_model.dart`

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `mac` | `String` | Hosts.PhysAddress | MAC address (uppercase) |
| `ip` | `String` | Hosts.IPAddress | IPv4 address |
| `hostName` | `String?` | Hosts.HostName | Device hostname |
| `isActive` | `bool` | Hosts.Active | Online status |
| `isWifi` | `bool` | Layer1Interface | Connection type |
| `signalStrength` | `int?` | WifiClient/Hosts | RSSI in dBm |
| `downlinkRate` | `int?` | WifiClient | bits/sec |
| `uplinkRate` | `int?` | WifiClient | bits/sec |
| `band` | `String?` | ConnectionDetail | "2.4GHz"/"5GHz"/"6GHz" |
| `ssidName` | `String?` | ConnectionDetail | Connected SSID |
| `deviceRole` | `String?` | Hosts.DeviceRole | "master"/"slave"/"client" |
| `parentNodeId` | `String?` | MeshTopology | Connected mesh node ID |
| `friendlyName` | `String?` | Hosts.FriendlyName | User-assigned name |
| `manufacturer` | `String?` | Hosts.Manufacturer | Device manufacturer |
| `additionalInterfaces` | `List<DeviceInterfaceInfo>` | Grouped | Multi-interface support |

**Key Computed Getters:**

```dart
// Display name priority: friendlyName > hostName > MAC
String get displayName;

// Device role helpers
bool get isClientDevice => deviceRole != 'master' && deviceRole != 'slave';
bool get isMeshNode => deviceRole == 'master' || deviceRole == 'slave';

// Signal quality (0.0-1.0): (rssi + 90) / 60
double get signalQuality;

// Signal level (0-3) using wifi.dart thresholds
int get signalLevel;

// Multi-interface support
bool get hasMultipleInterfaces;
int get interfaceCount;
List<String> get allMacAddresses;
```

---

### NodeUIModel

Presentation-layer model for mesh nodes (gateway + extenders).

**Location:** `lib/page/topology/models/node_ui_model.dart`

| Field | Type | Source | Description |
|-------|------|--------|-------------|
| `deviceId` | `String` | DataElements.ID | MAC address |
| `model` | `String?` | DataElements.ManufacturerModel | Router model |
| `manufacturer` | `String?` | DataElements.Manufacturer | "Linksys" etc. |
| `serialNumber` | `String?` | DataElements.SerialNumber | Device S/N |
| `softwareVersion` | `String?` | DataElements.SoftwareVersion | Firmware version |
| `isMaster` | `bool` | Computed | Gateway = true |
| `friendlyName` | `String?` | Hosts.FriendlyName | User name |
| `hostName` | `String?` | Hosts.HostName | Hostname |
| `connectedDeviceCount` | `int` | Computed | Clients on this node |
| `backhaulMediaType` | `String?` | DataElements | "IEEE 802.11ax"/"Ethernet" |
| `backhaulSignalStrength` | `int?` | DataElements | RSSI in dBm |
| `backhaulUplinkRate` | `int?` | DataElements | Backhaul speed (bps) |

**Key Computed Getters:**

```dart
// Display name priority: friendlyName > hostName > model > deviceId
String get displayName;

// Role label for UI
String get roleLabel => isMaster ? 'Master' : 'Slave';

// Has backhaul info (slave nodes only)
bool get hasBackhaul;
```

**List Extensions:**

```dart
extension NodeUIModelListExt on List<NodeUIModel> {
  NodeUIModel? get master;      // First master node
  List<NodeUIModel> get slaves; // All slave nodes
  bool get hasMesh;             // Has extenders
}
```

---

### MeshTopologyInfo

Container for mesh topology fetch results.

**Location:** `lib/page/_shared/models/mesh_topology_info.dart`

```dart
class MeshTopologyInfo extends Equatable {
  final List<NodeUIModel> nodes;
  final Map<String, String> clientToNodeMap; // Client MAC → Node deviceId
  
  static const empty = MeshTopologyInfo(nodes: [], clientToNodeMap: {});
}
```

---

## TR-181 Data Sources

### Connected Devices (Device.Hosts.Host.*)

Primary source for all connected devices including mesh nodes.

```
Device.Hosts.Host.*.PhysAddress          → mac
Device.Hosts.Host.*.IPAddress            → ip
Device.Hosts.Host.*.HostName             → hostName
Device.Hosts.Host.*.Active               → isActive
Device.Hosts.Host.*.Layer1Interface      → isWifi (parsed)
Device.Hosts.Host.*.InterfaceType        → interfaceType
Device.Hosts.Host.*.DeviceRole           → deviceRole
Device.Hosts.Host.*.DeviceID             → hostsDeviceId (UUID)
Device.Hosts.Host.*.FriendlyName         → friendlyName
Device.Hosts.Host.*.Manufacturer         → manufacturer
Device.Hosts.Host.*.ModelName            → modelName
Device.Hosts.Host.*.OperatingSystem      → operatingSystem
Device.Hosts.Host.*.ParentNodeID         → parentNodeId (from Hosts)
Device.Hosts.Host.*.SignalStrength       → signalStrength (fallback)
Device.Hosts.Host.*.LastDataDownlinkRate → downlinkRate (fallback)
Device.Hosts.Host.*.LastDataUplinkRate   → uplinkRate (fallback)
```

### DataElements (Device.WiFi.DataElements.Network.Device.*)

Mesh topology information for multi-AP networks.

```
Device.WiFi.DataElements.Network.Device.*.ID                    → deviceId
Device.WiFi.DataElements.Network.Device.*.ManufacturerModel     → model
Device.WiFi.DataElements.Network.Device.*.Manufacturer          → manufacturer
Device.WiFi.DataElements.Network.Device.*.SerialNumber          → serialNumber
Device.WiFi.DataElements.Network.Device.*.SoftwareVersion       → softwareVersion
Device.WiFi.DataElements.Network.Device.*.BackhaulALID          → backhaulAlId
Device.WiFi.DataElements.Network.Device.*.BackhaulMACAddress    → backhaulMacAddress
Device.WiFi.DataElements.Network.Device.*.BackhaulMediaType     → backhaulMediaType
Device.WiFi.DataElements.Network.Device.*.BackhaulPHYRate       → backhaulPhyRate

# Backhaul Stats (child path)
...MultiAPDevice.Backhaul.Stats.SignalStrength     → RCPI (convert to RSSI)
...MultiAPDevice.Backhaul.Stats.LastDataUplinkRate → backhaulUplinkRate

# Station list for client→node mapping
...Radio.*.BSS.*.STA.*.MACAddress → clientToNodeMap key
```

### WiFi Client Data (Enrichment)

Additional signal/speed data from WiFi subsystem.

```
Device.WiFi.AccessPoint.*.AssociatedDevice.*.SignalStrength
Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataDownlinkRate
Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataUplinkRate
Device.WiFi.AccessPoint.*.AssociatedDevice.*.OperatingStandard
```

---

## Service Layer

### UspDevicesDataService

**Location:** `lib/page/devices/services/usp_devices_data_service.dart`

Stateless service for fetching and transforming device data.

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `fetch()` | Fetches ConnectedDevices + builds DeviceUIModel list |
| `fetchMeshTopology()` | Fetches DataElements → MeshTopologyInfo |
| `rebuildWithWifiData()` | Incremental rebuild with WiFi enrichment |
| `rebuildWithMesh()` | Rebuild after mesh topology arrives |

**Key Transformations:**

#### 1. Device UI Model Building

```dart
// For each Host entry:
1. Normalize MAC to uppercase
2. Determine WiFi via Layer1Interface path or InterfaceType
3. Apply WiFi enrichment (signal, speed, band) if available
4. Map parent node from MeshTopologyInfo
5. Group multi-interface devices by hostname
```

#### 2. Multi-Interface Device Grouping

Devices with the same normalized hostname are merged:

```dart
// Hostname normalization:
// - Lowercase
// - Strip mDNS suffixes (._tcp.local, ._device-info._tcp.local)

// Primary interface selection priority:
1. Active status (active > inactive)
2. Connection type (WiFi > Ethernet)

// Result:
// Primary interface → DeviceUIModel fields
// Additional interfaces → additionalInterfaces list
```

#### 3. Node UI Model Building

```dart
// Extract mesh nodes from Hosts (deviceRole = master/slave)
// If no mesh devices: create gateway-only from SystemInfo
// For master: use SystemInfo for model/firmware
// For slaves: enrich from DataElements
// Count connected clients per node
```

#### 4. Mesh Node Matching

Matches Hosts devices to DataElements nodes via UUID:

```dart
// Hosts.DeviceID format: "0217B8A4-1082-4532-8345-80691ABB4694"
// Extract last 12 chars (no hyphens): "80691ABB4694"
// Format as MAC: "80:69:1A:BB:46:94"
// Match to DataElements node by ID
```

---

## Provider Layer

### DevicesDataProvider

**Location:** `lib/page/devices/providers/devices_data_provider.dart`

**State Container:**

```dart
class DevicesData {
  final DevicesCodegenContext codegenContext;  // Raw data for rebuilds
  final MeshTopologyInfo meshTopology;
  final List<DeviceUIModel> deviceModels;
  final List<NodeUIModel> nodeModels;
  final Map<String, String> hostNameByMac;
  
  // Computed
  List<DeviceUIModel> get clientDevices;  // Excludes mesh nodes
  int get onlineClientCount;
  int get totalClientCount;
}
```

**Fetch Flow:**

```
1. Build triggered (or SSE invalidation)
   ↓
2. UspDevicesDataService.fetch()
   ├─ Fetch ConnectedDevices
   ├─ Build DeviceUIModel list
   └─ Build NodeUIModel list (gateway only if no mesh)
   ↓
3. WiFi enrichment applied (5s timeout, soft dependency)
   └─ Signal/speed/band data populated
   ↓
4. Background: fetchMeshTopology()
   ├─ Fetch DataElements
   ├─ Build MeshTopologyInfo
   └─ Rebuild device/node models with mesh data
   ↓
5. State updated
```

**SSE Invalidation:**

- Listens to `InvalidationDomain.connectedDevices`
- Debounces 500ms before refetch
- Preserves existing mesh topology during refetch

---

## Topology Building

### UspTopologyBuilder

**Location:** `lib/page/topology/helpers/usp_topology_builder.dart`

Transforms DeviceUIModel + NodeUIModel into UI Kit's MeshTopology.

**Node Type Mapping:**

| Source Model | MeshNodeType | Node ID Format |
|--------------|--------------|----------------|
| Master NodeUIModel | `gateway` | `"gateway"` |
| Slave NodeUIModel | `extender` | `"extender-{deviceId}"` |
| Client DeviceUIModel | `client` | `"client-{mac}"` |

**Link Parent Determination:**

```dart
// For client devices:
if (hasMesh && device.parentNodeId != null) {
  if (extenderNodeIds.contains(device.parentNodeId)) {
    parentId = 'extender-${device.parentNodeId}';
  } else {
    parentId = 'gateway';  // Fallback
  }
} else {
  parentId = 'gateway';
}
```

**Output Structure:**

```dart
MeshTopology(
  nodes: [
    MeshNode(id: 'gateway', type: gateway, ...),
    MeshNode(id: 'extender-AA:BB:CC:DD:EE:FF', type: extender, parentId: 'gateway', ...),
    MeshNode(id: 'client-11:22:33:44:55:66', type: client, parentId: 'gateway', ...),
    MeshNode(id: 'client-77:88:99:AA:BB:CC', type: client, parentId: 'extender-...', ...),
  ],
  links: [
    MeshLink(sourceId: 'gateway', targetId: 'extender-...', connectionType: wifi, ...),
    MeshLink(sourceId: 'gateway', targetId: 'client-...', connectionType: ethernet, ...),
    MeshLink(sourceId: 'extender-...', targetId: 'client-...', connectionType: wifi, ...),
  ],
)
```

---

## Signal Strength Calculations

### RSSI Thresholds (wifi.dart)

```dart
const signalThresholdRSSI = [-65, -71, -78];

enum NodeSignalLevel { excellent, good, fair, poor, none, wired }

// >= -65 dBm → excellent
// >= -71 dBm → good
// >= -78 dBm → fair
// <  -78 dBm → poor
```

### DeviceUIModel.signalLevel (0-3)

```dart
int get signalLevel {
  if (signalStrength == null) return 0;
  return switch (getWifiSignalLevel(signalStrength)) {
    NodeSignalLevel.excellent => 3,
    NodeSignalLevel.good => 2,
    NodeSignalLevel.fair => 1,
    _ => 0,
  };
}
```

### LinkQuality (Topology)

```dart
static LinkQuality _rssiToLinkQuality(int? rssi) {
  if (rssi == null) return LinkQuality.unknown;
  final level = getWifiSignalLevel(rssi);
  return switch (level) {
    NodeSignalLevel.excellent => LinkQuality.excellent,
    NodeSignalLevel.good => LinkQuality.excellent,
    NodeSignalLevel.fair => LinkQuality.good,
    NodeSignalLevel.poor => LinkQuality.fair,
    NodeSignalLevel.none => LinkQuality.unknown,
    NodeSignalLevel.wired => LinkQuality.stable,
  };
}
```

### Level (0.0-1.0) for Node Visualization

```dart
static double _rssiValueToLevel(int? rssi) {
  if (rssi == null) return 0.0;
  if (rssi >= -50) return 0.9;
  if (rssi >= -60) return 0.65;
  if (rssi >= -70) return 0.4;
  return 0.1;
}
```

### Distance Factor (0.0-1.0) for Link Spacing

```dart
static double? _rssiToDistanceFactor(int? rssi) {
  if (rssi == null) return null;
  final clamped = rssi.clamp(-75, -45);
  return (clamped - (-45)).abs() / 30.0;
}
// -45 dBm (strong) → 0.0 (close)
// -75 dBm (weak)   → 1.0 (far)
```

### Backhaul RCPI to RSSI Conversion

```dart
// DataElements uses RCPI (0-220 scale)
// Convert to RSSI: (RCPI / 2) - 110
int rssi = (rcpi ~/ 2) - 110;
```

---

## Device Classification

### Device Roles

| Role | Description | Source |
|------|-------------|--------|
| `"master"` | Mesh gateway/router | Hosts.DeviceRole |
| `"slave"` | Mesh extender | Hosts.DeviceRole |
| `"client"` | Regular device | Default (null or other) |

### Helper Methods

```dart
// DeviceUIModel getters
bool get isClientDevice => deviceRole != 'master' && deviceRole != 'slave';
bool get isMeshNode => deviceRole == 'master' || deviceRole == 'slave';
bool get isMasterNode => deviceRole == 'master';
bool get isSlaveNode => deviceRole == 'slave';

// List extensions
extension DeviceUIModelListExt on List<DeviceUIModel> {
  List<DeviceUIModel> get clientDevices;
  List<DeviceUIModel> get meshNodes;
  DeviceUIModel? get masterNode;
  List<DeviceUIModel> get slaveNodes;
}
```

---

## Multi-Interface Device Support

Some devices connect via multiple interfaces (e.g., iPhone with WiFi + Ethernet dock).

### Grouping Strategy

1. **Normalize hostname** — lowercase, strip mDNS suffixes
2. **Group by hostname** — same hostname = same device
3. **Select primary** — active status, then WiFi preference
4. **Store additional** — in `additionalInterfaces` list

### DeviceInterfaceInfo

```dart
class DeviceInterfaceInfo extends Equatable {
  final String mac;
  final String? ip;
  final bool isWifi;
  final bool isActive;
  final String? layer1Interface;
  final String? band;
  final String? ssidName;
  final int? signalStrength;
}
```

### Usage

```dart
// Check for multi-interface
if (device.hasMultipleInterfaces) {
  print('Device has ${device.interfaceCount} interfaces');
  print('All MACs: ${device.allMacAddresses}');
  
  for (final iface in device.additionalInterfaces) {
    print('  ${iface.mac}: ${iface.isWifi ? "WiFi" : "Ethernet"}');
  }
}
```

---

## Error Handling & Fallbacks

| Scenario | Behavior |
|----------|----------|
| WiFi data unavailable | 5s timeout, proceed without enrichment |
| DataElements unsupported | `MeshTopologyInfo.empty`, no mesh display |
| Mesh fetch fails | Preserve existing mesh, no state update |
| Signal strength null | Display device, quality=0, link=unknown |
| Empty hostname | Device remains ungrouped |
| Master node missing | Create from SystemInfo |

---

## File Reference

### Models
- `lib/page/_shared/models/device_ui_model.dart`
- `lib/page/topology/models/node_ui_model.dart`
- `lib/page/_shared/models/mesh_topology_info.dart`

### Services
- `lib/page/devices/services/usp_devices_data_service.dart`
- `lib/page/_shared/utils/mesh_topology_builder.dart`

### Providers
- `lib/page/devices/providers/devices_data_provider.dart`

### Topology
- `lib/page/topology/helpers/usp_topology_builder.dart`
- `lib/page/topology/cards/usp_network_topology_card.dart`
- `lib/page/topology/views/usp_topology_view.dart`

### Utilities
- `lib/core/utils/wifi.dart` — Signal thresholds
- `lib/core/utils/device_classifier.dart` — Device icon classification

### Generated (Codegen)
- `lib/generated/connected_devices.g.dart`
- `lib/generated/data_elements_network.g.dart`
