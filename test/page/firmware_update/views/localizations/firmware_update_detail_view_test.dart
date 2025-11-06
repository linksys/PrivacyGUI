import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/firmware_update_test_state.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Firmware update detail view - 1 node with 1 update',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords1);
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Firmware update detail view - 2 node with 1 update',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords2);
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Checking',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords3);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Installing',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords4);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Rebooting',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords5);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Firmware update detail view - 2 node with 2 updates',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords6);
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Firmware update detail view - updating in 2 nodes',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords7);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Firmware update detail view - updating in 3 nodes',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords8);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Firmware update detail view - updating in 4 nodes',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords9);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Firmware update detail view - 2 node with no updates',
      (tester, locale) async {
    when(testHelper.mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(testHelper.mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords10);
    await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: locale,
    );
  }, screens: screens);
}