# USP Client v0.11.0 結構化回應 - Dart/Flutter 實作計劃

**專案名稱**: USP Client v0.11.0 Dart 層實作  
**建立日期**: 2026-04-09  
**文件版本**: 1.0  
**狀態**: Planning Phase  

## 📋 專案概覽

### **背景**
基於 [USP_CLIENT_INTERFACE_SPECIFICATION.md](USP_CLIENT_INTERFACE_SPECIFICATION.md) 和 [USP_CLIENT_ROOT_CAUSE_FIX_IMPLEMENTATION_PLAN.md](USP_CLIENT_ROOT_CAUSE_FIX_IMPLEMENTATION_PLAN.md)，usp-client WASM 層和 codegen 已更新至 v0.11.0，實作「Never Lose Information」原則。現需將 Dart/Flutter 層完全升級以適應新的結構化回應格式。

### **核心目標**
1. **完整適應結構化回應**：所有 USP 操作回傳 `Map<String, dynamic>` 而非簡單成功/失敗
2. **Sealed Class 設計**：提供類型安全的應用層 API
3. **零向後相容包袱**：開發階段無需維護舊 API
4. **豐富錯誤資訊**：逐參數錯誤碼和訊息
5. **部分成功處理**：精確區分完全成功、部分成功、完全失敗

---

## 🎯 架構設計

### **三層架構**
```
Application Layer (Sealed Classes) ← UspXXXResult
    ↓
Service Layer (UspService) ← Map<String, dynamic>  
    ↓
WASM Layer (UspClientWeb) ← JavaScript Objects
```

### **Sealed Class 層級結構**
```dart
sealed class UspOperationResult<T>
├── UspSuccess<T>           // 完全成功
├── UspPartialSuccess<T>    // 部分成功  
└── UspFailure<T>          // 完全失敗
```

---

## 📁 實作階段規劃

### **Phase 1: 核心資料模型 (Day 1 上午)**

#### 1.1 新增結果模型
**檔案**: `lib/core/usp/models/usp_operation_result.dart` (新建)
- `UspOperationResult<T>` sealed class
- `UspSuccess`, `UspPartialSuccess`, `UspFailure` 子類
- `UspSuccessDetail`, `UspErrorDetail` 詳細資料類別
- `UspUpdatedInstance`, `UspCreatedInstance`, `UspDeletedInstance` 實例類別
- Type aliases: `UspSetResult`, `UspAddResult`, `UspDeleteResult`, etc.

**檢查點**: 
- [ ] 所有 sealed class 編譯無誤
- [ ] Pattern matching 範例測試通過
- [ ] 便利方法 (`hasAnySuccess`, `isCompleteSuccess`) 正確運作

#### 1.2 更新匯出
**檔案**: `lib/core/usp/services/usp_service.dart`
- 新增 `export 'package:privacy_gui/core/usp/models/usp_operation_result.dart';`

---

### **Phase 2: WASM Client 升級 (Day 1 下午)**

#### 2.1 更新 WASM Wrapper 方法簽名
**檔案**: `lib/core/usp/web/usp_client_wasm.dart`

**修改清單**:
```dart
// 修改前 → 修改後
Future<void> setMultiple(...) → Future<Map<String, dynamic>> setMultiple(...)
Future<String> add(...) → Future<Map<String, dynamic>> add(...)
Future<void> delete(...) → Future<Map<String, dynamic>> delete(...)
Future<void> deleteMultiple(...) → Future<Map<String, dynamic>> deleteMultiple(...)
```

**具體修改**:
- `setMultiple()`: 回傳完整的 JavaScript 結構化物件
- `add()`: 回傳包含 `createdInstances` 的結構
- `delete()`: 回傳包含 `deletedInstances` 的結構
- 移除舊的簡單回傳值解析邏輯
- 新增完整的 `result.dartify()` 處理

**檢查點**:
- [ ] 所有方法回傳正確的 `Map<String, dynamic>` 結構
- [ ] JavaScript interop 正常運作
- [ ] 錯誤情況正確處理

#### 2.2 更新 Stub 實作  
**檔案**: `lib/core/usp/stub/usp_client_stub.dart`
- 同步更新方法簽名以維持 interface 一致性
- Mock 回傳符合新結構的測試資料

---

### **Phase 3: UspService 核心升級 (Day 2 上午)**

#### 3.1 更新核心操作方法
**檔案**: `lib/core/usp/services/usp_service.dart`

**修改清單**:
```dart
// 原始 Map-based 方法（供 codegen 使用）
Future<void> set(...) → Future<Map<String, dynamic>> set(...)
Future<String> add(...) → Future<Map<String, dynamic>> add(...)  
Future<void> delete(...) → Future<Map<String, dynamic>> delete(...)
Future<void> setMultiple(...) → Future<Map<String, dynamic>> setMultiple(...)
Future<void> deleteMultiple(...) → Future<Map<String, dynamic>> deleteMultiple(...)
```

#### 3.2 新增應用層封裝方法
**新增方法**:
```dart
/// 應用層強型別封裝方法
Future<UspSetResult> setWithResult(Map<String, dynamic> parameters, {bool allowPartial = false})
Future<UspAddResult> addWithResult(String objectPath, Map<String, String> params)  
Future<UspDeleteResult> deleteWithResult(String instancePath)
Future<UspDeleteResult> deleteMultipleWithResult(List<String> paths, {bool allowPartial = false})
```

#### 3.3 實作結果解析器
**新增私有方法**:
```dart
UspSetResult _parseSetResult(Map<String, dynamic> map)
UspAddResult _parseAddResult(Map<String, dynamic> map)
UspDeleteResult _parseDeleteResult(Map<String, dynamic> map)
List<UspSuccessDetail> _parseSuccessResults(List<dynamic> results)
List<UspErrorDetail> _parseErrorResults(List<dynamic> results)
```

**檢查點**:
- [ ] 所有解析器正確處理各種回應格式
- [ ] 邊界條件（空結果、null 值）正確處理  
- [ ] 異常情況轉換為 `UspFailure`

---

### **Phase 4: Generated Code 更新 (Day 2 下午)**

#### 4.1 重新生成所有代碼
**命令**:
```bash
./tools/usp-codegen --definitions-dir definitions/ \
  --output-dir lib/generated/ --language dart \
  --client-import 'package:privacy_gui/core/usp/services/usp_service.dart'
```

#### 4.2 驗證生成代碼格式
**預期變更**:
```dart
// 修改前
static Future<void> update(UspService client, WiFiSsidUpdate update) async
static Future<String> add(UspService client, {...}) async
static Future<void> delete(UspService client, String instancePath) async

// 修改後  
static Future<Map<String, dynamic>> update(UspService client, WiFiSsidUpdate update) async
static Future<Map<String, dynamic>> add(UspService client, {...}) async
static Future<Map<String, dynamic>> delete(UspService client, String instancePath) async
```

**檢查檔案**:
- [ ] `lib/generated/wi_fi_ssids.g.dart`
- [ ] `lib/generated/port_forwarding.g.dart`  
- [ ] `lib/generated/connected_devices.g.dart`
- [ ] 所有其他 `.g.dart` 檔案

#### 4.3 更新空結果處理
**確保所有生成方法**:
```dart
if (params.isEmpty) {
  return {
    'overallSuccess': true,
    'hasAnySuccess': false, 
    'hasErrors': false,
    'results': <Map<String, dynamic>>[],
  };
}
```

---

### **Phase 5: 應用層整合測試 (Day 3 上午)**

#### 5.1 建立測試架構
**檔案**: `test/core/usp/usp_operation_result_test.dart` (新建)
- Sealed class pattern matching 測試
- 結果解析正確性測試  
- 邊界條件測試

**檔案**: `test/core/usp/usp_service_v011_test.dart` (新建)
- WASM client 回應格式測試
- UspService 方法回傳格式測試
- 錯誤處理測試

#### 5.2 範例使用模式測試
**測試場景**:
```dart
// 完全成功
final result = await client.setWithResult({...});
switch (result) {
  case UspSuccess(details: final details):
    // 驗證成功處理邏輯
    
  case UspPartialSuccess(successes: final successes, failures: final failures):
    // 驗證部分成功處理邏輯
    
  case UspFailure(errors: final errors):
    // 驗證失敗處理邏輯
}
```

#### 5.3 Generated Code 整合測試
**測試生成代碼**:
- WiFi 設定更新測試
- Port Forwarding 新增/刪除測試
- 批次操作測試
- 部分成功場景測試

**檢查點**:
- [ ] 所有 sealed class 測試通過
- [ ] Pattern matching 正確運作
- [ ] 錯誤處理完整
- [ ] Generated code 無回歸問題

---

### **Phase 6: 文檔與範例 (Day 3 下午)**

#### 6.1 建立使用指南
**檔案**: `doc/usp/USP_V011_USAGE_GUIDE.md` (新建)
- Sealed class 使用範例
- Pattern matching 最佳實踐
- 錯誤處理策略
- 遷移指南（從舊格式到新格式）

#### 6.2 更新現有文檔
**檔案**: `CLAUDE.md`
- 更新 USP 系統架構說明
- 新增 v0.11.0 相關資訊

#### 6.3 建立範例代碼
**檔案**: `lib/page/usp_test/usp_v011_examples.dart` (新建)
- 各種操作的完整範例
- 錯誤處理範例
- 批次操作範例

---

## 📋 詳細檔案修改清單

### **新增檔案**
| 檔案路徑 | 目的 | 預估行數 |
|---------|------|---------|
| `lib/core/usp/models/usp_operation_result.dart` | Sealed class 結果類型 | ~300 |
| `test/core/usp/usp_operation_result_test.dart` | 結果類型測試 | ~200 |
| `test/core/usp/usp_service_v011_test.dart` | UspService 新格式測試 | ~150 |
| `doc/usp/USP_V011_USAGE_GUIDE.md` | 使用指南 | N/A |
| `lib/page/usp_test/usp_v011_examples.dart` | 範例代碼 | ~100 |

### **修改檔案**
| 檔案路徑 | 修改類型 | 預估影響 |
|---------|---------|---------|
| `lib/core/usp/web/usp_client_wasm.dart` | 方法簽名 + 回傳處理 | High |
| `lib/core/usp/stub/usp_client_stub.dart` | 方法簽名同步 | Medium |
| `lib/core/usp/services/usp_service.dart` | 核心方法 + 新增封裝方法 | High |
| `lib/generated/*.g.dart` | 自動重新生成 | High |
| `CLAUDE.md` | 文檔更新 | Low |

### **測試檔案影響評估**
| 測試檔案 | 影響程度 | 修改需求 |
|---------|---------|---------|
| `test/core/usp/services/usp_service_test.dart` | High | 更新所有方法回傳檢查 |
| `test/generated/*_test.dart` | Medium | 更新生成代碼測試 |
| `integration_test/**/*_test.dart` | Low | 僅需驗證功能正常 |

---

## 🔍 風險分析與緩解策略

### **技術風險**

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|----------|
| **WASM interop 格式不一致** | Medium | High | 建立詳細的 WASM 回應測試，確保 `dartify()` 正確轉換 |
| **Sealed class 效能影響** | Low | Medium | 進行效能基準測試，監控記憶體使用 |
| **Pattern matching 複雜度** | Low | Medium | 提供清楚的使用範例和最佳實踐指南 |
| **Generated code 格式錯誤** | Medium | High | 詳細測試 codegen 輸出，驗證所有操作類型 |

### **專案風險**

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|----------|
| **既有功能回歸** | Medium | High | 完整的回歸測試，特別是 dashboard 和設定頁面 |
| **測試覆蓋不足** | Low | Medium | 建立完整的測試矩陣，涵蓋所有使用場景 |
| **文檔過時** | Medium | Medium | 同步更新所有相關文檔和範例 |

---

## 🧪 測試策略

### **單元測試**
- **Sealed Class 測試**: 所有 pattern matching 分支
- **結果解析測試**: 各種 WASM 回應格式
- **邊界條件測試**: 空結果、null 值、格式錯誤

### **整合測試**  
- **WASM ↔ Dart 互操作**: 確保數據正確轉換
- **Generated Code**: 驗證所有生成方法正確運作
- **End-to-End**: 完整的 USP 操作流程

### **效能測試**
- **Sealed Class 開銷**: 與舊格式比較效能
- **記憶體使用**: 確保無記憶體洩漏
- **回應處理速度**: 大型回應的處理效能

### **相容性測試**
- **路由器韌體版本**: 測試不同 firmware 版本的回應格式
- **瀏覽器相容**: 確保 WASM interop 在各瀏覽器正常運作

---

## ✅ 完成檢查清單

### **Phase 1: 核心資料模型**
- [ ] `UspOperationResult` sealed class 完成
- [ ] 所有子類別 (`UspSuccess`, `UspPartialSuccess`, `UspFailure`) 實作完成
- [ ] 詳細資料類別 (`UspSuccessDetail`, `UspErrorDetail`) 完成
- [ ] 實例類別 (`UspUpdatedInstance` 等) 完成
- [ ] Type aliases 定義完成
- [ ] 基本 pattern matching 測試通過

### **Phase 2: WASM Client 升級**
- [ ] `setMultiple()` 回傳結構化 Map
- [ ] `add()` 回傳結構化 Map  
- [ ] `delete()` 回傳結構化 Map
- [ ] `deleteMultiple()` 回傳結構化 Map
- [ ] Stub 實作同步更新
- [ ] JavaScript interop 測試通過

### **Phase 3: UspService 核心升級**
- [ ] 核心方法簽名更新完成
- [ ] 應用層封裝方法實作完成
- [ ] 結果解析器實作完成  
- [ ] 錯誤處理邏輯完成
- [ ] 所有方法測試通過

### **Phase 4: Generated Code 更新**
- [ ] Codegen 重新執行完成
- [ ] 所有 `.g.dart` 檔案格式正確
- [ ] 空結果處理正確
- [ ] Generated code 編譯無誤
- [ ] Generated method 測試通過

### **Phase 5: 應用層整合測試**
- [ ] Sealed class 測試套件完成
- [ ] UspService 測試套件完成
- [ ] Generated code 整合測試完成
- [ ] End-to-end 測試通過
- [ ] 回歸測試無問題

### **Phase 6: 文檔與範例**
- [ ] 使用指南撰寫完成
- [ ] 範例代碼建立完成
- [ ] 文檔更新完成
- [ ] 遷移指南完成

---

## 📊 成功指標

### **功能指標**
- ✅ 所有 USP 操作回傳結構化資訊
- ✅ Sealed class pattern matching 正常運作
- ✅ 錯誤資訊精確到參數層級
- ✅ 部分成功場景正確處理
- ✅ Generated code 無回歸問題

### **品質指標**
- ✅ 測試覆蓋率 ≥ 90%
- ✅ 所有測試通過
- ✅ 編譯無 warning
- ✅ 靜態分析通過
- ✅ 效能無顯著退化

### **可用性指標**  
- ✅ 使用範例清楚易懂
- ✅ 錯誤訊息具體明確
- ✅ Pattern matching 語法簡潔
- ✅ IDE 自動完成支援良好

---

## 🚀 部署準備

### **Pre-deployment 檢查**
- [ ] 所有測試通過
- [ ] 文檔更新完成  
- [ ] 範例代碼驗證無誤
- [ ] 效能基準測試完成
- [ ] 相容性測試通過

### **部署後監控**
- [ ] Dashboard 功能正常
- [ ] 設定頁面操作無誤
- [ ] 錯誤處理符合預期
- [ ] 效能指標在預期範圍內

---

**實作負責人**: Development Team  
**預計完成日期**: 2026-04-12  
**核准狀態**: Pending Review