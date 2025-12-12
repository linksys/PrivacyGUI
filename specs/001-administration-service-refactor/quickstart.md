# Phase 1: Quick Start Guide

**Date**: 2024-12-03
**Purpose**: Quick reference for implementing AdministrationSettingsService extraction refactor

---

## Overview

Extract JNAP orchestration logic from `AdministrationSettingsNotifier` into `AdministrationSettingsService`.

**Branch**: `001-administration-service-refactor`

---

## Key Files to Create & Modify

### New Files

1. **`lib/page/advanced_settings/administration/services/administration_settings_service.dart`**
   - Main service class with `fetchAdministrationSettings()` method
   - ~75 LOC extracted from Notifier

2. **`test/page/advanced_settings/administration/services/administration_settings_service_test.dart`**
   - Unit tests for service with mocked RouterRepository
   - Target: ≥90% coverage, <100ms execution

### Modified Files

1. **`lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`**
   - Move JNAP imports to service
   - Simplify `performFetch()` to delegate to service
   - Remove ~75 lines of JNAP logic
   - Keep PreservableNotifierMixin and state management intact

2. **`test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart`**
   - Mock `AdministrationSettingsService` instead of RouterRepository directly
   - Update test setup to verify Notifier delegates correctly

### Unchanged Files

- `lib/page/advanced_settings/administration/providers/administration_settings_state.dart`
- `lib/page/advanced_settings/administration/views/*.dart`
- Any other administration-related files

---

## Step-by-Step Implementation

### Step 1: Create Service File

**File**: `lib/page/advanced_settings/administration/services/administration_settings_service.dart`

**Content structure**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/...dart';  // Import all 4 models
import 'package:privacy_gui/core/jnap/router_repository.dart';

class AdministrationSettingsService {
  /// Fetches all administration settings from the device.
  ///
  /// Orchestrates four JNAP actions in a single transaction.
  Future<AdministrationSettings> fetchAdministrationSettings(
    Ref ref, {
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    // Step 1: Get RouterRepository via Riverpod
    final repo = ref.read(routerRepositoryProvider);

    // Step 2: Build JNAP transaction with 4 actions
    final result = await repo.transaction(
      JNAPTransactionBuilder(commands: [
        const MapEntry(JNAPAction.getManagementSettings, {}),
        const MapEntry(JNAPAction.getUPnPSettings, {}),
        const MapEntry(JNAPAction.getALGSettings, {}),
        const MapEntry(JNAPAction.getExpressForwardingSettings, {}),
      ], auth: true),
      fetchRemote: forceRemote,
    );

    // Step 3: Parse results map
    final resultMap = Map.fromEntries(result.data);

    // Step 4: Extract each setting and create domain models
    final managementSettings = ...;  // Use .fromMap() constructor
    final upnpSettings = ...;
    final algSettings = ...;
    final expressSettings = ...;

    // Step 5: Return aggregate
    return AdministrationSettings(
      managementSettings: managementSettings,
      enabledALG: algSettings.enabled,
      isExpressForwardingSupported: expressSettings.isSupported,
      enabledExpressForwarfing: expressSettings.enabled,
      isUPnPEnabled: upnpSettings.enabled,
      canUsersConfigure: upnpSettings.canUsersConfigure,
      canUsersDisableWANAccess: upnpSettings.canUsersDisableWANAccess,
    );
  }
}
```

### Step 2: Extract Code from Notifier

**File**: `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`

**Changes**:
1. Remove JNAP action imports: `JNAPAction`, `JNAPTransaction`, `JNAPTransactionBuilder`
2. Remove model imports: `ManagementSettings`, `UPnPSettings`, `ALGSettings`, `ExpressForwardingSettings`
3. Add service import: `import './services/administration_settings_service.dart';`
4. Simplify `performFetch()`:

**Before**:
```dart
@override
Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({...}) async {
  final repo = ref.read(routerRepositoryProvider);
  final result = await repo.transaction(
    JNAPTransactionBuilder(commands: [
      // 4 MapEntry items
      ...
    ], auth: true),
    fetchRemote: forceRemote,
  );
  // ~150 lines of parsing logic
  ...
}
```

**After**:
```dart
@override
Future<(AdministrationSettings?, AdministrationStatus?)> performFetch({...}) async {
  final service = AdministrationSettingsService();
  final settings = await service.fetchAdministrationSettings(
    ref,
    forceRemote: forceRemote,
    updateStatusOnly: updateStatusOnly,
  );
  return (settings, null);
}
```

### Step 3: Create Service Unit Tests

**File**: `test/page/advanced_settings/administration/services/administration_settings_service_test.dart`

**Test cases**:
1. ✅ Successfully fetches all four settings and parses correctly
2. ✅ Handles ManagementSettings.fromMap() parsing
3. ✅ Handles UPnPSettings.fromMap() parsing
4. ✅ Handles ALGSettings.fromMap() parsing
5. ✅ Handles ExpressForwardingSettings.fromMap() parsing
6. ✅ Throws error if any JNAP action fails
7. ✅ Includes action context in error message

**Mocking strategy**:
```dart
// Mock RouterRepository
final mockRepo = MockRouterRepository();
when(mockRepo.transaction(...))
  .thenAnswer((_) async => JNAPResult.success(...));

// Create Riverpod container with override
final container = ProviderContainer(
  overrides: [
    routerRepositoryProvider.overrideWithValue(mockRepo),
  ],
);

// Test
final service = AdministrationSettingsService();
final settings = await service.fetchAdministrationSettings(container.ref);
```

### Step 4: Update Notifier Tests

**File**: `test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart`

**Changes**:
1. Mock `AdministrationSettingsService` instead of RouterRepository
2. Update provider override to use mocked service
3. Verify Notifier delegates to service correctly
4. Verify state updates from service results

**Example**:
```dart
when(mockService.fetchAdministrationSettings(...))
  .thenAnswer((_) async => mockSettings);

// Verify Notifier calls service and updates state
```

### Step 5: Run Tests & Lint

```bash
# Run all tests
flutter test

# Check lint compliance
flutter analyze

# Format code
dart format lib/page/advanced_settings/administration/ test/page/advanced_settings/administration/

# Check coverage (optional)
flutter test --coverage
```

---

## Validation Checklist

- [ ] Service file created with `fetchAdministrationSettings()` method
- [ ] All JNAP action imports moved to service
- [ ] All data model imports moved to service
- [ ] Notifier's `performFetch()` delegated to service (<75 LOC remaining)
- [ ] Service unit tests created (≥90% coverage)
- [ ] Notifier tests updated to mock service
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format` applied to all changed files
- [ ] Existing UI tests/screenshots still pass (no behavioral changes)
- [ ] Service is reusable (can be called from other components)

---

## Key Points

✅ **Don't**:
- Change the external API of AdministrationSettingsNotifier
- Modify state structure (AdministrationSettingsState)
- Add new error types (follow existing patterns)
- Skip tests

✅ **Do**:
- Keep service stateless
- Use existing `.fromMap()` constructors for models
- Mock thoroughly in tests
- Document with DartDoc

---

## Performance Targets

- Service instantiation: <50ms
- JNAP transaction: <100ms (network-dependent)
- Notifier.performFetch() total: <200ms (cold), <50ms (cached)

---

## References

- **Plan**: [plan.md](plan.md)
- **Research**: [research.md](research.md)
- **Data Model**: [data-model.md](data-model.md)
- **Spec**: [spec.md](spec.md)

---

## Next Steps

After implementing this quickstart:

1. **PR Review**: Submit PR against `dev-1.2.8` (or appropriate branch)
   - Include refactor changes + tests
   - Reference this feature branch in PR description

2. **Generate Tasks**: Run `/speckit.tasks` to create detailed task list

3. **Merge**: Merge to main branch after review and CI passes

---

**Implementation Status**: Ready to code
**Estimated Effort**: 1-2 days for experienced Flutter developer
**Risk Level**: Low (no behavioral changes, isolated refactor)
