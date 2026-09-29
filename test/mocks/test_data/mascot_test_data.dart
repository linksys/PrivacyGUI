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
  /// `newDeviceJoined` fires only when the MAC set *gains* an address, so a test
  /// needs two of these. The MACs [createClients] hands out are positional, so
  /// two calls with different counts share a prefix — `clientCount: 3` is
  /// `clientCount: 2` plus one new MAC, which is the shape of a device joining.
  /// For a swap (one leaves, one joins, count unchanged) pass [clients].
  static DevicesData createDevicesData({
    int clientCount = 2,
    List<ClientDevice>? clients,
  }) {
    return DevicesData(
      meshNetwork: DevicesTestData.createSingleNodeNetwork(
        masterClients: clients ?? createClients(clientCount),
      ),
    );
  }

  /// A single client, for composing a [clients] list by hand.
  ///
  /// [mac] is what the trigger identifies a device by; [hostName] and
  /// [friendlyName] are what it announces, in the order
  /// `ClientDevice.displayName` prefers them.
  static ClientDevice createClient({
    required String mac,
    String hostName = '',
    String? friendlyName,
  }) =>
      DevicesTestData.createWifiClient(
        mac: mac,
        ip: '192.168.1.200',
        hostName: hostName,
        friendlyName: friendlyName,
      );

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
