import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import '../pnp_admin_view_test_mocks.dart' as Mock;
import 'package:privacy_gui/page/pnp/data/pnp_state.dart';
import 'package:privacy_gui/page/pnp/pnp_admin_view.dart';

import '../../../common/mock_firebase_messaging.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_info_test_data.dart';

@GenerateNiceMocks([MockSpec<PnpNotifier>(), MockSpec<RouterRepository>()])
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
    // .thenThrow(ExceptionInvalidAdminPassword());
    when(mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {});
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {});
    when(mockPnpNotifier.save()).thenAnswer((_) async {});
  });

  testLocalizations('pnp admin view - checking internet ',
      (tester, locale) async {
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('pnp admin view - internet checked ',
      (tester, locale) async {
    when(mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });
    when(mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations('pnp admin view - input router password ',
      (tester, locale) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const PnpAdminView(),
          locale: locale,
          overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        ),
      );
      BuildContext context = tester.element(find.byType(PnpAdminView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await tester.pumpAndSettle();
    });
  });

  testLocalizations('pnp admin view - where is it tapped ',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpAdminView(),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pumpAndSettle();
    final btnFinder = find.byType(TextButton);
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('pnp admin view - factory reset', (tester, locale) async {
    when(mockPnpNotifier.checkRouterConfigured())
        .thenThrow(ExceptionRouterUnconfigured());
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const PnpAdminView(),
          locale: locale,
          overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
        ),
      );
      BuildContext context = tester.element(find.byType(PnpAdminView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await tester.pumpAndSettle();
    });
  });
}
