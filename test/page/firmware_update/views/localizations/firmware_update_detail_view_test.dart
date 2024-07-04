import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/firmware_update_test_state.dart';
import '../../firmware_update_detail_view_test_mocks.dart';

@GenerateNiceMocks([MockSpec<FirmwareUpdateNotifier>()])
void main() {
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;

  setUp(() {
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
  });

  testLocalizations('Firmware update detail view test - 1 node with 1 update',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords1);
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const FirmwareUpdateDetailView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('Firmware update detail view test - 3 node with 2 updates',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords2);
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
      overrides: [
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const FirmwareUpdateDetailView(),
    );
    await tester.pumpWidget(widget);
  });

}
