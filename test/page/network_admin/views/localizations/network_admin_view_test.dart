import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/network_admin/_network_admin.dart';
import 'package:privacy_gui/page/network_admin/providers/_providers.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/firmware_update_test_state.dart';
import '../../../../test_data/router_password_test_state.dart';
import '../../../../test_data/timezone_test_state.dart';
import '../../../firmware_update/firmware_update_detail_view_test_mocks.dart';
import '../../network_admin_view_test_mocks.dart';

@GenerateNiceMocks([
  MockSpec<RouterPasswordNotifier>(),
  MockSpec<TimezoneNotifier>(),
])
void main() {
  late RouterPasswordNotifier mockRouterPasswordNotifier;
  late TimezoneNotifier mockTimezoneNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;

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

  testLocalizations('Network admin view', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const NetworkAdminView(),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);
  });

  testLocalizations('Network admin view - router password edit modal',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const NetworkAdminView(),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);

    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Network admin view - timezone', (tester, locale) async {
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

  testLocalizations('Network admin view - timezone scroll down 1 - mobile',
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

  testLocalizations('Network admin view - timezone scroll down 2 - mobile',
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

  testLocalizations('Network admin view - timezone scroll down 3 - mobile',
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

    testLocalizations('Network admin view - timezone scroll down 4 - mobile',
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

      testLocalizations('Network admin view - timezone scroll down 5 - mobile',
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

  testLocalizations('Network admin view - timezone scroll down 1 - desktop',
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
  testLocalizations('Network admin view - timezone scroll down 2 - desktop',
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

    testLocalizations('Network admin view - timezone scroll down 3 - desktop',
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

    testLocalizations('Network admin view - timezone scroll down 4 - desktop',
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

    testLocalizations('Network admin view - timezone scroll down 5 - desktop',
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
}
