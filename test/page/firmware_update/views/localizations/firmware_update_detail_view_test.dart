import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../test_data/firmware_update_test_state.dart';
import '../../../../mocks/firmware_update_notifier_mocks.dart';

void main() {
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;

  setUp(() {
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
  });

  testLocalizations('Firmware update detail view - 1 node with 1 update',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords1);
    when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
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

  testLocalizations('Firmware update detail view - 2 node with 1 update',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords2);
    when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
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

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Checking',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords3);
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

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Installing',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords4);
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

  testLocalizations(
      'Firmware update detail view - updating in 1 node with Rebooting',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords5);
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

  testLocalizations('Firmware update detail view - 2 node with 2 updates',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords6);
    when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);
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

  testLocalizations('Firmware update detail view - updating in 2 nodes',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords7);
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

  testLocalizations('Firmware update detail view - updating in 3 nodes',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords8);
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

  testLocalizations('Firmware update detail view - updating in 4 nodes',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty().copyWith(isUpdating: true));
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords9);
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

  testLocalizations('Firmware update detail view - 2 node with no updates',
      (tester, locale) async {
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockFirmwareUpdateNotifier.getIDStatusRecords())
        .thenReturn(testFirmwareUpdateStatusRecords10);
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
