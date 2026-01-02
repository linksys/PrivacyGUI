# Data Model: NodeLightSettings Service Extraction

**Feature**: 002-node-light-settings-service
**Date**: 2026-01-02

## Overview

This refactoring uses existing data models without modification. The service extraction only changes where JNAP communication occurs, not the data structures.

## Existing Entities (No Changes)

### NodeLightSettings

**Location**: `lib/core/jnap/models/node_light_settings.dart`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| isNightModeEnable | bool | Yes | Whether night mode scheduling is enabled |
| startHour | int? | No | Hour when LED turns off (0-24) |
| endHour | int? | No | Hour when LED turns back on (0-24) |
| allDayOff | bool? | No | Whether LED is off all day |

**Factory Constructors**:
- `NodeLightSettings.on()` - LED always on (isNightModeEnable: false)
- `NodeLightSettings.off()` - LED always off (isNightModeEnable: true, 0-24)
- `NodeLightSettings.night()` - Night mode (isNightModeEnable: true, 20-8)
- `NodeLightSettings.fromStatus(NodeLightStatus)` - Create from UI enum

**JSON Mapping**:
```json
{
  "Enable": true,
  "StartingTime": 20,
  "EndingTime": 8,
  "AllDayOff": false
}
```

### NodeLightStatus (UI Enum)

**Location**: `lib/page/nodes/providers/node_detail_state.dart`

| Value | Description | Derived When |
|-------|-------------|--------------|
| `on` | LED always on | isNightModeEnable == false |
| `off` | LED always off | allDayOff == true OR (startHour == 0 && endHour == 24) |
| `night` | Night mode active | isNightModeEnable == true with partial schedule |

**Note**: The `currentStatus` getter deriving this enum stays in the Provider layer as it's UI transformation logic.

## New Entities

### NodeLightSettingsService

**Location**: `lib/core/jnap/services/node_light_settings_service.dart`

A stateless service class for LED night mode JNAP operations.

| Property | Type | Description |
|----------|------|-------------|
| _routerRepository | RouterRepository | Injected JNAP communication layer |

| Method | Signature | Description |
|--------|-----------|-------------|
| fetchSettings | `Future<NodeLightSettings> fetchSettings({bool forceRemote = false})` | Retrieve current LED settings |
| saveSettings | `Future<NodeLightSettings> saveSettings(NodeLightSettings settings)` | Persist LED settings, returns refreshed state |

## JNAP Action Mapping

| JNAP Action | Service Method | Input | Output |
|-------------|----------------|-------|--------|
| `getLedNightModeSetting` | `fetchSettings()` | forceRemote flag | NodeLightSettings |
| `setLedNightModeSetting` | `saveSettings()` | Enable, StartingTime, EndingTime | NodeLightSettings (after re-fetch) |

## Error Mapping

| JNAP Error | ServiceError |
|------------|--------------|
| `_ErrorUnauthorized` | `UnauthorizedError` |
| Other errors | `UnexpectedError` |

## Data Flow

```
┌─────────────────┐     ┌─────────────────────────┐     ┌──────────────────┐
│ View/UI Widget  │     │ NodeLightSettingsNotifier│     │ NodeLightSettings│
│                 │────▶│ (Provider)               │────▶│ Service          │
│                 │     │                          │     │                  │
│ Uses:           │     │ Delegates to Service     │     │ Handles JNAP     │
│ - state         │     │ Manages state            │     │ Maps errors      │
│ - currentStatus │     │ currentStatus getter     │     │                  │
└─────────────────┘     └─────────────────────────┘     └──────────────────┘
                                    │                            │
                                    │                            ▼
                                    │                    ┌──────────────────┐
                                    │                    │ RouterRepository │
                                    │                    │                  │
                                    │                    │ JNAP Protocol    │
                                    └───────────────────▶│ Communication    │
                                      State updates      └──────────────────┘
```

## Migration Notes

1. **No model changes** - NodeLightSettings class remains unchanged
2. **Provider simplification** - Remove JNAP imports, delegate to service
3. **State management** - Provider continues to own state, service is stateless
4. **currentStatus** - Remains in Provider as UI transformation logic
