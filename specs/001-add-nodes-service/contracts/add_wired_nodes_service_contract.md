# AddWiredNodesService Contract

**Feature**: 001-add-nodes-service (Scope Extension)
**Date**: 2026-01-07
**Location**: `lib/page/nodes/services/add_wired_nodes_service.dart`

## Provider Definition

```dart
/// Riverpod provider for AddWiredNodesService
final addWiredNodesServiceProvider = Provider<AddWiredNodesService>((ref) {
  return AddWiredNodesService(ref.watch(routerRepositoryProvider));
});
```

## Class Definition

```dart
/// Stateless service for Add Wired Nodes / Wired Auto-Onboarding operations
///
/// Encapsulates JNAP communication for wired node onboarding, separating
/// business logic from state management (AddWiredNodesNotifier).
///
/// Reference: constitution Article VI - Service Layer Principle
class AddWiredNodesService {
  /// Constructor injection of RouterRepository
  AddWiredNodesService(this._routerRepository);

  final RouterRepository _routerRepository;
}
```

---

## Method Contracts

### setAutoOnboardingEnabled

```dart
/// Enables or disables wired auto-onboarding on the router
///
/// Parameters:
///   - [enabled]: true to enable, false to disable
///
/// Throws:
///   - [NetworkError] if router communication fails
///   - [UnauthorizedError] if authentication expired
///   - [UnexpectedError] for other JNAP failures
Future<void> setAutoOnboardingEnabled(bool enabled) async
```

**JNAP Action**: `setWiredAutoOnboardingSettings`
**Auth**: Required (`auth: true`)
**Payload**: `{'isAutoOnboardingEnabled': enabled}`

---

### getAutoOnboardingEnabled

```dart
/// Fetches current wired auto-onboarding setting
///
/// Returns:
///   - `true` if auto-onboarding is enabled
///   - `false` if disabled or not configured
///
/// Throws:
///   - [NetworkError] if router communication fails
///   - [UnauthorizedError] if authentication expired
///   - [UnexpectedError] for other JNAP failures
Future<bool> getAutoOnboardingEnabled() async
```

**JNAP Action**: `getWiredAutoOnboardingSettings`
**Auth**: Required (`auth: true`)
**Output field**: `isAutoOnboardingEnabled`

---

### pollBackhaulChanges

```dart
/// Polls for backhaul changes compared to a snapshot
///
/// Detects new wired nodes by comparing current backhaul info against
/// the provided snapshot, using timestamp comparison to identify new entries.
///
/// Parameters:
///   - [snapshot]: Previous backhaul state to compare against
///   - [refreshing]: If true, uses shorter timeouts for refresh operations
///
/// Returns: Stream of [BackhaulPollResult] containing:
///   - [backhaulList]: Current backhaul entries as UI models
///   - [foundCounting]: Number of new nodes detected
///   - [anyOnboarded]: true if at least one new node was found
///
/// Polling Config:
///   - Normal: 1s first delay, 10s retry delay, 60 retries (~10 minutes)
///   - Refreshing: 1s first delay, 10s retry delay, 6 retries (~1 minute)
///
/// Stream completes when:
///   - Max retries exhausted (no early termination condition)
///
/// New node detection logic:
///   - Connection type is "Wired"
///   - Timestamp is after poll start time
///   - Timestamp is newer than snapshot timestamp for same UUID
Stream<BackhaulPollResult> pollBackhaulChanges(
  List<BackhaulInfoUIModel> snapshot, {
  bool refreshing = false,
})
```

**JNAP Action**: `getBackhaulInfo`
**Auth**: Required (`auth: true`)
**Output field**: `backhaulDevices`

---

### fetchNodes

```dart
/// Fetches all node devices from the router
///
/// Returns: List of [LinksysDevice] where nodeType != null
///
/// Throws:
///   - [NetworkError] if router communication fails
///   - [UnauthorizedError] if authentication expired
///   - [UnexpectedError] for other JNAP failures
///
/// Note: Returns empty list on error instead of throwing (matches existing behavior)
Future<List<LinksysDevice>> fetchNodes() async
```

**JNAP Action**: `getDevices`
**Auth**: Required (`auth: true`)
**Fetch Mode**: `fetchRemote: true`
**Output field**: `devices`

---

## Supporting Models

### BackhaulInfoUIModel

```dart
/// UI-friendly representation of backhaul information
///
/// Replaces BackHaulInfoData (JNAP model) in State/Provider layers
class BackhaulInfoUIModel extends Equatable {
  final String deviceUUID;
  final String connectionType;
  final String timestamp;

  const BackhaulInfoUIModel({
    required this.deviceUUID,
    required this.connectionType,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [deviceUUID, connectionType, timestamp];

  Map<String, dynamic> toMap();
  factory BackhaulInfoUIModel.fromMap(Map<String, dynamic> map);
  String toJson();
  factory BackhaulInfoUIModel.fromJson(String source);
}
```

**Location**: `lib/page/nodes/models/backhaul_info_ui_model.dart`

---

### BackhaulPollResult

```dart
/// Result container for pollBackhaulChanges stream emissions
class BackhaulPollResult {
  final List<BackhaulInfoUIModel> backhaulList;
  final int foundCounting;
  final bool anyOnboarded;

  const BackhaulPollResult({
    required this.backhaulList,
    required this.foundCounting,
    required this.anyOnboarded,
  });
}
```

**Location**: `lib/page/nodes/services/add_wired_nodes_service.dart` (inline)

---

## Error Handling Contract

All methods follow constitution Article XIII error mapping:

```dart
// Pattern for all methods
try {
  // JNAP operation
} on JNAPError catch (e) {
  throw mapJnapErrorToServiceError(e);
}
```

| JNAPError Pattern | ServiceError |
|-------------------|--------------|
| Network/timeout | `NetworkError` |
| `_ErrorUnauthorized` | `UnauthorizedError` |
| Other | `UnexpectedError(originalError: e)` |

---

## Usage Example

```dart
// In AddWiredNodesNotifier
class AddWiredNodesNotifier extends AutoDisposeNotifier<AddWiredNodesState> {
  AddWiredNodesService get _service => ref.read(addWiredNodesServiceProvider);

  Future<void> startAutoOnboarding(BuildContext context) async {
    try {
      // Enable wired auto-onboarding
      await _service.setAutoOnboardingEnabled(true);

      // Get current backhaul as snapshot
      final backhaulList = await _getInitialBackhaulSnapshot();
      state = state.copyWith(backhaulSnapshot: backhaulList);

      // Poll for backhaul changes
      await for (final result in _service.pollBackhaulChanges(backhaulList)) {
        if (result.foundCounting > 0) {
          state = state.copyWith(
            loadingMessage: loc(context).foundNNodesOnline(result.foundCounting),
            anyOnboarded: true,
          );
        }
      }

      // Disable auto-onboarding and fetch final node list
      await _service.setAutoOnboardingEnabled(false);
      final nodes = await _service.fetchNodes();
      state = state.copyWith(nodes: nodes);

    } on ServiceError catch (e) {
      // Handle service errors
      logger.e('Wired onboarding error: $e');
    }
  }
}
```

---

## Testing Contract

Service tests MUST mock RouterRepository and verify:

1. **setAutoOnboardingEnabled**: Calls correct JNAP action with enabled flag
2. **getAutoOnboardingEnabled**: Returns boolean from JNAP output
3. **pollBackhaulChanges**:
   - Transforms JNAPResult to BackhaulPollResult
   - Correctly calculates foundCounting using timestamp comparison
   - Handles snapshot comparison logic
4. **fetchNodes**: Transforms devices, filters by nodeType
5. **Error mapping**: JNAPError → ServiceError for each method

### Test Data Builder

```dart
class AddWiredNodesTestData {
  /// Create getWiredAutoOnboardingSettings success response
  static JNAPSuccess createWiredAutoOnboardingSettingsSuccess({
    bool isEnabled = false,
  });

  /// Create getBackhaulInfo success response
  static JNAPSuccess createBackhaulInfoSuccess({
    List<Map<String, dynamic>>? devices,
  });

  /// Create getDevices success response
  static JNAPSuccess createDevicesSuccess({
    List<Map<String, dynamic>>? devices,
  });

  /// Create JNAP error response
  static JNAPError createJNAPError({
    String result = 'ErrorUnknown',
  });
}
```

**Location**: `test/mocks/test_data/add_wired_nodes_test_data.dart`
