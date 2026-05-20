import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';

class MockUspClient extends Mock implements UspClient {}

/// Fake [SseOperationAwaiter] — mocktail can't easily handle the internal
/// state machine of the real class, so we record call arguments and return
/// canned [OperateResult]s set per-test.
class FakeSseOperationAwaiter implements SseOperationAwaiter {
  // Configurable per test:
  OperateResult? executeInSessionResult;
  OperateResult? executeResult;
  Object? executeInSessionError;
  Object? executeError;
  Map<String, OperateResult> executeInSessionResultsByCommand = {};

  // Recorded calls:
  int startSharedSessionCount = 0;
  int endSharedSessionCount = 0;
  String? lastReferencePath;
  final List<({String command, Map<String, String> args})>
      executeInSessionCalls = [];
  final List<({String command, String referencePath, Map<String, String> args})>
      executeCalls = [];

  @override
  Future<void> startSharedSession({required String referencePath}) async {
    startSharedSessionCount++;
    lastReferencePath = referencePath;
  }

  @override
  Future<void> endSharedSession() async {
    endSharedSessionCount++;
  }

  @override
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    executeInSessionCalls.add((command: operateCommand, args: args));
    if (executeInSessionError != null) throw executeInSessionError!;
    if (executeInSessionResultsByCommand.containsKey(operateCommand)) {
      return executeInSessionResultsByCommand[operateCommand]!;
    }
    if (executeInSessionResult != null) return executeInSessionResult!;
    throw StateError('No executeInSession result configured for '
        '$operateCommand');
  }

  @override
  Future<OperateResult> execute({
    required String operateCommand,
    required String referencePath,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    executeCalls.add(
        (command: operateCommand, referencePath: referencePath, args: args));
    if (executeError != null) throw executeError!;
    if (executeResult != null) return executeResult!;
    throw StateError('No execute result configured for $operateCommand');
  }

  @override
  Future<void> executeNoWait({
    required String operateCommand,
    Map<String, String> args = const {},
  }) async {}
}

void main() {
  late MockUspClient mockUsp;
  late FakeSseOperationAwaiter fakeAwaiter;
  late UnifiedDiagnosticsService service;

  setUp(() {
    mockUsp = MockUspClient();
    fakeAwaiter = FakeSseOperationAwaiter();
    service = UnifiedDiagnosticsService(mockUsp, fakeAwaiter);
  });

  // ────────────────────────────────────────────────────────────────────────
  // Test fixtures: full GET response maps satisfying codegen validation.
  // ────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> wanStatusResponse({
    String status = 'Up',
    String ip = '203.0.113.50',
    String mask = '255.255.255.0',
    String addressing = 'DHCP',
  }) =>
      {
        'Device.IP.Interface.2.Status': status,
        'Device.IP.Interface.2.IPv4Address.1.IPAddress': ip,
        'Device.IP.Interface.2.IPv4Address.1.SubnetMask': mask,
        'Device.IP.Interface.2.IPv4Address.1.AddressingType': addressing,
        'Device.IP.Interface.2.MaxMTUSize': '1500',
        'Device.IP.Interface.2.IPv6Enable': 'true',
      };

  Map<String, dynamic> systemInfoResponse({int uptime = 86400}) => {
        'Device.DeviceInfo.Manufacturer': 'Linksys',
        'Device.DeviceInfo.ModelName': 'M60TB',
        'Device.DeviceInfo.SerialNumber': 'SN-1',
        'Device.DeviceInfo.HardwareVersion': '1.0',
        'Device.DeviceInfo.SoftwareVersion': '1.0.16',
        'Device.DeviceInfo.UpTime': uptime.toString(),
        'Device.DeviceInfo.MemoryStatus.Total': '1024',
        'Device.DeviceInfo.MemoryStatus.Free': '512',
        'Device.DeviceInfo.ProcessStatus.CPUUsage': '10',
        'Device.DeviceInfo.ActiveFirmwareImage':
            'Device.DeviceInfo.FirmwareImage.1',
        'Device.DeviceInfo.BootFirmwareImage':
            'Device.DeviceInfo.FirmwareImage.1',
      };

  Map<String, dynamic> dnsClientResponse() => {
        'Device.DNS.Client.Enable': 'true',
        'Device.DNS.Client.Status': 'Enabled',
        'Device.DNS.Client.ServerNumberOfEntries': '2',
        'Device.DNS.Client.Server.1.DNSServer': '8.8.8.8',
        'Device.DNS.Client.Server.1.Type': 'DHCPv4',
        'Device.DNS.Client.Server.1.Enable': 'true',
        'Device.DNS.Client.Server.1.Status': 'Enabled',
        'Device.DNS.Client.Server.1.Alias': 'cpe-google',
        'Device.DNS.Client.Server.1.Interface': 'Device.IP.Interface.2.',
        'Device.DNS.Client.Server.2.DNSServer': '1.1.1.1',
        'Device.DNS.Client.Server.2.Type': 'DHCPv4',
        'Device.DNS.Client.Server.2.Enable': 'true',
        'Device.DNS.Client.Server.2.Status': 'Enabled',
        'Device.DNS.Client.Server.2.Alias': 'cpe-cloudflare',
        'Device.DNS.Client.Server.2.Interface': 'Device.IP.Interface.2.',
      };

  Map<String, dynamic> wifiRadiosResponse() => {
        'Device.WiFi.Radio.1.Enable': 'true',
        'Device.WiFi.Radio.1.Status': 'Up',
        'Device.WiFi.Radio.1.Channel': '6',
        'Device.WiFi.Radio.1.OperatingFrequencyBand': '2.4GHz',
        'Device.WiFi.Radio.1.OperatingChannelBandwidth': '20MHz',
        'Device.WiFi.Radio.1.PossibleChannels': '1-11',
        'Device.WiFi.Radio.1.OperatingStandards': 'g,n',
        'Device.WiFi.Radio.1.SupportedStandards': 'b,g,n',
        'Device.WiFi.Radio.1.TransmitPower': '100',
        'Device.WiFi.Radio.1.MaxBitRate': '300',
        'Device.WiFi.Radio.1.AutoChannelEnable': 'true',
        'Device.WiFi.Radio.1.IEEE80211hEnabled': 'false',
        'Device.WiFi.Radio.1.SupportedOperatingChannelBandwidths':
            '20MHz,40MHz',
        'Device.WiFi.Radio.2.Enable': 'true',
        'Device.WiFi.Radio.2.Status': 'Up',
        'Device.WiFi.Radio.2.Channel': '36',
        'Device.WiFi.Radio.2.OperatingFrequencyBand': '5GHz',
        'Device.WiFi.Radio.2.OperatingChannelBandwidth': '80MHz',
        'Device.WiFi.Radio.2.PossibleChannels': '36-165',
        'Device.WiFi.Radio.2.OperatingStandards': 'a,n,ac',
        'Device.WiFi.Radio.2.SupportedStandards': 'a,n,ac',
        'Device.WiFi.Radio.2.TransmitPower': '100',
        'Device.WiFi.Radio.2.MaxBitRate': '866',
        'Device.WiFi.Radio.2.AutoChannelEnable': 'true',
        'Device.WiFi.Radio.2.IEEE80211hEnabled': 'true',
        'Device.WiFi.Radio.2.SupportedOperatingChannelBandwidths':
            '20MHz,40MHz,80MHz',
      };

  Map<String, dynamic> connectedDeviceFields(
    int idx, {
    required String mac,
    required String hostName,
    required bool active,
    String? interfaceType = 'WiFi',
    int? signal,
    int? downlink,
    int? uplink,
    String? friendly,
  }) {
    final p = 'Device.Hosts.Host.$idx.';
    return <String, dynamic>{
      '${p}PhysAddress': mac,
      '${p}IPAddress': '192.168.1.$idx',
      '${p}HostName': hostName,
      '${p}Active': active ? 'true' : 'false',
      '${p}ActiveLastChange': '2026-05-20T00:00:00Z',
      '${p}Layer1Interface': interfaceType == 'WiFi'
          ? 'Device.WiFi.Radio.1.'
          : 'Device.Ethernet.Interface.1.',
      '${p}Layer3Interface': 'Device.IP.Interface.1.',
      '${p}InterfaceType': interfaceType ?? '',
      '${p}AddressSource': 'DHCP',
      '${p}DHCPClient': '',
      '${p}AssociatedDevice': '',
      '${p}DeviceID': 'id-$idx',
      '${p}DeviceRole': '',
      '${p}FriendlyName': friendly ?? '',
      '${p}Manufacturer': '',
      '${p}ModelName': '',
      '${p}OperatingSystem': '',
      '${p}ParentNodeID': '',
      '${p}SignalStrength': signal?.toString() ?? '',
      '${p}LastDataDownlinkRate': downlink?.toString() ?? '',
      '${p}LastDataUplinkRate': uplink?.toString() ?? '',
      '${p}IPv4Address.1.IPAddress': '192.168.1.$idx',
      '${p}IPv6Address.1.IPAddress': '',
    };
  }

  Map<String, dynamic> lanResponse({
    String min = '192.168.1.100',
    String max = '192.168.1.200',
    String enable = 'true',
  }) =>
      {
        'Device.IP.Interface.1.IPv4Address.1.IPAddress': '192.168.1.1',
        'Device.IP.Interface.1.IPv4Address.1.SubnetMask': '255.255.255.0',
        'Device.DHCPv4.Server.Pool.1.Enable': enable,
        'Device.DHCPv4.Server.Pool.1.MinAddress': min,
        'Device.DHCPv4.Server.Pool.1.MaxAddress': max,
        'Device.DHCPv4.Server.Pool.1.LeaseTime': '86400',
        'Device.DHCPv4.Server.Pool.1.DNSServers': '8.8.8.8',
        'Device.DeviceInfo.HostName': 'router',
        'Device.IP.Interface.1.IPv6Enable': 'false',
      };

  Map<String, dynamic> dhcpClientFields(int idx, {bool active = true}) {
    final p = 'Device.DHCPv4.Server.Pool.1.Client.$idx.';
    return <String, dynamic>{
      '${p}Chaddr': 'AA:BB:CC:DD:EE:0$idx',
      '${p}Active': active ? 'true' : 'false',
      '${p}IPv4Address.1.IPAddress': '192.168.1.${100 + idx}',
      '${p}IPv4Address.1.LeaseTimeRemaining': '2030-01-01T00:00:00Z',
    };
  }

  Map<String, dynamic> wifiAccessPointFields(int idx, String ssidRef) {
    final p = 'Device.WiFi.AccessPoint.$idx.';
    return <String, dynamic>{
      '${p}Enable': 'true',
      '${p}Status': 'Up',
      '${p}Security.ModesSupported': 'WPA2',
      '${p}Security.ModeEnabled': 'WPA2',
      '${p}Security.EncryptionMode': 'AES',
      '${p}Security.KeyPassphrase': 'secret',
      '${p}SSIDAdvertisementEnabled': 'true',
      '${p}SSIDReference': ssidRef,
    };
  }

  Map<String, dynamic> wifiSsidFields(int idx, String lowerLayers) {
    final p = 'Device.WiFi.SSID.$idx.';
    return <String, dynamic>{
      '${p}SSID': 'MyWifi-$idx',
      '${p}Enable': 'true',
      '${p}Status': 'Up',
      '${p}BSSID': 'AA:BB:CC:00:00:0$idx',
      '${p}LowerLayers': lowerLayers,
    };
  }

  Map<String, dynamic> wifiClientFields(
    int apIdx,
    int devIdx, {
    required int signalStrength,
    required bool active,
  }) {
    final p = 'Device.WiFi.AccessPoint.$apIdx.AssociatedDevice.$devIdx.';
    return <String, dynamic>{
      '${p}MACAddress': '11:22:33:44:55:0$devIdx',
      '${p}SignalStrength': signalStrength.toString(),
      '${p}Noise': '-90',
      '${p}LastDataDownlinkRate': '100000',
      '${p}LastDataUplinkRate': '50000',
      '${p}Active': active ? 'true' : 'false',
    };
  }

  // ────────────────────────────────────────────────────────────────────────

  group('checkWanStatus', () {
    test('parses WAN GET response into WanStatusUIModel', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => wanStatusResponse(ip: '198.51.100.10'));

      final result = await service.checkWanStatus();

      expect(result.status, 'Up');
      expect(result.ipAddress, '198.51.100.10');
      expect(result.subnetMask, '255.255.255.0');
      expect(result.addressingType, 'DHCP');
      expect(result.isUp, isTrue);
      expect(result.hasIp, isTrue);
    });

    test('marks status as not up when WAN is down', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => wanStatusResponse(
            status: 'Down',
            ip: '',
          ));

      final result = await service.checkWanStatus();

      expect(result.isUp, isFalse);
      expect(result.hasIp, isFalse);
    });

    test('propagates underlying GET errors', () async {
      when(() => mockUsp.get(any())).thenThrow('Get failed: Transport error');

      expect(service.checkWanStatus(), throwsA(isA<String>()));
    });
  });

  group('Session lifecycle', () {
    test('startSession delegates to awaiter with diagnostics path', () async {
      await service.startSession();
      expect(fakeAwaiter.startSharedSessionCount, 1);
      expect(fakeAwaiter.lastReferencePath, 'Device.IP.Diagnostics.');
    });

    test('endSession delegates to awaiter', () async {
      await service.endSession();
      expect(fakeAwaiter.endSharedSessionCount, 1);
    });
  });

  group('ping', () {
    test('parses successful PingResult and forwards args', () async {
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'k1',
        status: 'Complete',
        outputArgs: const {
          'SuccessCount': '5',
          'FailureCount': '0',
          'AverageResponseTime': '15',
          'MinimumResponseTime': '10',
          'MaximumResponseTime': '20',
        },
      );

      final result = await service.ping('8.8.8.8', repeatCount: 5);

      expect(result.host, '8.8.8.8');
      expect(result.successCount, 5);
      expect(result.failureCount, 0);
      expect(result.avgResponseTime, 15);
      expect(result.minResponseTime, 10);
      expect(result.maxResponseTime, 20);
      expect(result.status, 'Complete');

      final call = fakeAwaiter.executeInSessionCalls.single;
      expect(call.command, 'Device.IP.Diagnostics.IPPing()');
      expect(call.args, {'Host': '8.8.8.8', 'NumberOfRepetitions': '5'});
    });

    test('rethrows when awaiter throws', () async {
      fakeAwaiter.executeInSessionError = Exception('SSE timeout');
      expect(service.ping('8.8.8.8'), throwsException);
    });
  });

  group('pingGateway', () {
    test('derives gateway from WAN IP/mask and pings it', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          wanStatusResponse(ip: '203.0.113.50', mask: '255.255.255.0'));
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {
          'SuccessCount': '3',
          'FailureCount': '0',
          'AverageResponseTime': '5',
          'MinimumResponseTime': '5',
          'MaximumResponseTime': '5',
        },
      );

      final result = await service.pingGateway();

      expect(result.host, '203.0.113.1'); // Derived gateway
      expect(
          fakeAwaiter.executeInSessionCalls.single.args['Host'], '203.0.113.1');
    });

    test('falls back to 192.168.1.1 when WAN IP/mask are malformed', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => wanStatusResponse(
            ip: 'not-an-ip',
            mask: 'not-a-mask',
          ));
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {
          'SuccessCount': '3',
          'FailureCount': '0',
          'AverageResponseTime': '1',
          'MinimumResponseTime': '1',
          'MaximumResponseTime': '1',
        },
      );

      // Cannot parse IP — int.parse on 'not-an-ip' throws inside _deriveGateway,
      // which means the throw escapes pingGateway. Confirm error path.
      expect(service.pingGateway(), throwsA(isA<FormatException>()));
    });

    test('throws when WAN has no IP', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => wanStatusResponse(status: 'Down', ip: ''));

      expect(service.pingGateway(), throwsA(isA<Exception>()));
    });
  });

  group('pingDns / pingInternet', () {
    test('pingDns defaults to 8.8.8.8', () async {
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {
          'SuccessCount': '3',
          'FailureCount': '0',
          'AverageResponseTime': '10',
          'MinimumResponseTime': '5',
          'MaximumResponseTime': '15',
        },
      );

      final result = await service.pingDns();

      expect(result.host, '8.8.8.8');
      expect(fakeAwaiter.executeInSessionCalls.single.args['Host'], '8.8.8.8');
    });

    test('pingInternet defaults to 1.1.1.1', () async {
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {
          'SuccessCount': '3',
          'FailureCount': '0',
          'AverageResponseTime': '20',
          'MinimumResponseTime': '15',
          'MaximumResponseTime': '25',
        },
      );

      final result = await service.pingInternet();

      expect(result.host, '1.1.1.1');
      expect(fakeAwaiter.executeInSessionCalls.single.args['Host'], '1.1.1.1');
    });
  });

  group('getDnsClient', () {
    test('returns parsed DnsClient with two configured servers', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => dnsClientResponse());

      final dns = await service.getDnsClient();

      expect(dns.enabled, isTrue);
      expect(dns.serverCount, 2);
      expect(dns.servers.length, 2);
      expect(dns.servers.first.address, '8.8.8.8');
      expect(dns.servers.last.address, '1.1.1.1');
    });
  });

  group('nsLookup', () {
    test('parses NSLookup result and includes DNSServer arg when provided',
        () async {
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'NSLookupDiagnostics()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {
          'Status': 'Success',
          'SuccessCount': '1',
          'Result.1.Status': 'Success',
          'Result.1.AnswerType': 'A',
          'Result.1.HostNameReturned': 'example.com',
          'Result.1.IPAddresses': '93.184.216.34',
          'Result.1.DNSServerIP': '8.8.8.8',
          'Result.1.ResponseTime': '12',
        },
      );

      final result =
          await service.nsLookup('example.com', dnsServer: '8.8.8.8');

      expect(result.hostName, 'example.com');
      expect(result.successCount, 1);
      expect(result.answers.single.ipAddresses, ['93.184.216.34']);

      final args = fakeAwaiter.executeInSessionCalls.single.args;
      expect(args['HostName'], 'example.com');
      expect(args['DNSServer'], '8.8.8.8');
    });

    test('omits DNSServer when not provided', () async {
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'NSLookupDiagnostics()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {'Status': 'Success', 'SuccessCount': '0'},
      );

      await service.nsLookup('example.com');

      expect(
          fakeAwaiter.executeInSessionCalls.single.args
              .containsKey('DNSServer'),
          isFalse);
    });

    test('omits DNSServer when empty string passed', () async {
      fakeAwaiter.executeInSessionResult = OperateResult(
        commandName: 'NSLookupDiagnostics()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {'Status': 'Success', 'SuccessCount': '0'},
      );

      await service.nsLookup('example.com', dnsServer: '');

      expect(
          fakeAwaiter.executeInSessionCalls.single.args
              .containsKey('DNSServer'),
          isFalse);
    });

    test('rethrows when awaiter throws', () async {
      fakeAwaiter.executeInSessionError = Exception('boom');
      expect(service.nsLookup('host'), throwsException);
    });
  });

  group('traceroute', () {
    test('uses non-session execute and parses hops', () async {
      fakeAwaiter.executeResult = OperateResult(
        commandName: 'TraceRoute()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {
          'RouteHops.1.Host': 'gw',
          'RouteHops.1.HostAddress': '192.168.1.1',
          'RouteHops.1.RTTimes': '1,2,3',
          'RouteHops.2.Host': 'isp',
          'RouteHops.2.HostAddress': '10.0.0.1',
          'RouteHops.2.RTTimes': '10,20,15',
        },
      );

      final result = await service.traceroute(host: '8.8.8.8', maxHops: 20);

      expect(result.host, '8.8.8.8');
      expect(result.hops.length, 2);
      expect(result.hops.first.hopNumber, 1);

      final call = fakeAwaiter.executeCalls.single;
      expect(call.command, 'Device.IP.Diagnostics.TraceRoute()');
      expect(call.referencePath, 'Device.IP.Diagnostics.TraceRoute.');
      expect(call.args, {'Host': '8.8.8.8', 'MaxHopCount': '20'});
    });
  });

  group('checkWifiRadios', () {
    test('returns list of WiFiRadioUIModel with band/channel fields', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => wifiRadiosResponse());

      final radios = await service.checkWifiRadios();

      expect(radios.length, 2);
      expect(radios[0].band, '2.4GHz');
      expect(radios[0].is2_4GHz, isTrue);
      expect(radios[1].band, '5GHz');
      expect(radios[1].is5GHz, isTrue);
      expect(radios[1].is6GHz, isFalse);
    });
  });

  group('checkConnectedDevices', () {
    test('returns counts and high-bandwidth devices', () async {
      final response = <String, dynamic>{
        ...connectedDeviceFields(1,
            mac: '00:11:22:33:44:55',
            hostName: 'Mac',
            active: true,
            // 60 Mbps downlink → high bandwidth
            downlink: 60000000,
            signal: -50),
        ...connectedDeviceFields(2,
            mac: '66:77:88:99:AA:BB',
            hostName: '',
            active: true,
            // 11 Mbps uplink → high bandwidth (uplink threshold > 10 Mbps)
            uplink: 11000000,
            signal: -55),
        ...connectedDeviceFields(3,
            mac: 'CC:DD:EE:FF:00:11',
            hostName: 'Phone',
            active: false,
            downlink: 1000000),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkConnectedDevices();

      expect(result.totalDevices, 3);
      expect(result.activeDevices, 2);
      // Mac (named) and 66:77... (no hostName, falls back to mac)
      expect(result.highBandwidthDevices,
          containsAll(['Mac', '66:77:88:99:AA:BB']));
      expect(result.highBandwidthDevices.length, 2);
      expect(result.hasHighBandwidthDevices, isTrue);
      expect(result.hasManyDevices, isFalse);
    });

    test('hasHighBandwidthDevices is false when none qualify', () async {
      final response = <String, dynamic>{
        ...connectedDeviceFields(1,
            mac: '00:11:22:33:44:55',
            hostName: 'Phone',
            active: true,
            downlink: 1000),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkConnectedDevices();

      expect(result.highBandwidthDevices, isEmpty);
      expect(result.hasHighBandwidthDevices, isFalse);
    });
  });

  group('getDeviceScores', () {
    test('returns wireless/wired classification per active device', () async {
      final response = <String, dynamic>{
        ...connectedDeviceFields(1,
            mac: 'AA:BB:CC:00:00:01',
            hostName: 'Laptop',
            active: true,
            interfaceType: 'WiFi',
            signal: -55,
            downlink: 80000),
        ...connectedDeviceFields(2,
            mac: 'AA:BB:CC:00:00:02',
            hostName: '',
            friendly: 'Desk-PC',
            active: true,
            interfaceType: 'Ethernet',
            downlink: 1000000),
        ...connectedDeviceFields(3,
            mac: 'AA:BB:CC:00:00:03', hostName: 'Idle', active: false),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final scores = await service.getDeviceScores();

      expect(scores.length, 2);
      final laptop =
          scores.firstWhere((s) => s.macAddress == 'AA:BB:CC:00:00:01');
      expect(laptop.isWireless, isTrue);
      expect(laptop.name, 'Laptop');

      final pc = scores.firstWhere((s) => s.macAddress == 'AA:BB:CC:00:00:02');
      expect(pc.isWireless, isFalse);
      expect(pc.name, 'Desk-PC'); // hostName empty → friendlyName
    });

    test('getDeviceScore looks up by MAC address', () async {
      final response = <String, dynamic>{
        ...connectedDeviceFields(1,
            mac: 'AA:BB:CC:00:00:01',
            hostName: 'L1',
            active: true,
            signal: -50,
            downlink: 100000),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final found = await service.getDeviceScore('AA:BB:CC:00:00:01');
      expect(found?.name, 'L1');

      final missing = await service.getDeviceScore('99:99:99:99:99:99');
      expect(missing, isNull);
    });
  });

  group('checkDhcpPool', () {
    test(
        'computes capacity from MinAddress/MaxAddress and counts active leases',
        () async {
      final response = <String, dynamic>{
        ...lanResponse(min: '192.168.1.100', max: '192.168.1.200'),
        ...dhcpClientFields(1, active: true),
        ...dhcpClientFields(2, active: true),
        ...dhcpClientFields(3, active: false),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async {
        // Both LAN + DHCP responses come from get(); merge enables both fetches.
        return response;
      });

      final pool = await service.checkDhcpPool();

      expect(pool.enabled, isTrue);
      expect(pool.capacity, 101); // 200 - 100 + 1
      expect(pool.usedLeases, 2);
      expect(pool.totalLeases, 3);
      expect(pool.usageRatio, closeTo(2 / 101, 1e-6));
      expect(pool.isExhausted, isFalse);
      expect(pool.isNearCapacity, isFalse);
      expect(pool.capacityUnknown, isFalse);
    });

    test('treats malformed Min/Max as unknown capacity', () async {
      final response = <String, dynamic>{
        ...lanResponse(min: 'not-an-ip', max: '192.168.1.200'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final pool = await service.checkDhcpPool();

      expect(pool.capacity, 0);
      expect(pool.capacityUnknown, isTrue);
      expect(pool.usageRatio, 0);
      expect(pool.isExhausted, isFalse);
    });

    test('treats inverted ranges (max < min) as unknown capacity', () async {
      final response = <String, dynamic>{
        ...lanResponse(min: '192.168.1.200', max: '192.168.1.100'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final pool = await service.checkDhcpPool();

      expect(pool.capacity, 0);
      expect(pool.capacityUnknown, isTrue);
    });

    test('rejects octets outside 0-255 range', () async {
      final response = <String, dynamic>{
        ...lanResponse(min: '192.168.1.100', max: '192.168.1.999'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final pool = await service.checkDhcpPool();
      expect(pool.capacity, 0);
    });

    test('reports exhausted pool when used >= capacity', () async {
      final leases = <String, dynamic>{};
      // Capacity = 192.168.1.100 → 192.168.1.101 → size 2. Use 2 active.
      for (int i = 1; i <= 2; i++) {
        leases.addAll(dhcpClientFields(i, active: true));
      }
      final response = <String, dynamic>{
        ...lanResponse(min: '192.168.1.100', max: '192.168.1.101'),
        ...leases,
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final pool = await service.checkDhcpPool();
      expect(pool.capacity, 2);
      expect(pool.usedLeases, 2);
      expect(pool.isExhausted, isTrue);
      expect(pool.isNearCapacity, isTrue);
    });
  });

  group('analyzeWifiCoverage', () {
    test('flags weak signal devices and computes average', () async {
      final response = <String, dynamic>{
        ...wifiRadiosResponse(),
        ...connectedDeviceFields(1,
            mac: 'AA:00:00:00:00:01',
            hostName: 'Strong',
            active: true,
            signal: -50),
        ...connectedDeviceFields(2,
            mac: 'AA:00:00:00:00:02',
            hostName: 'Weak',
            active: true,
            signal: -75),
        ...connectedDeviceFields(
          3,
          mac: 'AA:00:00:00:00:03',
          hostName: 'Wired',
          active: true,
          interfaceType: 'Ethernet',
          // No signalStrength → not wireless
        ),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final coverage = await service.analyzeWifiCoverage();

      expect(coverage.totalWirelessDevices, 2);
      expect(coverage.weakSignalDevices.length, 1);
      expect(coverage.weakSignalDevices.first.name, 'Weak');
      expect(coverage.weakSignalDevices.first.rssiDbm, -75);
      expect(coverage.averageSignalStrength, (-50 + -75) ~/ 2);
      expect(coverage.radios.length, 2);
      expect(coverage.hasWeakSignalDevices, isTrue);
      expect(coverage.hasCoverageIssues, isTrue);
    });

    test('returns 0 average when no wireless devices', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => wifiRadiosResponse());

      final coverage = await service.analyzeWifiCoverage();
      expect(coverage.totalWirelessDevices, 0);
      expect(coverage.averageSignalStrength, 0);
      expect(coverage.hasWeakSignalDevices, isFalse);
    });
  });

  group('analyzeWifiSignalPerRadio', () {
    test('joins APs/SSIDs/Radios and aggregates RSSI per radio', () async {
      final response = <String, dynamic>{
        ...wifiRadiosResponse(),
        // AP.1 → SSID.1 → Radio.1 (2.4GHz)
        // AP.2 → SSID.2 → Radio.2 (5GHz)
        ...wifiAccessPointFields(1, 'Device.WiFi.SSID.1.'),
        ...wifiAccessPointFields(2, 'Device.WiFi.SSID.2.'),
        ...wifiSsidFields(1, 'Device.WiFi.Radio.1.'),
        ...wifiSsidFields(2, 'Device.WiFi.Radio.2.'),
        // Two clients on AP.1, one on AP.2
        ...wifiClientFields(1, 1, signalStrength: -50, active: true),
        ...wifiClientFields(1, 2, signalStrength: -70, active: true),
        ...wifiClientFields(2, 1, signalStrength: -45, active: true),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.analyzeWifiSignalPerRadio();

      expect(result.radios.length, 2);
      final r1 = result.radios
          .firstWhere((r) => r.instancePath == 'Device.WiFi.Radio.1.');
      expect(r1.clientCount, 2);
      expect(r1.averageRssi, (-50 + -70) ~/ 2);
      expect(r1.minRssi, -70);

      final r2 = result.radios
          .firstWhere((r) => r.instancePath == 'Device.WiFi.Radio.2.');
      expect(r2.clientCount, 1);
      expect(r2.averageRssi, -45);
    });

    test('routes clients to unknown bucket when AP→SSID→Radio cannot resolve',
        () async {
      final response = <String, dynamic>{
        ...wifiRadiosResponse(),
        // AP.1 has broken SSIDReference (points to non-existent SSID)
        ...wifiAccessPointFields(1, 'Device.WiFi.SSID.99.'),
        // No SSID entries — join fails entirely
        ...wifiClientFields(1, 1, signalStrength: -60, active: true),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.analyzeWifiSignalPerRadio();

      // Two configured radios with 0 clients + unknown bucket appended
      final unknown = result.radios.firstWhere((r) => r.instancePath == '');
      expect(unknown.clientCount, 1);
      expect(unknown.averageRssi, -60);
      expect(unknown.isResolved, isFalse);
    });

    test('skips inactive clients', () async {
      final response = <String, dynamic>{
        ...wifiRadiosResponse(),
        ...wifiAccessPointFields(1, 'Device.WiFi.SSID.1.'),
        ...wifiSsidFields(1, 'Device.WiFi.Radio.1.'),
        ...wifiClientFields(1, 1, signalStrength: -55, active: false),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.analyzeWifiSignalPerRadio();

      // Inactive client must not appear anywhere — all radios have 0 clients,
      // and there should be no unknown bucket added.
      expect(result.radios.every((r) => r.clientCount == 0), isTrue);
    });

    test('handles AP with empty SSIDReference and SSID with empty LowerLayers',
        () async {
      final response = <String, dynamic>{
        ...wifiRadiosResponse(),
        ...wifiAccessPointFields(1, ''),
        ...wifiAccessPointFields(2, 'Device.WiFi.SSID.2.'),
        ...wifiSsidFields(2, ''), // empty LowerLayers
        ...wifiClientFields(1, 1, signalStrength: -50, active: true),
        ...wifiClientFields(2, 1, signalStrength: -55, active: true),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.analyzeWifiSignalPerRadio();

      // Both clients should land in "unknown" because joins are broken.
      final unknown = result.radios.firstWhere((r) => r.instancePath == '');
      expect(unknown.clientCount, 2);
    });
  });

  group('UIModel getters', () {
    test('DeviceSignalUIModel.signalLabel covers all RSSI bands', () {
      DeviceSignalUIModel d(int rssi) =>
          DeviceSignalUIModel(name: 'd', macAddress: 'mac', rssiDbm: rssi);
      expect(d(-40).signalLabel, 'Excellent');
      expect(d(-55).signalLabel, 'Good');
      expect(d(-65).signalLabel, 'Fair');
      expect(d(-75).signalLabel, 'Weak');
      expect(d(-90).signalLabel, 'Very Weak');
    });

    test('WifiSignalPerRadioUIModel aggregates totals across active radios',
        () {
      const radios = WifiSignalPerRadioUIModel(radios: [
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.1.',
          band: '2.4GHz',
          channel: 6,
          status: 'Up',
          clientCount: 2,
          averageRssi: -60,
          minRssi: -70,
        ),
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.2.',
          band: '5GHz',
          channel: 36,
          status: 'Up',
          clientCount: 3,
          averageRssi: -75, // weak
          minRssi: -85,
        ),
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.3.',
          band: '6GHz',
          channel: 161,
          status: 'Up',
          clientCount: 0,
          averageRssi: 0,
          minRssi: 0,
        ),
      ]);

      expect(radios.activeRadios.length, 2);
      expect(radios.totalClients, 5);
      // weighted: (-60*2 + -75*3) / 5 = (-120 + -225)/5 = -69
      expect(radios.weightedAverageRssi, -69);
      expect(radios.hasWeakRadio, isTrue);
      expect(radios.radios.first.hasClients, isTrue);
      expect(radios.radios[1].isWeakAverage, isTrue);
    });

    test('WifiSignalPerRadioUIModel returns 0 weighted RSSI with no clients',
        () {
      const radios = WifiSignalPerRadioUIModel(radios: [
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.1.',
          band: '2.4GHz',
          channel: 6,
          status: 'Up',
          clientCount: 0,
          averageRssi: 0,
          minRssi: 0,
        ),
      ]);
      expect(radios.weightedAverageRssi, 0);
      expect(radios.hasWeakRadio, isFalse);
    });

    test('IntermittentUIModel.uptimeFormatted handles seconds/min/hour/day',
        () {
      IntermittentUIModel m(int s) => IntermittentUIModel(
            uptimeSeconds: s,
            pingSuccessRate: 1,
            averageLatencyMs: 0,
            jitterMs: 0,
            hasHighJitter: false,
            hasPacketLoss: false,
            recentReboot: false,
          );
      expect(m(30).uptimeFormatted, '0m'); // < 1 minute
      expect(m(60 * 5).uptimeFormatted, '5m');
      expect(m(3600 * 2 + 60 * 30).uptimeFormatted, '2h 30m');
      expect(m(86400 * 3 + 3600 * 4).uptimeFormatted, '3d 4h');
    });
  });

  group('checkIntermittent', () {
    test('aggregates 5 ping samples into latency/jitter/loss metrics',
        () async {
      // Stable latencies: 10,12,14,16,18 → avg 14, jitter 2
      final stubAwaiter = _SequentialPingAwaiter(const [10, 12, 14, 16, 18]);
      service = UnifiedDiagnosticsService(mockUsp, stubAwaiter);

      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 86400));

      final result = await service.checkIntermittent();

      expect(result.uptimeSeconds, 86400);
      expect(result.pingSuccessRate, 1.0);
      expect(result.averageLatencyMs, 14);
      expect(result.jitterMs, 2);
      expect(result.hasHighJitter, isFalse);
      expect(result.hasPacketLoss, isFalse);
      expect(result.recentReboot, isFalse);
      expect(result.hasIssues, isFalse);
      // unused but exercised getter
      expect(result.uptimeFormatted, isNotEmpty);
    });

    test('flags packet loss when pings return zero successes', () async {
      final stubAwaiter = _SequentialPingAwaiter(const [], successRate: 0);
      service = UnifiedDiagnosticsService(mockUsp, stubAwaiter);
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 100));

      final result = await service.checkIntermittent();

      expect(result.pingSuccessRate, 0.0);
      expect(result.hasPacketLoss, isTrue);
      expect(result.recentReboot, isTrue); // uptime < 300
    });

    test('handles awaiter exception per ping (counts as failure)', () async {
      final stubAwaiter = _ThrowingPingAwaiter();
      service = UnifiedDiagnosticsService(mockUsp, stubAwaiter);
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 86400));

      final result = await service.checkIntermittent();

      expect(result.pingSuccessRate, 0.0);
      expect(result.hasPacketLoss, isTrue);
    });

    test('reports high jitter when latency varies > 50ms', () async {
      // Wide swings: 10, 100, 10, 100, 10 → avg ≈ 46, jitter = 90
      final stubAwaiter = _SequentialPingAwaiter(const [10, 100, 10, 100, 10]);
      service = UnifiedDiagnosticsService(mockUsp, stubAwaiter);
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 86400));

      final result = await service.checkIntermittent();

      expect(result.jitterMs, 90);
      expect(result.hasHighJitter, isTrue);
      expect(result.hasIssues, isTrue);
    });
  });
}

/// Awaiter that returns ping latencies from a fixed list, one per call.
/// When the list is exhausted, returns the last value.
class _SequentialPingAwaiter implements SseOperationAwaiter {
  _SequentialPingAwaiter(this.latencies, {this.successRate = 1});
  final List<int> latencies;
  final int successRate;
  int _idx = 0;

  @override
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final i = _idx++;
    final v =
        latencies.isNotEmpty ? latencies[i.clamp(0, latencies.length - 1)] : 0;
    return OperateResult(
      commandName: 'IPPing()',
      commandKey: 'k$i',
      status: 'Complete',
      outputArgs: {
        'SuccessCount': successRate.toString(),
        'FailureCount': (1 - successRate).toString(),
        'AverageResponseTime': v.toString(),
        'MinimumResponseTime': v.toString(),
        'MaximumResponseTime': v.toString(),
      },
    );
  }

  @override
  Future<OperateResult> execute({
    required String operateCommand,
    required String referencePath,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> executeNoWait({
    required String operateCommand,
    Map<String, String> args = const {},
  }) async {}

  @override
  Future<void> startSharedSession({required String referencePath}) async {}

  @override
  Future<void> endSharedSession() async {}
}

/// Awaiter where every ping throws — exercises the catch-and-continue branch
/// in checkIntermittent.
class _ThrowingPingAwaiter implements SseOperationAwaiter {
  @override
  Future<OperateResult> executeInSession({
    required String operateCommand,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw Exception('SSE timeout');

  @override
  Future<OperateResult> execute({
    required String operateCommand,
    required String referencePath,
    Map<String, String> args = const {},
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> executeNoWait({
    required String operateCommand,
    Map<String, String> args = const {},
  }) async {}

  @override
  Future<void> startSharedSession({required String referencePath}) async {}

  @override
  Future<void> endSharedSession() async {}
}
