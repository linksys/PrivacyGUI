import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/home_title.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';

// #1637: with the router offline, the home title offers a Troubleshoot card
// that leads into PnP. A login that may not write is turned away from PnP, so
// the card would lead nowhere and is not offered.
void main() {
  mockDependencyRegister();

  Future<void> pumpOffline(WidgetTester tester, AccessPolicy policy) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dashboardManager = MockDashboardManagerNotifier();
    when(dashboardManager.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
    final polling = MockPollingNotifier();
    when(polling.build()).thenReturn(
        const CoreTransactionData(lastUpdate: 0, isReady: true, data: {}));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        dashboardManagerProvider.overrideWith(() => dashboardManager),
        pollingProvider.overrideWith(() => polling),
        internetStatusProvider.overrideWith((ref) => InternetStatus.offline),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const Scaffold(body: DashboardHomeTitle()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('an offline router offers Troubleshoot with full access',
      (tester) async {
    await pumpOffline(tester, AccessPolicy.full);

    expect(find.text('Troubleshoot'), findsOneWidget);
  });

  testWidgets('a read-only login is not offered Troubleshoot', (tester) async {
    await pumpOffline(tester, const AccessPolicy(canWrite: false));

    expect(find.text('Troubleshoot'), findsNothing);
  });
}
