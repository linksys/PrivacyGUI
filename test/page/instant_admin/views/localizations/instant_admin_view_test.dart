import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/jnap_service_supported_mocks.dart';
import '../../../../mocks/power_table_notifier_mocks.dart';
import '../../../../mocks/router_password_notifier_mocks.dart';
import '../../../../test_data/firmware_update_test_state.dart';
import '../../../../test_data/power_table_test_state.dart';
import '../../../../test_data/router_password_test_state.dart';
import '../../../../test_data/timezone_test_state.dart';
import '../../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../../mocks/timezone_notifier_mocks.dart';

void main() {
  late RouterPasswordNotifier mockRouterPasswordNotifier;
  late TimezoneNotifier mockTimezoneNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late PowerTableNotifier mockPowerTableNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockRouterPasswordNotifier = MockRouterPasswordNotifier();
    mockTimezoneNotifier = MockTimezoneNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockPowerTableNotifier = MockPowerTableNotifier();

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
    when(mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: false));
  });

  testLocalizations('Instant-Admin view', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
      ],
      locale: locale,
      child: const InstantAdminView(),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);
  });

  testLocalizations('Instant-Admin view - router password edit modal',
      (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
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

  testLocalizations('Instant-Admin view - timezone', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    // await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 3180)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 3180)),
  ]);

  testLocalizations('Instant-Admin view - region transmit enabled',
      (tester, locale) async {
    when(mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: true));
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
      ],
      locale: locale,
      child: const InstantAdminView(),
    );
    // await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens,
    ...responsiveDesktopScreens,
  ]);

  testLocalizations('Instant-Admin view - region transmit selection dialog',
      (tester, locale) async {
    when(mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: true));
    final widget = testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
      ],
      locale: locale,
      child: const InstantAdminView(),
    );
    // await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppCard).last);
    await tester.pumpAndSettle();

  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2040)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 2040)),
  ]);
}
