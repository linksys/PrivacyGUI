# Phase 1: Data Model & Service Contracts

**Date**: 2024-12-03
**Purpose**: Define service interface and data structures for AdministrationSettingsService extraction

---

## Data Models & Entities

### 1. AdministrationSettings (Aggregate)

**Purpose**: Root aggregate combining all administration-related settings fetched from the device.

**Fields**:
```dart
@immutable
class AdministrationSettings {
  final ManagementSettings managementSettings;  // HTTP, HTTPS, wireless, remote access settings
  final bool enabledALG;                        // Application Layer Gateway enabled
  final bool isExpressForwardingSupported;      // Device capability flag
  final bool enabledExpressForwarfing;          // Current state (note: typo in existing code)
  final bool isUPnPEnabled;                     // UPnP enabled state
  final bool canUsersConfigure;                 // Permission for users to configure UPnP
  final bool canUsersDisableWANAccess;          // Permission for users to disable WAN access
}
```

**Validation Rules**:
- All boolean fields must be defined (no null values)
- ManagementSettings must be valid and non-null
- No constraints on specific boolean combinations (device may have any valid state)

**Relationships**:
- **Composition**: Contains ManagementSettings aggregate
- **Dependencies**: Uses ALGSettings, UPnPSettings, ExpressForwardingSettings for individual setting details

---

### 2. ManagementSettings

**Purpose**: Device management access configuration (HTTP, HTTPS, wireless, remote).

**Existing Fields** (from `core/jnap/models/management_settings.dart`):
```dart
final bool canManageUsingHTTP;
final bool canManageUsingHTTPS;
final bool isManageWirelesslySupported;
final bool canManageRemotely;
```

**Usage**: Determines which management protocols are enabled on the device.

---

### 3. UPnPSettings

**Purpose**: Universal Plug and Play configuration.

**Existing Fields** (from `core/jnap/models/unpn_settings.dart`):
- UPnP enable/disable state
- User configuration permissions
- Port mapping configuration (if applicable)

**Usage**: Controls port mapping and device discovery capabilities.

---

### 4. ALGSettings

**Purpose**: Application Layer Gateway configuration.

**Existing Fields** (from `core/jnap/models/alg_settings.dart`):
- ALG enable/disable state
- Protocol-specific settings (FTP, DNS, SIP, etc.)

**Usage**: Manages application-level gateway features for protocol-specific handling.

---

### 5. ExpressForwardingSettings

**Purpose**: Express port forwarding (UPnP-like simplified interface).

**Existing Fields** (from `core/jnap/models/express_forwarding_settings.dart`):
- Enable/disable state
- Supported capability flag
- Port mapping entries (if applicable)

**Usage**: Simplified interface for users to quickly configure port forwarding without full UPnP UI.

---

## Service Interface Contract

### AdministrationSettingsService

**Purpose**: Orchestrate JNAP actions for administration settings and transform responses to domain models.

**Responsibility**:
- Coordinate four JNAP actions in a single transaction
- Parse JNAP responses into domain models
- Provide clear error context on failure
- Accept optional parameters for caching control

**Public Interface**:

```dart
class AdministrationSettingsService {
  /// Fetches all administration settings from the device via JNAP.
  ///
  /// Orchestrates four JNAP actions in a single transaction:
  /// - getManagementSettings
  /// - getUPnPSettings
  /// - getALGSettings
  /// - getExpressForwardingSettings
  ///
  /// **Parameters**:
  /// - [ref]: Riverpod ref for accessing RouterRepository
  /// - [forceRemote]: If true, bypasses cache and fetches from device (default: false)
  /// - [updateStatusOnly]: If true, fetches only status (not full settings) - currently unused
  ///
  /// **Returns**: [AdministrationSettings] on success
  ///
  /// **Throws**: [JNAPTransactionException] if any action fails. Exception includes:
  /// - Which action failed (action name)
  /// - JNAP error code (if available)
  /// - Human-readable error message
  ///
  /// **Example**:
  /// ```dart
  /// final settings = await service.fetchAdministrationSettings(
  ///   ref,
  ///   forceRemote: true,
  /// );
  /// ```
  Future<AdministrationSettings> fetchAdministrationSettings(
    Ref ref, {
    bool forceRemote = false,
    bool updateStatusOnly = false,
  });
}
```

**Error Handling**:

When JNAP transaction fails:
- Catch `JNAPResult` indicating failure
- Extract failure reason (which action, error code, details)
- Throw descriptive exception or return failure object (existing pattern in codebase)
- **Note**: Architecture allows for Result<T, Failure> pattern; will follow existing codebase pattern

**Testing Interface**:

Service methods designed for easy mocking:
```dart
// Test setup (pseudocode)
final mockRepo = MockRouterRepository();
when(mockRepo.transaction(...))
  .thenAnswer((_) async => JNAPResult.success(...));

// Service uses: ref.read(routerRepositoryProvider) → mockRepo
// Tests mock Riverpod provider or use ProviderContainer with test overrides
```

---

## State Transitions

**No new state transitions**: Service is stateless. State transitions remain in Notifier via PreservableNotifierMixin.

**Existing Notifier State Machine** (unchanged):
```
AdministrationSettingsState
├── settings: Preservable<AdministrationSettings>  // original vs current
└── status: AdministrationStatus                   // loading, success, error, etc.
```

---

## API Contracts

### JNAP Transaction Structure

**Input to Service**:
```dart
JNAPTransactionBuilder(
  commands: [
    MapEntry(JNAPAction.getManagementSettings, {}),
    MapEntry(JNAPAction.getUPnPSettings, {}),
    MapEntry(JNAPAction.getALGSettings, {}),
    MapEntry(JNAPAction.getExpressForwardingSettings, {}),
  ],
  auth: true,  // Requires authentication
)
```

**Output from JNAP**:
```dart
Map<JNAPAction, dynamic> resultMap = {
  JNAPAction.getManagementSettings: { /* raw JSON */ },
  JNAPAction.getUPnPSettings: { /* raw JSON */ },
  JNAPAction.getALGSettings: { /* raw JSON */ },
  JNAPAction.getExpressForwardingSettings: { /* raw JSON */ },
}
```

**Service Transformation**:
```dart
// Pseudocode showing transformation flow
AdministrationSettings _parseResults(Map<JNAPAction, dynamic> resultMap) {
  final mgmtResult = JNAPTransactionSuccessWrap.getResult(
    JNAPAction.getManagementSettings,
    resultMap,
  );
  final mgmtSettings = ManagementSettings.fromMap(mgmtResult.output);

  // ... repeat for UPnP, ALG, ExpressForwarding

  return AdministrationSettings(
    managementSettings: mgmtSettings,
    enabledALG: algSettings.enabled,
    isExpressForwardingSupported: expressSettings.isSupported,
    // ... etc
  );
}
```

---

## Validation Rules

### Input Validation
- Ref must be non-null (provided by caller)
- Optional parameters (forceRemote, updateStatusOnly) have sensible defaults

### Output Validation
- All fields of AdministrationSettings must be non-null
- All nested models (ManagementSettings, UPnPSettings, etc.) must be valid
- No partial data: if any JNAP action fails, entire fetch fails (all-or-nothing)

### Error Conditions
- **Transaction failure**: Any JNAP action returns error → service throws with action context
- **Parsing failure**: Invalid response format → service throws with parsing error details
- **Repository unavailable**: ref.read fails → Riverpod bubbles error naturally

---

## Dependencies & Relationships

```
AdministrationSettingsService
  ├── depends on: RouterRepository (via ref.read)
  ├── depends on: JNAP actions (getManagementSettings, etc.)
  ├── depends on: Domain models (.fromMap() constructors)
  │   ├── ManagementSettings
  │   ├── UPnPSettings
  │   ├── ALGSettings
  │   └── ExpressForwardingSettings
  └── used by: AdministrationSettingsNotifier (via delegation)

AdministrationSettingsNotifier
  ├── depends on: AdministrationSettingsService
  ├── depends on: PreservableNotifierMixin
  ├── manages: AdministrationSettingsState
  └── used by: UI layer (via administrationSettingsProvider)
```

---

## Backward Compatibility

**No breaking changes to existing models**:
- ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings remain identical
- AdministrationSettings aggregate structure unchanged
- AdministrationSettingsNotifier public API unchanged

**Internal-only changes**:
- JNAP logic moved from Notifier to Service
- Notifier now delegates to Service (invisible to consumers)

---

## Ready for Implementation

✅ Data models defined
✅ Service interface specified
✅ JNAP contracts documented
✅ Error handling strategy set
✅ Backward compatibility confirmed

Next: Generate task list via `/speckit.tasks`
