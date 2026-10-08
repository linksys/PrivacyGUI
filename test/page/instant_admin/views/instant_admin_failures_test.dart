import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
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

  late MockRouterPasswordNotifier routerPassword;
  late MockFirmwareUpdateNotifier firmware;
  late MockPowerTableNotifier powerTable;

  Future<void> pumpAdmin(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full,
      bool powerTableSelectable = false}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    routerPassword = MockRouterPasswordNotifier();
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
    when(powerTable.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: powerTableSelectable));

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        routerPasswordProvider.overrideWith(() => routerPassword),
        timezoneProvider.overrideWith(() => timezone),
        firmwareUpdateProvider.overrideWith(() => firmware),
        powerTableProvider.overrideWith(() => powerTable),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const InstantAdminView(),
    ));
    await tester.pumpAndSettle();
  }

  /// Opens the password dialog, fills in a valid new password, and saves.
  Future<void> changePassword(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('passwordCard')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('newPasswordField')), 'Linksys123!@#');
    await tester.enterText(
        find.byKey(const Key('confirmPasswordField')), 'Linksys123!@#');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> failPasswordWith(Object error) async {
    when(routerPassword.setAdminPasswordWithCredentials(any, any))
        .thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw error;
    });
  }

  // #1637: the switch's tile shows a spinner while its event runs and has no
  // finally, so an event that threw left it spinning for good.
  testWidgets('a failed policy change ends the spinner', (tester) async {
    await pumpAdmin(tester);
    when(firmware.setFirmwareUpdatePolicy(any)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      throw Exception('save failed');
    });
    final toggle = find.byWidgetPredicate((w) =>
        w is AppSwitch && w.semanticLabel == 'auto firmware update switch');
    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'the tile spun for good after its event threw');
    expect(toggle, findsOneWidget, reason: 'the switch is back');
  });

  // The password dialog said "Invalid admin password" for every failure, a
  // network error or a read-only refusal included. Only that error says so now.
  group('a failed password change', () {
    testWidgets('says the password is invalid when it is', (tester) async {
      await pumpAdmin(tester);
      await failPasswordWith(
          const JNAPError(result: 'ErrorInvalidAdminPassword'));

      await changePassword(tester);

      expect(find.text('Invalid admin password'), findsOneWidget);
    });

    testWidgets('does not blame the password for anything else',
        (tester) async {
      await pumpAdmin(tester);
      await failPasswordWith(const JNAPError(result: 'ErrorInvalidIPAddress'));

      await changePassword(tester);

      expect(find.text('Invalid admin password'), findsNothing);
      expect(find.text('Invalid IP address'), findsOneWidget);
    });

    testWidgets('adds nothing to a read-only refusal', (tester) async {
      await pumpAdmin(tester);
      await failPasswordWith(
          const ReadOnlyAccessException(JNAPAction.coreSetAdminPassword));

      await changePassword(tester);

      expect(find.text('Invalid admin password'), findsNothing,
          reason: 'the app root explains a refusal; the page adds nothing');
    });
  });

  // The transmit region said "Failed!" for every failure.
  group('a failed transmit region change', () {
    Future<void> changeRegion(WidgetTester tester, Object error) async {
      await pumpAdmin(tester, powerTableSelectable: true);
      when(powerTable.save(any)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        throw error;
      });
      await tester.tap(find.text('Transmit Region'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asia - China'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ok'));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('a known error code gets its own message', (tester) async {
      await changeRegion(
          tester, const JNAPError(result: 'ErrorInvalidIPAddress'));

      expect(find.text('Invalid IP address'), findsOneWidget);
    });

    testWidgets('adds nothing to a read-only refusal', (tester) async {
      await changeRegion(tester,
          const ReadOnlyAccessException(JNAPAction.setPowerTableSettings));

      expect(find.byType(SnackBar), findsNothing,
          reason: 'the app root explains a refusal; the page adds nothing');
    });
  });

  // #1637: each write on this page is blocked before it is sent, while the
  // values it shows stay readable.
  group('read-only mode', () {
    const readOnly = AccessPolicy(canWrite: false);

    testWidgets('does not open the password change dialog', (tester) async {
      await pumpAdmin(tester, policy: readOnly);

      await tester.tap(find.byKey(const Key('passwordCard')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('newPasswordField')), findsNothing);
    });

    testWidgets('blocks the auto firmware update switch', (tester) async {
      await pumpAdmin(tester, policy: readOnly);
      final toggle = find.byWidgetPredicate((w) =>
          w is AppSwitch && w.semanticLabel == 'auto firmware update switch');

      await tester.tap(toggle, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      verifyNever(firmware.setFirmwareUpdatePolicy(any));
    });
  });
}
