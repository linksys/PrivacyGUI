import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/pnp_unplug_modem_view.dart';
import '../../../../common/mock_firebase_messaging.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/device_info_test_data.dart';
import '../../pnp_admin_view_test_mocks.dart' as Mock;
import 'package:privacy_gui/page/pnp/data/pnp_state.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;

  setupFirebaseMessagingMocks();
  await Firebase.initializeApp();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true));
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  testLocalizations('pnp unplug modem view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpUnplugModemView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('pnp unplug modem view - show tips',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpUnplugModemView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
    final tipFinder = find.byType(TextButton);
    await tester.tap(tipFinder);
    await tester.pumpAndSettle();
  });
}