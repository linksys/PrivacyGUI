import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'dart:typed_data';

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

  testLocalizations('Manual firmware update - default', (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: locale,
    );
  }, screens: screens);
  testLocalizations('Manual firmware update - file selected',
      (tester, locale) async {
    when(testHelper.mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits))));
    await testHelper.pumpView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: locale,
    );
  }, screens: screens);

  testLocalizations('Manual firmware update - installing status',
      (tester, locale) async {
    when(testHelper.mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits)),
            status: ManualUpdateInstalling(15)));
    await testHelper.pumpView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: locale,
    );
    await tester.pump(Duration(seconds: 2));
  }, screens: screens);

  testLocalizations('Manual firmware update - rebooting status',
      (tester, locale) async {
    when(testHelper.mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits)),
            status: ManualUpdateRebooting()));
    when(testHelper.mockFirmwareUpdateNotifier.manualFirmwareUpdate(any, any))
        .thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 2));
      return true;
    });
    await testHelper.pumpView(
      tester,
      child: const ManualFirmwareUpdateView(),
      locale: locale,
    );
  }, screens: screens);
}