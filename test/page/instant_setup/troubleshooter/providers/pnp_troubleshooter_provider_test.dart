// PnP's troubleshooter waits for the WAN to come up after the ISP settings
// are saved (#1924 P0). The rule is in checkNewSettings: DHCP and static are up
// when GetWANStatus says Connected; PPPoE, and anything else, once the WAN has
// an address. These tests reach it through the notifier and RouterBoundary's
// scheduledCommand, which polls as the real one does, so they survive #1924
// moving validation and the save sequence out of the views, and fail when the
// rule or the wait changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';

import '../../../../common/router_boundary.dart';

/// `GetWANStatus` output with [wanStatus] and, when [ipAddress] is given, the
/// WAN connection that carries it.
Map<String, dynamic> _wan(String wanStatus, {String? ipAddress}) => {
      'macAddress': '00:11:22:33:44:55',
      'detectedWANType': 'PPPoE',
      'wanStatus': wanStatus,
      'wanIPv6Status': 'Disconnected',
      if (ipAddress != null)
        'wanConnection': {
          'wanType': 'PPPoE',
          'ipAddress': ipAddress,
          'networkPrefixLength': 32,
          'gateway': '198.51.100.1',
          'mtu': 1492,
          'dnsServer1': '198.51.100.53',
        },
      'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
    };

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  // What onCompleted was told: whether the polls ran out.
  late List<bool> completions;

  PnpTroubleshooterNotifier notifier() =>
      container.read(pnpTroubleshooterProvider.notifier);

  setUp(() {
    router = RouterBoundary();
    completions = [];
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
  });

  tearDown(() => container.dispose());

  Stream<bool> check(WanType type) => notifier().checkNewSettings(
        settingWanType: type,
        onCompleted: completions.add,
      );

  int wanReads() =>
      router.actions.where((a) => a == JNAPAction.getWANStatus).length;

  group('DHCP and static', () {
    for (final type in [WanType.dhcp, WanType.static]) {
      test('${type.type}: the WAN is up once the router says Connected',
          () async {
        router.holdsInTurn(JNAPAction.getWANStatus, [
          _wan('Connecting'),
          _wan('Connecting', ipAddress: '203.0.113.7'),
          _wan('Connected', ipAddress: '203.0.113.7'),
        ]);

        expect(await check(type).toList(), [false, false, true]);
        expect(completions, [false]);
      });
    }

    test('an address without Connected is not up', () async {
      router.holds(JNAPAction.getWANStatus,
          _wan('Connecting', ipAddress: '203.0.113.7'));

      expect(await check(WanType.dhcp).toList(), everyElement(isFalse));
    });

    test('gives up after 18 reads, and says the reads ran out', () async {
      router.holds(JNAPAction.getWANStatus, _wan('Disconnected'));

      final seen = await check(WanType.static).toList();

      expect(seen, hasLength(18));
      expect(wanReads(), 18);
      expect(completions, [true]);
    });

    testWidgets('reads the WAN every 5 seconds, 90 seconds in all',
        (tester) async {
      router
        ..honorsPollDelays = true
        ..holds(JNAPAction.getWANStatus, _wan('Disconnected'));
      check(WanType.dhcp).listen((_) {});

      // The first read waits scheduledCommand's 3 s.
      await tester.pump(const Duration(seconds: 3));
      expect(wanReads(), 1);
      await tester.pump(const Duration(seconds: 5));
      expect(wanReads(), 2);
      await tester.pump(const Duration(seconds: 5));
      expect(wanReads(), 3);

      // The wait ends 5 s after the 18th read, 3 + 18 x 5 s after it began.
      await tester.pump(const Duration(seconds: 79));
      expect(wanReads(), 18);
      expect(completions, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(completions, [true]);
    });
  });

  group('PPPoE', () {
    test('the WAN is up once it has an address, whatever its status says',
        () async {
      router.holdsInTurn(JNAPAction.getWANStatus, [
        _wan('Connecting'),
        _wan('Connecting', ipAddress: '0.0.0.0'),
        _wan('Connecting', ipAddress: '203.0.113.7'),
      ]);

      expect(await check(WanType.pppoe).toList(), [false, false, true]);
      expect(completions, [false]);
    });

    test('Connected without an address is not up', () async {
      router.holds(JNAPAction.getWANStatus, _wan('Connected'));

      expect(await check(WanType.pppoe).toList(), everyElement(isFalse));
    });

    test('every type but DHCP and static waits as PPPoE does', () async {
      router.holds(JNAPAction.getWANStatus, _wan('Connected'));

      expect(await check(WanType.l2tp).toList(), everyElement(isFalse));
    });

    test('gives up after 4 reads, and says the reads ran out', () async {
      router.holds(JNAPAction.getWANStatus, _wan('Connected'));

      expect(await check(WanType.pppoe).toList(), hasLength(4));
      expect(completions, [true]);
    });

    testWidgets('reads the WAN every 15 seconds, 60 seconds in all',
        (tester) async {
      router
        ..honorsPollDelays = true
        ..holds(JNAPAction.getWANStatus, _wan('Connecting'));
      check(WanType.pppoe).listen((_) {});

      await tester.pump(const Duration(seconds: 3));
      expect(wanReads(), 1);
      await tester.pump(const Duration(seconds: 14));
      expect(wanReads(), 1);
      await tester.pump(const Duration(seconds: 1));
      expect(wanReads(), 2);

      // The wait ends 15 s after the 4th read, 3 + 4 x 15 s after it began.
      await tester.pump(const Duration(seconds: 44));
      expect(wanReads(), 4);
      expect(completions, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(completions, [true]);
    });
  });

  test('a refused read is not up, and the wait goes on', () async {
    router.holdsInTurn(JNAPAction.getWANStatus, [
      const JNAPError(result: 'ErrorUnknown'),
      _wan('Connected', ipAddress: '203.0.113.7'),
    ]);

    expect(await check(WanType.dhcp).toList(), [false, true]);
  });

  group('state', () {
    test('remembers the page the troubleshooter was opened from', () {
      expect(container.read(pnpTroubleshooterProvider).enterRouteName, '');

      notifier().setEnterRoute('dashboardHome');

      expect(container.read(pnpTroubleshooterProvider).enterRouteName,
          'dashboardHome');
    });

    test('survives a JSON round trip, and reads a missing route as none', () {
      final state = PnpTroubleshooterState(enterRouteName: 'dashboardHome');

      expect(state.toMap(), {'enterRouteName': 'dashboardHome'});
      expect(PnpTroubleshooterState.fromJson(state.toJson()).enterRouteName,
          'dashboardHome');
      expect(PnpTroubleshooterState.fromMap(const {}).enterRouteName, '');
    });
  });
}
