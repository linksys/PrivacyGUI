import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/generated/mac_filter_access_points.g.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

class MockUspClient extends Mock implements UspClient {}

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

/// Only the three fields [UspInstantPrivacyService.meshBackhaulMacs] reads are
/// parameterised; the rest of [MeshNode] is irrelevant to the allow-list.
MeshNode _meshNode({
  String instancePath = 'Device.WiFi.DataElements.Network.Device.1.',
  String id = 'AA:BB:CC:DD:EE:00',
  String backhaulMacAddress = '',
  String backhaulBackhaulMacAddress = '',
}) =>
    MeshNode(
      instancePath: instancePath,
      id: id,
      manufacturerModel: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'SN0',
      softwareVersion: '2.0.0',
      backhaulAlId: '',
      backhaulMacAddress: backhaulMacAddress,
      backhaulMediaType: '',
      backhaulPhyRate: 0,
      multiApAssocIEEE1905DeviceRef: '',
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
      backhaulStatsSignalStrength: 0,
      radios: const [],
    );

MacFilterAccessPoint _ap({
  String instancePath = 'Device.WiFi.AccessPoint.1.',
  String ssidReference = 'Device.WiFi.SSID.1',
  bool macAddressControlEnabled = false,
  String allowedMACAddress = '',
}) =>
    MacFilterAccessPoint(
      instancePath: instancePath,
      ssidReference: ssidReference,
      macAddressControlEnabled: macAddressControlEnabled,
      allowedMACAddress: allowedMACAddress,
    );

/// A `Hosts.Host` response with one ordinary client and one slave node, the
/// node in its **post-firmware-fix** shape (FWDEV#166): a real MAC, a real
/// `Layer1Interface`, and a truthful `Active`. Today's masking shape would let
/// the existing predicates hide the node for the wrong reason.
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

/// One complete `DataElements.Network.Device.{i}` response block.
///
/// Every path must be spelled out: [DataElementsNetwork.fetch] validates that
/// the response carries all of them and throws otherwise. That matches the real
/// device, which returns empty strings for fields it has no value for rather
/// than omitting the keys. Only the fields this feature reads are parameterised.
Map<String, dynamic> _networkDeviceResponse(
  int instance, {
  required String id,
  String backhaulMacAddress = '',
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
    '${p}BackhaulALID': '',
    '${p}BackhaulMACAddress': backhaulMacAddress,
    '${p}BackhaulMediaType': '',
    '${p}BackhaulPHYRate': '0',
    '${p}MultiAPDevice.AssocIEEE1905DeviceRef': '',
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

/// A `DataElements.Network.Device` response shaped like the measured M60TB bench
/// (2026-09-03): the gateway, which has no upstream backhaul and reports both
/// backhaul MAC fields empty, plus one wireless-backhaul slave whose backhaul
/// MAC is **neither** its `Hosts.Host.PhysAddress` (`…:EE:99`, see
/// [_devicesResponseWithSlaveNode]) **nor** its DataElements `ID` (`…:EE:98`) —
/// three distinct MACs per node, exactly as firmware reports them.
///
/// The two backhaul fields differ in case here for the same reason firmware
/// does: the top-level one came back lower-cased and the `MultiAPDevice` one
/// upper-cased on the real device.
final _networkResponseWithBackhaul = {
  ..._networkDeviceResponse(1, id: 'AA:BB:CC:DD:EE:00'),
  ..._networkDeviceResponse(
    2,
    id: 'AA:BB:CC:DD:EE:98',
    backhaulMacAddress: 'aa:bb:cc:dd:ee:9b',
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

  // ---------------------------------------------------------------------------
  // validateMac
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — validateMac', () {
    test('valid colon-separated MAC', () {
      expect(UspInstantPrivacyService.validateMac('AA:BB:CC:DD:EE:FF'), isTrue);
    });

    test('valid hyphen-separated MAC', () {
      expect(UspInstantPrivacyService.validateMac('AA-BB-CC-DD-EE-FF'), isTrue);
    });

    test('valid lowercase MAC', () {
      expect(UspInstantPrivacyService.validateMac('aa:bb:cc:dd:ee:ff'), isTrue);
    });

    test('trims whitespace', () {
      expect(UspInstantPrivacyService.validateMac('  AA:BB:CC:DD:EE:FF  '),
          isTrue);
    });

    test('rejects empty string', () {
      expect(UspInstantPrivacyService.validateMac(''), isFalse);
    });

    test('rejects too few octets', () {
      expect(UspInstantPrivacyService.validateMac('AA:BB:CC:DD:EE'), isFalse);
    });

    test('rejects non-hex characters', () {
      expect(
          UspInstantPrivacyService.validateMac('GG:BB:CC:DD:EE:FF'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // normalizeMac
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — normalizeMac', () {
    test('uppercases and replaces hyphens', () {
      expect(UspInstantPrivacyService.normalizeMac('aa-bb-cc-dd-ee-ff'),
          'AA:BB:CC:DD:EE:FF');
    });

    test('trims whitespace', () {
      expect(UspInstantPrivacyService.normalizeMac('  aa:bb:cc:dd:ee:ff  '),
          'AA:BB:CC:DD:EE:FF');
    });

    test('idempotent for already normalized', () {
      expect(UspInstantPrivacyService.normalizeMac('AA:BB:CC:DD:EE:FF'),
          'AA:BB:CC:DD:EE:FF');
    });
  });

  // ---------------------------------------------------------------------------
  // activeDevices
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — activeDevices', () {
    test('returns only active devices with non-empty interface', () {
      final data = ConnectedDevices(items: [
        _device(
            isActive: true,
            interface_: 'eth0',
            macAddress: 'AA:BB:CC:DD:EE:01'),
        _device(
          instancePath: 'p.2.',
          isActive: false,
          interface_: 'eth0',
          macAddress: 'AA:BB:CC:DD:EE:02',
        ),
        _device(
          instancePath: 'p.3.',
          isActive: true,
          interface_: '',
          macAddress: 'AA:BB:CC:DD:EE:03',
        ),
      ]);

      final result = service.activeDevices(data);

      expect(result, hasLength(1));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:01');
    });

    test('uses hostname as displayName when available', () {
      final data = ConnectedDevices(items: [
        _device(hostName: 'Laptop', macAddress: 'AA:BB:CC:DD:EE:FF'),
      ]);

      final result = service.activeDevices(data);

      expect(result[0].displayName, 'Laptop');
    });

    test('uses MAC as displayName when hostname empty', () {
      final data = ConnectedDevices(items: [
        _device(hostName: '', macAddress: 'aa:bb:cc:dd:ee:ff'),
      ]);

      final result = service.activeDevices(data);

      expect(result[0].displayName, 'AA:BB:CC:DD:EE:FF');
    });

    test('empty devices returns empty list', () {
      final result = service.activeDevices(ConnectedDevices(items: []));
      expect(result, isEmpty);
    });

    test('flags locally-administered (private) MAC as isPrivateMac', () {
      // Second hex digit 2/6/A/E → U/L bit set → private/randomized MAC.
      final data = ConnectedDevices(items: [
        _device(macAddress: '2E:52:AD:77:D0:F8'),
      ]);

      final result = service.activeDevices(data);

      expect(result[0].isPrivateMac, isTrue);
    });

    test('does not flag a universally-administered (real) MAC', () {
      // 74 → U/L bit clear → real hardware MAC.
      final data = ConnectedDevices(items: [
        _device(macAddress: '74:12:13:21:56:3B'),
      ]);

      final result = service.activeDevices(data);

      expect(result[0].isPrivateMac, isFalse);
    });

    // Both role literals live in one boolean expression, so line coverage looks
    // complete with only one of them tested — table-drive instead. 'master' is
    // the gateway the customer is connected through, the worst row of all to
    // leak into a customer-facing list.
    for (final role in ['master', 'slave']) {
      test(
          'excludes a mesh node (deviceRole $role) in its post-firmware-fix '
          'shape — isActive true and a populated interface (REQ-10a)', () {
        // The point of the fix: after the firmware node-row PhysAddress bug
        // (FWDEV#166) is fixed, a node row looks exactly like a normal active
        // device — truthful Active, a real interface, a real MAC. The ONLY
        // thing that distinguishes it is deviceRole, so today's masking shape
        // (Active=0 / empty interface) is deliberately NOT used here.
        final data = ConnectedDevices(items: [
          _device(
            instancePath: 'p.node.',
            macAddress: 'AA:BB:CC:DD:EE:99',
            isActive: true,
            interface_: 'Device.WiFi.Radio.1',
            deviceRole: role,
          ),
        ]);

        final result = service.activeDevices(data);

        expect(result, isEmpty);
      });
    }

    test('excludes a mesh node whose deviceRole casing differs from firmware',
        () {
      // DeviceRole is an unvalidated wire string; a build reporting 'Slave'
      // must not turn the node back into a customer-facing row.
      final data = ConnectedDevices(items: [
        _device(
          macAddress: 'AA:BB:CC:DD:EE:99',
          isActive: true,
          interface_: 'Device.WiFi.Radio.1',
          deviceRole: ' Slave ',
        ),
      ]);

      expect(service.activeDevices(data), isEmpty);
    });

    test(
        'includes an ordinary client row (no deviceRole) — exclusion has not '
        'widened', () {
      final data = ConnectedDevices(items: [
        _device(
          macAddress: 'AA:BB:CC:DD:EE:10',
          isActive: true,
          interface_: 'Device.Ethernet.Interface.1',
          deviceRole: null,
        ),
      ]);

      final result = service.activeDevices(data);

      expect(result, hasLength(1));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:10');
    });
  });

  // ---------------------------------------------------------------------------
  // meshNodeMacs
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — meshNodeMacs', () {
    test('collects master and slave MACs and ignores clients', () {
      final data = ConnectedDevices(items: [
        _device(macAddress: 'AA:BB:CC:DD:EE:01', deviceRole: 'master'),
        _device(macAddress: 'aa:bb:cc:dd:ee:02', deviceRole: 'slave'),
        _device(macAddress: 'AA:BB:CC:DD:EE:03', deviceRole: 'client'),
        _device(macAddress: 'AA:BB:CC:DD:EE:04', deviceRole: null),
      ]);

      expect(service.meshNodeMacs(data),
          ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);
    });

    test('includes a node firmware currently reports as down', () {
      // REQ-10a is about the node keeping its place in the allow-list. A node
      // dropped because it looked offline for one poll cannot come back: on an
      // allow-list-mode filter, absent means denied. This is exactly the shape
      // node rows have TODAY under FWDEV#166 (Active = 0, empty interface).
      final data = ConnectedDevices(items: [
        _device(
          macAddress: 'AA:BB:CC:DD:EE:99',
          isActive: false,
          interface_: '',
          deviceRole: 'slave',
        ),
      ]);

      expect(service.meshNodeMacs(data), ['AA:BB:CC:DD:EE:99']);
    });

    test('skips node rows with no MAC and de-duplicates', () {
      final data = ConnectedDevices(items: [
        _device(macAddress: '', deviceRole: 'slave'),
        _device(macAddress: 'AA:BB:CC:DD:EE:01', deviceRole: 'master'),
        _device(macAddress: 'AA-BB-CC-DD-EE-01', deviceRole: 'master'),
      ]);

      expect(service.meshNodeMacs(data), ['AA:BB:CC:DD:EE:01']);
    });

    test('returns empty for a client-only network', () {
      final data = ConnectedDevices(items: [
        _device(macAddress: 'AA:BB:CC:DD:EE:10'),
      ]);

      expect(service.meshNodeMacs(data), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // meshBackhaulMacs
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — meshBackhaulMacs', () {
    test('collects the backhaul MAC, which is not the host MAC', () {
      // Measured shape: host MAC …:EE:99, DataElements ID …:EE:98, backhaul MAC
      // …:EE:9B. Only the last one is what the AP's allow-list is checked
      // against, so it is the only one this method may return.
      final data = DataElementsNetwork(items: [
        _meshNode(
          id: 'AA:BB:CC:DD:EE:98',
          backhaulBackhaulMacAddress: 'AA:BB:CC:DD:EE:9B',
        ),
      ]);

      expect(service.meshBackhaulMacs(data), ['AA:BB:CC:DD:EE:9B']);
    });

    test('reads both fields firmware exposes the address in', () {
      final data = DataElementsNetwork(items: [
        _meshNode(backhaulMacAddress: 'AA:BB:CC:DD:EE:9B'),
        _meshNode(
          instancePath: 'Device.WiFi.DataElements.Network.Device.2.',
          backhaulBackhaulMacAddress: 'AA:BB:CC:DD:EE:AB',
        ),
      ]);

      expect(service.meshBackhaulMacs(data),
          ['AA:BB:CC:DD:EE:9B', 'AA:BB:CC:DD:EE:AB']);
    });

    test('de-duplicates the two fields after normalizing case and separator',
        () {
      // The real device returned the top-level field lower-cased and the
      // MultiAPDevice one upper-cased for the same node.
      final data = DataElementsNetwork(items: [
        _meshNode(
          backhaulMacAddress: 'aa-bb-cc-dd-ee-9b',
          backhaulBackhaulMacAddress: 'AA:BB:CC:DD:EE:9B',
        ),
      ]);

      expect(service.meshBackhaulMacs(data), ['AA:BB:CC:DD:EE:9B']);
    });

    test('the gateway contributes nothing — it has no upstream backhaul', () {
      // Both fields come back empty for the root node. It reaches the
      // allow-list through meshNodeMacs instead.
      final data = DataElementsNetwork(items: [_meshNode()]);

      expect(service.meshBackhaulMacs(data), isEmpty);
    });

    test('returns empty for a router with no mesh', () {
      expect(service.meshBackhaulMacs(const DataElementsNetwork(items: [])),
          isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // isEnabled
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — isEnabled', () {
    test('returns true when any AP has MAC filter enabled', () {
      final data = MacFilterAccessPoints(items: [
        _ap(macAddressControlEnabled: false),
        _ap(instancePath: 'p.2.', macAddressControlEnabled: true),
      ]);

      expect(service.isEnabled(data), isTrue);
    });

    test('returns false when all APs disabled', () {
      final data = MacFilterAccessPoints(items: [
        _ap(macAddressControlEnabled: false),
      ]);

      expect(service.isEnabled(data), isFalse);
    });

    test('returns false when no APs', () {
      final data = MacFilterAccessPoints(items: []);
      expect(service.isEnabled(data), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // allowedDevices
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — allowedDevices', () {
    test('parses comma-separated MAC list', () {
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:02'),
      ]);

      final result = service.allowedDevices(data);

      expect(result, hasLength(2));
      expect(result[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(result[1].mac, 'AA:BB:CC:DD:EE:02');
    });

    test('deduplicates MACs', () {
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:01'),
      ]);

      final result = service.allowedDevices(data);

      expect(result, hasLength(1));
    });

    test('trims whitespace in MAC entries', () {
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: ' AA:BB:CC:DD:EE:01 , AA:BB:CC:DD:EE:02 '),
      ]);

      final result = service.allowedDevices(data);

      expect(result, hasLength(2));
    });

    test('empty allowedMACAddress returns empty list', () {
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: ''),
      ]);

      final result = service.allowedDevices(data);

      expect(result, isEmpty);
    });

    test('empty AP list returns empty', () {
      final result = service.allowedDevices(MacFilterAccessPoints(items: []));
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // buildEnableUpdates
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — buildEnableUpdates', () {
    test('creates update for each AP with enabled + MAC list', () {
      final data = MacFilterAccessPoints(items: [
        _ap(instancePath: 'ap.1.'),
        _ap(instancePath: 'ap.2.'),
      ]);

      final updates = service.buildEnableUpdates(
        ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02'],
        data,
      );

      expect(updates, hasLength(2));
      expect(updates[0].macAddressControlEnabled, isTrue);
      expect(
          updates[0].allowedMACAddress, 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:02');
      expect(updates[1].instancePath, 'ap.2.');
    });

    test('empty MAC list creates update with empty string', () {
      final data = MacFilterAccessPoints(items: [_ap()]);

      final updates = service.buildEnableUpdates([], data);

      expect(updates[0].allowedMACAddress, '');
    });

    test('always-allowed MACs are unioned into the written list (REQ-10a)', () {
      final data = MacFilterAccessPoints(items: [_ap()]);

      final updates = service.buildEnableUpdates(
        ['AA:BB:CC:DD:EE:10'],
        data,
        alwaysAllowedMacs: ['AA:BB:CC:DD:EE:99'],
      );

      expect(
          updates[0].allowedMACAddress, 'AA:BB:CC:DD:EE:10,AA:BB:CC:DD:EE:99');
    });

    test('always-allowed MACs are not duplicated when already in the snapshot',
        () {
      final data = MacFilterAccessPoints(items: [_ap()]);

      final updates = service.buildEnableUpdates(
        ['AA:BB:CC:DD:EE:99', 'AA:BB:CC:DD:EE:10'],
        data,
        alwaysAllowedMacs: ['aa-bb-cc-dd-ee-99'],
      );

      expect(
          updates[0].allowedMACAddress, 'AA:BB:CC:DD:EE:99,AA:BB:CC:DD:EE:10');
    });

    test('always-allowed MACs are written even when the snapshot is empty', () {
      // The node must be allowed regardless of what the customer's snapshot
      // happened to contain — enabling the feature must never lock a node out.
      final data = MacFilterAccessPoints(items: [_ap()]);

      final updates = service.buildEnableUpdates(
        [],
        data,
        alwaysAllowedMacs: ['AA:BB:CC:DD:EE:99'],
      );

      expect(updates[0].allowedMACAddress, 'AA:BB:CC:DD:EE:99');
    });
  });

  // ---------------------------------------------------------------------------
  // buildDisableUpdates
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — buildDisableUpdates', () {
    test('creates disable update for each AP', () {
      final data = MacFilterAccessPoints(items: [
        _ap(instancePath: 'ap.1.'),
        _ap(instancePath: 'ap.2.'),
      ]);

      final updates = service.buildDisableUpdates(data);

      expect(updates, hasLength(2));
      expect(updates[0].macAddressControlEnabled, isFalse);
      expect(updates[0].allowedMACAddress, '');
    });
  });

  // ---------------------------------------------------------------------------
  // buildAddMacUpdates
  // ---------------------------------------------------------------------------

  group('UspInstantPrivacyService — buildAddMacUpdates', () {
    test('appends new MAC to existing list', () {
      final data = MacFilterAccessPoints(items: [
        _ap(
          instancePath: 'ap.1.',
          allowedMACAddress: 'AA:BB:CC:DD:EE:01',
        ),
      ]);

      final updates = service.buildAddMacUpdates('AA:BB:CC:DD:EE:02', data);

      expect(updates, hasLength(1));
      expect(
          updates[0].allowedMACAddress, 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:02');
    });

    test('returns empty when MAC already present', () {
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: 'AA:BB:CC:DD:EE:01'),
      ]);

      final updates = service.buildAddMacUpdates('AA:BB:CC:DD:EE:01', data);

      expect(updates, isEmpty);
    });

    test('returns empty when no APs', () {
      final data = MacFilterAccessPoints(items: []);

      final updates = service.buildAddMacUpdates('AA:BB:CC:DD:EE:01', data);

      expect(updates, isEmpty);
    });

    test('adds first MAC to empty list', () {
      final data = MacFilterAccessPoints(items: [
        _ap(instancePath: 'ap.1.', allowedMACAddress: ''),
      ]);

      final updates = service.buildAddMacUpdates('AA:BB:CC:DD:EE:01', data);

      expect(updates, hasLength(1));
      expect(updates[0].allowedMACAddress, 'AA:BB:CC:DD:EE:01');
    });

    test('restores always-allowed MACs missing from the stored list (REQ-10a)',
        () {
      // A list written before this fix (or by an older build) has no node MACs
      // in it. Adding a device is a write, so it is also a chance to put the
      // invariant back rather than perpetuate the omission.
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: 'AA:BB:CC:DD:EE:01'),
      ]);

      final updates = service.buildAddMacUpdates(
        'AA:BB:CC:DD:EE:02',
        data,
        alwaysAllowedMacs: ['AA:BB:CC:DD:EE:99'],
      );

      expect(updates[0].allowedMACAddress,
          'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:02,AA:BB:CC:DD:EE:99');
    });

    test('always-allowed MACs do not change the already-present verdict', () {
      final data = MacFilterAccessPoints(items: [
        _ap(allowedMACAddress: 'AA:BB:CC:DD:EE:01'),
      ]);

      final updates = service.buildAddMacUpdates(
        'AA:BB:CC:DD:EE:01',
        data,
        alwaysAllowedMacs: ['AA:BB:CC:DD:EE:99'],
      );

      expect(updates, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // High-level CRUD (fetchAll, enable, disable, addMac)
  // ---------------------------------------------------------------------------

  /// Standard path-based mock for fetchAll: routes ConnectedDevices vs
  /// MacFilterAccessPoints vs DataElementsNetwork based on requested paths.
  ///
  /// [networkResponse] defaults to `{}` — a router with no mesh, which is what
  /// most of these tests are about. Pass [_networkResponseWithBackhaul] for the
  /// mesh case.
  void stubFetchAll(
    MockUspClient mock, {
    Map<String, dynamic>? devicesResponse,
    Map<String, dynamic>? apResponse,
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
    final aps = apResponse ??
        {
          'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
          'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': true,
          'Device.WiFi.AccessPoint.1.AllowedMACAddress': 'AA:BB:CC:DD:EE:01',
        };
    final network = networkResponse ?? const <String, dynamic>{};
    when(() => mock.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Hosts.Host'))) {
        return devices;
      }
      if (paths.any((p) => p.toString().contains('DataElements'))) {
        return network;
      }
      return aps;
    });
  }

  group('UspInstantPrivacyService — fetchAll', () {
    test('returns enriched result with active devices and allowed list',
        () async {
      stubFetchAll(mockUsp);

      final result = await service.fetchAll();

      expect(result.isEnabled, isTrue);
      expect(result.connectedDevices, hasLength(1));
      expect(result.allowedDevices, hasLength(1));
      // Allowed device should be enriched with hostname from devices
      expect(result.allowedDevices[0].displayName, 'Laptop');
    });

    test('allowed device uses MAC when no host match', () async {
      stubFetchAll(mockUsp, apResponse: {
        'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
        'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': true,
        'Device.WiFi.AccessPoint.1.AllowedMACAddress': 'FF:FF:FF:FF:FF:FF',
      });

      final result = await service.fetchAll();

      // FF:FF:FF:FF:FF:FF is not in connected devices → MAC address as display name
      expect(result.allowedDevices[0].displayName, 'FF:FF:FF:FF:FF:FF');
    });

    test('allowed devices have isPrivateMac flag set correctly', () async {
      stubFetchAll(mockUsp, apResponse: {
        'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
        'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': true,
        // 2E:... is locally-administered (private), 74:... is universal (real)
        'Device.WiFi.AccessPoint.1.AllowedMACAddress':
            '2E:52:AD:77:D0:F8,74:12:13:21:56:3B',
      });

      final result = await service.fetchAll();

      expect(result.allowedDevices, hasLength(2));
      expect(result.allowedDevices[0].mac, '2E:52:AD:77:D0:F8');
      expect(result.allowedDevices[0].isPrivateMac, isTrue);
      expect(result.allowedDevices[1].mac, '74:12:13:21:56:3B');
      expect(result.allowedDevices[1].isPrivateMac, isFalse);
    });

    test(
        'neither a node host MAC nor a node backhaul MAC reaches a '
        'customer-facing list (REQ-10a)', () async {
      // Both are already on the wire's allow-list, as REQ-10a requires. Neither
      // may show up as a row: the host MAC would read as a blockable device, and
      // the backhaul MAC has no hostname at all, so it would render as a bare
      // unexplained address.
      stubFetchAll(
        mockUsp,
        devicesResponse: _devicesResponseWithSlaveNode,
        networkResponse: _networkResponseWithBackhaul,
        apResponse: {
          'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
          'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': true,
          'Device.WiFi.AccessPoint.1.AllowedMACAddress':
              'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:99,AA:BB:CC:DD:EE:9B',
        },
      );

      final result = await service.fetchAll();

      expect(result.connectedDevices.map((d) => d.mac), ['AA:BB:CC:DD:EE:01']);
      expect(result.allowedDevices.map((d) => d.mac), ['AA:BB:CC:DD:EE:01']);
    });
  });

  group('UspInstantPrivacyService — enable', () {
    test('calls set via updateMany with enable updates', () async {
      // Stub fetchAll to get a real MacFilterContext
      stubFetchAll(mockUsp, apResponse: {
        'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
        'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': false,
        'Device.WiFi.AccessPoint.1.AllowedMACAddress': '',
      });
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final result = await service.fetchAll();

      await service.enable(['AA:BB:CC:DD:EE:01'], result.macFilterContext);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(
          params,
          containsPair(
            'Device.WiFi.AccessPoint.1.MACAddressControlEnabled',
            true,
          ));
      expect(
          params,
          containsPair(
            'Device.WiFi.AccessPoint.1.AllowedMACAddress',
            'AA:BB:CC:DD:EE:01',
          ));
    });

    test(
        'writes the mesh node MAC the customer-facing list omits — a node can '
        'never be locked out (REQ-10a)', () async {
      // This is where the requirement actually lives: the MAC set that reaches
      // the wire. The node is absent from connectedDevices by design, so the
      // notifier's snapshot cannot carry it — the service must.
      stubFetchAll(
        mockUsp,
        devicesResponse: _devicesResponseWithSlaveNode,
        apResponse: {
          'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
          'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': false,
          'Device.WiFi.AccessPoint.1.AllowedMACAddress': '',
        },
      );
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final result = await service.fetchAll();
      // Exactly what UspInstantPrivacyNotifier.enable() sends.
      final snapshot = result.connectedDevices.map((d) => d.mac).toList();
      expect(snapshot, ['AA:BB:CC:DD:EE:01']);

      await service.enable(snapshot, result.macFilterContext);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(
          params,
          containsPair(
            'Device.WiFi.AccessPoint.1.AllowedMACAddress',
            'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:99',
          ));
    });

    test(
        'writes the node backhaul MAC — the address the AP actually filters on '
        '(REQ-10a)', () async {
      // A node's host MAC is not the MAC it associates with. Writing only the
      // host MAC denies the node's own backhaul association: it disappears from
      // the mesh the moment the customer enables the feature. Measured on the
      // M60TB bench — see meshBackhaulMacs.
      stubFetchAll(
        mockUsp,
        devicesResponse: _devicesResponseWithSlaveNode,
        networkResponse: _networkResponseWithBackhaul,
        apResponse: {
          'Device.WiFi.AccessPoint.1.SSIDReference': 'Device.WiFi.SSID.1',
          'Device.WiFi.AccessPoint.1.MACAddressControlEnabled': false,
          'Device.WiFi.AccessPoint.1.AllowedMACAddress': '',
        },
      );
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final result = await service.fetchAll();
      final snapshot = result.connectedDevices.map((d) => d.mac).toList();

      await service.enable(snapshot, result.macFilterContext);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      final written =
          (params['Device.WiFi.AccessPoint.1.AllowedMACAddress'] as String)
              .split(',');
      expect(written, contains('AA:BB:CC:DD:EE:01')); // the customer's device
      expect(written, contains('AA:BB:CC:DD:EE:99')); // the node's host MAC
      expect(written, contains('AA:BB:CC:DD:EE:9B')); // the node's backhaul MAC
      // The gateway reports no backhaul, so nothing empty leaks into the list.
      expect(written, everyElement(isNotEmpty));
    });
  });

  group('UspInstantPrivacyService — disable', () {
    test('calls set via updateMany with disable updates', () async {
      stubFetchAll(mockUsp);
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final result = await service.fetchAll();

      await service.disable(result.macFilterContext);

      final captured = verify(
        () =>
            mockUsp.set(captureAny(), allowPartial: any(named: 'allowPartial')),
      ).captured;
      final params = captured.first as Map<String, dynamic>;
      expect(
          params,
          containsPair(
            'Device.WiFi.AccessPoint.1.MACAddressControlEnabled',
            false,
          ));
      expect(
          params,
          containsPair(
            'Device.WiFi.AccessPoint.1.AllowedMACAddress',
            '',
          ));
    });
  });

  group('UspInstantPrivacyService — addMac', () {
    test('adds new MAC and calls set', () async {
      stubFetchAll(mockUsp);
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {'data': <String, dynamic>{}},
              });

      final result = await service.fetchAll();

      final added = await service.addMac(
        'FF:FF:FF:FF:FF:FF',
        result.macFilterContext,
      );

      expect(added, isTrue);
      verify(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .called(1);
    });

    test('returns false when MAC already present', () async {
      stubFetchAll(mockUsp);

      final result = await service.fetchAll();

      // AA:BB:CC:DD:EE:01 is already in the allowed list
      final added = await service.addMac(
        'AA:BB:CC:DD:EE:01',
        result.macFilterContext,
      );

      expect(added, isFalse);
      verifyNever(
        () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // MacFilterContext
  // ---------------------------------------------------------------------------

  group('MacFilterContext', () {
    test('empty context is constant', () {
      expect(MacFilterContext.empty, MacFilterContext.empty);
    });

    test('props uses item count for equality', () async {
      stubFetchAll(mockUsp);
      final result = await service.fetchAll();

      // Same item count → equal props
      expect(result.macFilterContext.props, isNotEmpty);
      expect(MacFilterContext.empty.props, isNotEmpty);
    });
  });
}
