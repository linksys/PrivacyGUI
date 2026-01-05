# Data Model: InstantPrivacyService

**Date**: 2026-01-02
**Branch**: `001-instant-privacy-service`

## Overview

This document defines the data model for the InstantPrivacyService extraction. Since this is a refactoring of existing code, most models already exist. This documents the data flow and transformations.

## Entity Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        JNAP Layer (Data)                            │
├─────────────────────────────────────────────────────────────────────┤
│  MACFilterSettings (JNAP Model)                                     │
│  ├── macFilterMode: String ("Disabled" | "Allow" | "Deny")          │
│  ├── maxMACAddresses: int                                           │
│  └── macAddresses: List<String>                                     │
│                                                                     │
│  GetLocalDevice Response                                            │
│  └── deviceID: String                                               │
│                                                                     │
│  GetSTABSSIDs Response                                              │
│  └── staBSSIDS: List<String>                                        │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ Service transforms
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Application Layer (UI Models)                   │
├─────────────────────────────────────────────────────────────────────┤
│  InstantPrivacySettings (existing - lib/page/.../providers/)        │
│  ├── mode: MacFilterMode (enum)                                     │
│  ├── macAddresses: List<String>                                     │
│  ├── denyMacAddresses: List<String>                                 │
│  ├── maxMacAddresses: int                                           │
│  ├── bssids: List<String>                                           │
│  └── myMac: String?                                                 │
│                                                                     │
│  InstantPrivacyStatus (existing)                                    │
│  └── mode: MacFilterMode                                            │
│                                                                     │
│  MacFilterMode (enum - existing)                                    │
│  ├── disabled                                                       │
│  ├── allow                                                          │
│  └── deny                                                           │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Transformations

### Fetch: JNAP → UI Model

```
MACFilterSettings.fromMap(jnapResponse)
        │
        ▼
┌───────────────────────────────────────┐
│ InstantPrivacyService.fetchSettings() │
│                                       │
│ 1. Parse macFilterMode → MacFilterMode│
│ 2. Split macAddresses by mode:        │
│    - Allow → macAddresses             │
│    - Deny → denyMacAddresses          │
│ 3. Fetch staBSSIDs (if supported)     │
│ 4. Fetch myMac via getLocalDevice     │
└───────────────────────────────────────┘
        │
        ▼
(InstantPrivacySettings, InstantPrivacyStatus)
```

### Save: UI Model → JNAP

```
InstantPrivacySettings (current state)
        │
        ▼
┌─────────────────────────────────────────────┐
│ InstantPrivacyService.saveMacFilterSettings │
│                                             │
│ 1. Determine macFilterMode from settings    │
│ 2. Merge addresses based on mode:           │
│    - Allow: macAddresses + nodesMacs + bssids│
│    - Deny: denyMacAddresses                 │
│ 3. Build JNAP payload                       │
└─────────────────────────────────────────────┘
        │
        ▼
JNAPAction.setMACFilterSettings({
  'macFilterMode': mode.name.capitalize(),
  'macAddresses': mergedAddresses
})
```

## Existing Models (No Changes)

### MacFilterMode (enum)

**File**: `lib/page/instant_privacy/providers/instant_privacy_state.dart`

```dart
enum MacFilterMode {
  disabled,
  allow,
  deny;

  static MacFilterMode resolve(String value);
  bool get isEnabled;
}
```

### InstantPrivacySettings

**File**: `lib/page/instant_privacy/providers/instant_privacy_state.dart`

| Field | Type | Description |
|-------|------|-------------|
| mode | MacFilterMode | Current filter mode |
| macAddresses | List\<String\> | Allowed MAC addresses |
| denyMacAddresses | List\<String\> | Denied MAC addresses |
| maxMacAddresses | int | Maximum allowed entries |
| bssids | List\<String\> | STA BSSIDs |
| myMac | String? | Current device MAC |

### InstantPrivacyStatus

**File**: `lib/page/instant_privacy/providers/instant_privacy_state.dart`

| Field | Type | Description |
|-------|------|-------------|
| mode | MacFilterMode | Current filter status |

## JNAP Model (Service Layer Only)

### MACFilterSettings

**File**: `lib/core/jnap/models/mac_filter_settings.dart`

| Field | Type | JNAP Key |
|-------|------|----------|
| macFilterMode | String | `macFilterMode` |
| maxMACAddresses | int | `maxMACAddresses` |
| macAddresses | List\<String\> | `macAddresses` |

**Note**: This model is imported ONLY in the Service layer, never in Provider or UI.

## Validation Rules

| Rule | Source | Applied In |
|------|--------|------------|
| MAC addresses uppercase | Existing behavior | Service |
| Remove duplicates (unique) | Existing behavior | Service |
| maxMacAddresses limit | Router constraint | Provider (UI validation) |

## State Transitions

```
┌──────────────┐    enable      ┌─────────────┐
│   Disabled   │ ──────────────▶│    Allow    │
└──────────────┘                └─────────────┘
       ▲                              │
       │       disable                │ setAccess(deny)
       │◀─────────────────────────────┤
       │                              ▼
       │                        ┌─────────────┐
       └────────────────────────│    Deny     │
              disable           └─────────────┘
```

All transitions handled by Provider via Service save operations.
