import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

import '../../../common/mock_firebase_messaging.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() async {
  setupFirebaseMessagingMocks();
  // FirebaseMessaging? messaging;
  await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;
  // messaging = FirebaseMessaging.instance;

  testLocalizations('Dashboard Navigation', (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: StyledAppPageView(
            appBarStyle: AppBarStyle.none, child: Container()),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  });
}
