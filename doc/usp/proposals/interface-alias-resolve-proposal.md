# Proposal: Interface Alias Resolution for USP Codegen

**Author:** Austin  
**Date:** 2026-05-29  
**Status:** Draft  

---

## 1. Problem Statement

### 現狀

目前 codegen 產生的 `.g.dart` 檔案使用 hardcoded interface index：

```yaml
# wan_status.yaml
instance: Device.IP.Interface.2
```

```dart
// wan_status.g.dart
static const _paths = [
  'Device.IP.Interface.2.Status',
  'Device.IP.Interface.2.IPv4Address.1.IPAddress',
  // ...
];
```

### 問題

1. **語義錯誤風險**：`Interface.2` 不一定是 WAN，不同 router 型號的 WAN/LAN index 可能不同
2. **維護困難**：如果 router firmware 更新改變了 interface mapping，需要手動修改所有相關 YAML
3. **跨型號不通用**：同一份 code 無法在不同型號 router 正確運作

### 實際案例

M60TB router 的 Interface mapping：
- `Device.IP.Interface.1.Alias = cpe-lan` (LAN)
- `Device.IP.Interface.2.Alias = cpe-wan` (WAN)

但其他型號可能相反，或使用不同的 index。

---

## 2. Proposed Solution

### 核心概念

使用 TR-181 標準的 `Alias` 參數動態 resolve interface index，而非 hardcode。

### YAML Spec 擴充

新增 `resolveBy` 欄位：

```yaml
# wan_status.yaml
name: WanStatus
description: WAN interface status and IPv4 configuration

instance: Device.IP.Interface
resolveBy:
  param: Alias
  value: cpe-wan
  fallback: 2

params:
  - name: status
    path: Status
    type: string
  - name: ipAddress
    path: IPv4Address.1.IPAddress
    type: string
  # ...
```

### 產生的 Code 行為

```dart
class WanStatus {
  // Resolve config
  static const _resolveParam = 'Alias';
  static const _resolveValue = 'cpe-wan';
  static const _resolveFallback = 2;
  
  static Future<WanStatus> fetch(UspClient client) async {
    // Step 1: Resolve interface index
    final index = await _resolveInterfaceIndex(client);
    
    // Step 2: Build paths with resolved index
    final paths = _buildPaths(index);
    
    // Step 3: Fetch data
    final response = await client.get(paths);
    return WanStatus._fromResponse(response, index);
  }
  
  static Future<int> _resolveInterfaceIndex(UspClient client) async {
    try {
      final response = await client.get(['Device.IP.Interface.*.Alias']);
      // Parse response to find matching Alias
      for (final entry in response.entries) {
        if (entry.value == _resolveValue) {
          // Extract index from path: Device.IP.Interface.{index}.Alias
          final match = RegExp(r'Interface\.(\d+)\.Alias').firstMatch(entry.key);
          if (match != null) {
            return int.parse(match.group(1)!);
          }
        }
      }
    } catch (e) {
      // Log warning, use fallback
    }
    return _resolveFallback;
  }
  
  static List<String> _buildPaths(int index) {
    return [
      'Device.IP.Interface.$index.Status',
      'Device.IP.Interface.$index.IPv4Address.1.IPAddress',
      // ...
    ];
  }
}
```

---

## 3. Design Considerations

### 3.1 效能：每次 Resolve vs Cache

| 方案 | 優點 | 缺點 |
|------|------|------|
| **A: 每次 resolve** | 簡單、無狀態 | 每次多一個 GET 請求 |
| **B: 全域 cache** | 效能好 | 需要 cache 機制、invalidation |
| **C: 傳入 resolver** | 彈性、可測試 | API 變動 |

**建議：方案 A（每次 resolve）**

理由：
- 不需要處理 cache invalidation 時機（router reboot、設定變更等）
- 避免 cache 過期但沒更新的潛在 bug
- 實作簡單、無狀態
- 多一個 GET 請求的代價可接受（Alias 查詢很輕量）

```dart
static Future<WanStatus> fetch(UspClient client) async {
  final index = await _resolveInterfaceIndex(client); // 每次都查
  final paths = _buildPaths(index);
  final response = await client.get(paths);
  return WanStatus._fromResponse(response, index);
}
```

### 3.2 Subscription 處理

Subscription 路徑需要在訂閱時確定：

```dart
static Future<Subscription<WanStatus>> subscribe(UspClient client) async {
  // 需要先 resolve index
  final index = await _resolveInterfaceIndex(client);
  
  return client.subscribe<WanStatus>(
    id: 'wan-status-valuechange',
    notifType: NotifType.valueChange,
    paths: ['Device.IP.Interface.$index.'],
    parser: (response) => WanStatus._fromResponse(response, index),
  );
}
```

### 3.3 多 Interface 情境

`multi_interface_traffic_stats` 同時需要 WAN 和 LAN：

```yaml
# multi_interface_traffic_stats.yaml
name: MultiInterfaceTrafficStats

interfaces:
  - name: wan
    resolveBy:
      param: Alias
      value: cpe-wan
      fallback: 2
  - name: lan
    resolveBy:
      param: Alias
      value: cpe-lan
      fallback: 1

params:
  - name: wanBytesSent
    interface: wan
    path: Stats.BytesSent
    type: int
  - name: lanBytesSent
    interface: lan
    path: Stats.BytesSent
    type: int
```

### 3.4 Fallback 策略

當 Alias resolve 失敗時：

```
1. GET Device.IP.Interface.*.Alias
2. 找不到 matching Alias?
   → 使用 YAML 定義的 fallback index
3. GET 請求本身失敗?
   → 使用 fallback index，log warning
4. Fallback 也失敗?
   → Throw error (router 可能有問題)
```

---

## 4. Affected Files

### YAML Definitions (需修改)

| 檔案 | 目前使用 | 改為 |
|------|----------|------|
| `wan_status.yaml` | Interface.2 | resolveBy: cpe-wan |
| `wan_settings.yaml` | Interface.2 | resolveBy: cpe-wan |
| `lan_network_info.yaml` | Interface.1 | resolveBy: cpe-lan |
| `ipv6settings.yaml` | Interface.2 | resolveBy: cpe-wan |
| `multi_interface_traffic_stats.yaml` | Interface.1 + 2 | resolveBy: cpe-lan + cpe-wan |

### Generated Files (會重新產生)

- `wan_status.g.dart`
- `wan_settings.g.dart`
- `lan_network_info.g.dart`
- `ipv6settings.g.dart`
- `multi_interface_traffic_stats.g.dart`

### Service/Provider/View

**無需修改** — API 保持不變

---

## 5. API Compatibility

### Before

```dart
final wan = await WanStatus.fetch(client);
final subscription = await WanStatus.subscribe(client);
```

### After

```dart
// 完全相同！
final wan = await WanStatus.fetch(client);
final subscription = await WanStatus.subscribe(client);
```

**對外 API 100% 相容**，只有內部實作改變。

---

## 6. Open Questions

### Q1: Cache Invalidation ✅ Resolved

**決定採用每次 resolve，不使用 cache。**

理由：避免處理 cache invalidation 的複雜性（router reboot、設定變更、session reconnect 等情境）。

### Q2: 標準 Alias 值 ✅ Confirmed

Linksys firmware 使用的 Alias 命名：
- WAN: `cpe-wan`
- LAN: `cpe-lan`
- Loopback: `cpe-loopback`（本機回環介面，不影響 WAN/LAN resolve）

**已與 FW team 確認**：不同型號的 interface index 確實可能不同（有案例 WAN/LAN index 是反過來的），所以必須用 Alias 判斷。

### Q3: 多 WAN 支援

如果未來支援 dual-WAN，需要 resolve 多個 WAN interface：
- `cpe-wan` (primary)
- `cpe-wan2` (secondary)

目前是否需要考慮？

**建議**：MVP 只處理單一 WAN/LAN，multi-WAN 未來再擴充

### Q4: Codegen 實作時程

| Task | 估計工時 |
|------|----------|
| YAML spec 定義 | 0.5d |
| Codegen 修改 | 2-3d |
| 測試 | 1d |
| **Total** | **3-4d** |

---

## 7. Recommendation

**建議採用此方案**，原因：

1. **語義正確** — WanStatus 真的是 WAN，不是「碰巧 Interface.2」
2. **跨型號通用** — 同一份 code 可在不同 router 運作
3. **向後相容** — 外部 API 不變，上層無需修改
4. **標準化** — 使用 TR-181 標準的 Alias 機制

---

## 8. Next Steps

1. [x] 確認 M60TB 的 WAN/LAN Alias 實際值 — `cpe-wan`, `cpe-lan`
2. [x] 確認其他 Linksys 型號的 Alias 命名是否一致 — FW team 確認一致，但 index 可能不同
3. [ ] Review 此 proposal
4. [ ] 實作 codegen 修改
5. [ ] 更新 YAML definitions
6. [ ] 重新產生 .g.dart 並驗證

---

## Appendix: TR-181 Alias Reference

根據 TR-181 規範，`Device.IP.Interface.{i}.Alias` 是：

> A non-volatile unique key used to reference this instance. Alias provides a mechanism for a Controller to label this instance for future reference.

常見值：
- `cpe-lan` — LAN interface
- `cpe-wan` — WAN interface
- `cpe-loopback` — Loopback interface
