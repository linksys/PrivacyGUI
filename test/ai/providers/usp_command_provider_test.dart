import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/ai/providers/usp_command_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

/// Provider for UspCommandProvider in tests.
final _testUspCommandProvider = Provider<UspCommandProvider>((ref) {
  return UspCommandProvider(ref);
});

void main() {
  group('UspCommandProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          systemInfoDataProvider.overrideWith(
            () => _FixedSystemInfoNotifier(_testSystemInfoData),
          ),
          devicesDataProvider.overrideWith(
            () => _FixedDevicesNotifier(_testDevicesData),
          ),
          wifiDataProvider.overrideWith(
            () => _FixedWifiNotifier(_testWifiData),
          ),
          wanDataProvider.overrideWith(
            () => _FixedWanNotifier(_testWanData),
          ),
          // These three are stubbed for two reasons beyond supplying data.
          //
          // Their real notifiers open a `Timer.periodic` that fetches over USP,
          // guarded only by `appConnectionStateProvider` not being
          // `authenticated` — which happens to hold in tests but is nothing this
          // file states or controls. Stubbing keeps a unit test from depending
          // on that, and from starting timers if it ever stops holding.
          //
          // They also carry the tools most likely to reach the model with an
          // un-encodable value: histories and distributions rather than flat
          // scalars. Left unstubbed they return "no data" and the encodability
          // test below passes over them without ever seeing a populated result.
          uspDeviceAnalyticsProvider.overrideWith(
            () => _FixedDeviceAnalyticsNotifier(_testDeviceAnalyticsState),
          ),
          uspSystemMonitorProvider.overrideWith(
            () => _FixedSystemMonitorNotifier(_testSystemMonitorState),
          ),
          uspTrafficAnalysisProvider.overrideWith(
            () => _FixedTrafficAnalysisNotifier(_testTrafficAnalysisState),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('listCommands', () {
      test('returns all available commands', () async {
        final provider = container.read(_testUspCommandProvider);
        final commands = await provider.listCommands();

        expect(commands, isNotEmpty);
        expect(
          commands.map((c) => c.name),
          containsAll([
            'getSystemInfo',
            'getConnectedDevices',
            'getWifiSettings',
            'getWanStatus',
            'getNetworkOverview',
          ]),
        );
      });

      test('all read commands have read access level', () async {
        final provider = container.read(_testUspCommandProvider);
        final commands = await provider.listCommands();

        for (final cmd in commands) {
          if (cmd.name.startsWith('get')) {
            expect(cmd.accessLevel, AccessLevel.read);
          }
        }
      });

      test('all commands have valid input schema', () async {
        final provider = container.read(_testUspCommandProvider);
        final commands = await provider.listCommands();

        for (final cmd in commands) {
          expect(cmd.inputSchema, isA<Map<String, dynamic>>());
          expect(cmd.inputSchema['type'], 'object');
        }
      });
    });

    group('listResources', () {
      test('returns all available resources', () {
        final provider = container.read(_testUspCommandProvider);
        final resources = provider.listResources();

        expect(resources, hasLength(10));
        expect(
          resources.map((r) => r.uri),
          containsAll([
            'router://system',
            'router://devices',
            'router://wifi',
            'router://wan',
            'router://lan',
            'router://dhcp',
            'router://ethernet',
            'router://firewall',
            'router://port-forwarding',
            'router://time',
          ]),
        );
      });

      test('each resource has name and description', () {
        final provider = container.read(_testUspCommandProvider);
        final resources = provider.listResources();

        for (final resource in resources) {
          expect(resource.name, isNotEmpty);
          expect(resource.description, isNotEmpty);
        }
      });
    });

    group('execute', () {
      test('getSystemInfo returns system data', () async {
        final provider = container.read(_testUspCommandProvider);
        final result = await provider.execute('getSystemInfo', {});

        expect(result.success, isTrue);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data['modelName'], 'MR7500');
        expect(result.data['softwareVersion'], '1.0.16.26013014');
      });

      test('getConnectedDevices returns device list', () async {
        final provider = container.read(_testUspCommandProvider);
        final result = await provider.execute('getConnectedDevices', {});

        expect(result.success, isTrue);
        expect(result.data['totalCount'], 2);
        expect(result.data['onlineCount'], 2);
        expect(result.data['devices'], isA<List>());
        expect((result.data['devices'] as List).length, 2);
      });

      test('getWifiSettings returns wifi data', () async {
        final provider = container.read(_testUspCommandProvider);
        final result = await provider.execute('getWifiSettings', {});

        expect(result.success, isTrue);
        expect(result.data['radios'], isA<List>());
        final radios = result.data['radios'] as List;
        expect(radios.length, 2);
      });

      test('getWanStatus returns wan data', () async {
        final provider = container.read(_testUspCommandProvider);
        final result = await provider.execute('getWanStatus', {});

        expect(result.success, isTrue);
        expect(result.data['isConnected'], isTrue);
        expect(result.data['ipAddress'], '192.168.1.100');
        expect(result.data['connectionType'], 'DHCP');
      });

      test('getNetworkOverview returns combined data', () async {
        final provider = container.read(_testUspCommandProvider);
        final result = await provider.execute('getNetworkOverview', {});

        expect(result.success, isTrue);
        expect(result.data['routerModel'], 'MR7500');
        expect(result.data['internetStatus'], 'Connected');
        expect(result.data['totalDevices'], 2);
        expect(result.data['onlineDevices'], 2);
      });

      test('unknown command throws UnauthorizedCommandException', () async {
        final provider = container.read(_testUspCommandProvider);
        expect(
          () => provider.execute('unknownCommand', {}),
          throwsA(isA<UnauthorizedCommandException>()),
        );
      });
    });

    // Every result here is handed to `jsonEncode` on its way to the model. An
    // un-encodable value does not merely spoil one answer: the throw happens
    // after the result is already in the conversation history, so each later
    // request re-encodes the same entry and fails too, leaving the session
    // permanently unable to reply. These tests exist to keep that class of
    // value out of tool results.
    group('tool results are JSON-encodable', () {
      test('getDeviceAnalytics keys signal levels by label, not by int',
          () async {
        final provider = container.read(_testUspCommandProvider);

        final result = await provider.execute('getDeviceAnalytics', {});

        expect(result.success, isTrue);
        // The assertion that matters: an int-keyed map throws here.
        expect(() => jsonEncode(result.data), returnsNormally);
        expect(result.data['signalLevelDistribution'], {
          'excellent': 4,
          'good': 2,
          'fair': 1,
        });
      });

      test('unrecognised signal levels are kept rather than dropped', () async {
        final analyticsContainer = ProviderContainer(
          overrides: [
            uspDeviceAnalyticsProvider.overrideWith(
              () => _FixedDeviceAnalyticsNotifier(
                const DeviceAnalyticsState(
                  current: DeviceDistribution(
                    signalLevelDistribution: {7: 3},
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(analyticsContainer.dispose);
        final provider = analyticsContainer.read(_testUspCommandProvider);

        final result = await provider.execute('getDeviceAnalytics', {});

        expect(() => jsonEncode(result.data), returnsNormally);
        expect(result.data['signalLevelDistribution'], {'level7': 3});
      });

      // Covers every command at once. Commands whose providers are not stubbed
      // return a failure result, which is still encoded and sent, so they are
      // worth asserting on even though they carry no data.
      test('every command produces an encodable result', () async {
        final provider = container.read(_testUspCommandProvider);
        final commands = await provider.listCommands();

        for (final cmd in commands) {
          final result = await provider.execute(cmd.name, {});
          expect(
            () => jsonEncode(result.data),
            returnsNormally,
            reason: '${cmd.name} returned a result that cannot be encoded',
          );
          _expectStringKeysThroughout(result.data, cmd.name);
        }
      });
    });

    group('readResource', () {
      test('router://system returns system info', () async {
        final provider = container.read(_testUspCommandProvider);
        final resource = await provider.readResource('router://system');

        expect(resource.uri, 'router://system');
        expect(resource.content, isA<Map<String, dynamic>>());
        expect(resource.content['modelName'], 'MR7500');
      });

      test('router://devices returns device list', () async {
        final provider = container.read(_testUspCommandProvider);
        final resource = await provider.readResource('router://devices');

        expect(resource.uri, 'router://devices');
        expect(resource.content['devices'], isA<List>());
      });

      test('router://wifi returns wifi settings', () async {
        final provider = container.read(_testUspCommandProvider);
        final resource = await provider.readResource('router://wifi');

        expect(resource.uri, 'router://wifi');
        expect(resource.content['radios'], isA<List>());
      });

      test('router://wan returns wan status', () async {
        final provider = container.read(_testUspCommandProvider);
        final resource = await provider.readResource('router://wan');

        expect(resource.uri, 'router://wan');
        expect(resource.content['isConnected'], isTrue);
      });

      test('unknown resource throws ResourceNotFoundException', () async {
        final provider = container.read(_testUspCommandProvider);
        expect(
          () => provider.readResource('router://unknown'),
          throwsA(isA<ResourceNotFoundException>()),
        );
      });
    });

    group('error handling', () {
      test('returns failure when systemInfo provider has no data', () async {
        final emptyContainer = ProviderContainer(
          overrides: [
            systemInfoDataProvider.overrideWith(
              () => _LoadingSystemInfoNotifier(),
            ),
          ],
        );
        final provider = emptyContainer.read(_testUspCommandProvider);

        final result = await provider.execute('getSystemInfo', {});

        expect(result.success, isFalse);
        expect(result.error, contains('not available'));

        emptyContainer.dispose();
      });

      test('returns failure when devices provider has no data', () async {
        final emptyContainer = ProviderContainer(
          overrides: [
            devicesDataProvider.overrideWith(
              () => _LoadingDevicesNotifier(),
            ),
          ],
        );
        final provider = emptyContainer.read(_testUspCommandProvider);

        final result = await provider.execute('getConnectedDevices', {});

        expect(result.success, isFalse);
        expect(result.error, contains('not available'));

        emptyContainer.dispose();
      });
    });
  });

  group('buildRouterContext', () {
    test('builds context string from providers', () {
      final container = ProviderContainer(
        overrides: [
          systemInfoDataProvider.overrideWith(
            () => _FixedSystemInfoNotifier(_testSystemInfoData),
          ),
          devicesDataProvider.overrideWith(
            () => _FixedDevicesNotifier(_testDevicesData),
          ),
          wifiDataProvider.overrideWith(
            () => _FixedWifiNotifier(_testWifiData),
          ),
          wanDataProvider.overrideWith(
            () => _FixedWanNotifier(_testWanData),
          ),
        ],
      );

      final context = buildRouterContext(container.read);

      expect(context, contains('# Current Router State'));
      expect(context, contains('## Router'));
      expect(context, contains('Model: MR7500'));
      expect(context, contains('## Internet Connection'));
      expect(context, contains('Status: Connected'));
      expect(context, contains('## Connected Devices'));
      expect(context, contains('Total connected devices: 2'));
      expect(context, contains('## WiFi'));

      container.dispose();
    });

    test('handles missing data gracefully', () {
      final container = ProviderContainer(
        overrides: [
          systemInfoDataProvider.overrideWith(
            () => _LoadingSystemInfoNotifier(),
          ),
          devicesDataProvider.overrideWith(
            () => _LoadingDevicesNotifier(),
          ),
          wifiDataProvider.overrideWith(
            () => _LoadingWifiNotifier(),
          ),
          wanDataProvider.overrideWith(
            () => _LoadingWanNotifier(),
          ),
        ],
      );

      final context = buildRouterContext(container.read);

      expect(context, contains('# Current Router State'));
      // Should not crash, just omit sections with no data

      container.dispose();
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

/// Fails if any map nested anywhere under [value] is keyed by something other
/// than a `String`.
///
/// `jsonEncode` already rejects those keys, so this adds nothing for a result
/// that is fully populated. It earns its place on the sparse ones: a tool whose
/// provider holds no data returns an empty map, which encodes cleanly and would
/// let a non-string key pass unnoticed until the day that tool has data.
void _expectStringKeysThroughout(Object? value, String commandName) {
  if (value is Map) {
    for (final entry in value.entries) {
      expect(
        entry.key,
        isA<String>(),
        reason: '$commandName has a non-String map key: ${entry.key}',
      );
      _expectStringKeysThroughout(entry.value, commandName);
    }
  } else if (value is Iterable) {
    for (final element in value) {
      _expectStringKeysThroughout(element, commandName);
    }
  }
}

// =============================================================================
// Fixed Notifiers (set state immediately in build)
// =============================================================================

class _FixedDeviceAnalyticsNotifier extends UspDeviceAnalyticsNotifier {
  final DeviceAnalyticsState _data;
  _FixedDeviceAnalyticsNotifier(this._data);

  @override
  DeviceAnalyticsState build() => _data;
}

class _FixedSystemMonitorNotifier extends UspSystemMonitorNotifier {
  final SystemMonitorState _data;
  _FixedSystemMonitorNotifier(this._data);

  @override
  SystemMonitorState build() => _data;
}

class _FixedTrafficAnalysisNotifier extends UspTrafficAnalysisNotifier {
  final TrafficAnalysisState _data;
  _FixedTrafficAnalysisNotifier(this._data);

  @override
  TrafficAnalysisState build() => _data;
}

class _FixedSystemInfoNotifier extends SystemInfoDataNotifier {
  final SystemInfoData _data;
  _FixedSystemInfoNotifier(this._data);

  @override
  Future<SystemInfoData> build() async {
    state = AsyncValue.data(_data);
    return _data;
  }
}

class _FixedDevicesNotifier extends DevicesDataNotifier {
  final DevicesData _data;
  _FixedDevicesNotifier(this._data);

  @override
  Future<DevicesData> build() async {
    state = AsyncValue.data(_data);
    return _data;
  }
}

class _FixedWifiNotifier extends WifiDataNotifier {
  final WifiData _data;
  _FixedWifiNotifier(this._data);

  @override
  Future<WifiData> build() async {
    state = AsyncValue.data(_data);
    return _data;
  }
}

class _FixedWanNotifier extends WanDataNotifier {
  final WanData _data;
  _FixedWanNotifier(this._data);

  @override
  Future<WanData> build() async {
    state = AsyncValue.data(_data);
    return _data;
  }
}

// =============================================================================
// Loading Notifiers (never complete, stay in loading state)
// =============================================================================

class _LoadingSystemInfoNotifier extends SystemInfoDataNotifier {
  @override
  Future<SystemInfoData> build() async {
    await Future.delayed(const Duration(days: 1));
    throw UnimplementedError();
  }
}

class _LoadingDevicesNotifier extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async {
    await Future.delayed(const Duration(days: 1));
    throw UnimplementedError();
  }
}

class _LoadingWifiNotifier extends WifiDataNotifier {
  @override
  Future<WifiData> build() async {
    await Future.delayed(const Duration(days: 1));
    throw UnimplementedError();
  }
}

class _LoadingWanNotifier extends WanDataNotifier {
  @override
  Future<WanData> build() async {
    await Future.delayed(const Duration(days: 1));
    throw UnimplementedError();
  }
}

// =============================================================================
// Test Data Fixtures
// =============================================================================

final _testSystemInfoData = SystemInfoData(
  model: const SystemInfoUIModel(
    modelName: 'MR7500',
    manufacturer: 'Linksys',
    hardwareVersion: '1.0',
    softwareVersion: '1.0.16.26013014',
    serialNumber: 'ABC123456',
    uptime: 86400,
    totalMemory: 524288,
    freeMemory: 262144,
    cpuUsage: 25,
  ),
);

final _testDevicesData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'MR7500',
      connectedClients: [
        ClientDevice(
          mac: 'AA:BB:CC:DD:EE:01',
          ip: '192.168.1.100',
          hostName: 'iPhone-15-Pro',
          isActive: true,
          connectionType: ConnectionType.wifi,
          wifi: WifiConnectionInfo(signalStrength: -42, band: '5GHz'),
        ),
        ClientDevice(
          mac: 'AA:BB:CC:DD:EE:02',
          ip: '192.168.1.101',
          hostName: 'MacBook-Air',
          isActive: true,
          connectionType: ConnectionType.wifi,
          wifi: WifiConnectionInfo(signalStrength: -68, band: '5GHz'),
        ),
      ],
    ),
  ),
);

final _testWifiData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: const [
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.1.',
      band: '2.4GHz',
      enable: true,
      transmitPower: -1,
      channel: 6,
      autoChannelEnable: false,
      channelBandwidth: '20MHz',
      maxBitRate: 300,
      supportedStandards: 'b,g,n,ax',
      accessPoints: [
        WifiAccessPointUIModel(
          enable: true,
          ssidName: 'TestNetwork',
          securityMode: 'WPA2-Personal',
          encryptionMode: 'AES',
          isGuest: false,
        ),
      ],
    ),
    WifiRadioUIModel(
      instancePath: 'Device.WiFi.Radio.2.',
      band: '5GHz',
      enable: true,
      transmitPower: -1,
      channel: 36,
      autoChannelEnable: true,
      channelBandwidth: '80MHz',
      maxBitRate: 1200,
      supportedStandards: 'a,n,ac,ax',
      accessPoints: [
        WifiAccessPointUIModel(
          enable: true,
          ssidName: 'TestNetwork',
          securityMode: 'WPA3-Personal',
          encryptionMode: 'AES',
          isGuest: false,
        ),
      ],
    ),
  ],
);

/// Levels 3/2/1 populated and 0 absent, matching the notifier, which only
/// records levels it actually saw.
const _testDeviceAnalyticsState = DeviceAnalyticsState(
  current: DeviceDistribution(
    wifiCount: 7,
    wiredCount: 2,
    onlineCount: 9,
    offlineCount: 1,
    bandDistribution: {'2.4GHz': 3, '5GHz': 4, 'Wired': 2},
    signalLevelDistribution: {3: 4, 2: 2, 1: 1},
    bandSignalQuality: {'2.4GHz': 0.62, '5GHz': 0.88},
  ),
);

/// Two snapshots so the history arrays the tool builds are non-empty; the tools
/// treat an empty history as "no data yet" and return a failure instead.
final _testSystemMonitorState = SystemMonitorState(
  refreshInterval: const Duration(seconds: 30),
  history: [
    SystemSnapshot(
      timestamp: DateTime.utc(2026, 1, 1, 0, 0),
      cpuPercent: 21,
      memoryPercent: 47,
      totalMemoryKb: 524288,
      freeMemoryKb: 277872,
      uptimeSeconds: 86400,
    ),
    SystemSnapshot(
      timestamp: DateTime.utc(2026, 1, 1, 0, 0, 30),
      cpuPercent: 25,
      memoryPercent: 49,
      totalMemoryKb: 524288,
      freeMemoryKb: 267386,
      uptimeSeconds: 86430,
    ),
  ],
);

final _testTrafficAnalysisState = TrafficAnalysisState(
  refreshInterval: const Duration(seconds: 10),
  history: [
    MultiInterfaceSnapshot(
      timestamp: DateTime.utc(2026, 1, 1, 0, 0),
      interfaces: const {
        TrafficInterface.wan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 12000,
          downloadBytesPerSec: 98000,
          uploadPacketsPerSec: 41,
          downloadPacketsPerSec: 133,
          totalBytesSent: 4200000,
          totalBytesReceived: 51000000,
          totalPacketsSent: 18400,
          totalPacketsReceived: 62100,
        ),
      },
    ),
    MultiInterfaceSnapshot(
      timestamp: DateTime.utc(2026, 1, 1, 0, 0, 10),
      interfaces: const {
        TrafficInterface.wan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 15500,
          downloadBytesPerSec: 143000,
          uploadPacketsPerSec: 52,
          downloadPacketsPerSec: 190,
          totalBytesSent: 4355000,
          totalBytesReceived: 52430000,
          totalPacketsSent: 18920,
          totalPacketsReceived: 64000,
        ),
      },
    ),
  ],
);

final _testWanData = WanData(
  model: const WanStatusUIModel(
    isUp: true,
    addressingType: 'DHCP',
    ipAddress: '192.168.1.100',
    subnetMask: '255.255.255.0',
    gateway: '192.168.1.1',
    ipv6Enabled: false,
    mtu: 1500,
  ),
);
