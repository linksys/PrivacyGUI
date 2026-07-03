import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/ai/providers/usp_command_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
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
// Fixed Notifiers (set state immediately in build)
// =============================================================================

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
