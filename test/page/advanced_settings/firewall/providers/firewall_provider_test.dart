import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';

import '../../../../common/router_boundary.dart';

/// `GetFirewallSettings` output, the spec's sample.
const _firewall = <String, dynamic>{
  'isIPv4FirewallEnabled': true,
  'isIPv6FirewallEnabled': true,
  'blockMulticast': false,
  'blockNATRedirection': false,
  'blockIDENT': true,
  'blockAnonymousRequests': true,
  'blockIPSec': true,
  'blockPPTP': true,
  'blockL2TP': true,
};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late FirewallNotifier notifier;

  FirewallState page() => container.read(firewallProvider);

  setUp(() {
    router = RouterBoundary()..holds(JNAPAction.getFirewallSettings, _firewall);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(firewallProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('shows what the router holds', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(page().settings, FirewallSettings.fromMap(_firewall));
      expect(page().settings.isIPv4FirewallEnabled, isTrue);
      expect(page().settings.blockMulticast, isFalse);
    });

    test('reports a read the router refuses, and keeps the page', () async {
      router.refuses(JNAPAction.getFirewallSettings);
      final before = page();

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page(), before);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router.sent.clear();
    });

    test('writes every switch the page shows', () async {
      notifier.setSettings(
          page().settings.copyWith(blockMulticast: true, blockL2TP: false));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setFirewallSettings).single, {
        ..._firewall,
        'blockMulticast': true,
        'blockL2TP': false,
      });
    });

    test('reads the switches back from the router after the write', () async {
      router.holds(JNAPAction.getFirewallSettings,
          {..._firewall, 'isIPv6FirewallEnabled': false});

      final saved = await notifier.save();

      expect(router.actions,
          [JNAPAction.setFirewallSettings, JNAPAction.getFirewallSettings]);
      expect(saved.settings.isIPv6FirewallEnabled, isFalse);
      expect(page().settings.isIPv6FirewallEnabled, isFalse);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setFirewallSettings);
      notifier.setSettings(page().settings.copyWith(blockPPTP: false));

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setFirewallSettings]);
      expect(page().settings.blockPPTP, isFalse);
    });
  });
}
