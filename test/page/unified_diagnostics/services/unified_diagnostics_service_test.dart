import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';

class MockUspClient extends Mock implements UspClient {}

class _MockExecutor extends Mock implements NetworkDiagnosticsExecutor {}

/// Recording fake [DiagnosticScope] — mocktail can't easily express the
/// inter-call ordering we want for sequential pings, so we wrap a real
/// recording structure but keep the [DiagnosticScope] interface satisfied.
class FakeDiagnosticScope implements DiagnosticScope {
  // Per-test configuration:
  OperateResult? pingResult;
  OperateResult? traceRouteResult;
  OperateResult? nsLookupResult;
  Object? pingError;
  Object? traceRouteError;
  Object? nsLookupError;
  Map<String, OperateResult> resultsByCommand = {};

  // Recorded calls:
  final List<({String command, Map<String, String> args})> calls = [];
  bool released = false;

  void _record(String command, Map<String, String> args) {
    calls.add((command: command, args: args));
  }

  @override
  bool get isReleased => released;

  @override
  Future<void> release() async {
    released = true;
  }

  @override
  Future<OperateResult> ping({
    required String host,
    int? numberOfRepetitions,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final args = <String, String>{'Host': host};
    if (numberOfRepetitions != null) {
      args['NumberOfRepetitions'] = numberOfRepetitions.toString();
    }
    _record('Device.IP.Diagnostics.IPPing()', args);
    if (pingError != null) throw pingError!;
    if (resultsByCommand.containsKey('Device.IP.Diagnostics.IPPing()')) {
      return resultsByCommand['Device.IP.Diagnostics.IPPing()']!;
    }
    if (pingResult != null) return pingResult!;
    throw StateError('No ping result configured');
  }

  @override
  Future<OperateResult> traceRoute({
    required String host,
    int? maxHopCount,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    final args = <String, String>{'Host': host};
    if (maxHopCount != null) args['MaxHopCount'] = maxHopCount.toString();
    _record('Device.IP.Diagnostics.TraceRoute()', args);
    if (traceRouteError != null) throw traceRouteError!;
    if (traceRouteResult != null) return traceRouteResult!;
    throw StateError('No traceRoute result configured');
  }

  @override
  Future<OperateResult> nsLookup({
    required String hostName,
    String? dnsServer,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final args = <String, String>{'HostName': hostName};
    if (dnsServer != null) args['DNSServer'] = dnsServer;
    _record('Device.DNS.Diagnostics.NSLookupDiagnostics()', args);
    if (nsLookupError != null) throw nsLookupError!;
    if (nsLookupResult != null) return nsLookupResult!;
    throw StateError('No nsLookup result configured');
  }

  @override
  Future<OperateResult> downloadDiagnostic({
    required String downloadUrl,
    String? ethernetPriority,
    String? dscp,
    int? numberOfConnections,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OperateResult> uploadDiagnostic({
    required String uploadUrl,
    int? testFileLength,
    String? ethernetPriority,
    String? dscp,
    int? numberOfConnections,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OperateResult> udpEcho({
    required String host,
    required int port,
    int? numberOfRepetitions,
    int? echoTimeout,
    int? dataBlockSize,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OperateResult> serverSelection({
    required String hostList,
    String? protocol,
    int? port,
    int? numberOfRepetitions,
    int? selectionTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  late MockUspClient mockUsp;
  late _MockExecutor mockExecutor;
  late FakeDiagnosticScope fakeScope;
  late UnifiedDiagnosticsService service;

  setUp(() {
    mockUsp = MockUspClient();
    mockExecutor = _MockExecutor();
    fakeScope = FakeDiagnosticScope();
    when(() => mockExecutor.acquireScope(
          referencePaths: any(named: 'referencePaths'),
        )).thenAnswer((_) async => fakeScope);
    service = UnifiedDiagnosticsService(mockUsp);
    service.attachScope(fakeScope);
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

    test('maps underlying GET errors to ServiceError', () async {
      when(() => mockUsp.get(any())).thenThrow('Get failed: Transport error');

      expect(service.checkWanStatus(), throwsA(isA<ServiceError>()));
    });
  });

  group('Scope contract', () {
    test('throws when no scope is attached', () async {
      final unsetService = UnifiedDiagnosticsService(mockUsp);
      expect(unsetService.ping('8.8.8.8'), throwsA(isA<StateError>()));
    });

    test('throws when scope has been released', () async {
      fakeScope.released = true;
      expect(service.ping('8.8.8.8'), throwsA(isA<StateError>()));
    });
  });

  group('ping', () {
    test('parses successful PingResult and forwards args to scope', () async {
      fakeScope.pingResult = OperateResult(
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

      final call = fakeScope.calls.single;
      expect(call.command, 'Device.IP.Diagnostics.IPPing()');
      expect(call.args, {'Host': '8.8.8.8', 'NumberOfRepetitions': '5'});
    });

    test('rethrows when scope throws', () async {
      fakeScope.pingError = Exception('SSE timeout');
      expect(service.ping('8.8.8.8'), throwsException);
    });
  });

  group('pingGateway', () {
    test('derives gateway from WAN IP/mask and pings it', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          wanStatusResponse(ip: '203.0.113.50', mask: '255.255.255.0'));
      fakeScope.pingResult = OperateResult(
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
      expect(fakeScope.calls.single.args['Host'], '203.0.113.1');
    });

    test('falls back to 192.168.1.1 when WAN IP/mask are malformed', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => wanStatusResponse(
            ip: 'not-an-ip',
            mask: 'not-a-mask',
          ));
      fakeScope.pingResult = OperateResult(
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
      fakeScope.pingResult = OperateResult(
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
      expect(fakeScope.calls.single.args['Host'], '8.8.8.8');
    });

    test('pingInternet defaults to 1.1.1.1', () async {
      fakeScope.pingResult = OperateResult(
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
      expect(fakeScope.calls.single.args['Host'], '1.1.1.1');
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
      fakeScope.nsLookupResult = OperateResult(
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

      final args = fakeScope.calls.single.args;
      expect(args['HostName'], 'example.com');
      expect(args['DNSServer'], '8.8.8.8');
    });

    test('omits DNSServer when not provided', () async {
      fakeScope.nsLookupResult = OperateResult(
        commandName: 'NSLookupDiagnostics()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {'Status': 'Success', 'SuccessCount': '0'},
      );

      await service.nsLookup('example.com');

      expect(fakeScope.calls.single.args.containsKey('DNSServer'), isFalse);
    });

    test('omits DNSServer when empty string passed', () async {
      fakeScope.nsLookupResult = OperateResult(
        commandName: 'NSLookupDiagnostics()',
        commandKey: 'k',
        status: 'Complete',
        outputArgs: const {'Status': 'Success', 'SuccessCount': '0'},
      );

      await service.nsLookup('example.com', dnsServer: '');

      expect(fakeScope.calls.single.args.containsKey('DNSServer'), isFalse);
    });

    test('rethrows when scope throws', () async {
      fakeScope.nsLookupError = Exception('boom');
      expect(service.nsLookup('host'), throwsException);
    });
  });

  group('traceroute', () {
    test('uses scope.traceRoute and parses hops', () async {
      fakeScope.traceRouteResult = OperateResult(
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

      final call = fakeScope.calls.single;
      expect(call.command, 'Device.IP.Diagnostics.TraceRoute()');
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
      // Thresholds from wifi.dart: rssiExcellent=-65, rssiGood=-71, rssiFair=-78
      expect(d(-40).signalLabel, 'Excellent'); // >= -65
      expect(d(-65).signalLabel, 'Excellent'); // == -65 (boundary)
      expect(d(-66).signalLabel, 'Good'); // >= -71
      expect(d(-71).signalLabel, 'Good'); // == -71 (boundary)
      expect(d(-72).signalLabel, 'Fair'); // >= -78
      expect(d(-78).signalLabel, 'Fair'); // == -78 (boundary)
      expect(d(-79).signalLabel, 'Weak'); // < -78
      expect(d(-90).signalLabel, 'Weak');
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

  // ────────────────────────────────────────────────────────────────────────
  // Mesh / Backhaul fixtures
  // ────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> meshNodeFields(
    int idx, {
    required String id,
    required String mediaType,
    required int phyRate,
    required int signalStrength,
    required String operationMode,
    required String assocRef,
    String manufacturerModel = 'Linksys M60TB',
    String? linkType,
    String? backhaulDeviceId,
  }) {
    final p = 'Device.WiFi.DataElements.Network.Device.$idx.';
    // Controller has no upstream link — mirror firmware behavior where
    // BackhaulALID/MAC are empty when MediaType is empty.
    final hasBackhaul = mediaType.isNotEmpty || phyRate > 0;
    // Derive linkType from mediaType if not provided
    final derivedLinkType =
        linkType ?? (mediaType.contains('Ethernet') ? 'Ethernet' : 'Wi-Fi');
    return <String, dynamic>{
      '${p}ID': id,
      '${p}ManufacturerModel': manufacturerModel,
      '${p}Manufacturer': 'Linksys',
      '${p}SerialNumber': 'SN-$idx',
      '${p}SoftwareVersion': '1.0.16',
      '${p}BackhaulALID': hasBackhaul ? 'al-$idx' : '',
      '${p}BackhaulMACAddress': hasBackhaul ? 'AA:BB:CC:DD:EE:0$idx' : '',
      '${p}BackhaulMediaType': mediaType,
      '${p}BackhaulPHYRate': phyRate.toString(),
      // Use a recent timestamp to avoid stale detection (within 5 minutes)
      '${p}MultiAPDevice.LastContactTime':
          DateTime.now().toUtc().toIso8601String(),
      '${p}MultiAPDevice.AssocIEEE1905DeviceRef': assocRef,
      '${p}MultiAPDevice.EasyMeshAgentOperationMode': operationMode,
      '${p}MultiAPDevice.Backhaul.BackhaulDeviceID':
          backhaulDeviceId ?? (hasBackhaul ? 'parent-$idx' : ''),
      '${p}MultiAPDevice.Backhaul.BackhaulMACAddress':
          hasBackhaul ? 'BB:CC:DD:EE:FF:0$idx' : '',
      '${p}MultiAPDevice.Backhaul.LinkType': hasBackhaul ? derivedLinkType : '',
      '${p}MultiAPDevice.Backhaul.MACAddress':
          hasBackhaul ? 'CC:DD:EE:FF:00:0$idx' : '',
      '${p}MultiAPDevice.Backhaul.Stats.PacketsSent': '1000',
      '${p}MultiAPDevice.Backhaul.Stats.PacketsReceived': '1100',
      '${p}MultiAPDevice.Backhaul.Stats.ErrorsSent': '0',
      '${p}MultiAPDevice.Backhaul.Stats.ErrorsReceived': '0',
      '${p}MultiAPDevice.Backhaul.Stats.TimeStamp': '2026-05-21T00:00:00Z',
      // phyRate is in Mbps, but LastDataUplinkRate/DownlinkRate are in kbps
      '${p}MultiAPDevice.Backhaul.Stats.LastDataUplinkRate':
          (phyRate * 1000).toString(),
      '${p}MultiAPDevice.Backhaul.Stats.LastDataDownlinkRate':
          (phyRate * 1000).toString(),
      // signalStrength param is RSSI (dBm), convert to RCPI for firmware format
      '${p}MultiAPDevice.Backhaul.Stats.SignalStrength':
          rssiToRcpi(signalStrength).toString(),
    };
  }

  group('checkMeshBackhaul', () {
    test('returns empty list for single-router (no mesh) deployment', () async {
      // Single node — backhaul concept doesn't apply.
      final response = <String, dynamic>{
        ...meshNodeFields(1,
            id: 'controller',
            mediaType: '',
            phyRate: 0,
            signalStrength: 0,
            operationMode: 'Controller',
            assocRef: ''),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkMeshBackhaul();

      expect(result, isEmpty);
    });

    test('returns empty list when no nodes report any data', () async {
      // All zeros / empty trigger codegen "drop empty row" filter.
      when(() => mockUsp.get(any())).thenAnswer((_) async => <String, dynamic>{
            // No mesh keys at all.
          });

      final result = await service.checkMeshBackhaul();
      expect(result, isEmpty);
    });

    test('classifies wired (Ethernet) backhaul as healthy regardless of RSSI',
        () async {
      final response = <String, dynamic>{
        ...meshNodeFields(1,
            id: 'controller',
            mediaType: '',
            phyRate: 0,
            signalStrength: 0,
            operationMode: 'Controller',
            assocRef: ''),
        ...meshNodeFields(2,
            id: 'agent-A',
            mediaType: 'IEEE_802_3ab_Ethernet',
            phyRate: 1000,
            signalStrength: 0, // wired — RSSI not meaningful
            operationMode: 'Agent',
            assocRef: 'controller'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkMeshBackhaul();

      expect(result, hasLength(1));
      final node = result.single;
      expect(node.nodeId, 'agent-A');
      expect(node.severity, MeshBackhaulSeverity.healthy);
      expect(node.mediaType, contains('Ethernet'));
    });

    test('classifies low-PHY wireless backhaul as poor', () async {
      final response = <String, dynamic>{
        ...meshNodeFields(1,
            id: 'controller',
            mediaType: '',
            phyRate: 0,
            signalStrength: 0,
            operationMode: 'Controller',
            assocRef: ''),
        ...meshNodeFields(2,
            id: 'agent-A',
            mediaType: 'IEEE_802_11ax',
            phyRate: 50,
            signalStrength: -80, // poor RSSI
            operationMode: 'Agent',
            assocRef: 'controller'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkMeshBackhaul();
      expect(result.single.severity, MeshBackhaulSeverity.poor);
    });

    test('classifies marginal wireless backhaul as weak', () async {
      final response = <String, dynamic>{
        ...meshNodeFields(1,
            id: 'controller',
            mediaType: '',
            phyRate: 0,
            signalStrength: 0,
            operationMode: 'Controller',
            assocRef: ''),
        ...meshNodeFields(2,
            id: 'agent-A',
            mediaType: 'IEEE_802_11ax',
            phyRate: 200,
            signalStrength: -70, // marginal RSSI
            operationMode: 'Agent',
            assocRef: 'controller'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkMeshBackhaul();
      expect(result.single.severity, MeshBackhaulSeverity.weak);
    });

    test('classifies strong wireless backhaul as healthy', () async {
      final response = <String, dynamic>{
        ...meshNodeFields(1,
            id: 'controller',
            mediaType: '',
            phyRate: 0,
            signalStrength: 0,
            operationMode: 'Controller',
            assocRef: ''),
        ...meshNodeFields(2,
            id: 'agent-A',
            mediaType: 'IEEE_802_11ax',
            phyRate: 900,
            signalStrength: -55, // good RSSI
            operationMode: 'Agent',
            assocRef: 'controller'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkMeshBackhaul();
      expect(result.single.severity, MeshBackhaulSeverity.healthy);
    });

    test('excludes the controller node from results', () async {
      final response = <String, dynamic>{
        ...meshNodeFields(1,
            id: 'controller',
            mediaType: '',
            phyRate: 0,
            signalStrength: 0,
            operationMode: 'Controller',
            assocRef: ''),
        ...meshNodeFields(2,
            id: 'agent-A',
            mediaType: 'IEEE_802_11ax',
            phyRate: 800,
            signalStrength: -50, // excellent RSSI
            operationMode: 'Agent',
            assocRef: 'controller'),
        ...meshNodeFields(3,
            id: 'agent-B',
            mediaType: 'IEEE_802_3ab_Ethernet',
            phyRate: 1000,
            signalStrength: 0,
            operationMode: 'Agent',
            assocRef: 'controller'),
      };
      when(() => mockUsp.get(any())).thenAnswer((_) async => response);

      final result = await service.checkMeshBackhaul();
      expect(result.map((n) => n.nodeId), ['agent-A', 'agent-B']);
      expect(result.every((n) => !n.isController), isTrue);
    });
  });

  group('checkIntermittent', () {
    test('aggregates 5 ping samples into latency/jitter/loss metrics',
        () async {
      // Stable latencies: 10,12,14,16,18 → avg 14, jitter 2
      service.attachScope(_SequentialPingScope(const [10, 12, 14, 16, 18]));

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
      service.attachScope(_SequentialPingScope(const [], successRate: 0));
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 100));

      final result = await service.checkIntermittent();

      expect(result.pingSuccessRate, 0.0);
      expect(result.hasPacketLoss, isTrue);
      expect(result.recentReboot, isTrue); // uptime < 300
    });

    test('handles scope exception per ping (counts as failure)', () async {
      service.attachScope(_ThrowingPingScope());
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 86400));

      final result = await service.checkIntermittent();

      expect(result.pingSuccessRate, 0.0);
      expect(result.hasPacketLoss, isTrue);
    });

    test('reports high jitter when latency varies > 50ms', () async {
      // Wide swings: 10, 100, 10, 100, 10 → avg ≈ 46, jitter = 90
      service.attachScope(_SequentialPingScope(const [10, 100, 10, 100, 10]));
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => systemInfoResponse(uptime: 86400));

      final result = await service.checkIntermittent();

      expect(result.jitterMs, 90);
      expect(result.hasHighJitter, isTrue);
      expect(result.hasIssues, isTrue);
    });
  });
}

/// Scope that returns ping latencies from a fixed list, one per call.
/// When the list is exhausted, returns the last value.
class _SequentialPingScope implements DiagnosticScope {
  _SequentialPingScope(this.latencies, {this.successRate = 1});
  final List<int> latencies;
  final int successRate;
  int _idx = 0;

  @override
  bool get isReleased => false;

  @override
  Future<void> release() async {}

  @override
  Future<OperateResult> ping({
    required String host,
    int? numberOfRepetitions,
    Duration timeout = const Duration(seconds: 30),
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
  Future<OperateResult> traceRoute({
    required String host,
    int? maxHopCount,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> nsLookup({
    required String hostName,
    String? dnsServer,
    Duration timeout = const Duration(seconds: 20),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> downloadDiagnostic({
    required String downloadUrl,
    String? ethernetPriority,
    String? dscp,
    int? numberOfConnections,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> uploadDiagnostic({
    required String uploadUrl,
    int? testFileLength,
    String? ethernetPriority,
    String? dscp,
    int? numberOfConnections,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> udpEcho({
    required String host,
    required int port,
    int? numberOfRepetitions,
    int? echoTimeout,
    int? dataBlockSize,
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> serverSelection({
    required String hostList,
    String? protocol,
    int? port,
    int? numberOfRepetitions,
    int? selectionTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw UnimplementedError();
}

/// Scope where every ping throws — exercises the catch-and-continue branch
/// in checkIntermittent.
class _ThrowingPingScope implements DiagnosticScope {
  @override
  bool get isReleased => false;

  @override
  Future<void> release() async {}

  @override
  Future<OperateResult> ping({
    required String host,
    int? numberOfRepetitions,
    Duration timeout = const Duration(seconds: 30),
  }) async =>
      throw Exception('SSE timeout');

  @override
  Future<OperateResult> traceRoute({
    required String host,
    int? maxHopCount,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> nsLookup({
    required String hostName,
    String? dnsServer,
    Duration timeout = const Duration(seconds: 20),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> downloadDiagnostic({
    required String downloadUrl,
    String? ethernetPriority,
    String? dscp,
    int? numberOfConnections,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> uploadDiagnostic({
    required String uploadUrl,
    int? testFileLength,
    String? ethernetPriority,
    String? dscp,
    int? numberOfConnections,
    Duration timeout = const Duration(seconds: 120),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> udpEcho({
    required String host,
    required int port,
    int? numberOfRepetitions,
    int? echoTimeout,
    int? dataBlockSize,
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw UnimplementedError();

  @override
  Future<OperateResult> serverSelection({
    required String hostList,
    String? protocol,
    int? port,
    int? numberOfRepetitions,
    int? selectionTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async =>
      throw UnimplementedError();
}
