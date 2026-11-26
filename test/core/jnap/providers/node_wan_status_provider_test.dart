// Whether the dashboard and the top bar show the router online, as read from
// the last poll.
//
// The input is the poll as polling hands it over, through RecordingPolling
// (#1834, #1922 P0): the fetch's result is what is pinned, not which reads
// polling chose to send.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import '../../../common/recording_polling.dart';

/// Polling whose next poll can fail, as a poll does when the router stops
/// answering: the error keeps the last good poll beside it.
class _FailingPolling extends RecordingPolling {
  _FailingPolling(super.data);

  void fail() {
    state = AsyncValue<CoreTransactionData>.error('no answer', StackTrace.empty)
        .copyWithPrevious(state);
  }
}

JNAPSuccess _internet(String connectionStatus) =>
    JNAPSuccess(result: 'OK', output: {'connectionStatus': connectionStatus});

/// `GetWANStatus` output with [status] as the IPv4 WAN's state.
JNAPSuccess _wan(String status) => JNAPSuccess(result: 'OK', output: {
      'supportedWANTypes': const ['DHCP', 'Static', 'PPPoE'],
      'supportedIPv6WANTypes': const ['Automatic'],
      'supportedWANCombinations': const [
        {'wanType': 'DHCP', 'wanIPv6Type': 'Automatic'},
      ],
      'detectedWANType': 'DHCP',
      'wanStatus': status,
      'wanIPv6Status': 'Disconnected',
      'macAddress': '30:23:03:2E:AF:EE',
    });

void main() {
  late ProviderContainer container;
  late _FailingPolling polling;

  InternetStatus internet() => container.read(internetStatusProvider);

  void start(Map<JNAPAction, JNAPResult> poll) {
    polling = _FailingPolling(poll);
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => polling),
    ]);
  }

  tearDown(() {
    container.dispose();
  });

  test('is online when the router says the Internet is connected', () {
    start({
      JNAPAction.getInternetConnectionStatus: _internet('InternetConnected'),
    });

    expect(internet(), InternetStatus.online);
  });

  test('is offline when the router says the Internet is not connected', () {
    start({
      JNAPAction.getInternetConnectionStatus: _internet('NoPortConnected'),
    });

    expect(internet(), InternetStatus.offline);
  });

  test('believes the Internet status over a connected WAN', () {
    start({
      JNAPAction.getInternetConnectionStatus: _internet('InternetDisconnected'),
      JNAPAction.getWANStatus: _wan('Connected'),
    });

    expect(internet(), InternetStatus.offline);
  });

  test('reads the WAN status on a router that gives no Internet status', () {
    start({JNAPAction.getWANStatus: _wan('Connected')});

    expect(internet(), InternetStatus.online);
  });

  test('is offline on a router whose WAN is not connected', () {
    start({JNAPAction.getWANStatus: _wan('Connecting')});

    expect(internet(), InternetStatus.offline);
  });

  test('is offline before a poll has said anything', () {
    start({});

    expect(internet(), InternetStatus.offline);
  });

  test('turns offline when a poll fails after a connected one', () {
    start({
      JNAPAction.getInternetConnectionStatus: _internet('InternetConnected'),
    });
    expect(internet(), InternetStatus.online);

    polling.fail();

    expect(internet(), InternetStatus.offline);
  });
}
