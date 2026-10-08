import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/topology_data.dart';

/// A master with one offline child, Kitchen.
class _OfflineChildTopology extends InstantTopologyNotifier {
  @override
  InstantTopologyState build() => TopologyTestData().testTopology1OfflineState;
}

void main() {
  mockDependencyRegister();

  // #1637: an offline node's dialog offers to remove it from the network, which
  // deletes it from the router, so that button is blocked in read-only mode.
  group('offline node dialog', () {
    final removeButton = find.text('Remove node from network');
    final removeConfirm = find.text(
        'Are you sure you want to remove Kitchen from your mesh network?');

    Future<void> openOfflineNode(WidgetTester tester,
        {AccessPolicy policy = AccessPolicy.full}) async {
      await tester.setScreenSize(device1440w);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(testableSingleRoute(
        locale: const Locale('en'),
        overrides: [
          instantTopologyProvider.overrideWith(_OfflineChildTopology.new),
          accessPolicyProvider.overrideWithValue(policy),
        ],
        child: const InstantTopologyView(),
      ));
      await tester.pumpAndSettle();
      // Its name, as the middle of the card is selectable text.
      await tester.tap(find.text('Kitchen'));
      await tester.pumpAndSettle();
      expect(removeButton, findsOneWidget);
    }

    testWidgets('read-only mode blocks removing the node', (tester) async {
      await openOfflineNode(tester,
          policy: const AccessPolicy(canWrite: false));
      expect(
          find.ancestor(
              of: removeButton,
              matching:
                  find.byTooltip('This feature is unavailable in remote mode')),
          findsOneWidget);

      await tester.tap(removeButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(removeConfirm, findsNothing);
      expect(removeButton, findsOneWidget, reason: 'the dialog stays open');
    });

    testWidgets('the node can be removed with full access', (tester) async {
      await openOfflineNode(tester);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(removeConfirm, findsOneWidget);
    });
  });
}
