/// Composed scenes for `usp_statistics_view` — the golden suite's two states, its two
/// tab interactions, and the gate's one.
///
/// Moved here from
/// `test/golden_test/page/statistics/fixtures/statistics_test_data.dart` by #1380
/// (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate may not
/// import from `test/golden_test/` (#1361), and one fixture read by both suites beats
/// two that can disagree. The mock that consumes these had already moved — see
/// `test/mocks/provider_overrides/mock_statistics.dart`, which three non-golden suites
/// were already importing before this wave.
library;

import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

final _now = DateTime(2026, 5, 22, 14, 0, 0);

List<MultiInterfaceSnapshot> get testTrafficHistory => List.generate(
      10,
      (i) => MultiInterfaceSnapshot(
        timestamp: _now.subtract(Duration(seconds: (9 - i) * 5)),
        interfaces: {
          TrafficInterface.wan: InterfaceTrafficSnapshot(
            uploadBytesPerSec: 500000.0 + i * 50000,
            downloadBytesPerSec: 2000000.0 + i * 100000,
            uploadPacketsPerSec: 300.0 + i * 10,
            downloadPacketsPerSec: 1200.0 + i * 50,
            totalBytesSent: 50000000 + i * 500000,
            totalBytesReceived: 200000000 + i * 1000000,
            totalPacketsSent: 30000 + i * 300,
            totalPacketsReceived: 120000 + i * 500,
            errorsSentPerSec: 0.5 + i * 0.1,
            errorsReceivedPerSec: 1.0 + i * 0.2,
          ),
          TrafficInterface.lan: InterfaceTrafficSnapshot(
            uploadBytesPerSec: 1800000.0 + i * 80000,
            downloadBytesPerSec: 600000.0 + i * 40000,
            uploadPacketsPerSec: 1100.0 + i * 40,
            downloadPacketsPerSec: 400.0 + i * 20,
            totalBytesSent: 180000000 + i * 800000,
            totalBytesReceived: 60000000 + i * 400000,
            totalPacketsSent: 110000 + i * 400,
            totalPacketsReceived: 40000 + i * 200,
          ),
        },
      ),
    );

TrafficAnalysisState get testTrafficState => TrafficAnalysisState(
      history: testTrafficHistory,
      refreshInterval: const Duration(seconds: 5),
    );

DeviceAnalyticsState get testDeviceAnalyticsState => DeviceAnalyticsState(
      current: const DeviceDistribution(
        wifiCount: 5,
        wiredCount: 2,
        onlineCount: 6,
        offlineCount: 1,
        bandDistribution: {'2.4GHz': 2, '5GHz': 3, 'Wired': 2},
        signalLevelDistribution: {3: 2, 2: 2, 1: 1, 0: 0},
        bandSignalQuality: {'2.4GHz': 0.6, '5GHz': 0.85},
      ),
      hourlyHistory: List.generate(
        6,
        (i) => HourlyAggregate(
          hour: _now.subtract(Duration(hours: 5 - i)),
          wifiCount: 4 + (i % 3),
          wiredCount: 2,
          activeMacs: {'mac1', 'mac2', 'mac3', 'mac4', if (i > 2) 'mac5'},
        ),
      ),
      allKnownMacs: const {'mac1', 'mac2', 'mac3', 'mac4', 'mac5'},
      macDisplayNames: const {
        'mac1': 'iPhone',
        'mac2': 'MacBook',
        'mac3': 'PS5',
        'mac4': 'iPad',
        'mac5': 'TV',
      },
    );

SystemMonitorState get testSystemMonitorState => SystemMonitorState(
      history: List.generate(
        10,
        (i) => SystemSnapshot(
          timestamp: _now.subtract(Duration(seconds: (9 - i) * 30)),
          cpuPercent: 35 + (i * 3) % 40,
          memoryPercent: 60 + (i * 2) % 20,
          totalMemoryKb: 524288,
          freeMemoryKb: 209715 - i * 5000,
          uptimeSeconds: 86400 + i * 30,
        ),
      ),
      refreshInterval: const Duration(seconds: 30),
    );

const testSystemInfoData = SystemInfoData(
  model: SystemInfoUIModel(
    manufacturer: 'Linksys',
    modelName: 'MX6200',
    serialNumber: 'ABC123456',
    hardwareVersion: '1.0',
    softwareVersion: '2.1.0.123456',
    uptime: 345600,
    totalMemory: 524288,
    freeMemory: 209715,
    cpuUsage: 42,
  ),
);

const testFirewallData = FirewallData.empty();

const testPortForwardingData = PortForwardingData(
  ruleModels: [
    PortForwardingRuleUIModel(
      enabled: true,
      description: 'Web Server',
      protocol: 'TCP',
      externalPort: 80,
      internalPort: 80,
      internalClient: '192.168.1.100',
    ),
    PortForwardingRuleUIModel(
      enabled: true,
      description: 'Game',
      protocol: 'Both',
      externalPort: 3000,
      internalPort: 3000,
      internalClient: '192.168.1.102',
    ),
  ],
);

const testWifiData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: [
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.1.',
      band: '2.4GHz',
      enable: true,
      transmitPower: -1,
      maxBitRate: 300,
      channel: 6,
      autoChannelEnable: true,
      channelBandwidth: '20/40MHz',
      supportedStandards: 'b,g,n',
    ),
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.2.',
      band: '5GHz',
      enable: true,
      transmitPower: -1,
      maxBitRate: 1733,
      channel: 36,
      autoChannelEnable: true,
      channelBandwidth: '80MHz',
      supportedStandards: 'a,n,ac,ax',
    ),
  ],
);

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------
//
// There is no `gateStatisticsState` here, because this page's scene is not one state
// but seven providers: `gateStatisticsOverrides()` in
// `test/mocks/provider_overrides/mock_statistics.dart` composes it from the finals
// above, and its doc says why the gate wants every one of them populated where the
// golden suite splits them across three states.
