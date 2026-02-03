# Quickstart: DashboardHome Service Extraction

**Feature**: 006-dashboard-home-service-extraction
**Date**: 2025-12-29

---

## Overview

This guide provides step-by-step instructions for implementing the DashboardHomeService extraction refactoring.

---

## Prerequisites

- Branch: `006-dashboard-home-service-extraction`
- Flutter SDK installed
- Dependencies installed (`flutter pub get`)

---

## Implementation Steps

### Step 1: Create Service File

Create `lib/page/dashboard/services/dashboard_home_service.dart`:

```dart
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

final dashboardHomeServiceProvider = Provider<DashboardHomeService>((ref) {
  return const DashboardHomeService();
});

class DashboardHomeService {
  const DashboardHomeService();

  DashboardHomeState buildDashboardHomeState({
    required DashboardManagerState dashboardManagerState,
    required DeviceManagerState deviceManagerState,
    required String Function(LinksysDevice device) getBandForDevice,
    required List<LinksysDevice> deviceList,
  }) {
    // Implementation here - move logic from DashboardHomeNotifier.createState()
  }
}
```

### Step 2: Refactor Provider

Update `lib/page/dashboard/providers/dashboard_home_provider.dart`:

```dart
// REMOVE these imports:
// import 'package:privacy_gui/core/jnap/models/radio_info.dart';

// ADD service import:
import 'package:privacy_gui/page/dashboard/services/dashboard_home_service.dart';

class DashboardHomeNotifier extends Notifier<DashboardHomeState> {
  @override
  DashboardHomeState build() {
    final service = ref.read(dashboardHomeServiceProvider);
    final dashboardManagerState = ref.watch(dashboardManagerProvider);
    final deviceManagerState = ref.watch(deviceManagerProvider);

    return service.buildDashboardHomeState(
      dashboardManagerState: dashboardManagerState,
      deviceManagerState: deviceManagerState,
      getBandForDevice: (device) =>
          ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device),
      deviceList: ref.read(deviceManagerProvider).deviceList,
    );
  }
}
```

### Step 3: Refactor State File

Update `lib/page/dashboard/providers/dashboard_home_state.dart`:

```dart
// REMOVE these imports:
// import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
// import 'package:privacy_gui/core/jnap/models/radio_info.dart';

// REMOVE these factory methods from DashboardWiFiUIModel:
// factory DashboardWiFiUIModel.fromMainRadios(...)
// factory DashboardWiFiUIModel.fromGuestRadios(...)
```

### Step 4: Create Test Data Builder

Create `test/mocks/test_data/dashboard_home_test_data.dart`:

```dart
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

class DashboardHomeTestData {
  static DashboardManagerState createDashboardManagerState({
    // Parameters with defaults
  }) {
    // Return mock state
  }

  static DeviceManagerState createDeviceManagerState({
    // Parameters with defaults
  }) {
    // Return mock state
  }
}
```

### Step 5: Create Service Tests

Create `test/page/dashboard/services/dashboard_home_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/services/dashboard_home_service.dart';
import 'package:test/mocks/test_data/dashboard_home_test_data.dart';

void main() {
  late DashboardHomeService service;

  setUp(() {
    service = const DashboardHomeService();
  });

  group('DashboardHomeService - buildDashboardHomeState', () {
    test('returns correct state with main WiFi networks', () {
      // Test implementation
    });
  });
}
```

---

## Verification Commands

```bash
# Run tests
flutter test test/page/dashboard/

# Check architecture compliance
grep -r "import.*jnap/models" lib/page/dashboard/providers/
# Should return 0 results

# Run static analysis
flutter analyze lib/page/dashboard/
```

---

## File Checklist

| File | Action |
|------|--------|
| `lib/page/dashboard/services/dashboard_home_service.dart` | CREATE |
| `lib/page/dashboard/providers/dashboard_home_provider.dart` | MODIFY |
| `lib/page/dashboard/providers/dashboard_home_state.dart` | MODIFY |
| `test/page/dashboard/services/dashboard_home_service_test.dart` | CREATE |
| `test/mocks/test_data/dashboard_home_test_data.dart` | CREATE |

---

## Common Issues

### Issue: `getBandConnectedBy` not accessible

**Solution**: Pass as callback function to service method.

### Issue: Circular import

**Solution**: Ensure service only imports from `core/` and returns types from `providers/`.

### Issue: Test coverage below 90%

**Solution**: Add tests for edge cases (empty lists, null values, offline nodes).
