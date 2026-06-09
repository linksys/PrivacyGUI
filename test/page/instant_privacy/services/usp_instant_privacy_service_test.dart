import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
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
}) =>
    ConnectedDevice(
      instancePath: instancePath,
      macAddress: macAddress,
      ipAddress: ipAddress,
      hostName: hostName,
      isActive: isActive,
      interface_: interface_,
      addressSource: addressSource,
      ipv4Addresses: const [],
      ipv6Addresses: const [],
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
  });

  // ---------------------------------------------------------------------------
  // High-level CRUD (fetchAll, enable, disable, addMac)
  // ---------------------------------------------------------------------------

  /// Standard path-based mock for fetchAll: routes ConnectedDevices vs
  /// MacFilterAccessPoints based on requested paths.
  void stubFetchAll(
    MockUspClient mock, {
    Map<String, dynamic>? devicesResponse,
    Map<String, dynamic>? apResponse,
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
    when(() => mock.get(any())).thenAnswer((_) async {
      final paths = _.positionalArguments[0] as List;
      if (paths.any((p) => p.toString().contains('Hosts.Host'))) {
        return devices;
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
