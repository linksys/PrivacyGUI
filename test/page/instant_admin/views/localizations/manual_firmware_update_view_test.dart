// View ID: MFUV
// Reference to Implementation File: lib/page/instant_admin/views/manual_firmware_update_view.dart
//
// File-Level Summary:
// This file contains screenshot tests for the ManualFirmwareUpdateView.
//
// | Test ID             | Description                                                                 |
// | :------------------ | :-------------------------------------------------------------------------- |
// | `MFUV-DEFAULT`      | Verifies the default state of the manual firmware update view.              |
// | `MFUV-FILE_SELECTED`| Verifies the view when a firmware file has been selected.                   |
// | `MFUV-INSTALLING`   | Verifies the view during the firmware installation process.                 |
// | `MFUV-REBOOTING`    | Verifies the view during the router rebooting process.                      |

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/buttons/button.dart';
import 'dart:typed_data';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  testLocalizationsV2('Manual firmware update - default',
      (tester, localizedScreen) async {
    // Test ID: MFUV-DEFAULT
    await testHelper.pumpShellView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: localizedScreen.locale,
    );

    // Verify page title
    expect(find.text(testHelper.loc(tester.element(find.byType(ManualFirmwareUpdateView))).manualFirmwareUpdate), findsOneWidget);

    // Verify "Manual" title
    expect(find.text(testHelper.loc(tester.element(find.byType(ManualFirmwareUpdateView))).manual), findsOneWidget);

    // Verify "No file chosen" text
    expect(find.text(testHelper.loc(tester.element(find.byType(ManualFirmwareUpdateView))).noFileChosen), findsOneWidget);

    // Verify "Choose File" button
    expect(find.text(testHelper.loc(tester.element(find.byType(ManualFirmwareUpdateView))).chooseFile), findsOneWidget);

    // Verify "Start" button is disabled
    expect(find.text(testHelper.loc(tester.element(find.byType(ManualFirmwareUpdateView))).start), findsOneWidget);
    expect(tester.widget<AppFilledButton>(find.byType(AppFilledButton)).onTap, isNull);
  }, screens: screens, goldenFilename: 'MFUV-DEFAULT-01-initial_state');
  testLocalizationsV2('Manual firmware update - file selected',
      (tester, localizedScreen) async {
    // Test ID: MFUV-FILE_SELECTED
    when(testHelper.mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits))));
    final context = await testHelper.pumpShellView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: localizedScreen.locale,
    );

    // Verify page title
    expect(find.text(testHelper.loc(context).manualFirmwareUpdate), findsOneWidget);

    // Verify "Manual" title
    expect(find.text(testHelper.loc(context).manual), findsOneWidget);

    // Verify file name text
    expect(find.text('FW_LN16_1.0.5.216445_release.img'), findsOneWidget);

    // Verify "Remove" button
    expect(find.text(testHelper.loc(context).remove), findsOneWidget);

    // Verify "Start" button is enabled
    expect(find.text(testHelper.loc(context).start), findsOneWidget);
    expect(tester.widget<AppFilledButton>(find.byType(AppFilledButton)).onTap, isNotNull);
  }, screens: screens, goldenFilename: 'MFUV-FILE_SELECTED-01-initial_state');

  testLocalizationsV2('Manual firmware update - installing status',
      (tester, localizedScreen) async {
    // Test ID: MFUV-INSTALLING
    when(testHelper.mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits)),
            status: ManualUpdateInstalling(15)));
    final context = await testHelper.pumpShellView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: localizedScreen.locale,
    );
    await tester.pump(Duration(seconds: 2));

    // Verify processing icon
    expect(find.byIcon(LinksysIcons.cloudDownload), findsOneWidget);

    // Verify processing title
    expect(find.text(testHelper.loc(context).firmwareInstallingTitle), findsOneWidget);

    // Verify processing message
    expect(find.text('${testHelper.loc(context).firmwareDownloadingMessage1}\n${testHelper.loc(context).firmwareDownloadingMessage2}\n${testHelper.loc(context).firmwareDownloadingMessage3}'), findsOneWidget);

    // Verify LinearProgressIndicator
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  }, screens: screens, goldenFilename: 'MFUV-INSTALLING-01-initial_state');

  testLocalizationsV2('Manual firmware update - rebooting status',
      (tester, localizedScreen) async {
    // Test ID: MFUV-REBOOTING
    when(testHelper.mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits)),
            status: ManualUpdateRebooting()));
    when(testHelper.mockManualFirmwareUpdateNotifier.manualFirmwareUpdate(any, any))
        .thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 2));
      return true;
    });
    final context = await testHelper.pumpShellView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: localizedScreen.locale,
    );
    await tester.pump(); // Ensure UI is settled after pump

    // Verify processing icon
    expect(find.byIcon(LinksysIcons.restartAlt), findsOneWidget);

    // Verify processing title
    expect(find.text(testHelper.loc(context).firmwareRebootingTitle), findsOneWidget);

    // Verify processing message
    expect(find.text('${testHelper.loc(context).firmwareRestartingMessage1}\n${testHelper.loc(context).firmwareRestartingMessage2}\n${testHelper.loc(context).firmwareRestartingMessage3}'), findsOneWidget);
  }, screens: screens, goldenFilename: 'MFUV-REBOOTING-01-initial_state');
}