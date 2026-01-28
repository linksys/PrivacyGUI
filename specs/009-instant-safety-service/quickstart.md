# Quickstart: InstantSafety Service Extraction

**Feature**: 004-instant-safety-service
**Date**: 2025-12-22

## Overview

This guide provides step-by-step instructions for implementing the InstantSafety service extraction. Follow these steps in order.

---

## Prerequisites

- [x] Feature branch: `004-instant-safety-service`
- [x] Read specification: [spec.md](./spec.md)
- [x] Read contracts: [contracts/instant_safety_service_contract.md](./contracts/instant_safety_service_contract.md)
- [x] Understand reference: `lib/page/instant_admin/services/router_password_service.dart`

---

## Implementation Steps

### Step 1: Create Service File

**File**: `lib/page/instant_safety/services/instant_safety_service.dart`

```bash
mkdir -p lib/page/instant_safety/services
```

Create service with:
- Provider definition
- Constructor with RouterRepository injection
- `fetchSettings()` method
- `saveSettings()` method
- Private helpers for DNS detection and Fortinet compatibility
- DNS configuration constants

Reference: [Service Contract](./contracts/instant_safety_service_contract.md)

---

### Step 2: Create Test Data Builder

**File**: `test/mocks/test_data/instant_safety_test_data.dart`

Create class with factory methods for:
- `createLANSettingsSuccess()` - Default successful LAN settings response
- `createLANSettingsWithFortinet()` - LAN settings with Fortinet DNS
- `createLANSettingsWithOpenDNS()` - LAN settings with OpenDNS
- `createDeviceInfo()` - Device info for compatibility testing

---

### Step 3: Create Service Tests

**File**: `test/page/instant_safety/services/instant_safety_service_test.dart`

Test groups:
1. `fetchSettings` - DNS detection, Fortinet compatibility, error handling
2. `saveSettings` - DNS construction for each type, error handling

Target coverage: ≥90%

---

### Step 4: Modify State Class

**File**: `lib/page/instant_safety/providers/instant_safety_state.dart`

Changes:
1. Remove `import 'package:privacy_gui/core/jnap/models/lan_settings.dart';`
2. Remove `RouterLANSettings? lanSetting` from `InstantSafetyStatus`
3. Update `copyWith`, `props`, `toMap`, `fromMap` methods

---

### Step 5: Create State Tests

**File**: `test/page/instant_safety/providers/instant_safety_state_test.dart`

Test:
- `InstantSafetySettings` - copyWith, equality, serialization
- `InstantSafetyStatus` - copyWith, equality, serialization
- `InstantSafetyState` - initial factory, copyWith, serialization

---

### Step 6: Modify Provider

**File**: `lib/page/instant_safety/providers/instant_safety_provider.dart`

Changes:
1. Remove JNAP imports:
   - `core/jnap/actions/better_action.dart`
   - `core/jnap/command/base_command.dart`
   - `core/jnap/models/device_info.dart`
   - `core/jnap/models/lan_settings.dart`
   - `core/jnap/models/set_lan_settings.dart`
   - `core/jnap/result/jnap_result.dart`
   - `core/jnap/router_repository.dart`
2. Add service import
3. Add `core/errors/service_error.dart` import
4. Update `performFetch()` to delegate to service
5. Update `performSave()` to delegate to service
6. Remove private helper methods (moved to service)
7. Remove `DhcpOption`, `CompatibilityItem`, `CompatibilityFW` classes
8. Remove `SafeBrowsingError` class
9. Remove DNS constant definitions

---

### Step 7: Create Provider Tests

**File**: `test/page/instant_safety/providers/instant_safety_provider_test.dart`

Test groups:
1. `build` - Initial state, fetch trigger
2. `performFetch` - Service delegation, state update
3. `performSave` - Service delegation, error handling
4. `setSafeBrowsingEnabled` - State toggle logic
5. `setSafeBrowsingProvider` - Provider selection

Target coverage: ≥85%

---

### Step 8: Verify Architecture Compliance

Run compliance checks:

```bash
# Provider should NOT import JNAP models
grep -r "import.*jnap/models" lib/page/instant_safety/providers/
# Expected: 0 results

# Provider should NOT import JNAP result
grep -r "import.*jnap/result" lib/page/instant_safety/providers/
# Expected: 0 results

# Service SHOULD import JNAP models
grep -r "import.*jnap/models" lib/page/instant_safety/services/
# Expected: Results found

# Service SHOULD import ServiceError
grep -r "import.*core/errors/service_error" lib/page/instant_safety/services/
# Expected: Results found
```

---

### Step 9: Run Tests

```bash
# Run all instant_safety tests
flutter test test/page/instant_safety/

# Run with coverage
flutter test --coverage test/page/instant_safety/

# Check specific coverage
lcov --list coverage/lcov.info | grep instant_safety
```

---

### Step 10: Final Checks

```bash
# Static analysis
flutter analyze lib/page/instant_safety/

# Format check
dart format --set-exit-if-changed lib/page/instant_safety/
```

---

## File Checklist

### Create
- [ ] `lib/page/instant_safety/services/instant_safety_service.dart`
- [ ] `test/page/instant_safety/services/instant_safety_service_test.dart`
- [ ] `test/page/instant_safety/providers/instant_safety_provider_test.dart`
- [ ] `test/page/instant_safety/providers/instant_safety_state_test.dart`
- [ ] `test/mocks/test_data/instant_safety_test_data.dart`

### Modify
- [ ] `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [ ] `lib/page/instant_safety/providers/instant_safety_state.dart`

### No Changes
- [ ] `lib/page/instant_safety/views/` - UI unchanged

---

## Common Pitfalls

1. **Forgetting to cache LAN settings** - Service needs to store fetched settings for save operation
2. **JNAPSideEffectError handling** - Must rethrow this error type for UI handling
3. **Polling provider access** - Provider passes device info to service, service doesn't access polling directly
4. **Test isolation** - Mock RouterRepository for service tests, mock Service for provider tests
