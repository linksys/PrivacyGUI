# Data Model: ConnectivityService Extraction

**Date**: 2026-01-02
**Feature**: 001-connectivity-service

## Entities

### 1. RouterType (Existing)

**Location**: `lib/providers/connectivity/connectivity_info.dart`
**Type**: Enum
**Status**: No changes required

```dart
enum RouterType {
  behind,        // Connected to a Linksys router (different from managed)
  behindManaged, // Connected to the managed Linksys router (same serial number)
  others,        // Not connected to a Linksys router
}
```

### 2. RouterConfiguredData (Existing)

**Location**: `lib/providers/connectivity/connectivity_provider.dart`
**Type**: Data Class
**Status**: No changes required

```dart
class RouterConfiguredData {
  const RouterConfiguredData({
    required this.isDefaultPassword,
    required this.isSetByUser,
  });

  final bool isDefaultPassword;  // true if admin password is factory default
  final bool isSetByUser;        // true if admin password was set by user
}
```

### 3. ConnectivityService (New)

**Location**: `lib/providers/connectivity/services/connectivity_service.dart`
**Type**: Service Class
**Status**: To be created

```dart
class ConnectivityService {
  ConnectivityService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Tests the type of router connection based on device info.
  ///
  /// Returns:
  /// - RouterType.behindManaged: Same serial number as stored
  /// - RouterType.behind: Different Linksys router
  /// - RouterType.others: Not a Linksys router or unreachable
  ///
  /// Throws: Never throws, returns RouterType.others on any error
  Future<RouterType> testRouterType(String? gatewayIp) async;

  /// Fetches router configuration status (password default/set by user).
  ///
  /// Returns: RouterConfiguredData with password configuration status
  /// Throws: [ServiceError] on JNAP failure
  Future<RouterConfiguredData> fetchRouterConfiguredData() async;
}
```

### 4. ConnectivityServiceProvider (New)

**Location**: `lib/providers/connectivity/services/connectivity_service.dart`
**Type**: Riverpod Provider
**Status**: To be created

```dart
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref.watch(routerRepositoryProvider));
});
```

## Relationships

```
┌─────────────────────────┐
│ ConnectivityNotifier    │ ──depends on──▶ ConnectivityService
│ (State Management)      │
└─────────────────────────┘
            │
            │ uses
            ▼
┌─────────────────────────┐
│ ConnectivityState       │
│ - hasInternet           │
│ - connectivityInfo      │ ──contains──▶ RouterType
│ - cloudAvailabilityInfo │
└─────────────────────────┘

┌─────────────────────────┐
│ ConnectivityService     │ ──depends on──▶ RouterRepository
│ (Business Logic)        │
└─────────────────────────┘
            │
            │ returns
            ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│ RouterType              │     │ RouterConfiguredData    │
│ (enum)                  │     │ (data class)            │
└─────────────────────────┘     └─────────────────────────┘
```

## State Transitions

### RouterType Detection Flow

```
┌─────────────────┐
│ Check Gateway   │
│ IP Available?   │
└────────┬────────┘
         │
    ┌────▼────┐     No
    │ IP null?├──────────▶ RouterType.others
    └────┬────┘
         │ Yes (has IP)
         ▼
┌─────────────────┐
│ Call JNAP       │
│ getDeviceInfo   │
└────────┬────────┘
         │
    ┌────▼────┐     Error/Empty
    │ Got SN? ├──────────▶ RouterType.others
    └────┬────┘
         │ Yes (has serial number)
         ▼
┌─────────────────┐
│ Compare with    │
│ Stored SN       │
└────────┬────────┘
         │
    ┌────▼────┐     No Match
    │ Match?  ├──────────▶ RouterType.behind
    └────┬────┘
         │ Match
         ▼
   RouterType.behindManaged
```

## Validation Rules

| Field | Rule | Enforced By |
|-------|------|-------------|
| `RouterConfiguredData.isDefaultPassword` | Boolean, always non-null | Service (JNAP provides default) |
| `RouterConfiguredData.isSetByUser` | Boolean, always non-null | Service (JNAP provides default) |
| `gatewayIp` | Can be null (no network) | Service handles gracefully |
