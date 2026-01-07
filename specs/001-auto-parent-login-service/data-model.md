# Data Model: AutoParentFirstLogin Service Extraction

**Date**: 2026-01-07
**Feature**: 001-auto-parent-login-service

## Overview

This refactoring does not introduce new data models. The existing JNAP models remain in the Data layer, and the State class remains unchanged.

---

## Existing Entities (No Changes)

### AutoParentFirstLoginState

**Location**: `lib/page/login/auto_parent/providers/auto_parent_first_login_state.dart`

```dart
class AutoParentFirstLoginState extends Equatable {
  @override
  List<Object?> get props => [];
}
```

**Notes**:
- Minimal state class with no fields
- No UI Model needed per constitution.md Article V Section 5.3.4 (flat, basic types)
- Remains unchanged by this refactoring

---

### FirmwareUpdateSettings (JNAP Model)

**Location**: `lib/core/jnap/models/firmware_update_settings.dart`

**Used By**: Service layer ONLY (after refactoring)

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `updatePolicy` | `String` | Policy value (e.g., `firmwareUpdatePolicyAuto`) |
| `autoUpdateWindow` | `FirmwareAutoUpdateWindow` | Time window for auto updates |

**Notes**:
- This JNAP model is currently imported by Provider (violation)
- After refactoring: imported ONLY by Service
- Provider will never see this model

---

### FirmwareAutoUpdateWindow (JNAP Model)

**Location**: `lib/core/jnap/models/firmware_update_settings.dart`

**Key Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `startMinute` | `int` | Start time in minutes from midnight |
| `durationMinutes` | `int` | Window duration in minutes |

**Notes**:
- Nested within FirmwareUpdateSettings
- Default values: `startMinute: 0`, `durationMinutes: 240` (4 hours)

---

## New Entities

### AutoParentFirstLoginService (NEW)

**Location**: `lib/page/login/auto_parent/services/auto_parent_first_login_service.dart`

**Type**: Stateless Service class

**Dependencies**:
- `RouterRepository` (injected via constructor)

**Not a Data Model**: This is a service class, not a data entity. It has no persistent state or serialization requirements.

---

## Model Layer Compliance

| Layer | Models Used | Status |
|-------|-------------|--------|
| **Presentation** | N/A (no UI model needed) | ✅ |
| **Provider** | `AutoParentFirstLoginState` | ✅ No JNAP models |
| **Service** | `FirmwareUpdateSettings`, `FirmwareAutoUpdateWindow` | ✅ Correct layer |
| **Data/JNAP** | Raw JNAP responses | ✅ |

---

## JNAP Actions Data Shapes

### JNAPAction.getInternetConnectionStatus

**Response**:
```json
{
  "connectionStatus": "InternetConnected" | "InternetDisconnected" | ...
}
```

### JNAPAction.getFirmwareUpdateSettings

**Response**:
```json
{
  "updatePolicy": "AutoUpdate" | "Manual" | ...,
  "autoUpdateWindow": {
    "startMinute": 0,
    "durationMinutes": 240
  }
}
```

### JNAPAction.setFirmwareUpdateSettings

**Request**:
```json
{
  "updatePolicy": "AutoUpdate",
  "autoUpdateWindow": {
    "startMinute": 0,
    "durationMinutes": 240
  }
}
```

### JNAPAction.setUserAcknowledgedAutoConfiguration

**Request**:
```json
{}
```
**Response**: Empty success or error

---

## UI Model Decision

Per constitution.md Article V Section 5.3.4:

**Analysis**:
- ❌ Not a collection/list
- ❌ Not reused across multiple places
- ❌ Not complex (State has zero fields)
- ❌ No computed properties needed

**Decision**: No UI Model required. `AutoParentFirstLoginState` directly holds state (currently empty, may expand in future).
