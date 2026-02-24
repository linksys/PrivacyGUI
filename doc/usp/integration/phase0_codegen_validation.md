# Phase 0: Codegen 驗證報告

**日期:** 2026-02-24
**分支:** `doc/usp-integration-assessment`
**狀態:** 完成 — codegen 管線已端對端驗證
**Codegen 版本:** v2（更新後重新測試）

---

## 1. 目標

驗證端對端管線：**YAML 定義檔 → usp-codegen → 生成 Dart 程式碼 → 編譯通過**，作為主遷移計劃（Phase 1-4）的前置條件。

---

## 2. 正確的 YAML 格式

經過多版工具迭代與範例測試，確認**完整可運作的格式**如下：

```yaml
name: feature_name           # snake_case → 生成 PascalCase class name
version: 1.0.0
schema_version: 1.0.0
description: "人類可讀描述"

parameters:
  - field_name: field_name   # snake_case → 生成 camelCase getter/setter（建議提供）
    path: Device.Full.Path   # 完整絕對 TR-181 路徑
    type: string             # string | int | boolean | double
    writable: false          # true → 生成 setXxx() 方法
    description: "生成為 /// doc comment"

# 可選：presets（array 格式）→ 生成 enum + applyPreset()
presets:
  - name: PresetName
    description: "..."
    values:
      ParamPath: "value"

# 可選：transforms → 使用分離的 _transforms.yaml 檔案（見第 7 節）
# 或嵌入主檔（object 格式，目前僅接受 schema 不生成程式碼）
```

### YAML Schema 欄位行為對照表

| 欄位 | 行為 | 重要度 |
|------|------|--------|
| `name` | snake_case → PascalCase class name（`system_info` → `SystemInfo`） | 必要 |
| `field_name` | snake_case → camelCase getter（`model_name` → `getModelName()`）。**建議提供**以獲得更好的命名控制。若省略，工具從 `path` 最後一段推導方法名 | 建議 |
| `path`（無 `field_name` 時） | 從路徑最後一段生成方法名（`Manufacturer` → `getManufacturer()`）。v2 已修正，不再全部命名為 `get()` | 可用 |
| `path` | 必須為**完整絕對 TR-181 路徑**（如 `Device.DeviceInfo.Manufacturer`） | 必要 |
| `base_path` | **不要使用** — 工具不會將其加到相對路徑前面，導致發送不完整路徑 | 避免 |
| `type`（parameter） | `string` → `String`；`int` → `int`（含 `int.parse()`）；`boolean` → `bool`（含 `== true`） | 必要 |
| `writable: true` | **有效！** 生成 `setXxx()` 方法 | 重要 |
| `writable: false` | 僅生成 `getXxx()` 方法 | 預設行為 |
| `access` | 被識別但**不產生** setter，即使設為 `read-write`。應使用 `writable` 替代 | 已棄用 |
| `description`（parameter） | 正確轉為 `///` doc comment | 建議 |
| `presets`（array） | ✅ **完整生成** `enum Preset` + `applyPreset()` 方法 | 可用 |
| `presets`（object） | ❌ 驗證錯誤：`must be an array` | 不支援 |
| `transforms`（`_transforms.yaml` 分離檔） | ✅ **完整生成** formula getter + mapping switch/case | **可用** |
| `transforms`（object 嵌入主檔） | 接受且不報錯，但不生成程式碼 | 預留 |
| `transforms`（array） | ❌ 驗證錯誤：`must be an object` | 不支援 |
| `category` | 不識別（warning: `Unknown field`） | 忽略 |
| `validation` | 靜默接受，不生成驗證程式碼 | 忽略 |
| `version` / `schema_version` | 接受，無可見效果 | 建議 |

---

## 3. Codegen CLI 參考

```bash
./tools/usp-codegen \
  --definitions-dir doc/usp/definitions \
  --output-dir lib/generated \
  --language dart \
  --dart-import 'package:privacy_gui/usp/services/usp_service.dart'
```

| Flag | 用途 | 必要 |
|------|------|------|
| `--definitions-dir` | YAML 定義檔目錄（遞迴掃描所有子目錄） | 是 |
| `--output-dir` | 生成程式碼輸出目錄 | 是 |
| `--language` | `dart` / `typescript` / `swift` | 是 |
| `--dart-import` | 自訂 client class import 路徑 | 否（預設 `package:usp_test/services/usp_service.dart`） |
| `--client-class` | 自訂 client class 名稱 | 否（預設 `UspService`） |
| `--validate-paths` | 啟用 TR-181 路徑驗證 | 否 |
| `--json` | JSON 格式錯誤輸出（CI 用） | 否 |

---

## 4. 生成程式碼分析

### 4.1 工具實際生成的內容

**唯讀定義 (`writable: false`)：**

```dart
class SystemInfo {
  final UspService _client;
  SystemInfo(this._client);

  Future<Map<String, dynamic>> fetchAll() async { ... }  // 批次取得
  Future<String> getManufacturer() async { ... }          // 字串 getter
  Future<int> getUptime() async { ... }                   // int getter (含 int.parse)
  Future<bool> getEnable() async { ... }                  // bool getter (含 == true)
}
```

**可寫定義 (`writable: true`)：**

```dart
class DnsSettings {
  // ... getters 同上 ...

  Future<void> setEnable(bool value) async {
    await _client.set({'Device.DNS.Client.Enable': value});
  }
  Future<void> setPreferredServer(String value) async {
    await _client.set({'Device.DNS.Client.PreferredServer': value});
  }
}
```

**Presets 定義（array 格式）：**

```dart
/// Available presets
enum Preset {
  google,
  cloudflare,
}

class DnsSettings {
  // ... getters + setters ...

  /// Apply a preset configuration via USP Set message
  Future<void> applyPreset(Preset preset) async {
    final params = <String, dynamic>{};
    switch (preset) {
      case Preset.google:
        params['PreferredServer'] = '8.8.8.8';
        params['AlternateServer'] = '8.8.4.4';
        break;
      case Preset.cloudflare:
        params['PreferredServer'] = '1.1.1.1';
        params['AlternateServer'] = '1.0.0.1';
        break;
    }
    await _client.set(params);
  }
}
```

### 4.2 生成程式碼 vs. CODEGEN_GUIDE 規格

| 功能 | CODEGEN_GUIDE 描述 | 實際生成結果 | 差距 |
|------|-------------------|-------------|------|
| Fetch 模式 | `SystemInfo.fetch(client)` 靜態方法 → typed data class | `SystemInfo(client).fetchAll()` 實例方法 → `Map<String, dynamic>` | 顯著 |
| 型別資料類別 | `info.manufacturer` 屬性存取 | 無資料類別；獨立 `getManufacturer()` 方法 | 顯著 |
| **寫入操作** | `wifi.save(client)` 批次寫入 | **`setXxx(value)` 個別寫入** ✅ | 形式不同但可用 |
| **Presets** | `applyPreset()` 方法 | **`enum Preset` + `applyPreset()` 完整生成** ✅ | 匹配 |
| **Transforms** | 計算屬性 getter | **`_transforms.yaml` 分離檔完整生成** formula + mapping ✅ | 匹配 |
| `subscribe()` | 回傳 typed stream | 未生成（⏳ 延後） | Dart/JS 端均未實作 |
| `add()` / `delete()` | 多實例操作 | Codegen 未生成，但 **Dart API 已就緒** | UI 可直接呼叫 `UspService` |
| `operate()` | 執行 USP 命令 | Codegen 未生成，但 **Dart API 已就緒** | 同上 |
| Boolean 型別 | typed bool | ✅ `params['path'] == true` | 正確 |
| Int 型別 | typed int | ✅ `int.parse(params['path'] as String)` | 正確 |

### 4.3 Client 介面相容性

**完全相容。** 生成程式碼呼叫的介面與現有 `UspService` 匹配：

| 生成程式碼呼叫 | UspService 方法 | 相容性 |
|--------------|----------------|--------|
| `_client.get(List<String>)` | `UspService.get(List<String>) → Future<Map<String, dynamic>>` | ✓ |
| `_client.set(Map<String, dynamic>)` | `UspService.set(Map<String, dynamic>)` | ✓ |
| `params['path'] as String` | `_coerceValue()` 回傳原始字串 | ✓ |
| `params['path'] == true` | `_coerceValue()` 回傳 bool | ✓ |
| `int.parse(...)` | 值為字串形式的數字 | ✓ |

### 4.4 UspService 完整 API 清單

`UspService`（`lib/usp/services/usp_service.dart`）已實作所有 USP CRUD + Operate 操作，底層經由 `UspClientWeb`（JS interop）→ WASM → 路由器通訊。

| 操作類型 | 方法簽名 | 用途 | Codegen 支援 |
|---------|---------|------|-------------|
| **Get** | `get(List<String>) → Future<Map<String, dynamic>>` | 批次讀取參數 | ✅ 生成 `getXxx()` |
| **Get** | `getSingle(String) → Future<String?>` | 單一參數讀取 | — Legacy |
| **Set** | `set(Map<String, dynamic>)` | 批次設定參數 | ✅ 生成 `setXxx()` |
| **Set** | `setSingle(String, String)` | 單一參數設定 | — Legacy |
| **Add** | `add(String objectPath, Map<String, String> parameters) → Future<String>` | 新增物件實例（回傳建立的實例路徑） | ❌ 需手動或未來 codegen |
| **Add** | `addMultiple(List<Map<String, dynamic>>, {allowPartial}) → Future<List<String>>` | 批次新增物件實例 | ❌ 同上 |
| **Delete** | `delete(String path)` | 刪除物件實例 | ❌ 需手動或未來 codegen |
| **Delete** | `deleteMultiple(List<String>, {allowPartial})` | 批次刪除物件實例 | ❌ 同上 |
| **Operate** | `operate(String command, {Map<String, String> args}) → Future<Map<String, String>>` | 執行 USP Operate 命令（如 Ping、Reboot） | ❌ 需手動或未來 codegen |
| **Auth** | `login(String password)` / `logout()` / `refreshToken()` | 認證管理 | — 不需 codegen |
| **Subscribe** | — | 即時參數變更通知 | ⏳ 延後（Dart 與 JS 端均未實作） |

> **附註：** `add`/`delete`/`operate` 的 Dart 介面與 JS interop 層已完整實作並通過 `dart analyze`。Codegen 目前不會自動生成呼叫這些 API 的程式碼，但 UI 層可直接透過 `UspService` 手動呼叫。

### 4.5 已知的潛在問題

**Preset 路徑問題：** `applyPreset()` 中使用的 key 來自 YAML `values` 區段的原始值（如 `PreferredServer`），而非完整 TR-181 路徑（如 `Device.DNS.Client.PreferredServer`）。若 `UspService.set()` 需要完整路徑，則 YAML 的 `values` 區段需寫完整路徑：

```yaml
# 建議寫法（使用完整路徑）：
presets:
  - name: Google
    values:
      Device.DNS.Client.PreferredServer: "8.8.8.8"
      Device.DNS.Client.AlternateServer: "8.8.4.4"
```

---

## 5. 編譯結果

| 檢查 | 結果 |
|------|------|
| `dart analyze lib/generated/system_info.g.dart` | **No issues found** |
| `dart analyze lib/generated/` | **No issues found** |
| Import 解析 | `package:privacy_gui/usp/services/usp_service.dart` 正確解析 |

---

## 6. 範例檔案測試結果（Codegen v2）

### 6.1 範例檔案（`doc/usp/codegen_example/`）

| 範例檔案 | codegen 結果 | 生成程式碼品質 |
|---------|------------|--------------|
| `example_readonly.yaml` | ✅ 生成 | ✅ getter 從 `path` 推導命名（v2 修正） |
| `example_writable.yaml` | ✅ 生成 | ⚠️ getter 正確，但 `access: read-write` 不生成 setter |
| `example_transform.yaml` | ✅ 生成 | ⚠️ getter 正確，transform 不在此檔中 |
| `example_transform_ext.yaml` | ❌ 失敗 | N/A（`_ext.yaml` 不支援） |
| `example_presets.yaml` | ✅ **生成** | ✅ **完整 enum + applyPreset()** |

### 6.2 v1 → v2 改進對照

| 功能 | v1 (舊版) | v2 (更新版) |
|------|----------|-----------|
| `path` 推導方法名 | ❌ 全部叫 `get()` | ✅ 從路徑推導（`getManufacturer()`） |
| `presets`（array） | ❌ 驗證錯誤 | ✅ **完整生成** enum + applyPreset() |
| `presets`（object） | ✅ 接受（不生成） | ❌ 驗證錯誤（格式反轉） |
| `transforms`（object 嵌入） | 接受（不生成） | 接受（不生成）— 無變化 |
| `_transforms.yaml` 分離 | 未測試 | ✅ **完整生成** formula + mapping |
| `_ext.yaml` 分離 | ❌ 不支援 | ❌ 仍不支援（正確命名為 `_transforms.yaml`） |
| `writable: true` setter | ✅ 有效 | ✅ 有效 — 無變化 |
| `access: read-write` setter | ❌ 無效 | ❌ 仍無效 |

### 6.3 範例格式建議

範例檔案大部分已可用。建議修正：

| 修正項目 | 目前範例格式 | 建議修正 |
|---------|-----------|---------|
| 存取控制 | `access: read-write` | 加上 `writable: true` 以確保 setter 生成 |
| 路徑格式 | `base_path` + 相對 `path` | 使用完整絕對路徑（或等 `base_path` 修復） |
| Transform 檔案命名 | `*_ext.yaml` | 改為 `*_transforms.yaml` |

---

## 7. Transform 支援狀態

### ✅ `_transforms.yaml` 分離檔案 — 完整支援

工具透過 **`_transforms.yaml`** 命名慣例識別 transform 檔案（**不是** `_ext.yaml`）。

**命名規則：** 定義檔 `foo.yaml` 對應的 transform 檔為 `foo_transforms.yaml`。

工具處理時會輸出 `Found transform file: ...` 確認配對成功。

#### Transform 檔案格式

```yaml
# example_transform_transforms.yaml
name: SpeedTest              # 必須與主定義檔的 name 一致
transforms:
  - name: throughputMbps
    description: Download throughput in megabits per second
    type: formula
    formula: "(TestBytesReceived * 8) / (TestDuration * 1000)"
    inputs:
      - TestBytesReceived
      - TestDuration
    output_type: double

  - name: diagnosticsStateDisplay
    description: Human-readable diagnostic state
    type: mapping
    input: DiagnosticsState
    mappings:
      None: "Not started"
      Requested: "Test in progress..."
      Complete: "Test completed successfully"
      Error_Timeout: "Test timed out"
```

#### 生成的程式碼

**Formula transform** → 呼叫對應 getter 計算：

```dart
/// Download throughput in megabits per second
Future<double> getThroughputMbps() async {
  final TestBytesReceived = await getTestBytesReceived();
  final TestDuration = await getTestDuration();
  return ((TestBytesReceived * 8) / (TestDuration * 1000)).toDouble();
}
```

**Mapping transform** → 生成完整 switch/case：

```dart
/// Human-readable diagnostic state
Future<String> getDiagnosticsStateDisplay() async {
  final value = await getDiagnosticsState();
  switch (value) {
    case 'None': return 'Not started';
    case 'Requested': return 'Test in progress...';
    case 'Complete': return 'Test completed successfully';
    case 'Error_Timeout': return 'Test timed out';
    default: return value.toString();
  }
}
```

### ⚠️ 嵌入主檔（object 格式）

`transforms` 以 object 格式嵌入主定義檔時，工具接受不報錯，但**不生成程式碼**。建議使用 `_transforms.yaml` 分離檔。

### ❌ `_ext.yaml` 命名

不支援。工具不識別 `_ext.yaml` 慣例，會將其當作普通定義檔處理並報錯。

---

## 8. 結論與建議

### 已可運作的功能

| # | 功能 | 狀態 |
|---|------|------|
| 1 | YAML → Dart codegen 管線 | ✅ 完整可用 |
| 2 | `UspService` 介面相容性（get + set） | ✅ 完全相容 |
| 3 | `string` / `int` / `boolean` 型別轉換 | ✅ 正確生成 |
| 4 | `--dart-import` 自訂 import 路徑 | ✅ 正確運作（`package:privacy_gui/usp/services/usp_service.dart`） |
| 5 | 遞迴目錄掃描 | ✅ 支援子目錄結構 |
| 6 | **讀取操作** (`getXxx()`) | ✅ 每個 parameter 一個 getter |
| 7 | **寫入操作** (`setXxx()`) | ✅ `writable: true` 生成 setter |
| 8 | **Presets** | ✅ array 格式生成 `enum` + `applyPreset()` |
| 9 | **Transforms**（`_transforms.yaml`） | ✅ formula → 計算 getter；mapping → switch/case |
| 10 | **`path` 推導命名** | ✅ 省略 `field_name` 時從路徑推導 getter 名 |
| 11 | **Add/Delete API**（`UspService`） | ✅ Dart + JS interop 完整實作（`add`, `addMultiple`, `delete`, `deleteMultiple`） |
| 12 | **Operate API**（`UspService`） | ✅ Dart + JS interop 完整實作（`operate`） |

### 尚需增強的功能（Codegen 工具端）

| # | 功能 | 目前狀態 | 影響 |
|---|------|---------|------|
| 1 | `base_path` 路徑前綴 | 不組合 | 須用完整路徑（已有 workaround） |
| 2 | `subscribe()` 訂閱 | ⏳ 延後 | Dart/JS 端均未實作；待需求明確後再加入 |
| 3 | `add()` / `delete()` 多實例 codegen | Codegen 未生成 | **Dart API 已就緒**（`UspService.add/delete`）；UI 可直接呼叫，codegen 自動生成待未來版本 |
| 4 | `operate()` 命令 codegen | Codegen 未生成 | **Dart API 已就緒**（`UspService.operate`）；同上 |
| 5 | 強型別資料類別 | 僅生成 getter/setter | 無 data class pattern |
| 6 | 靜態 `fetch()` 方法 | 未實作 | 使用實例模式替代 |

### 建議的 YAML 慣例

```yaml
name: feature_name           # snake_case
version: 1.0.0
schema_version: 1.0.0
description: "..."

parameters:
  - field_name: field_name   # 建議提供，以獲得更好的命名控制
    path: Device.Full.Path   # 完整絕對 TR-181 路徑
    type: string|int|boolean
    writable: true|false     # true 會生成 setXxx()
    description: "..."

# Presets（array 格式 — 完整生成 enum + applyPreset）
presets:
  - name: PresetName
    description: "..."
    values:
      Device.Full.Path: "value"   # 建議使用完整路徑

# Transforms → 使用分離的 _transforms.yaml 檔案
# 檔名慣例：定義檔 foo.yaml → transform 檔 foo_transforms.yaml
# transforms 格式為 array（見第 7 節完整範例）
```

### Phase 1 就緒度評估

| 需求 | 狀態 | 備註 |
|------|------|------|
| YAML → Dart codegen 管線 | ✅ 就緒 | |
| Client 介面相容性 | ✅ 就緒 | |
| 讀取操作 (`getXxx()`) | ✅ 就緒 | Codegen 自動生成 |
| 寫入操作 (`setXxx()`) | ✅ 就緒 | Codegen 自動生成（`writable: true`） |
| Presets (`applyPreset()`) | ✅ 就緒 | Codegen 自動生成（array 格式） |
| Transforms（`_transforms.yaml`） | ✅ 就緒 | formula + mapping 完整生成 |
| 新增/刪除物件實例 (`add`/`delete`) | ✅ Dart API 就緒 | `UspService` 已實作；Codegen 不自動生成，UI 層可直接呼叫 |
| USP Operate 命令 (`operate`) | ✅ Dart API 就緒 | 同上 |
| 訂閱 (`subscribe()`) | ⏳ 延後 | Dart 與 JS 端均未實作；依需求排入未來迭代 |
| `--dart-import` 路徑 | ✅ 確認 | `package:privacy_gui/usp/services/usp_service.dart` |

**結論：** 專案可以用完整的讀寫定義檔（含 presets + transforms）推進 Phase 2。`add`/`delete`/`operate` 的 Dart API 已完整就緒，UI 層可直接使用。`subscribe()` 延後處理，待需求明確後納入。
