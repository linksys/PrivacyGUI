# Research: ConnectivityService Extraction

**Date**: 2026-01-02
**Feature**: 001-connectivity-service

## Overview

This research documents the technical decisions for extracting `ConnectivityService` from `ConnectivityNotifier`.

## Research Tasks

### 1. Service Layer Pattern in This Codebase

**Decision**: Follow existing service implementation patterns

**Rationale**:
- Multiple reference implementations exist: `RouterPasswordService`, `HealthCheckService`, `DMZService`
- All use constructor injection with `RouterRepository`
- All use `mapJnapErrorToServiceError()` for error mapping
- Services are stateless and provided via `Provider<T>`

**Reference Implementation**: `lib/page/instant_admin/services/router_password_service.dart`

### 2. Error Handling Approach

**Decision**: Use `mapJnapErrorToServiceError()` from `lib/core/errors/jnap_error_mapper.dart`

**Rationale**:
- Centralized error mapping already exists
- `ConnectivityError` already defined in `service_error.dart` for router connectivity issues
- Consistent with Article XIII of constitution.md

**Alternatives Considered**:
- Custom error mapping in service → Rejected (violates DRY, inconsistent with other services)

### 3. RouterConfiguredData Location

**Decision**: Keep `RouterConfiguredData` in `connectivity_provider.dart` initially, can be moved to models later if needed

**Rationale**:
- It's a simple data class with two boolean fields
- Only used by `ConnectivityNotifier` and `ConnectivityService`
- Moving to separate file adds complexity without benefit for this scope

**Alternatives Considered**:
- Create `lib/providers/connectivity/models/router_configured_data.dart` → Deferred (can be done later if reuse emerges)

### 4. SharedPreferences Dependency

**Decision**: Pass `SharedPreferences` instance to service method, not constructor

**Rationale**:
- `SharedPreferences.getInstance()` is async
- Other services (e.g., `RouterPasswordService`) inject `FlutterSecureStorage` via constructor
- For `SharedPreferences`, passing to method is simpler since it's only used in one place

**Alternative Approaches**:
- Inject via constructor with async initialization → More complex, not needed for single use case
- Use `SharedPreferencesAsync` provider → Over-engineering for this scope

### 5. Service Location

**Decision**: `lib/providers/connectivity/services/connectivity_service.dart`

**Rationale**:
- `ConnectivityProvider` is in `lib/providers/` not `lib/page/`
- Following the relative pattern: `[parent]/services/[name]_service.dart`
- Keeps related files together

## Existing Code Analysis

### Current `_testRouterType()` Logic (lines 79-111)

```dart
Future<RouterType> _testRouterType(String? newIp) async {
  final routerRepository = ref.read(routerRepositoryProvider);
  final routerSN = await routerRepository
      .send(JNAPAction.getDeviceInfo, ...)
      .then((value) => NodeDeviceInfo.fromJson(value.output).serialNumber)
      .onError((error, stackTrace) => '');

  if (routerSN.isEmpty) return RouterType.others;

  final prefs = await SharedPreferences.getInstance();
  final currentSN = prefs.get(pCurrentSN);

  if (routerSN.isNotEmpty && routerSN == currentSN) {
    return RouterType.behindManaged;
  }
  return RouterType.behind;
}
```

**Extraction Notes**:
- Handles errors gracefully (returns empty string on failure)
- Uses `NodeDeviceInfo` JNAP model (must be encapsulated in service)
- Uses `pCurrentSN` constant from SharedPreferences

### Current `isRouterConfigured()` Logic (lines 113-125)

```dart
Future<RouterConfiguredData> isRouterConfigured() async {
  final routerRepository = ref.read(routerRepositoryProvider);
  final results = await routerRepository.fetchIsConfigured();

  bool isDefaultPassword = JNAPTransactionSuccessWrap.getResult(
    JNAPAction.isAdminPasswordDefault, Map.fromEntries(results)
  )?.output['isAdminPasswordDefault'];

  bool isSetByUser = JNAPTransactionSuccessWrap.getResult(
    JNAPAction.isAdminPasswordDefault, Map.fromEntries(results)
  )?.output['isAdminPasswordSetByUser'];

  return RouterConfiguredData(isDefaultPassword: isDefaultPassword, isSetByUser: isSetByUser);
}
```

**Extraction Notes**:
- Uses `JNAPTransactionSuccessWrap` (must be encapsulated in service)
- Uses `JNAPAction.isAdminPasswordDefault` (must be encapsulated in service)
- Returns `RouterConfiguredData` directly (already a UI-friendly type)

## Conclusions

All technical decisions are resolved. No blockers for Phase 1 design.
