import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/di.dart';
import '../../../../../common/testable_router.dart';

const _rule = SinglePortForwardingRule(
  isEnabled: true,
  externalPort: 3074,
  protocol: 'TCP',
  internalServerIPAddress: '192.168.1.150',
  internalPort: 3074,
  description: 'XBOX',
);

/// The form's identifiers in both modes. Only an existing rule has the switch.
const _formIds = [
  'pf-single-description',
  'pf-single-internal-port',
  'pf-single-external-port',
  'pf-single-protocol',
  'pf-single-internal-ip-octet-0',
  'pf-single-internal-ip-octet-1',
  'pf-single-internal-ip-octet-2',
  'pf-single-internal-ip-octet-3',
  'pf-single-select-device',
  'pf-single-submit',
];

/// The identifiers that [ids] name, each with the number of nodes that have
/// it. Semantics must be on.
Map<String, int> _found(List<String> ids) => {
      for (final id in ids) id: find.bySemanticsIdentifier(id).evaluate().length
    };

// E2E tests locate the rule form's controls by these (constitution 11.2,
// 11.3). Adding and updating share one submit identifier (issue #1935,
// Decision 5).
void main() {
  mockDependencyRegister();

  Future<void> pumpRule(WidgetTester tester, Map<String, dynamic> args) async {
    await tester.pumpWidget(testableSingleRoute(
      child: SinglePortForwardingRuleView(args: args),
      locale: const Locale('en'),
      config: LinksysRouteConfig(noNaviRail: true),
    ));
    await tester.pumpAndSettle();
  }

  SinglePortForwardingRule? ruleOf(WidgetTester tester) =>
      ProviderScope.containerOf(
              tester.element(find.byType(SinglePortForwardingRuleView)))
          .read(singlePortForwardingRuleProvider)
          .rule;

  testWidgets('a new rule has every field but the switch', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpRule(tester, {});

    final found = _found([..._formIds, 'pf-single-enabled']);
    semantics.dispose();

    expect(found, {for (final id in _formIds) id: 1, 'pf-single-enabled': 0});
  });

  testWidgets('a test toggles a rule and picks its protocol by identifiers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpRule(tester, {
      'items': [_rule],
      'edit': _rule,
    });

    final found = _found([..._formIds, 'pf-single-enabled']);
    await tester.tap(find.bySemanticsIdentifier('pf-single-enabled'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('pf-single-protocol'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('pf-single-protocol-item-udp'));
    await tester.pumpAndSettle();
    final rule = ruleOf(tester);
    // Before any expect: flutter_test checks for a live handle before
    // tear-down runs.
    semantics.dispose();

    expect(found.values, everyElement(1), reason: '$found');
    expect(rule?.isEnabled, isFalse);
    expect(rule?.protocol, 'UDP');
  });
}
