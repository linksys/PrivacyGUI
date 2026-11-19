// The firmware update detail page's Update All with full access.
//
// Update All is offered only when an update is available; that it starts the
// update when it is offered is pinned in
// firmware_update_detail_write_guard_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../test_data/firmware_update_test_state.dart';

void main() {
  mockDependencyRegister();

  Future<MockFirmwareUpdateNotifier> pumpDetail(WidgetTester tester,
      {required int availableUpdates, bool refuseInstall = false}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final firmware = MockFirmwareUpdateNotifier();
    when(firmware.build()).thenReturn(FirmwareUpdateState.empty());
    when(firmware.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords1);
    when(firmware.getAvailableUpdateNumber()).thenReturn(availableUpdates);
    if (refuseInstall) {
      when(firmware.updateFirmware()).thenAnswer(
          (_) async => throw const JNAPError(result: 'ErrorUnknown'));
    }

    await tester.pumpWidget(testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      locale: const Locale('en'),
      overrides: [
        firmwareUpdateProvider.overrideWith(() => firmware),
        accessPolicyProvider.overrideWithValue(AccessPolicy.full),
      ],
      child: const FirmwareUpdateDetailView(),
    ));
    await tester.pumpAndSettle();
    return firmware;
  }

  testWidgets('Update All is absent when nothing is available', (tester) async {
    await pumpDetail(tester, availableUpdates: 0);

    // The page itself is up; only its footer is missing.
    expect(find.text('Firmware Update'), findsWidgets);
    expect(find.text('Update all'), findsNothing);
  });

  // An error no one catches fails a testWidgets test by itself, so the
  // binding is the assertion here: without the page's catch, this fails with
  // "The following JNAPError object was thrown running a test".
  testWidgets('a refused Update All leaves no uncaught error', (tester) async {
    final firmware =
        await pumpDetail(tester, availableUpdates: 1, refuseInstall: true);

    await tester.tap(find.text('Update all'));
    await tester.pumpAndSettle();

    verify(firmware.updateFirmware()).called(1);
  });
}
