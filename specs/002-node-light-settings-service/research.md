# Phase 0 Research: NodeLightSettings Service Extraction

**Feature**: 002-node-light-settings-service
**Date**: 2026-01-02
**Status**: Complete - No unknowns

## Research Summary

This is a straightforward service extraction following established patterns. No external research required.

## Existing Pattern Analysis

### Reference Implementation: DeviceManagerService

Located at `lib/core/jnap/services/device_manager_service.dart`:

```dart
final deviceManagerServiceProvider = Provider<DeviceManagerService>((ref) {
  return DeviceManagerService(ref.watch(routerRepositoryProvider));
});

class DeviceManagerService {
  final RouterRepository _routerRepository;

  DeviceManagerService(this._routerRepository);

  // Methods use _routerRepository.send() for JNAP communication
  // Errors are mapped via _mapJnapError()
}
```

### Target Provider Analysis

Current `NodeLightSettingsNotifier` at `lib/core/jnap/providers/node_light_settings_provider.dart`:

**JNAP Actions Used**:
- `JNAPAction.getLedNightModeSetting` - Fetches current LED night mode settings
- `JNAPAction.setLedNightModeSetting` - Saves LED night mode settings

**Current Methods**:
- `fetch([bool forceRemote = false])` - Retrieves settings from router
- `save()` - Persists current state to router
- `setSettings(NodeLightSettings settings)` - Updates local state
- `currentStatus` getter - Transforms settings to UI enum (stays in Provider)

### Data Model

`NodeLightSettings` at `lib/core/jnap/models/node_light_settings.dart`:
- `isNightModeEnable: bool` (required)
- `startHour: int?` (0-24)
- `endHour: int?` (0-24)
- `allDayOff: bool?`

`NodeLightStatus` enum at `lib/page/nodes/providers/node_detail_state.dart`:
- `on` - LED always on
- `off` - LED always off
- `night` - Night mode enabled with schedule

### ServiceError Pattern

From `lib/core/errors/service_error.dart`:

```dart
ServiceError _mapJnapError(JNAPError error) {
  return switch (error.result) {
    '_ErrorUnauthorized' => const UnauthorizedError(),
    // ... other mappings
    _ => UnexpectedError(originalError: error, message: error.result),
  };
}
```

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Service location | `lib/core/jnap/services/node_light_settings_service.dart` | Follows existing service convention |
| Provider pattern | Constructor injection via `Provider` | Matches DeviceManagerService pattern |
| Error mapping | Use existing ServiceError hierarchy | Consistency with other services |
| currentStatus getter | Keep in Provider | UI transformation logic belongs in Application layer |

## No External Research Needed

- No new APIs to investigate
- No third-party dependencies
- No architectural decisions to make
- Pattern is well-established in codebase

## Dependencies

- `RouterRepository` - For JNAP communication
- `ServiceError` - For error mapping
- `NodeLightSettings` - Existing data model (no changes needed)

## Risks

None identified. This is a refactoring task with no functional changes.
