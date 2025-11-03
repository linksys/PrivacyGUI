import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/_index.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  testLocalizations('Instant device view - default', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      overrides: [
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList()),
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );
  });

  testLocalizations('Instant device view - 1 device', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      overrides: [
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .take(1)
            .toList()),
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );
  });

  testLocalizations('Instant device view - no device', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      overrides: [
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .take(0)
            .toList()),
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );
  });

  testLocalizations('Instant device view - filter with unknown node',
      (tester, locale) async {
    when(testHelper.mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(showOrphanNodes: true));
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const InstantDeviceView(),
    );
  }, screens: responsiveDesktopScreens);

  testLocalizations('Instant device view - filter with unknown node',
      (tester, locale) async {
    when(testHelper.mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(showOrphanNodes: true));
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const InstantDeviceView(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LinksysIcons.filter));
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations('Instant device view - offline devices',
      (tester, locale) async {
    when(testHelper.mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    await testHelper.pumpView(
      tester,
      overrides: [
        filteredDeviceListProvider.overrideWith((ref) =>
            deviceFilteredOfflineTestData
                .map((e) => DeviceListItem.fromMap(e))
                .toList()),
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );

    final deviceCheckboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard), matching: find.byType(AppCheckbox));
    await tester.tap(deviceCheckboxFinder.first);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Instant device view - offline devices - delete confirm modal',
      (tester, locale) async {
    when(testHelper.mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState)
            .copyWith(connectionFilter: false));
    await testHelper.pumpView(
      tester,
      overrides: [
        filteredDeviceListProvider.overrideWith((ref) =>
            deviceFilteredOfflineTestData
                .map((e) => DeviceListItem.fromMap(e))
                .toList()),
      ],
      locale: locale,
      child: const InstantDeviceView(),
    );

    final deviceCheckboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard), matching: find.byType(AppCheckbox));
    await tester.tap(deviceCheckboxFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFilledButton).last);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant device view - deauth confirm modal',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      locale: locale,
      overrides: [
        filteredDeviceListProvider.overrideWith((ref) =>
            deviceFilteredTestData
                .map((e) => DeviceListItem.fromMap(e))
                .toList()),
      ],
      child: const InstantDeviceView(),
    );
    await tester.pumpAndSettle();
    final deviceCheckboxFinder = find.descendant(
        of: find.byType(AppDeviceListCard),
        matching: find.byIcon(LinksysIcons.bidirectional));
    await tester.tap(deviceCheckboxFinder.first);
    await tester.pumpAndSettle();
  });
}
