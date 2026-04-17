# USP 架構完整重構計劃

## 概述

完整重構 USP 架構，實現兩個主要目標：
1. **命名重構**：UspService → UspClient，避免與業務服務層命名混淆
2. **架構層次化**：新增 Service 層處理結構化回應，實現 "Never Lose Information" 原則

## 重構前後架構對比

### 當前架構
```
┌─────────────────┐
│ Provider Layer  │ ← 狀態管理、UI 邏輯
├─────────────────┤
│ Codegen Layer   │ ← 資料模型、直接調用 UspService
│ - SystemInfo.fetch(UspService)
│ - DhcpClients.fetch(UspService)
├─────────────────┤
│ UspService      │ ← USP 協議客戶端、認證、節流
│                 │   (命名與業務服務混淆)
├─────────────────┤
│ UspClientWeb    │ ← Web 平台 WASM 包裝
└─────────────────┘
```

### 目標架構
```
┌─────────────────┐
│ Provider Layer  │ ← 狀態管理、UI 邏輯
├─────────────────┤
│ Service Layer   │ ← 業務邏輯、錯誤處理策略 (新增)
│ - SystemInfoService
│ - DhcpService
│ - FirewallService
├─────────────────┤
│ Codegen Layer   │ ← 資料模型、USP 調用
│ - SystemInfo.fetchWithResult()
│ - DhcpClients.fetchWithResult()
├─────────────────┤
│ UspClient       │ ← USP 協議客戶端 (重新命名)
│                 │   認證、結構化回應、節流
├─────────────────┤
│ UspClientWeb    │ ← Web 平台 WASM 包裝
└─────────────────┘
```

## Phase 1: 重命名重構 (UspService → UspClient)

### 目標
- 解決 UspService 與業務服務層命名混淆
- 為 Phase 2 的 Service 層實作做準備
- 保持現有功能完全不變

### 影響範圍
- **總計影響檔案**: 約 200+ 檔案
- 詳細清單參見：`doc/architecture/usp-service-to-client-rename-plan.md`

### 執行步驟
1. 更新 Codegen 設定和 Memory 檔案
2. 重新命名核心檔案：`UspService` → `UspClient`
3. 重新生成 codegen 程式碼（27個檔案）
4. 更新 Provider 匯入（53個檔案）
5. 更新類別參考（107個檔案）
6. 更新文件和測試

### 完成標準
- ✅ 所有程式碼可編譯通過
- ✅ 現有測試全部通過
- ✅ USP 功能完全不變

## Phase 2: Service 層架構實作

### 目標
- 實作業務邏輯層，處理 UspOperationResult 結構化回應
- 為不同業務場景提供不同的錯誤處理策略
- 保持 Provider 層邏輯簡潔，可選擇使用傳統或結構化 API

### 2.1 架構設計原則

#### Client 層職責 (UspClient)
```dart
abstract class UspClient {
  // 結構化回應 API (推薦)
  Future<UspGetResult> getWithResult(List<String> paths);
  Future<UspSetResult> setWithResult(Map<String, String> params);
  Future<UspAddResult> addWithResult(String path, Map<String, String> params);
  Future<UspDeleteResult> deleteWithResult(String path);
  
  // 傳統 API (向後兼容)
  Future<Map<String, String>> get(List<String> paths);
  Future<void> set(Map<String, String> params);
  // ...
}
```

#### Service 層職責 (業務邏輯 + 錯誤映射)
```dart
class SystemInfoService {
  final UspClient _client;
  
  // 業務特定的資料獲取
  Future<SystemInfoData> fetchSystemInfoData() async {
    try {
      // 使用結構化 API
      final result = await _client.getWithResult(['Device.DeviceInfo.*']);
      final parsedResult = UspResultParser.parseGetResult<SystemInfo>(
        result, 
        (data) => SystemInfo.fromMap(data)  // 使用 codegen 的解析邏輯
      );
      
      return _handleBusinessLogic(parsedResult);
    } catch (e) {
      // 使用現有的統一錯誤映射
      throw mapUspErrorToServiceError(e);
    }
  }
  
  // 業務特定的結構化回應處理
  SystemInfoData _handleBusinessLogic(UspOperationResult<SystemInfo> result) {
    return result.when(
      success: (data, details) => SystemInfoData.fromSystemInfo(data),
      partialSuccess: (data, successes, failures) {
        // 系統資訊允許部分成功，記錄警告
        logger.w('SystemInfo 部分參數獲取失敗: ${failures.length} errors');
        return SystemInfoData.fromSystemInfo(data);
      },
      failure: (errors) {
        // 這裡不會到達，因為 WASM 錯誤已經在 try-catch 轉換為 ServiceError
        throw UnexpectedError(message: 'Unexpected failure result');
      },
    );
  }
}
```

#### Provider 層選擇 (狀態管理 + 統一錯誤處理)
```dart
class SystemInfoDataNotifier extends AsyncNotifier<SystemInfoData> {
  @override
  Future<SystemInfoData> build() async {
    final client = ref.read(uspClientProvider)!;
    
    try {
      // 方案 A：使用 Service 層（推薦）
      final service = SystemInfoService(client);
      return await service.fetchSystemInfoData();
    } on ServiceError {
      // ServiceError 會自動被 Riverpod 轉換為 AsyncError 狀態
      rethrow;
    }
    
    // 方案 B：直接使用 Codegen（簡單場景，需要手動錯誤處理）
    // try {
    //   return SystemInfo.fetch(client);
    // } catch (e) {
    //   throw mapUspErrorToServiceError(e);
    // }
  }
}
```

### 2.2 實作計劃

#### 階段 2A: UspClient API 完善
```bash
# 目標：確保 UspClient 有完整的結構化 API

1. ✅ 添加 UspClient.getWithResult() 方法
   - lib/core/usp/services/usp_client.dart
   - 確保 GET 操作能返回 UspGetResult

2. ✅ 完善 UspResultParser
   - lib/core/usp/models/usp_operation_result.dart
   - 添加 parseGetResult() 方法

3. ✅ 更新 WASM 層支持
   - lib/core/usp/web/usp_client_wasm.dart
   - 確保 GET 操作回傳結構化回應（移除臨時兼容層）
```

#### 階段 2B: Service 層架構設計 (不修改 Codegen)
```bash
# 目標：設計 Service 層標準實作模式，基於現有 unified error handling 架構

1. ✅ 利用現有 ServiceError 架構
   - lib/core/errors/service_error.dart (已存在)
   - lib/core/usp/errors/usp_error.dart (已存在)
   - mapUspErrorToServiceError() 函數 (已存在)

2. ✅ 標準 Service 層模式
   - 使用 UspClient.getWithResult() 結構化 API
   - 使用 UspResultParser 解析結構化回應
   - 使用 SystemInfo.fromMap() 等 codegen 解析邏輯（不修改 codegen）
   - 統一錯誤映射：catch → mapUspErrorToServiceError() → throw ServiceError

3. ✅ Provider 層錯誤處理
   - 只需 catch ServiceError 子類型
   - Riverpod 自動轉換為 AsyncError 狀態
```

#### 階段 2C: Service 層試點實作
```bash
# 目標：實作 3 個關鍵 Service 作為試點，展示標準模式

1. ✅ SystemInfoService
   - lib/page/admin/services/system_info_service.dart
   - 展示讀取操作 + 部分成功容錯處理

2. ✅ ConnectedDevicesService  
   - lib/page/devices/services/connected_devices_service.dart
   - 展示多模型聚合 + 錯誤處理

3. ✅ WiFiSettingsService
   - lib/page/wifi_settings/services/wifi_settings_service.dart
   - 展示寫入操作 + 嚴格錯誤處理

# 每個 Service 標準結構：
- fetchXxxData(): 使用 getWithResult() + UspResultParser + mapUspErrorToServiceError()
- saveXxxData(): 使用 setWithResult() + 業務邏輯錯誤處理 + 統一錯誤映射  
- _handleResult(): 結構化回應的 when() 處理（成功/部分成功/失敗）
- Provider 層只需處理 ServiceError 子類型
```

#### 階段 2D: Provider 層遷移（關鍵模組）
```bash
# 目標：關鍵 Provider 遷移到 Service 層架構 + 統一錯誤處理

1. ✅ SystemInfoDataNotifier
   - lib/page/admin/providers/system_info_data_provider.dart
   - 從直接 codegen 調用 → SystemInfoService + ServiceError 處理

2. ✅ DevicesDataNotifier
   - lib/page/devices/providers/devices_data_provider.dart
   - ConnectedDevicesService + 多模型聚合錯誤處理

3. ✅ WiFiDataProvider
   - lib/page/wifi_settings/providers/wifi_data_provider.dart
   - WiFiSettingsService + 寫入操作嚴格錯誤處理

4. ✅ 寫入操作 Provider (高優先級)
   - 所有有 SET/ADD/DELETE 操作的 Provider
   - 利用結構化回應處理部分成功場景
   - 統一的 ServiceError 錯誤處理，UI 層一致體驗

# Provider 層遷移模式：
- 移除直接 codegen 調用和手動錯誤處理
- 使用 Service 層 + catch ServiceError 子類型
- Riverpod AsyncError 自動處理，UI 層統一錯誤顯示
```

### 2.3 Service 層實作模式（基於現有 Unified Error Handling）

#### 模式 A: 錯誤敏感業務邏輯（關鍵系統）
```dart
class CriticalSystemService {
  final UspClient _client;
  
  Future<SystemData> fetchData() async {
    try {
      // 使用結構化 API + 現有 codegen 解析
      final result = await _client.getWithResult(['Device.System.*']);
      final parsedResult = UspResultParser.parseGetResult<SystemModel>(
        result, 
        (data) => SystemModel.fromMap(data)
      );
      
      return parsedResult.when(
        success: (data, details) => SystemData.fromSystemModel(data),
        partialSuccess: (data, successes, failures) {
          // 關鍵系統：部分失敗也要拋出 ServiceError
          throw InvalidInputError(
            message: 'Critical data incomplete: ${failures.length} errors'
          );
        },
        failure: (errors) {
          // 這裡不會到達（WASM 錯誤已轉換為 ServiceError）
          throw UnexpectedError(message: 'Unexpected failure result');
        },
      );
    } catch (e) {
      // 統一錯誤映射：所有 USP 錯誤 → ServiceError
      throw mapUspErrorToServiceError(e);
    }
  }
}
```

#### 模式 B: 容錯業務邏輯（顯示資料）
```dart
class DisplayDataService {
  final UspClient _client;
  
  Future<DisplayData> fetchData() async {
    try {
      final result = await _client.getWithResult(['Device.Display.*']);
      final parsedResult = UspResultParser.parseGetResult<DisplayModel>(
        result, 
        (data) => DisplayModel.fromMap(data)
      );
      
      return parsedResult.when(
        success: (data, details) => DisplayData.fromDisplayModel(data),
        partialSuccess: (data, successes, failures) {
          // 顯示資料：允許部分成功，記錄但不中斷
          logger.w('部分資料獲取失敗，繼續顯示可用資料');
          return DisplayData.fromDisplayModel(data);
        },
        failure: (errors) {
          // 這裡不會到達（WASM 錯誤已轉換為 ServiceError）
          throw UnexpectedError(message: 'Unexpected failure result');
        },
      );
    } catch (e) {
      // 統一錯誤映射
      throw mapUspErrorToServiceError(e);
    }
  }
}
```

#### 模式 C: 簡單業務邏輯（保持傳統 API）
```dart
class SimpleDataNotifier extends AsyncNotifier<SimpleData> {
  @override
  Future<SimpleData> build() async {
    final client = ref.watch(uspClientProvider)!;
    
    try {
      // 簡單場景：繼續使用傳統 API + 手動錯誤處理
      return await SimpleData.fetch(client);
    } catch (e) {
      // 手動錯誤映射到 ServiceError
      throw mapUspErrorToServiceError(e);
    }
  }
}
```

### 2.4 基於現有 ServiceError 架構的錯誤處理策略

#### 利用現有 ServiceError 層次結構
```dart
class ServiceLayerErrorHandling {
  /// 容錯策略：部分成功可接受
  T handleTolerantly<T>(UspOperationResult<T> result, T Function(T) transform) {
    return result.when(
      success: (data, details) => transform(data),
      partialSuccess: (data, successes, failures) {
        logger.w('部分成功，繼續處理: ${failures.length} 個參數失敗');
        return transform(data);
      },
      failure: (errors) {
        // 這裡不會到達，因為 WASM 錯誤已轉換為 ServiceError
        throw UnexpectedError(message: 'Unexpected failure result');
      },
    );
  }
  
  /// 嚴格策略：部分失敗也拋出 ServiceError
  T handleStrictly<T>(UspOperationResult<T> result, T Function(T) transform) {
    return result.when(
      success: (data, details) => transform(data),
      partialSuccess: (data, successes, failures) {
        // 拋出 ServiceError，讓 Provider 層統一處理
        throw InvalidInputError(
          message: 'Partial success not acceptable: ${failures.length} errors'
        );
      },
      failure: (errors) {
        throw UnexpectedError(message: 'Unexpected failure result');
      },
    );
  }
}
```

#### Provider 層統一錯誤處理模式
```dart
class ExampleDataNotifier extends AsyncNotifier<ExampleData> {
  @override
  Future<ExampleData> build() async {
    final client = ref.read(uspClientProvider)!;
    
    try {
      final service = ExampleService(client);
      return await service.fetchData();
    } on InvalidCredentialsError {
      // 處理特定的認證錯誤
      ref.read(authProvider.notifier).logout();
      rethrow;
    } on NetworkError catch (e) {
      // 處理網路錯誤
      logger.e('Network error: ${e.message}');
      rethrow;
    } on ServiceError {
      // 其他 ServiceError 讓 Riverpod 自動轉換為 AsyncError
      rethrow;
    }
  }
}
```

## 完整執行時程

### Week 1: Phase 1 重命名重構
- **Day 1-2**: Codegen 設定更新和核心檔案重新命名
- **Day 3-4**: Provider 和類別參考更新
- **Day 5**: 測試驗證和文件更新

### Week 2: Phase 2A-2B 基礎架構
- **Day 1-2**: UspClient API 完善和 WASM 層修復
- **Day 3-4**: Codegen 模板更新和重新生成
- **Day 5**: 雙重 API 驗證測試

### Week 3: Phase 2C-2D 業務層實作
- **Day 1-2**: 3 個試點 Service 層實作
- **Day 3-4**: 關鍵 Provider 遷移到 Service 層
- **Day 5**: 集成測試和錯誤處理驗證

### Week 4: 驗證和最佳化
- **Day 1-2**: 完整功能測試和回歸測試
- **Day 3-4**: 效能最佳化和程式碼清理
- **Day 5**: 文件更新和架構驗證

## 成功標準

### Phase 1 完成標準
- ✅ 所有程式碼編譯通過
- ✅ 現有 USP 功能完全正常
- ✅ 測試套件 100% 通過
- ✅ 命名衝突完全解決

### Phase 2 完成標準
- ✅ 結構化回應完整實作，無資訊丟失
- ✅ 3 個試點 Service 層功能正常
- ✅ Provider 可選擇傳統或 Service 層架構
- ✅ 錯誤處理策略靈活可配置
- ✅ 向後兼容性 100% 保持

### 整體架構目標
- ✅ **命名清晰**: Client/Service/Provider 職責邊界明確
- ✅ **資訊完整**: 結構化回應保留所有 firmware 資訊
- ✅ **業務導向**: 錯誤處理策略由業務邏輯決定
- ✅ **漸進式**: 可按模組逐步採用新架構
- ✅ **類型安全**: 使用 sealed class 確保完整錯誤處理

## 風險評估與緩解

### 高風險項目
1. **WASM 層結構化回應**: 可能影響所有 USP 操作
2. **Codegen 模板更新**: 可能導致生成程式碼不相容
3. **Provider 大規模遷移**: 可能影響 UI 功能

### 緩解策略
1. **分支隔離**: 每個 Phase 使用獨立分支開發
2. **階段性測試**: 每個階段完成後立即進行完整測試
3. **向後兼容**: 保持傳統 API 可用，確保漸進式遷移
4. **回滾計劃**: 每個階段都有明確的回滾步驟

---

**文件版本**: v1.0  
**建立日期**: 2026-04-10  
**預計總工期**: 4 週  
**負責人**: Austin Chang