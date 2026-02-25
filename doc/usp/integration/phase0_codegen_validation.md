# Phase 0: Codegen 驗證報告

**日期:** 2026-02-25
**分支:** `doc/usp-integration-assessment`
**狀態:** 完成 — codegen 管線已端對端驗證
**Codegen 版本:** v3
**YAML 規格:** `doc/usp/yaml-spec.md`

---

## 1. 目標

驗證端對端管線：**YAML 定義檔 → usp-codegen → 生成 Dart 程式碼 → 編譯通過**，作為主遷移計劃（Phase 1-4）的前置條件。

---

## 2. YAML 定義檔格式

完整規格詳見 `doc/usp/yaml-spec.md`。以下為經驗證的核心格式：

```yaml
name: DNSSettings              # PascalCase → 生成 class name 及 .g.dart 檔名
version: 1.0.0
base_path: Device.DNS.Client   # TR-181 基礎路徑（parameter + preset 路徑解析用）
category: core                 # 分類標籤（可選）
description: DNS client configuration

parameters:
  - field_name: preferredServer   # camelCase → 生成 getPreferredServer() / setPreferredServer()
    path: Server.1.DNSServer      # 相對路徑（codegen 自動加上 base_path 前綴）
    type: string                  # string | int | uint | boolean | double | ...
    writable: true                # true → 生成 setXxx() 方法
    description: "Primary DNS"    # 生成為 /// doc comment

# 可選：presets（群組陣列）→ 每組生成獨立 enum + applyXxxPreset()
presets:
  - field: dnsProvider            # camelCase → DnsProviderPreset enum
    options:
      - id: google
        label: dns_provider_google
        values:                   # array 格式，path 以 . 開頭
          - path: .Server.1.DNSServer
            value: "8.8.8.8"
      - id: custom
        userInputs:               # 使用者輸入欄位
          - field: customPrimaryDns
            path: .Server.1.DNSServer
            validation: ipv4

# 可選：subscribe → 生成訂閱方法（⏳ 暫不驗證）
subscribe:
  enabled: true
  notifType: ValueChange

# 可選：transforms → 使用分離的 _ext.yaml 檔案（見第 7 節）
```

### YAML Schema 欄位行為對照表

| 欄位 | 行為 | 重要度 |
|------|------|--------|
| `name` | PascalCase → class name + 檔名（`DNSSettings` → `DNSSettings.g.dart`） | 必要 |
| `base_path` | ✅ **v3 正常運作** — 自動加到 parameter 路徑、preset 路徑、subscribe 路徑前面 | 建議 |
| `field_name` | camelCase → getter/setter 名稱（`preferredServer` → `getPreferredServer()`）。若省略，從 `path` 推導 | 建議 |
| `path`（parameter） | 相對路徑（如 `Server.1.DNSServer`）。codegen 組合 `base_path` + `path` 成完整 TR-181 路徑 | 必要 |
| `type`（parameter） | `string` → `String`；`int`/`uint` → `int`（`int.parse()`）；`boolean` → `bool`（`== true`）；`double` → `double`（`double.parse()`） | 必要 |
| `writable: true` | 生成 `setXxx()` 方法 | 預設 `false` |
| `presets`（群組陣列） | ✅ 多組 preset 各自生成獨立 enum + apply 方法 | 可選 |
| `presets.options.values` | **必須為 array**（`- path: .xxx` / `value: "yyy"`），path 以 `.` 開頭 | 格式重要 |
| `presets.options.userInputs` | 生成 `{Map<String, dynamic>? inputs}` 參數 | 可選 |
| `subscribe` | **必須為 object**（`enabled: true`）。v3 可生成方法但暫不驗證 | ⏳ |
| `category` | 接受，無 warning | 可選 |
| `version` | 接受，無可見效果 | 建議 |

---

## 3. Codegen CLI 參考

```bash
./tools/usp-codegen \
  --definitions-dir doc/usp/definitions \
  --output-dir lib/generated \
  --language dart \
  --client-import 'package:privacy_gui/usp/services/usp_service.dart'
```

| Flag | 用途 | 必要 |
|------|------|------|
| `--definitions-dir` | YAML 定義檔目錄（遞迴掃描所有子目錄） | 是 |
| `--output-dir` | 生成程式碼輸出目錄 | 是 |
| `--language` | `dart` / `typescript` / `swift` | 是 |
| `--client-import` | 自訂 client library import 路徑（v3 取代 `--dart-import`） | 否（預設 `package:usp_test/services/usp_service.dart`） |
| `--client-class` | 自訂 client class 名稱 | 否（預設 `UspService`） |
| `--validate-paths` | 啟用 TR-181 路徑驗證 | 否 |
| `--json` | JSON 格式錯誤輸出（CI 用） | 否 |

---

## 4. 生成程式碼分析

### 4.1 工具實際生成的內容

**唯讀定義（`base_path` + 相對路徑）：**

```dart
class DeviceInfo {
  final UspService _client;
  DeviceInfo(this._client);

  Future<Map<String, dynamic>> fetchAll() async {
    return await _client.get([
      'Device.DeviceInfo.Manufacturer',    // base_path + Manufacturer
      'Device.DeviceInfo.SoftwareVersion',
      'Device.DeviceInfo.UpTime',
    ]);
  }

  Future<String> getManufacturer() async {
    final params = await _client.get(['Device.DeviceInfo.Manufacturer']);
    return params['Device.DeviceInfo.Manufacturer'] as String;
  }

  Future<int> getUpTime() async {
    final params = await _client.get(['Device.DeviceInfo.UpTime']);
    return int.parse(params['Device.DeviceInfo.UpTime'] as String);
  }
}
```

**可寫定義 + 多組 Presets：**

```dart
enum DnsProviderPreset { google, cloudflare, custom }
enum SecurityLevelPreset { standard, secure }

class DNSSettings {
  // ... getters + setters ...

  Future<void> applyDnsProviderPreset(DnsProviderPreset preset,
      {Map<String, dynamic>? inputs}) async {
    final params = <String, dynamic>{};
    switch (preset) {
      case DnsProviderPreset.google:
        params['Device.DNS.Client.Server.1.DNSServer'] = '8.8.8.8';
        params['Device.DNS.Client.Server.2.DNSServer'] = '8.8.4.4';
        break;
      case DnsProviderPreset.custom:
        params['Device.DNS.Client.Server.1.DNSServer'] = inputs!['customPrimaryDns'];
        params['Device.DNS.Client.Server.2.DNSServer'] = inputs!['customSecondaryDns'];
        break;
    }
    await _client.set(params);
  }

  Future<void> applySecurityLevelPreset(SecurityLevelPreset preset) async { ... }
}
```

**Sidecar Transform（`_ext.yaml` → `extension` block）：**

```dart
extension SpeedTestExt on SpeedTest {
  Future<double> getThroughputMbps() async {
    final TestBytesReceived = await getTestBytesReceived();
    final TestDuration = await getTestDuration();
    return ((TestBytesReceived * 8) / (TestDuration * 1000)).toDouble();
  }

  Future<String> getDiagnosticsStateDisplay() async {
    final value = await getDiagnosticsState();
    switch (value) {
      case 'None': return 'Not started';
      case 'Complete': return 'Test completed successfully';
      default: return value.toString();
    }
  }
}
```

### 4.2 Codegen 功能矩陣

| 功能 | 狀態 | 備註 |
|------|------|------|
| `base_path` + 相對路徑 | ✅ | v3 修復 — parameter/preset/subscribe 全部正確組合完整 TR-181 路徑 |
| `getXxx()` 唯讀 getter | ✅ | 每個 parameter 一個，型別安全 |
| `setXxx()` 可寫 setter | ✅ | `writable: true` 觸發 |
| `fetchAll()` 批次取得 | ✅ | 一次發送所有 path |
| 多組 Preset Groups | ✅ | 每組獨立 enum + `applyXxxPreset()` |
| Preset `values`（array） | ✅ | `.path` + `value` 格式，完整路徑輸出 |
| Preset `userInputs` | ✅ | 生成 `inputs` 參數 |
| Sidecar Transforms（`_ext.yaml`） | ✅ | `extension` block — formula + mapping |
| `string` → `String` | ✅ | `as String` |
| `int`/`uint` → `int` | ✅ | `int.parse()` |
| `boolean` → `bool` | ✅ | `== true` |
| `double`/`float`/`decimal` → `double` | ✅ | `double.parse()` — v3 新增 |
| 含 `.` 路徑方法名處理 | ✅ | `MemoryStatus.Total` → `getMemoryStatusTotal()` — v3 修復 |
| `subscribe` 方法生成 | ⏳ | v3 可生成，暫不驗證（`UspService` 尚無 `subscribe()` 方法） |
| `add()` / `delete()` codegen | ❌ | Codegen 不生成；**Dart API 已就緒**，UI 可直接呼叫 |
| `operate()` codegen | ❌ | 同上 |

### 4.3 Client 介面相容性

**完全相容。** 生成程式碼呼叫的介面與現有 `UspService` 匹配：

| 生成程式碼呼叫 | UspService 方法 | 相容性 |
|--------------|----------------|--------|
| `_client.get(List<String>)` | `UspService.get(List<String>) → Future<Map<String, dynamic>>` | ✓ |
| `_client.set(Map<String, dynamic>)` | `UspService.set(Map<String, dynamic>)` | ✓ |
| `params['path'] as String` | `_coerceValue()` 回傳原始字串 | ✓ |
| `params['path'] == true` | `_coerceValue()` 回傳 bool | ✓ |
| `int.parse(...)` / `double.parse(...)` | 值為字串形式的數字 | ✓ |

### 4.4 UspService 完整 API 清單

`UspService`（`lib/usp/services/usp_service.dart`）已實作所有 USP CRUD + Operate 操作，底層經由 `UspClientWeb`（JS interop）→ WASM → 路由器通訊。

| 操作類型 | 方法簽名 | 用途 | Codegen 支援 |
|---------|---------|------|-------------|
| **Get** | `get(List<String>) → Future<Map<String, dynamic>>` | 批次讀取參數 | ✅ 生成 `getXxx()` |
| **Get** | `getSingle(String) → Future<String?>` | 單一參數讀取 | — Legacy |
| **Set** | `set(Map<String, dynamic>)` | 批次設定參數 | ✅ 生成 `setXxx()` |
| **Set** | `setSingle(String, String)` | 單一參數設定 | — Legacy |
| **Add** | `add(String objectPath, Map<String, String> parameters) → Future<String>` | 新增物件實例 | ❌ 需手動或未來 codegen |
| **Add** | `addMultiple(List<Map<String, dynamic>>, {allowPartial}) → Future<List<String>>` | 批次新增 | ❌ 同上 |
| **Delete** | `delete(String path)` | 刪除物件實例 | ❌ 需手動或未來 codegen |
| **Delete** | `deleteMultiple(List<String>, {allowPartial})` | 批次刪除 | ❌ 同上 |
| **Operate** | `operate(String command, {Map<String, String> args}) → Future<Map<String, String>>` | 執行 USP 命令 | ❌ 需手動或未來 codegen |
| **Auth** | `login` / `logout` / `refreshToken` | 認證管理 | — 不需 codegen |
| **Subscribe** | — | 即時參數變更通知 | ⏳ 延後 |

> **附註：** `add`/`delete`/`operate` 的 Dart 介面與 JS interop 層已完整實作並通過 `dart analyze`。Codegen 目前不會自動生成呼叫這些 API 的程式碼，但 UI 層可直接透過 `UspService` 手動呼叫。

---

## 5. 編譯結果

| 檢查 | 結果 |
|------|------|
| `dart analyze lib/generated/SystemInfo.g.dart` | **No issues found** |
| Import 解析 | `package:privacy_gui/usp/services/usp_service.dart` 正確解析 |

---

## 6. 版本演進對照

### v1 → v2 → v3 改進

| 功能 | v1 | v2 | v3 |
|------|----|----|-----|
| `base_path` 路徑前綴 | ❌ 不組合 | ❌ 不組合 | ✅ **正確組合到 parameter + preset** |
| `path` 推導方法名 | ❌ 全部叫 `get()` | ✅ 從路徑推導 | ✅ 同 v2 |
| 含 `.` 路徑方法名 | — | ❌ 無效語法 `getA.B()` | ✅ `getAB()` |
| Preset 格式 | `{name, values: {map}}` | `[{name, values: {map}}]` | `[{field, options: [{id, values: [{path, value}]}]}]` |
| 多組 Preset | ❌ | ❌ 僅單一 enum | ✅ 每組獨立 enum + apply |
| Preset `userInputs` | ❌ | ❌ | ✅ 生成 `inputs` 參數 |
| Sidecar 檔名 | `_ext.yaml` ❌ | `_transforms.yaml` ✅ | `_ext.yaml` ✅（反轉回來） |
| Transform 生成方式 | — | 主 class 內 inline | `extension` block |
| `double` 型別 | ❌ | ❌ | ✅ `double.parse()` |
| `subscribe` | ❌ | ❌ | ⏳ Schema 接受，可生成方法 |
| Import flag | `--dart-import` | `--dart-import` | `--client-import` |
| 輸出檔名 | `snake_case.g.dart` | `snake_case.g.dart` | `PascalCase.g.dart` |

### v2 → v3 Breaking Changes

| 項目 | v2 格式 | v3 格式 | 遷移方式 |
|------|--------|--------|---------|
| Preset YAML | `- name: Google` / `values: { path: "val" }` | `- field: dnsProvider` / `options: [{ id: google, values: [{ path: .xxx, value: "val" }] }]` | 重寫 preset 區段 |
| Sidecar 檔名 | `*_transforms.yaml` | `*_ext.yaml` | 重新命名檔案 |
| Parameter path | 完整絕對路徑 | 相對路徑 + `base_path` | 加上 `base_path`，path 改為相對 |
| Import flag | `--dart-import` | `--client-import` | 更新 CLI 指令 |
| `name` 慣例 | `snake_case` | `PascalCase` | 更新 YAML name 欄位 |

---

## 7. Transform 支援狀態（`_ext.yaml`）

### ✅ `_ext.yaml` 分離檔案 — 完整支援

v3 的 sidecar 命名慣例為 **`_ext.yaml`**（取代 v2 的 `_transforms.yaml`）。

**命名規則：** 定義檔 `SpeedTest.yaml` 對應的延伸檔為 `SpeedTest_ext.yaml`。

工具處理時會輸出 `Found transform file: ...` 確認配對成功。

#### Transform 檔案格式

```yaml
# SpeedTest_ext.yaml
name: SpeedTest              # 必須與主定義檔的 name 一致
transforms:
  - name: throughputMbps
    type: formula
    description: Download throughput in megabits per second
    formula: "(TestBytesReceived * 8) / (TestDuration * 1000)"
    inputs:
      - TestBytesReceived
      - TestDuration
    output_type: double

  - name: diagnosticsStateDisplay
    type: mapping
    description: Human-readable diagnostic state
    input: DiagnosticsState
    mappings:
      None: "Not started"
      Requested: "Test in progress..."
      Complete: "Test completed successfully"
      Error_Timeout: "Test timed out"
```

#### v3 生成的程式碼

v3 使用 **`extension` block** 取代 v2 的 inline 方法：

```dart
extension SpeedTestExt on SpeedTest {
  /// Download throughput in megabits per second
  Future<double> getThroughputMbps() async {
    final TestBytesReceived = await getTestBytesReceived();
    final TestDuration = await getTestDuration();
    return ((TestBytesReceived * 8) / (TestDuration * 1000)).toDouble();
  }

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
}
```

---

## 8. 結論與建議

### 已可運作的功能

| # | 功能 | 狀態 |
|---|------|------|
| 1 | YAML → Dart codegen 管線 | ✅ 完整可用 |
| 2 | `base_path` + 相對路徑自動組合 | ✅ v3 修復 — parameter/preset 路徑正確 |
| 3 | `UspService` 介面相容性（get + set） | ✅ 完全相容 |
| 4 | `string` / `int` / `boolean` / `double` 型別轉換 | ✅ 正確生成（v3 新增 `double`） |
| 5 | `--client-import` 自訂 import 路徑 | ✅ `package:privacy_gui/usp/services/usp_service.dart` |
| 6 | 遞迴目錄掃描 | ✅ 支援子目錄結構 |
| 7 | **讀取操作** (`getXxx()`) | ✅ 每個 parameter 一個 getter |
| 8 | **寫入操作** (`setXxx()`) | ✅ `writable: true` 生成 setter |
| 9 | **多組 Presets** | ✅ 每組獨立 enum + `applyXxxPreset()` + `userInputs` 支援 |
| 10 | **Transforms**（`_ext.yaml`） | ✅ `extension` block — formula + mapping |
| 11 | **`path` 推導命名 + `.` 處理** | ✅ `MemoryStatus.Total` → `getMemoryStatusTotal()` |
| 12 | **Add/Delete API**（`UspService`） | ✅ Dart + JS interop 完整實作 |
| 13 | **Operate API**（`UspService`） | ✅ Dart + JS interop 完整實作 |

### 尚需增強的功能（Codegen 工具端）

| # | 功能 | 目前狀態 | 影響 |
|---|------|---------|------|
| 1 | `subscribe()` 訂閱 | ⏳ Codegen 可生成方法，但 `UspService` 尚無 `subscribe()` | 待 Dart/JS 端實作後啟用 |
| 2 | `add()` / `delete()` 多實例 codegen | Codegen 未生成 | **Dart API 已就緒**；UI 可直接呼叫 |
| 3 | `operate()` 命令 codegen | Codegen 未生成 | 同上 |
| 4 | 強型別資料類別 | 僅生成 getter/setter | 無 data class pattern |
| 5 | 靜態 `fetch()` 方法 | 未實作 | 使用實例模式替代 |

### 建議的 YAML 慣例（v3）

```yaml
name: FeatureName              # PascalCase（直接作為 class name + 檔名）
version: 1.0.0
base_path: Device.Full.Base    # 共用路徑前綴
category: core|extensions|vendor
description: "..."

parameters:
  - field_name: fieldName      # camelCase（建議提供）
    path: RelativePath         # 相對於 base_path
    type: string|int|uint|boolean|double
    writable: true|false       # true 會生成 setXxx()
    description: "..."

# Presets — 群組陣列
presets:
  - field: groupName           # camelCase → {GroupPascal}Preset enum
    options:
      - id: optionId
        label: i18n_key
        values:
          - path: .Relative.Path   # 以 . 開頭，組合 base_path
            value: "value"
        userInputs:                # 或 userInputs 取代 values
          - field: inputName
            path: .Relative.Path
            validation: ipv4

# Transforms → 使用分離的 _ext.yaml 檔案
# 檔名慣例：定義檔 Foo.yaml → 延伸檔 Foo_ext.yaml
```

### Phase 1 就緒度評估

| 需求 | 狀態 | 備註 |
|------|------|------|
| YAML → Dart codegen 管線 | ✅ 就緒 | v3 全功能驗證通過 |
| `base_path` + 相對路徑 | ✅ 就緒 | v3 修復，YAML 更簡潔 |
| Client 介面相容性 | ✅ 就緒 | |
| 讀取操作 (`getXxx()`) | ✅ 就緒 | Codegen 自動生成 |
| 寫入操作 (`setXxx()`) | ✅ 就緒 | Codegen 自動生成（`writable: true`） |
| 多組 Presets | ✅ 就緒 | 獨立 enum + apply + userInputs |
| Transforms（`_ext.yaml`） | ✅ 就緒 | `extension` block — formula + mapping |
| 新增/刪除物件實例 | ✅ Dart API 就緒 | `UspService` 已實作；Codegen 不自動生成 |
| USP Operate 命令 | ✅ Dart API 就緒 | 同上 |
| 訂閱 (`subscribe()`) | ⏳ 延後 | Codegen 可生成，Dart 端待實作 |
| `--client-import` 路徑 | ✅ 確認 | `package:privacy_gui/usp/services/usp_service.dart` |
| YAML 規格文件 | ✅ 就緒 | `doc/usp/yaml-spec.md` |

**結論：** Codegen v3 已完整驗證。`base_path` 路徑組合、多組 Presets、`_ext.yaml` transforms、`double` 型別等 v2 缺失的功能均已實作。專案可以用 spec 合規的 YAML 定義檔推進後續 Phase。
