import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/power_table_test_state.dart';
import '../../../../test_data/timezone_test_state.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();

    when(testHelper.mockRouterPasswordNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
    });
    when(testHelper.mockTimezoneNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return TimezoneState.fromMap(timezoneTestState);
    });
  });

  testLocalizations('Instant-Admin view', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const InstantAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 2));
  }, screens: screens);

  testLocalizations('Instant-Admin view - router password edit modal',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const InstantAdminView(),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 2));

    final editFinder = find.byIcon(LinksysIcons.edit);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
  }, screens: screens);

  testLocalizations('Instant-Admin view - timezone', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const TimezoneView(),
      locale: locale,
    );

    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 3780)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 3780)),
  ]);

  testLocalizations('Instant-Admin view - region transmit enabled',
      (tester, locale) async {
    when(testHelper.mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: true));
    await testHelper.pumpView(
      tester,
      child: const InstantAdminView(),
      locale: locale,
    );

    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens,
    ...responsiveDesktopScreens,
  ]);

  testLocalizations('Instant-Admin view - region transmit selection dialog',
      (tester, locale) async {
    when(testHelper.mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: true));
    await testHelper.pumpView(
      tester,
      child: const InstantAdminView(),
      locale: locale,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppCard).last);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2040)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 2040)),
  ]);
}