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

#### Service 層職責 (業務邏輯)
```dart
class SystemInfoService {
  final UspClient _client;
  
  // 業務特定的資料獲取
  Future<SystemInfoData> fetchSystemInfoData() async {
    final result = await SystemInfo.fetchWithResult(_client);
    return _handleBusinessLogic(result);
  }
  
  // 業務特定的錯誤處理策略
  SystemInfoData _handleBusinessLogic(UspGetResult<SystemInfo> result) {
    return result.when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) {
        // 系統資訊允許部分成功，記錄警告
        logger.w('SystemInfo 部分參數獲取失敗: ${failures.length} errors');
        return data;
      },
      failure: (errors) => throw SystemInfoException(errors),
    );
  }
}
```

#### Provider 層選擇 (狀態管理)
```dart
class SystemInfoDataNotifier extends AsyncNotifier<SystemInfoData> {
  @override
  Future<SystemInfoData> build() async {
    final client = ref.read(uspClientProvider)!;
    
    // 方案 A：使用 Service 層（推薦）
    final service = SystemInfoService(client);
    return service.fetchSystemInfoData();
    
    // 方案 B：直接使用 Codegen（簡單場景）
    // return SystemInfo.fetch(client);
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

#### 階段 2B: Codegen 模板更新
```bash
# 目標：所有生成的程式碼提供雙重 API

1. ✅ 更新 codegen 模板
   - 生成 .fetch() 方法（傳統，向後兼容）
   - 生成 .fetchWithResult() 方法（結構化，推薦）

2. ✅ 重新生成所有模型
   - ./tools/usp-codegen --definitions-dir definitions/ --output-dir lib/generated/

3. ✅ 驗證生成結果
   - SystemInfo.fetch() 和 SystemInfo.fetchWithResult() 都可用
```

#### 階段 2C: Service 層試點實作
```bash
# 目標：實作 3 個關鍵 Service 作為試點

1. ✅ SystemInfoService
   - lib/page/admin/services/system_info_service.dart
   - 處理系統資訊的業務邏輯和錯誤處理

2. ✅ ConnectedDevicesService  
   - lib/page/devices/services/connected_devices_service.dart
   - 處理設備列表的業務邏輯

3. ✅ WiFiSettingsService
   - lib/page/wifi_settings/services/wifi_settings_service.dart
   - 處理 Wi-Fi 設定的業務邏輯

# 每個 Service 包含：
- fetchXxxData() 方法
- saveXxxData() 方法  
- 業務特定的錯誤處理策略
- 結構化回應的 when() 處理邏輯
```

#### 階段 2D: Provider 層遷移（關鍵模組）
```bash
# 目標：關鍵 Provider 遷移到 Service 層架構

1. ✅ SystemInfoDataNotifier
   - lib/page/admin/providers/system_info_data_provider.dart
   - 使用 SystemInfoService 替代直接 codegen 調用

2. ✅ DevicesDataNotifier
   - lib/page/devices/providers/devices_data_provider.dart
   - 使用 ConnectedDevicesService

3. ✅ WiFiDataProvider
   - lib/page/wifi_settings/providers/wifi_data_provider.dart
   - 使用 WiFiSettingsService

4. ✅ 寫入操作 Provider (高優先級)
   - 所有有 SET/ADD/DELETE 操作的 Provider
   - 錯誤處理對寫入操作更重要
```

### 2.3 Service 層實作模式

#### 模式 A: 錯誤敏感業務邏輯
```dart
class CriticalSystemService {
  Future<SystemData> fetchData() async {
    final result = await SystemModel.fetchWithResult(_client);
    
    return result.when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) {
        // 關鍵系統：部分失敗也要拋出異常
        throw PartialFailureException('Critical data incomplete', failures);
      },
      failure: (errors) => throw SystemException(errors),
    );
  }
}
```

#### 模式 B: 容錯業務邏輯
```dart
class DisplayDataService {
  Future<DisplayData> fetchData() async {
    final result = await DisplayModel.fetchWithResult(_client);
    
    return result.when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) {
        // 顯示資料：允許部分成功，記錄但不中斷
        logger.w('部分資料獲取失敗，繼續顯示可用資料');
        return data;
      },
      failure: (errors) => throw DisplayException(errors),
    );
  }
}
```

#### 模式 C: 簡單業務邏輯
```dart
class SimpleDataNotifier extends AsyncNotifier<SimpleData> {
  @override
  Future<SimpleData> build() async {
    final client = ref.watch(uspClientProvider)!;
    // 對於簡單場景，繼續使用傳統 API
    return SimpleData.fetch(client);
  }
}
```

### 2.4 錯誤處理策略擴展

#### 業務錯誤處理擴展
```dart
extension UspResultBusinessLogic<T> on UspOperationResult<T> {
  /// 允許部分成功的業務邏輯
  T getDataOrPartial({String? context}) {
    return when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) {
        logger.w('[$context] 部分成功: ${failures.length} 個參數失敗');
        return data;
      },
      failure: (errors) => throw UspBusinessException(context, errors),
    );
  }
  
  /// 嚴格模式：任何錯誤都中斷
  T getDataStrict({String? context}) {
    return when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) => 
        throw UspPartialFailureException(context, failures),
      failure: (errors) => throw UspBusinessException(context, errors),
    );
  }
  
  /// 容錯模式：提供預設值
  T getDataWithFallback(T fallback, {String? context}) {
    return when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) => data,
      failure: (errors) {
        logger.e('[$context] 資料獲取失敗，使用預設值');
        return fallback;
      },
    );
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