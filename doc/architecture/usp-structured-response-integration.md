# USP 結構化回應集成架構方案

## 概述

本文檔描述如何將 USP v0.11.0 結構化回應系統架構性地集成到現有的 codegen + provider 架構中。

## 當前狀況

### 基礎建設 ✅
- `UspOperationResult<T>` 封裝類已完成
- `UspResultParser` 解析器已完成  
- WASM 層已能回傳結構化回應
- SET/ADD/DELETE 操作已有 `xxxWithResult()` 方法

### 架構缺口 ❌
- GET 操作缺少 `getWithResult()` 方法
- Codegen 直接調用扁平 API (`UspService.get()`)
- Provider 層無法獲得錯誤詳情和操作狀態
- 部分成功場景無法正確處理

## 解決方案：混合架構模式

### 1. **UspService 層完善**

添加缺少的結構化 API：

```dart
// 新增 GET 操作的結構化版本
Future<UspGetResult> getWithResult(
  List<String> paths, {
  RequestPriority? priority,
}) async {
  final rawResult = await _rawGetStructured(paths, priority: priority);
  return UspResultParser.parseGetResult(rawResult);
}

Future<Map<String, dynamic>> _rawGetStructured(
  List<String> paths, {
  RequestPriority? priority,
}) async {
  // 調用 WASM 層獲取結構化回應，不做扁平化處理
}
```

### 2. **Codegen 模板更新**

提供雙重 API 支持：

```dart
// 生成的 SystemInfo 類
class SystemInfo {
  // 傳統 API (向後兼容)
  static Future<SystemInfo> fetch(UspService usp) async {
    final result = await fetchWithResult(usp);
    return result.when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) => data,
      failure: (errors) => throw UspOperationException(errors),
    );
  }
  
  // 結構化 API (推薦使用)
  static Future<UspGetResult<SystemInfo>> fetchWithResult(UspService usp) async {
    final paths = [
      'Device.DeviceInfo.Manufacturer',
      'Device.DeviceInfo.ModelName',
      // ...
    ];
    
    final result = await usp.getWithResult(paths);
    return result.map((rawData) => SystemInfo.fromMap(rawData));
  }
}
```

### 3. **Provider 層集成策略**

#### 策略 A：錯誤敏感的業務邏輯
```dart
class SystemInfoNotifier extends AsyncNotifier<SystemInfo> {
  @override
  Future<SystemInfo> build() async {
    final usp = ref.watch(uspServiceProvider)!;
    final result = await SystemInfo.fetchWithResult(usp);
    
    return result.when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) {
        // 記錄警告但繼續使用部分資料
        logger.w('SystemInfo 部分成功: ${failures.length} 個參數失敗');
        return data;
      },
      failure: (errors) {
        // 根據業務需求決定錯誤處理策略
        throw UspOperationException(errors);
      },
    );
  }
}
```

#### 策略 B：簡單業務邏輯
```dart
class SimpleDataNotifier extends AsyncNotifier<SimpleData> {
  @override
  Future<SimpleData> build() async {
    final usp = ref.watch(uspServiceProvider)!;
    // 使用傳統 API，codegen 內部處理錯誤
    return SimpleData.fetch(usp);
  }
}
```

### 4. **錯誤處理分層**

#### 業務層錯誤處理
```dart
extension UspResultBusinessLogic<T> on UspOperationResult<T> {
  /// 業務邏輯：允許部分成功，記錄錯誤但不中斷
  T getDataOrPartial({String? context}) {
    return when(
      success: (data, details) => data,
      partialSuccess: (data, successes, failures) {
        logger.w('[$context] 部分成功: ${failures.length} errors');
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
}
```

## 遷移路徑

### Phase 1: 基礎 API 完善
- [ ] 添加 `UspService.getWithResult()`
- [ ] 更新 WASM 層 GET 操作支持結構化回應
- [ ] 更新 codegen 模板生成雙重 API

### Phase 2: 關鍵模組遷移  
- [ ] 系統資訊 (SystemInfo)
- [ ] 設備列表 (ConnectedDevices)
- [ ] Wi-Fi 設定 (WiFiSSIDs)

### Phase 3: 寫入操作統一
- [ ] 確保所有 Provider 使用 `xxxWithResult()` API
- [ ] 統一錯誤處理策略
- [ ] 移除臨時兼容性代碼

### Phase 4: 最佳化與清理
- [ ] 移除傳統扁平 API (可選)
- [ ] 效能最佳化
- [ ] 測試覆蓋率提升

## 決策原則

1. **向後兼容**：現有 Provider 可繼續使用傳統 API
2. **漸進式遷移**：按模組逐步採用結構化 API
3. **業務導向**：錯誤處理策略由業務邏輯決定
4. **完整資訊**：結構化回應保留所有 firmware 資訊
5. **類型安全**：使用 sealed class 確保完整的錯誤處理

## 實施優先級

**High Priority**：
- UspService.getWithResult() 實作
- 寫入操作的 Provider 遷移 (錯誤處理很重要)

**Medium Priority**：  
- 讀取操作的 codegen 雙重 API
- 關鍵業務模組遷移

**Low Priority**：
- 非關鍵模組遷移
- 傳統 API 移除