# PrivacyGUI 架構違規修復歷史 (Architecture Violations History)

**初始報告**: 2026-01-16  
**完成修復**: 2026-01-19  
**文件狀態**: ✅ **全部完成** — 本文件現作為修復歷史記錄保留

> [!TIP]
> 所有 14 處架構違規已於 2026-01-19 全部修復完成。本文件保留詳細的修復過程記錄供日後參考。

---

## 違規統計摘要

| 違規類型 | 原始數量 | 已修復 | 剩餘 |
|----------|----------|--------|------|
| RouterRepository 在 Views 中使用 | 4 | 4 | ✅ 0 |
| RouterRepository 在 Providers 中使用 | 4 | 4 | ✅ 0 |
| JNAPAction 在非 Services 中使用 | 2 | 2 | ✅ 0 |
| JNAP Models 在 Views 中引用 | 4 | 4 | ✅ 0 |
| **總計** | **14** | **14** | **✅ 0** |

---

## 🔴 P0: RouterRepository 在 Views 中直接使用

### 違規原則
Views (展示層) 不應直接存取 RouterRepository (資料層)，應透過 Provider → Service 的路徑。

---

### 1. `prepare_dashboard_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/dashboard/views/prepare_dashboard_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/dashboard/views/prepare_dashboard_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-16 修復
>
> **修復方式**: 在 `SessionService` 新增 `forceFetchDeviceInfo()` 方法，將 JNAP 操作封裝在 Service 層。

**原違規行號**: 78-86

**原違規程式碼**:
```dart
} else if (loginType == LoginType.local) {
  logger.i('PREPARE LOGIN:: local');
  final routerRepository = ref.read(routerRepositoryProvider);  // ❌ 直接讀取

  final newSerialNumber = await routerRepository
      .send(
        JNAPAction.getDeviceInfo,  // ❌ 直接使用 JNAPAction
        fetchRemote: true,
      )
      .then<String>(
          (value) => NodeDeviceInfo.fromJson(value.output).serialNumber);
```

**修復後程式碼**:
```dart
} else if (loginType == LoginType.local) {
  logger.i('PREPARE LOGIN:: local');
  // Use sessionProvider.forceFetchDeviceInfo() instead of direct RouterRepository access
  // This adheres to Clean Architecture: View -> Provider -> Service -> Repository
  final deviceInfo = await ref
      .read(sessionProvider.notifier)
      .forceFetchDeviceInfo();  // ✅ 透過 Provider/Service
  await ref
      .read(sessionProvider.notifier)
      .saveSelectedNetwork(deviceInfo.serialNumber, '');
}
```

**相關測試**:
- [session_service_test.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/test/core/data/services/session_service_test.dart) - `forceFetchDeviceInfo` 測試群組
- [session_provider_test.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/test/core/data/providers/session_provider_test.dart) - `forceFetchDeviceInfo` 測試群組

---

### 2. `router_assistant_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/ai_assistant/views/router_assistant_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/ai_assistant/views/router_assistant_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-16 修復
>
> **修復方式**: 將 `routerCommandProviderProvider` 移動到專用的 Provider 檔案 `lib/page/ai_assistant/providers/router_command_provider.dart`，並在 View 中導入使用。

**相關變更**:
- [router_command_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/ai_assistant/providers/router_command_provider.dart) - 新建立的 Provider 檔案
- [router_assistant_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/ai_assistant/views/router_assistant_view.dart) - 移除 View 內的 Provider 定義

---

### 3. `local_network_settings_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-16 修復
>
> **修復方式**: 將 `getLocalIp()` 函數改為接受 `ProviderReader` 型別，支援 `Ref` 與 `WidgetRef` 共用。

**原違規行號**: 270, 308

**原違規程式碼**:
```dart
// Line 270 - 在 _saveSettings 錯誤處理中
final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();  // ❌

// Line 308 - 在 _finishSaveSettings 中
final currentUrl = ref.read(routerRepositoryProvider).getLocalIP();  // ❌
```

**修復後程式碼**:
```dart
// 使用平台感知的 getLocalIp 工具函數
final currentUrl = getLocalIp(ref.read);  // ✅ 不再依賴 RouterRepository
```

**相關變更**:
- [get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/get_local_ip.dart) - 新增 `ProviderReader` typedef
- [mobile_get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/mobile_get_local_ip.dart) - 更新簽名
- [web_get_local_ip.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/core/utils/ip_getter/web_get_local_ip.dart) - 更新簽名

---

### 4. `pnp_no_internet_connection_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart)

```dart
// 使用 AuthProvider 檢查登入狀態
final loginType = ref.read(authProvider.select((value) => value.value?.loginType));
if (loginType != null && loginType != LoginType.none) {
  goRoute(RouteNamed.pnpIspTypeSelection);
}

// 或透過 PnpProvider 暴露狀態
if (ref.read(pnpProvider.notifier).isLoggedIn) {
  goRoute(RouteNamed.pnpIspTypeSelection);
}
```

---

## 🟡 P1: RouterRepository 在 Providers 中直接使用

### 違規原則
Providers (應用層) 應透過 Service (服務層) 存取 RouterRepository，而不是直接呼叫。

---

### 1. `select_network_provider.dart` ✅ 已修復

**檔案路徑**: [lib/page/select_network/providers/select_network_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/select_network/providers/select_network_provider.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-16 修復
>
> **修復方式**: 建立了 `NetworkAvailabilityService` 並將 `select_network_provider.dart` 中的 `RouterRepository` 依賴轉移至該 Service。

**原違規行號**: 54-64

**原違規程式碼**:
```dart
Future<SelectNetworkState> _checkNetworkOnline(CloudNetworkModel network) async {
  final routerRepository = ref.read(routerRepositoryProvider);  // ❌
  bool isOnline = await routerRepository
      .send(JNAPAction.isAdminPasswordDefault,  // ❌ 直接使用 JNAPAction
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

### 2. `channelfinder_provider.dart` ✅ 已修復

**檔案路徑**: [lib/page/wifi_settings/providers/channelfinder_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/wifi_settings/providers/channelfinder_provider.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-16 修復
>
> **修復方式**: 將 `channelFinderServiceProvider` 定義移動至 Service 檔案 `channel_finder_service.dart` 中，解決了組織結構上的違規。

**原違規行號**: 7-9

**原違規程式碼**:
```dart
final channelFinderServiceProvider = Provider((ref) {
  return ChannelFinderService(ref.watch(routerRepositoryProvider));  // ⚠️
});
```

**相關變更**:
- [channel_finder_service.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/wifi_settings/services/channel_finder_service.dart) - 包含 Provider 定義
- [channelfinder_provider.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/wifi_settings/providers/channelfinder_provider.dart) - 移除 Provider 定義與 Repo 依賴

---

## 🟡 P2: JNAP Models 在 Views 中引用

### 違規原則
Views 應使用 UI Models，不應直接引用 JNAP Data Models。

---

### 1. `login_local_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/login/views/login_local_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/login/views/login_local_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-19 修復
>
> **修復方式**: 移除了 JNAP `device_info.dart` 的 import，該檔案不再直接依賴 JNAP 資料模型。

---

### 2. `prepare_dashboard_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/dashboard/views/prepare_dashboard_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/dashboard/views/prepare_dashboard_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-19 修復
>
> **修復方式**: 將 JNAP `device_info.dart` 改為引用 UI Model `core/models/device_info.dart`。

---

### 3. `firmware_update_process_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/firmware_update/views/firmware_update_process_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/firmware_update/views/firmware_update_process_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-19 修復
>
> **修復方式**: 將 JNAP `FirmwareUpdateStatus` tuple 改為使用 UI Model `FirmwareUpdateUIModel`。

---

### 4. `instant_admin_view.dart` ✅ 已修復

**檔案路徑**: [lib/page/instant_admin/views/instant_admin_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/instant_admin/views/instant_admin_view.dart)

> [!NOTE]
> **修復狀態**: ✅ 已於 2026-01-19 修復
>
> **修復方式**: 在 `FirmwareUpdateState` 新增 `isAutoUpdateEnabled` getter，在 `FirmwareUpdateNotifier` 新增 `setAutoUpdateEnabled()` 方法，移除 View 中的 JNAP import。

---

## 修復優先級建議

| 優先級 | 違規 | 預估工時 | 影響範圍 | 狀態 |
|--------|------|----------|----------|------|
| **P0-1** | `prepare_dashboard_view.dart` | 2-4 小時 | 登入流程 | ✅ 已修復 |
| **P0-2** | `pnp_no_internet_connection_view.dart` | 1-2 小時 | PnP 流程 | ✅ 已修復 |
| **P0-3** | `local_network_settings_view.dart` | 1-2 小時 | 網路設定 | ✅ 已修復 |
| **P0-4** | `router_assistant_view.dart` | 1 小時 | AI 助手 | ✅ 已修復 |
| **P1-1** | `select_network_provider.dart` | 2-3 小時 | 網路選擇 | ✅ 已修復 |
| **P1-2** | `channelfinder_provider.dart` | 30 分鐘 | WiFi 最佳化 | ✅ 已修復 |
| **P2-1** | `login_local_view.dart` (device_info) | 30 分鐘 | 低風險 | ✅ 已修復 |
| **P2-2** | `prepare_dashboard_view.dart` (device_info) | 30 分鐘 | 低風險 | ✅ 已修復 |
| **P2-3** | `firmware_update_process_view.dart` | 30 分鐘 | 低風險 | ✅ 已修復 |
| **P2-4** | `instant_admin_view.dart` | 30 分鐘 | 低風險 | ✅ 已修復 |

---

## 最佳實踐範例

### DMZ 模組 (參考範例)

```
lib/page/advanced_settings/dmz/
├── _dmz.dart                           # Barrel Export
├── views/
│   ├── dmz_view.dart                  # ✅ 只引用 Provider
│   └── dmz_settings_view.dart
├── providers/
│   ├── _providers.dart                # Barrel Export
│   ├── dmz_settings_provider.dart     # ✅ 透過 Service 存取資料
│   ├── dmz_settings_state.dart        # ✅ UI Models
│   └── dmz_status.dart
└── services/
    └── dmz_settings_service.dart      # ✅ 封裝所有 JNAP 操作
```

**關鍵原則**:
1. ✅ Views 只引用 Providers
2. ✅ Providers 透過 Services 存取 RouterRepository
3. ✅ Services 負責 Data Model ↔ UI Model 轉換
4. ✅ UI Models 與 JNAP Data Models 完全隔離

---

## 相關文件

- [service-decoupling-audit.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/audit/service-decoupling-audit.md) - 服務解耦審計 (更廣泛的分析)
- [architecture_analysis_2026-01-16.md](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/doc/architecture_analysis_2026-01-16.md) - 整體架構分析
- [DMZ Service](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/advanced_settings/dmz/services/dmz_settings_service.dart) - 最佳實踐範例
