import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

import 'data_path_resolver.dart';

/// JNAP implementation of [DataPathResolver].
///
/// Maps abstract data paths to Riverpod providers for JNAP-based data.
class JnapDataResolver implements DataPathResolver {
  final Ref _ref;

  JnapDataResolver(this._ref);

  @override
  dynamic resolve(String path) {
    try {
      // Static resolution using _ref.read for one-time values
      return switch (path) {
        'router.deviceCount' => _ref
            .read(deviceManagerProvider)
            .deviceList
            .where((d) => d.nodeType == null && d.isOnline())
            .length
            .toString(),
        'router.nodeCount' => _ref
            .read(deviceManagerProvider)
            .deviceList
            .where((d) => d.nodeType != null)
            .length
            .toString(),
        'router.wanStatus' =>
          _resolveWanStatus(_ref.read(dashboardHomeProvider)),
        'router.uptime' =>
          _formatUptime(_ref.read(dashboardHomeProvider).uptime ?? 0),
        'router.uploadSpeed' => '2.5 MB/s', // Static placeholder
        'router.downloadSpeed' => '8.3 MB/s', // Static placeholder
        'system.cpuUsage' => '25% CPU', // Static placeholder
        'system.memoryUsage' => '68% 記憶體', // Static placeholder
        'system.temperature' => '42°C', // Static placeholder
        'system.uptime' =>
          _formatUptime(_ref.read(dashboardHomeProvider).uptime ?? 0),
        'wifi.ssid' => _ref.read(dashboardHomeProvider).mainSSID,
        _ => _getDefaultValue(path),
      };
    } catch (e) {
      debugPrint('Failed to resolve data path "$path": $e');
      return _getDefaultValue(path);
    }
  }

  // Helper methods for resolve()
  String _resolveWanStatus(DashboardHomeState state) {
    final status = state.wanPortConnection;
    return status != null && status.toLowerCase().contains('connected')
        ? 'Online'
        : 'Offline';
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${days}d ${hours}h ${minutes}m';
  }

  /// Gets default value for data path when resolution fails.
  dynamic _getDefaultValue(String path) {
    return switch (path) {
      'router.deviceCount' => '0',
      'router.nodeCount' => '0',
      'router.wanStatus' => 'Unknown',
      'router.uptime' => '--:--:--',
      'router.uploadSpeed' => '0 MB/s',
      'router.downloadSpeed' => '0 MB/s',
      'system.cpuUsage' => '0% CPU',
      'system.memoryUsage' => '0% 記憶體',
      'system.temperature' => '--°C',
      'system.uptime' => '--:--:--',
      'wifi.ssid' => 'Unknown Network',
      String() when path.startsWith('router.') => 'Router data unavailable',
      String() when path.startsWith('wifi.') => 'WiFi data unavailable',
      String() when path.startsWith('device.') => 'Device data unavailable',
      _ => 'Loading data...',
    };
  }

  @override
  ProviderListenable<dynamic>? watch(String path) {
    try {
      return switch (path) {
        'router.deviceCount' => _watchDeviceCount(),
        'router.nodeCount' => _watchNodeCount(),
        'router.wanStatus' => _watchWanStatus(),
        'router.uptime' => _watchUptime(),
        'wifi.ssid' => _watchSsid(),
        _ => null, // Will use resolve() with default values
      };
    } catch (e) {
      debugPrint('Failed to watch data path "$path": $e');
      return null; // Will fall back to resolve() method
    }
  }

  // --- Watch Implementations ---

  ProviderListenable<String> _watchDeviceCount() {
    try {
      return deviceManagerProvider.select((state) {
        try {
          return state.deviceList
              .where((d) => d.nodeType == null && d.isOnline())
              .length
              .toString();
        } catch (e) {
          debugPrint('Error counting devices: $e');
          return '0'; // Default value
        }
      });
    } catch (e) {
      debugPrint('Error setting up device count watcher: $e');
      rethrow; // Let watch() handle the error
    }
  }

  ProviderListenable<String> _watchNodeCount() {
    try {
      return deviceManagerProvider.select((state) {
        try {
          return state.deviceList
              .where((d) => d.nodeType != null)
              .length
              .toString();
        } catch (e) {
          debugPrint('Error counting nodes: $e');
          return '0'; // Default value
        }
      });
    } catch (e) {
      debugPrint('Error setting up node count watcher: $e');
      rethrow; // Let watch() handle the error
    }
  }

  ProviderListenable<String> _watchWanStatus() {
    try {
      return dashboardHomeProvider.select((state) {
        try {
          final status = state.wanPortConnection;
          return status != null && status.toLowerCase().contains('connected')
              ? 'Online'
              : 'Offline';
        } catch (e) {
          debugPrint('Error getting WAN status: $e');
          return 'Unknown'; // Default value
        }
      });
    } catch (e) {
      debugPrint('Error setting up WAN status watcher: $e');
      rethrow; // Let watch() handle the error
    }
  }

  ProviderListenable<String> _watchUptime() {
    try {
      return dashboardHomeProvider.select((state) {
        try {
          final seconds = state.uptime ?? 0;
          final days = seconds ~/ 86400;
          final hours = (seconds % 86400) ~/ 3600;
          final minutes = (seconds % 3600) ~/ 60;
          return '${days}d ${hours}h ${minutes}m';
        } catch (e) {
          debugPrint('Error formatting uptime: $e');
          return '--:--:--'; // Default value
        }
      });
    } catch (e) {
      debugPrint('Error setting up uptime watcher: $e');
      rethrow; // Let watch() handle the error
    }
  }

  ProviderListenable<String> _watchSsid() {
    try {
      return dashboardHomeProvider.select((state) {
        try {
          return state.mainSSID;
        } catch (e) {
          debugPrint('Error getting SSID: $e');
          return 'Unknown Network'; // Default value
        }
      });
    } catch (e) {
      debugPrint('Error setting up SSID watcher: $e');
      rethrow; // Let watch() handle the error
    }
  }
}

/// Provider for JnapDataResolver.
final jnapDataResolverProvider = Provider<DataPathResolver>((ref) {
  return JnapDataResolver(ref);
});
