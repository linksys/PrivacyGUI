# USP Prefetch Cache Proposal

> Status: **Proposed** | Date: 2026-03-03

## Problem

USP Dashboard 目前發送 7 個順序 GET 請求（因 WASM 並行 bug），每個都是一次 WebSocket round-trip。假設每次 ~200ms，總共 ~1.4s。使用者體感載入慢。

## Root Cause

`usp_client_bg.wasm`（Rust 編譯）內部的 WebSocket 層無法正確以 `msg_id` 關聯並行的 request/response，導致 `Future.wait` 會配錯回應。修復需要改 Rust 原始碼並重編 WASM binary。

## Architecture

```
Dart (UspService)
  ↓ JS interop
JS glue (usp_client.js)        ← wasm-bindgen 自動產生
  ↓
Rust WASM (usp_client_bg.wasm) ← msg_id 邏輯在此，無法從 JS/Dart 修改
  ↓
WebSocket → Router (USP Agent)
```

## Evaluated Options

### Option 1: Codegen 加 public `fromResponse`

讓 codegen 產出 public `fromResponse(Map<String, dynamic>)` static method，provider 可以一次 GET 打包所有路徑，再分別呼叫各 class 的 parser。

#### Codegen 修改

`tools/usp-codegen` 模板需新增一個 public static method（保留現有 `fetch` + private `_fromResponse` 不變）：

**Single-instance（如 SystemInfo、TimeSettings）：**

```dart
// 現有（不動）
static Future<SystemInfo> fetch(UspService client) async { ... }
factory SystemInfo._fromResponse(Map<String, dynamic> response) { ... }

// 新增
static SystemInfo fromResponse(Map<String, dynamic> response) {
  return SystemInfo._fromResponse(response);
}
```

**Multi-instance（如 WiFiRadios、ConnectedDevices）：**

```dart
// 現有（不動）
static Future<WiFiRadios> fetch(UspService client) async { ... }
factory WiFiRadios._fromResponse(Map<String, dynamic> response) { ... }

// 新增
static WiFiRadios fromResponse(Map<String, dynamic> response) {
  return WiFiRadios._fromResponse(response);
}
```

#### Codegen CLI 變更

codegen 的 Dart template 加一個 public wrapper：

```
// In codegen template (pseudo):
static {{ClassName}} fromResponse(Map<String, dynamic> response) {
  return {{ClassName}}._fromResponse(response);
}
```

影響範圍：所有 `lib/generated/*.g.dart` 檔案會多一個 method，既有 `fetch()` 和 `_fromResponse()` 不受影響。

#### Dashboard Provider 用法

```dart
// 一次 GET 打包所有路徑
final response = await usp.get([
  // SystemInfo
  'Device.DeviceInfo.Manufacturer',
  'Device.DeviceInfo.ModelName',
  'Device.DeviceInfo.SerialNumber',
  'Device.DeviceInfo.HardwareVersion',
  'Device.DeviceInfo.SoftwareVersion',
  'Device.DeviceInfo.UpTime',
  'Device.DeviceInfo.MemoryStatus.Total',
  'Device.DeviceInfo.MemoryStatus.Free',
  'Device.DeviceInfo.ProcessStatus.CPUUsage',
  // Multi-instance tables
  'Device.Hosts.Host.',
  'Device.WiFi.Radio.',
  'Device.WiFi.SSID.',
  'Device.WiFi.AccessPoint.',
  // TimeSettings
  'Device.Time.Enable',
  'Device.Time.Status',
  'Device.Time.NTPServer1',
  'Device.Time.NTPServer2',
  'Device.Time.LocalTimeZone',
  'Device.Time.CurrentLocalTime',
  // DHCP
  'Device.DHCPv4.Server.Pool.1.StaticAddress.',
]);

// 分別 parse（0 network calls）
final systemInfo = SystemInfo.fromResponse(response);
final connectedDevices = ConnectedDevices.fromResponse(response);
final wifiRadios = WiFiRadios.fromResponse(response);
final wifiSsids = WiFiSsids.fromResponse(response);
final wifiAccessPoints = WiFiAccessPoints.fromResponse(response);
final timeSettings = TimeSettings.fromResponse(response);
final dhcpReservations = DhcpReservations.fromResponse(response);
```

#### Considerations

- **Codegen 改動小**：只加一個 1-line public wrapper，不改既有 `_fromResponse` 邏輯
- **向後相容**：既有的 `fetch()` API 完全不變，`fromResponse` 是額外的
- **路徑維護**：provider 中的路徑列表需與各 YAML 定義保持同步；若新增欄位忘記加路徑會導致 parse 時取到 null/default
- **Response 混合**：combined response 中所有 key 共存，multi-instance 的 `getInstances(basePath)` 會用 prefix match 只取自己的，不會互相干擾（已驗證 `UspResponseExtension.getInstances` 邏輯）
- **需要重編 codegen**：`tools/usp-codegen` 是 Mach-O arm64 binary，需要 Rust 原始碼修改模板後重新編譯

### Option 2: Dart 層 Prefetch Cache ✅ Recommended

在 `UspService` 加 prefetch/cache 機制，對 codegen 完全透明。

#### Flow

```
Dashboard Provider
  │
  ├── usp.prefetch([all paths])   ← 1 次 WebSocket round-trip
  │         └── _cache = { all keys → values }
  │
  ├── SystemInfo.fetch(usp)       → get() → cache hit (0ms)
  ├── ConnectedDevices.fetch(usp) → get() → cache hit (0ms)
  ├── WiFiRadios.fetch(usp)      → get() → cache hit (0ms)
  ├── WiFiSsids.fetch(usp)       → get() → cache hit (0ms)
  ├── WiFiAccessPoints.fetch(usp) → get() → cache hit (0ms)
  ├── TimeSettings.fetch(usp)    → get() → cache hit (0ms)
  ├── DhcpReservations.fetch(usp) → get() → cache hit (0ms)
  │
  └── usp.clearPrefetch()         ← 清除 cache
```

#### Implementation Sketch

```dart
// In UspService:

Map<String, dynamic>? _prefetchCache;

/// Pre-fetch all paths in one GET call, store in cache.
Future<void> prefetch(List<String> paths) async {
  _prefetchCache = await get(paths);
}

/// Clear prefetch cache after batch operations complete.
void clearPrefetch() {
  _prefetchCache = null;
}

/// Modified get() — check cache first for multi-instance prefix match.
Future<Map<String, dynamic>> get(List<String> paths) async {
  if (_prefetchCache != null) {
    final result = <String, dynamic>{};
    bool allFound = true;
    for (final path in paths) {
      if (path.endsWith('.')) {
        // Multi-instance: prefix match
        final matched = _prefetchCache!.entries
            .where((e) => e.key.startsWith(path));
        if (matched.isNotEmpty) {
          for (final e in matched) result[e.key] = e.value;
        } else {
          allFound = false; break;
        }
      } else {
        // Single param: exact match
        if (_prefetchCache!.containsKey(path)) {
          result[path] = _prefetchCache![path];
        } else {
          allFound = false; break;
        }
      }
    }
    if (allFound) return result;
  }
  // Fallback: actual network call
  // ... existing implementation ...
}
```

#### Dashboard Provider Usage

```dart
// Before individual fetches:
await usp.prefetch([
  // SystemInfo
  'Device.DeviceInfo.Manufacturer', 'Device.DeviceInfo.ModelName', ...
  // Multi-instance tables
  'Device.Hosts.Host.',
  'Device.WiFi.Radio.',
  'Device.WiFi.SSID.',
  'Device.WiFi.AccessPoint.',
  // TimeSettings
  'Device.Time.Enable', 'Device.Time.Status', ...
  // DHCP
  'Device.DHCPv4.Server.Pool.1.StaticAddress.',
]);

// These now all hit cache (0ms each):
final systemInfo = await SystemInfo.fetch(usp);
final connectedDevices = await ConnectedDevices.fetch(usp);
// ...

usp.clearPrefetch();
```

#### Considerations

- **Cache scope**: 僅在 `prefetch()` → `clearPrefetch()` 之間生效，不影響其他呼叫端
- **Multi-instance prefix match**: `Device.WiFi.Radio.` 需 match 所有 `Device.WiFi.Radio.1.*`, `Device.WiFi.Radio.2.*` etc.
- **Cache miss fallback**: 若某路徑不在 cache 中，自動 fallback 到實際網路請求
- **Thread safety**: Dart 是 single-threaded（除 isolate），無 race condition 問題

### Option 3: 修復 WASM msg_id 關聯

修復 Rust WASM binary 中的 WebSocket 層，讓每個 GET request 使用唯一 `msg_id`，response 按 `msg_id` dispatch。修好後 Dart 端直接用 `Future.wait` 並行發送。

**結論**：最理想方案，但需要 Rust 原始碼存取權和重編 WASM。列為長期目標。

## Performance Estimate

| Approach | Round-trips | Est. Time (200ms/req) |
|----------|------------|----------------------|
| Current (7 sequential) | 7 | ~1.4s |
| Option 2 (prefetch cache) | 1 | ~200ms |
| Option 3 (parallel fix) | 7 parallel | ~200ms |

## Decision

- **短期**：實作 Option 2（Dart prefetch cache）
- **長期**：追蹤 Option 3（WASM parallel fix），需 Rust 原始碼

## Related Files

- `lib/usp/services/usp_service.dart` — prefetch/cache 實作位置
- `lib/page/usp_dashboard/providers/usp_dashboard_provider.dart` — prefetch 呼叫端
- `web/usp_client.js` — wasm-bindgen glue（自動產生，勿手改）
- `web/usp_client_bg.wasm` — Rust WASM binary（msg_id 邏輯所在）
