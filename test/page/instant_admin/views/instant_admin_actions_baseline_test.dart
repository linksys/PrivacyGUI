// Baseline for Instant Admin's direct write controls in the default build.
//
// Two controls here save without a Save button: the auto firmware update switch
// saves the moment it is flipped, and Transmit Region saves when its picker is
// confirmed. A read-only build has to disable both individually. These tests pin
// that in the default build both are live and reach their save, and that manual
// firmware update is enabled - it is gated today only for the force=remote
// build, which the default build is not.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

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
  late MockRouterPasswordNotifier mockRouterPasswordNotifier;
  late MockTimezoneNotifier mockTimezoneNotifier;
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late MockPowerTableNotifier mockPowerTableNotifier;

  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockRouterPasswordNotifier = MockRouterPasswordNotifier();
    mockTimezoneNotifier = MockTimezoneNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockPowerTableNotifier = MockPowerTableNotifier();

    when(mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    when(mockRouterPasswordNotifier.fetch()).thenAnswer((_) async {});
    when(mockTimezoneNotifier.build())
        .thenReturn(TimezoneState.fromMap(timezoneTestState));
    when(mockTimezoneNotifier.fetch()).thenAnswer((_) async {});
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockFirmwareUpdateNotifier.setFirmwareUpdatePolicy(any))
        .thenAnswer((_) async {});
    final powerTable = PowerTableState.fromMap(powerTableTestState);
    when(mockPowerTableNotifier.build()).thenReturn(powerTable);
    when(mockPowerTableNotifier.save(any)).thenAnswer((_) async => powerTable);
  });

  tearDown(() => reset(mockServiceHelper));

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
      ],
      child: const InstantAdminView(),
    ));
    await tester.pumpAndSettle();
  }

  testResponsiveWidgets('auto firmware update saves as soon as it is flipped',
      (tester) async {
    await pump(tester);

    final tile = find.byType(AppSwitchTriggerTile).first;
    await tester.ensureVisible(tile);
    await tester.tap(find.descendant(of: tile, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    verify(mockFirmwareUpdateNotifier.setFirmwareUpdatePolicy(any)).called(1);
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('transmit region saves the confirmed country',
      (tester) async {
    await pump(tester);

    final card = find.widgetWithText(AppListCard, 'Transmit Region');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    verifyNever(mockPowerTableNotifier.save(any));

    await tester.tap(find.widgetWithText(AppTextButton, 'Ok'));
    await tester.pumpAndSettle();
    verify(mockPowerTableNotifier.save(any)).called(1);
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('cancelling transmit region saves nothing',
      (tester) async {
    await pump(tester);

    final card = find.widgetWithText(AppListCard, 'Transmit Region');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await tester.pumpAndSettle();
    verifyNever(mockPowerTableNotifier.save(any));
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets('manual firmware update is enabled locally',
      (tester) async {
    expect(BuildConfig.isRemote(), isFalse);
    await pump(tester);

    final button = find.byKey(const Key('manualUpdateButton'));
    await tester.ensureVisible(button);
    expect(tester.widget<AppTextButton>(button).onTap, isNotNull);
  }, variants: responsiveDesktopVariants);
}
