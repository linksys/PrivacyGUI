# InstantSafetyService Contract

**Feature**: 004-instant-safety-service
**Date**: 2025-12-22

## Overview

`InstantSafetyService` encapsulates all JNAP communication for the InstantSafety (Safe Browsing) feature. It handles fetching and saving DNS-based safe browsing configuration.

## Provider Definition

```dart
/// Riverpod provider for InstantSafetyService
final instantSafetyServiceProvider = Provider<InstantSafetyService>((ref) {
  return InstantSafetyService(ref.watch(routerRepositoryProvider));
});
```

---

## Class Definition

```dart
/// Stateless service for instant safety (safe browsing) operations
///
/// Encapsulates JNAP communication for DNS-based parental control settings,
/// separating business logic from state management (InstantSafetyNotifier).
class InstantSafetyService {
  /// Constructor injection of dependencies
  InstantSafetyService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Internal cache for LAN settings (used in save operation)
  RouterLANSettings? _cachedLanSettings;
}
```

---

## Method Contracts

### fetchSettings

Fetches current safe browsing configuration from router.

**Signature**:
```dart
Future<InstantSafetyFetchResult> fetchSettings({
  required Map<String, dynamic>? deviceInfo,
  bool forceRemote = false,
}) async
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| deviceInfo | Map<String, dynamic>? | Yes | Device info from polling provider for Fortinet compatibility check |
| forceRemote | bool | No (default: false) | Force fresh fetch from router |

**Returns**: `InstantSafetyFetchResult`
```dart
class InstantSafetyFetchResult {
  final InstantSafetyType safeBrowsingType;
  final bool hasFortinet;
}
```

**Throws**:
| Error Type | Condition |
|------------|-----------|
| `NetworkError` | JNAP communication failure |
| `UnexpectedError` | Unexpected JNAP error response |

**Behavior**:
1. Calls `getLANSettings` JNAP action
2. Caches full `RouterLANSettings` for later save operation
3. Determines safe browsing type from DNS server configuration
4. Checks Fortinet compatibility using provided device info
5. Returns result tuple

**Example**:
```dart
final service = ref.read(instantSafetyServiceProvider);
final deviceInfo = ref.read(pollingProvider).value?.data[JNAPAction.getDeviceInfo]?.output;

try {
  final result = await service.fetchSettings(
    deviceInfo: deviceInfo,
    forceRemote: true,
  );
  // result.safeBrowsingType: InstantSafetyType.openDNS
  // result.hasFortinet: false
} on ServiceError catch (e) {
  // Handle error
}
```

---

### saveSettings

Saves safe browsing configuration to router.

**Signature**:
```dart
Future<void> saveSettings(InstantSafetyType safeBrowsingType) async
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| safeBrowsingType | InstantSafetyType | Yes | Selected safe browsing provider |

**Returns**: `void` on success

**Throws**:
| Error Type | Condition |
|------------|-----------|
| `InvalidInputError` | Cached LAN settings not available (fetch not called) |
| `NetworkError` | JNAP communication failure |
| `UnexpectedError` | Unexpected JNAP error response |

**Behavior**:
1. Validates cached LAN settings exist (throws `InvalidInputError` if not)
2. Constructs DHCP settings with appropriate DNS servers based on type:
   - `fortinet`: DNS1=208.91.114.155
   - `openDNS`: DNS1=208.67.222.222, DNS2=208.67.220.220
   - `off`: Clear all DNS servers
3. Calls `setLANSettings` JNAP action
4. Allows `JNAPSideEffectError` to propagate (handled by UI layer)

**Example**:
```dart
final service = ref.read(instantSafetyServiceProvider);

try {
  await service.saveSettings(InstantSafetyType.openDNS);
  // Success - settings saved
} on InvalidInputError {
  // Fetch was not called before save
} on ServiceError catch (e) {
  // Handle network/unexpected errors
}
```

---

### checkFortinetCompatibility (Private Helper)

Checks if device supports Fortinet safe browsing.

**Signature**:
```dart
bool _checkFortinetCompatibility(Map<String, dynamic>? deviceInfo)
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| deviceInfo | Map<String, dynamic>? | Yes | Raw device info output from JNAP |

**Returns**: `bool` - true if Fortinet is supported

**Behavior**:
1. Returns `false` if deviceInfo is null
2. Parses model number and firmware version
3. Checks against compatibility map (currently empty - always returns false)
4. Validates firmware version is within compatible range

---

### determineSafeBrowsingType (Private Helper)

Determines current safe browsing type from DNS configuration.

**Signature**:
```dart
InstantSafetyType _determineSafeBrowsingType(RouterLANSettings lanSettings)
```

**Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| lanSettings | RouterLANSettings | Yes | LAN settings from JNAP |

**Returns**: `InstantSafetyType`

**Logic**:
```dart
final dnsServer1 = lanSettings.dhcpSettings.dnsServer1;
if (dnsServer1 == '208.91.114.155') {
  return InstantSafetyType.fortinet;
} else if (dnsServer1 == '208.67.222.222') {
  return InstantSafetyType.openDNS;
} else {
  return InstantSafetyType.off;
}
```

---

## Error Mapping

Service maps JNAP errors to ServiceError types:

```dart
ServiceError _mapJnapError(JNAPError error) {
  // Most getLANSettings/setLANSettings errors are network-level
  // No specific business error codes to map
  return UnexpectedError(
    originalError: error,
    message: error.error,
  );
}
```

---

## DNS Configuration Constants

Private constants within service:

```dart
// Fortinet Safe Browsing DNS
static const _fortinetDns1 = '208.91.114.155';

// OpenDNS Family Shield (NOW-713: Updated IPs)
static const _openDnsDns1 = '208.67.222.222';
static const _openDnsDns2 = '208.67.220.220';
```

---

## Usage in Provider

```dart
class InstantSafetyNotifier extends Notifier<InstantSafetyState>
    with PreservableNotifierMixin<InstantSafetySettings, InstantSafetyStatus, InstantSafetyState> {

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final service = ref.read(instantSafetyServiceProvider);
    final deviceInfo = ref.read(pollingProvider).value?.data[JNAPAction.getDeviceInfo]?.output;

    try {
      final result = await service.fetchSettings(
        deviceInfo: deviceInfo,
        forceRemote: forceRemote,
      );

      final settings = InstantSafetySettings(safeBrowsingType: result.safeBrowsingType);
      final status = InstantSafetyStatus(hasFortinet: result.hasFortinet);

      return (settings, status);
    } on ServiceError catch (e) {
      // Log error, rethrow for mixin to handle
      rethrow;
    }
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(instantSafetyServiceProvider);
    final currentType = state.settings.current.safeBrowsingType;

    try {
      await service.saveSettings(currentType);
    } on JNAPSideEffectError {
      rethrow; // Let UI handle side effects
    } on ServiceError catch (e) {
      // Transform to user-friendly error if needed
      rethrow;
    }
  }
}
```
