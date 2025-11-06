import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/device_info_test_data.dart';

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Instant Setup - PnP: Checking unconfigured router',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
      ),
    );
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
      throw ExceptionRouterUnconfigured();
    });

    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 1));
  }, screens: screens);

  testLocalizations('Instant Setup - PnP: Router is unconfigured',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: true,
      ),
    );
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(PnpAdminView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerLn12, context);
      await tester.pumpAndSettle();
    });
  }, screens: screens);

  testLocalizations('Instant Setup - PnP: Checking internet connection',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
      ),
    );
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });
    when(testHelper.mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 1));
  }, screens: screens);

  testLocalizations('Instant Setup - PnP: Internet is connected',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
      ),
    );
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });
    when(testHelper.mockPnpNotifier.checkInternetConnection()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
    });

    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 2));
  }, screens: screens);

  testLocalizations('Instant Setup - PnP: Password input required',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: false,
      ),
    );
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 1));
  }, screens: screens);

  testLocalizations('Instant Setup - PnP: Tap Where is it',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: false,
      ),
    );
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.checkRouterConfigured()).thenAnswer((_) async {
      throw ExceptionRouterUnconfigured();
    });

    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 1));
    final btnFinder = find.byType(TextButton);
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();
  }, screens: screens);
}