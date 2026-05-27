import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Stub factory that renders representative fake-data cards for golden tests.
class _StubWidgetFactory extends UspWidgetFactory {
  @override
  Widget? buildWidget(String id) {
    return AppCard(child: _buildContent(id));
  }

  Widget _buildContent(String id) {
    switch (id) {
      case 'device_info':
        return _keyValueCard('Device Info', {
          'Model': 'M60-EU',
          'Firmware': '1.0.16',
        });
      case 'network_status':
        return _keyValueCard('Network', {
          'WAN IP': '192.168.1.1',
          'Type': 'DHCP',
          'MTU': '1500',
        });
      case 'wifi_status':
        return _keyValueCard('Wi-Fi Status', {
          '2.4 GHz': 'MyNetwork',
          '5 GHz': 'MyNetwork',
          'Clients': '8',
        });
      case 'connected_devices':
        return _keyValueCard('Connected Devices', {
          'Online': '5',
          'Offline': '3',
          'Guest': '1',
        });
      case 'system_status':
        return _keyValueCard('System Status', {
          'CPU': '23%',
          'Memory': '61%',
          'Uptime': '3d 14h',
        });
      default:
        return Center(
          child: Text(id, style: const TextStyle(fontSize: 12)),
        );
    }
  }

  Widget _keyValueCard(String title, Map<String, String> entries) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelLarge(title),
          const SizedBox(height: 8),
          ...entries.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.bodySmall(e.key),
                    AppText.bodySmall(e.value),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FixedOrchestratorNotifier extends DashboardOrchestrator {
  @override
  Future<DashboardOrchestratorState> build() async =>
      const DashboardOrchestratorState(isAuthenticated: true);

  @override
  Future<void> refreshAll() async {}
}

class _FixedSystemMonitorNotifier extends UspSystemMonitorNotifier {
  @override
  SystemMonitorState build() => const SystemMonitorState();
}

class _FixedTrafficAnalysisNotifier extends UspTrafficAnalysisNotifier {
  @override
  TrafficAnalysisState build() => const TrafficAnalysisState();
}

class _FixedDeviceAnalyticsNotifier extends UspDeviceAnalyticsNotifier {
  @override
  DeviceAnalyticsState build() => const DeviceAnalyticsState();
}

class _FixedPackageWidgetLoader extends PackageWidgetLoader {
  @override
  Future<Map<String, PackageWidgetTemplate>> build() async => {};
}

class _FixedLayoutPrefsNotifier extends UspLayoutPreferencesNotifier {
  // Let parent's build() run — it calls _loadFromPrefs which uses
  // SharedPreferences (mocked via initDashboardSharedPreferences)
  // and completes _initCompleter so that _enterEditMode can proceed.
}

/// Simple layout for golden tests — 5 cards in a 12-column grid.
List<LayoutItem> _defaultTestLayout() => [
      const LayoutItem(id: 'device_info', x: 0, y: 0, w: 4, h: 3),
      const LayoutItem(id: 'network_status', x: 4, y: 0, w: 4, h: 3),
      const LayoutItem(id: 'wifi_status', x: 8, y: 0, w: 4, h: 3),
      const LayoutItem(id: 'connected_devices', x: 0, y: 3, w: 6, h: 2),
      const LayoutItem(id: 'system_status', x: 6, y: 3, w: 6, h: 2),
    ];

class _FixedControllerNotifier extends UspSliverDashboardControllerNotifier {
  // Inherits super() which calls _initializeLayout() — that loads the layout
  // from SharedPreferences (seeded in initDashboardSharedPreferences) and
  // calls _preSeedBreakpoints() to populate 4/8-column caches.
}

/// Initialize SharedPreferences with dashboard defaults to prevent async calls.
void initDashboardSharedPreferences() {
  SharedPreferences.setMockInitialValues({
    'usp_preset_dialog_seen': true,
    'usp_sliver_dashboard_layout': _testLayoutJson,
  });
}

/// JSON representation of [_defaultTestLayout] for SharedPreferences seeding.
final String _testLayoutJson =
    '[${_defaultTestLayout().map((item) => '{"id":"${item.id}","x":${item.x},"y":${item.y},"w":${item.w},"h":${item.h}}').join(',')}]';

/// Returns provider overrides for dashboard golden tests.
List<Override> dashboardOverrides() {
  return [
    dashboardOrchestratorProvider
        .overrideWith(() => _FixedOrchestratorNotifier()),
    uspSliverDashboardControllerProvider.overrideWith(
      (ref) => _FixedControllerNotifier(),
    ),
    uspWidgetFactoryProvider.overrideWithValue(_StubWidgetFactory()),
    uspSystemMonitorProvider.overrideWith(() => _FixedSystemMonitorNotifier()),
    uspTrafficAnalysisProvider
        .overrideWith(() => _FixedTrafficAnalysisNotifier()),
    uspDeviceAnalyticsProvider
        .overrideWith(() => _FixedDeviceAnalyticsNotifier()),
    packageWidgetLoaderProvider.overrideWith(() => _FixedPackageWidgetLoader()),
    uspLayoutPreferencesProvider
        .overrideWith(() => _FixedLayoutPrefsNotifier()),
  ];
}
