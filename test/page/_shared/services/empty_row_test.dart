import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/admin_users.g.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/data_elements_interfaces.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/generated/time_zones.g.dart';
import 'package:privacy_gui/generated/vendor_log_files.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/page/_shared/services/empty_row.dart';

import '../../../mocks/test_data/data_elements_test_data.dart';
import '../../../mocks/test_data/wifi_settings_test_data.dart';

void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  group('isBlank', () {
    test('a string is blank when empty, "0" or "false"', () {
      expect(['', '0', 'false'].every(isBlank), isTrue);
      expect(['x', '1', 'true', ' '].any(isBlank), isFalse);
    });

    test('null, 0, false and the epoch are blank', () {
      expect([null, 0, false, epoch].every(isBlank), isTrue);
      expect([1, true, DateTime.utc(2030)].any(isBlank), isFalse);
    });
  });

  group('isEmptyDhcpClient', () {
    DhcpClient client({
      String chaddr = '',
      bool active = false,
      List<DhcpClientIpv4Address> ipv4Addresses = const [],
    }) =>
        DhcpClient(
          instancePath: 'Device.DHCPv4.Server.Pool.4.Client.9.',
          chaddr: chaddr,
          active: active,
          ipv4Addresses: ipv4Addresses,
        );

    test('a client with every field blank is empty', () {
      expect(isEmptyDhcpClient(client()), isTrue);
      expect(
          isEmptyDhcpClient(client(ipv4Addresses: [
            DhcpClientIpv4Address(
                instancePath: 'a.', ipAddress: '', leaseTimeRemaining: epoch),
          ])),
          isTrue);
    });

    test('any one field set keeps the client', () {
      expect(isEmptyDhcpClient(client(chaddr: 'AA:BB:CC:DD:EE:01')), isFalse);
      expect(isEmptyDhcpClient(client(active: true)), isFalse);
      expect(
          isEmptyDhcpClient(client(ipv4Addresses: [
            DhcpClientIpv4Address(
                instancePath: 'a.',
                ipAddress: '192.168.1.5',
                leaseTimeRemaining: epoch),
          ])),
          isFalse);
      expect(
          isEmptyDhcpClient(client(ipv4Addresses: [
            DhcpClientIpv4Address(
                instancePath: 'a.',
                ipAddress: '',
                leaseTimeRemaining: DateTime.utc(2030)),
          ])),
          isFalse);
    });
  });

  group('isEmptyDhcpReservation', () {
    test('only enable, chaddr and yiaddr count, as before', () {
      const blank = DhcpReservation(
          instancePath: 'p.', enable: false, chaddr: '', yiaddr: '');
      expect(isEmptyDhcpReservation(blank), isTrue);
      // The name is new in 0.18.1 and was never part of the check.
      expect(
          isEmptyDhcpReservation(const DhcpReservation(
              instancePath: 'p.',
              enable: false,
              chaddr: '',
              yiaddr: '',
              name: 'Laptop')),
          isTrue);
      expect(
          isEmptyDhcpReservation(const DhcpReservation(
              instancePath: 'p.',
              enable: false,
              chaddr: '',
              yiaddr: '1.2.3.4')),
          isFalse);
    });
  });

  group('isEmptyWiFiSsid', () {
    WiFiSsid ssid({String ssid = '', bool enable = false}) =>
        WifiSettingsTestData.createSsid(
          instancePath: 'Device.WiFi.SSID.4.',
          ssid: ssid,
          enable: enable,
          status: '',
          bssid: '',
          lowerLayers: '',
        );

    test('blank is empty; an SSID name or Enable keeps it', () {
      expect(isEmptyWiFiSsid(ssid()), isTrue);
      expect(isEmptyWiFiSsid(ssid(ssid: 'Home')), isFalse);
      expect(isEmptyWiFiSsid(ssid(enable: true)), isFalse);
    });
  });

  group('isEmptyWiFiRadio', () {
    WiFiRadio radio({int channel = 0, String band = ''}) =>
        WifiSettingsTestData.createRadio(
          instancePath: 'Device.WiFi.Radio.4.',
          enable: false,
          status: '',
          channel: channel,
          operatingFrequencyBand: band,
          operatingChannelBandwidth: '',
          possibleChannels: '',
          operatingStandards: '',
          supportedStandards: '',
          transmitPower: 0,
          maxBitRate: 0,
          autoChannelEnable: false,
          supportedOperatingChannelBandwidths: '',
        );

    test('blank is empty; a band or a channel keeps it', () {
      expect(isEmptyWiFiRadio(radio()), isTrue);
      expect(isEmptyWiFiRadio(radio(band: '5GHz')), isFalse);
      expect(isEmptyWiFiRadio(radio(channel: 36)), isFalse);
    });
  });

  group('isEmptyMeshNode', () {
    MeshNode node({String id = '', String? serialNumber}) =>
        DataElementsTestData.node(
            instance: '4', id: id, serialNumber: serialNumber);

    test('blank is empty; an ID or any identity field keeps it', () {
      expect(isEmptyMeshNode(node()), isTrue);
      expect(isEmptyMeshNode(node(id: '74:12:13:21:55:50')), isFalse);
      expect(isEmptyMeshNode(node(serialNumber: 'SN1')), isFalse);
    });
  });

  group('isEmptyDmzEntry', () {
    DmzEntry entry({String destIp = '', String? destMac}) => DmzEntry(
          instancePath: 'Device.Firewall.DMZ.4.',
          enable: false,
          destIp: destIp,
          destMacAddress: destMac,
          sourcePrefix: '',
          interface_: '',
          description: '',
          status: '',
        );

    test('blank is empty; the new MAC field does not count, as before', () {
      expect(isEmptyDmzEntry(entry()), isTrue);
      expect(isEmptyDmzEntry(entry(destMac: 'AA:BB:CC:DD:EE:01')), isTrue);
      expect(isEmptyDmzEntry(entry(destIp: '192.168.1.50')), isFalse);
    });
  });

  group('isEmptyFirewallChainRule', () {
    test('blank is empty; a description or target keeps it', () {
      const blank = FirewallChainRule(
          instancePath: 'p.', enable: false, description: '', target: '');
      expect(isEmptyFirewallChainRule(blank), isTrue);
      expect(
          isEmptyFirewallChainRule(const FirewallChainRule(
              instancePath: 'p.',
              enable: false,
              description: '',
              target: 'Drop')),
          isFalse);
    });
  });

  group('isEmptyConnectedDevice', () {
    ConnectedDevice device({String mac = '', bool active = false}) =>
        ConnectedDevice(
          instancePath: 'Device.Hosts.Host.4.',
          macAddress: mac,
          ipAddress: '',
          hostName: '',
          isActive: active,
          interface_: '',
          ipv4Addresses: const [],
          ipv6Addresses: const [],
        );

    test('blank is empty; a MAC or Active keeps it', () {
      expect(isEmptyConnectedDevice(device()), isTrue);
      expect(isEmptyConnectedDevice(device(mac: 'AA:BB:CC:DD:EE:01')), isFalse);
      expect(isEmptyConnectedDevice(device(active: true)), isFalse);
    });
  });

  group('isEmptyMeshInterfaceNode', () {
    test('a node with no ID is empty, whatever its interfaces', () {
      expect(
          isEmptyMeshInterfaceNode(const MeshNodeInterfaces(
              instancePath: 'p.', id: '', interfaces: [])),
          isTrue);
      expect(
          isEmptyMeshInterfaceNode(const MeshNodeInterfaces(
              instancePath: 'p.', id: '74:12:13:21:55:50', interfaces: [])),
          isFalse);
    });
  });

  group('isEmptyWifiClient', () {
    WifiClient client({String mac = '', int signal = 0}) => WifiClient(
          instancePath: 'Device.WiFi.AccessPoint.1.AssociatedDevice.4.',
          parentPath: 'Device.WiFi.AccessPoint.1.',
          macAddress: mac,
          signalStrength: signal,
          noise: 0,
          lastDataDownlinkRate: 0,
          lastDataUplinkRate: 0,
          active: false,
        );

    test('blank is empty; a MAC or a signal keeps it', () {
      expect(isEmptyWifiClient(client()), isTrue);
      expect(isEmptyWifiClient(client(mac: 'AA:BB:CC:DD:EE:01')), isFalse);
      expect(isEmptyWifiClient(client(signal: -60)), isFalse);
    });
  });

  group('isEmptyEthernetInterface', () {
    EthernetInterface port({String name = '', int bitRate = 0}) =>
        EthernetInterface(
          instancePath: 'Device.Ethernet.Interface.4.',
          name: name,
          status: '',
          upstream: false,
          currentBitRate: bitRate,
        );

    test('blank is empty; a name or a bit rate keeps it', () {
      expect(isEmptyEthernetInterface(port()), isTrue);
      expect(isEmptyEthernetInterface(port(name: 'lan1')), isFalse);
      expect(isEmptyEthernetInterface(port(bitRate: 1000)), isFalse);
    });
  });

  group('isEmptyPortForwardingRule', () {
    PortForwardingRule rule({int externalPort = 0, String client = ''}) =>
        PortForwardingRule(
          instancePath: 'Device.NAT.PortMapping.4.',
          enabled: false,
          externalPort: externalPort,
          externalPortEndRange: 0,
          internalPort: 0,
          internalClient: client,
          protocol: '',
          description: '',
        );

    test('blank is empty; a port or a client keeps it', () {
      expect(isEmptyPortForwardingRule(rule()), isTrue);
      expect(isEmptyPortForwardingRule(rule(externalPort: 8080)), isFalse);
      expect(isEmptyPortForwardingRule(rule(client: '192.168.1.5')), isFalse);
    });
  });

  group('isEmptyPortTrigger', () {
    PortTrigger trigger({int port = 0, List<PortTriggerForwardRule>? rules}) =>
        PortTrigger(
          instancePath: 'Device.NAT.PortTrigger.4.',
          enabled: false,
          description: '',
          triggerPort: port,
          triggerPortEndRange: 0,
          triggerProtocol: '',
          rules: rules ?? const [],
        );

    test('blank is empty; its forward rules do not count, as before', () {
      expect(isEmptyPortTrigger(trigger()), isTrue);
      expect(
          isEmptyPortTrigger(trigger(rules: const [
            PortTriggerForwardRule(
                instancePath: 'r.',
                forwardPort: 80,
                forwardPortEndRange: 80,
                forwardProtocol: 'TCP'),
          ])),
          isTrue);
      expect(isEmptyPortTrigger(trigger(port: 6112)), isFalse);
    });
  });

  group('isEmptyVendorLogFile', () {
    test('blank is empty; a name keeps it', () {
      expect(
          isEmptyVendorLogFile(const VendorLogFile(
              instancePath: 'p.', name: '', maximumSize: 0, persistent: false)),
          isTrue);
      expect(
          isEmptyVendorLogFile(const VendorLogFile(
              instancePath: 'p.',
              name: 'messages',
              maximumSize: 0,
              persistent: false)),
          isFalse);
    });
  });

  group('isEmptyTimeZone', () {
    test('blank is empty; an ID keeps it', () {
      expect(
          isEmptyTimeZone(const TimeZoneEntry(
              instancePath: 'p.',
              timeZoneId: '',
              utcOffsetMinutes: 0,
              observesDst: false,
              description: '')),
          isTrue);
      expect(
          isEmptyTimeZone(const TimeZoneEntry(
              instancePath: 'p.',
              timeZoneId: 'UTC',
              utcOffsetMinutes: 0,
              observesDst: false,
              description: '')),
          isFalse);
    });
  });

  group('isEmptyAdminUser', () {
    test('blank is empty; a username keeps it', () {
      expect(
          isEmptyAdminUser(const AdminUser(
              instancePath: 'p.', username: '', password: '', enable: false)),
          isTrue);
      expect(
          isEmptyAdminUser(const AdminUser(
              instancePath: 'p.',
              username: 'admin',
              password: '',
              enable: false)),
          isFalse);
    });
  });
}
