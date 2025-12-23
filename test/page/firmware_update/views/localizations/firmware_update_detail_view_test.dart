import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/firmware_update_test_state.dart';

// View ID: FUDV
// Reference to Implementation File: lib/page/firmware_update/views/firmware_update_detail_view.dart
//
// File-Level Summary:
// This file contains screenshot tests for the FirmwareUpdateDetailView.
//
// | Test ID             | Description                                                                 |
// | :------------------ | :-------------------------------------------------------------------------- |
// | `FUDV-1_NODE_1_UPDATE` | Displaying firmware update details for a single node with an update.        |
// | `FUDV-2_NODE_1_UPDATE` | Displaying firmware update details for two nodes with one update.           |
// | `FUDV-1_NODE_CHECKING` | Displaying firmware update details during firmware update process (checking). |
// | `FUDV-1_NODE_INSTALLING` | Displaying firmware update details during firmware update process (installing). |
// | `FUDV-1_NODE_REBOOTING` | Displaying firmware update details during firmware update process (rebooting). |
// | `FUDV-2_NODE_2_UPDATES` | Displaying firmware update details for two nodes with two updates.          |
// | `FUDV-UPDATING_2_NODES` | Displaying firmware update details for two nodes during update process.     |
// | `FUDV-UPDATING_3_NODES` | Displaying firmware update details for three nodes during update process.   |
// | `FUDV-UPDATING_4_NODES` | Displaying firmware update details for four nodes during update process.    |
// | `FUDV-2_NODE_NO_UPDATES` | Displaying firmware update details for two nodes with no updates.           |
void main() {
  final testHelper = TestHelper();
  final screens = [
    ...responsiveDesktopScreens,
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440))
  ];

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('Firmware update detail view - 1 node with 1 update',
      (tester, localizedScreen) async {
    // Test ID: FUDV-1_NODE_1_UPDATE
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            nodesStatus: testFirmwareUpdateStatusRecords1
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
        .thenReturn(1);
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsOneWidget);

    // Verify description texts
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc1), findsOneWidget);
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc2), findsOneWidget);

    // Verify "Update All" button
    expect(find.text(testHelper.loc(context).updateAll), findsOneWidget);

    // Verify FirmwareUpdateNodeCard content
    expect(find.byType(FirmwareUpdateNodeCard), findsOneWidget);
    expect(find.text('Linksys03056 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216308')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).newVersion('1.0.4.216394')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).updateAvailable), findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-1_NODE_1_UPDATE-01-initial_state');

  testLocalizations('Firmware update detail view - 2 node with 1 update',
      (tester, localizedScreen) async {
    // Test ID: FUDV-2_NODE_1_UPDATE
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            nodesStatus: testFirmwareUpdateStatusRecords2
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
        .thenReturn(1);
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsOneWidget);

    // Verify description texts
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc1), findsOneWidget);
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc2), findsOneWidget);

    // Verify "Update All" button
    expect(find.text(testHelper.loc(context).updateAll), findsOneWidget);

    // Verify FirmwareUpdateNodeCard content for the first node (with update)
    expect(find.text('Linksys03056 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216308')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).newVersion('1.0.4.216394')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).updateAvailable), findsOneWidget);

    // Verify FirmwareUpdateNodeCard content for the second node (no update)
    expect(find.text('Linksys03027 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216252')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).upToDate), findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-2_NODE_1_UPDATE-01-initial_state');

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Checking',
      (tester, localizedScreen) async {
    // Test ID: FUDV-1_NODE_CHECKING
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            isUpdating: true,
            nodesStatus: testFirmwareUpdateStatusRecords3
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title is not present
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsNothing);

    // Verify progress indicator and texts
    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.text('Linksys03056'), findsOneWidget);
    expect(find.text(testHelper.loc(context).firmwareDownloadingTitle),
        findsOneWidget); // 'Checking' maps to 'firmwareDownloadingTitle'
    expect(find.text('45 %'), findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-1_NODE_CHECKING-01-initial_state');

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Installing',
      (tester, localizedScreen) async {
    // Test ID: FUDV-1_NODE_INSTALLING
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            isUpdating: true,
            nodesStatus: testFirmwareUpdateStatusRecords4
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title is not present
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsNothing);

    // Verify progress indicator and texts
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Linksys03056'), findsOneWidget);
    expect(find.text(testHelper.loc(context).firmwareInstallingTitle),
        findsOneWidget);
    expect(find.text('70 %'), findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-1_NODE_INSTALLING-01-initial_state');

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Rebooting',
      (tester, localizedScreen) async {
    // Test ID: FUDV-1_NODE_REBOOTING
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            isUpdating: true,
            nodesStatus: testFirmwareUpdateStatusRecords5
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title is not present
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsNothing);

    // Verify progress indicator and texts
    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.text('Linksys03056'), findsOneWidget);
    expect(find.text(testHelper.loc(context).firmwareRebootingTitle),
        findsOneWidget);
    expect(find.text('90 %'), findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-1_NODE_REBOOTING-01-initial_state');

  testLocalizations('Firmware update detail view - 2 node with 2 updates',
      (tester, localizedScreen) async {
    // Test ID: FUDV-2_NODE_2_UPDATES
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            nodesStatus: testFirmwareUpdateStatusRecords6
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
        .thenReturn(1);
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsOneWidget);

    // Verify description texts
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc1), findsOneWidget);
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc2), findsOneWidget);

    // Verify "Update All" button
    expect(find.text(testHelper.loc(context).updateAll), findsOneWidget);

    // Verify FirmwareUpdateNodeCard content for the first node (with update)
    expect(find.text('Linksys03056 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216308')),
        findsOneWidget);

    // Verify FirmwareUpdateNodeCard content for the second node (with update)
    expect(find.text('Linksys03027 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216252')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).newVersion('1.0.4.216394')),
        findsNWidgets(2)); // Both nodes have updates
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-2_NODE_2_UPDATES-01-initial_state');

  testLocalizations('Firmware update detail view - updating in 2 nodes',
      (tester, localizedScreen) async {
    // Test ID: FUDV-UPDATING_2_NODES
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            isUpdating: true,
            nodesStatus: testFirmwareUpdateStatusRecords7
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title is not present
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsNothing);

    // Verify GridView.builder is present for multiple updating nodes
    expect(find.byType(GridView), findsOneWidget);

    // Verify progress indicators and texts for both nodes
    expect(find.byType(AppLoader), findsNWidgets(2));
    expect(find.text('Linksys03056'), findsOneWidget);
    expect(find.text(testHelper.loc(context).firmwareDownloadingTitle),
        findsNWidgets(2)); // Both 'Checking' and 'Downloading' map to this
    expect(find.text('45 %'), findsOneWidget);
    expect(find.text('Linksys03027'), findsOneWidget);
    expect(find.text('95 %'), findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-UPDATING_2_NODES-01-initial_state');

  testLocalizations('Firmware update detail view - updating in 3 nodes',
      (tester, localizedScreen) async {
    // Test ID: FUDV-UPDATING_3_NODES
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            isUpdating: true,
            nodesStatus: testFirmwareUpdateStatusRecords8
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title is not present
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsNothing);

    // Verify GridView.builder is present for multiple updating nodes
    expect(find.byType(GridView), findsOneWidget);

    // Verify progress indicators and texts for all three nodes
    expect(find.byType(AppLoader), findsNWidgets(3));
    expect(find.text('Linksys03056'), findsOneWidget);
    expect(find.text(testHelper.loc(context).firmwareDownloadingTitle),
        findsNWidgets(3)); // All 'Checking' and 'Downloading' map to this
    expect(find.text('45 %'), findsOneWidget);
    expect(find.text('Linksys03027'), findsNWidgets(2));
    expect(find.text('95 %'), findsNWidgets(2));
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-UPDATING_3_NODES-01-initial_state');

  testLocalizations('Firmware update detail view - updating in 4 nodes',
      (tester, localizedScreen) async {
    // Test ID: FUDV-UPDATING_4_NODES
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            isUpdating: true,
            nodesStatus: testFirmwareUpdateStatusRecords9
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title is not present
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsNothing);

    // Verify GridView.builder is present for multiple updating nodes
    expect(find.byType(GridView), findsOneWidget);
    await testHelper.takeScreenshot(tester, 'XXXXX-FUDV-UPDATING_4_NODES');
    // Verify progress indicators and texts for all four nodes
    expect(find.byType(AppLoader), findsNWidgets(4));
    expect(find.text('Linksys03056'), findsOneWidget);
    expect(find.text(testHelper.loc(context).firmwareDownloadingTitle),
        findsNWidgets(4)); // All 'Checking' and 'Downloading' map to this
    expect(find.text('45 %'), findsOneWidget);
    expect(find.text('Linksys03027'), findsNWidgets(3));
    expect(find.text('95 %'), findsNWidgets(3));
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-UPDATING_4_NODES-01-initial_state');

  testLocalizations('Firmware update detail view - 2 node with no updates',
      (tester, localizedScreen) async {
    // Test ID: FUDV-2_NODE_NO_UPDATES
    when(testHelper.mockFirmwareUpdateNotifier.build()).thenReturn(
        FirmwareUpdateState.empty().copyWith(
            nodesStatus: testFirmwareUpdateStatusRecords10
                .map((e) => FirmwareUpdateUIModel.fromNodeFirmwareUpdateStatus(
                    e.$2, e.$1))
                .toList()));
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber())
        .thenReturn(0);
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      child: const FirmwareUpdateDetailView(),
      locale: localizedScreen.locale,
    );

    // Verify page title
    expect(find.text(testHelper.loc(context).firmwareUpdate), findsOneWidget);

    // Verify description texts
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc1), findsOneWidget);
    expect(
        find.text(testHelper.loc(context).firmwareUpdateDesc2), findsOneWidget);

    // Verify "Update All" button is not present
    expect(find.text(testHelper.loc(context).updateAll), findsNothing);

    // Verify FirmwareUpdateNodeCard content for the first node (no update)
    expect(find.text('Linksys03056 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216308')),
        findsOneWidget);
    expect(find.text(testHelper.loc(context).upToDate),
        findsNWidgets(2)); // Both nodes are up to date

    // Verify FirmwareUpdateNodeCard content for the second node (no update)
    expect(find.text('Linksys03027 (LN16)'), findsOneWidget);
    expect(find.text(testHelper.loc(context).currentVersion('1.0.3.216252')),
        findsOneWidget);
  },
      helper: testHelper,
      screens: screens,
      goldenFilename: 'FUDV-2_NODE_NO_UPDATES-01-initial_state');
}
