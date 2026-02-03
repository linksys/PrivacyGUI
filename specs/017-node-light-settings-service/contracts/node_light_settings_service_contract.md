# Service Contract: NodeLightSettingsService

**Feature**: 002-node-light-settings-service
**Date**: 2026-01-02

## Overview

Stateless service for LED night mode settings JNAP operations.

## Class Definition

```dart
/// Service for LED night mode settings operations.
///
/// Handles JNAP communication for retrieving and persisting
/// LED night mode configuration. Stateless - all state management
/// is delegated to NodeLightSettingsNotifier.
class NodeLightSettingsService {
  final RouterRepository _routerRepository;

  NodeLightSettingsService(this._routerRepository);
}
```

## Provider Definition

```dart
final nodeLightSettingsServiceProvider = Provider<NodeLightSettingsService>((ref) {
  return NodeLightSettingsService(ref.watch(routerRepositoryProvider));
});
```

## Method Contracts

### fetchSettings

```dart
/// Retrieves current LED night mode settings from router.
///
/// [forceRemote] - If true, bypasses cache and fetches from device.
///                 Default: false (may use cached data).
///
/// Returns: [NodeLightSettings] with current configuration.
///
/// Throws:
/// - [UnauthorizedError] if authentication fails
/// - [UnexpectedError] for other JNAP errors
///
/// Example:
/// ```dart
/// final settings = await service.fetchSettings();
/// print('Night mode: ${settings.isNightModeEnable}');
/// ```
Future<NodeLightSettings> fetchSettings({bool forceRemote = false})
```

### saveSettings

```dart
/// Persists LED night mode settings to router.
///
/// [settings] - The settings to save. All non-null fields are sent.
///
/// Returns: [NodeLightSettings] - Refreshed settings after save
///          (fetches from device to confirm).
///
/// Throws:
/// - [UnauthorizedError] if authentication fails
/// - [UnexpectedError] for other JNAP errors
///
/// Behavior:
/// - Sends Enable, StartingTime, EndingTime to router
/// - Automatically re-fetches after save to sync state
/// - Null fields are excluded from request
///
/// Example:
/// ```dart
/// final updated = await service.saveSettings(
///   NodeLightSettings.night(),
/// );
/// ```
Future<NodeLightSettings> saveSettings(NodeLightSettings settings)
```

## Error Mapping

```dart
/// Maps JNAP errors to ServiceError types.
ServiceError _mapJnapError(JNAPError error) {
  return switch (error.result) {
    '_ErrorUnauthorized' => const UnauthorizedError(),
    _ => UnexpectedError(originalError: error, message: error.result),
  };
}
```

## JNAP Actions

| Method | JNAP Action | Request Data | Response |
|--------|-------------|--------------|----------|
| fetchSettings | `getLedNightModeSetting` | None | `{Enable, StartingTime, EndingTime, AllDayOff}` |
| saveSettings | `setLedNightModeSetting` | `{Enable, StartingTime, EndingTime}` | OK/Error |

## Usage by Provider

```dart
class NodeLightSettingsNotifier extends Notifier<NodeLightSettings> {
  @override
  NodeLightSettings build() {
    return NodeLightSettings(isNightModeEnable: false);
  }

  Future<NodeLightSettings> fetch([bool forceRemote = false]) async {
    final service = ref.read(nodeLightSettingsServiceProvider);
    state = await service.fetchSettings(forceRemote: forceRemote);
    return state;
  }

  Future<NodeLightSettings> save() async {
    final service = ref.read(nodeLightSettingsServiceProvider);
    state = await service.saveSettings(state);
    return state;
  }

  void setSettings(NodeLightSettings settings) {
    state = settings;
  }

  /// UI transformation logic - stays in Provider
  NodeLightStatus get currentStatus {
    if ((state.allDayOff ?? false) ||
        (state.startHour == 0 && state.endHour == 24)) {
      return NodeLightStatus.off;
    } else if (!state.isNightModeEnable) {
      return NodeLightStatus.on;
    } else {
      return NodeLightStatus.night;
    }
  }
}
```

## Test Scenarios

### Model Tests (NodeLightSettings)

| Scenario | Input | Expected |
|----------|-------|----------|
| fromMap with all fields | `{Enable: true, StartingTime: 20, EndingTime: 8, AllDayOff: false}` | All fields populated correctly |
| fromMap with minimal fields | `{Enable: false}` | isNightModeEnable=false, others null |
| toMap excludes nulls | Settings with null startHour | Map has no 'StartingTime' key |
| toMap includes all non-null | Complete settings | All 4 keys present |
| factory on() | - | isNightModeEnable=false, no hours |
| factory off() | - | isNightModeEnable=true, 0-24 |
| factory night() | - | isNightModeEnable=true, 20-8 |
| fromStatus(on) | NodeLightStatus.on | Same as on() factory |
| fromStatus(off) | NodeLightStatus.off | Same as off() factory |
| fromStatus(night) | NodeLightStatus.night | Same as night() factory |
| copyWith partial | copyWith(startHour: 22) | Only startHour changed |
| equality | Two identical settings | props match, equals true |
| toJson/fromJson roundtrip | Complete settings | Identical after roundtrip |

### Service Tests

| Scenario | Input | Expected |
|----------|-------|----------|
| Fetch success | forceRemote: false | Returns NodeLightSettings from JNAP response |
| Fetch force remote | forceRemote: true | Bypasses cache, fetches from device |
| Fetch unauthorized | Invalid auth | Throws UnauthorizedError |
| Save success | NodeLightSettings.night() | Saves and returns refreshed settings |
| Save unauthorized | Invalid auth | Throws UnauthorizedError |
| Save null fields | Settings with nulls | Only non-null fields sent to JNAP |

### Provider Tests

| Scenario | Expected |
|----------|----------|
| fetch() delegates | Calls service.fetchSettings() and updates state |
| save() delegates | Calls service.saveSettings(state) and updates state |
| currentStatus on | Returns NodeLightStatus.on when !isNightModeEnable |
| currentStatus off | Returns NodeLightStatus.off when allDayOff or 0-24 |
| currentStatus night | Returns NodeLightStatus.night when enabled with schedule |
