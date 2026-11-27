// The device detail page: the device the user picked from a list, as the
// list shows it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_device/providers/device_detail_id_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/external_device_detail_provider.dart';

import '../../../common/recording_polling.dart';
import 'home_network_poll.dart';

/// Polling whose last poll a test replaces, as the next poll would.
class _NextPoll extends RecordingPolling {
  _NextPoll(super.data);

  void answer(Map<JNAPAction, JNAPResult> data) => state =
      AsyncData(CoreTransactionData(lastUpdate: 2, isReady: true, data: data));
}

void main() {
  late ProviderContainer container;

  DeviceListItem shown() => container.read(externalDeviceDetailProvider).item;

  void pick(String deviceId) =>
      container.read(deviceDetailIdProvider.notifier).state = deviceId;

  setUp(() {
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => RecordingPolling(homeNetworkPoll())),
    ]);
  });

  tearDown(() => container.dispose());

  test('shows no device before one is picked', () {
    expect(container.read(deviceDetailIdProvider), '');
    expect(shown().deviceId, '');
    expect(shown().name, '');
    expect(shown().macAddress, '');
  });

  test('shows the device picked', () {
    pick('phone');

    expect(shown().deviceId, 'phone');
    expect(shown().name, 'Alice iPhone');
    expect(shown().ipv4Address, '192.168.1.120');
    expect(shown().macAddress, phoneMac);
    expect(shown().upstreamDevice, 'Bedroom');
  });

  test('follows the pick to another device', () {
    pick('phone');
    shown();

    pick('printer');

    expect(shown().deviceId, 'printer');
    expect(shown().isOnline, isFalse);
  });

  test('shows no device once the one picked leaves the list', () {
    final poll = _NextPoll(homeNetworkPoll());
    container.dispose();
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => poll),
    ]);
    pick('phone');
    expect(shown().deviceId, 'phone');

    // The next poll no longer lists the phone: deleted, or dropped by the
    // router while its detail page is open.
    poll.answer(homeNetworkPoll(devices: [
      masterDevice(),
      bedroomNode(),
      laptopDevice(),
      tabletDevice(),
      printerDevice(),
    ]));

    expect(shown().deviceId, '');
    expect(shown().name, '');
  });
}
