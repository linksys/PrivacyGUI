import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/device_details_test_state.dart';
import '../../../../test_data/local_network_settings_state.dart';

// View ID: IDDV
// Implementation: lib/page/instant_device/views/device_detail_view.dart
/// | Test ID        | Description                                                                 |
/// | :------------- | :-------------------------------------------------------------------------- |
/// | `IDDV-ONLINE`  | Online wireless device renders avatar card, connection info, and IP button. |
/// | `IDDV-EDIT`    | Edit dialog enforces non-empty and max-length validations.                  |
/// | `IDDV-RESERVE` | Reserve IP action exposes confirmation dialog with localized copy.          |
/// | `IDDV-RELEASE` | Already reserved devices expose release flow with proper messaging.         |
/// | `IDDV-MLO`     | MLO-capable clients show CTA and informational modal.                       |

final _deviceDetailScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1080)),
  ...responsiveDesktopScreens,
];

final _defaultExternalState =
    ExternalDeviceDetailState.fromMap(deviceDetailsTestState1);
final _defaultNetworkState =
    LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);

LocalNetworkSettingsState _networkStateWithReservation() {
  final reservation = DHCPReservationUIModel(
    macAddress: _defaultExternalState.item.macAddress,
    ipAddress: _defaultExternalState.item.ipv4Address,
    description: 'Reserved device',
  );
  return _defaultNetworkState.copyWith(
    status: _defaultNetworkState.status
        .copyWith(dhcpReservationList: [reservation]),
  );
}

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  Future<BuildContext> pumpDeviceDetailView(
    WidgetTester tester,
    LocalizedScreen screen, {
    ExternalDeviceDetailState? externalState,
    LocalNetworkSettingsState? networkState,
  }) async {
    when(testHelper.mockExternalDeviceDetailNotifier.build())
        .thenReturn(externalState ?? _defaultExternalState);
    when(testHelper.mockLocalNetworkSettingsNotifier.build())
        .thenReturn(networkState ?? _defaultNetworkState);
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(
      forceRemote: anyNamed('forceRemote'),
      updateStatusOnly: anyNamed('updateStatusOnly'),
    )).thenAnswer((_) async => networkState ?? _defaultNetworkState);

    final context = await testHelper.pumpView(
      tester,
      child: const DeviceDetailView(),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();
    return context;
  }

  // Test ID: IDDV-ONLINE — verify layout for online wireless device
  testLocalizations(
    'device detail view - online wireless summary',
    (tester, screen) async {
      final context = await pumpDeviceDetailView(tester, screen);
      final loc = testHelper.loc(context);
      final item = _defaultExternalState.item;

      expect(find.text(item.name), findsNWidgets(2));
      expect(find.text(loc.manufacturer), findsOneWidget);
      expect(find.text(item.manufacturer), findsOneWidget);
      expect(find.text(loc.device), findsOneWidget);
      expect(find.text(item.model), findsOneWidget);
      expect(find.text(loc.connectTo), findsOneWidget);
      expect(find.text(item.upstreamDevice), findsOneWidget);
      expect(find.text(loc.ssid), findsOneWidget);
      expect(find.text('${item.ssid} • ${item.band}'), findsOneWidget);
      expect(find.text(loc.signalStrength), findsOneWidget);
      expect(find.textContaining('${item.signalStrength}'), findsWidgets);
      expect(find.text(loc.ipAddress), findsOneWidget);
      expect(find.text(item.ipv4Address), findsOneWidget);
      expect(find.text(loc.reserveIp), findsOneWidget);
      expect(find.byIcon(AppFontIcons.edit), findsOneWidget);
    },
    screens: _deviceDetailScreens,
    goldenFilename: 'IDDV-ONLINE-01-layout',
    helper: testHelper,
  );

  // Test ID: IDDV-EDIT — edit modal validation states
  testLocalizations(
    'device detail view - edit modal validations',
    (tester, screen) async {
      final context = await pumpDeviceDetailView(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.byIcon(AppFontIcons.edit));
      await tester.pumpAndSettle();

      final inputFinder = find.byType(AppTextFormField).first;
      await tester.enterText(inputFinder, '');
      await tester.pumpAndSettle();
      expect(find.text(loc.theNameMustNotBeEmpty), findsOneWidget);
      await testHelper.takeScreenshot(
        tester,
        'IDDV-EDIT-01-empty_error',
      );

      await tester.enterText(
        inputFinder,
        'm' * 260,
      );
      await tester.pumpAndSettle();
      expect(find.text(loc.deviceNameExceedMaxSize), findsOneWidget);
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDDV-EDIT-02-max_error',
    helper: testHelper,
  );

  // Test ID: IDDV-RESERVE — reserve IP dialog
  testLocalizations(
    'device detail view - reserve ip dialog',
    (tester, screen) async {
      final context = await pumpDeviceDetailView(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.text(loc.reserveIp));
      await tester.pumpAndSettle();

      expect(find.text(loc.reserveIp), findsAtLeastNWidgets(1));
      expect(find.text(loc.reservedIpDescription), findsOneWidget);
      expect(find.text(loc.cancel), findsOneWidget);
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDDV-RESERVE-01-dialog',
    helper: testHelper,
  );

  // Test ID: IDDV-RELEASE — release IP dialog for reserved clients
  testLocalizations(
    'device detail view - release ip dialog',
    (tester, screen) async {
      final context = await pumpDeviceDetailView(
        tester,
        screen,
        networkState: _networkStateWithReservation(),
      );
      final loc = testHelper.loc(context);

      await tester.tap(find.text(loc.releaseReservedIp));
      await tester.pumpAndSettle();

      expect(find.text(loc.releaseReservedIp), findsAtLeastNWidgets(1));
      expect(find.text(loc.releaseReservedIpDescription), findsOneWidget);
      expect(find.text(loc.cancel), findsOneWidget);
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDDV-RELEASE-01-dialog',
    helper: testHelper,
  );

  // Test ID: IDDV-MLO — show MLO CTA and modal
  testLocalizations(
    'device detail view - mlo capable modal',
    (tester, screen) async {
      final context = await pumpDeviceDetailView(
        tester,
        screen,
        externalState: _defaultExternalState.copyWith(
          item: _defaultExternalState.item.copyWith(isMLO: true),
        ),
      );
      final loc = testHelper.loc(context);

      final mloButton = find.text(loc.mloCapable);
      expect(mloButton, findsOneWidget);

      await tester.tap(mloButton);
      await tester.pumpAndSettle();
      expect(find.text(loc.mlo), findsOneWidget);
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDDV-MLO-01-modal',
    helper: testHelper,
  );
}
