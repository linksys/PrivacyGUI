import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

class FixedTrafficAnalysisNotifier extends UspTrafficAnalysisNotifier {
  final TrafficAnalysisState _fixedState;

  FixedTrafficAnalysisNotifier(this._fixedState);

  @override
  TrafficAnalysisState build() => _fixedState;

  @override
  void setRefreshInterval(Duration? interval) {}
}

class FixedDeviceAnalyticsNotifier extends UspDeviceAnalyticsNotifier {
  final DeviceAnalyticsState _fixedState;

  FixedDeviceAnalyticsNotifier(this._fixedState);

  @override
  DeviceAnalyticsState build() => _fixedState;
}

class FixedSystemMonitorNotifier extends UspSystemMonitorNotifier {
  final SystemMonitorState _fixedState;

  FixedSystemMonitorNotifier(this._fixedState);

  @override
  SystemMonitorState build() => _fixedState;

  @override
  void setRefreshInterval(Duration? interval) {}

  @override
  void pushSnapshot(SystemSnapshot snapshot) {}
}

class FixedFirewallDataNotifier extends FirewallDataNotifier {
  final FirewallData _fixedData;

  FixedFirewallDataNotifier(this._fixedData);

  @override
  Future<FirewallData> build() async => _fixedData;
}

class FixedPortForwardingDataNotifier extends PortForwardingDataNotifier {
  final PortForwardingData _fixedData;

  FixedPortForwardingDataNotifier(this._fixedData);

  @override
  Future<PortForwardingData> build() async => _fixedData;
}

class FixedSystemInfoDataNotifier extends SystemInfoDataNotifier {
  final SystemInfoData _fixedData;

  FixedSystemInfoDataNotifier(this._fixedData);

  @override
  Future<SystemInfoData> build() async => _fixedData;
}

class FixedWifiDataNotifier extends WifiDataNotifier {
  final WifiData _fixedData;

  FixedWifiDataNotifier(this._fixedData);

  @override
  Future<WifiData> build() async => _fixedData;
}

class FixedDevicesDataNotifierForStats extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async => const DevicesData();
}

List<Override> statisticsOverrides({
  TrafficAnalysisState trafficState = const TrafficAnalysisState(),
  DeviceAnalyticsState deviceAnalyticsState = const DeviceAnalyticsState(),
  SystemMonitorState systemMonitorState = const SystemMonitorState(),
  FirewallData firewallData = const FirewallData.empty(),
  PortForwardingData portForwardingData =
      const PortForwardingData(ruleModels: []),
  SystemInfoData? systemInfoData,
  WifiData wifiData = const WifiData.empty(),
}) =>
    [
      uspTrafficAnalysisProvider.overrideWith(
        () => FixedTrafficAnalysisNotifier(trafficState),
      ),
      uspDeviceAnalyticsProvider.overrideWith(
        () => FixedDeviceAnalyticsNotifier(deviceAnalyticsState),
      ),
      uspSystemMonitorProvider.overrideWith(
        () => FixedSystemMonitorNotifier(systemMonitorState),
      ),
      firewallDataProvider.overrideWith(
        () => FixedFirewallDataNotifier(firewallData),
      ),
      portForwardingDataProvider.overrideWith(
        () => FixedPortForwardingDataNotifier(portForwardingData),
      ),
      if (systemInfoData != null)
        systemInfoDataProvider.overrideWith(
          () => FixedSystemInfoDataNotifier(systemInfoData),
        ),
      wifiDataProvider.overrideWith(
        () => FixedWifiDataNotifier(wifiData),
      ),
      devicesDataProvider
          .overrideWith(() => FixedDevicesDataNotifierForStats()),
    ];
