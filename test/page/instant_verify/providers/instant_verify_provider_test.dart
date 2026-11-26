// Instant Verify: the WAN connection, radios and guest network it shows, read
// from the poll, and its ping and traceroute against the router behind
// RouterRepository.
//
// The poll's input is poll-shaped, a Map<JNAPAction, JNAPResult> through
// RecordingPolling, not the parsed snapshots in test/test_data (#1922 decodes
// the poll in one place; a test fed by the poll survives that).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../instant_device/providers/home_network_poll.dart';

void main() {
  late RouterBoundary router;
  late ProviderContainer container;

  InstantVerifyNotifier notifier() =>
      container.read(instantVerifyProvider.notifier);
  InstantVerifyState page() => container.read(instantVerifyProvider);

  void open(Map<JNAPAction, JNAPResult> poll) {
    router = RouterBoundary()
      ..holds(JNAPAction.startPing, {})
      ..holds(JNAPAction.stopPing, {})
      ..holds(JNAPAction.startTracroute, {})
      ..holds(JNAPAction.stopTracroute, {});
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => RecordingPolling(poll)),
    ]);
    addTearDown(container.dispose);
  }

  group('what the poll reports', () {
    test('shows the WAN connection', () {
      open(homeNetworkPoll());

      expect(page().wanConnection?.wanType, 'DHCP');
      expect(page().wanConnection?.ipAddress, '203.0.113.7');
      expect(page().wanConnection?.gateway, '203.0.113.1');
      expect(page().wanConnection?.dnsServer1, '203.0.113.53');
    });

    test('shows the radios and the guest network', () {
      open(homeNetworkPoll());

      expect(page().radioInfo.radios.map((radio) => radio.radioID),
          ['RADIO_2.4GHz', 'RADIO_5GHz']);
      expect(page().radioInfo.radios.first.settings.ssid, 'Home');
      expect(page().guestRadioSettings.isGuestNetworkEnabled, isTrue);
      expect(page().guestRadioSettings.radios.first.guestSSID, 'Home-Guest');
    });

    test('shows no WAN connection when the poll has no WAN status', () {
      open(homeNetworkPoll()..remove(JNAPAction.getWANStatus));

      expect(page().wanConnection, isNull);
      expect(page().radioInfo.radios, hasLength(2));
    });

    test('before any poll, shows no WAN, no radios and the guest network off',
        () {
      open(const {});

      expect(page().wanConnection, isNull);
      expect(page().radioInfo.radios, isEmpty);
      expect(page().radioInfo.isBandSteeringSupported, isFalse);
      expect(page().guestRadioSettings.isGuestNetworkEnabled, isFalse);
      expect(page().guestRadioSettings.radios, isEmpty);
      expect(page().isRunning, isFalse);
    });

    test('follows the next poll', () {
      open(homeNetworkPoll());
      expect(page().wanConnection?.ipAddress, '203.0.113.7');

      final next = wanStatus();
      (next['wanConnection'] as Map<String, dynamic>)['ipAddress'] =
          '198.51.100.20';
      container.read(pollingProvider.notifier).state = AsyncData(
          CoreTransactionData(
              lastUpdate: 2,
              isReady: true,
              data: homeNetworkPoll(extra: {JNAPAction.getWANStatus: next})));

      expect(page().wanConnection?.ipAddress, '198.51.100.20');
    });
  });

  group('ping', () {
    setUp(() => open(homeNetworkPoll()));

    test('starts a ping of the host with 32-byte packets, and shows it running',
        () async {
      await notifier().ping(host: '8.8.8.8', pingCount: 5);

      expect(router.payloadsOf(JNAPAction.startPing).single,
          {'host': '8.8.8.8', 'packetSizeBytes': 32, 'pingCount': 5});
      expect(page().isRunning, isTrue);
    });

    test('leaves the count to the router when none is given', () async {
      await notifier().ping(host: '8.8.8.8', pingCount: null);

      expect(router.payloadsOf(JNAPAction.startPing).single,
          {'host': '8.8.8.8', 'packetSizeBytes': 32});
    });

    test('a refused start reaches the caller', () async {
      router.refuses(JNAPAction.startPing);

      await expectLater(notifier().ping(host: '8.8.8.8', pingCount: 5),
          throwsA(isA<JNAPError>()));
    });

    test('a stop sends the stop and shows it stopped', () async {
      await notifier().ping(host: '8.8.8.8', pingCount: 5);

      await notifier().stopPing();

      expect(router.actions.last, JNAPAction.stopPing);
      expect(page().isRunning, isFalse);
    });

    test('follows the ping until it stops running, then shows it stopped',
        () async {
      router.holdsInTurn(JNAPAction.getPingStatus, [
        {'isRunning': true, 'pingLog': 'PING 8.8.8.8: 32 data bytes'},
        {
          'isRunning': false,
          'pingLog': 'PING 8.8.8.8: 32 data bytes\n5 packets received',
        },
      ]);
      await notifier().ping(host: '8.8.8.8', pingCount: 5);

      final logs = await notifier()
          .getPingStatus()
          .map((status) => status.pingLog)
          .toList();

      expect(logs, [
        'PING 8.8.8.8: 32 data bytes',
        'PING 8.8.8.8: 32 data bytes\n5 packets received',
      ]);
      expect(page().isRunning, isFalse);
    });

    test('passes on a status it cannot read, and gives up after 30 tries',
        () async {
      router.refuses(JNAPAction.getPingStatus);
      await notifier().ping(host: '8.8.8.8', pingCount: 5);
      final errors = <Object>[];

      await notifier().getPingStatus().handleError(errors.add).drain<void>();

      expect(errors, hasLength(30));
      expect(errors.first, isA<JNAPError>());
      expect(router.polls, [JNAPAction.getPingStatus]);
      expect(page().isRunning, isFalse);
    });
  });

  group('traceroute', () {
    setUp(() => open(homeNetworkPoll()));

    test('starts a traceroute to the host, and shows it running', () async {
      await notifier().traceroute(host: 'example.com', pingCount: null);

      expect(router.payloadsOf(JNAPAction.startTracroute).single,
          {'host': 'example.com'});
      expect(page().isRunning, isTrue);
    });

    test('a refused start reaches the caller', () async {
      router.refuses(JNAPAction.startTracroute);

      await expectLater(
          notifier().traceroute(host: 'example.com', pingCount: null),
          throwsA(isA<JNAPError>()));
    });

    test('a stop sends the stop and shows it stopped', () async {
      await notifier().traceroute(host: 'example.com', pingCount: null);

      await notifier().stopTraceroute();

      expect(router.actions.last, JNAPAction.stopTracroute);
      expect(page().isRunning, isFalse);
    });

    test('follows the traceroute until it stops running, then shows it stopped',
        () async {
      router.holdsInTurn(JNAPAction.getTracerouteStatus, [
        {'isRunning': true, 'tracerouteLog': '1  192.168.1.1  1 ms'},
        {
          'isRunning': false,
          'tracerouteLog': '1  192.168.1.1  1 ms\n2  203.0.113.1  5 ms',
        },
      ]);
      await notifier().traceroute(host: 'example.com', pingCount: null);

      final logs = await notifier()
          .getTracerouteStatus()
          .map((status) => status.tracerouteLog)
          .toList();

      expect(logs, [
        '1  192.168.1.1  1 ms',
        '1  192.168.1.1  1 ms\n2  203.0.113.1  5 ms',
      ]);
      expect(page().isRunning, isFalse);
    });

    test('passes on a status it cannot read, and gives up after 30 tries',
        () async {
      router.refuses(JNAPAction.getTracerouteStatus);
      await notifier().traceroute(host: 'example.com', pingCount: null);
      final errors = <Object>[];

      await notifier()
          .getTracerouteStatus()
          .handleError(errors.add)
          .drain<void>();

      expect(errors, hasLength(30));
      expect(errors.first, isA<JNAPError>());
      expect(page().isRunning, isFalse);
    });
  });
}
