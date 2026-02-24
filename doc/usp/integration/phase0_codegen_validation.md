# Phase 0: Codegen 驗證報告

**日期:** 2026-02-24
**分支:** `doc/usp-integration-assessment`
**狀態:** 完成 — codegen 管線已端對端驗證

---

## 1. 目標

驗證端對端管線：**YAML 定義檔 → usp-codegen → 生成 Dart 程式碼 → 編譯通過**，作為主遷移計劃（Phase 1-4）的前置條件。

---

## 2. 正確的 YAML 格式

經過多次迭代與範例測試，確認**可運作的格式**如下：

```yaml
name: feature_name           # snake_case → 生成 PascalCase class name
version: 1.0.0
schema_version: 1.0.0
description: "人類可讀描述"

parameters:
  - field_name: field_name   # snake_case → 生成 camelCase getter/setter
    path: Device.Full.Path   # 完整絕對 TR-181 路徑
    type: string             # string | int | boolean | double
    writable: false          # true → 生成 setXxx() 方法
    description: "生成為 /// doc comment"

# 可選：transforms (object 格式，不是 array)
transforms:
  transform_name:
    description: "..."
    type: formula|mapping
    ...

# 可選：presets (object 格式，不是 array)
presets:
  preset_name:
    description: "..."
    values: {...}
```

### YAML Schema 欄位行為對照表

| 欄位 | 行為 | 重要度 |
|------|------|--------|
| `name` | snake_case → PascalCase class name (`system_info` → `SystemInfo`) | 必要 |
| `field_name` | **必須提供**。snake_case → camelCase getter (`model_name` → `getModelName()`) + setter (`setModelName()`)。缺少此欄位會導致所有 getter 命名為 `get()`，無法編譯 | **關鍵** |
| `path` | 必須為**完整絕對 TR-181 路徑**（如 `Device.DeviceInfo.Manufacturer`） | 必要 |
| `base_path` | **不要使用** — 工具不會將其加到相對路徑前面，導致發送不完整路徑 | 避免 |
| `type` (parameter) | `string` → `String`；`int` → `int`（含 `int.parse()`）；`boolean` → `bool`（含 `== true`） | 必要 |
| `writable: true` | **有效！** 搭配 `field_name` 時會生成 `setXxx()` 方法 | 重要 |
| `writable: false` | 僅生成 `getXxx()` 方法 | 預設行為 |
| `access` | 被識別但**不產生** setter，即使設為 `read-write`。應使用 `writable` 替代 | 已棄用 |
| `description` (parameter) | 正確轉為 `///` doc comment | 建議 |
| `transforms` (object) | 接受且不報錯，但**目前不生成計算屬性程式碼** | 預留 |
| `transforms` (array) | 驗證錯誤：`must be an object` | 不支援 |
| `presets` (object) | 接受且不報錯，但**目前不生成 preset 程式碼** | 預留 |
| `presets` (array) | 驗證錯誤：`must be an object` | 不支援 |
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

### 4.2 生成程式碼 vs. CODEGEN_GUIDE 規格

| 功能 | CODEGEN_GUIDE 描述 | 實際生成結果 | 差距 |
|------|-------------------|-------------|------|
| Fetch 模式 | `SystemInfo.fetch(client)` 靜態方法 → 回傳 typed data class | `SystemInfo(client).fetchAll()` 實例方法 → `Map<String, dynamic>` | 顯著 |
| 型別資料類別 | `info.manufacturer` 屬性存取 | 無資料類別；獨立 `getManufacturer()` 方法 | 顯著 |
| **寫入操作** | `wifi.save(client)` 批次寫入 | **`setXxx(value)` 個別寫入** ✓ | 形式不同但可用 |
| `subscribe()` | 回傳 typed stream | 未生成 | 重大 |
| `add()` / `delete()` | 多實例操作 | 未生成 | 重大 |
| Transforms | `_ext.yaml` 計算屬性 | Object 格式接受但不生成程式碼；`_ext.yaml` 分離檔案不支援 | 重大 |
| Presets | `applyPreset()` 方法 | Object 格式接受但不生成程式碼 | 重大 |
| Boolean 型別 | typed bool | ✓ `params['path'] == true` | 正確 |
| Int 型別 | typed int | ✓ `int.parse(params['path'] as String)` | 正確 |

### 4.3 Client 介面相容性

**完全相容。** 生成程式碼呼叫的介面與現有 `UspService` 匹配：

| 生成程式碼呼叫 | UspService 方法 | 相容性 |
|--------------|----------------|--------|
| `_client.get(List<String>)` | `UspService.get(List<String>) → Future<Map<String, dynamic>>` | ✓ |
| `_client.set(Map<String, dynamic>)` | `UspService.set(Map<String, dynamic>)` | ✓ |
| `params['path'] as String` | `_coerceValue()` 回傳原始字串 | ✓ |
| `params['path'] == true` | `_coerceValue()` 回傳 bool | ✓ |
| `int.parse(...)` | 值為字串形式的數字 | ✓ |

---

## 5. 編譯結果

| 檢查 | 結果 |
|------|------|
| `dart analyze lib/generated/system_info.g.dart` | **No issues found** |
| `dart analyze lib/generated/` | **No issues found** |
| Import 解析 | `package:privacy_gui/usp/services/usp_service.dart` 正確解析 |

---

## 6. 範例檔案格式問題

`doc/usp/codegen_example/` 中的範例使用了較舊的 schema 格式，與工具實際行為不一致：

| 範例使用的格式 | 問題 | 正確格式 |
|---------------|------|---------|
| `path: Manufacturer` + `access: read-only` | 所有 getter 命名為 `get()`，無法編譯。`access` 不生成 setter | `field_name: manufacturer` + `writable: false` |
| `base_path: Device.DeviceInfo` + 相對 `path` | `base_path` 不會前綴，路徑不完整 | 使用完整絕對路徑 |
| `transforms:` (array 格式) | 驗證錯誤 `must be an object` | 使用 object 格式 |
| `presets:` (array 格式) | 驗證錯誤 `must be an object` | 使用 object 格式 |
| `_ext.yaml` 分離檔案 | 被當作普通定義檔，缺少必要欄位 | 嵌入主定義檔中（object 格式） |
| `category: core` | 不識別（warning） | 省略 |

### 範例 vs 實際測試對照

| 範例檔案 | codegen 結果 | 生成程式碼可編譯？ |
|---------|------------|-----------------|
| `example_readonly.yaml` | 生成 ✓ | ✗ 所有 getter 同名 `get()` |
| `example_writable.yaml` | 生成 ✓ | ✗ 同上 + 無 setter |
| `example_transform.yaml` | 生成 ✓ | ✗ 同上 |
| `example_transform_ext.yaml` | **失敗** | N/A |
| `example_presets.yaml` | **失敗** | N/A |

---

## 7. Transform 與 Preset 支援狀態

### Transform

`transforms` 以 **object 格式** 嵌入主定義檔時，工具接受不報錯，但**不生成對應程式碼**。這表示 transform 功能的 schema 驗證已實作，但程式碼生成尚未完成。

```yaml
# 接受的格式（不生成程式碼）：
transforms:
  throughputMbps:
    description: "..."
    type: formula
    formula: "(testBytesReceived * 8) / (testDuration * 1000)"
    inputs: [test_bytes_received, test_duration]
    output_type: double

# 不接受的格式（驗證失敗）：
transforms:
  - name: throughputMbps    # ← array 格式會報錯
    ...
```

### Preset

同理，`presets` 以 object 格式嵌入時接受但不生成程式碼。

### `_ext.yaml` 分離檔案

**不支援。** 工具將所有 `.yaml` 檔案視為獨立定義檔處理，不實作 `_ext.yaml` 配對機制。

---

## 8. 結論與建議

### 已可運作的功能

| # | 功能 | 狀態 |
|---|------|------|
| 1 | YAML → Dart codegen 管線 | ✅ 完整可用 |
| 2 | `UspService` 介面相容性（get + set） | ✅ 完全相容 |
| 3 | `string` / `int` / `boolean` 型別轉換 | ✅ 正確生成 |
| 4 | `--dart-import` 自訂 import 路徑 | ✅ 正確運作 |
| 5 | 遞迴目錄掃描 | ✅ 支援子目錄結構 |
| 6 | **讀取操作** (`getXxx()`) | ✅ 每個 parameter 一個 getter |
| 7 | **寫入操作** (`setXxx()`) | ✅ `writable: true` 生成 setter |

### 尚需增強的功能（Codegen 工具端）

| # | 功能 | 目前狀態 | 影響 |
|---|------|---------|------|
| 1 | `base_path` 路徑前綴 | 不組合 | 須用完整路徑（已有 workaround） |
| 2 | Transform 程式碼生成 | Schema 接受但不生成 | 計算屬性需手動實作 |
| 3 | Preset 程式碼生成 | Schema 接受但不生成 | 預設組合需手動實作 |
| 4 | `_ext.yaml` 配對機制 | 不支援 | Transform 須嵌入主檔 |
| 5 | `subscribe()` 訂閱 | 未實作 | 即時更新需手動實作 |
| 6 | `add()` / `delete()` 多實例 | 未實作 | 動態物件管理需手動實作 |
| 7 | 強型別資料類別 | 僅生成 getter/setter | 無 data class pattern |
| 8 | 靜態 `fetch()` 方法 | 未實作 | 使用實例模式替代 |

### 建議的 YAML 慣例

```yaml
name: feature_name           # snake_case
version: 1.0.0
schema_version: 1.0.0
description: "..."

parameters:
  - field_name: field_name   # snake_case → camelCase getter/setter
    path: Device.Full.Path   # 完整絕對 TR-181 路徑
    type: string|int|boolean
    writable: true|false     # true 會生成 setXxx()
    description: "..."

# 預留（未來 codegen 增強後可生效）
transforms:
  name:
    type: formula|mapping
    ...
```

### Phase 1 就緒度評估

| 需求 | 狀態 |
|------|------|
| YAML → Dart codegen 管線 | ✅ 就緒 |
| Client 介面相容性 | ✅ 就緒 |
| 讀取操作 (`getXxx()`) | ✅ 就緒 |
| 寫入操作 (`setXxx()`) | ✅ 就緒 |
| 訂閱 (`subscribe()`) | ❌ 未就緒 |
| Transform 計算屬性 | ❌ 未就緒（schema 預留） |
| 多實例定義 | ⚠️ 未測試 |

**結論：** 專案可以用完整的讀寫定義檔推進 Phase 2（MIL-1 至 MIL-2 範圍）。訂閱與 Transform 需要 codegen 工具升級或手動 wrapper。

---

## 附錄：範例檔案格式修正建議

`doc/usp/codegen_example/` 中的範例需更新為可運作的格式：

| 修正項目 | 舊格式 | 新格式 |
|---------|--------|--------|
| 欄位識別 | `path: Manufacturer` | `field_name: manufacturer` + `path: Device.DeviceInfo.Manufacturer` |
| 存取控制 | `access: read-write` | `writable: true` |
| 路徑格式 | `base_path` + 相對路徑 | 完整絕對路徑 |
| Transforms | array 格式 | object 格式 |
| Presets | array 格式 | object 格式 |
| 分離 `_ext.yaml` | 獨立檔案 | 嵌入主定義檔 |
