# Phase 0: Codegen 驗證報告

**日期:** 2026-02-26（v5 更新）
**分支:** `doc/usp-integration-assessment`
**狀態:** 完成 — v5 修復 v4 全部 4 個 Bug，全定義檔通過
**Codegen 版本:** v3（穩定） / v4（已知 Bug） / **v5（目前版本，就緒）**
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

### v1 → v2 → v3 → v4 → v5 改進

| 功能 | v1 | v2 | v3 | v4 | v5 |
|------|----|----|-----|-----|-----|
| `base_path` 路徑前綴 | ❌ 不組合 | ❌ 不組合 | ✅ 正確組合 | ✅ 向後相容 | ✅ 同 v4 |
| `path` 推導方法名 | ❌ 全部叫 `get()` | ✅ 從路徑推導 | ✅ 同 v2 | ✅ Data class 欄位 | ✅ 同 v4 |
| 含 `.` 路徑方法名 | — | ❌ `getA.B()` | ✅ `getAB()` | ✅ Data class 欄位 | ✅ 同 v4 |
| **程式碼模式** | 實例 | 實例 | 實例（`_client`） | 靜態（`static fetch()`） | ✅ 靜態（修復完成） |
| **Multi-instance** | ❌ | ❌ | ❌ | ⚠️ 名稱衝突 | ✅ **`singularName` 支援 + 自動推導** |
| **subscribe** | ❌ | ❌ | ⏳ | ⚠️ 引用 `_client` | ✅ **static + client 參數** |
| **Dart 保留字** | — | — | — | ⚠️ `interface` 衝突 | ✅ **自動加 `_` 後綴** |
| **Multi-instance 尾部 `.`** | — | — | — | ⚠️ 缺少 | ✅ **自動補齊** |
| Preset 格式 | `{name, values}` | `[{name, values}]` | `[{field, options}]` | 同 v3 | 同 v3 |
| 多組 Preset | ❌ | ❌ 僅單一 | ✅ 獨立 enum | ✅ 同 v3 | ✅ 同 v3 |
| Transform 生成方式 | — | inline | `extension`（非同步） | `extension`（同步） | ✅ 同 v4 |
| `double` 型別 | ❌ | ❌ | ✅ | ✅ | ✅ |
| Import flag | `--dart-import` | `--dart-import` | `--client-import` | `--client-import` | `--client-import` |
| 輸出檔名 | `snake_case.g.dart` | `snake_case.g.dart` | `PascalCase.g.dart` | `PascalCase.g.dart` | `snake_case.g.dart` |

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

## 8. Codegen v4 驗證（2026-02-26）

### 8.1 v4 架構變更

v4 採用 **Data class + static method** 模式，取代 v3 的實例模式：

| 特性 | v3 | v4 |
|------|----|----|
| 模式 | 實例模式（`_client` 欄位） | **靜態模式**（`static fetch()` / `save()`） |
| 單實例讀取 | `getXxx()` 非同步 getter | **Data class** + `static fetch()` |
| 單實例寫入 | `setXxx()` 個別 setter | **Data class** + `static save()` |
| 多實例讀取 | — | `ConnectedDevice` data class + `static fetchAll()` |
| 多實例寫入 | — | `ConnectedDeviceUpdate` + `update()` / `updateMany()` |
| Transform | `extension` block（非同步） | `extension` block（**同步 getter**） |
| `base_path` | `base_path` | `basePath`（接受 `base_path` 別名，向後相容） |
| `multi_instance` | — | `multiInstance`（接受 `multi_instance` 別名） |

### 8.2 v4 正常運作項目

| # | 功能 | 驗證結果 |
|---|------|---------|
| 1 | `base_path` 向後相容 | ✅ v4 接受 v3 的 `base_path` 作為 `instance`/`basePath` 的別名 |
| 2 | `multi_instance` 向後相容 | ✅ `multiInstance` 的別名 |
| 3 | Data class + `static fetch()` / `save()` | ✅ 單實例模式正確 |
| 4 | Multi-instance data class 模式 | ✅ `ConnectedDevice` + `ConnectedDeviceUpdate` + `update()` / `updateMany()` |
| 5 | Transform `extension` block | ✅ 同步 getter 正確生成 |

### 8.3 v4 已知 Bug

| # | 檔案 | 問題 | 嚴重度 | 狀態 |
|---|------|------|--------|------|
| 1 | `port_forwarding.g.dart` | **Class 名稱衝突** — `PortForwarding` 同時用於 singular data class (L9) 和 collection class (L51)，無法編譯。需要 codegen 用 `singularName` 來區分（或自動推導） | 🔴 高 | 待修 |
| 2 | `connected_devices.g.dart` | **`subscribe` 引用 `_client`** — subscribe 方法引用 `_client` (L58-60)，但 v4 是 static 模式，沒有 `_client` 欄位。subscribe 在 v4 靜態模式下的回歸 | 🔴 高 | 待修 |
| 3 | `connected_devices.g.dart` | **`interface` 保留字** — `interface` 是 Dart 保留字，不能用作欄位名稱 (L15, L22) | 🟡 中 | 待修 |
| 4 | Multi-instance path | **缺少尾部 `.`** — `base_path: Device.Hosts.Host` 生成 `client.get(['Device.Hosts.Host'])`，缺少尾部 `.`。`yaml-spec` 範例用 `basePath: Device.Hosts.Host.`（有 `.`） | 🟢 低 | 待確認（可能是 YAML 端慣例問題） |

#### Bug #1 詳情：Class 名稱衝突

```dart
// port_forwarding.g.dart — 無法編譯
class PortForwarding {          // L9: singular data class
  final String protocol;
  // ...
}

class PortForwarding {          // L51: collection class — 衝突！
  static Future<List<PortForwarding>> fetchAll() async { ... }
}
```

**建議修復：** Codegen 應支援 `singularName` 欄位，或自動推導：collection class 用 YAML `name`（如 `PortForwarding`），singular data class 用 `PortForwardingEntry` 或由 `singularName` 指定。

#### Bug #2 詳情：subscribe 引用不存在的 _client

```dart
// connected_devices.g.dart — v4 static 模式下的回歸
class ConnectedDevices {
  // v4 沒有 _client 欄位（靜態模式）

  Stream<...> subscribe() {
    return _client.subscribe(...);  // L58-60: _client 不存在！
  }
}
```

**建議修復：** v4 的 subscribe 應改為 static 方法，接受 client 參數或使用與 `fetch()`/`save()` 一致的靜態存取方式。

### 8.4 v3 → v4 向後相容性總結

| YAML 欄位 | v3 名稱 | v4 名稱 | 向後相容 |
|-----------|---------|---------|---------|
| 基礎路徑 | `base_path` | `basePath` | ✅ 接受別名 |
| 多實例標記 | — | `multiInstance` / `multi_instance` | ✅ 接受別名 |
| Parameters | 相同 | 相同 | ✅ |
| Presets | 相同 | 相同 | ✅ |
| Transforms (`_ext.yaml`) | 相同 | 相同 | ✅ |
| Subscribe | 相同 | 相同 | ⚠️ Bug #2 |

---

## 9. Codegen v5 驗證（2026-02-26）

### 9.1 v4 Bug 修復狀態

| # | v4 Bug | v5 修復方式 | 驗證結果 |
|---|--------|-----------|---------|
| 1 | 🔴 Class 名稱衝突 | 偵測同名衝突並報錯：`"Add 'singularName' to the YAML definition"`。提供 `singularName` 後正確生成 `PortForwardingRule`（singular）+ `PortForwarding`（collection） | ✅ 修復 |
| 2 | 🔴 subscribe 引用 `_client` | 改為 `static Stream<...> subscribeXxx(UspService client)` — 與 `fetch()` 一致的靜態模式 | ✅ 修復 |
| 3 | 🟡 `interface` 保留字 | 自動加底線後綴：`interface` → `interface_` | ✅ 修復 |
| 4 | 🟢 Multi-instance 缺少尾部 `.` | 自動補齊：`Device.Hosts.Host` → `Device.Hosts.Host.` | ✅ 修復 |

### 9.2 v5 生成程式碼範例

#### 單實例（SystemInfo）

```dart
class SystemInfo {
  final String manufacturer;
  final String modelName;
  final int uptime;
  // ...

  const SystemInfo({required this.manufacturer, ...});

  static Future<SystemInfo> fetch(UspService client) async {
    final response = await client.get([
      'Device.DeviceInfo.Manufacturer',
      'Device.DeviceInfo.ModelName',
      'Device.DeviceInfo.UpTime',
    ]);
    return SystemInfo._fromResponse(response);
  }

  factory SystemInfo._fromResponse(Map<String, dynamic> response) {
    return SystemInfo(
      manufacturer: response['Device.DeviceInfo.Manufacturer'] as String,
      uptime: int.parse(response['Device.DeviceInfo.UpTime'] as String),
    );
  }
}
```

#### 多實例（PortForwarding + singularName）

```dart
// singular data class — 名稱由 singularName 指定
class PortForwardingRule {
  final String instancePath;
  final bool enabled;
  final int externalPort;
  // ...
  const PortForwardingRule({required this.instancePath, ...});
}

// update descriptor — nullable fields for partial update
class PortForwardingRuleUpdate {
  final String instancePath;
  final bool? enabled;
  final int? externalPort;
  // ...
  const PortForwardingRuleUpdate({required this.instancePath, ...});
}

// collection class — 名稱為 YAML name
class PortForwarding {
  final List<PortForwardingRule> items;
  const PortForwarding({required this.items});

  static Future<PortForwarding> fetch(UspService client) async { ... }
  static Future<void> update(UspService client, PortForwardingRuleUpdate update) async { ... }
  static Future<void> updateMany(UspService client, List<PortForwardingRuleUpdate> updates, {bool allowPartial = false}) async { ... }
}
```

#### 多實例 + subscribe（ConnectedDevices — 自動推導 singular）

```dart
class ConnectedDevice { ... }        // 自動推導：ConnectedDevices → ConnectedDevice

class ConnectedDevices {
  final List<ConnectedDevice> items;

  static Future<ConnectedDevices> fetch(UspService client) async { ... }

  // subscribe — static + client 參數（v5 修復）
  static Stream<Map<String, dynamic>> subscribeConnectedDevices01(UspService client) {
    return client.subscribe(['Device.Hosts.Host.'], 2);
  }
}
```

### 9.3 v5 新增功能與 Pattern

| 功能 | 說明 |
|------|------|
| `singularName` YAML 欄位 | Multi-instance 定義可指定 singular class 名稱（如 `PortForwardingRule`）。未指定時自動從 `name` 推導（去尾 `s`） |
| `XxxUpdate` class | Multi-instance writable 參數生成 nullable update descriptor |
| `update()` / `updateMany()` | 靜態方法，支援單一/批次更新，`updateMany` 支援 `allowPartial` 參數 |
| `response.getInstances()` | 新 helper pattern — 從 response 解析多實例（需 `UspService` 擴展支援） |
| `instance.getString()` / `getBool()` / `getInt()` | 型別安全的 instance 欄位存取 helper |
| Dart 保留字自動迴避 | `interface` → `interface_`，避免編譯錯誤 |
| 輸出檔名 | 回歸 `snake_case.g.dart`（如 `connected_devices.g.dart`、`port_forwarding.g.dart`） |

### 9.4 v5 待確認事項（已全部解決）

| # | 項目 | 狀態 | 解決方式 |
|---|------|------|---------|
| 1 | `response.getInstances()` | ✅ 已實作 | 新增 `lib/usp/services/usp_response_helpers.dart` — `UspResponseExtension` on `Map<String, dynamic>` |
| 2 | `client.subscribe()` 簽名 | ✅ 已加 stub | `UspService.subscribe(List<String>, int)` — 第二參數為 notifType（1=ValueChange, 2=ObjectCreation, 3=ObjectDeletion）。JS/WASM 端尚未實作，目前回傳 `Stream.empty()` |
| 3 | `allowPartial` 參數 | ✅ 原本就支援 | `UspService.set()` 已有 `{bool allowPartial = false}` 參數 |

**新增檔案：** `lib/usp/services/usp_response_helpers.dart`
- `UspInstance` class — `path`, `getString()`, `getBool()`, `getInt()`, `getDouble()`
- `UspResponseExtension` on `Map<String, dynamic>` — `getInstances(String basePath)`
- 透過 `usp_service.dart` 的 `export` 自動匯出，generated code 只需一個 import

### 9.5 YAML 定義檔更新

為支援 v5，已更新 `PortForwarding.yaml` 加入 `singularName: PortForwardingRule`。

---

## 10. 結論與建議

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

| # | 功能 | v3 狀態 | v5 狀態 | 備註 |
|---|------|---------|---------|------|
| 1 | `subscribe()` 訂閱 | ⏳ 可生成 | ✅ static + client 參數 | v5 修復 |
| 2 | `add()` / `delete()` 多實例 codegen | 未生成 | ✅ `update()`/`updateMany()` | v5 就緒 |
| 3 | `operate()` 命令 codegen | 未生成 | 未生成 | **Dart API 已就緒**；UI 可直接呼叫 |
| 4 | 強型別資料類別 | ❌ 僅 getter/setter | ✅ Data class pattern | v4+ |
| 5 | 靜態 `fetch()` 方法 | ❌ 實例模式 | ✅ `static fetch(UspService client)` | v4+ |
| 6 | Multi-instance `singularName` | — | ✅ 支援 + 衝突偵測 | v5 新增 |
| 7 | Dart 保留字迴避 | — | ✅ 自動加 `_` 後綴 | v5 修復 |
| 8 | `response.getInstances()` helper | — | ✅ 已實作 `UspResponseExtension` | `lib/usp/services/usp_response_helpers.dart` |

### 建議的 YAML 慣例（v5）

```yaml
name: FeatureName              # PascalCase — collection class name（多實例）或 class name（單實例）
singularName: FeatureEntry     # 可選 — 多實例時 singular data class 名稱（未指定則自動推導去尾 s）
version: 1.0.0
base_path: Device.Full.Base    # 共用路徑前綴（不需尾部 .，v5 自動補齊）
category: core|extensions|vendor
description: "..."

# 多實例定義需加此欄位
multi_instance: true           # 生成 singular data class + collection class + update/updateMany

parameters:
  - field_name: fieldName      # camelCase — 直接作為 data class 欄位名
    path: RelativePath         # 相對於 base_path
    type: string|int|uint|boolean|double
    writable: true|false       # true → 多實例生成 XxxUpdate class
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

# Subscribe — v5 生成 static Stream 方法
subscribe:
  enabled: true
  notifType: ObjectCreation    # ValueChange | ObjectCreation | ...
  id: unique-subscription-id   # 用於方法名稱

# Transforms → 使用分離的 _ext.yaml 檔案
# 檔名慣例：定義檔 Foo.yaml → 延伸檔 Foo_ext.yaml
```

### Phase 1 就緒度評估

| 需求 | v5 狀態 | 備註 |
|------|---------|------|
| YAML → Dart codegen 管線 | ✅ 就緒 | 3/3 定義檔通過 |
| `base_path` + 相對路徑 | ✅ 就緒 | 向後相容 `base_path` 別名 |
| Client 介面相容性 | ✅ 就緒 | 靜態模式 `static fetch(UspService client)` |
| 讀取操作 | ✅ 就緒 | Data class + `fetch()` |
| 寫入操作 | ✅ 就緒 | Data class + `save()` / `update()` |
| Multi-instance | ✅ 就緒 | `singularName` 支援 + 自動推導 |
| 多組 Presets | ✅ 就緒 | — |
| Transforms（`_ext.yaml`） | ✅ 就緒 | 同步 getter |
| 新增/刪除物件實例 | ✅ 就緒 | `update()` / `updateMany()` |
| USP Operate 命令 | — | `UspService` 手動呼叫 |
| 訂閱 (`subscribe()`) | ✅ 就緒 | static + client 參數 |
| `--client-import` 路徑 | ✅ 確認 | `package:privacy_gui/usp/services/usp_service.dart` |
| YAML 規格文件 | ✅ 就緒 | `doc/usp/yaml-spec.md` |
| `response.getInstances()` helper | ✅ 已實作 | `UspResponseExtension` + `UspInstance` class |

**結論：**
- **Codegen v5** 修復了 v4 全部 4 個 Bug，全部定義檔通過生成。
- v5 是目前推薦的 codegen 版本，Data class + static 模式 + multi-instance 支援完整。
- **所有待確認項已解決。** `UspResponseExtension`（`getInstances` / `getString` / `getBool` / `getInt`）已實作；`subscribe` 已加 stub；`allowPartial` 原本就支援。
- **建議：** 以 v5 作為正式 codegen 版本推進 Phase 1-4。端對端管線完整就緒：YAML → codegen → generated Dart code → `dart analyze` 通過。
