import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../common/config.dart';
import '../../../common/screen.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/device_filter_config_test_state.dart';
import '../../../test_data/device_filtered_list_test_data.dart';
import '../../../test_data/node_details_data.dart';

// View ID: NDVL
// Implementation: lib/page/nodes/views/node_detail_view.dart
/// | Test ID             | Description                                                                      |
/// | :------------------ | :------------------------------------------------------------------------------- |
/// | `NDVL-INFO`         | Desktop info tab shows node summary, firmware status, and connected devices.     |
/// | `NDVL-MOBILE`       | Mobile layout switches between Info and Devices tabs correctly.                  |
/// | `NDVL-MLO`          | Nodes flagged as MLO display the badge and modal explaining the capability.      |
/// | `NDVL-LIGHTS`       | Node light settings card opens the LED mode dialog with toggles.                 |
/// | `NDVL-EDIT`         | Edit name dialog enforces empty validation with blink control.                   |
/// | `NDVL-EDIT_LONG`    | Edit name dialog shows error when the name exceeds the max length.               |

final _desktopScreens = responsiveDesktopScreens
    .map((screen) => screen.copyWith(height: 1400))
    .toList();
final _mobileScreens = responsiveMobileScreens
    .map((screen) => screen.copyWith(height: 1280))
    .toList();

final _defaultFilterState =
    DeviceFilterConfigState.fromMap(deviceFilterConfigTestState);
final _masterState = NodeDetailState.fromMap(nodeDetailsCherry7TestState);
final _slaveState = NodeDetailState.fromMap(fakeNodeDetailsState2);
final _deviceList =
    deviceFilteredTestData.map((e) => DeviceListItem.fromMap(e)).toList();
final _singleDeviceList = deviceFilteredTestData
    .map((e) => DeviceListItem.fromMap(e))
    .take(1)
    .toList();

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  Future<BuildContext> pumpNodeDetailView(
    WidgetTester tester,
    LocalizedScreen screen, {
    NodeDetailState? nodeState,
    List<DeviceListItem>? devices,
    DeviceFilterConfigState? filterState,
    FirmwareUpdateState? firmwareState,
  }) async {
    when(testHelper.mockNodeDetailNotifier.build())
        .thenReturn(nodeState ?? _masterState);
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(firmwareState ?? FirmwareUpdateState.empty());
    when(testHelper.mockDeviceFilterConfigNotifier.build())
        .thenReturn(filterState ?? _defaultFilterState);

    final context = await testHelper.pumpShellView(
      tester,
      locale: screen.locale,
      child: const NodeDetailView(),
      overrides: [
        filteredDeviceListProvider.overrideWith(
          (ref) => devices ?? _deviceList,
        ),
      ],
    );

    await tester.runAsync(() async {
      final element = tester.element(find.byType(NodeDetailView));
      final theme = CustomTheme.of(element);
      final iconName = routerIconTestByModel(
          modelNumber: (nodeState ?? _masterState).modelNumber);
      await precacheImage(theme.getRouterImage(iconName), element);
    });
    await tester.pumpAndSettle();
    return context;
  }

  // Test ID: NDVL-INFO — desktop info tab layout with devices list
  testLocalizationsV2(
    'node detail view - desktop info layout',
    (tester, screen) async {
      final context = await pumpNodeDetailView(
        tester,
        screen,
        devices: _deviceList,
        nodeState: _masterState,
      );
      final loc = testHelper.loc(context);

      expect(find.text(_masterState.location), findsWidgets);
      expect(find.text(loc.connectTo), findsWidgets);
      expect(find.text(loc.firmwareVersion), findsOneWidget);
      expect(find.text(loc.nDevices(_deviceList.length)), findsOneWidget);
      expect(find.text(loc.filters), findsWidgets);
      expect(find.text(loc.refresh), findsOneWidget);
    },
    screens: _desktopScreens,
    goldenFilename: 'NDVL-INFO-01-desktop',
    helper: testHelper,
  );

  // Test ID: NDVL-MOBILE — verify mobile tab navigation
  testLocalizationsV2(
    'node detail view - mobile tabs',
    (tester, screen) async {
      final context = await pumpNodeDetailView(
        tester,
        screen,
        devices: _singleDeviceList,
      );
      final loc = testHelper.loc(context);

      await tester.tap(find.text(loc.devices));
      await tester.pumpAndSettle();

      expect(find.text(loc.nDevices(_singleDeviceList.length)), findsOneWidget);
      // expect(find.text(loc.filters), findsOneWidget);
    },
    screens: _mobileScreens,
    goldenFilename: 'NDVL-MOBILE-01-tabs',
    helper: testHelper,
  );

  // Test ID: NDVL-MLO — show connected with MLO modal
  testLocalizationsV2(
    'node detail view - mlo modal',
    (tester, screen) async {
      final context = await pumpNodeDetailView(
        tester,
        screen,
        nodeState: _slaveState.copyWith(isMLO: true),
      );
      final loc = testHelper.loc(context);

      await tester.tap(find.text(loc.connectedWithMLO));
      await tester.pumpAndSettle();

      expect(find.text(loc.mlo), findsOneWidget);

      await testHelper.takeScreenshot(tester, 'NDVL-MLO-01-dialog');
    },
    screens: _desktopScreens,
    helper: testHelper,
  );

  // Test ID: NDVL-LIGHTS — node light settings dialog
  testLocalizationsV2(
    'node detail view - node light settings dialog',
    (tester, screen) async {
      when(testHelper.mockNodeLightSettingsNotifier.build()).thenReturn(
        const NodeLightSettings(
          isNightModeEnable: true,
          startHour: 20,
          endHour: 8,
          allDayOff: false,
        ),
      );

      final context = await pumpNodeDetailView(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.byKey(const ValueKey('nodeLightSettings')));
      await tester.pumpAndSettle();

      expect(find.text(loc.nodeDetailsLedNightMode), findsOneWidget);
      expect(find.text(loc.lightsOff), findsOneWidget);

      await testHelper.takeScreenshot(tester, 'NDVL-LIGHTS-01-dialog');
    },
    screens: _desktopScreens,
    helper: testHelper,
  );

  // Test ID: NDVL-EDIT — edit name dialog validations
  testLocalizationsV2(
    'node detail view - edit name validations',
    (tester, screen) async {
      when(testHelper.mockServiceHelper.isSupportLedBlinking())
          .thenReturn(true);
      final context = await pumpNodeDetailView(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.byIcon(LinksysIcons.edit).first);
      await tester.pumpAndSettle();

      final nameField = find.bySemanticsLabel('node name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();
      expect(find.text(loc.theNameMustNotBeEmpty), findsOneWidget);
      await testHelper.takeScreenshot(tester, 'NDVL-EDIT-01-empty_error');
    },
    screens: _desktopScreens,
    helper: testHelper,
  );

  // Test ID: NDVL-EDIT_LONG — edit name dialog with overly long input
  testLocalizationsV2(
    'node detail view - edit name too long error',
    (tester, screen) async {
      final context = await pumpNodeDetailView(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.byIcon(LinksysIcons.edit).first);
      await tester.pumpAndSettle();

      final nameField = find.bySemanticsLabel('node name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'n' * 300);
      await tester.pumpAndSettle();

      expect(find.text(loc.deviceNameExceedMaxSize), findsOneWidget);
      await testHelper.takeScreenshot(tester, 'NDVL-EDIT_LONG-01-error');
    },
    screens: _desktopScreens,
    helper: testHelper,
  );
}
