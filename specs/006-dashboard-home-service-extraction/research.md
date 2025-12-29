# Research: DashboardHome Service Extraction

**Feature**: 006-dashboard-home-service-extraction
**Date**: 2025-12-29

## Research Summary

This is a straightforward refactoring task with no unknowns requiring deep research. All patterns are already established in the codebase.

---

## Decision 1: Service Pattern for Pure Transformation

**Decision**: Use stateless service class with pure transformation methods (no RouterRepository dependency)

**Rationale**:
- `DashboardHomeNotifier` does NOT call JNAP directly
- It transforms data from other providers (`dashboardManagerProvider`, `deviceManagerProvider`)
- The service only needs to perform data transformation, not API calls
- This differs from services like `RouterPasswordService` which interact with `RouterRepository`

**Alternatives Considered**:
| Alternative | Rejected Because |
|------------|------------------|
| Service with RouterRepository injection | Unnecessary - no JNAP calls needed |
| Static utility class | Less testable, doesn't follow project patterns |
| Extension methods on state classes | Doesn't isolate JNAP model dependencies |

---

## Decision 2: Handling `getBandConnectedBy` Dependency

**Decision**: Pass band information as a callback function to the service method

**Rationale**:
- Current code calls `ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device)`
- Service layer cannot access Riverpod `ref` directly (violates stateless principle)
- Callback pattern keeps service pure and testable

**Implementation Pattern**:
```dart
// Service signature
DashboardHomeState buildState({
  required DashboardManagerState dashboardState,
  required DeviceManagerState deviceState,
  required String Function(LinksysDevice) getBandForDevice,
  required List<LinksysDevice> deviceList,
});

// Provider usage
final state = service.buildState(
  dashboardState: dashboardManagerState,
  deviceState: deviceManagerState,
  getBandForDevice: (device) => ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device),
  deviceList: ref.read(deviceManagerProvider).deviceList,
);
```

**Alternatives Considered**:
| Alternative | Rejected Because |
|------------|------------------|
| Pass Ref to service | Violates stateless principle, tight coupling |
| Pre-compute all bands in provider | Complex, duplicates logic |
| Inject DeviceManagerNotifier | Creates circular dependency risk |

---

## Decision 3: Factory Method Relocation

**Decision**: Remove `DashboardWiFiUIModel.fromMainRadios()` and `fromGuestRadios()` factories, replace with private service methods

**Rationale**:
- Factory methods on UI model classes create JNAP model dependencies
- Moving logic to service isolates the dependency
- Private methods prevent external misuse

**Implementation Pattern**:
```dart
// In DashboardHomeService
DashboardWiFiUIModel _buildMainWiFiItem(List<RouterRadio> radios, int connectedDevices) {
  final radio = radios.first;
  return DashboardWiFiUIModel(
    ssid: radio.settings.ssid,
    password: radio.settings.wpaPersonalSettings?.passphrase ?? '',
    radios: radios.map((e) => e.radioID).toList(),
    isGuest: false,
    isEnabled: radio.settings.isEnabled,
    numOfConnectedDevices: connectedDevices,
  );
}
```

---

## Decision 4: Test Data Builder Location

**Decision**: Create `test/mocks/test_data/dashboard_home_test_data.dart`

**Rationale**:
- Follows constitution Article I Section 1.6.2
- Provides reusable mock data for DashboardManagerState, DeviceManagerState
- Centralizes test data creation

---

## Reference Implementations

| Pattern | Reference File | Relevance |
|---------|---------------|-----------|
| Service with Provider injection | `lib/page/instant_admin/services/router_password_service.dart` | Service provider pattern |
| Transformation service | `lib/page/dashboard/services/dashboard_manager_service.dart` | Similar transformation logic |
| Test data builder | `test/mocks/test_data/` | Test data organization |

---

## No Further Research Needed

All technical decisions are resolved. Proceed to Phase 1 design.
