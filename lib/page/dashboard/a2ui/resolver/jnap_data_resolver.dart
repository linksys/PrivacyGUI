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
    // For static resolution, we can use _ref.read if needed,
    // but the UI should primarily use watch() for reactivity.
    // Returning null here to encourage usage of watch().
    return null;
  }

  @override
  ProviderListenable<dynamic>? watch(String path) {
    return switch (path) {
      'router.deviceCount' => _watchDeviceCount(),
      'router.nodeCount' => _watchNodeCount(),
      'router.wanStatus' => _watchWanStatus(),
      'router.uptime' => _watchUptime(),
      'wifi.ssid' => _watchSsid(),
      _ => null,
    };
  }

  // --- Watch Implementations ---

  ProviderListenable<int> _watchDeviceCount() {
    return deviceManagerProvider.select((state) => state.deviceList
        .where((d) => d.nodeType == null && d.isOnline())
        .length);
  }

  ProviderListenable<int> _watchNodeCount() {
    return deviceManagerProvider.select(
        (state) => state.deviceList.where((d) => d.nodeType != null).length);
  }

  ProviderListenable<String> _watchWanStatus() {
    return dashboardHomeProvider.select((state) {
      final status = state.wanPortConnection;
      return status != null && status.toLowerCase().contains('connected')
          ? 'Online'
          : 'Offline';
    });
  }

  ProviderListenable<String> _watchUptime() {
    return dashboardHomeProvider.select((state) {
      final seconds = state.uptime ?? 0;
      final days = seconds ~/ 86400;
      final hours = (seconds % 86400) ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${days}d ${hours}h ${minutes}m';
    });
  }

  ProviderListenable<String> _watchSsid() {
    return dashboardHomeProvider.select((state) => state.mainSSID);
  }
}

/// Provider for JnapDataResolver.
final jnapDataResolverProvider = Provider<DataPathResolver>((ref) {
  return JnapDataResolver(ref);
});
