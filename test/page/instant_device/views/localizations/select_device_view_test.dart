// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';

import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

// Corresponding implementation: lib/page/instant_device/views/select_device_view.dart
// View ID: IDSDV

/// | Test ID          | Description                                                                 |
/// | :--------------- | :-------------------------------------------------------------------------- |
/// | `IDSDV-MULTI`    | Verifies multiple selection mode with online and offline devices.           |
/// | `IDSDV-SINGLE`   | Verifies single selection mode where tapping an item pops the view.         |
/// | `IDSDV-SELECT`   | Verifies item selection and deselection in multiple selection mode.         |
/// | `IDSDV-ONLINE`   | Verifies that only online devices are shown when `onlineOnly` is true.      |
/// | `IDSDV-WIRED`    | Verifies that only wired devices are shown when `connection` is `wired`.    |
/// | `IDSDV-IPMAC`    | Verifies the display of both IP and MAC addresses.                          |
/// | `IDSDV-UNSELECT` | Verifies that unselectable items are disabled and have lower opacity.       |

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final testHelper = TestHelper();

  final onlineDevice1 = DeviceListItem(
    name: 'Online Device 1',
    macAddress: 'AA:BB:CC:00:00:01',
    ipv4Address: '192.168.1.101',
    isOnline: true,
    isWired: true,
  );
  final onlineDevice2 = DeviceListItem(
    name: 'Online Device 2',
    macAddress: 'AA:BB:CC:00:00:02',
    ipv4Address: '192.168.1.102',
    isOnline: true,
    isWired: false,
  );
  final offlineDevice = DeviceListItem(
    name: 'Offline Device',
    macAddress: 'AA:BB:CC:00:00:03',
    ipv4Address: '192.168.1.103',
    isOnline: false,
    isWired: true,
  );
  final unselectableDevice = DeviceListItem(
    name: 'Unselectable Device',
    macAddress: '',
    ipv4Address: '',
    isOnline: true,
    isWired: false,
  );

  final allDevices = [
    onlineDevice1,
    onlineDevice2,
    offlineDevice,
    unselectableDevice,
  ];

  setUp(() {
    testHelper.setup();
    when(testHelper.mockDeviceListNotifier.build())
        .thenReturn(DeviceListState(devices: allDevices));
  });

  group('SelectDeviceView', () {
    // Test ID: IDSDV-MULTI
    testLocalizationsV2(
      'should display devices in multiple selection mode',
      (tester, screen) async {
        final context = await testHelper.pumpView(
          tester,
          child: const SelectDeviceView(
            args: {'selectMode': 'multiple', 'type': 'mac'},
          ),
        );

        expect(find.text(testHelper.loc(context).selectDevices), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).onlineDevices), findsOneWidget);
        expect(
            find.text(testHelper.loc(context).offlineDevices), findsOneWidget);
        expect(find.text('Online Device 1'), findsOneWidget);
        expect(find.text('Online Device 2'), findsOneWidget);
        expect(find.text('Offline Device'), findsOneWidget);
        expect(find.text('Unselectable Device'), findsOneWidget);
        expect(find.byType(AppCheckbox), findsNWidgets(4));
        expect(find.text(testHelper.loc(context).nAdd(0)), findsOneWidget);

        await testHelper.takeScreenshot(
          tester,
          'IDSDV-MULTI-01-initial',
        );
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );

    // Test ID: IDSDV-SINGLE
    testLocalizationsV2(
      'should display devices in single selection mode and pop on tap',
      (tester, screen) async {
        final context = await testHelper.pumpView(
          tester,
          child: const SelectDeviceView(
            args: {'selectMode': 'single', 'type': 'ipv4'},
          ),
        );

        expect(find.byType(AppCheckbox), findsNothing);
        expect(find.text('192.168.1.101'), findsOneWidget);

        await testHelper.takeScreenshot(
          tester,
          'IDSDV-SINGLE-01-initial',
        );

        // await tester.tap(find.text('Online Device 1'));
        await tester.pumpAndSettle();
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );

    // Test ID: IDSDV-SELECT
    testLocalizationsV2(
      'should allow selecting and deselecting items',
      (tester, screen) async {
        final context = await testHelper.pumpView(
          tester,
          child: SelectDeviceView(
            args: {
              'selectMode': 'multiple',
              'type': 'mac',
              'selected': [onlineDevice1.macAddress],
            },
          ),
        );

        expect(find.text(testHelper.loc(context).nAdd(1)), findsOneWidget);
        await testHelper.takeScreenshot(
          tester,
          'IDSDV-SELECT-01-preselected',
        );

        await tester.tap(find.descendant(
          of: find.widgetWithText(AppListCard, 'Online Device 1'),
          matching: find.byType(AppCheckbox),
        ));
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).nAdd(0)), findsOneWidget);
        await testHelper.takeScreenshot(
          tester,
          'IDSDV-SELECT-02-deselected',
        );

        await tester.tap(find.descendant(
          of: find.widgetWithText(AppListCard, 'Online Device 2'),
          matching: find.byType(AppCheckbox),
        ));
        await tester.pumpAndSettle();
        expect(find.text(testHelper.loc(context).nAdd(1)), findsOneWidget);
        await testHelper.takeScreenshot(
          tester,
          'IDSDV-SELECT-03-another_selected',
        );
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );

    // Test ID: IDSDV-ONLINE
    testLocalizationsV2(
      'should show only online devices when onlineOnly is true',
      (tester, screen) async {
        final context = await testHelper.pumpView(
          tester,
          child: const SelectDeviceView(
            args: {
              'selectMode': 'multiple',
              'type': 'mac',
              'onlineOnly': true
            },
          ),
        );

        expect(
            find.text(testHelper.loc(context).onlineDevices), findsOneWidget);
        expect(find.text(testHelper.loc(context).offlineDevices), findsNothing);
        expect(find.text('Offline Device'), findsNothing);
        expect(find.text('Online Device 1'), findsOneWidget);

        await testHelper.takeScreenshot(
          tester,
          'IDSDV-ONLINE-01-initial',
        );
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );

    // Test ID: IDSDV-WIRED
    testLocalizationsV2(
      'should show only wired devices when connection is wired',
      (tester, screen) async {
        await testHelper.pumpView(
          tester,
          child: const SelectDeviceView(
            args: {
              'selectMode': 'multiple',
              'type': 'mac',
              'connection': 'wired'
            },
          ),
        );

        expect(find.text('Online Device 1'), findsOneWidget);
        expect(find.text('Online Device 2'), findsNothing);
        expect(find.text('Offline Device'), findsOneWidget);
        expect(find.text('Unselectable Device'), findsNothing);

        await testHelper.takeScreenshot(
          tester,
          'IDSDV-WIRED-01-initial',
        );
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );

    // Test ID: IDSDV-IPMAC
    testLocalizationsV2(
      'should show IP and MAC addresses',
      (tester, screen) async {
        await testHelper.pumpView(
          tester,
          child: const SelectDeviceView(
            args: {'selectMode': 'multiple', 'type': 'ipv4AndMac'},
          ),
        );

        expect(find.text('IP: 192.168.1.101\nMAC: AA:BB:CC:00:00:01'),
            findsOneWidget);

        await testHelper.takeScreenshot(
          tester,
          'IDSDV-IPMAC-01-initial',
        );
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );

    // Test ID: IDSDV-UNSELECT
    testLocalizationsV2(
      'should show unselectable items as disabled',
      (tester, screen) async {
        await testHelper.pumpView(
          tester,
          child: const SelectDeviceView(
            args: {'selectMode': 'multiple', 'type': 'mac'},
          ),
        );

        final card = find.ancestor(
          of: find.text('Unselectable Device'),
          matching: find.byType(AppListCard),
        );
        expect(card, findsOneWidget);

        final cardOpacityFinder =
            find.ancestor(of: card, matching: find.byType(Opacity));
        final cardOpacity =
            tester.widget<Opacity>(cardOpacityFinder.first);
        expect(cardOpacity.opacity, 1.0);

        final checkbox =
            find.descendant(of: card, matching: find.byType(AppCheckbox));
        final checkboxOpacityFinder =
            find.ancestor(of: checkbox, matching: find.byType(Opacity));
        final checkboxOpacity =
            tester.widget<Opacity>(checkboxOpacityFinder.first);
        expect(checkboxOpacity.opacity, 0.3);

        await testHelper.takeScreenshot(
          tester,
          'IDSDV-UNSELECT-01-initial',
        );
      },
      helper: testHelper,
      locales: [const Locale('en')],
    );
  });
}
