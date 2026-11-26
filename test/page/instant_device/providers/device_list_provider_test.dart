// The device list the Devices page shows, built from what the router reports
// in a poll.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

import '../../../common/recording_polling.dart';
import 'home_network_poll.dart';

void main() {
  late ProviderContainer container;

  void pollReports(List<Map<String, dynamic>>? devices) {
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(
          () => RecordingPolling(homeNetworkPoll(devices: devices))),
    ]);
    addTearDown(container.dispose);
  }

  DeviceListItem item(String deviceId) => container
      .read(deviceListProvider)
      .devices
      .singleWhere((device) => device.deviceId == deviceId);

  setUp(() => pollReports(null));

  test('lists the clients, not the router or its nodes', () {
    expect(
      container.read(deviceListProvider).devices.map((d) => d.deviceId),
      unorderedEquals(['laptop', 'phone', 'tablet', 'printer']),
    );
  });

  test('a wired client is on Ethernet, by its addresses, under the router', () {
    final laptop = item('laptop');

    expect(laptop.name, 'Work Laptop');
    expect(laptop.isOnline, isTrue);
    expect(laptop.isWired, isTrue);
    expect(laptop.band, 'Ethernet');
    expect(laptop.ipv4Address, '192.168.1.100');
    expect(laptop.ipv6Address, 'fd00::10');
    expect(laptop.macAddress, laptopMac);
    expect(laptop.manufacturer, 'Dell');
    expect(laptop.model, 'XPS 13');
    expect(laptop.operatingSystem, 'Windows');
    expect(laptop.upstreamDevice, 'Living Room');
    expect(laptop.upstreamDeviceID, 'master');
    expect(laptop.icon, 'computer');
  });

  test('a Wi-Fi client shows the node, band, network and signal it is on', () {
    final phone = item('phone');

    expect(phone.name, 'Alice iPhone');
    expect(phone.isWired, isFalse);
    expect(phone.band, '5GHz');
    expect(phone.ssid, 'Home');
    expect(phone.signalStrength, -48);
    expect(phone.type, WifiConnectionType.main);
    expect(phone.upstreamDevice, 'Bedroom');
    expect(phone.upstreamDeviceID, 'bedroom');
    expect(phone.upstreamIcon, 'routerMx5300');
    expect(phone.icon, 'phone');
  });

  test('a client on an MLO-capable link is marked MLO', () {
    expect(item('phone').isMLO, isTrue);
    expect(item('tablet').isMLO, isFalse);
  });

  test('a guest client shows the guest network', () {
    final tablet = item('tablet');

    expect(tablet.type, WifiConnectionType.guest);
    expect(tablet.ssid, 'Home-Guest');
    expect(tablet.band, '2.4GHz');
    expect(tablet.model, 'Tablet', reason: 'no model number, so its type');
  });

  test('an offline client has no address and no node', () {
    final printer = item('printer');

    expect(printer.isOnline, isFalse);
    expect(printer.ipv4Address, '');
    expect(printer.ipv6Address, '');
    expect(printer.upstreamDevice, '');
    expect(printer.upstreamDeviceID, '');
    expect(printer.macAddress, printerMac);
  });

  test('the icon the user chose wins over the one the model gives', () {
    pollReports([
      masterDevice(),
      phoneDevice(userDeviceType: 'gameConsole'),
    ]);

    expect(item('phone').icon, 'gameConsole');
  });

  test('the offline list holds only the clients that are offline', () {
    expect(
      container.read(offlineDeviceListProvider).map((d) => d.deviceId),
      ['printer'],
    );
  });

  test('a router that reports no devices lists none', () {
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => RecordingPolling()),
    ]);
    addTearDown(container.dispose);

    expect(container.read(deviceListProvider).devices, isEmpty);
    expect(container.read(offlineDeviceListProvider), isEmpty);
  });
}
