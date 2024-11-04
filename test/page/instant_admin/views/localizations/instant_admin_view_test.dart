import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/jnap_service_supported_mocks.dart';
import '../../../../mocks/router_password_notifier_mocks.dart';
import '../../../../test_data/firmware_update_test_state.dart';
import '../../../../test_data/router_password_test_state.dart';
import '../../../../test_data/timezone_test_state.dart';
import '../../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../../mocks/timezone_notifier_mocks.dart';

void main() {
  late RouterPasswordNotifier mockRouterPasswordNotifier;
  late TimezoneNotifier mockTimezoneNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockRouterPasswordNotifier = MockRouterPasswordNotifier();
    mockTimezoneNotifier = MockTimezoneNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();

    when(mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    when(mockTimezoneNotifier.build())
        .thenReturn(TimezoneState.fromMap(timezoneTestState));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockRouterPasswordNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
    when(mockTimezoneNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
  });

  testLocalizations('Instant admin view', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const InstantAdminView(),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);
  });

  testLocalizations('Instant admin view - router password edit modal',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const InstantAdminView(),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);

    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant admin view - timezone', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    // await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  });

  testLocalizations('Instant admin view - timezone scroll down 1 - mobile',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -500));

    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant admin view - timezone scroll down 2 - mobile',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -1000));

    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant admin view - timezone scroll down 3 - mobile',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -1500));

    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant admin view - timezone scroll down 4 - mobile',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -2000));

    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant admin view - timezone scroll down 5 - mobile',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll
    await gesture.moveBy(const Offset(0, -2500));

    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant admin view - timezone scroll down 1 - desktop',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll

    await gesture.moveBy(const Offset(0, -500));
    await gesture.moveBy(const Offset(0, -500));

    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);
  testLocalizations('Instant admin view - timezone scroll down 2 - desktop',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll

    await gesture.moveBy(const Offset(0, -500));
    await gesture.moveBy(const Offset(0, -1000));

    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant admin view - timezone scroll down 3 - desktop',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll

    await gesture.moveBy(const Offset(0, -500));
    await gesture.moveBy(const Offset(0, -1500));

    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant admin view - timezone scroll down 4 - desktop',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll

    await gesture.moveBy(const Offset(0, -500));
    await gesture.moveBy(const Offset(0, -2000));

    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant admin view - timezone scroll down 5 - desktop',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // Manual scroll

    await gesture.moveBy(const Offset(0, -500));
    await gesture.moveBy(const Offset(0, -2500));

    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant admin view - naual firmware update',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const ManualFirmwareUpdateView(),
    );
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  });
}
