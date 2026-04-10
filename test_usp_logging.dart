// 快速測試 USP 日誌記錄功能
// 這個文件僅用於驗證日誌輸出，不會提交到 git

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';

void main() async {
  // 設置為 debug 模式以啟用詳細日誌
  assert(() {
    print('Debug mode enabled - detailed logs should appear');
    return true;
  }());

  // 創建模擬的結構化回應
  final mockSetResult = {
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
            'updatedParams': {'SSID': 'MyNetwork', 'Enable': 'true'}
          }
        ]
      }
    ]
  };

  final mockAddResult = {
    'overallSuccess': true,
    'hasAnySuccess': true,
    'hasErrors': false,
    'results': [
      {
        'requestedPath': 'Device.DHCPv4.Server.Pool.1.StaticAddress.',
        'success': true,
        'createdInstances': [
          {
            'affectedPath': 'Device.DHCPv4.Server.Pool.1.StaticAddress.3.',
            'initialParams': {'Chaddr': 'AA:BB:CC:DD:EE:FF', 'Yiaddr': '192.168.1.100'}
          }
        ]
      }
    ]
  };

  final mockDeleteResult = {
    'overallSuccess': false,
    'hasAnySuccess': true,
    'hasErrors': true,
    'results': [
      {
        'requestedPath': 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
        'success': true,
        'deletedInstances': [
          {'affectedPath': 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.'}
        ]
      },
      {
        'requestedPath': 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
        'success': false,
        'errorCode': 7026,
        'errorMessage': 'Invalid path'
      }
    ]
  };

  print('\n=== Testing USP Logging (should show detailed logs in debug mode) ===\n');

  // 測試 kDebugMode
  print('kDebugMode: $kDebugMode');

  if (kDebugMode) {
    print('\n--- Mock SET Result ---');
    _logSetResult(mockSetResult, 1);

    print('\n--- Mock ADD Result ---');
    _logAddResult(mockAddResult, 2);

    print('\n--- Mock DELETE Result ---');
    _logDeleteResult(mockDeleteResult, 3);
  } else {
    print('Not in debug mode - detailed logs disabled');
  }
}

// 複製 USP Service 中的日誌邏輯來測試
void _logSetResult(Map<String, dynamic> result, int id) {
  final overallSuccess = result['overallSuccess'] as bool? ?? false;
  final hasErrors = result['hasErrors'] as bool? ?? false;
  final results = result['results'] as List? ?? [];

  print('[USP][Service]#$id SET result: success=$overallSuccess, errors=$hasErrors, details=${results.length}');

  if (results.isNotEmpty) {
    for (var i = 0; i < results.length; i++) {
      final detail = results[i] as Map<String, dynamic>? ?? {};
      final requestedPath = detail['requestedPath'] ?? 'unknown';
      final success = detail['success'] ?? false;

      if (success) {
        final updatedInstances = detail['updatedInstances'] as List? ?? [];
        print('[USP][Service]#$id SET[$i] ✅ $requestedPath → ${updatedInstances.length} instances updated');

        for (var instance in updatedInstances) {
          final instanceMap = instance as Map<String, dynamic>? ?? {};
          final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
          final updatedParams = instanceMap['updatedParams'] as Map? ?? {};
          print('[USP][Service]#$id SET[$i]   📝 $affectedPath: ${updatedParams.keys.join(', ')}');
        }
      } else {
        final errorCode = detail['errorCode'] ?? 'unknown';
        final errorMessage = detail['errorMessage'] ?? 'unknown error';
        print('[USP][Service]#$id SET[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
      }
    }
  }
}

void _logAddResult(Map<String, dynamic> result, int id) {
  final overallSuccess = result['overallSuccess'] as bool? ?? false;
  final hasErrors = result['hasErrors'] as bool? ?? false;
  final results = result['results'] as List? ?? [];

  print('[USP][Service]#$id ADD result: success=$overallSuccess, errors=$hasErrors, details=${results.length}');

  for (var i = 0; i < results.length; i++) {
    final detail = results[i] as Map<String, dynamic>? ?? {};
    final requestedPath = detail['requestedPath'] ?? 'unknown';
    final success = detail['success'] ?? false;

    if (success) {
      final createdInstances = detail['createdInstances'] as List? ?? [];
      print('[USP][Service]#$id ADD[$i] ✅ $requestedPath → ${createdInstances.length} instances created');

      for (var instance in createdInstances) {
        final instanceMap = instance as Map<String, dynamic>? ?? {};
        final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
        final initialParams = instanceMap['initialParams'] as Map? ?? {};
        print('[USP][Service]#$id ADD[$i]   🆕 $affectedPath with ${initialParams.length} params: ${initialParams.keys.join(', ')}');
      }
    } else {
      final errorCode = detail['errorCode'] ?? 'unknown';
      final errorMessage = detail['errorMessage'] ?? 'unknown error';
      print('[USP][Service]#$id ADD[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
    }
  }
}

void _logDeleteResult(Map<String, dynamic> result, int id) {
  final overallSuccess = result['overallSuccess'] as bool? ?? false;
  final hasErrors = result['hasErrors'] as bool? ?? false;
  final results = result['results'] as List? ?? [];

  print('[USP][Service]#$id DELETE result: success=$overallSuccess, errors=$hasErrors, details=${results.length}');

  for (var i = 0; i < results.length; i++) {
    final detail = results[i] as Map<String, dynamic>? ?? {};
    final requestedPath = detail['requestedPath'] ?? 'unknown';
    final success = detail['success'] ?? false;

    if (success) {
      final deletedInstances = detail['deletedInstances'] as List? ?? [];
      print('[USP][Service]#$id DELETE[$i] ✅ $requestedPath → ${deletedInstances.length} instances deleted');

      for (var instance in deletedInstances) {
        final instanceMap = instance as Map<String, dynamic>? ?? {};
        final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
        print('[USP][Service]#$id DELETE[$i]   🗑️ $affectedPath');
      }
    } else {
      final errorCode = detail['errorCode'] ?? 'unknown';
      final errorMessage = detail['errorMessage'] ?? 'unknown error';
      print('[USP][Service]#$id DELETE[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
    }
  }
}