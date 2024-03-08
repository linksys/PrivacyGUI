import 'package:firebase_core/firebase_core.dart';
import 'package:linksys_app/page/dashboard/_dashboard.dart';

import '../../../common/mock_firebase_messaging.dart';
import '../../../common/testable_widget.dart';
import '../../../common/test_localization.dart';

void main() async {
  setupFirebaseMessagingMocks();
  // FirebaseMessaging? messaging;
  await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;
  // messaging = FirebaseMessaging.instance;

  testLocalizations('Dashboard Menu View', (tester, locale) async {
    await tester.pumpWidget(
      testableRouteWidget(
        child: const DashboardShell(child: DashboardMenuView()),
        locale: locale,
      ),
    );
  });
}
