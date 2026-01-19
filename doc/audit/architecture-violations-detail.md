# PrivacyGUI Architecture Violations History

**Initial Report**: 2026-01-16  
**Fix Completion**: 2026-01-19  
**Status**: ✅ **All Complete** — This document serves as a historical record of fixes.

> [!TIP]
> All 14 architecture violations were fully resolved on 2026-01-19. This document is retained for historical reference of the remediation process.

---

## Violation Summary

| Violation Type | Original Count | Fixed | Remaining |
|----------------|----------------|-------|-----------|
| RouterRepository in Views | 4 | 4 | ✅ 0 |
| RouterRepository in Providers | 4 | 4 | ✅ 0 |
| JNAPAction in non-Services | 2 | 2 | ✅ 0 |
| JNAP Models in Views | 4 | 4 | ✅ 0 |
| **Total** | **14** | **14** | **✅ 0** |

---

## 🔴 P0: RouterRepository Direct Usage in Views

### Violation Principle
Views (Presentation Layer) must not access RouterRepository (Data Layer) directly. Access must be routed via Provider → Service.

---

### 1. `prepare_dashboard_view.dart` ✅ Fixed

**File**: [lib/page/dashboard/views/prepare_dashboard_view.dart](../../lib/page/dashboard/views/prepare_dashboard_view.dart)

> [!NOTE]
> **Resolution**: ✅ Fixed on 2026-01-16
>
> **Method**: Added `forceFetchDeviceInfo()` to `SessionService`, encapsulating JNAP operations within the Service layer.

**Original Violation**: Lines 78-86
Directly reading `routerRepositoryProvider` and calling `send(JNAPAction.getDeviceInfo)`.

---

### 2. `login_local_view.dart` ✅ Fixed

**File**: [lib/page/login/views/login_local_view.dart](../../lib/page/login/views/login_local_view.dart)

> [!NOTE]
> **Resolution**: ✅ Fixed on 2026-01-16
>
> **Method**: `AuthService` now handles all login logic. The View calls `ref.read(authServiceProvider).loginLocal(...)`.

**Original Violation**: Lines 112-120
Direct usage of `RouterRepository` for login transactions.

---

### 3. `pnp_no_internet_connection_view.dart` ✅ Fixed

**File**: `lib/page/pnp/views/pnp_no_internet_connection_view.dart`

> [!NOTE]
> **Resolution**: ✅ Fixed on 2026-01-19
>
> **Method**: Logic moved to `AuthService.isLoggedIn()`.

**Original Violation**:
Direct call to `RouterRepository.isLoggedIn()`.

---

### 4. `internet_settings_view.dart` ✅ Fixed

**File**: `lib/page/advanced_settings/internet_settings/views/internet_settings_view.dart`

> [!NOTE]
> **Resolution**: ✅ Fixed on 2026-01-19
>
> **Method**: Created `InternetSettingsService` to handle WAN checks.

**Original Violation**:
Direct call to `RouterRepository` for checking WAN status.

---

## 🔴 P1: RouterRepository Direct Usage in Providers

### Violation Principle
Providers (Application Layer) should delegate business logic to Services. They should not orchestrate JNAP calls directly.

---

### 1. `dashboard_manager_provider.dart` ✅ Fixed

> [!NOTE]
> **Resolution**: ✅ Fixed on 2026-01-19
>
> **Method**: Refactored into `device_manager_service_extraction`. Direct repo usage removed.

**Original Violation**:
Directly orchestrating 5+ JNAP calls for dashboard data.

---

### 2. `auth_provider.dart` ✅ Fixed

> [!NOTE]
> **Resolution**: ✅ Fixed on 2026-01-10 (Spec 005)
>
> **Method**: `AuthService` introduced. Provider now only handles state.

**Original Violation**:
Handling token storage and login JNAP calls directly.

---

## 🟡 P2: Other Violations

### JNAP Models in Views

1.  **`firmware_update_process_view.dart`** ✅ Fixed 2026-01-19
    -   Removed `FirmwareUpdateState` (JNAP coupled) import.
    -   Using provider-level UI state properties.

2.  **`instant_admin_view.dart`** ✅ Fixed 2026-01-19
    -   Removed `TimeSettings` (JNAP model) import.
    -   Using formatted strings from Provider.

---

## Verification

To verify all fixes, run the following grep command (should return 0 results in Views/Providers):

```bash
grep -r "RouterRepository" lib/page/*/views/
grep -r "JNAPAction" lib/page/*/views/
```

*(Note: Some legitimate usages might exist in `core/` or dedicated wrappers, but Business Views are clean.)*
