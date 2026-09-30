import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

class MockUspClient extends Mock implements UspClient {}

const _modePath = 'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterMode';
const _listPath = 'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterList';
const _cmdPath = 'Device.WiFi.DataElements.Network.X_LINKSYS_SetMACFilter()';

ConnectedDevice _device({
  String instancePath = 'Device.Hosts.Host.1.',
  String macAddress = 'AA:BB:CC:DD:EE:FF',
  String ipAddress = '192.168.1.100',
  String hostName = 'MyDevice',
  bool isActive = true,
  String interface_ = 'Device.Ethernet.Interface.1',
  String addressSource = 'DHCP',
  String? deviceRole,
}) =>
    ConnectedDevice(
      instancePath: instancePath,
      macAddress: macAddress,
      ipAddress: ipAddress,
      hostName: hostName,
      isActive: isActive,
      interface_: interface_,
      addressSource: addressSource,
      deviceRole: deviceRole,
      ipv4Addresses: const [],
      ipv6Addresses: const [],
    );

MeshNode _meshNode({
  String instancePath = 'Device.WiFi.DataElements.Network.Device.1.',
  String id = 'AA:BB:CC:DD:EE:00',
  String radioBackhaulStaMac = '',
  String backhaulBackhaulMacAddress = '',
}) =>
    MeshNode(
      instancePath: instancePath,
      id: id,
      manufacturerModel: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'SN0',
      softwareVersion: '2.0.0',
      multiApEasyMeshAgentOperationMode: '',
      backhaulBackhaulDeviceId: '',
      backhaulBackhaulMacAddress: backhaulBackhaulMacAddress,
      backhaulLinkType: '',
      backhaulMacAddressMultiAp: '',
      backhaulStatsLastDataDownlinkRate: 0,
      backhaulStatsPacketsSent: 0,
      backhaulStatsPacketsReceived: 0,
      backhaulStatsErrorsSent: 0,
      backhaulStatsErrorsReceived: 0,
      backhaulStatsLastDataUplinkRate: 0,
      backhaulStatsSignalStrengthRcpi: 0,
      radios: [
        MeshRadio(
          instancePath: '${instancePath}Radio.1.',
          backhaulStaMacAddress: radioBackhaulStaMac,
          currentOperatingClassProfiles: const [],
          bssList: const [],
        ),
      ],
    );

/// A `Hosts.Host` response with one ordinary client and one slave node in its
/// post-firmware-fix shape (FWDEV#166): a real MAC, interface, and Active.
const _devicesResponseWithSlaveNode = {
  'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
  'Device.Hosts.Host.1.IPAddress': '192.168.1.10',
  'Device.Hosts.Host.1.HostName': 'Laptop',
  'Device.Hosts.Host.1.Active': true,
  'Device.Hosts.Host.1.Layer1Interface': 'Device.Ethernet.Interface.1',
  'Device.Hosts.Host.1.AddressSource': 'DHCP',
  'Device.Hosts.Host.2.PhysAddress': 'AA:BB:CC:DD:EE:99',
  'Device.Hosts.Host.2.IPAddress': '192.168.1.11',
  'Device.Hosts.Host.2.HostName': 'Node-Bedroom',
  'Device.Hosts.Host.2.Active': true,
  'Device.Hosts.Host.2.Layer1Interface': 'Device.WiFi.Radio.1',
  'Device.Hosts.Host.2.AddressSource': 'DHCP',
  'Device.Hosts.Host.2.DeviceRole': 'slave',
};

Map<String, dynamic> _networkDeviceResponse(
  int instance, {
  required String id,
  String radioBackhaulStaMac = '',
  String backhaulBackhaulMacAddress = '',
  String linkType = '',
}) {
  final p = 'Device.WiFi.DataElements.Network.Device.$instance.';
  return {
    '${p}ID': id,
    '${p}ManufacturerModel': 'MR7500',
    '${p}Manufacturer': 'Linksys',
    '${p}SerialNumber': 'SN$instance',
    '${p}SoftwareVersion': '2.0.0',
    '${p}Radio.1.BackhaulSta.MACAddress': radioBackhaulStaMac,
    '${p}MultiAPDevice.EasyMeshAgentOperationMode': '',
    '${p}MultiAPDevice.Backhaul.BackhaulDeviceID': '',
    '${p}MultiAPDevice.Backhaul.BackhaulMACAddress': backhaulBackhaulMacAddress,
    '${p}MultiAPDevice.Backhaul.LinkType': linkType,
    '${p}MultiAPDevice.Backhaul.MACAddress': '',
    '${p}MultiAPDevice.Backhaul.Stats.LastDataDownlinkRate': '0',
    '${p}MultiAPDevice.Backhaul.Stats.PacketsSent': '0',
    '${p}MultiAPDevice.Backhaul.Stats.PacketsReceived': '0',
    '${p}MultiAPDevice.Backhaul.Stats.ErrorsSent': '0',
    '${p}MultiAPDevice.Backhaul.Stats.ErrorsReceived': '0',
    '${p}MultiAPDevice.Backhaul.Stats.LastDataUplinkRate': '0',
    '${p}MultiAPDevice.Backhaul.Stats.SignalStrength': '0',
  };
}

final _networkResponseWithBackhaul = {
  ..._networkDeviceResponse(1, id: 'AA:BB:CC:DD:EE:00'),
  ..._networkDeviceResponse(
    2,
    id: 'AA:BB:CC:DD:EE:98',
    radioBackhaulStaMac: 'aa:bb:cc:dd:ee:9b',
    backhaulBackhaulMacAddress: 'AA:BB:CC:DD:EE:9B',
    linkType: 'Wi-Fi',
  ),
};

void main() {
  late MockUspClient mockUsp;
  late UspInstantPrivacyService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspInstantPrivacyService(mockUsp);
  });

  /// Stubs the three reads `fetchAll` makes, routing by path:
  ///   Hosts.Host   → connected devices
  ///   DataElements → mesh network (backhaul MACs)
  ///   X_LINKSYS_MACFilter* → the network-wide filter mode + list
  ///
  /// [mode]/[list] set the MAC-filter read (Instant Privacy is Allow mode).
  void stubFetchAll(
    MockUspClient mock, {
    Map<String, dynamic>? devicesResponse,
    String mode = 'Allow',
    String list = 'AA:BB:CC:DD:EE:01',
    Map<String, dynamic>? networkResponse,
  }) {
    final devices = devicesResponse ??
        {
          'Device.Hosts.Host.1.PhysAddress': 'AA:BB:CC:DD:EE:01',
          'Device.Hosts.Host.1.IPAddress': '192.168.1.10',
          'Device.Hosts.Host.1.HostName': 'Laptop',
          'Device.Hosts.Host.1.Active': true,
          'Device.Hosts.Host.1.Layer1Interface': 'Device.Ethernet.Interface.1',
          'Device.Hosts.Host.1.AddressSource': 'DHCP',
        };
    final network = networkResponse ?? const <String, dynamic>{};
    when(() => mock.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Hosts.Host'))) {
        return devices;
      }
      if (paths.any((p) => p.toString().contains('X_LINKSYS_MACFilter'))) {
        return {_modePath: mode, _listPath: list};
      }
      if (paths.any((p) => p.toString().contains('DataElements'))) {
        return network;
      }
      return const <String, dynamic>{};
    });
  }

  void stubOperateOk(MockUspClient mock) {
    when(() => mock.operate(any(), args: any(named: 'args'))).thenAnswer(
        (_) async => {
              'success': true,
              'result': {
                'data': {'commandKey': 'k'}
              }
            });
  }

  // ---------------------------------------------------------------------------
  // static MAC helpers (delegated to UspMacFilterService, still public API here)
  // ---------------------------------------------------------------------------

  group('validateMac', () {
    test('accepts colon and dash, rejects garbage', () {
      expect(UspInstantPrivacyService.validateMac('AA:BB:CC:DD:EE:01'), isTrue);
      expect(UspInstantPrivacyService.validateMac('aa-bb-cc-dd-ee-01'), isTrue);
      expect(UspInstantPrivacyService.validateMac('nope'), isFalse);
    });
  });

  group('normalizeMac', () {
    test('uppercases and colon-separates', () {
      expect(UspInstantPrivacyService.normalizeMac('aa-bb-cc-dd-ee-01'),
          'AA:BB:CC:DD:EE:01');
    });
  });

  // ---------------------------------------------------------------------------
  // read helpers — unchanged by the migration
  // ---------------------------------------------------------------------------

  group('activeDevices', () {
    test('keeps active non-node devices, maps to UI model', () {
      final data = ConnectedDevices(items: [
        _device(macAddress: 'AA:BB:CC:DD:EE:01', hostName: 'Laptop'),
      ]);

      final result = service.activeDevices(data);

      expect(result, hasLength(1));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(result[0].displayName, 'Laptop');
      expect(result[0].ipAddress, '192.168.1.100');
    });

    test('drops inactive, interfaceless, and mesh-node rows', () {
      final data = ConnectedDevices(items: [
        _device(macAddress: 'AA:BB:CC:DD:EE:01', isActive: false),
        _device(macAddress: 'AA:BB:CC:DD:EE:02', interface_: ''),
        _device(macAddress: 'AA:BB:CC:DD:EE:03', deviceRole: 'slave'),
        _device(macAddress: 'AA:BB:CC:DD:EE:04', hostName: 'Keep'),
      ]);

      final result = service.activeDevices(data);

      expect(result.map((d) => d.mac), ['AA:BB:CC:DD:EE:04']);
    });

    for (final role in ['master', 'slave']) {
      test('excludes a $role node by role even when active (REQ-10a)', () {
        final data = ConnectedDevices(items: [
          _device(macAddress: 'AA:BB:CC:DD:EE:0A', deviceRole: role),
        ]);

        expect(service.activeDevices(data), isEmpty);
      });
    }
  });

  group('meshNodeMacs', () {
    test('collects node host MACs regardless of active/interface', () {
      final data = ConnectedDevices(items: [
        _device(macAddress: 'AA:BB:CC:DD:EE:01'), // client
        _device(
            macAddress: 'AA:BB:CC:DD:EE:99',
            deviceRole: 'slave',
            isActive: false,
            interface_: ''),
      ]);

      expect(service.meshNodeMacs(data), ['AA:BB:CC:DD:EE:99']);
    });
  });

  group('meshBackhaulMacs', () {
    test('unions device + radio backhaul MACs, drops empty/unset', () {
      final data = DataElementsNetwork(items: [
        _meshNode(id: 'AA:BB:CC:DD:EE:00'), // gateway, both empty
        _meshNode(
          instancePath: 'Device.WiFi.DataElements.Network.Device.2.',
          id: 'AA:BB:CC:DD:EE:98',
          radioBackhaulStaMac: 'aa:bb:cc:dd:ee:9b',
          backhaulBackhaulMacAddress: 'AA:BB:CC:DD:EE:9B',
        ),
      ]);

      // Both sources normalize to the same MAC → deduped to one.
      expect(service.meshBackhaulMacs(data), ['AA:BB:CC:DD:EE:9B']);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchAll — now reads the network-wide filter
  // ---------------------------------------------------------------------------

  group('fetchAll', () {
    test('enriches the allowed list with hostnames', () async {
      stubFetchAll(mockUsp, mode: 'Allow', list: 'AA:BB:CC:DD:EE:01');

      final result = await service.fetchAll();

      expect(result.isEnabled, isTrue);
      expect(result.connectedDevices, hasLength(1));
      expect(result.allowedDevices, hasLength(1));
      expect(result.allowedDevices[0].displayName, 'Laptop');
    });

    test('isEnabled is false when mode is Disabled', () async {
      stubFetchAll(mockUsp, mode: 'Disabled', list: '');

      final result = await service.fetchAll();

      expect(result.isEnabled, isFalse);
      expect(result.allowedDevices, isEmpty);
    });

    test('allowed device uses MAC when no host match', () async {
      stubFetchAll(mockUsp, mode: 'Allow', list: 'FF:FF:FF:FF:FF:FF');

      final result = await service.fetchAll();

      expect(result.allowedDevices[0].displayName, 'FF:FF:FF:FF:FF:FF');
    });

    test('allowed devices carry the isPrivateMac flag', () async {
      stubFetchAll(mockUsp,
          mode: 'Allow', list: '2E:52:AD:77:D0:F8,74:12:13:21:56:3B');

      final result = await service.fetchAll();

      expect(result.allowedDevices, hasLength(2));
      expect(result.allowedDevices[0].mac, '2E:52:AD:77:D0:F8');
      expect(result.allowedDevices[0].isPrivateMac, isTrue);
      expect(result.allowedDevices[1].isPrivateMac, isFalse);
    });

    test(
        'neither a node host MAC nor a node backhaul MAC reaches a '
        'customer-facing list (REQ-10a)', () async {
      stubFetchAll(
        mockUsp,
        devicesResponse: _devicesResponseWithSlaveNode,
        networkResponse: _networkResponseWithBackhaul,
        mode: 'Allow',
        list: 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:99,AA:BB:CC:DD:EE:9B',
      );

      final result = await service.fetchAll();

      expect(result.connectedDevices.map((d) => d.mac), ['AA:BB:CC:DD:EE:01']);
      expect(result.allowedDevices.map((d) => d.mac), ['AA:BB:CC:DD:EE:01']);
    });
  });

  // ---------------------------------------------------------------------------
  // writes — now operate(SetMACFilter), Allow mode
  // ---------------------------------------------------------------------------

  Map _capturedArgs() =>
      verify(() => mockUsp.operate(_cmdPath, args: captureAny(named: 'args')))
          .captured
          .single as Map;

  group('enable', () {
    test('writes Allow with the given whitelist as a JSON array', () async {
      stubFetchAll(mockUsp, mode: 'Disabled', list: '');
      stubOperateOk(mockUsp);
      final ctx = (await service.fetchAll()).macFilterContext;

      await service.enable(['AA:BB:CC:DD:EE:01'], ctx);

      final args = _capturedArgs();
      expect(args['Mode'], 'Allow');
      expect(args['MACAddressList'], jsonEncode(['AA:BB:CC:DD:EE:01']));
    });

    test('unions the always-allowed node MACs (REQ-10a)', () async {
      stubFetchAll(
        mockUsp,
        devicesResponse: _devicesResponseWithSlaveNode,
        networkResponse: _networkResponseWithBackhaul,
        mode: 'Disabled',
        list: '',
      );
      stubOperateOk(mockUsp);
      final ctx = (await service.fetchAll()).macFilterContext;

      await service.enable(['AA:BB:CC:DD:EE:01'], ctx);

      final args = _capturedArgs();
      final written =
          (jsonDecode(args['MACAddressList'] as String) as List).cast<String>();
      // Customer MAC plus both node identities (host MAC + backhaul MAC).
      expect(written, contains('AA:BB:CC:DD:EE:01'));
      expect(written, contains('AA:BB:CC:DD:EE:99'));
      expect(written, contains('AA:BB:CC:DD:EE:9B'));
    });
  });

  group('disable', () {
    test('writes Disabled', () async {
      stubFetchAll(mockUsp, mode: 'Allow', list: 'AA:BB:CC:DD:EE:01');
      stubOperateOk(mockUsp);
      final ctx = (await service.fetchAll()).macFilterContext;

      await service.disable(ctx);

      expect(_capturedArgs()['Mode'], 'Disabled');
    });
  });

  group('addMac', () {
    test('adds a new MAC and returns true', () async {
      stubFetchAll(mockUsp, mode: 'Allow', list: 'AA:BB:CC:DD:EE:01');
      stubOperateOk(mockUsp);
      final ctx = (await service.fetchAll()).macFilterContext;

      final added = await service.addMac('AA:BB:CC:DD:EE:02', ctx);

      expect(added, isTrue);
      final written =
          (jsonDecode(_capturedArgs()['MACAddressList'] as String) as List)
              .cast<String>();
      expect(written, containsAll(['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']));
    });

    test('returns false and does not write when already present', () async {
      stubFetchAll(mockUsp, mode: 'Allow', list: 'AA:BB:CC:DD:EE:01');
      stubOperateOk(mockUsp);
      final ctx = (await service.fetchAll()).macFilterContext;

      final added = await service.addMac('AA:BB:CC:DD:EE:01', ctx);

      expect(added, isFalse);
      verifyNever(() => mockUsp.operate(any(), args: any(named: 'args')));
    });
  });

  group('MacFilterContext', () {
    test('empty context has no macs', () {
      expect(MacFilterContext.empty, MacFilterContext.empty);
    });
  });
}
