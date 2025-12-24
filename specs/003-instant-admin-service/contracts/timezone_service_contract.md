# TimezoneService Contract

**Feature**: 003-instant-admin-service
**Date**: 2025-12-22

## Overview

`TimezoneService` encapsulates all timezone-related JNAP communication, providing a clean interface for `TimezoneNotifier` to manage timezone settings without direct JNAP dependencies.

---

## Provider Definition

```dart
/// Riverpod provider for TimezoneService
final timezoneServiceProvider = Provider<TimezoneService>((ref) {
  return TimezoneService(ref.watch(routerRepositoryProvider));
});
```

---

## Class Definition

```dart
/// Stateless service for timezone JNAP operations
///
/// Handles all JNAP communication for timezone settings,
/// transforming JNAP responses to application-layer models.
class TimezoneService {
  /// Constructor injection of RouterRepository
  TimezoneService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Methods defined below
}
```

---

## Methods

### fetchTimezoneSettings

Fetches timezone configuration from the router.

**Signature**:
```dart
Future<(TimezoneSettings, TimezoneStatus)> fetchTimezoneSettings({
  bool forceRemote = false,
}) async
```

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| forceRemote | bool | No | If true, bypasses cache and fetches from router directly. Default: false |

**Returns**: `(TimezoneSettings, TimezoneStatus)` - A tuple containing:
- `TimezoneSettings`: Current timezone configuration (timezoneId, isDaylightSaving)
- `TimezoneStatus`: Read-only status including supported timezones list

**Throws**:
- `NetworkError`: Network communication failure
- `UnexpectedError`: Unmapped JNAP error

**JNAP Action**: `JNAPAction.getTimeSettings`

**Example**:
```dart
final service = ref.read(timezoneServiceProvider);
try {
  final (settings, status) = await service.fetchTimezoneSettings();
  // settings.timezoneId, settings.isDaylightSaving
  // status.supportedTimezones
} on ServiceError catch (e) {
  // Handle error
}
```

---

### saveTimezoneSettings

Saves timezone configuration to the router.

**Signature**:
```dart
Future<void> saveTimezoneSettings({
  required TimezoneSettings settings,
  required List<SupportedTimezone> supportedTimezones,
}) async
```

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| settings | TimezoneSettings | Yes | The timezone settings to save |
| supportedTimezones | List\<SupportedTimezone\> | Yes | List of supported timezones (for DST validation) |

**Returns**: `void`

**Throws**:
- `NetworkError`: Network communication failure
- `UnexpectedError`: Unmapped JNAP error

**JNAP Action**: `JNAPAction.setTimeSettings`

**JNAP Payload**:
```json
{
  "timeZoneID": "PST8PDT",
  "autoAdjustForDST": true
}
```

**Business Logic**:
- If selected timezone does not support DST (`observesDST == false`), `autoAdjustForDST` is sent as `false` regardless of user setting

**Example**:
```dart
final service = ref.read(timezoneServiceProvider);
try {
  await service.saveTimezoneSettings(
    settings: currentSettings,
    supportedTimezones: status.supportedTimezones,
  );
} on ServiceError catch (e) {
  // Handle error
}
```

---

## Error Handling

All methods follow Article XIII error handling:

```dart
try {
  final result = await _routerRepository.send(JNAPAction.getTimeSettings, ...);
  // Transform result
} on JNAPError catch (e) {
  throw mapJnapErrorToServiceError(e);
}
```

---

## Testing Requirements

| Test Case | Description |
|-----------|-------------|
| fetchTimezoneSettings returns settings and status on success | Verify tuple contains correct TimezoneSettings and TimezoneStatus |
| fetchTimezoneSettings sorts timezones by UTC offset | Verify supportedTimezones are sorted ascending by utcOffsetMinutes |
| fetchTimezoneSettings throws ServiceError on JNAP failure | Verify JNAPError is mapped to ServiceError |
| saveTimezoneSettings sends correct JNAP payload | Verify timeZoneID and autoAdjustForDST are correctly formatted |
| saveTimezoneSettings handles DST for non-DST timezones | Verify autoAdjustForDST is false when timezone doesn't support DST |
| saveTimezoneSettings throws ServiceError on JNAP failure | Verify JNAPError is mapped to ServiceError |

**Coverage Target**: ≥90%
