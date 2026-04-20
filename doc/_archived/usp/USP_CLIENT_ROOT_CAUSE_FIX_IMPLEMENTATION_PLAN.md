# USP Client Root Cause Fix - Implementation Plan

**項目名稱**: USP Client 根本原因修復  
**建立日期**: 2026-04-09  
**文件版本**: 1.0  
**狀態**: Planning Phase  

## 📋 專案概覽

### **問題描述**
當前 usp-client 在 WASM bindgen 和 C FFI 介面層將來自 firmware 的完整結構化回應（SetResponse、AddResponse、DeleteResponse）人為簡化為二元結果（success/failure），導致關鍵資訊遺失：

- 逐參數成功/失敗狀態
- `affected_path`（實際被修改的路徑）  
- `updated_params`（firmware 實際套用的值）
- 個別錯誤碼與訊息
- 部分成功的詳細資訊

### **解決方案架構**
採用三步驟漸進式修復方案：

```
Step 1: usp-client (協議層) → 真實傳遞所有執行結果
Step 2: codegen (代碼生成層) → 使用原生 Map，一次改到位  
Step 3: UspService (應用封裝層) → Map → UspXXXResult 轉換
```

### **核心原則**
1. **Never Lose Information**: 協議層不得遺失任何來自 firmware 的資訊
2. **Clean Architecture**: 各層責任分離，依賴關係清晰
3. **No Backward Compatibility Burden**: codegen 層一次改到位
4. **Type Safety at Application Layer**: 僅在需要的應用層提供強型別封裝

---

## 🔧 Step 1: usp-client 協議層修改

### **1.1 目標與範圍**
- **核心目標**: 修改 WASM bindgen 介面，回傳完整的操作結果
- **工期**: 2 週
- **影響範圍**: `set*`, `add*`, `delete*` 相關函數
- **風險等級**: 🔴 High（影響協議層基礎）

### **1.2 實作清單**

#### **檔案修改**
- `usp-client/src/wasm/mod.rs` - 主要修改目標
- `usp-client/src/lib.rs` - 如需要 export 新函數
- `usp-client/tests/wasm_serialization_tests.rs` - 新增測試檔案
- `usp-client/tests/integration_router_tests.rs` - 新增整合測試

#### **核心實作 - 序列化助手函數**

```rust
// usp-client/src/wasm/mod.rs - 新增的助手函數

/// 序列化 SetResponse 為 JavaScript Object
fn serialize_set_response_to_js(response: &SetResponse) -> Result<JsValue, JsValue> {
    let result_obj = Object::new();
    
    // 基本狀態標誌
    Reflect::set(&result_obj, &"overallSuccess".into(), 
                &JsValue::from_bool(response.is_success()))?;
    Reflect::set(&result_obj, &"hasAnySuccess".into(), 
                &JsValue::from_bool(response.has_any_success()))?;
    Reflect::set(&result_obj, &"hasErrors".into(), 
                &JsValue::from_bool(response.has_errors()))?;
    
    // 詳細結果數組
    let results_array = Array::new();
    for result in response.results() {
        let result_obj = Object::new();
        Reflect::set(&result_obj, &"requestedPath".into(), 
                    &JsValue::from_str(result.requested_path()))?;
        Reflect::set(&result_obj, &"success".into(), 
                    &JsValue::from_bool(result.is_success()))?;
        
        if result.is_success() {
            // 成功情況：詳細的更新實例資訊
            if let Some(instances) = result.updated_instances() {
                let instances_array = Array::new();
                for instance in instances {
                    let inst_obj = Object::new();
                    Reflect::set(&inst_obj, &"affectedPath".into(), 
                                &JsValue::from_str(instance.affected_path()))?;
                    
                    // 更新的參數轉為 JS Object
                    let params_obj = Object::new();
                    for (key, value) in instance.updated_params() {
                        Reflect::set(&params_obj, &JsValue::from_str(key), 
                                    &JsValue::from_str(value))?;
                    }
                    Reflect::set(&inst_obj, &"updatedParams".into(), &params_obj)?;
                    instances_array.push(&inst_obj);
                }
                Reflect::set(&result_obj, &"updatedInstances".into(), &instances_array)?;
            }
        } else {
            // 失敗情況：錯誤代碼和訊息
            if let Some(code) = result.error_code() {
                Reflect::set(&result_obj, &"errorCode".into(), 
                            &JsValue::from_f64(code as f64))?;
            }
            if let Some(msg) = result.error_message() {
                Reflect::set(&result_obj, &"errorMessage".into(), 
                            &JsValue::from_str(msg))?;
            }
        }
        results_array.push(&result_obj);
    }
    Reflect::set(&result_obj, &"results".into(), &results_array)?;
    
    Ok(result_obj.into())
}

/// 類似的 serialize_add_response_to_js() 和 serialize_delete_response_to_js()
```

#### **函數修改範圍**

```rust
// 修改這些 WASM bindgen 函數使用新的序列化助手：

/// set() - 單參數設定
pub fn set(&self, path: String, value: String) -> js_sys::Promise

/// set_multiple() - 多參數設定  
pub fn set_multiple(&self, parameters: JsValue, allow_partial: bool) -> js_sys::Promise

/// add() - 單物件新增
pub fn add(&self, object_path: String, parameters: JsValue) -> js_sys::Promise

/// add_multiple() - 批次新增
pub fn add_multiple(&self, objects: Box<[JsValue]>, allow_partial: bool) -> js_sys::Promise

/// add_multiple_with_timeout() - 帶超時的批次新增
pub fn add_multiple_with_timeout(&self, objects: Box<[JsValue]>, allow_partial: bool, timeout_seconds: u32) -> js_sys::Promise

/// delete_obj() - 單物件刪除
pub fn delete_obj(&self, path: String) -> js_sys::Promise

/// delete_multiple() - 批次刪除
pub fn delete_multiple(&self, paths: Box<[JsValue]>, allow_partial: bool) -> js_sys::Promise
```

### **1.3 測試策略**

#### **單元測試**
```rust
// usp-client/tests/wasm_serialization_tests.rs

#[cfg(test)]
mod tests {
    use super::*;
    use wasm_bindgen_test::*;
    
    #[wasm_bindgen_test]
    fn test_serialize_set_response_success() {
        let response = create_mock_set_response_success();
        let js_result = serialize_set_response_to_js(&response).unwrap();
        
        // 驗證 JavaScript 物件結構
        let obj = js_result.dyn_into::<Object>().unwrap();
        
        // 檢查基本標誌
        let overall_success = Reflect::get(&obj, &"overallSuccess".into()).unwrap();
        assert_eq!(overall_success.as_bool().unwrap(), true);
        
        // 檢查結果數組
        let results = Reflect::get(&obj, &"results".into()).unwrap();
        let results_array = results.dyn_into::<Array>().unwrap();
        assert_eq!(results_array.length(), 1);
    }
    
    #[wasm_bindgen_test] 
    fn test_serialize_set_response_partial_failure() {
        let response = create_mock_set_response_partial_failure();
        let js_result = serialize_set_response_to_js(&response).unwrap();
        
        let obj = js_result.dyn_into::<Object>().unwrap();
        
        let overall_success = Reflect::get(&obj, &"overallSuccess".into()).unwrap();
        assert_eq!(overall_success.as_bool().unwrap(), false);
        
        let has_any_success = Reflect::get(&obj, &"hasAnySuccess".into()).unwrap();
        assert_eq!(has_any_success.as_bool().unwrap(), true);
        
        let has_errors = Reflect::get(&obj, &"hasErrors".into()).unwrap();
        assert_eq!(has_errors.as_bool().unwrap(), true);
    }
}
```

#### **整合測試**
```rust
// usp-client/tests/integration_router_tests.rs

#[cfg(test)]
mod integration_tests {
    #[tokio::test]
    async fn test_set_with_real_router_success() {
        let router_url = std::env::var("TEST_ROUTER_URL")
            .unwrap_or_else(|_| "https://192.168.1.1".to_string());
        let password = std::env::var("TEST_ROUTER_PASSWORD")
            .unwrap_or_else(|_| "admin".to_string());
        
        let client = UspClient::new(&router_url).unwrap();
        client.login(&password).await.unwrap();
        
        let result = client.set(
            "Device.WiFi.SSID.1.SSID".to_string(), 
            "TestNetwork123".to_string()
        ).await;
        
        assert!(result.is_ok(), "Set operation should succeed");
    }
    
    #[tokio::test] 
    async fn test_set_multiple_partial_failure_with_real_router() {
        let client = setup_authenticated_client().await;
        
        let mut params = std::collections::HashMap::new();
        params.insert("Device.WiFi.SSID.1.SSID".to_string(), "ValidSSID".to_string());
        params.insert("Device.Invalid.Path.Value".to_string(), "ShouldFail".to_string());
        
        let result = client.set_multiple_with_options(params, true).await;
        assert!(result.is_ok(), "Partial failure should still return result");
    }
}
```

### **1.4 建置與封裝**
```bash
# WASM 建置
wasm-pack build --target web --out-dir pkg

# 驗證二進制大小
ls -la pkg/usp_client_bg.wasm

# 執行測試
wasm-pack test --headless --chrome
```

---

## 🏗️ Step 2: codegen 模板全面改版

### **2.1 目標與範圍**
- **核心目標**: 生成的 API 直接回傳 Map，無向後相容包袱
- **工期**: 1 週（在 Step 1 完成後）
- **影響範圍**: 所有 Dart 代碼生成模板
- **風險等級**: 🟡 Medium

### **2.2 模板修改**

#### **主要模板檔案**
`usp-codegen/include/dart_templates.h`

```cpp
/**
 * Dart save method template - returns detailed operation Map
 */
static const char *DART_SAVE_METHOD_TEMPLATE =
"/// ${DESCRIPTION}\n"
"/// Returns Map with detailed operation result:\n"
"/// {\n"
"///   'overallSuccess': bool,\n"
"///   'hasAnySuccess': bool, \n"
"///   'hasErrors': bool,\n"
"///   'results': [{\n"
"///     'requestedPath': String,\n"
"///     'success': bool,\n"
"///     'updatedInstances': [...] | 'errorCode': int, 'errorMessage': String\n"
"///   }]\n" 
"/// }\n"
"static Future<Map<String, dynamic>> save(UspService client, {\n"
"${PARAMETERS}"
"}) async {\n"
"  final params = <String, dynamic>{};\n"
"${PARAM_MAPPINGS}"
"  if (params.isEmpty) {\n"
"    return {\n"
"      'overallSuccess': true,\n"
"      'hasAnySuccess': false,\n"
"      'hasErrors': false,\n"
"      'results': <Map<String, dynamic>>[],\n"
"    };\n"
"  }\n"
"  return await client.setMultiple(params, allowPartial: false);\n"
"}\n";

/**
 * Dart update method template
 */
static const char *DART_UPDATE_METHOD_TEMPLATE =
"/// Update a single instance - returns operation result Map\n"
"static Future<Map<String, dynamic>> update(UspService client, ${UPDATE_CLASS} update) async {\n"
"  final params = <String, dynamic>{};\n"
"${UPDATE_MAPPINGS}"
"  if (params.isEmpty) {\n"
"    return {'overallSuccess': true, 'hasAnySuccess': false, 'hasErrors': false, 'results': []};\n"
"  }\n"
"  return await client.setMultiple(params, allowPartial: false);\n"
"}\n";

/**
 * Dart batch update method template
 */
static const char *DART_UPDATE_BATCH_METHOD_TEMPLATE =
"/// Update multiple ${CLASS_NAME} instances with partial success support\n"
"/// Returns detailed operation result Map\n"
"static Future<Map<String, dynamic>> updateMany(\n"
"    UspService client,\n"
"    List<${UPDATE_CLASS}> updates,\n"
"    {bool allowPartial = false}\n"
") async {\n"
"  final params = <String, dynamic>{};\n"
"  for (final update in updates) {\n"
"${UPDATE_MAPPINGS_LOOP}"
"  }\n"
"  if (params.isEmpty) {\n"
"    return {'overallSuccess': true, 'hasAnySuccess': false, 'hasErrors': false, 'results': []};\n"
"  }\n"
"  return await client.setMultiple(params, allowPartial: allowPartial);\n"
"}\n";

/**
 * Dart add method template
 */
static const char *DART_ADD_METHOD_TEMPLATE =
"/// Add new ${CLASS_NAME} instance - returns operation result Map\n"
"static Future<Map<String, dynamic>> add(UspService client, {\n"
"${ADD_PARAMETERS}"
"}) async {\n"
"  final params = <String, dynamic>{};\n"
"${ADD_MAPPINGS}"
"  return await client.add('${OBJECT_PATH}', params);\n"
"}\n";

/**
 * Dart delete method template
 */
static const char *DART_DELETE_METHOD_TEMPLATE =
"/// Delete ${CLASS_NAME} instance - returns operation result Map\n"
"static Future<Map<String, dynamic>> delete(UspService client, String instancePath) async {\n"
"  return await client.delete(instancePath);\n"
"}\n";
```

### **2.3 生成程式碼範例**

```dart
// 預期生成的 wifi_settings.g.dart
import '../../stubs/dart/usp_service.dart';

class WifiSettings {
  final String ssid;
  final bool enabled;
  final String macAddress;
  final String securityMode;
  final String passphrase;

  const WifiSettings({
    required this.ssid,
    required this.enabled,
    required this.macAddress,
    required this.securityMode,
    required this.passphrase,
  });

  /// Update WiFi settings
  /// Returns Map with detailed operation result
  static Future<Map<String, dynamic>> save(UspService client, {
    String? ssid,
    bool? enabled,
    String? securityMode,
    String? passphrase,
  }) async {
    final params = <String, dynamic>{};
    if (ssid != null) params['Device.WiFi.SSID.1.SSID'] = ssid;
    if (enabled != null) params['Device.WiFi.SSID.1.Enable'] = enabled;
    if (securityMode != null) params['Device.WiFi.AccessPoint.1.Security.ModeEnabled'] = securityMode;
    if (passphrase != null) params['Device.WiFi.AccessPoint.1.Security.KeyPassphrase'] = passphrase;
    
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

### **2.4 測試策略**

```dart
// test/generated_code_test.dart

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import '../lib/generated/wifi_settings.g.dart';
import '../lib/core/usp/services/usp_service.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  group('Generated WifiSettings', () {
    late MockUspService mockUspService;
    
    setUp(() {
      mockUspService = MockUspService();
    });
    
    test('save() returns correct Map structure for successful operation', () async {
      final expectedResult = {
        'overallSuccess': true,
        'hasAnySuccess': true,
        'hasErrors': false,
        'results': [
          {
            'requestedPath': 'Device.WiFi.SSID.1.SSID',
            'success': true,
            'updatedInstances': [
              {
                'affectedPath': 'Device.WiFi.SSID.1.',
                'updatedParams': {'SSID': 'NewNetworkName'}
              }
            ]
          }
        ]
      };
      
      when(mockUspService.setMultiple(any, allowPartial: false))
          .thenAnswer((_) async => expectedResult);
      
      final result = await WifiSettings.save(
        mockUspService,
        ssid: 'NewNetworkName',
      );
      
      expect(result['overallSuccess'], true);
      expect(result['hasAnySuccess'], true);
      expect(result['hasErrors'], false);
      expect(result['results'], isA<List>());
      expect(result['results'].length, 1);
    });
    
    test('save() handles partial failure correctly', () async {
      final partialFailureResult = {
        'overallSuccess': false,
        'hasAnySuccess': true,
        'hasErrors': true,
        'results': [
          {
            'requestedPath': 'Device.WiFi.SSID.1.SSID',
            'success': true,
            'updatedInstances': [/* ... */]
          },
          {
            'requestedPath': 'Device.Invalid.Parameter',
            'success': false,
            'errorCode': 7004,
            'errorMessage': 'Parameter not writable'
          }
        ]
      };
      
      when(mockUspService.setMultiple(any, allowPartial: true))
          .thenAnswer((_) async => partialFailureResult);
      
      // 驗證測試邏輯...
    });
  });
}
```

---

## 📦 Step 3: UspService 應用封裝層

### **3.1 目標與範圍**
- **核心目標**: 提供類型安全的應用層 API，Map ↔ UspXXXResult 轉換
- **工期**: 1 週（在 Step 2 完成後）
- **影響範圍**: UspService 和相關資料模型
- **風險等級**: 🟢 Low

### **3.2 資料模型**

```dart
// lib/core/usp/models/usp_operation_result.dart

/// Base class for all USP operation results
abstract class UspOperationResult {
  final bool overallSuccess;
  final bool hasAnySuccess;
  final bool hasErrors;
  
  const UspOperationResult({
    required this.overallSuccess,
    required this.hasAnySuccess,
    required this.hasErrors,
  });
  
  /// Returns true if operation should be considered successful based on context
  bool isSuccessfulInContext({bool allowPartial = false}) {
    return allowPartial ? hasAnySuccess : overallSuccess;
  }
}

/// Result of a USP Set operation
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
  
  factory UspSetResult.empty() {
    return const UspSetResult(
      overallSuccess: true,
      hasAnySuccess: false,
      hasErrors: false,
      results: [],
    );
  }
  
  /// Returns human-readable error summary
  String getErrorSummary() {
    final errors = results
        .where((r) => !r.success)
        .map((r) => '${r.requestedPath}: ${r.errorMessage ?? "Unknown error"}')
        .toList();
    return errors.isEmpty ? 'No errors' : errors.join('; ');
  }
  
  /// Returns all successfully updated instances
  List<UspUpdatedInstance> getSuccessfulUpdates() {
    return results
        .where((r) => r.success)
        .expand((r) => r.updatedInstances ?? <UspUpdatedInstance>[])
        .toList();
  }
}

/// Individual parameter result in a Set operation
class UspSetParameterResult {
  final String requestedPath;
  final bool success;
  final List<UspUpdatedInstance>? updatedInstances;
  final int? errorCode;
  final String? errorMessage;
  
  const UspSetParameterResult({
    required this.requestedPath,
    required this.success,
    this.updatedInstances,
    this.errorCode,
    this.errorMessage,
  });
  
  factory UspSetParameterResult.fromMap(Map<String, dynamic> map) {
    return UspSetParameterResult(
      requestedPath: map['requestedPath'] as String,
      success: map['success'] as bool,
      updatedInstances: map['updatedInstances'] != null
          ? (map['updatedInstances'] as List<dynamic>)
              .map((i) => UspUpdatedInstance.fromMap(i as Map<String, dynamic>))
              .toList()
          : null,
      errorCode: map['errorCode'] as int?,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}

/// Information about an updated instance
class UspUpdatedInstance {
  final String affectedPath;
  final Map<String, String> updatedParams;
  
  const UspUpdatedInstance({
    required this.affectedPath,
    required this.updatedParams,
  });
  
  factory UspUpdatedInstance.fromMap(Map<String, dynamic> map) {
    return UspUpdatedInstance(
      affectedPath: map['affectedPath'] as String,
      updatedParams: Map<String, String>.from(map['updatedParams']),
    );
  }
}

// 類似的 UspAddResult 和 UspDeleteResult 類別...
```

### **3.3 UspService 增強**

```dart
// lib/core/usp/services/usp_service.dart

class UspService {
  final UspClientWeb _client;
  
  // 原始 Map-based 方法（供 codegen 使用）
  Future<Map<String, dynamic>> setMultiple(
    Map<String, dynamic> parameters, 
    {bool allowPartial = false}
  ) async {
    return await _withAuthRetry(() async {
      final jsResult = await _client.setMultiple(
        jsObjectFromMap(parameters), 
        allowPartial: allowPartial
      );
      return dartObjectFromJs(jsResult);
    });
  }
  
  Future<Map<String, dynamic>> add(String objectPath, Map<String, String> params) async {
    return await _withAuthRetry(() async {
      final jsResult = await _client.add(objectPath, jsObjectFromMap(params));
      return dartObjectFromJs(jsResult);
    });
  }
  
  Future<Map<String, dynamic>> delete(String instancePath) async {
    return await _withAuthRetry(() async {
      final jsResult = await _client.delete(instancePath);
      return dartObjectFromJs(jsResult);
    });
  }
  
  // 應用層封裝方法（供 Service/Provider 層使用）
  Future<UspSetResult> setWithResult(
    Map<String, dynamic> parameters,
    {bool allowPartial = false}
  ) async {
    try {
      final resultMap = await setMultiple(parameters, allowPartial: allowPartial);
      return UspSetResult.fromMap(resultMap);
    } catch (e) {
      return UspSetResult(
        overallSuccess: false,
        hasAnySuccess: false,
        hasErrors: true,
        results: [
          UspSetParameterResult(
            requestedPath: 'Unknown',
            success: false,
            errorCode: -1,
            errorMessage: e.toString(),
          )
        ],
      );
    }
  }
  
  Future<UspAddResult> addWithResult(String objectPath, Map<String, String> params) async {
    try {
      final resultMap = await add(objectPath, params);
      return UspAddResult.fromMap(resultMap);
    } catch (e) {
      // 錯誤處理邏輯...
    }
  }
  
  Future<UspDeleteResult> deleteWithResult(String instancePath) async {
    try {
      final resultMap = await delete(instancePath);
      return UspDeleteResult.fromMap(resultMap);
    } catch (e) {
      // 錯誤處理邏輯...
    }
  }
}
```

### **3.4 測試策略**

```dart
// test/usp_service_enhanced_test.dart

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import '../lib/core/usp/services/usp_service.dart';
import '../lib/core/usp/models/usp_operation_result.dart';

class MockUspClientWeb extends Mock implements UspClientWeb {}

void main() {
  group('Enhanced UspService', () {
    late UspService uspService;
    late MockUspClientWeb mockClient;
    
    setUp(() {
      mockClient = MockUspClientWeb();
      uspService = UspService(mockClient);
    });
    
    test('setWithResult() converts successful Map to UspSetResult', () async {
      final mockMap = {
        'overallSuccess': true,
        'hasAnySuccess': true,
        'hasErrors': false,
        'results': [
          {
            'requestedPath': 'Device.WiFi.SSID.1.SSID',
            'success': true,
            'updatedInstances': [
              {
                'affectedPath': 'Device.WiFi.SSID.1.',
                'updatedParams': {'SSID': 'TestNetwork'}
              }
            ]
          }
        ]
      };
      
      // Mock 設定...
      when(uspService.setMultiple(any, allowPartial: false))
          .thenAnswer((_) async => mockMap);
      
      final result = await uspService.setWithResult(
        {'Device.WiFi.SSID.1.SSID': 'TestNetwork'},
        allowPartial: false,
      );
      
      // 驗證轉換結果...
      expect(result.overallSuccess, true);
      expect(result.hasAnySuccess, true);
      expect(result.hasErrors, false);
      expect(result.results.length, 1);
    });
  });
}
```

---

## 📊 實施時程與里程碑

### **時程規劃**

| 階段 | 工期 | 開始日期 | 結束日期 | 依賴關係 |
|------|------|----------|----------|----------|
| Step 1: Protocol Layer | 2 週 | Week 1 | Week 2 | None |
| Step 2: Codegen Overhaul | 1 週 | Week 3 | Week 3 | Step 1 完成 |
| Step 3: Application Layer | 1 週 | Week 4 | Week 4 | Step 2 完成 |
| Integration & Testing | 3 天 | Week 4 後半 | Week 5 前半 | All steps 完成 |

### **里程碑定義**

| 里程碑 | 完成標準 | 驗證方式 |
|--------|----------|----------|
| **M1: Protocol Layer Complete** | Step 1 所有任務完成，測試通過 | WASM 測試套件 + 路由器整合測試 |
| **M2: Codegen Overhaul Complete** | Step 2 完成，新程式碼編譯無誤 | 生成程式碼編譯測試 + 結構驗證 |
| **M3: Application Layer Complete** | Step 3 完成，端到端測試通過 | 完整的應用層測試套件 |
| **M4: System Integration** | 所有層級整合，真實路由器測試通過 | 端到端真實環境測試 |

### **關鍵成功因素**

1. **測試覆蓋率**: 每個階段達到指定的測試覆蓋率目標
2. **向上相容**: 確保修改不破壞現有功能
3. **效能基準**: 新實作不得顯著影響效能
4. **文件完整**: 每個階段提供完整的技術文件

---

## ⚠️ 風險管控

### **技術風險**

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|----------|
| WASM 編譯問題 | Medium | High | 提前建立測試環境，逐步驗證編譯流程 |
| JavaScript 序列化效能問題 | Low | Medium | 建立效能基準測試，持續監控 |
| 路由器韌體相容性 | Medium | High | 多型號路由器測試，建立相容性矩陣 |
| 記憶體使用量增加 | Low | Medium | 監控 WASM 二進制大小，優化序列化邏輯 |

### **專案風險**

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|----------|
| 測試環境不足 | Medium | High | 提前準備多台測試路由器，建立自動化測試環境 |
| 時程延誤 | Low | Medium | 保守估計工期，預留緩衝時間 |
| 團隊知識缺口 | Low | High | 技術文件詳細記錄，知識轉移會議 |

### **品質保證**

| 品質指標 | 目標值 | 測量方式 |
|----------|--------|----------|
| 測試覆蓋率 | >90% | 自動化覆蓋率報告 |
| 編譯成功率 | 100% | CI/CD 管道驗證 |
| 整合測試通過率 | >95% | 自動化測試套件 |
| 效能回歸 | <5% | 基準測試比較 |

---

## 📋 可交付成果

### **Step 1 交付物**

| 檔案 | 內容 | 測試覆蓋率 |
|------|------|------------|
| `usp-client/src/wasm/mod.rs` | 修改後的 WASM 介面 | N/A |
| `usp-client/tests/wasm_serialization_tests.rs` | 序列化函數單元測試 | 95%+ |
| `usp-client/tests/integration_router_tests.rs` | 路由器整合測試 | 80%+ |
| `docs/step1_implementation_guide.md` | 實作指南與架構說明 | N/A |
| `pkg/usp_client_bg.wasm` | 建置後的 WASM 二進制 | N/A |

### **Step 2 交付物**

| 檔案 | 內容 | 測試覆蓋率 |
|------|------|------------|
| `usp-codegen/include/dart_templates.h` | 更新的模板定義 | N/A |
| `examples/generated/dart/*.g.dart` | 重新生成的範例程式碼 | N/A |
| `test/generated_code_test.dart` | 生成程式碼測試 | 90%+ |
| `test/template_validation_test.dart` | 模板驗證測試 | 95%+ |
| `docs/step2_codegen_changes.md` | 代碼生成變更說明 | N/A |

### **Step 3 交付物**

| 檔案 | 內容 | 測試覆蓋率 |
|------|------|------------|
| `lib/core/usp/models/usp_operation_result.dart` | 結果資料模型 | 95%+ |
| `lib/core/usp/services/usp_service.dart` | 增強的 UspService | 90%+ |
| `test/usp_service_enhanced_test.dart` | UspService 測試 | 95%+ |
| `test/usp_operation_result_test.dart` | 資料模型測試 | 95%+ |
| `test/end_to_end_integration_test.dart` | 端到端測試 | 80%+ |
| `docs/step3_application_layer_guide.md` | 應用層使用指南 | N/A |

### **整合交付物**

| 檔案 | 內容 |
|------|------|
| `docs/MIGRATION_GUIDE.md` | 完整的遷移指南 |
| `docs/API_REFERENCE.md` | 新 API 參考文件 |
| `docs/TROUBLESHOOTING.md` | 常見問題排解 |
| `docs/PERFORMANCE_ANALYSIS.md` | 效能分析報告 |
| `CHANGELOG.md` | 詳細的變更記錄 |

---

## 🏁 專案成功定義

### **主要成功指標**

1. **功能完整性**: 所有原有功能保持正常運作
2. **資訊保全性**: 來自 firmware 的所有結構化資訊都能完整傳遞到應用層
3. **錯誤精確性**: 能夠精確區分完全成功、部分成功、完全失敗等情境
4. **效能穩定性**: 新實作的效能不得比原版本退化超過 5%
5. **測試覆蓋率**: 所有關鍵路徑達到 90%+ 的測試覆蓋率

### **驗收標準**

1. **協議層驗收**: WASM 介面能正確序列化所有 SetResponse/AddResponse/DeleteResponse 結構
2. **代碼生成驗收**: 生成的所有 `.g.dart` 檔案都能編譯通過，且回傳正確的 Map 結構
3. **應用層驗收**: UspXXXResult 類別能正確解析所有可能的操作結果
4. **整合驗收**: 端到端測試能在真實路由器環境下通過所有測試案例
5. **回歸驗收**: 現有的所有功能和測試都不得被破壞

---

**文件建立者**: Development Team  
**最後更新**: 2026-04-09  
**核准狀態**: Pending Review