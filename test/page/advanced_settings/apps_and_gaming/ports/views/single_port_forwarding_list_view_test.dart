import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/config.dart';
import '../../../../../common/di.dart';
import '../../../../../common/screen.dart';
import '../../../../../common/semantics_identifiers.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/single_port_forwarding_list_notifier_mocks.dart';

/// Two rules on one port and with one name, which only their protocols tell
/// apart.
final _tcp = _rule(externalPort: 80, protocol: 'TCP', description: 'Web');
final _udp = _rule(externalPort: 80, protocol: 'UDP', description: 'Web');

SinglePortForwardingRule _rule({
  required int externalPort,
  required String protocol,
  String description = 'XBOX',
}) =>
    SinglePortForwardingRule(
      isEnabled: true,
      externalPort: externalPort,
      protocol: protocol,
      internalServerIPAddress: '192.168.1.150',
      internalPort: 3074,
      description: description,
    );

void main() {
  group('singlePortForwardingRuleKey', () {
    test('is the external port and the protocol, in lower case', () {
      expect(
        singlePortForwardingRuleKey(_rule(externalPort: 3074, protocol: 'TCP')),
        '3074-tcp',
      );
      expect(
        singlePortForwardingRuleKey(_rule(externalPort: 80, protocol: 'UDP')),
        '80-udp',
      );
      expect(
        singlePortForwardingRuleKey(_rule(externalPort: 22, protocol: 'Both')),
        '22-both',
      );
    });

    // The page saves two rules with one name, and a name in another script
    // has no kebab-case letters, so the name is left out.
    test('does not depend on the rule\'s name', () {
      expect(
        singlePortForwardingRuleKey(
            _rule(externalPort: 22, protocol: 'Both', description: '遊戲主機')),
        '22-both',
      );
    });
  });

  // E2E tests locate the list's controls by these (constitution 11.2, 11.3):
  // a rule's actions are keyed by singlePortForwardingRuleKey, never by its
  // position.
  group('identifiers', () {
    late MockSinglePortForwardingListNotifier mockNotifier;

    mockDependencyRegister();

    setUp(() {
      mockNotifier = MockSinglePortForwardingListNotifier();
      when(mockNotifier.build())
          .thenReturn(SinglePortForwardingListState(rules: [_tcp, _udp]));
    });

    Future<void> pumpList(WidgetTester tester, ScreenSize screen) async {
      await tester.setScreenSize(screen);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(testableSingleRoute(
        child: const SinglePortForwardingListView(),
        locale: const Locale('en'),
        config: LinksysRouteConfig(noNaviRail: true),
        overrides: [
          singlePortForwardingListProvider.overrideWith(() => mockNotifier),
        ],
      ));
      await tester.pumpAndSettle();
    }

    const rowIds = [
      'pf-single-add',
      'pf-single-edit-80-tcp',
      'pf-single-delete-80-tcp',
      'pf-single-edit-80-udp',
      'pf-single-delete-80-udp',
    ];

    testWidgets('a mobile card is deleted by its rule\'s key', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpList(tester, device480w);

      final found = identifierCounts(rowIds);
      await tester.tap(find.bySemanticsIdentifier('pf-single-delete-80-udp'));
      await tester.pumpAndSettle();
      // Before any expect: flutter_test checks for a live handle before
      // tear-down runs.
      semantics.dispose();

      expect(found.values, everyElement(1), reason: '$found');
      verify(mockNotifier.deleteRule(_udp)).called(1);
    });

    testWidgets('a desktop row is edited in place, with the form\'s fields',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpList(tester, device1440w);

      final rows = identifierCounts(rowIds);
      await tester.tap(find.bySemanticsIdentifier('pf-single-edit-80-tcp'));
      await tester.pumpAndSettle();
      final editing = identifierCounts([
        'pf-single-save-80-tcp',
        'pf-single-cancel-80-tcp',
        'pf-single-description',
        'pf-single-internal-port',
        'pf-single-external-port',
        'pf-single-protocol',
        'pf-single-internal-ip-octet-0',
        'pf-single-internal-ip-octet-1',
        'pf-single-internal-ip-octet-2',
        'pf-single-internal-ip-octet-3',
      ]);
      semantics.dispose();

      expect(rows.values, everyElement(1), reason: '$rows');
      expect(editing.values, everyElement(1), reason: '$editing');
    });

    // An identifier does not change with state (constitution 11.3): a test
    // that found the row's save keeps it while it edits the key's own fields.
    testWidgets('a desktop row keeps its key while its port is edited',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpList(tester, device1440w);

      await tester.tap(find.bySemanticsIdentifier('pf-single-edit-80-tcp'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.bySemanticsIdentifier('pf-single-external-port'), '8080');
      await tester.pumpAndSettle();
      final found = identifierCounts([
        'pf-single-save-80-tcp',
        'pf-single-cancel-80-tcp',
        'pf-single-save-8080-tcp',
      ]);
      final edited = ProviderScope.containerOf(
              tester.element(find.byType(SinglePortForwardingListView)))
          .read(singlePortForwardingRuleProvider)
          .rule;
      semantics.dispose();

      expect(edited?.externalPort, 8080, reason: 'the edit took');
      expect(found, {
        'pf-single-save-80-tcp': 1,
        'pf-single-cancel-80-tcp': 1,
        'pf-single-save-8080-tcp': 0,
      });
    });
  });
}
