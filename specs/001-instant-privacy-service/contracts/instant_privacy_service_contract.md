# InstantPrivacyService Contract

**Date**: 2026-01-02
**Branch**: `001-instant-privacy-service`

## Overview

API contract for `InstantPrivacyService` - a stateless service that handles all JNAP communication for the MAC filtering (Instant Privacy) feature.

## Provider Definition

```dart
final instantPrivacyServiceProvider = Provider<InstantPrivacyService>((ref) {
  return InstantPrivacyService(ref.watch(routerRepositoryProvider));
});
```

## Class Definition

```dart
/// Stateless service for MAC filtering (Instant Privacy) operations.
///
/// Encapsulates all JNAP communication for:
/// - getMACFilterSettings / setMACFilterSettings
/// - getSTABSSIDs
/// - getLocalDevice (for current device MAC)
///
/// Reference: constitution.md Article VI
class InstantPrivacyService {
  InstantPrivacyService(this._routerRepository);

  final RouterRepository _routerRepository;
}
```

## Methods

### fetchMacFilterSettings

Fetches MAC filter configuration from the router.

```dart
/// Fetches MAC filter settings and status from JNAP.
///
/// Parameters:
///   - forceRemote: If true, bypasses cache (default: false)
///   - updateStatusOnly: If true, returns only status without full settings
///
/// Returns: Tuple of (InstantPrivacySettings?, InstantPrivacyStatus?)
///   - If updateStatusOnly is true, first element is null
///
/// Throws: [ServiceError] on JNAP failure
Future<(InstantPrivacySettings?, InstantPrivacyStatus?)> fetchMacFilterSettings({
  bool forceRemote = false,
  bool updateStatusOnly = false,
});
```

**JNAP Actions Used**:
- `JNAPAction.getMACFilterSettings` (always)
- `JNAPAction.getSTABSSIDs` (conditional - if supported and not updateStatusOnly)

**Data Transformation**:
```
JNAP MACFilterSettings {
  macFilterMode: "Allow",
  maxMACAddresses: 32,
  macAddresses: ["AA:BB:CC:DD:EE:FF"]
}
    ↓
InstantPrivacySettings {
  mode: MacFilterMode.allow,
  macAddresses: ["AA:BB:CC:DD:EE:FF"],  // if mode == allow
  denyMacAddresses: [],                  // if mode == deny
  maxMacAddresses: 32,
  bssids: [...],
  myMac: "11:22:33:44:55:66"
}
```

---

### saveMacFilterSettings

Persists MAC filter settings to the router.

```dart
/// Saves MAC filter settings to JNAP.
///
/// Parameters:
///   - settings: The InstantPrivacySettings to save
///   - nodesMacAddresses: MAC addresses of mesh nodes (to include in allow list)
///
/// Throws: [ServiceError] on JNAP failure
Future<void> saveMacFilterSettings(
  InstantPrivacySettings settings,
  List<String> nodesMacAddresses,
);
```

**JNAP Actions Used**:
- `JNAPAction.setMACFilterSettings`

**Data Transformation**:
```
InstantPrivacySettings + nodesMacAddresses
    ↓
JNAP Payload {
  'macFilterMode': 'Allow',  // capitalize first letter
  'macAddresses': [
    ...settings.macAddresses,      // if allow mode
    ...nodesMacAddresses,          // if allow mode
    ...settings.bssids,            // if allow mode
  ] or [
    ...settings.denyMacAddresses   // if deny mode
  ]
}
```

---

### fetchStaBssids

Fetches STA BSSIDs for device identification.

```dart
/// Fetches STA BSSIDs from the router.
///
/// Returns: List of BSSID strings (uppercase), or empty list if not supported
///
/// Note: Gracefully returns empty list if router doesn't support getSTABSSIDs
Future<List<String>> fetchStaBssids();
```

**JNAP Actions Used**:
- `JNAPAction.getSTABSSIDs`

**Error Handling**:
- Returns `[]` if action not supported or fails

---

### fetchMyMacAddress

Gets the MAC address of the current device.

```dart
/// Fetches the MAC address of the current device.
///
/// Parameters:
///   - deviceList: List of known devices to search
///
/// Returns: MAC address string or null if not found
///
/// Note: Uses getLocalDevice to find deviceID, then looks up MAC in deviceList
Future<String?> fetchMyMacAddress(List<LinksysDevice> deviceList);
```

**JNAP Actions Used**:
- `JNAPAction.getLocalDevice`

**Error Handling**:
- Returns `null` if device not found or JNAP fails

---

## Error Handling

All methods follow constitution.md Article XIII:

```dart
try {
  await _routerRepository.send(JNAPAction.xxx, ...);
} on JNAPError catch (e) {
  throw _mapJnapError(e);
}

ServiceError _mapJnapError(JNAPError error) {
  // Currently no domain-specific errors for MAC filter
  // All errors map to UnexpectedError
  return UnexpectedError(originalError: error, message: error.result);
}
```

## Usage Example

```dart
// In InstantPrivacyNotifier
final service = ref.read(instantPrivacyServiceProvider);

@override
Future<(InstantPrivacySettings?, InstantPrivacyStatus?)> performFetch({
  bool forceRemote = false,
  bool updateStatusOnly = false,
}) async {
  final (settings, status) = await service.fetchMacFilterSettings(
    forceRemote: forceRemote,
    updateStatusOnly: updateStatusOnly,
  );

  // Fetch myMac if full settings needed
  if (settings != null) {
    final deviceList = ref.read(deviceManagerProvider).deviceList;
    final myMac = await service.fetchMyMacAddress(deviceList);
    return (settings.copyWith(myMac: myMac), status);
  }

  return (settings, status);
}

@override
Future<void> performSave() async {
  final nodesMacAddresses = ref
      .read(deviceManagerProvider)
      .nodeDevices
      .map((e) => e.getMacAddress().toUpperCase())
      .toList();

  await service.saveMacFilterSettings(
    state.settings.current,
    nodesMacAddresses,
  );
}
```

## Dependencies

| Dependency | Usage |
|------------|-------|
| `RouterRepository` | JNAP command execution |
| `JNAPAction` | Action constants |
| `MACFilterSettings` | JNAP model parsing |
| `ServiceError` | Error abstraction |

## Test Strategy

| Test Category | Mock |
|---------------|------|
| fetchMacFilterSettings | RouterRepository returns mock JNAPSuccess |
| saveMacFilterSettings | Verify RouterRepository.send called with correct payload |
| fetchStaBssids | RouterRepository returns mock or throws |
| fetchMyMacAddress | RouterRepository returns mock deviceID |
| Error handling | RouterRepository throws JNAPError |
