# USP 架構命名重構方案

## 當前問題

現有架構中 `UspService` 與新增的業務服務層（如 `SystemInfoService`）命名混淆，職責邊界不清。

## 重構方案

### 1. 核心重新命名

```dart
// 當前
UspService        → UspClient
uspServiceProvider → uspClientProvider

// 保持不變
UspClientWeb  (Web 平台實現)
UspClientJS   (JavaScript 綁定)
```

### 2. 新架構層次

```
┌─────────────────┐
│ Provider Layer  │ ← 狀態管理、UI 邏輯
├─────────────────┤
│ Service Layer   │ ← 業務邏輯、錯誤處理 (新增)
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
├─────────────────┤
│ UspClientJS     │ ← JavaScript 綁定
└─────────────────┘
```

### 3. 重構檔案清單

#### 需要重新命名的檔案
- `lib/core/usp/services/usp_service.dart` → `lib/core/usp/clients/usp_client.dart`
- `lib/core/usp/providers/usp_service_provider.dart` → `lib/core/usp/providers/usp_client_provider.dart`

#### 需要更新引用的檔案 (約 50+ 檔案)
- 所有 Provider 檔案
- 所有 Codegen 模板
- 測試檔案
- 服務檔案

### 4. 漸進式重構步驟

#### Phase 1: 核心重新命名
- [ ] 重新命名 `UspService` → `UspClient`
- [ ] 更新 provider 引用
- [ ] 更新所有測試

#### Phase 2: 新增 Service 層
- [ ] 實作 `SystemInfoService` (試點)
- [ ] 實作 `DhcpService` 
- [ ] 驗證架構可行性

#### Phase 3: 全面遷移
- [ ] 其餘 Service 層實作
- [ ] 更新所有 Provider
- [ ] 移除臨時相容性代碼

### 5. 命名規範

#### Client 層 (協議/傳輸)
```dart
// 抽象協議客戶端
abstract class UspClient {
  Future<UspGetResult> getWithResult(List<String> paths);
  Future<UspSetResult> setWithResult(Map<String, String> params);
  // ...
}

// Web 平台實作
class UspClientImpl implements UspClient {
  final UspClientWeb _webClient;
}
```

#### Service 層 (業務邏輯)
```dart
// 業務服務封裝
class SystemInfoService {
  final UspClient _client;
  
  Future<SystemInfoData> fetchSystemInfoData() async {
    final result = await SystemInfo.fetchWithResult(_client);
    return _handleResult(result);
  }
}
```

#### Provider 層 (狀態管理)  
```dart
class SystemInfoDataNotifier extends AsyncNotifier<SystemInfoData> {
  @override
  Future<SystemInfoData> build() async {
    final client = ref.read(uspClientProvider)!;
    final service = SystemInfoService(client);
    return service.fetchSystemInfoData();
  }
}
```

## 預期效果

### 命名清晰度
- ✅ **Client**: 協議通信、傳輸層
- ✅ **Service**: 業務邏輯、錯誤處理
- ✅ **Provider**: 狀態管理、UI 邏輯

### 職責分離
- ✅ 每層職責清楚
- ✅ 測試更容易
- ✅ 維護性更好

### 漸進式演進
- ✅ 可分階段實施
- ✅ 風險可控
- ✅ 向後相容

## 影響評估

### 重構規模
- 檔案重新命名: 2 個核心檔案
- 引用更新: ~50 個檔案
- 新增檔案: ~12 個 Service 檔案

### 測試影響
- 單元測試需更新 import
- 集成測試邏輯不變
- 需新增 Service 層測試