# Data Model: Instant Admin Service Extraction

**Feature**: 003-instant-admin-service
**Date**: 2025-12-22

## Overview

This document describes the data models involved in the timezone and power table service extraction. Most models already exist; this refactoring focuses on where they are used (Service vs Provider layer).

---

## Existing Models (No Changes Required)

### TimezoneSettings (Application Layer)

**Location**: `lib/page/instant_admin/providers/timezone_state.dart`

```dart
class TimezoneSettings extends Equatable {
  final bool isDaylightSaving;
  final String timezoneId;
}
```

**Usage**:
- Service layer: Returned from `fetchTimezoneSettings()`
- Provider layer: Stored in `TimezoneState.settings`

---

### TimezoneStatus (Application Layer)

**Location**: `lib/page/instant_admin/providers/timezone_state.dart`

```dart
class TimezoneStatus extends Equatable {
  final List<SupportedTimezone> supportedTimezones;
  final String? error;
}
```

**Usage**:
- Service layer: Returned from `fetchTimezoneSettings()`
- Provider layer: Stored in `TimezoneState.status`

---

### SupportedTimezone (Data Layer - JNAP)

**Location**: `lib/core/jnap/models/timezone.dart`

```dart
class SupportedTimezone extends Equatable {
  final bool observesDST;
  final String timeZoneID;
  final String description;
  final int utcOffsetMinutes;
}
```

**Usage**:
- Service layer: Import allowed (transforms JNAP response)
- Provider layer: ❌ Should NOT import directly (receives via TimezoneStatus)

---

### TimezoneState (Application Layer)

**Location**: `lib/page/instant_admin/providers/timezone_state.dart`

```dart
class TimezoneState extends FeatureState<TimezoneSettings, TimezoneStatus> {
  // Uses PreservableNotifierMixin pattern
}
```

**Usage**:
- Provider layer only
- No changes required

---

### PowerTableState (Application Layer)

**Location**: `lib/page/instant_admin/providers/power_table_state.dart`

```dart
class PowerTableState extends Equatable {
  final bool isPowerTableSelectable;
  final List<PowerTableCountries> supportedCountries;
  final PowerTableCountries? country;
}
```

**Usage**:
- Service layer: Returned from `parsePowerTableSettings()`
- Provider layer: Managed by `PowerTableNotifier`

---

### PowerTableCountries (Application Layer - Enum)

**Location**: `lib/page/instant_admin/providers/power_table_provider.dart`

```dart
enum PowerTableCountries {
  chn, hkg, ind, idn, jpn, kor, phl, sgp, twn, tha, xah,
  aus, can, eee, lam, bhr, egy, kwt, omn, qat, sau, tur, are, xme, nzl, usa;

  String resolveDisplayText(BuildContext context) => ...;
  static PowerTableCountries resolve(String country) => ...;
}
```

**Usage**:
- Service layer: Used for JNAP payload construction
- Provider layer: Used for state management
- UI layer: Used for display text resolution

---

### PowerTableSettings (Data Layer - JNAP)

**Location**: `lib/core/jnap/models/power_table_settings.dart`

```dart
class PowerTableSettings {
  final bool isPowerTableSelectable;
  final List<String> supportedCountries;
  final String? country;
}
```

**Usage**:
- Service layer: Import allowed (transforms JNAP response)
- Provider layer: ❌ Should NOT import

---

## Data Flow Diagrams

### Timezone Fetch Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         JNAP Layer                              │
│  RouterRepository.send(JNAPAction.getTimeSettings)              │
│  Returns: { timeZoneID, supportedTimeZones[], autoAdjustForDST }│
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TimezoneService                            │
│  fetchTimezoneSettings()                                        │
│  - Parses JNAP response                                         │
│  - Creates TimezoneSettings(isDaylightSaving, timezoneId)       │
│  - Creates TimezoneStatus(supportedTimezones, error)            │
│  Returns: (TimezoneSettings, TimezoneStatus)                    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     TimezoneNotifier                            │
│  performFetch()                                                 │
│  - Calls service.fetchTimezoneSettings()                        │
│  - Updates state with returned tuple                            │
└─────────────────────────────────────────────────────────────────┘
```

### Power Table Fetch Flow (via Polling)

```
┌─────────────────────────────────────────────────────────────────┐
│                      PollingProvider                            │
│  Periodically fetches JNAP data including getPowerTableSettings │
│  Stores in pollingProvider.value.data                           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PowerTableNotifier                           │
│  build() - watches pollingProvider                              │
│  - Extracts getPowerTableSettings result from polling data      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PowerTableService                           │
│  parsePowerTableSettings(pollingData)                           │
│  - Extracts PowerTableSettings from polling data                │
│  - Transforms to PowerTableState                                │
│  Returns: PowerTableState                                       │
└─────────────────────────────────────────────────────────────────┘
```

### Save Flow (Both Services)

```
┌─────────────────────────────────────────────────────────────────┐
│                      Provider Layer                             │
│  performSave() / save()                                         │
│  - Reads current state                                          │
│  - Calls service method with UI model data                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                              │
│  saveTimezoneSettings() / savePowerTableCountry()               │
│  - Transforms UI model to JNAP payload                          │
│  - Calls RouterRepository.send()                                │
│  - Catches JNAPError → throws ServiceError                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                       JNAP Layer                                │
│  RouterRepository.send(JNAPAction.setXxx, data: {...})          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Import Rules After Refactoring

| File | Allowed Imports | Forbidden Imports |
|------|-----------------|-------------------|
| `timezone_service.dart` | `jnap/models/timezone.dart`, `jnap/result/jnap_result.dart`, `service_error.dart` | - |
| `power_table_service.dart` | `jnap/models/power_table_settings.dart`, `jnap/result/jnap_result.dart`, `service_error.dart` | - |
| `timezone_provider.dart` | `timezone_service.dart`, `timezone_state.dart`, `service_error.dart` | `jnap/models/*`, `jnap/result/*` |
| `power_table_provider.dart` | `power_table_service.dart`, `power_table_state.dart`, `service_error.dart` | `jnap/models/*`, `jnap/result/*` |

---

## Validation Rules

### TimezoneSettings
- `timezoneId`: Must be a valid timezone ID from `supportedTimezones` list
- `isDaylightSaving`: Only applicable if selected timezone supports DST (`observesDST == true`)

### PowerTableState
- `country`: Must be one of `supportedCountries` if `isPowerTableSelectable == true`
- `isPowerTableSelectable`: Determines if UI shows transmit region option
