import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

const _systemInfo = SystemInfo(
  manufacturer: 'Linksys',
  modelName: 'M60TB',
  serialNumber: 'SN12345',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.16',
  uptime: 86400,
  totalMemory: 524288,
  freeMemory: 262144,
  cpuUsage: 35,
  activeFirmwareImage: 'Device.DeviceInfo.FirmwareImage.1.',
  bootFirmwareImage: 'Device.DeviceInfo.FirmwareImage.1.',
);

void main() {
  late UspDeviceService svc;

  setUp(() {
    svc = UspDeviceService();
  });

  // -----------------------------------------------------------------------
  // buildSystemInfoUIModel
  // -----------------------------------------------------------------------
  group('buildSystemInfoUIModel', () {
    test('maps all fields correctly', () {
      final model = svc.buildSystemInfoUIModel(_systemInfo);

      expect(model.manufacturer, 'Linksys');
      expect(model.modelName, 'M60TB');
      expect(model.serialNumber, 'SN12345');
      expect(model.hardwareVersion, '1.0');
      expect(model.softwareVersion, '1.0.16');
      expect(model.uptime, 86400);
      expect(model.totalMemory, 524288);
      expect(model.freeMemory, 262144);
      expect(model.cpuUsage, 35);
      expect(model.firmwareImages, isEmpty);
    });

    test('passes firmware images through', () {
      final fwModels = svc.buildFirmwareImageUIModels(
        data: FirmwareImages(items: [
          FirmwareImage(
            instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
            name: 'fw1',
            version: '1.0',
            status: 'Active',
            available: true,
          ),
        ]),
        activeRef: 'Device.DeviceInfo.FirmwareImage.1.',
        bootRef: 'Device.DeviceInfo.FirmwareImage.1.',
      );

      final model =
          svc.buildSystemInfoUIModel(_systemInfo, firmwareImages: fwModels);
      expect(model.firmwareImages.length, 1);
      expect(model.firmwareImages.first.name, 'fw1');
    });
  });

  // -----------------------------------------------------------------------
  // buildFirmwareImageUIModels
  // -----------------------------------------------------------------------
  group('buildFirmwareImageUIModels', () {
    test('maps fields and marks active/boot', () {
      final result = svc.buildFirmwareImageUIModels(
        data: FirmwareImages(items: [
          FirmwareImage(
            instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
            name: 'fw1',
            version: '1.0.16',
            status: 'Active',
            available: true,
          ),
          FirmwareImage(
            instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
            name: 'fw2',
            version: '1.0.14',
            status: 'Available',
            available: true,
          ),
        ]),
        activeRef: 'Device.DeviceInfo.FirmwareImage.1.',
        bootRef: 'Device.DeviceInfo.FirmwareImage.1.',
      );

      expect(result.length, 2);
      expect(result[0].isActive, isTrue);
      expect(result[0].isBootTarget, isTrue);
      expect(result[1].isActive, isFalse);
      expect(result[1].isBootTarget, isFalse);
    });

    test('handles trailing dot normalization in refs', () {
      final result = svc.buildFirmwareImageUIModels(
        data: FirmwareImages(items: [
          FirmwareImage(
            instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
            name: 'fw1',
            version: '1.0',
            status: 'Active',
            available: true,
          ),
        ]),
        // Ref WITHOUT trailing dot — should still match
        activeRef: 'Device.DeviceInfo.FirmwareImage.1',
        bootRef: '',
      );

      expect(result.first.isActive, isTrue);
      expect(result.first.isBootTarget, isFalse);
    });

    test('empty items returns empty list', () {
      final result = svc.buildFirmwareImageUIModels(
        data: FirmwareImages(items: []),
        activeRef: '',
        bootRef: '',
      );
      expect(result, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // buildTimeSettingsUIModel
  // -----------------------------------------------------------------------
  group('buildTimeSettingsUIModel', () {
    test('maps all fields', () {
      final model = svc.buildTimeSettingsUIModel(TimeSettings(
        enable: true,
        status: 'Synchronized',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: 'time.google.com',
        localTimeZone: 'Asia/Taipei',
        currentLocalTime: '2026-03-30T16:00:00',
      ));

      expect(model.enable, isTrue);
      expect(model.status, 'Synchronized');
      expect(model.ntpServer1, 'pool.ntp.org');
      expect(model.ntpServer2, 'time.google.com');
      expect(model.localTimeZone, 'Asia/Taipei');
      expect(model.currentLocalTime, '2026-03-30T16:00:00');
    });
  });

  // -----------------------------------------------------------------------
  // buildLanInfoUIModel
  // -----------------------------------------------------------------------
  group('buildLanInfoUIModel', () {
    test('maps all fields', () {
      final model = svc.buildLanInfoUIModel(
        LanNetworkInfo(
          ipAddress: '192.168.1.1',
          subnetMask: '255.255.255.0',
          dhcpEnabled: true,
          minAddress: '192.168.1.100',
          maxAddress: '192.168.1.200',
          leaseTime: 86400,
          dnsServers: '8.8.8.8',
          hostName: 'router',
          ipv6Enabled: false,
        ),
      );

      expect(model.ipAddress, '192.168.1.1');
      expect(model.subnetMask, '255.255.255.0');
      expect(model.dhcpEnabled, isTrue);
      expect(model.minAddress, '192.168.1.100');
      expect(model.maxAddress, '192.168.1.200');
      expect(model.dnsServers, '8.8.8.8');
      expect(model.ipv6Enabled, isFalse);
      expect(model.ipv6Addresses, isEmpty);
    });

    test('passes ipv6Addresses through', () {
      final model = svc.buildLanInfoUIModel(
        LanNetworkInfo(
          ipAddress: '192.168.1.1',
          subnetMask: '255.255.255.0',
          dhcpEnabled: true,
          minAddress: '192.168.1.100',
          maxAddress: '192.168.1.200',
          leaseTime: 0,
          dnsServers: '',
          hostName: '',
          ipv6Enabled: true,
        ),
        ipv6Addresses: ['2001:db8::1', 'fe80::1'],
      );

      expect(model.ipv6Enabled, isTrue);
      expect(model.ipv6Addresses, ['2001:db8::1', 'fe80::1']);
    });
  });

  // -----------------------------------------------------------------------
  // buildWanStatusUIModel
  // -----------------------------------------------------------------------
  group('buildWanStatusUIModel', () {
    test('maps fields, isUp from status string', () {
      final model = svc.buildWanStatusUIModel(
        wanStatus: WanStatus(
          status: 'Up',
          ipAddress: '100.64.0.1',
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          maxMtuSize: 1500,
          ipv6Enabled: false,
        ),
        gateway: '100.64.0.254',
      );

      expect(model.isUp, isTrue);
      expect(model.ipAddress, '100.64.0.1');
      expect(model.subnetMask, '255.255.255.0');
      expect(model.addressingType, 'DHCP');
      expect(model.mtu, 1500);
      expect(model.gateway, '100.64.0.254');
    });

    test('status Down → isUp false', () {
      final model = svc.buildWanStatusUIModel(
        wanStatus: WanStatus(
          status: 'Down',
          ipAddress: '',
          subnetMask: '',
          addressingType: '',
          maxMtuSize: 0,
          ipv6Enabled: false,
        ),
        gateway: '',
      );

      expect(model.isUp, isFalse);
    });

    test('passes ipv6 fields', () {
      final model = svc.buildWanStatusUIModel(
        wanStatus: WanStatus(
          status: 'Up',
          ipAddress: '100.64.0.1',
          subnetMask: '255.255.255.0',
          addressingType: 'DHCP',
          maxMtuSize: 1500,
          ipv6Enabled: true,
        ),
        gateway: '',
        ipv6Addresses: ['2001:db8::1'],
      );

      expect(model.ipv6Enabled, isTrue);
      expect(model.ipv6Addresses, ['2001:db8::1']);
    });
  });

  // -----------------------------------------------------------------------
  // buildDhcpReservationUIModels
  // -----------------------------------------------------------------------
  group('buildDhcpReservationUIModels', () {
    test('maps reservation fields', () {
      final result = svc.buildDhcpReservationUIModels(DhcpReservations(items: [
        DhcpReservation(
          instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
          enable: true,
          chaddr: 'AA:BB:CC:DD:EE:01',
          yiaddr: '192.168.1.50',
        ),
        DhcpReservation(
          instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
          enable: false,
          chaddr: 'AA:BB:CC:DD:EE:02',
          yiaddr: '192.168.1.51',
        ),
      ]));

      expect(result.length, 2);
      expect(result[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(result[0].ip, '192.168.1.50');
      expect(result[0].enable, isTrue);
      expect(result[1].enable, isFalse);
    });

    test('empty reservations returns empty list', () {
      final result =
          svc.buildDhcpReservationUIModels(DhcpReservations(items: []));
      expect(result, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // buildPortForwardingRuleUIModels
  // -----------------------------------------------------------------------
  group('buildPortForwardingRuleUIModels', () {
    test('maps rule fields', () {
      final result = svc.buildPortForwardingRuleUIModels(PortForwarding(items: [
        PortForwardingRule(
          instancePath: 'Device.NAT.PortMapping.1.',
          enabled: true,
          externalPort: 8080,
          externalPortEndRange: 8090,
          internalPort: 80,
          internalClient: '192.168.1.10',
          protocol: 'TCP',
          description: 'Web Server',
        ),
      ]));

      expect(result.length, 1);
      expect(result.first.description, 'Web Server');
      expect(result.first.externalPort, 8080);
      expect(result.first.externalPortEndRange, 8090);
      expect(result.first.internalPort, 80);
      expect(result.first.internalClient, '192.168.1.10');
      expect(result.first.protocol, 'TCP');
      expect(result.first.enabled, isTrue);
    });

    test('empty rules returns empty list', () {
      final result =
          svc.buildPortForwardingRuleUIModels(PortForwarding(items: []));
      expect(result, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // buildPortTriggeringRuleUIModels
  // -----------------------------------------------------------------------
  group('buildPortTriggeringRuleUIModels', () {
    test('maps trigger with nested forward rules', () {
      final result = svc.buildPortTriggeringRuleUIModels(PortTriggering(items: [
        PortTrigger(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: true,
          description: 'Gaming',
          triggerPort: 3000,
          triggerPortEndRange: 3010,
          triggerProtocol: 'TCP',
          rules: [
            PortTriggerForwardRule(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.1.',
              forwardPort: 4000,
              forwardPortEndRange: 4010,
              forwardProtocol: 'UDP',
            ),
            PortTriggerForwardRule(
              instancePath: 'Device.NAT.PortTrigger.1.Rule.2.',
              forwardPort: 5000,
              forwardPortEndRange: 5005,
              forwardProtocol: 'TCP',
            ),
          ],
        ),
      ]));

      expect(result.length, 1);
      final trigger = result.first;
      expect(trigger.enabled, isTrue);
      expect(trigger.description, 'Gaming');
      expect(trigger.triggerPort, 3000);
      expect(trigger.triggerPortEndRange, 3010);
      expect(trigger.triggerProtocol, 'TCP');
      expect(trigger.forwardRules.length, 2);
      expect(trigger.forwardRules[0].forwardPort, 4000);
      expect(trigger.forwardRules[0].forwardProtocol, 'UDP');
      expect(trigger.forwardRules[1].forwardPort, 5000);
    });

    test('trigger with no forward rules', () {
      final result = svc.buildPortTriggeringRuleUIModels(PortTriggering(items: [
        PortTrigger(
          instancePath: 'Device.NAT.PortTrigger.1.',
          enabled: false,
          description: 'Empty',
          triggerPort: 100,
          triggerPortEndRange: 100,
          triggerProtocol: 'TCP',
          rules: [],
        ),
      ]));

      expect(result.length, 1);
      expect(result.first.forwardRules, isEmpty);
      expect(result.first.enabled, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // buildDhcpClientUIModels (medium — hostname enrichment)
  // -----------------------------------------------------------------------
  group('buildDhcpClientUIModels', () {
    final leaseTime = DateTime(2026, 3, 30, 12, 0, 0);

    test('maps client fields with hostname enrichment', () {
      final result = svc.buildDhcpClientUIModels(
        clients: DhcpClients(items: [
          DhcpClient(
            instancePath: 'Device.DHCPv4.Server.Pool.1.Client.1.',
            chaddr: 'AA:BB:CC:DD:EE:FF',
            active: true,
            ipAddress: '192.168.1.10',
            leaseTimeRemaining: leaseTime,
          ),
        ]),
        connectedDevices: ConnectedDevices(items: [
          ConnectedDevice(
            instancePath: 'Device.Hosts.Host.1.',
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.10',
            hostName: 'laptop',
            isActive: true,
            interface_: 'Device.Ethernet.Interface.1',
            addressSource: 'DHCP',
            ipv6Addresses: [],
          ),
        ]),
      );

      expect(result.length, 1);
      expect(result.first.mac, 'AA:BB:CC:DD:EE:FF');
      expect(result.first.ip, '192.168.1.10');
      expect(result.first.active, isTrue);
      expect(result.first.hostName, 'laptop');
    });

    test('case-insensitive MAC matching for hostname', () {
      final result = svc.buildDhcpClientUIModels(
        clients: DhcpClients(items: [
          DhcpClient(
            instancePath: 'Device.DHCPv4.Server.Pool.1.Client.1.',
            chaddr: 'aa:bb:cc:dd:ee:ff',
            active: true,
            ipAddress: '192.168.1.10',
            leaseTimeRemaining: leaseTime,
          ),
        ]),
        connectedDevices: ConnectedDevices(items: [
          ConnectedDevice(
            instancePath: 'Device.Hosts.Host.1.',
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.10',
            hostName: 'laptop',
            isActive: true,
            interface_: 'Device.Ethernet.Interface.1',
            addressSource: 'DHCP',
            ipv6Addresses: [],
          ),
        ]),
      );

      expect(result.first.hostName, 'laptop');
    });

    test('no matching device — hostname empty', () {
      final result = svc.buildDhcpClientUIModels(
        clients: DhcpClients(items: [
          DhcpClient(
            instancePath: 'Device.DHCPv4.Server.Pool.1.Client.1.',
            chaddr: 'FF:FF:FF:FF:FF:FF',
            active: true,
            ipAddress: '192.168.1.99',
            leaseTimeRemaining: leaseTime,
          ),
        ]),
        connectedDevices: ConnectedDevices(items: []),
      );

      expect(result.first.hostName, '');
    });

    test('empty clients returns empty list', () {
      final result = svc.buildDhcpClientUIModels(
        clients: DhcpClients(items: []),
        connectedDevices: ConnectedDevices(items: []),
      );
      expect(result, isEmpty);
    });
  });
}
