import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

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

  // #1637: the switch's tile shows a spinner while its event runs and has no
  // finally, so an event that threw left it spinning for good.
  testWidgets('a failed policy change ends the spinner', (tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routerPassword = MockRouterPasswordNotifier();
    final timezone = MockTimezoneNotifier();
    final firmware = MockFirmwareUpdateNotifier();
    final powerTable = MockPowerTableNotifier();
    when(routerPassword.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    when(routerPassword.fetch()).thenAnswer((_) async {});
    when(timezone.build()).thenReturn(TimezoneState.fromMap(timezoneTestState));
    when(timezone.fetch()).thenAnswer((_) async {});
    when(firmware.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(firmware.setFirmwareUpdatePolicy(any)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw Exception('save failed');
    });
    when(powerTable.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: false));

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        routerPasswordProvider.overrideWith(() => routerPassword),
        timezoneProvider.overrideWith(() => timezone),
        firmwareUpdateProvider.overrideWith(() => firmware),
        powerTableProvider.overrideWith(() => powerTable),
      ],
      child: const InstantAdminView(),
    ));
    await tester.pumpAndSettle();
    final toggle = find.byWidgetPredicate((w) =>
        w is AppSwitch && w.semanticLabel == 'auto firmware update switch');
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'the tile spun for good after its event threw');
    expect(toggle, findsOneWidget, reason: 'the switch is back');
  });
}
