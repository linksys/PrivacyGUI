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
  ///
  /// Capped at 99: the last MAC octet is a two-digit field, and `101 + i` runs
  /// out of the /24 at 155. Both would produce a syntactically invalid address
  /// rather than a test failure, so the ceiling is asserted instead of clamped
  /// (clamping would silently hand out duplicates and break the "distinct"
  /// promise the trigger's count comparison relies on).
  static List<ClientDevice> createClients(int count) {
    assert(count <= 99, 'createClients supports at most 99 clients');
    return List.generate(
      count,
      (i) => DevicesTestData.createWifiClient(
        mac: '11:22:33:44:55:${(i + 1).toString().padLeft(2, '0')}',
        ip: '192.168.1.${101 + i}',
        hostName: 'Client-${i + 1}',
      ),
    );
  }
}
