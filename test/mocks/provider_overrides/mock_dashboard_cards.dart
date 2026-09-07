import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

class FixedDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _fixedData;
  FixedDevicesDataNotifier(this._fixedData);

  @override
  Future<DevicesData> build() async => _fixedData;
}

class FixedSystemInfoDataNotifier extends SystemInfoDataNotifier {
  final SystemInfoData _fixedData;
  FixedSystemInfoDataNotifier(this._fixedData);

  @override
  Future<SystemInfoData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedTimeDataNotifier extends TimeDataNotifier {
  final TimeData _fixedData;
  FixedTimeDataNotifier(this._fixedData);

  @override
  Future<TimeData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedWanDataNotifier extends WanDataNotifier {
  final WanData _fixedData;
  FixedWanDataNotifier(this._fixedData);

  @override
  Future<WanData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedLanDataNotifier extends LanDataNotifier {
  final LanData _fixedData;
  FixedLanDataNotifier(this._fixedData);

  @override
  Future<LanData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedEthernetDataNotifier extends EthernetDataNotifier {
  final EthernetData _fixedData;
  FixedEthernetDataNotifier(this._fixedData);

  @override
  Future<EthernetData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedDhcpDataNotifier extends DhcpDataNotifier {
  final DhcpData _fixedData;
  FixedDhcpDataNotifier(this._fixedData);

  @override
  Future<DhcpData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedWifiDataNotifier extends WifiDataNotifier {
  final WifiData _fixedData;
  FixedWifiDataNotifier(this._fixedData);

  @override
  Future<WifiData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedPortForwardingDataNotifier extends PortForwardingDataNotifier {
  final PortForwardingData _fixedData;
  FixedPortForwardingDataNotifier(this._fixedData);

  @override
  Future<PortForwardingData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedPortTriggeringDataNotifier extends PortTriggeringDataNotifier {
  final PortTriggeringData _fixedData;
  FixedPortTriggeringDataNotifier(this._fixedData);

  @override
  Future<PortTriggeringData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedFirewallDataNotifier extends FirewallDataNotifier {
  final FirewallData _fixedData;
  FixedFirewallDataNotifier(this._fixedData);

  @override
  Future<FirewallData> build() async {
    state = AsyncData(_fixedData);
    return _fixedData;
  }
}

class FixedSystemMonitorNotifier extends UspSystemMonitorNotifier {
  final SystemMonitorState _fixedState;
  FixedSystemMonitorNotifier(this._fixedState);

  @override
  SystemMonitorState build() => _fixedState;
}

class FixedTrafficAnalysisNotifier extends UspTrafficAnalysisNotifier {
  final TrafficAnalysisState _fixedState;
  FixedTrafficAnalysisNotifier(this._fixedState);

  @override
  TrafficAnalysisState build() => _fixedState;
}

class FixedDeviceAnalyticsNotifier extends UspDeviceAnalyticsNotifier {
  final DeviceAnalyticsState _fixedState;
  FixedDeviceAnalyticsNotifier(this._fixedState);

  @override
  DeviceAnalyticsState build() => _fixedState;
}

List<Override> cardOverrides({
  DevicesData? devicesData,
  SystemInfoData? systemInfoData,
  TimeData? timeData,
  WanData? wanData,
  LanData? lanData,
  EthernetData? ethernetData,
  DhcpData? dhcpData,
  WifiData? wifiData,
  PortForwardingData? portForwardingData,
  PortTriggeringData? portTriggeringData,
  FirewallData? firewallData,
  SystemMonitorState? systemMonitorState,
  TrafficAnalysisState? trafficAnalysisState,
  DeviceAnalyticsState? deviceAnalyticsState,
}) =>
    [
      if (devicesData != null)
        devicesDataProvider
            .overrideWith(() => FixedDevicesDataNotifier(devicesData)),
      if (systemInfoData != null)
        systemInfoDataProvider
            .overrideWith(() => FixedSystemInfoDataNotifier(systemInfoData)),
      if (timeData != null)
        timeDataProvider.overrideWith(() => FixedTimeDataNotifier(timeData)),
      if (wanData != null)
        wanDataProvider.overrideWith(() => FixedWanDataNotifier(wanData)),
      if (lanData != null)
        lanDataProvider.overrideWith(() => FixedLanDataNotifier(lanData)),
      if (ethernetData != null)
        ethernetDataProvider
            .overrideWith(() => FixedEthernetDataNotifier(ethernetData)),
      if (dhcpData != null)
        dhcpDataProvider.overrideWith(() => FixedDhcpDataNotifier(dhcpData)),
      if (wifiData != null)
        wifiDataProvider.overrideWith(() => FixedWifiDataNotifier(wifiData)),
      if (portForwardingData != null)
        portForwardingDataProvider.overrideWith(
            () => FixedPortForwardingDataNotifier(portForwardingData)),
      if (portTriggeringData != null)
        portTriggeringDataProvider.overrideWith(
            () => FixedPortTriggeringDataNotifier(portTriggeringData)),
      if (firewallData != null)
        firewallDataProvider
            .overrideWith(() => FixedFirewallDataNotifier(firewallData)),
      if (systemMonitorState != null)
        uspSystemMonitorProvider
            .overrideWith(() => FixedSystemMonitorNotifier(systemMonitorState)),
      if (trafficAnalysisState != null)
        uspTrafficAnalysisProvider.overrideWith(
            () => FixedTrafficAnalysisNotifier(trafficAnalysisState)),
      if (deviceAnalyticsState != null)
        uspDeviceAnalyticsProvider.overrideWith(
            () => FixedDeviceAnalyticsNotifier(deviceAnalyticsState)),
    ];
