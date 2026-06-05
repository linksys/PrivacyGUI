# Codegen Implementation: resolveBy Feature

**Author:** Austin  
**Date:** 2026-05-29  
**Status:** Draft  
**Parent:** [interface-alias-resolve-proposal.md](interface-alias-resolve-proposal.md)

---

## 1. Scope

本文件定義 `usp-codegen` 工具支援 `resolveBy` 功能的實作規格。

### In Scope

- YAML spec 新增 `resolveBy` 語法
- Codegen 解析與程式碼產生邏輯
- 產生的 Dart code 結構
- 錯誤處理與 fallback 機制

### Out of Scope

- 上層 Service/Provider 改動（無需改動）
- Cache 機制（決定不實作）
- Multi-WAN 支援（未來擴充）

---

## 2. YAML Spec Extension

### 2.1 新增欄位：`resolveBy`

```yaml
resolveBy:
  param: <string>      # 用於 resolve 的參數名稱（必填）
  value: <string>      # 要匹配的值（必填）
  fallback: <int>      # resolve 失敗時的 fallback index（必填）
```

### 2.2 完整範例：wan_status.yaml

**Before:**
```yaml
name: WanStatus
description: WAN interface status and IPv4 configuration

instance: Device.IP.Interface.2

params:
  - name: status
    path: Status
    type: string
  - name: ipAddress
    path: IPv4Address.1.IPAddress
    type: string
  - name: subnetMask
    path: IPv4Address.1.SubnetMask
    type: string
  - name: addressingType
    path: IPv4Address.1.AddressingType
    type: string
  - name: maxMtuSize
    path: MaxMTUSize
    type: int
  - name: ipv6Enabled
    path: IPv6Enable
    type: bool
```

**After:**
```yaml
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
  - name: subnetMask
    path: IPv4Address.1.SubnetMask
    type: string
  - name: addressingType
    path: IPv4Address.1.AddressingType
    type: string
  - name: maxMtuSize
    path: MaxMTUSize
    type: int
  - name: ipv6Enabled
    path: IPv6Enable
    type: bool
```

### 2.3 多 Interface 範例：multi_interface_traffic_stats.yaml

```yaml
name: MultiInterfaceTrafficStats
description: Traffic statistics for WAN and LAN interfaces

interfaces:
  - id: wan
    instance: Device.IP.Interface
    resolveBy:
      param: Alias
      value: cpe-wan
      fallback: 2
  - id: lan
    instance: Device.IP.Interface
    resolveBy:
      param: Alias
      value: cpe-lan
      fallback: 1

params:
  - name: wanBytesSent
    interface: wan
    path: Stats.BytesSent
    type: int
  - name: wanBytesReceived
    interface: wan
    path: Stats.BytesReceived
    type: int
  - name: lanBytesSent
    interface: lan
    path: Stats.BytesSent
    type: int
  - name: lanBytesReceived
    interface: lan
    path: Stats.BytesReceived
    type: int
```

---

## 3. Generated Code Structure

### 3.1 單一 Interface（wan_status.g.dart）

```dart
// AUTO-GENERATED CODE - DO NOT EDIT

import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// WAN interface status and IPv4 configuration
class WanStatus {
  final String status;
  final String ipAddress;
  final String subnetMask;
  final String addressingType;
  final int maxMtuSize;
  final bool ipv6Enabled;

  const WanStatus({
    required this.status,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
    required this.maxMtuSize,
    required this.ipv6Enabled,
  });

  // ============================================================
  // Resolve Configuration
  // ============================================================
  
  static const _instanceBase = 'Device.IP.Interface';
  static const _resolveParam = 'Alias';
  static const _resolveValue = 'cpe-wan';
  static const _resolveFallback = 2;

  // ============================================================
  // Interface Index Resolution
  // ============================================================

  /// Resolves the interface index by matching [_resolveParam] = [_resolveValue].
  /// Returns [_resolveFallback] if resolution fails.
  static Future<int> _resolveIndex(UspClient client) async {
    try {
      final response = await client.get(['$_instanceBase.*.$_resolveParam']);
      for (final entry in response.entries) {
        if (entry.value == _resolveValue) {
          final match = RegExp(r'\.(\d+)\.' + _resolveParam + r'$')
              .firstMatch(entry.key);
          if (match != null) {
            return int.parse(match.group(1)!);
          }
        }
      }
    } catch (_) {
      // Resolution failed, use fallback
    }
    return _resolveFallback;
  }

  /// Builds parameter paths using the resolved index.
  static List<String> _buildPaths(int index) {
    return [
      '$_instanceBase.$index.Status',
      '$_instanceBase.$index.IPv4Address.1.IPAddress',
      '$_instanceBase.$index.IPv4Address.1.SubnetMask',
      '$_instanceBase.$index.IPv4Address.1.AddressingType',
      '$_instanceBase.$index.MaxMTUSize',
      '$_instanceBase.$index.IPv6Enable',
    ];
  }

  // ============================================================
  // Fetch
  // ============================================================

  /// Fetch all parameters via USP Get message.
  /// Automatically resolves interface index using Alias.
  static Future<WanStatus> fetch(UspClient client) async {
    final index = await _resolveIndex(client);
    final paths = _buildPaths(index);
    final response = await client.get(paths);
    return WanStatus._fromResponse(response, index);
  }

  factory WanStatus._fromResponse(Map<String, dynamic> response, int index) {
    final base = '$_instanceBase.$index';
    final missing = <String>[];
    
    if (!response.containsKey('$base.Status'))
      missing.add('$base.Status');
    if (!response.containsKey('$base.IPv4Address.1.IPAddress'))
      missing.add('$base.IPv4Address.1.IPAddress');
    if (!response.containsKey('$base.IPv4Address.1.SubnetMask'))
      missing.add('$base.IPv4Address.1.SubnetMask');
    if (!response.containsKey('$base.IPv4Address.1.AddressingType'))
      missing.add('$base.IPv4Address.1.AddressingType');
    if (!response.containsKey('$base.MaxMTUSize'))
      missing.add('$base.MaxMTUSize');
    if (!response.containsKey('$base.IPv6Enable'))
      missing.add('$base.IPv6Enable');
    
    if (missing.isNotEmpty) {
      throw 'Get failed: Required fields missing: ${missing.join(", ")}';
    }
    
    return WanStatus(
      status: (response['$base.Status'] ?? '') as String,
      ipAddress: (response['$base.IPv4Address.1.IPAddress'] ?? '') as String,
      subnetMask: (response['$base.IPv4Address.1.SubnetMask'] ?? '') as String,
      addressingType: (response['$base.IPv4Address.1.AddressingType'] ?? '') as String,
      maxMtuSize: int.tryParse(response['$base.MaxMTUSize']?.toString() ?? '') ?? 0,
      ipv6Enabled: response['$base.IPv6Enable'] == true ||
          response['$base.IPv6Enable'] == 'true' ||
          response['$base.IPv6Enable'] == '1',
    );
  }

  // ============================================================
  // Subscribe
  // ============================================================

  /// Subscribe to value changes. Resolves interface index before subscribing.
  static Future<Subscription<WanStatus>> subscribe(UspClient client) async {
    final index = await _resolveIndex(client);
    return client.subscribe<WanStatus>(
      id: 'wan-status-valuechange',
      notifType: NotifType.valueChange,
      paths: ['$_instanceBase.$index.'],
      parser: (response) => WanStatus._fromResponse(response, index),
    );
  }

  // ============================================================
  // Save (if applicable)
  // ============================================================

  /// Save modified parameters. Resolves interface index before saving.
  Future<void> save(UspClient client) async {
    final index = await _resolveIndex(client);
    final base = '$_instanceBase.$index';
    final params = <String, String>{};
    
    // Only include changed fields (implementation depends on dirty tracking)
    params['$base.IPv6Enable'] = ipv6Enabled.toString();
    
    if (params.isNotEmpty) {
      await client.set(params);
    }
  }

  @override
  String toString() {
    return 'WanStatus('
        'status: $status, '
        'ipAddress: $ipAddress, '
        'subnetMask: $subnetMask, '
        'addressingType: $addressingType, '
        'maxMtuSize: $maxMtuSize, '
        'ipv6Enabled: $ipv6Enabled'
        ')';
  }
}
```

### 3.2 多 Interface（multi_interface_traffic_stats.g.dart 片段）

```dart
class MultiInterfaceTrafficStats {
  // ...fields...

  // Resolve configs for each interface
  static const _interfaces = {
    'wan': _InterfaceConfig(
      instanceBase: 'Device.IP.Interface',
      resolveParam: 'Alias',
      resolveValue: 'cpe-wan',
      fallback: 2,
    ),
    'lan': _InterfaceConfig(
      instanceBase: 'Device.IP.Interface',
      resolveParam: 'Alias',
      resolveValue: 'cpe-lan',
      fallback: 1,
    ),
  };

  /// Resolves all interface indices in parallel.
  static Future<Map<String, int>> _resolveAllIndices(UspClient client) async {
    final response = await client.get(['Device.IP.Interface.*.Alias']);
    final result = <String, int>{};
    
    for (final config in _interfaces.entries) {
      result[config.key] = _findIndex(response, config.value) 
          ?? config.value.fallback;
    }
    return result;
  }

  static int? _findIndex(Map<String, dynamic> response, _InterfaceConfig config) {
    for (final entry in response.entries) {
      if (entry.value == config.resolveValue) {
        final match = RegExp(r'\.(\d+)\.' + config.resolveParam + r'$')
            .firstMatch(entry.key);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      }
    }
    return null;
  }

  static Future<MultiInterfaceTrafficStats> fetch(UspClient client) async {
    final indices = await _resolveAllIndices(client);
    final paths = _buildPaths(indices);
    final response = await client.get(paths);
    return MultiInterfaceTrafficStats._fromResponse(response, indices);
  }
}

class _InterfaceConfig {
  final String instanceBase;
  final String resolveParam;
  final String resolveValue;
  final int fallback;
  
  const _InterfaceConfig({
    required this.instanceBase,
    required this.resolveParam,
    required this.resolveValue,
    required this.fallback,
  });
}
```

---

## 4. Codegen Implementation Details

### 4.1 Parser Changes

新增 YAML 解析邏輯：

```
1. 檢查是否有 `resolveBy` 欄位
2. 如果有：
   - 驗證必填欄位：param, value, fallback
   - 標記此 definition 為 "dynamic instance"
   - instance path 不應包含 index（如 Device.IP.Interface 而非 Device.IP.Interface.2）
3. 如果沒有：
   - 維持現有行為（hardcoded path）
```

### 4.2 Code Generator Changes

```
1. 如果是 dynamic instance：
   - 產生 _resolveIndex() 方法
   - 產生 _buildPaths(index) 方法
   - fetch() 先呼叫 _resolveIndex() 再 _buildPaths()
   - subscribe() 先 resolve 再訂閱
   - save() 先 resolve 再存
   - _fromResponse() 接受 index 參數

2. 如果是 static instance（現有行為）：
   - 維持現有 hardcoded paths
```

### 4.3 Validation Rules

| Rule | Description |
|------|-------------|
| V1 | `resolveBy` 存在時，`instance` 不應包含數字 index |
| V2 | `resolveBy.param` 必須是有效的 TR-181 參數名稱 |
| V3 | `resolveBy.fallback` 必須是正整數 |
| V4 | 多 interface 模式時，每個 interface 都必須有唯一的 `id` |

---

## 5. Migration Path

### 5.1 需修改的 YAML 檔案

| 檔案 | 變更 |
|------|------|
| `wan_status.yaml` | `instance: Device.IP.Interface.2` → `resolveBy: cpe-wan` |
| `wan_settings.yaml` | `instance: Device.IP.Interface.2` → `resolveBy: cpe-wan` |
| `lan_network_info.yaml` | `instance: Device.IP.Interface.1` → `resolveBy: cpe-lan` |
| `ipv6settings.yaml` | `instance: Device.IP.Interface.2` → `resolveBy: cpe-wan` |
| `multi_interface_traffic_stats.yaml` | 改用 `interfaces` array 格式 |

### 5.2 向後相容

- 沒有 `resolveBy` 的 YAML 維持現有行為
- 產生的 API（fetch, subscribe, save）簽名不變
- 上層 code 無需修改

---

## 6. Testing

### 6.1 Unit Tests

```dart
// Test: Resolve index from response
test('resolveIndex finds correct index', () async {
  final mockResponse = {
    'Device.IP.Interface.1.Alias': 'cpe-lan',
    'Device.IP.Interface.2.Alias': 'cpe-wan',
    'Device.IP.Interface.3.Alias': 'cpe-loopback',
  };
  
  final index = WanStatus._findIndexFromResponse(mockResponse);
  expect(index, equals(2));
});

// Test: Fallback when Alias not found
test('resolveIndex uses fallback when not found', () async {
  final mockResponse = {
    'Device.IP.Interface.1.Alias': 'something-else',
  };
  
  final index = WanStatus._findIndexFromResponse(mockResponse) 
      ?? WanStatus._resolveFallback;
  expect(index, equals(2)); // fallback
});

// Test: Fallback on error
test('resolveIndex uses fallback on GET error', () async {
  final mockClient = MockUspClient();
  when(() => mockClient.get(any())).thenThrow(Exception('Network error'));
  
  final index = await WanStatus._resolveIndex(mockClient);
  expect(index, equals(2)); // fallback
});
```

### 6.2 Integration Tests

- 在 M60TB 上驗證 WAN index resolve 正確
- 模擬 index 反轉的情境（如果可行）
- 驗證 subscribe 使用正確的 path

---

## 7. Timeline

| Task | Estimate |
|------|----------|
| YAML parser 修改 | 0.5d |
| Code generator 修改 | 1.5d |
| 單元測試 | 0.5d |
| YAML 定義檔更新 | 0.5d |
| 整合測試 | 0.5d |
| **Total** | **3.5d** |

---

## 8. Appendix: Regex Pattern

用於從路徑中提取 index：

```
Pattern: \.(\d+)\.<param>$
Example: Device.IP.Interface.2.Alias
Match group 1: 2
```

```dart
final pattern = RegExp(r'\.(\d+)\.' + resolveParam + r'$');
final match = pattern.firstMatch('Device.IP.Interface.2.Alias');
final index = int.parse(match!.group(1)!); // 2
```
