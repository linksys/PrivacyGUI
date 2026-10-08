import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
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

  late MockFirmwareUpdateNotifier firmware;

  Future<void> pumpDetail(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    firmware = MockFirmwareUpdateNotifier();
    when(firmware.build()).thenReturn(FirmwareUpdateState.empty());
    when(firmware.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords1);
    when(firmware.getAvailableUpdateNumber()).thenReturn(1);

    await tester.pumpWidget(testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      locale: const Locale('en'),
      overrides: [
        firmwareUpdateProvider.overrideWith(() => firmware),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const FirmwareUpdateDetailView(),
    ));
    await tester.pumpAndSettle();
  }

  // #1637: "Update all" flashes every node, so it is blocked before it can
  // start the update, while the list of versions stays readable.
  group('update all', () {
    testWidgets('is blocked in read-only mode', (tester) async {
      await pumpDetail(tester, policy: const AccessPolicy(canWrite: false));

      expect(find.byTooltip('This feature is unavailable in remote mode'),
          findsOneWidget);

      await tester.tap(find.text('Update all'), warnIfMissed: false);
      await tester.pumpAndSettle();

      verifyNever(firmware.updateFirmware());
    });

    testWidgets('starts the update with full access', (tester) async {
      await pumpDetail(tester);

      await tester.tap(find.text('Update all'));
      await tester.pumpAndSettle();

      verify(firmware.updateFirmware()).called(1);
    });
  });
}
