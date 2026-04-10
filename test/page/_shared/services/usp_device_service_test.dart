import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

SystemInfo _sysInfo({
  String manufacturer = 'Linksys',
  String modelName = 'M60TB',
  String serialNumber = 'SN123',
  String hardwareVersion = '1.0',
  String softwareVersion = '2.0.0',
  int uptime = 3600,
  int totalMemory = 512000,
  int freeMemory = 256000,
  int cpuUsage = 25,
  String activeFirmwareImage = '',
  String bootFirmwareImage = '',
}) =>
    SystemInfo(
      manufacturer: manufacturer,
      modelName: modelName,
      serialNumber: serialNumber,
      hardwareVersion: hardwareVersion,
      softwareVersion: softwareVersion,
      uptime: uptime,
      totalMemory: totalMemory,
      freeMemory: freeMemory,
      cpuUsage: cpuUsage,
      activeFirmwareImage: activeFirmwareImage,
      bootFirmwareImage: bootFirmwareImage,
    );

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

  // ---------------------------------------------------------------------------
  // buildSystemInfoUIModel
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildSystemInfoUIModel', () {
    test('maps all fields correctly', () {
      final info = _sysInfo();
      final result = service.buildSystemInfoUIModel(info);

      expect(result.manufacturer, 'Linksys');
      expect(result.modelName, 'M60TB');
      expect(result.serialNumber, 'SN123');
      expect(result.hardwareVersion, '1.0');
      expect(result.softwareVersion, '2.0.0');
      expect(result.uptime, 3600);
      expect(result.totalMemory, 512000);
      expect(result.freeMemory, 256000);
      expect(result.cpuUsage, 25);
      expect(result.firmwareImages, isEmpty);
    });

    test('includes firmware images when provided', () {
      final images = [
        FirmwareImageUIModel(
          instancePath: 'p.1.',
          name: 'fw1',
          version: '1.0',
          status: 'active',
          available: true,
        ),
      ];
      final result =
          service.buildSystemInfoUIModel(_sysInfo(), firmwareImages: images);
      expect(result.firmwareImages, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // buildFirmwareImageUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildFirmwareImageUIModels', () {
    test('identifies active and boot target images', () {
      final data = FirmwareImages(items: [
        FirmwareImage(
          instancePath: 'Device.FW.1.',
          name: 'fw1',
          version: '1.0',
          status: 'active',
          available: true,
        ),
        FirmwareImage(
          instancePath: 'Device.FW.2.',
          name: 'fw2',
          version: '2.0',
          status: 'inactive',
          available: true,
        ),
      ]);

      final result = service.buildFirmwareImageUIModels(
        data: data,
        activeRef: 'Device.FW.1.',
        bootRef: 'Device.FW.2.',
      );

      expect(result[0].isActive, isTrue);
      expect(result[0].isBootTarget, isFalse);
      expect(result[1].isActive, isFalse);
      expect(result[1].isBootTarget, isTrue);
    });

    test('strips trailing dot for comparison', () {
      final data = FirmwareImages(items: [
        FirmwareImage(
          instancePath: 'Device.FW.1.',
          name: 'fw1',
          version: '1.0',
          status: 'active',
          available: true,
        ),
      ]);

      // activeRef without trailing dot should still match
      final result = service.buildFirmwareImageUIModels(
        data: data,
        activeRef: 'Device.FW.1',
        bootRef: '',
      );

      expect(result[0].isActive, isTrue);
      expect(result[0].isBootTarget, isFalse);
    });

    test('empty refs mark nothing as active/boot', () {
      final data = FirmwareImages(items: [
        FirmwareImage(
          instancePath: 'Device.FW.1.',
          name: 'fw1',
          version: '1.0',
          status: 'inactive',
          available: true,
        ),
      ]);

      final result = service.buildFirmwareImageUIModels(
        data: data,
        activeRef: '',
        bootRef: '',
      );

      expect(result[0].isActive, isFalse);
      expect(result[0].isBootTarget, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // buildDeviceUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildDeviceUIModels', () {
    final emptyMesh = MeshTopologyInfo(nodes: [], clientToNodeMap: {});

    test('filters out devices with empty interface', () {
      final devices = ConnectedDevices(items: [
        _device(interface_: 'Device.WiFi.SSID.1'),
        _device(
          instancePath: 'p.2.',
          macAddress: 'BB:CC:DD:EE:FF:00',
          interface_: '',
        ),
      ]);

      final result = service.buildDeviceUIModels(
        connectedDevices: devices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: emptyMesh,
        gatewayName: 'Router',
      );

      expect(result, hasLength(1));
    });

    test('detects WiFi devices by interface containing wifi', () {
      final devices = ConnectedDevices(items: [
        _device(interface_: 'Device.WiFi.SSID.1'),
        _device(
          instancePath: 'p.2.',
          macAddress: 'BB:CC:DD:EE:FF:00',
          interface_: 'Device.Ethernet.Interface.1',
        ),
      ]);

      final result = service.buildDeviceUIModels(
        connectedDevices: devices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: emptyMesh,
        gatewayName: 'Router',
      );

      expect(result[0].isWifi, isTrue);
      expect(result[1].isWifi, isFalse);
    });

    test('enriches WiFi devices with signal data', () {
      final devices = ConnectedDevices(items: [
        _device(macAddress: 'aa:bb:cc:dd:ee:ff'),
      ]);
      final wifiMap = {
        'AA:BB:CC:DD:EE:FF': WifiClientUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          signalStrength: -50,
          noise: -90,
          lastDataDownlinkRate: 100,
          lastDataUplinkRate: 50,
          active: true,
        ),
      };

      final result = service.buildDeviceUIModels(
        connectedDevices: devices,
        wifiClientMap: wifiMap,
        connectionDetailMap: {},
        meshTopology: emptyMesh,
        gatewayName: 'Router',
      );

      expect(result[0].signalStrength, -50);
      expect(result[0].downlinkRate, 100);
    });

    test('non-mesh active device gets gateway name as parent', () {
      final devices = ConnectedDevices(items: [_device()]);

      final result = service.buildDeviceUIModels(
        connectedDevices: devices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: emptyMesh,
        gatewayName: 'MyRouter',
      );

      expect(result[0].parentNodeName, 'MyRouter');
      expect(result[0].parentNodeId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // buildTimeSettingsUIModel
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildTimeSettingsUIModel', () {
    test('maps all fields', () {
      final settings = TimeSettings(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-03-23T12:00:00',
        localTimeZone: 'Asia/Taipei',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: 'time.google.com',
      );

      final result = service.buildTimeSettingsUIModel(settings);

      expect(result.enable, isTrue);
      expect(result.status, 'Synchronized');
      expect(result.localTimeZone, 'Asia/Taipei');
      expect(result.ntpServer1, 'pool.ntp.org');
    });
  });

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

  // ---------------------------------------------------------------------------
  // buildNodeUIModels
  // ---------------------------------------------------------------------------

  group('UspDeviceService — buildNodeUIModels', () {
    test('empty mesh creates synthetic gateway node', () {
      final emptyMesh = MeshTopologyInfo(nodes: [], clientToNodeMap: {});
      final sysInfo = SystemInfoUIModel(
        manufacturer: 'Linksys',
        modelName: 'M60TB',
        serialNumber: 'SN123',
        hardwareVersion: '1.0',
        softwareVersion: '2.0.0',
        uptime: 3600,
        totalMemory: 512000,
        freeMemory: 256000,
        cpuUsage: 25,
      );

      final result = service.buildNodeUIModels(
        meshTopology: emptyMesh,
        deviceModels: [
          DeviceUIModel(
            mac: 'AA:BB:CC:DD:EE:01',
            ip: '192.168.1.10',
            hostName: 'PC',
            isActive: true,
            isWifi: false,
          ),
        ],
        systemInfo: sysInfo,
      );

      expect(result, hasLength(1));
      expect(result[0].deviceId, 'gateway');
      expect(result[0].isMaster, isTrue);
      expect(result[0].model, 'M60TB');
      expect(result[0].connectedDeviceCount, 1);
    });

    test('mesh network: first node is master', () {
      final mesh = MeshTopologyInfo(
        nodes: [
          MeshNodeInfo(
            instancePath: 'p.1.',
            deviceId: 'node-1',
            model: 'M60',
          ),
          MeshNodeInfo(
            instancePath: 'p.2.',
            deviceId: 'node-2',
            model: 'M60',
          ),
        ],
        clientToNodeMap: {},
      );

      final result = service.buildNodeUIModels(
        meshTopology: mesh,
        deviceModels: [],
        systemInfo: SystemInfoUIModel(
          manufacturer: '',
          modelName: '',
          serialNumber: '',
          hardwareVersion: '',
          softwareVersion: '',
          uptime: 0,
          totalMemory: 0,
          freeMemory: 0,
          cpuUsage: 0,
        ),
      );

      expect(result[0].isMaster, isTrue);
      expect(result[1].isMaster, isFalse);
    });

    test('counts connected devices per node (case insensitive)', () {
      final mesh = MeshTopologyInfo(
        nodes: [
          MeshNodeInfo(
            instancePath: 'p.1.',
            deviceId: 'NODE-A',
            model: 'M60',
          ),
        ],
        clientToNodeMap: {},
      );

      final devices = [
        DeviceUIModel(
          mac: 'AA:BB:CC:DD:EE:01',
          ip: '192.168.1.10',
          hostName: 'PC1',
          isActive: true,
          isWifi: false,
          parentNodeId: 'node-a', // lowercase
        ),
        DeviceUIModel(
          mac: 'AA:BB:CC:DD:EE:02',
          ip: '192.168.1.11',
          hostName: 'PC2',
          isActive: false, // inactive — not counted
          isWifi: false,
          parentNodeId: 'node-a',
        ),
      ];

      final result = service.buildNodeUIModels(
        meshTopology: mesh,
        deviceModels: devices,
        systemInfo: SystemInfoUIModel(
          manufacturer: '',
          modelName: '',
          serialNumber: '',
          hardwareVersion: '',
          softwareVersion: '',
          uptime: 0,
          totalMemory: 0,
          freeMemory: 0,
          cpuUsage: 0,
        ),
      );

      expect(result[0].connectedDeviceCount, 1);
    });
  });

  // buildWifiRadioUIModels — moved to UspWifiDataService.
  // Tests: test/page/wifi_settings/services/usp_wifi_data_service_test.dart
}
