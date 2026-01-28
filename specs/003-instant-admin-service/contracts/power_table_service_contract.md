# PowerTableService Contract

**Feature**: 003-instant-admin-service
**Date**: 2025-12-22

## Overview

`PowerTableService` encapsulates all power table (transmit region) JNAP communication, providing a clean interface for `PowerTableNotifier` to manage transmit region settings without direct JNAP dependencies.

---

## Provider Definition

```dart
/// Riverpod provider for PowerTableService
final powerTableServiceProvider = Provider<PowerTableService>((ref) {
  return PowerTableService(ref.watch(routerRepositoryProvider));
});
```

---

## Class Definition

```dart
/// Stateless service for power table JNAP operations
///
/// Handles JNAP communication for transmit region settings,
/// transforming JNAP responses to application-layer models.
class PowerTableService {
  /// Constructor injection of RouterRepository
  PowerTableService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Methods defined below
}
```

---

## Methods

### parsePowerTableSettings

Parses power table settings from polling data.

**Signature**:
```dart
PowerTableState? parsePowerTableSettings(
  Map<JNAPAction, JNAPResult> pollingData,
)
```

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| pollingData | Map\<JNAPAction, JNAPResult\> | Yes | Polling data containing getPowerTableSettings result |

**Returns**: `PowerTableState?`
- Returns `PowerTableState` if power table data exists in polling data
- Returns `null` if power table data is not available

**Throws**: Does not throw (parsing is best-effort)

**Business Logic**:
- Extracts `JNAPAction.getPowerTableSettings` result from polling data
- Transforms `PowerTableSettings` (JNAP model) to `PowerTableState`
- Resolves country codes to `PowerTableCountries` enum
- Sorts supported countries by enum index

**Example**:
```dart
final service = ref.read(powerTableServiceProvider);
final pollingData = ref.watch(pollingProvider).value?.data ?? {};
final state = service.parsePowerTableSettings(pollingData);
if (state == null) {
  return PowerTableState(isPowerTableSelectable: false, supportedCountries: []);
}
```

---

### savePowerTableCountry

Saves the selected transmit region country.

**Signature**:
```dart
Future<void> savePowerTableCountry(PowerTableCountries country) async
```

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| country | PowerTableCountries | Yes | The country/region to set |

**Returns**: `void`

**Throws**:
- `NetworkError`: Network communication failure
- `UnexpectedError`: Unmapped JNAP error

**JNAP Action**: `JNAPAction.setPowerTableSettings`

**JNAP Payload**:
```json
{
  "country": "USA"
}
```

**Note**: Country code is sent as uppercase string (e.g., "USA", "TWN", "JPN")

**Example**:
```dart
final service = ref.read(powerTableServiceProvider);
try {
  await service.savePowerTableCountry(PowerTableCountries.usa);
} on ServiceError catch (e) {
  // Handle error
}
```

---

## Error Handling

Save method follows Article XIII error handling:

```dart
try {
  await _routerRepository.send(
    JNAPAction.setPowerTableSettings,
    data: {'country': country.name.toUpperCase()},
    auth: true,
  );
} on JNAPError catch (e) {
  throw mapJnapErrorToServiceError(e);
}
```

---

## Data Transformation

### JNAP Response → PowerTableState

```dart
// JNAP Response (from polling)
{
  "isPowerTableSelectable": true,
  "supportedCountries": ["USA", "CAN", "JPN", "TWN"],
  "country": "USA"
}

// Transformed to PowerTableState
PowerTableState(
  isPowerTableSelectable: true,
  supportedCountries: [
    PowerTableCountries.usa,
    PowerTableCountries.can,
    PowerTableCountries.jpn,
    PowerTableCountries.twn,
  ],
  country: PowerTableCountries.usa,
)
```

---

## Testing Requirements

| Test Case | Description |
|-----------|-------------|
| parsePowerTableSettings returns state when data exists | Verify PowerTableState is correctly created from polling data |
| parsePowerTableSettings returns null when data missing | Verify null is returned when getPowerTableSettings not in polling data |
| parsePowerTableSettings resolves country codes correctly | Verify string codes are mapped to PowerTableCountries enum |
| parsePowerTableSettings sorts countries by index | Verify supportedCountries are sorted |
| parsePowerTableSettings handles non-selectable state | Verify isPowerTableSelectable=false is handled |
| savePowerTableCountry sends correct JNAP payload | Verify country is sent as uppercase string |
| savePowerTableCountry throws ServiceError on JNAP failure | Verify JNAPError is mapped to ServiceError |

**Coverage Target**: ≥90%
