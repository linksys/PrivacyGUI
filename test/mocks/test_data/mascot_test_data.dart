import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

import 'devices_test_data.dart';

/// Test data builder for the mascot trigger system.
///
/// Trigger evaluation compares a *previous* snapshot against a current one, so
/// what these factories parameterise is the discriminator each trigger reads:
/// the client count for `newDeviceJoined`, the WAN flag for `wanDown` /
/// `wanRestored` (see `SystemHealthTestData.createWanData`), and the IPv4 SPI
/// flag for `firewallDisabled` (see `FirewallTestData`).
class MascotTestData {
  /// Devices data holding exactly [clientCount] clients under the master node.
  ///
  /// `newDeviceJoined` fires only when the count *increases*, so a test needs
  /// two of these with different counts.
  static DevicesData createDevicesData({int clientCount = 2}) {
    return DevicesData(
      meshNetwork: DevicesTestData.createSingleNodeNetwork(
        masterClients: createClients(clientCount),
      ),
    );
  }

  /// [count] online WiFi clients with distinct MACs and IPs.
  static List<ClientDevice> createClients(int count) => List.generate(
        count,
        (i) => DevicesTestData.createWifiClient(
          mac: '11:22:33:44:55:${(i + 1).toString().padLeft(2, '0')}',
          ip: '192.168.1.${101 + i}',
          hostName: 'Client-${i + 1}',
        ),
      );
}
