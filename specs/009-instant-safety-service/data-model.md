# Data Model: InstantSafety Service Extraction

**Feature**: 004-instant-safety-service
**Date**: 2025-12-22

## Entity Overview

This refactoring affects data flow between layers but creates no new UI models (per constitution Section 5.3.4 - flat basic types don't require separate UI models).

```
┌─────────────────────────────────────┐
│  Provider Layer                     │
│  InstantSafetyNotifier              │
│  - Uses: InstantSafetyState         │
│  - Catches: ServiceError only       │
└──────────────┬──────────────────────┘
               │ delegates to
┌──────────────▼──────────────────────┐
│  Service Layer                      │
│  InstantSafetyService               │
│  - Uses: RouterLANSettings (JNAP)   │
│  - Throws: ServiceError             │
│  - Returns: FetchResult, void       │
└──────────────┬──────────────────────┘
               │ communicates via
┌──────────────▼──────────────────────┐
│  Data Layer                         │
│  RouterRepository                   │
│  - getLANSettings                   │
│  - setLANSettings                   │
└─────────────────────────────────────┘
```

---

## Existing Entities (No Changes)

### InstantSafetyType (Enum)
**Location**: `lib/page/instant_safety/providers/instant_safety_state.dart`
**Purpose**: Represents safe browsing provider selection

```dart
enum InstantSafetyType {
  off,
  fortinet,
  openDNS,
}
```

### InstantSafetySettings (Preservable Settings)
**Location**: `lib/page/instant_safety/providers/instant_safety_state.dart`
**Purpose**: User-modifiable settings tracked by PreservableNotifierMixin

| Field | Type | Description |
|-------|------|-------------|
| safeBrowsingType | InstantSafetyType | Selected safe browsing provider |

**Validation**: None required (enum constraint)

---

## Modified Entities

### InstantSafetyStatus (BEFORE)
**Current State**: Contains JNAP model dependency

```dart
class InstantSafetyStatus extends Equatable {
  final RouterLANSettings? lanSetting;  // ❌ JNAP model
  final bool hasFortinet;
}
```

### InstantSafetyStatus (AFTER)
**Target State**: Clean of JNAP dependencies

```dart
class InstantSafetyStatus extends Equatable {
  final bool hasFortinet;
  // RouterLANSettings moved to service layer cache
}
```

| Field | Type | Description |
|-------|------|-------------|
| hasFortinet | bool | Whether device supports Fortinet safe browsing |

**Validation**: None required (boolean)
**State Transitions**: Set during fetch, read-only thereafter

---

## New Internal Entities (Service Layer Only)

### InstantSafetyFetchResult
**Location**: `lib/page/instant_safety/services/instant_safety_service.dart`
**Purpose**: Return type for service fetch operation

```dart
/// Result of fetching instant safety settings
class InstantSafetyFetchResult {
  final InstantSafetyType safeBrowsingType;
  final bool hasFortinet;

  const InstantSafetyFetchResult({
    required this.safeBrowsingType,
    required this.hasFortinet,
  });
}
```

| Field | Type | Description |
|-------|------|-------------|
| safeBrowsingType | InstantSafetyType | Current safe browsing type from DNS config |
| hasFortinet | bool | Device compatibility for Fortinet |

**Note**: This is a simple tuple-like class internal to the service. Could alternatively use Dart record `(InstantSafetyType, bool)` but named class improves readability.

---

## Service Internal State

### Cached LAN Settings
**Location**: `InstantSafetyService` instance field
**Purpose**: Cache LAN settings for save operation

```dart
class InstantSafetyService {
  RouterLANSettings? _cachedLanSettings;

  // Set during fetchSettings()
  // Used during saveSettings()
}
```

**Lifecycle**:
1. `null` at service creation
2. Populated by `fetchSettings()`
3. Read by `saveSettings()` to construct update payload
4. Cleared/refreshed on next `fetchSettings()`

---

## JNAP Data Models (Reference Only - No Changes)

These models exist in Data Layer and are used only by the Service:

### RouterLANSettings
**Location**: `lib/core/jnap/models/lan_settings.dart`

Key fields used by InstantSafetyService:
- `dhcpSettings.dnsServer1` - Primary DNS (used to detect provider)
- `dhcpSettings.dnsServer2` - Secondary DNS
- `dhcpSettings.dnsServer3` - Tertiary DNS
- `ipAddress`, `networkPrefixLength`, `hostName`, `isDHCPEnabled` - Preserved during save

### SetRouterLANSettings
**Location**: `lib/core/jnap/models/set_lan_settings.dart`

Used to construct setLANSettings payload with modified DNS values.

---

## Data Flow Diagrams

### Fetch Flow
```
User opens InstantSafety page
         │
         ▼
InstantSafetyNotifier.build()
         │ calls
         ▼
InstantSafetyService.fetchSettings(deviceInfo)
         │ sends
         ▼
RouterRepository.send(getLANSettings)
         │ returns
         ▼
RouterLANSettings (JNAP model)
         │ service transforms
         ▼
InstantSafetyFetchResult {
  safeBrowsingType: (from DNS detection),
  hasFortinet: (from device compatibility)
}
         │ provider updates state
         ▼
InstantSafetyState {
  settings: Preservable(InstantSafetySettings),
  status: InstantSafetyStatus(hasFortinet: true/false)
}
```

### Save Flow
```
User taps Save
         │
         ▼
InstantSafetyNotifier.performSave()
         │ calls
         ▼
InstantSafetyService.saveSettings(safeBrowsingType)
         │ uses cached LAN settings + new type
         │ constructs SetRouterLANSettings with updated DNS
         ▼
RouterRepository.send(setLANSettings)
         │ success/failure
         ▼
void / throws ServiceError
```

---

## Removed Entities

### SafeBrowsingError (Custom Error Class)
**Current Location**: `instant_safety_provider.dart` line 237-243
**Action**: DELETE - Replace with ServiceError types

```dart
// ❌ REMOVE
class SafeBrowsingError extends Error {
  final String? message;
  SafeBrowsingError({this.message = 'Unknown error'});
}
```

**Replacement**: Use `UnexpectedError` or `InvalidInputError` from `service_error.dart`

### DhcpOption, CompatibilityItem, CompatibilityFW
**Current Location**: `instant_safety_provider.dart` lines 203-235
**Action**: MOVE to `instant_safety_service.dart` - These are implementation details for DNS configuration

---

## Entity Relationship Summary

```
┌─────────────────────────────────┐
│    InstantSafetyState           │
│  (FeatureState<Settings,Status>)│
├─────────────────────────────────┤
│ settings: Preservable<          │
│   InstantSafetySettings>        │──────┐
│ status: InstantSafetyStatus     │──┐   │
└─────────────────────────────────┘  │   │
                                     │   │
     ┌───────────────────────────────┘   │
     │                                   │
     ▼                                   ▼
┌─────────────────────┐    ┌─────────────────────────┐
│ InstantSafetyStatus │    │ InstantSafetySettings   │
├─────────────────────┤    ├─────────────────────────┤
│ hasFortinet: bool   │    │ safeBrowsingType: Enum  │
└─────────────────────┘    └─────────────────────────┘
```
