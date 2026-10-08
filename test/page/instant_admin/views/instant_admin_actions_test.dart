// Instant Admin's direct write controls with full access on a local login.
//
// Two controls here save without a Save button: the auto firmware update switch
// saves the moment it is flipped, and Transmit Region saves when its picker is
// confirmed. These tests pin that both reach their save, that cancelling the
// picker saves nothing, and that manual firmware update is not blocked on a
// local login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../mocks/power_table_notifier_mocks.dart';
import '../../../mocks/router_password_notifier_mocks.dart';
import '../../../mocks/timezone_notifier_mocks.dart';
import '../../../test_data/firmware_update_test_state.dart';
import '../../../test_data/power_table_test_state.dart';
import '../../../test_data/router_password_test_state.dart';
import '../../../test_data/timezone_test_state.dart';

void main() {
  mockDependencyRegister();

  late MockFirmwareUpdateNotifier firmware;
  late MockPowerTableNotifier powerTable;

  Future<void> pumpAdmin(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routerPassword = MockRouterPasswordNotifier();
    final timezone = MockTimezoneNotifier();
    firmware = MockFirmwareUpdateNotifier();
    powerTable = MockPowerTableNotifier();
    when(routerPassword.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    when(routerPassword.fetch()).thenAnswer((_) async {});
    when(timezone.build()).thenReturn(TimezoneState.fromMap(timezoneTestState));
    when(timezone.fetch()).thenAnswer((_) async {});
    when(firmware.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(firmware.setFirmwareUpdatePolicy(any)).thenAnswer((_) async {});
    final regions = PowerTableState.fromMap(powerTableTestState);
    when(powerTable.build()).thenReturn(regions);
    when(powerTable.save(any)).thenAnswer((_) async => regions);

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        routerPasswordProvider.overrideWith(() => routerPassword),
        timezoneProvider.overrideWith(() => timezone),
        firmwareUpdateProvider.overrideWith(() => firmware),
        powerTableProvider.overrideWith(() => powerTable),
        accessPolicyProvider.overrideWithValue(AccessPolicy.full),
        isRemoteLoginProvider.overrideWithValue(false),
      ],
      child: const InstantAdminView(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('auto firmware update saves as soon as it is flipped',
      (tester) async {
    await pumpAdmin(tester);

    await tester.tap(find.byWidgetPredicate((w) =>
        w is AppSwitch && w.semanticLabel == 'auto firmware update switch'));
    await tester.pumpAndSettle();

    verify(firmware.setFirmwareUpdatePolicy(any)).called(1);
  });

  group('transmit region', () {
    final regionCard = find.widgetWithText(AppListCard, 'Transmit Region');

    // Opening the picker saves nothing; only Ok does.
    testWidgets('saves the confirmed country', (tester) async {
      await pumpAdmin(tester);

      await tester.tap(regionCard);
      await tester.pumpAndSettle();
      verifyNever(powerTable.save(any));

      await tester.tap(find.widgetWithText(AppTextButton, 'Ok'));
      await tester.pumpAndSettle();

      // Nothing else was picked, so the current region is the one confirmed.
      verify(powerTable.save(PowerTableCountries.twn)).called(1);
    });

    testWidgets('saves nothing when cancelled', (tester) async {
      await pumpAdmin(tester);

      await tester.tap(regionCard);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(powerTable.save(any));
    });
  });

  testWidgets('manual firmware update is enabled locally', (tester) async {
    await pumpAdmin(tester);

    final manualUpdate = find.byKey(const Key('manualUpdateButton'));
    expect(tester.widget<AppTextButton>(manualUpdate).onTap, isNotNull);
    expect(
        find.ancestor(
            of: manualUpdate,
            matching:
                find.byTooltip('This feature is unavailable in remote mode')),
        findsNothing);
  });
}
