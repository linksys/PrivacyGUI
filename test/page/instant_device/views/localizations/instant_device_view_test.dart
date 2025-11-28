import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/device_filter_config_test_state.dart';
import '../../../../test_data/device_filtered_list_test_data.dart';

// View ID: IDVC
// Implementation: lib/page/instant_device/views/instant_device_view.dart
/// | Test ID         | Description                                                                 |
/// | :-------------- | :-------------------------------------------------------------------------- |
/// | `IDVC-ONLINE`   | Desktop layout renders instant devices list with filter card and summary.   |
/// | `IDVC-FILTER`   | Mobile layout exposes DevicesFilter bottom sheet from the Filters button.   |
/// | `IDVC-OFF_EDIT` | Offline filter enables edit mode with selectable rows and delete bar.       |
/// | `IDVC-OFF_DEL`  | Offline edit mode shows confirmation dialog when delete action is invoked.  |
/// | `IDVC-DEAUTH`   | Online mode allows de-authenticating a wireless client through dialog flow. |

final _defaultFilterState =
    DeviceFilterConfigState.fromMap(deviceFilterConfigTestState);
final _onlineDevices =
    deviceFilteredTestData.map((e) => DeviceListItem.fromMap(e)).toList();
final _offlineDevices = deviceFilteredOfflineTestData
    .map((e) => DeviceListItem.fromMap(e))
    .toList();

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  Future<BuildContext> pumpInstantDeviceView(
    WidgetTester tester,
    LocalizedScreen screen, {
    List<DeviceListItem>? devices,
    DeviceFilterConfigState? filterState,
    bool useShell = false,
  }) async {
    when(testHelper.mockDeviceFilterConfigNotifier.build()).thenReturn(
      filterState ?? _defaultFilterState,
    );
    final overrides = [
      filteredDeviceListProvider.overrideWith(
        (ref) => devices ?? _onlineDevices,
      ),
    ];
    final pump = useShell ? testHelper.pumpShellView : testHelper.pumpView;
    final context = await pump(
      tester,
      overrides: overrides,
      locale: screen.locale,
      child: const InstantDeviceView(),
    );
    await tester.pumpAndSettle();
    return context;
  }

  // Test ID: IDVC-ONLINE — desktop layout renders base instant device UI
  testLocalizationsV2(
    'instant device view - desktop layout',
    (tester, screen) async {
      final context = await pumpInstantDeviceView(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.instantDevices), findsOneWidget);
      expect(find.text(loc.nDevices(_onlineDevices.length)), findsOneWidget);
      expect(find.byType(DevicesFilterWidget), findsOneWidget);
      expect(find.text(loc.selectAll), findsOneWidget);
      expect(find.byIcon(LinksysIcons.refresh), findsOneWidget);
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDVC-ONLINE-01-layout',
    helper: testHelper,
  );

  // Test ID: IDVC-FILTER — mobile filters button opens DevicesFilter sheet
  testLocalizationsV2(
    'instant device view - mobile filter bottom sheet',
    (tester, screen) async {
      await pumpInstantDeviceView(tester, screen);

      final filterButton =
          find.widgetWithIcon(AppTextButton, LinksysIcons.filter);
      expect(filterButton, findsOneWidget);
      expect(find.byType(DevicesFilterWidget), findsNothing);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      expect(find.byType(DevicesFilterWidget), findsOneWidget);
    },
    screens: responsiveMobileScreens,
    goldenFilename: 'IDVC-FILTER-01-bottom_sheet',
    helper: testHelper,
  );

  // Test ID: IDVC-OFF_EDIT — offline mode enables edit state and selection
  testLocalizationsV2(
    'instant device view - offline edit state',
    (tester, screen) async {
      final context = await pumpInstantDeviceView(
        tester,
        screen,
        devices: _offlineDevices,
        filterState: _defaultFilterState.copyWith(connectionFilter: false),
      );
      final loc = testHelper.loc(context);

      final checkboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard),
        matching: find.byType(AppCheckbox),
      );
      expect(checkboxFinder, findsWidgets);

      await tester.tap(checkboxFinder.first);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppDeviceListCard && widget.isSelected == true,
        ),
        findsWidgets,
      );
      expect(find.byKey(const Key('pageBottomPositiveButton')), findsOneWidget);
      expect(find.text(loc.delete), findsOneWidget);
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDVC-OFF_EDIT-01-selection',
    helper: testHelper,
  );

  // Test ID: IDVC-OFF_DEL — delete action shows confirmation dialog
  testLocalizationsV2(
    'instant device view - offline delete dialog',
    (tester, screen) async {
      final context = await pumpInstantDeviceView(
        tester,
        screen,
        devices: _offlineDevices,
        filterState: _defaultFilterState.copyWith(connectionFilter: false),
      );
      final loc = testHelper.loc(context);

      final checkboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard),
        matching: find.byType(AppCheckbox),
      );
      await tester.tap(checkboxFinder.first);
      await tester.pumpAndSettle();

      final deleteButton = find.byKey(const Key('pageBottomPositiveButton'));
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(
        find.text(loc.nDevicesDeleteDevicesTitle(1)),
        findsOneWidget,
      );
      expect(
        find.text(loc.nDevicesDeleteDevicesDescription(1)),
        findsOneWidget,
      );
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDVC-OFF_DEL-01-dialog',
    helper: testHelper,
  );

  // Test ID: IDVC-DEAUTH — deauth button opens confirmation dialog
  testLocalizationsV2(
    'instant device view - deauth dialog',
    (tester, screen) async {
      final context = await pumpInstantDeviceView(
        tester,
        screen,
        useShell: true,
      );
      final loc = testHelper.loc(context);

      final deauthButton = find.descendant(
        of: find.byType(AppDeviceListCard),
        matching: find.byIcon(LinksysIcons.bidirectional),
      );
      expect(deauthButton, findsWidgets);

      await tester.tap(deauthButton.first);
      await tester.pumpAndSettle();

      expect(find.text(loc.disconnectClient), findsOneWidget);
      expect(find.text(loc.disconnect), findsAtLeastNWidgets(1));
    },
    screens: responsiveDesktopScreens,
    goldenFilename: 'IDVC-DEAUTH-01-dialog',
    helper: testHelper,
  );
}
