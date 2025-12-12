# Phase 1 Design: Data Models & Contracts

**Date**: 2025-12-09
**Status**: Complete

---

## Entity Definitions

### Layer 1: Data Models (JNAP Protocol Layer)

Located in: `lib/core/jnap/models/`

#### FirewallSettings

**Current Location**: `lib/core/jnap/models/firewall_settings.dart`

**Responsibility**: Exact representation of JNAP firewall response

**Fields**:
```dart
class FirewallSettings {
  final bool blockAnonymousRequests;
  final bool blockIDENT;
  final bool blockIPSec;
  final bool blockL2TP;
  final bool blockMulticast;
  final bool blockNATRedirection;
  final bool blockPPTP;
  final bool isIPv4FirewallEnabled;
  final bool isIPv6FirewallEnabled;
}
```

**Responsibilities**:
- JNAP protocol mapping only
- `fromMap()` parses JNAP response
- `toMap()` prepares for JNAP request
- No business logic
- No UI concerns

**Validation Rules**:
- All fields required (no nulls)
- Boolean values only
- No transformation needed

**Serialization**:
- Uses `@freezed` + `json_serializable`
- toJson/fromJson for testing
- toMap/fromMap for JNAP protocol

---

#### IPv6PortServiceRule

**Current Location**: `lib/core/jnap/models/ipv6_port_service_rule.dart`

**Responsibility**: Single port forwarding rule from JNAP

**Fields**:
```dart
class IPv6PortServiceRule {
  final String protocol;           // e.g., "TCP", "UDP"
  final int externalPort;
  final int internalPort;
  final String internalIPAddress;  // IPv6 address
  final String description;
  final bool enabled;
}
```

**Responsibilities**:
- Exact JNAP representation
- Protocol validation (TCP/UDP only)
- Port range validation (0-65535)

**Validation Rules**:
- Protocol: TCP or UDP only
- Ports: 1-65535
- IPv6 address format validation
- Description: max 128 characters

**Serialization**: Same as FirewallSettings

---

### Layer 2: Application Models (UI Layer Models)

Located in: `lib/page/advanced_settings/firewall/providers/`

#### FirewallUISettings

**File**: `lib/page/advanced_settings/firewall/providers/firewall_state.dart`

**Responsibility**: Application-layer adaptation of FirewallSettings for Presentation use

**Relationship**: 1:1 mapping to FirewallSettings (no additional logic)

**Fields**:
```dart
class FirewallUISettings extends Equatable {
  final bool blockAnonymousRequests;
  final bool blockIDENT;
  final bool blockIPSec;
  final bool blockL2TP;
  final bool blockMulticast;
  final bool blockNATRedirection;
  final bool blockPPTP;
  final bool isIPv4FirewallEnabled;
  final bool isIPv6FirewallEnabled;

  const FirewallUISettings({...});
}
```

**Responsibilities**:
- Bridge between Data layer (FirewallSettings) and Presentation layer (Views)
- No JNAP protocol knowledge
- Used only in Provider and View layers
- Equatable for state comparison
- copyWith for immutable updates

**Validation Rules**:
- Same as FirewallSettings (inherited from Data layer)

**When to use**:
- ✅ In Provider notifier state
- ✅ In View widgets
- ✅ In View tests
- ❌ Never in JNAP/Repository code

---

#### IPv6PortServiceRuleUI

**File**: `lib/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart`

**Responsibility**: Application-layer adaptation of IPv6PortServiceRule

**Relationship**: 1:1 mapping to IPv6PortServiceRule

**Fields**:
```dart
class IPv6PortServiceRuleUI extends Equatable {
  final String protocol;
  final int externalPort;
  final int internalPort;
  final String internalIPAddress;
  final String description;
  final bool enabled;

  const IPv6PortServiceRuleUI({...});
}
```

**Responsibilities**:
- Same as FirewallUISettings pattern
- Used in Port Service list Provider and Views

---

### Layer 2: State Models (Provider State)

#### FirewallState

**File**: `lib/page/advanced_settings/firewall/providers/firewall_state.dart`

**Responsibility**: Provider state container using PreservableNotifierMixin

**Structure**:
```dart
class FirewallState extends Equatable {
  final Preservable<FirewallUISettings> settings;
  final EmptyStatus status;

  const FirewallState({
    required this.settings,
    required this.status,
  });

  @override
  List<Object?> get props => [settings, status];

  FirewallState copyWith({...}) {...}
}
```

**Preservable Pattern**:
- `original`: Server state (unchanged from fetch)
- `current`: User-edited state (local modifications)
- Enables undo/reset functionality

**Status**:
- `EmptyStatus`: No additional status fields needed
- Used for loading/error states in Provider

---

#### IPv6PortServiceListState

**File**: `lib/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart`

**Responsibility**: Provider state for port service rule list

**Structure**:
```dart
class IPv6PortServiceListState extends Equatable {
  final List<IPv6PortServiceRuleUI> rules;
  final EmptyStatus status;

  const IPv6PortServiceListState({...});
}
```

**Responsibilities**:
- Manage list of port rules
- Support add/update/delete operations
- Preserve original and current states

---

#### IPv6PortServiceRuleState

**File**: `lib/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart`

**Responsibility**: State for individual rule editing

**Structure**: Similar to FirewallState with Preservable pattern

---

## Transformation Pipelines

### Fetch Pipeline (JNAP → Data → UI)

```
JNAP Response (JSON)
    ↓
FirewallSettings.fromMap() [Data Layer]
    ↓
Service._parseFirewallSettings() [Application Layer]
    ↓
FirewallUISettings construction [Application Layer]
    ↓
Provider receives FirewallUISettings
    ↓
Views use FirewallUISettings (never see FirewallSettings)
```

### Save Pipeline (UI → Data → JNAP)

```
FirewallUISettings (from View/Provider)
    ↓
Service.saveFirewallSettings() [Application Layer]
    ↓
FirewallSettings construction [Application Layer]
    ↓
FirewallSettings.toMap() [Data Layer]
    ↓
Repository.send(JNAPAction, data:map)
    ↓
JNAP Request (JSON)
```

---

## API Contracts

### Service Layer Interface

**FirewallSettingsService**:

```dart
/// Fetch firewall settings and transform to UI models
Future<(FirewallUISettings?, EmptyStatus?)> fetchFirewallSettings(
  Ref ref, {
  bool forceRemote = false,
  bool updateStatusOnly = false,
}) async { ... }

/// Save firewall settings from UI model to device
Future<void> saveFirewallSettings(
  Ref ref,
  FirewallUISettings settings,
) async { ... }
```

**IPv6PortServiceListService**:

```dart
Future<(List<IPv6PortServiceRuleUI>?, EmptyStatus?)> fetchPortServiceRules(
  Ref ref,
  {bool forceRemote = false},
) async { ... }

Future<void> addPortServiceRule(
  Ref ref,
  IPv6PortServiceRuleUI rule,
) async { ... }

Future<void> updatePortServiceRule(
  Ref ref,
  IPv6PortServiceRuleUI rule,
) async { ... }

Future<void> deletePortServiceRule(
  Ref ref,
  IPv6PortServiceRuleUI rule,
) async { ... }
```

---

## Serialization Specifications

### State Serialization (for testing)

Both UI models must support serialization for state preservation tests:

```dart
// FirewallUISettings must support:
Map<String, dynamic> toMap();
factory FirewallUISettings.fromMap(Map<String, dynamic> map);

String toJson();
factory FirewallUISettings.fromJson(String json);
```

### Round-Trip Validation

Critical test: Serialize → Deserialize → Should be equal

```
FirewallUISettings original
  ↓ toMap()
Map<String, dynamic>
  ↓ fromMap()
FirewallUISettings restored
  ↓ assertEquals(original, restored)
✓ PASS
```

---

## Validation Rules Matrix

| Field | Type | Constraints | Error Message |
|-------|------|-------------|---------------|
| blockAnonymousRequests | bool | - | - |
| blockIDENT | bool | - | - |
| blockIPSec | bool | - | - |
| blockL2TP | bool | - | - |
| blockMulticast | bool | - | - |
| blockNATRedirection | bool | - | - |
| blockPPTP | bool | - | - |
| isIPv4FirewallEnabled | bool | - | - |
| isIPv6FirewallEnabled | bool | - | - |
| protocol | String | TCP\|UDP only | "Protocol must be TCP or UDP" |
| externalPort | int | 1-65535 | "Port must be 1-65535" |
| internalPort | int | 1-65535 | "Port must be 1-65535" |
| internalIPAddress | String | Valid IPv6 | "Invalid IPv6 address format" |
| description | String | max 128 chars | "Description too long (max 128)" |

---

## State Transitions

### Firewall Settings Flow

```
INITIAL STATE
├── settings: Preservable(original: defaults, current: defaults)
├── status: EmptyStatus()

↓ Fetch
LOADING
├── [same settings]
├── status: indicates loading

↓ Success
LOADED
├── settings: Preservable(original: fetched, current: fetched)
├── status: EmptyStatus()

↓ User Edit
EDITED
├── settings: Preservable(original: unchanged, current: edited)
├── status: EmptyStatus()

↓ Save
SAVING
├── [same as EDITED]
├── status: indicates saving

↓ Save Success
SAVED
├── settings: Preservable(original: saved, current: saved)
├── status: EmptyStatus()

↓ Reset
RESET
├── settings: Preservable(original: reset_to, current: reset_to)
├── status: EmptyStatus()
```

---

## Phase 1 Completion Checklist

- [x] Data layer models defined (FirewallSettings, IPv6PortServiceRule)
- [x] Application layer models defined (FirewallUISettings, IPv6PortServiceRuleUI)
- [x] State models defined (FirewallState, IPv6PortServiceListState, etc.)
- [x] Transformation pipelines documented
- [x] Service layer interface contracts defined
- [x] Serialization specifications complete
- [x] Validation rules specified
- [x] State transitions documented

---

**Ready for Phase 2**: Task generation via `/speckit.tasks`
