# 計劃：適配 Service 層至新 USP Client & Codegen v0.12.1

## 背景

分支 `hank/l1-service-merge-new-usp-client` 上 **usp-codegen v0.12.1** 已重新生成所有 `.g.dart`。生成的程式碼對 `UspClient` 的 `add()`/`delete()` 呼叫同時有兩種模式（批量 + 單筆子項），但當前 `UspClient` 將這些 API 分離為 `add`/`addMultiple`、`delete`/`deleteMultiple`，造成編譯錯誤。此外 service 層仍在呼叫舊的 `save()`、`updateMany()` 及命名參數的 `add()` — 這些 API 在新生成的程式碼中已不存在。

## 差異總覽

### UspClient 需統一的方法（除了 setOrdered 外全部統一）

| WASM 層（分離） | UspClient 統一後 | 分派邏輯 |
|--|--|--|
| `get(String)` + `getMultiple(List<String>)` | `get(List<String>, {priority})` | 不變，固定 List |
| `set(String, String)` + `setMultiple(Map, {allowPartial})` | `set(Object, [dynamic], {allowPartial})` | **唯一 dynamic**：`String` → 單筆，`Map` → 批量 |
| `add(String, Map)` + `addMultiple(List, {allowPartial})` | `add(List<Map>, {allowPartial})` | 固定 List，內部依長度分派 |
| `delete(String)` + `deleteMultiple(List, {allowPartial})` | `delete(List<String>, {allowPartial})` | 固定 List，內部依長度分派 |
| `*WithResult` 全部（6 個方法） | **移除**（技術債） | service 層不使用，codegen 才是正確抽象層 |
| `operate(String, {args})` | 不變 | |
| `setOrdered` / `setOrderedWithOptions` | 獨立保留 | **唯一例外** |

**設計原則：** UspClient 是中間層，向上適配 codegen 生成的呼叫，向下對接 WASM client 的分離方法。

**參數型別規則：**
- `get(List<String>, {priority})` — 不變，內部呼叫 `_client.getMultiple()`
- `set(Object, [dynamic], {allowPartial})` — **唯一 dynamic**：`(String, String)` → `_client.set()`，`(Map)` → `_client.setMultiple()`
- `add(List<Map>, {allowPartial})` — 固定 List，內部自動判斷單筆（`_client.add`）或批量（`_client.addMultiple`）
- `delete(List<String>, {allowPartial})` — 固定 List，內部自動判斷單筆（`_client.delete`）或批量（`_client.deleteMultiple`）

**codegen v0.12.1 已更新** — 子項方法也統一為 List 呼叫（`client.add([{...}])`、`client.delete([path])`）。

### Service 層 Breaking Changes（完整清單）

**A. `save()` → `update()`（7 處）：**
- `lib/page/admin/services/usp_admin_service.dart` :59, :78 — `TimeSettings.save()`
- `lib/page/local_network/services/usp_local_network_service.dart` :32 — `LanNetworkInfo.save()`
- `lib/page/internet_settings/services/usp_internet_settings_service.dart` :267, :282, :341 — `WanSettings.save()`, `Ipv6Settings.save()`
- `lib/page/instant_safety/services/instant_safety_service.dart` :42 — `LanNetworkInfo.save()`

**B. `updateMany()` → 手動合併或逐筆 `update()`（12 處）：**
- `lib/page/dhcp/services/usp_dhcp_service.dart` :142
- `lib/page/port_forwarding/services/usp_port_forwarding_service.dart` :182, :278
- `lib/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart` :102
- `lib/page/static_routing/services/usp_static_routing_service.dart` :112
- `lib/page/instant_privacy/services/instant_privacy_service.dart` :208, :218, :230
- `lib/page/wifi_settings/services/usp_wifi_settings_service.dart` :225, :257
- `lib/page/wifi/services/wifi_settings_service.dart` :139
- `lib/page/firewall/services/usp_firewall_service.dart` :68

**C. `ClassName.add()` 命名參數 → `List<Map>` 原始參數 Map（10 處）：**
- `lib/page/dhcp/services/usp_dhcp_service.dart` :62, :112
- `lib/page/dmz/services/usp_dmz_service.dart` :50
- `lib/page/internet_settings/services/usp_internet_settings_service.dart` :189, :228
- `lib/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart` :63
- `lib/page/port_forwarding/services/usp_port_forwarding_service.dart` :81, :146, :224
- `lib/page/static_routing/services/usp_static_routing_service.dart` :76

**D. `ClassName.delete()` 單字串 → `List<String>`（8 處）：**
- `lib/page/dhcp/services/usp_dhcp_service.dart` :71, :101
- `lib/page/internet_settings/services/usp_internet_settings_service.dart` :203, :242
- `lib/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart` :52
- `lib/page/port_forwarding/services/usp_port_forwarding_service.dart` :136, :218
- `lib/page/static_routing/services/usp_static_routing_service.dart` :65

---

## 實施計劃

### 第一階段：統一 UspClient API（2 個檔案）

**`lib/core/usp/services/usp_client.dart`：**

#### 1. `get` — 不變

```dart
// 簽名不變，已是 List<String>
Future<Map<String, dynamic>> get(List<String> paths, {RequestPriority? priority})
```

#### 2. 統一 `set` — 唯一 dynamic

```dart
// 舊：set(Map, {allowPartial}) + setMultiple(Map<String, String>, {allowPartial})
// 新：set(Object, [dynamic], {allowPartial}) — (String, String) 或 (Map)
Future<Map<String, dynamic>> set(Object pathOrParams, [dynamic singleValue],
    {bool allowPartial = false}) async {
  if (pathOrParams is String && singleValue != null) {
    return await _singleSet(pathOrParams, singleValue.toString());
  } else if (pathOrParams is Map) {
    return await _batchSet(pathOrParams.cast<String, dynamic>(), allowPartial: allowPartial);
  }
  throw ArgumentError('set() expects (String, value) or (Map<String, dynamic>)');
}
```

- 現有 `set(Map...)` 邏輯 → `_batchSet`
- 新增 `_singleSet(String, String)` → 呼叫 `_client.set(path, value)`
- 移除 `setMultiple` 公開方法

#### 3. 統一 `add` — 固定 List

```dart
// 舊：add(String, Map) + addMultiple(List, {allowPartial})
// 新：add(List<Map>, {allowPartial}) — 內部依長度選擇 WASM 方法
Future<Map<String, dynamic>> add(List<Map<String, dynamic>> items,
    {bool allowPartial = false}) async {
  if (items.length == 1) {
    final item = items.first;
    return await _singleAdd(item['path'] as String, item['params'] as Map<String, dynamic>? ?? {});
  }
  return await _batchAdd(items, allowPartial: allowPartial);
}
```

- 現有 `add(String, Map)` 邏輯 → `_singleAdd`（內部）
- 現有 `addMultiple(List, {allowPartial})` 邏輯 → `_batchAdd`（內部）
- 移除 `addMultiple` 公開方法

#### 4. 統一 `delete` — 固定 List

```dart
// 舊：delete(String) + deleteMultiple(List, {allowPartial})
// 新：delete(List<String>, {allowPartial}) — 內部依長度選擇 WASM 方法
Future<Map<String, dynamic>> delete(List<String> paths,
    {bool allowPartial = false}) async {
  if (paths.length == 1) {
    return await _singleDelete(paths.first);
  }
  return await _batchDelete(paths, allowPartial: allowPartial);
}
```

- 現有 `delete(String)` 邏輯 → `_singleDelete`（內部）
- 現有 `deleteMultiple(List, {allowPartial})` 邏輯 → `_batchDelete`（內部）
- 移除 `deleteMultiple` 公開方法

#### 5. 移除 `*WithResult` 變體（技術債清理）

移除所有 `*WithResult` 方法：`getWithResult`、`setWithResult`、`addWithResult`、`addMultipleWithResult`、`deleteWithResult`、`deleteMultipleWithResult`。

**理由：** Service 層 100% 透過 codegen 呼叫，從不直接使用 `*WithResult`。唯一使用者是 test console（改用 `set()` + 手動解析）。結構化錯誤處理應由 codegen 在 `.g.dart` 內部實作，而非 UspClient 公開 API。

同時移除相關型別（如 `UspResultParser`、`UspGetResult` 等 type aliases）— 若無其他引用者。

---

**`lib/demo/usp/demo_usp_service.dart`：**

1. `get` override — 不變（已是 `List<String>`）
2. 統一 `set` override — dynamic 分派（`(String, String)` 或 `(Map)`）
3. 統一 `add` override — `List<Map>` 簽名，內部迭代呼叫單筆邏輯
4. 統一 `delete` override — `List<String>` 簽名，內部迭代呼叫單筆邏輯
5. 移除 `addMultiple` / `deleteMultiple` / `setMultiple` override

**不需修改：**
- `lib/core/usp/web/usp_client_wasm.dart` — 內部 WASM 層保留分離方法
- `lib/core/usp/stub/usp_client_stub.dart` — 內部 stub 層保留分離方法

### 第二階段：驗證生成的程式碼可編譯

```bash
flutter analyze lib/generated/
```

Phase 1 完成後，所有 `.g.dart` 應零錯誤。

### 第三階段：更新 Service 層（14 個檔案，37 處修改）

按 4 種模式系統性修改：

**模式 A — `save()` → `update()`（7 處）：**
```dart
// 舊：TimeSettings.save(_usp, enable: true, ntpServer1: 'pool.ntp.org')
// 新：TimeSettings.update(_usp, enable: true, ntpServer1: 'pool.ntp.org')
// 注意：參數不變，僅方法名改變
```

**模式 B — `updateMany()` → 手動合併 `_usp.set()` 或逐筆 `update()`（12 處）：**

優先使用手動合併（效能較佳，一次 SET）：
```dart
// 舊：await DhcpReservations.updateMany(_usp, toUpdate);
// 新（手動合併）：
final params = <String, dynamic>{};
for (final u in toUpdate) {
  if (u.enable != null) params['${u.instancePath}Enable'] = u.enable;
  if (u.chaddr != null) params['${u.instancePath}Chaddr'] = u.chaddr;
  if (u.yiaddr != null) params['${u.instancePath}Yiaddr'] = u.yiaddr;
}
if (params.isNotEmpty) await _usp.set(params);
```

備選方案（較簡潔但 N 次請求）：
```dart
for (final u in toUpdate) {
  await DhcpReservations.update(_usp, u);
}
```

**模式 C — `ClassName.add(named params)` → `ClassName.add(client, [Map])`（10 處）：**
```dart
// 舊：await DhcpReservations.add(_usp, enable: true, chaddr: mac, yiaddr: ip)
// 新：await DhcpReservations.add(_usp, [{'Enable': true, 'Chaddr': mac, 'Yiaddr': ip}])
```

**模式 D — `ClassName.delete(client, String)` → `ClassName.delete(client, [String])`（8 處）：**
```dart
// 舊：await DhcpReservations.delete(_usp, instancePath)
// 新：await DhcpReservations.delete(_usp, [instancePath])
```

**完整檔案對照表：**

| # | 檔案 | 模式 | 修改數 |
|---|------|------|--------|
| 1 | `lib/page/admin/services/usp_admin_service.dart` | A | 2 |
| 2 | `lib/page/local_network/services/usp_local_network_service.dart` | A | 1 |
| 3 | `lib/page/instant_safety/services/instant_safety_service.dart` | A | 1 |
| 4 | `lib/page/internet_settings/services/usp_internet_settings_service.dart` | A+C+D | 6 |
| 5 | `lib/page/dhcp/services/usp_dhcp_service.dart` | B+C+D | 5 |
| 6 | `lib/page/dmz/services/usp_dmz_service.dart` | C | 1 |
| 7 | `lib/page/port_forwarding/services/usp_port_forwarding_service.dart` | B+C+D | 7 |
| 8 | `lib/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart` | B+C+D | 3 |
| 9 | `lib/page/static_routing/services/usp_static_routing_service.dart` | B+C+D | 4 |
| 10 | `lib/page/instant_privacy/services/instant_privacy_service.dart` | B | 3 |
| 11 | `lib/page/wifi_settings/services/usp_wifi_settings_service.dart` | B | 2 |
| 12 | `lib/page/wifi/services/wifi_settings_service.dart` | B | 1 |
| 13 | `lib/page/firewall/services/usp_firewall_service.dart` | B | 1 |

### 第四階段：更新測試

- 搜尋所有 `when(() => mockUsp.add(` / `mockUsp.delete(` / `mockUsp.addMultiple(` / `mockUsp.deleteMultiple(`
- 更新 mock stub 以匹配統一簽名
- 更新 verify 斷言的參數預期
- 搜尋所有 `.save(` / `.updateMany(` 呼叫並更新

### 第五階段：驗證

1. `flutter analyze lib/` — 零錯誤
2. `flutter test` — 全部通過
3. Web 手動測試 — CRUD 操作端對端正常

---

## 主要風險

1. **執行時型別分派** 僅 `set` 使用 dynamic — `add`/`delete`/`get` 均為強型別 List
2. **`updateMany` 移除** 影響最廣（12 處）— 推薦手動合併為單次 `_usp.set()` 以維持效能
3. **內部 WASM 呼叫不受影響** — `createNotifySubscription` / `purgeAllSubscriptions` 使用 `_client.add/delete`（WASM 層）
