// Firewall's Save writes two tabs at once: the firewall settings and the IPv6
// port services. Each tab's saved baseline follows its own write, so when the
// router takes one and refuses the other, the page keeps what landed and
// still offers to save the rest.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/router_boundary.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../common/theme_data.dart';
import '../../../../test_data/firewall_settings_test_state.dart';
import '../../../../test_data/ipv6_port_service_list_test_state.dart';

/// `GetFirewallSettings` output before the save, from the test data.
final _firewall =
    Map<String, dynamic>.from(firewallSettingsTestState['settings']!);

/// The same, with multicast blocked: what the user saves, and what the
/// router holds once it takes the write.
final _savedFirewall = {..._firewall, 'blockMulticast': true};

final _ipv6Rules = Map<String, dynamic>.from(ipv6PortServiceListTestState);
final _firstRule = Map<String, dynamic>.from(
    (ipv6PortServiceListTestState['rules'] as List)[0] as Map);
final _secondRule = Map<String, dynamic>.from(
    (ipv6PortServiceListTestState['rules'] as List)[1] as Map);

const _overlapMessage = 'The rules cannot be created because multiple rules '
    'were specified for a single port/protocol combination.';

void main() {
  mockDependencyRegister();

  late RouterBoundary router;
  late ProviderContainer container;

  final save = find.widgetWithText(AppFilledButton, 'Save');

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<AppFilledButton>(save).onTap != null;

  Future<void> openFirewall(WidgetTester tester) async {
    await loadTestFonts();
    await tester.setScreenSize(device1440w.copyWith(height: 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
        accessPolicyProvider.overrideWithValue(AccessPolicy.full),
      ],
      child: const FirewallView(),
    ));
    await tester.pumpAndSettle();
    container =
        ProviderScope.containerOf(tester.element(find.byType(FirewallView)));
  }

  /// Blocks multicast on the firewall tab and deletes the second IPv6 rule.
  Future<void> editBothTabs(WidgetTester tester) async {
    container
        .read(firewallProvider.notifier)
        .setSettings(FirewallSettings.fromMap(_savedFirewall));
    container
        .read(ipv6PortServiceListProvider.notifier)
        .deleteRule(IPv6FirewallRule.fromMap(_secondRule));
    await tester.pumpAndSettle();
  }

  setUp(() {
    router = RouterBoundary()
      ..holdsInTurn(JNAPAction.getFirewallSettings, [_firewall, _savedFirewall])
      ..holds(JNAPAction.getIPv6FirewallRules, _ipv6Rules);
  });

  testWidgets('keeps the firewall save when the router refuses the IPv6 rules',
      (tester) async {
    router.refuses(JNAPAction.setIPv6FirewallRules,
        result: 'ErrorRulesOverlap');
    await openFirewall(tester);
    await editBothTabs(tester);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(router.payloadsOf(JNAPAction.setFirewallSettings).single,
        _savedFirewall);
    expect(find.text(_overlapMessage), findsOneWidget);
    expect(find.text('Changes saved'), findsNothing);
    // The IPv6 edit stays on the page, still to be saved.
    expect(container.read(ipv6PortServiceListProvider).rules,
        [IPv6FirewallRule.fromMap(_firstRule)]);
    expect(saveEnabled(tester), isTrue);

    // Save again: the firewall settings landed, so only the IPv6 rules go.
    router.sent.clear();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(router.actions, [JNAPAction.setIPv6FirewallRules]);
    expect(router.payloadsOf(JNAPAction.setIPv6FirewallRules).single, {
      'rules': [_firstRule],
    });
  });

  testWidgets('says the changes are saved when the router takes both tabs',
      (tester) async {
    router.holdsInTurn(JNAPAction.getIPv6FirewallRules, [
      _ipv6Rules,
      {
        ..._ipv6Rules,
        'rules': [_firstRule]
      },
    ]);
    await openFirewall(tester);
    await editBothTabs(tester);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
        router.actions,
        containsAll([
          JNAPAction.setFirewallSettings,
          JNAPAction.setIPv6FirewallRules,
        ]));
    expect(find.text('Changes saved'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });
}
