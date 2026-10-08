import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
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

const _guardTooltip = 'This feature is unavailable in remote mode';
const _manualUpdatePage = Key('manualUpdatePage');

void main() {
  mockDependencyRegister();

  late MockPowerTableNotifier powerTable;

  Future<void> pumpAdmin(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full,
      bool remoteLogin = false}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routerPassword = MockRouterPasswordNotifier();
    final timezone = MockTimezoneNotifier();
    final firmware = MockFirmwareUpdateNotifier();
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
            .copyWith(isPowerTableSelectable: true));

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        routerPasswordProvider.overrideWith(() => routerPassword),
        timezoneProvider.overrideWith(() => timezone),
        firmwareUpdateProvider.overrideWith(() => firmware),
        powerTableProvider.overrideWith(() => powerTable),
        accessPolicyProvider.overrideWithValue(policy),
        isRemoteLoginProvider.overrideWithValue(remoteLogin),
      ],
      child: const InstantAdminView(),
      extraRoutes: [
        LinksysRoute(
          name: RouteNamed.manualFirmwareUpdate,
          path: '/manual-firmware-update',
          builder: (context, state) =>
              const SizedBox.shrink(key: _manualUpdatePage),
        ),
      ],
    ));
    await tester.pumpAndSettle();
  }

  // #1637: the manual update page uploads a firmware file to the router's
  // local address directly, which no remote session can reach, so the button
  // is local-only: any remote login is kept off that page, full access or not.
  group('manual firmware update', () {
    final manualUpdate = find.byKey(const Key('manualUpdateButton'));

    testWidgets('is blocked on a remote login, even with full access',
        (tester) async {
      await pumpAdmin(tester, remoteLogin: true);

      expect(
          find.ancestor(
              of: manualUpdate, matching: find.byTooltip(_guardTooltip)),
          findsOneWidget);

      await tester.tap(manualUpdate, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(_manualUpdatePage), findsNothing);
    });

    testWidgets('opens the manual update page on a local login',
        (tester) async {
      await pumpAdmin(tester);

      await tester.tap(manualUpdate);
      await tester.pumpAndSettle();

      expect(find.byKey(_manualUpdatePage), findsOneWidget);
    });
  });

  // #1637: picking a transmit region saves it to the router, so in read-only
  // mode the card no longer opens the region list, while the region it shows
  // stays readable.
  group('transmit region', () {
    final regionCard = find.text('Transmit Region');
    // Only the region dialog lists the other countries; the list is lazy, so
    // look for the first one.
    final regionDialog = find.text('Asia - China');

    testWidgets('does not open the region list in read-only mode',
        (tester) async {
      await pumpAdmin(tester, policy: const AccessPolicy(canWrite: false));

      // The chevron says why the card does nothing.
      final chevron = find.descendant(
          of: find.widgetWithText(AppListCard, 'Transmit Region'),
          matching: find.byIcon(LinksysIcons.chevronRight));
      expect(
          find.ancestor(of: chevron, matching: find.byTooltip(_guardTooltip)),
          findsOneWidget);

      await tester.tap(regionCard, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(regionDialog, findsNothing);
      verifyNever(powerTable.save(any));
    });

    testWidgets('opens the region list with full access', (tester) async {
      await pumpAdmin(tester);

      await tester.tap(regionCard);
      await tester.pumpAndSettle();

      expect(regionDialog, findsOneWidget);
    });
  });
}
