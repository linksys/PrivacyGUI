// Baseline for the firmware update detail page's Update All in the default
// build.
//
// A read-only build is going to disable Update All here. These tests pin that
// the default build still offers it when an update is available, that it
// starts the update, and that it is absent when there is nothing to install -
// so disabling it cannot quietly change what a local user sees.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../test_data/firmware_update_test_state.dart';

void main() {
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;

  mockDependencyRegister();

  setUp(() {
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords1);
    when(mockFirmwareUpdateNotifier.updateFirmware()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      child: const FirmwareUpdateDetailView(),
    ));
    await tester.pumpAndSettle();
  }

  final updateAll = find.widgetWithText(AppFilledButton, 'Update all');

  testWidgets('Update All is offered and starts the update', (tester) async {
    when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
    await pump(tester);

    expect(tester.widget<AppFilledButton>(updateAll).onTap, isNotNull);
    await tester.tap(updateAll);
    await tester.pumpAndSettle();
    verify(mockFirmwareUpdateNotifier.updateFirmware()).called(1);
  });

  testWidgets('Update All is absent when nothing is available', (tester) async {
    when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(0);
    await pump(tester);

    expect(updateAll, findsNothing);
  });
}
