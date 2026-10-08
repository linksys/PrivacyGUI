import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/external_device_detail_notifier_mocks.dart';
import '../../../mocks/local_network_settings_notifier_mocks.dart';
import '../../../test_data/device_details_test_state.dart';
import '../../../test_data/local_network_settings_state.dart';

const _readOnly = AccessPolicy(canWrite: false);

void main() {
  mockDependencyRegister();

  Future<void> pumpDetail(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full,
      List<DHCPReservation>? reservations}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final device = MockExternalDeviceDetailNotifier();
    final localNetwork = MockLocalNetworkSettingsNotifier();
    when(device.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    final settings =
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    when(localNetwork.build()).thenReturn(reservations == null
        ? settings
        : settings.copyWith(dhcpReservationList: reservations));

    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        localNetworkSettingProvider.overrideWith(() => localNetwork),
        externalDeviceDetailProvider.overrideWith(() => device),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const DeviceDetailView(),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: renaming a device saves its new name and icon to the router, so the
  // edit button is blocked before it opens the dialog.
  group('device name edit', () {
    Future<void> tapEdit(WidgetTester tester) async {
      await tester.tap(find.byIcon(LinksysIcons.edit), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('does not open in read-only mode', (tester) async {
      await pumpDetail(tester, policy: _readOnly);

      await tapEdit(tester);

      expect(find.text('Device Name and Icon'), findsNothing);
    });

    testWidgets('opens with full access', (tester) async {
      await pumpDetail(tester);

      await tapEdit(tester);

      expect(find.text('Device Name and Icon'), findsOneWidget);
    });
  });

  // #1637: reserving an IP, or releasing a reserved one, saves the DHCP
  // reservation list to the router. Both are blocked before the confirm dialog.
  group('IP reservation', () {
    const description =
        'Reserving DHCP means your device will always be assigned to this '
        'specific IP address.';
    final reserved = [
      const DHCPReservation(
        macAddress: '3C:22:FB:E4:4F:18',
        ipAddress: '10.216.1.30',
        description: 'ASTWP-29134',
      ),
    ];

    Future<void> tapButton(WidgetTester tester, String label) async {
      await tester.tap(find.text(label), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('reserve does not ask in read-only mode', (tester) async {
      await pumpDetail(tester, policy: _readOnly);

      await tapButton(tester, 'Reserve IP');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(description), findsNothing);
    });

    testWidgets('reserve asks with full access', (tester) async {
      await pumpDetail(tester);

      await tapButton(tester, 'Reserve IP');

      expect(find.text(description), findsOneWidget);
    });

    testWidgets('release does not ask in read-only mode', (tester) async {
      await pumpDetail(tester, policy: _readOnly, reservations: reserved);

      await tapButton(tester, 'Release Reserved IP');

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('release asks with full access', (tester) async {
      await pumpDetail(tester, reservations: reserved);

      await tapButton(tester, 'Release Reserved IP');

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
