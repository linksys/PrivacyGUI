import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// The real notifier with the router taken out: the page fetches on entry.
class _FakeTroubleshooting extends TroubleshootingNotifier {
  @override
  TroubleshootingState build() =>
      const TroubleshootingState(deviceStatusList: [], dhcpClientList: []);

  @override
  Future fetch({bool force = false}) async {}
}

void main() {
  mockDependencyRegister();

  Future<void> pumpPage(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        troubleshootingProvider.overrideWith(_FakeTroubleshooting.new),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const TroubleshootingView(),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: sharing router info has the router email its logs, a write, so the
  // button is blocked before it opens the share dialog.
  group('share router info', () {
    final share = find.text('Share router info with Linksys');

    testWidgets('is blocked in read-only mode', (tester) async {
      await pumpPage(tester, policy: const AccessPolicy(canWrite: false));

      expect(
          find.ancestor(
              of: share,
              matching:
                  find.byTooltip('This feature is unavailable in remote mode')),
          findsOneWidget);

      await tester.tap(share, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Send logs'), findsNothing);
    });

    testWidgets('opens the share dialog with full access', (tester) async {
      await pumpPage(tester);

      await tester.tap(share);
      await tester.pumpAndSettle();

      expect(find.text('Send logs'), findsOneWidget);
    });
  });
}
