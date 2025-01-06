import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'dart:typed_data';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/jnap_service_supported_mocks.dart';
import '../../../../mocks/manual_firmware_update_notifier_mocks.dart';
import '../../../../test_data/firmware_update_test_state.dart';
import '../../../../mocks/firmware_update_notifier_mocks.dart';

void main() {
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late ManualFirmwareUpdateNotifier mockManualFirmwareUpdateNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockManualFirmwareUpdateNotifier = MockManualFirmwareUpdateNotifier();

    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockManualFirmwareUpdateNotifier.build())
        .thenReturn(ManualFirmwareUpdateState());
  });

  testLocalizations('Mnaual firmware update - default', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        manualFirmwareUpdateProvider
            .overrideWith(() => mockManualFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const ManualFirmwareUpdateView(),
    );
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  });
  testLocalizations('Mnaual firmware update - file selected',
      (tester, locale) async {
    when(mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits))));
    final widget = testableSingleRoute(
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        manualFirmwareUpdateProvider
            .overrideWith(() => mockManualFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const ManualFirmwareUpdateView(),
    );
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  });

  testLocalizations('Mnaual firmware update - installing status',
      (tester, locale) async {
    when(mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits)),
            status: ManualUpdateInstalling(15)));
    final widget = testableSingleRoute(
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        manualFirmwareUpdateProvider
            .overrideWith(() => mockManualFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const ManualFirmwareUpdateView(),
    );
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();
  });

  testLocalizations('Mnaual firmware update - rebooting status',
      (tester, locale) async {
    when(mockManualFirmwareUpdateNotifier.build()).thenReturn(
        ManualFirmwareUpdateState(
            file: FileInfo(
                name: 'FW_LN16_1.0.5.216445_release.img',
                bytes: Uint8List.fromList('bytes'.codeUnits)),
            status: ManualUpdateRebooting()));
    when(mockFirmwareUpdateNotifier.manualFirmwareUpdate(any, any))
        .thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 2));
      return true;
    });
    final widget = testableSingleRoute(
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        manualFirmwareUpdateProvider
            .overrideWith(() => mockManualFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const ManualFirmwareUpdateView(),
    );
    await tester.pumpWidget(widget);
  });
}
