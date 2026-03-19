# PrivacyGUI Architecture Violations List (Architecture Violations Report)

**Report Date**: 2026-01-16  
**Purpose**: Document all code that violates Clean Architecture principles to facilitate planned refactoring

---

## Violations Statistics Summary

| Violation Type | Count | Criticality |
|----------|------|--------|
| RouterRepository used in Views | ~~4~~ 2 | 🔴 High |
| RouterRepository used in Providers | 2 | 🟡 Medium |
| JNAPAction used in non-Services | ~~2~~ 1 | 🔴 High |
| JNAP Models referenced in Views | 4 | 🟡 Medium |
| **Total** | **~~12~~ 9** | - |

---

## 🔴 P0: RouterRepository directly used in Views

### Violation Principle
Views (Presentation Layer) should not directly access RouterRepository (Data Layer); they should go through the Provider → Service path.

---

### 1. `prepare_dashboard_view.dart` ✅ Fixed

**File Path**: [lib/page/dashboard/views/prepare_dashboard_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/dashboard/views/prepare_dashboard_view.dart)

> [!NOTE]
> **Fix Status**: ✅ 已於 2026-01-16 Fix
>
> **Fix Method**: Added `forceFetchDeviceInfo()` method in `SessionService` to encapsulate JNAP operations in the Service layer.

**Original Violation Line Number**: 78-86

**Original Violating Code**:
```dart
} else if (loginType == LoginType.local) {
  logger.i('PREPARE LOGIN:: local');
  final routerRepository = ref.read(routerRepositoryProvider);  // ❌ Direct Read

  final newSerialNumber = await routerRepository
      .send(
        JNAPAction.getDeviceInfo,  // ❌ Direct use of JNAPAction
        fetchRemote: true,
      )
      .then<String>(
          (value) => NodeDeviceInfo.fromJson(value.output).serialNumber);
```

**Fixed Code**:
```dart
} else if (loginType == LoginType.local) {
  logger.i('PREPARE LOGIN:: local');
  // Use sessionProvider.forceFetchDeviceInfo() instead of direct RouterRepository access
  // This adheres to Clean Architecture: View -> Provider -> Service -> Repository
  final deviceInfo = await ref
      .read(sessionProvider.notifier)
      .forceFetchDeviceInfo();  // ✅ Via Provider/Service
  await ref
      .read(sessionProvider.notifier)
      .saveSelectedNetwork(deviceInfo.serialNumber, '');
}
```

**Related Testing**:
- [session_service_test.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/test/core/data/services/session_service_test.dart) - `forceFetchDeviceInfo` testing group
- [session_provider_test.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/test/core/data/providers/session_provider_test.dart) - `forceFetchDeviceInfo` testing group

---

### 2. `router_assistant_view.dart` ✅ Fixed

**File Path**: [lib/page/ai_assistant/views/router_assistant_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/ai_assistant/views/router_assistant_view.dart)

> [!NOTE]
> **Fix Status**: ✅ 已於 2026-01-16 Fix
>
> **Fix Method**: 將 `routerCommandProviderProvider` Moved to dedicated Provider file `lib/page/ai_assistant/providers/router_command_provider.dart`，and imported for use in View。

**相關變更**:
- [router_command_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/ai_assistant/providers/router_command_provider.dart) - Newly created Provider file
- [router_assistant_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/ai_assistant/views/router_assistant_view.dart) - Removed Provider definition inside View

---

### 3. `local_network_settings_view.dart` ✅ Fixed

**File Path**: [lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart)

> [!NOTE]
> **Fix Status**: ✅ 已於 2026-01-16 Fix
>
> **Fix Method**: Changed `getLocalIp()` function to accept `ProviderReader` type, supporting shared use with `Ref` and `WidgetRef`.

**Original Violation Line Number**: 270, 308

**Original Violating Code**:
```dart
// Line 270 - In _saveSettings error handling
final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();  // ❌

// Line 308 - In _finishSaveSettings
final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();  // ❌
```

**Fixed Code**:
```dart
// Use platform-aware getLocalIp utility function
final currentUrl = getLocalIp(ref.read);  // ✅ No longer depends on RouterRepository
```

**相關變更**:
- [get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/get_local_ip.dart) - Added `ProviderReader` typedef
- [mobile_get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/mobile_get_local_ip.dart) - update signature
- [web_get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/web_get_local_ip.dart) - update signature

---

### 4. `pnp_no_internet_connection_view.dart` ✅ Fixed

**File Path**: [lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart)

```dart
// Use AuthProvider to check login status
final loginType = ref.read(authProvider.select((value) => value.value?.loginType));
if (loginType != null && loginType != LoginType.none) {
  goRoute(RouteNamed.pnpIspTypeSelection);
}

// Or expose status via PnpProvider
if (ref.read(pnpProvider.notifier).isLoggedIn) {
  goRoute(RouteNamed.pnpIspTypeSelection);
}
```

---

## 🟡 P1: RouterRepository directly used in Providers

### Violation Principle
Providers (Application Layer) should access RouterRepository through Service (Service Layer) instead of calling it directly.

---

### 1. `select_network_provider.dart` ✅ Fixed

**File Path**: [lib/page/select_network/providers/select_network_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/select_network/providers/select_network_provider.dart)

> [!NOTE]
> **Fix Status**: ✅ 已於 2026-01-16 Fix
>
> **Fix Method**: Create了 `NetworkAvailabilityService` and moved `RouterRepository` dependency in `select_network_provider.dart` to that Service.

**Original Violation Line Number**: 54-64

**Original Violating Code**:
```dart
Future<SelectNetworkState> _checkNetworkOnline(CloudNetworkModel network) async {
  final routerRepository = ref.read(routerRepositoryProvider);  // ❌
  bool isOnline = await routerRepository
      .send(JNAPAction.isAdminPasswordDefault,  // ❌ Direct use of JNAPAction
          extraHeaders: {
            kJNAPNetworkId: network.network.networkId,
          },
          type: CommandType.remote,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache)
      .then((value) => value.result == 'OK')
      .onError((error, stackTrace) => false);
  //...
}
```

      final result = await _repository.send(
        JNAPAction.isAdminPasswordDefault,
        extraHeaders: {kJNAPNetworkId: networkId},
        type: CommandType.remote,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
      return result.result == 'OK';
    } catch (_) {
      return false;
    }
  }
}
```

---

### 2. `channelfinder_provider.dart` ✅ Fixed

**File Path**: [lib/page/wifi_settings/providers/channelfinder_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/wifi_settings/providers/channelfinder_provider.dart)

> [!NOTE]
> **Fix Status**: ✅ 已於 2026-01-16 Fix
>
> **Fix Method**: Moved `channelFinderServiceProvider` definition to Service file `channel_finder_service.dart` , resolving organizational structure Violations.

**Original Violation Line Number**: 7-9

**Original Violating Code**:
```dart
final channelFinderServiceProvider = Provider((ref) {
  return ChannelFinderService(ref.watch(routerRepositoryProvider));  // ⚠️
});
```

**相關變更**:
- [channel_finder_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/wifi_settings/services/channel_finder_service.dart) - contains Provider 定義
- [channelfinder_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/wifi_settings/providers/channelfinder_provider.dart) - Removed Provider definition and Repo dependency

---

## 🟡 P2: JNAP Models referenced in Views

### Violation Principle
Views should use UI Models and should not directly reference JNAP Data Models.

---

### 1. `login_local_view.dart`

**File Path**: [lib/page/login/views/login_local_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/login/views/login_local_view.dart)

**ViolationsLine Number**: 8

**Violating Code**:
```dart
import 'package:privacy_gui/core/jnap/models/device_info.dart';  // ❌
```

**Issue Description**: View references JNAP data model

---

### 2. `prepare_dashboard_view.dart`

**File Path**: [lib/page/dashboard/views/prepare_dashboard_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/dashboard/views/prepare_dashboard_view.dart)

**ViolationsLine Number**: 16

**Violating Code**:
```dart
import 'package:privacy_gui/core/jnap/models/device_info.dart';  // ❌
```

**Issue Description**: View references JNAP data model (Related to P0 #1)

---

### 3. `firmware_update_process_view.dart`

**File Path**: [lib/page/firmware_update/views/firmware_update_process_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/firmware_update/views/firmware_update_process_view.dart)

**ViolationsLine Number**: 4

**Violating Code**:
```dart
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';  // ❌
```

**Issue Description**: View references JNAP data model

---

### 4. `instant_admin_view.dart`

**File Path**: [lib/page/instant_admin/views/instant_admin_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_admin/views/instant_admin_view.dart)

**ViolationsLine Number**: 7

**Violating Code**:
```dart
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';  // ❌
```

**Issue Description**: View references JNAP data model

---

## Fix Priority Suggestions

| Priority | Violations | Estimated Effort | Impact Scope | Status |
|--------|------|----------|----------|------|
| **P0-1** | `prepare_dashboard_view.dart` | 2-4 hours | Login Flow | ✅ Fixed |
| **P0-2** | `pnp_no_internet_connection_view.dart` | 1-2 hours | PnP Flow | ✅ Fixed |
| **P0-3** | `local_network_settings_view.dart` | 1-2 hours | Network Setup | ✅ Fixed |
| **P0-4** | `router_assistant_view.dart` | 1 hours | AI Assistant | ✅ Fixed |
| **P1-1** | `select_network_provider.dart` | 2-3 hours | Network Selection | ✅ Fixed |
| **P1-2** | `channelfinder_provider.dart` | 30 minutes | WiFi Optimization | ✅ Fixed |
| **P2** | JNAP Models imports | 30 minutes each | Low Risk | To Be Fixed |

---

## Best Practices Example

### DMZ Module (Reference Example)

```
lib/page/advanced_settings/dmz/
├── _dmz.dart                           # Barrel Export
├── views/
│   ├── dmz_view.dart                  # ✅ Only references Provider
│   └── dmz_settings_view.dart
├── providers/
│   ├── _providers.dart                # Barrel Export
│   ├── dmz_settings_provider.dart     # ✅ Accesses data via Service
│   ├── dmz_settings_state.dart        # ✅ UI Models
│   └── dmz_status.dart
└── services/
    └── dmz_settings_service.dart      # ✅ Encapsulates all JNAP operations
```

**Key Principles**:
1. ✅ Views only reference Providers
2. ✅ Providers access RouterRepository via Services
3. ✅ Services responsible for Data Model ↔ UI Model conversion
4. ✅ UI Models completely isolated from JNAP Data Models

---

## Related Documents

- [service-decoupling-audit.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/service-decoupling-audit.md) - Service decoupling audit (Broader Analysis)
- [architecture_analysis_2026-01-16.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/architecture_analysis_2026-01-16.md) - Overall Architecture Analysis
- [DMZ Service](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/dmz/services/dmz_settings_service.dart) - Best Practices Example
