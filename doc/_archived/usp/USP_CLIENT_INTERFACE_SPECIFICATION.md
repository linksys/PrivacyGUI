# USP Client Interface Specification

**版本**: 1.0  
**日期**: 2026-04-09  
**狀態**: Draft  
**作用**: Step 1 (usp-client) 和 Step 2 (codegen) 之間的介面契約

## 📋 文件目的

本文件定義了 USP Client 根本修復中各層級之間的精確介面規範，確保：

1. **Step 1 (WASM 層)** 產生的 JavaScript 物件結構
2. **Step 2 (Codegen 層)** 使用的 Dart Map 格式
3. **Step 3 (Application 層)** 的強型別 UspXXXResult 類別

## 🎯 核心設計原則

### **資訊完整性原則**
- **Never Lose Information**: 任何來自 firmware 的結構化資訊都不得遺失
- **Structured Propagation**: 每一層都保持資訊的結構化傳遞
- **Error Granularity**: 錯誤資訊必須精確到參數層級

### **介面一致性原則**
- **Uniform Structure**: 所有操作類型（Set/Add/Delete）使用一致的回應結構
- **Predictable Naming**: 欄位命名遵循一致的 camelCase 慣例
- **Type Safety**: 每個欄位都有明確的型別定義

---

## 🔧 Step 1: WASM 層介面規範

### **1.1 JavaScript 物件結構定義**

#### **通用回應結構**
```typescript
interface UspOperationResult {
  // 基本狀態標誌
  overallSuccess: boolean;    // 是否整體成功（所有操作都成功）
  hasAnySuccess: boolean;     // 是否有任何成功操作
  hasErrors: boolean;         // 是否包含錯誤
  
  // 詳細結果數組
  results: UspParameterResult[];
}

interface UspParameterResult {
  requestedPath: string;      // 請求的路徑或物件
  success: boolean;           // 此參數/物件的操作是否成功
  
  // 成功時包含的資訊（互斥）
  updatedInstances?: UspUpdatedInstance[];
  createdInstances?: UspCreatedInstance[];
  deletedInstances?: UspDeletedInstance[];
  
  // 失敗時包含的資訊
  errorCode?: number;         // USP 錯誤代碼
  errorMessage?: string;      // 人類可讀的錯誤訊息
}

interface UspUpdatedInstance {
  affectedPath: string;                    // 實際被影響的實例路徑
  updatedParams: Record<string, string>;   // 實際被更新的參數
}

interface UspCreatedInstance {
  affectedPath: string;                    // 新建立的實例路徑
  initialParams: Record<string, string>;   // 建立時設定的參數
}

interface UspDeletedInstance {
  affectedPath: string;                    // 被刪除的實例路徑
}
```

### **1.2 操作特定介面**

#### **SET 操作回應**
```typescript
// JavaScript: client.setMultiple(params, allowPartial) 回傳
interface SetOperationResult extends UspOperationResult {
  results: Array<{
    requestedPath: string;        // e.g., "Device.WiFi.SSID.1.SSID"
    success: boolean;
    updatedInstances?: Array<{
      affectedPath: string;       // e.g., "Device.WiFi.SSID.1."
      updatedParams: Record<string, string>; // e.g., {"SSID": "MyNetwork"}
    }>;
    errorCode?: number;           // e.g., 7004
    errorMessage?: string;        // e.g., "Parameter not writable"
  }>;
}
```

#### **ADD 操作回應**
```typescript
// JavaScript: client.add(objectPath, params) 回傳
interface AddOperationResult extends UspOperationResult {
  results: Array<{
    requestedPath: string;        // e.g., "Device.NAT.PortMapping."
    success: boolean;
    createdInstances?: Array<{
      affectedPath: string;       // e.g., "Device.NAT.PortMapping.3."
      initialParams: Record<string, string>; // 建立時的參數
    }>;
    errorCode?: number;
    errorMessage?: string;
  }>;
}
```

#### **DELETE 操作回應**
```typescript
// JavaScript: client.delete(instancePath) 回傳
interface DeleteOperationResult extends UspOperationResult {
  results: Array<{
    requestedPath: string;        // e.g., "Device.NAT.PortMapping.3."
    success: boolean;
    deletedInstances?: Array<{
      affectedPath: string;       // e.g., "Device.NAT.PortMapping.3."
    }>;
    errorCode?: number;
    errorMessage?: string;
  }>;
}
```

### **1.3 WASM 函數簽名**

```rust
// 修改後的 WASM bindgen 函數必須回傳結構化結果
#[wasm_bindgen]
impl UspClient {
    pub fn set(&self, path: String, value: String) -> js_sys::Promise;
    //         ↑ Promise<SetOperationResult>
    
    pub fn set_multiple(&self, parameters: JsValue, allow_partial: bool) -> js_sys::Promise;
    //                  ↑ Promise<SetOperationResult>
    
    pub fn add(&self, object_path: String, parameters: JsValue) -> js_sys::Promise;
    //         ↑ Promise<AddOperationResult>
    
    pub fn delete_obj(&self, path: String) -> js_sys::Promise;
    //               ↑ Promise<DeleteOperationResult>
}
```

---

## 🏗️ Step 2: Codegen 層介面規範

### **2.1 Dart Map 結構定義**

#### **通用 Map 結構**
```dart
// 所有生成的方法都回傳此格式的 Map
typedef UspOperationResultMap = Map<String, dynamic>;

// 結構定義：
{
  'overallSuccess': bool,
  'hasAnySuccess': bool,
  'hasErrors': bool,
  'results': List<Map<String, dynamic>>  // UspParameterResultMap[]
}

typedef UspParameterResultMap = Map<String, dynamic>;
// 結構定義：
{
  'requestedPath': String,
  'success': bool,
  
  // 成功時（根據操作類型選一）
  'updatedInstances'?: List<Map<String, dynamic>>,
  'createdInstances'?: List<Map<String, dynamic>>,
  'deletedInstances'?: List<Map<String, dynamic>>,
  
  // 失敗時
  'errorCode'?: int,
  'errorMessage'?: String,
}

// Instance Map 結構
{
  'affectedPath': String,
  'updatedParams'?: Map<String, String>,   // SET 時使用
  'initialParams'?: Map<String, String>,   // ADD 時使用
}
```

### **2.2 生成的方法簽名**

#### **SET 操作方法**
```dart
// WiFi Settings 範例
class WifiSettings {
  /// 更新 WiFi 設定 - 回傳詳細操作結果
  static Future<Map<String, dynamic>> save(UspService client, {
    String? ssid,
    bool? enabled,
    String? securityMode,
    String? passphrase,
  }) async {
    final params = <String, dynamic>{};
    if (ssid != null) params['Device.WiFi.SSID.1.SSID'] = ssid;
    if (enabled != null) params['Device.WiFi.SSID.1.Enable'] = enabled;
    // ...
    
    if (params.isEmpty) {
      return {
        'overallSuccess': true,
        'hasAnySuccess': false,
        'hasErrors': false,
        'results': <Map<String, dynamic>>[],
      };
    }
    
    return await client.setMultiple(params, allowPartial: false);
  }
}
```

#### **ADD 操作方法**
```dart
// Port Forwarding 範例
class PortForwardingRules {
  /// 新增 Port Forwarding 規則 - 回傳建立結果
  static Future<Map<String, dynamic>> add(UspService client, {
    required String protocol,
    required int externalPort,
    required int internalPort,
    required String internalClient,
    bool? enabled,
    String? description,
  }) async {
    final params = <String, dynamic>{};
    params['Protocol'] = protocol;
    params['ExternalPort'] = externalPort;
    // ...
    
    return await client.add('Device.NAT.PortMapping.', params);
  }
}
```

#### **DELETE 操作方法**
```dart
class PortForwardingRules {
  /// 刪除 Port Forwarding 規則 - 回傳刪除結果
  static Future<Map<String, dynamic>> delete(UspService client, String instancePath) async {
    return await client.delete(instancePath);
  }
}
```

### **2.3 批次操作支援**

```dart
// 批次更新方法
class PortForwardingRules {
  /// 批次更新多個 Port Forwarding 規則
  static Future<Map<String, dynamic>> updateMany(
    UspService client,
    List<PortForwardingRuleUpdate> updates,
    {bool allowPartial = false}
  ) async {
    final params = <String, dynamic>{};
    for (final update in updates) {
      if (update.enabled != null) {
        params['${update.instancePath}Enable'] = update.enabled;
      }
      // ...
    }
    
    if (params.isEmpty) {
      return _emptySuccessResult();
    }
    
    return await client.setMultiple(params, allowPartial: allowPartial);
  }
  
  // 空結果的標準格式
  static Map<String, dynamic> _emptySuccessResult() {
    return {
      'overallSuccess': true,
      'hasAnySuccess': false,
      'hasErrors': false,
      'results': <Map<String, dynamic>>[],
    };
  }
}
```

---

## 📦 Step 3: Application 層介面規範

### **3.1 UspService 增強介面**

```dart
class UspService {
  // 原始 Map-based 方法（供 codegen 使用）
  Future<Map<String, dynamic>> setMultiple(
    Map<String, dynamic> parameters,
    {bool allowPartial = false}
  );
  
  Future<Map<String, dynamic>> add(
    String objectPath,
    Map<String, String> params
  );
  
  Future<Map<String, dynamic>> delete(String instancePath);
  
  // 應用層封裝方法（供 Service/Provider 層使用）
  Future<UspSetResult> setWithResult(
    Map<String, dynamic> parameters,
    {bool allowPartial = false}
  );
  
  Future<UspAddResult> addWithResult(
    String objectPath,
    Map<String, String> params
  );
  
  Future<UspDeleteResult> deleteWithResult(String instancePath);
}
```

### **3.2 強型別結果類別**

```dart
abstract class UspOperationResult {
  final bool overallSuccess;
  final bool hasAnySuccess;
  final bool hasErrors;
  
  const UspOperationResult({
    required this.overallSuccess,
    required this.hasAnySuccess,
    required this.hasErrors,
  });
  
  bool isSuccessfulInContext({bool allowPartial = false}) {
    return allowPartial ? hasAnySuccess : overallSuccess;
  }
}

class UspSetResult extends UspOperationResult {
  final List<UspSetParameterResult> results;
  
  const UspSetResult({
    required super.overallSuccess,
    required super.hasAnySuccess,
    required super.hasErrors,
    required this.results,
  });
  
  factory UspSetResult.fromMap(Map<String, dynamic> map) {
    return UspSetResult(
      overallSuccess: map['overallSuccess'] as bool,
      hasAnySuccess: map['hasAnySuccess'] as bool,
      hasErrors: map['hasErrors'] as bool,
      results: (map['results'] as List<dynamic>)
          .map((r) => UspSetParameterResult.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }
  
  String getErrorSummary() {
    final errors = results
        .where((r) => !r.success)
        .map((r) => '${r.requestedPath}: ${r.errorMessage ?? "Unknown error"}')
        .toList();
    return errors.isEmpty ? 'No errors' : errors.join('; ');
  }
  
  List<UspUpdatedInstance> getSuccessfulUpdates() {
    return results
        .where((r) => r.success)
        .expand((r) => r.updatedInstances ?? <UspUpdatedInstance>[])
        .toList();
  }
}
```

---

## 🧪 測試規範

### **4.1 介面一致性測試**

```dart
// 每個層級都必須通過的一致性測試
void testInterfaceConsistency() {
  group('Interface Consistency Tests', () {
    test('WASM → Dart Map conversion maintains structure', () async {
      final jsResult = await wasmClient.setMultiple(testParams);
      final dartMap = convertJsToDartMap(jsResult);
      
      expect(dartMap['overallSuccess'], isA<bool>());
      expect(dartMap['hasAnySuccess'], isA<bool>());
      expect(dartMap['hasErrors'], isA<bool>());
      expect(dartMap['results'], isA<List>());
    });
    
    test('Dart Map → UspXXXResult conversion preserves data', () {
      final testMap = createTestResultMap();
      final result = UspSetResult.fromMap(testMap);
      
      expect(result.overallSuccess, testMap['overallSuccess']);
      expect(result.results.length, testMap['results'].length);
    });
  });
}
```

### **4.2 邊界條件測試規範**

```dart
// 必須支援的邊界條件
void testBoundaryConditions() {
  group('Boundary Conditions', () {
    test('Empty parameters return empty success result', () async {
      final result = await WifiSettings.save(client);
      
      expect(result['overallSuccess'], true);
      expect(result['hasAnySuccess'], false);
      expect(result['hasErrors'], false);
      expect(result['results'], isEmpty);
    });
    
    test('Partial failure scenarios are handled correctly', () {
      // 測試部分成功的情況
    });
    
    test('Complete failure scenarios provide detailed errors', () {
      // 測試完全失敗的情況
    });
  });
}
```

---

## 🔄 版本相容性規範

### **5.1 向前相容性**

- **新增欄位**: 可以在結構中新增可選欄位
- **欄位重新命名**: 必須維護別名映射
- **錯誤代碼**: 新的錯誤代碼必須有明確的語義定義

### **5.2 破壞性變更警告**

以下變更被視為破壞性變更，需要主版本號升級：

- 移除現有欄位
- 改變欄位型別（如 `string` → `number`）
- 改變必填欄位為可選，或反之
- 改變陣列結構

---

## 📋 實施檢查清單

### **Step 1 實施前檢查**
- [ ] WASM 序列化函數產生正確的 JavaScript 物件結構
- [ ] 所有欄位名稱符合 camelCase 慣例
- [ ] TypeScript 介面定義與實際物件結構一致
- [ ] 邊界條件（空參數、錯誤情況）正確處理

### **Step 2 實施前檢查**
- [ ] Codegen 模板產生正確的 Dart Map 結構
- [ ] 空參數情況回傳標準的空成功結果
- [ ] 批次操作支援 `allowPartial` 參數
- [ ] 生成的方法簽名與規範一致

### **Step 3 實施前檢查**
- [ ] Map → UspXXXResult 轉換無資料遺失
- [ ] 所有輔助方法（如 `getErrorSummary()`）正常運作
- [ ] 異常處理正確轉換為結果物件
- [ ] 強型別介面與 Map 結構完全對應

---

## ⚠️ 關鍵注意事項

### **資料型別規範**
- **JavaScript 數字**: 在 Dart 中統一處理為 `num`，需要時轉換
- **空值處理**: `undefined` 在 Dart 中對應 `null`
- **陣列**: JavaScript `Array` 對應 Dart `List<dynamic>`
- **物件**: JavaScript `Object` 對應 Dart `Map<String, dynamic>`

### **錯誤處理原則**
- **永不吞噬異常**: 所有異常都要轉換為結構化錯誤資訊
- **錯誤層級**: 區分協議層錯誤、網路錯誤、應用層錯誤
- **錯誤追蹤**: 保留完整的錯誤追蹤鏈

### **效能考量**
- **序列化開銷**: WASM ↔ JavaScript 序列化不應該顯著影響效能
- **記憶體使用**: 避免不必要的深拷貝
- **快取策略**: 相同的錯誤訊息可以考慮快取

---

**文件狀態**: Draft  
**需要確認**: Step 1 和 Step 2 開發團隊  
**預期完成**: 介面規範確認後即可開始平行開發