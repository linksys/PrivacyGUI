import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

ConnectedDevice _device({
  String instancePath = 'Device.Hosts.Host.1.',
  String macAddress = 'AA:BB:CC:DD:EE:FF',
  String ipAddress = '192.168.1.100',
  String hostName = 'TestDevice',
  bool isActive = true,
  String interface_ = 'Device.WiFi.SSID.1',
  String addressSource = 'DHCP',
  List<ConnectedDeviceIpv6> ipv6Addresses = const [],
}) =>
    ConnectedDevice(
      instancePath: instancePath,
      macAddress: macAddress,
      ipAddress: ipAddress,
      hostName: hostName,
      isActive: isActive,
      interface_: interface_,
      addressSource: addressSource,
      ipv6Addresses: ipv6Addresses,
    );

void main() {
  late UspDeviceService service;

  setUp(() {
    service = UspDeviceService();
  });

  // buildSystemInfoUIModel — moved to UspSystemInfoDataService
  // buildFirmwareImageUIModels — moved to UspSystemInfoDataService

  // buildDeviceUIModels — moved to UspDevicesDataService
  // buildNodeUIModels — moved to UspDevicesDataService

  // ---------------------------------------------------------------------------
  // buildDhcpClientUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildDhcpClientUIModels', () {
    test('enriches with hostname from connected devices', () {
      final clients = DhcpClients(items: [
        DhcpClient(
          instancePath: 'p.1.',
          chaddr: 'AA:BB:CC:DD:EE:FF',
          active: true,
          ipAddress: '192.168.1.100',
          leaseTimeRemaining: DateTime(2026, 1, 1, 1, 0, 0),
        ),
      ]);
      final devices = ConnectedDevices(items: [
        _device(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          hostName: 'Laptop',
        ),
      ]);

      final result = service.buildDhcpClientUIModels(
        clients: clients,
        connectedDevices: devices,
      );

      expect(result[0].hostName, 'Laptop');
      expect(result[0].mac, 'AA:BB:CC:DD:EE:FF');
    });

    test('missing hostname defaults to empty string', () {
      final clients = DhcpClients(items: [
        DhcpClient(
          instancePath: 'p.1.',
          chaddr: 'AA:BB:CC:DD:EE:FF',
          active: true,
          ipAddress: '192.168.1.100',
          leaseTimeRemaining: DateTime(2026, 1, 1, 1, 0, 0),
        ),
      ]);

      final result = service.buildDhcpClientUIModels(
        clients: clients,
        connectedDevices: ConnectedDevices(items: []),
      );

      expect(result[0].hostName, '');
    });

    test('MAC case normalized for lookup', () {
      final clients = DhcpClients(items: [
        DhcpClient(
          instancePath: 'p.1.',
          chaddr: 'aa:bb:cc:dd:ee:ff',
          active: true,
          ipAddress: '192.168.1.100',
          leaseTimeRemaining: DateTime(2026, 1, 1, 1, 0, 0),
        ),
      ]);
      final devices = ConnectedDevices(items: [
        _device(macAddress: 'AA:BB:CC:DD:EE:FF', hostName: 'Match'),
      ]);

      final result = service.buildDhcpClientUIModels(
        clients: clients,
        connectedDevices: devices,
      );

      expect(result[0].hostName, 'Match');
    });
  });

  // ---------------------------------------------------------------------------
  // buildDhcpReservationUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildDhcpReservationUIModels', () {
    test('maps all fields', () {
      final data = DhcpReservations(items: [
        DhcpReservation(
          instancePath: 'path.1.',
          enable: true,
          chaddr: 'AA:BB:CC:DD:EE:FF',
          yiaddr: '192.168.1.50',
        ),
      ]);

      final result = service.buildDhcpReservationUIModels(data);

      expect(result, hasLength(1));
      expect(result[0].instancePath, 'path.1.');
      expect(result[0].mac, 'AA:BB:CC:DD:EE:FF');
      expect(result[0].ip, '192.168.1.50');
      expect(result[0].enable, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // buildPortForwardingRuleUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildPortForwardingRuleUIModels', () {
    test('maps all fields including nested data', () {
      final data = PortForwarding(items: [
        PortForwardingRule(
          instancePath: 'path.1.',
          description: 'HTTP',
          externalPort: 80,
          externalPortEndRange: 80,
          internalPort: 80,
          internalClient: '192.168.1.100',
          protocol: 'TCP',
          enabled: true,
        ),
      ]);

      final result = service.buildPortForwardingRuleUIModels(data);

      expect(result, hasLength(1));
      expect(result[0].description, 'HTTP');
      expect(result[0].protocol, 'TCP');
      expect(result[0].enabled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // buildPortTriggeringRuleUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildPortTriggeringRuleUIModels', () {
    test('maps parent + nested forward rules', () {
      final data = PortTriggering(items: [
        PortTrigger(
          instancePath: 'path.1.',
          enabled: true,
          description: 'FTP',
          triggerPort: 21,
          triggerPortEndRange: 21,
          triggerProtocol: 'TCP',
          rules: [
            PortTriggerForwardRule(
              instancePath: 'path.1.Rule.1.',
              forwardPort: 1024,
              forwardPortEndRange: 1030,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ]);

      final result = service.buildPortTriggeringRuleUIModels(data);

      expect(result, hasLength(1));
      expect(result[0].description, 'FTP');
      expect(result[0].forwardRules, hasLength(1));
      expect(result[0].forwardRules[0].forwardPort, 1024);
    });

    test('empty forward rules list', () {
      final data = PortTriggering(items: [
        PortTrigger(
          instancePath: 'path.1.',
          enabled: true,
          description: 'Simple',
          triggerPort: 5060,
          triggerPortEndRange: 5060,
          triggerProtocol: 'UDP',
          rules: [],
        ),
      ]);

      final result = service.buildPortTriggeringRuleUIModels(data);
      expect(result[0].forwardRules, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // buildLanInfoUIModel
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildLanInfoUIModel', () {
    test('maps all fields with optional IPv6', () {
      final info = LanNetworkInfo(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        dhcpEnabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
        leaseTime: 86400,
        dnsServers: '8.8.8.8',
        hostName: 'Router',
        ipv6Enabled: true,
      );

      final result = service.buildLanInfoUIModel(
        info,
        ipv6Addresses: ['2001:db8::1'],
      );

      expect(result.hostName, 'Router');
      expect(result.ipAddress, '192.168.1.1');
      expect(result.dhcpEnabled, isTrue);
      expect(result.leaseTimeMinutes, 1440); // 86400s / 60
      expect(result.ipv6Enabled, isTrue);
      expect(result.ipv6Addresses, ['2001:db8::1']);
    });

    test('IPv6 defaults to false/empty', () {
      final info = LanNetworkInfo(
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        dhcpEnabled: false,
        minAddress: '',
        maxAddress: '',
        leaseTime: 0,
        dnsServers: '',
        hostName: '',
        ipv6Enabled: false,
      );

      final result = service.buildLanInfoUIModel(info);

      expect(result.ipv6Enabled, isFalse);
      expect(result.ipv6Addresses, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // buildWanStatusUIModel
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildWanStatusUIModel', () {
    test('maps fields and derives isUp from status', () {
      final status = WanStatus(
        status: 'Up',
        ipAddress: '203.0.113.1',
        subnetMask: '255.255.255.0',
        addressingType: 'DHCP',
        maxMtuSize: 1500,
        ipv6Enabled: false,
      );

      final result = service.buildWanStatusUIModel(
        wanStatus: status,
        gateway: '203.0.113.254',
      );

      expect(result.isUp, isTrue);
      expect(result.ipAddress, '203.0.113.1');
      expect(result.mtu, 1500);
      expect(result.gateway, '203.0.113.254');
    });

    test('status "down" → isUp false (case insensitive)', () {
      final status = WanStatus(
        status: 'Down',
        ipAddress: '',
        subnetMask: '',
        addressingType: '',
        maxMtuSize: 0,
        ipv6Enabled: false,
      );

      final result = service.buildWanStatusUIModel(
        wanStatus: status,
        gateway: '',
      );

      expect(result.isUp, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // buildEthernetPortUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildEthernetPortUIModels', () {
    test('classifies by bridge membership not upstream flag', () {
      final interfaces = EthernetInterfaces(items: [
        EthernetInterface(
          instancePath: 'Device.Ethernet.Interface.1.',
          name: 'eth1',
          status: 'Up',
          upstream: true, // misleading — actually LAN
          currentBitRate: 1000,
        ),
        EthernetInterface(
          instancePath: 'Device.Ethernet.Interface.2.',
          name: 'eth0',
          status: 'Up',
          upstream: false, // misleading — actually WAN
          currentBitRate: 1000,
        ),
      ]);

      // Bridge port map: eth1 is a bridge member → LAN
      final bridgePortMap = {
        'Device.Bridging.Bridge.1.Port.1.': 'Device.Ethernet.Interface.1',
      };

      final result = service.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: [],
        bridgePortMap: bridgePortMap,
      );

      // eth1 is bridge member → LAN (no wired devices, single LAN entry)
      // eth0 is NOT bridge member → WAN port
      expect(result, hasLength(2));
      expect(result[0].isWan, isTrue);
      expect(result[0].label, 'WAN');
      expect(result[1].isWan, isFalse);
      expect(result[1].label, 'LAN');
      expect(result[1].connectedDevices, isEmpty);
    });

    test('creates LAN port per active wired device', () {
      final interfaces = EthernetInterfaces(items: [
        EthernetInterface(
          instancePath: 'Device.Ethernet.Interface.1.',
          name: 'eth1',
          status: 'Up',
          upstream: false,
          currentBitRate: 1000,
        ),
      ]);
      final bridgePortMap = {
        'port.1.': 'Device.Ethernet.Interface.1',
      };
      final devices = [
        DeviceUIModel(
          mac: 'AA:BB:CC:DD:EE:01',
          ip: '192.168.1.10',
          hostName: 'PC1',
          isActive: true,
          isWifi: false,
        ),
        DeviceUIModel(
          mac: 'AA:BB:CC:DD:EE:02',
          ip: '192.168.1.11',
          hostName: 'PC2',
          isActive: true,
          isWifi: false,
        ),
      ];

      final result = service.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: devices,
        bridgePortMap: bridgePortMap,
      );

      expect(result, hasLength(2));
      expect(result[0].label, 'LAN 1');
      expect(result[1].label, 'LAN 2');
      expect(result[0].connectedDevices[0].hostName, 'PC1');
    });

    test('WiFi and inactive devices excluded from wired count', () {
      final interfaces = EthernetInterfaces(items: [
        EthernetInterface(
          instancePath: 'Device.Ethernet.Interface.1.',
          name: 'eth1',
          status: 'Up',
          upstream: false,
          currentBitRate: 1000,
        ),
      ]);
      final bridgePortMap = {'port.1.': 'Device.Ethernet.Interface.1'};
      final devices = [
        DeviceUIModel(
          mac: 'AA:BB:CC:DD:EE:01',
          ip: '192.168.1.10',
          hostName: 'WiFi',
          isActive: true,
          isWifi: true, // excluded — WiFi
        ),
        DeviceUIModel(
          mac: 'AA:BB:CC:DD:EE:02',
          ip: '192.168.1.11',
          hostName: 'Inactive',
          isActive: false, // excluded — inactive
          isWifi: false,
        ),
      ];

      final result = service.buildEthernetPortUIModels(
        ethernetInterfaces: interfaces,
        deviceModels: devices,
        bridgePortMap: bridgePortMap,
      );

      // Single LAN port with no connected devices (WiFi/inactive excluded)
      expect(result, hasLength(1));
      expect(result[0].isWan, isFalse);
      expect(result[0].label, 'LAN');
      expect(result[0].connectedDevices, isEmpty);
    });
  });

  // buildNodeUIModels — moved to UspDevicesDataService
  // buildDeviceUIModels — moved to UspDevicesDataService
  // buildWifiRadioUIModels — moved to UspWifiDataService
}
