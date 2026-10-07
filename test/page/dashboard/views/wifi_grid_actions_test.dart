import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/wifi_grid.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/_index.dart';

// Each WiFi card's switch saves from its own confirm dialog, with no Save bar
// behind it. #1637 blocks it in read-only mode (dashboard_write_guard_test.dart);
// these pin that with full access every switch is live and reaches its save
// after confirmation - main networks through saveToggleEnabled, guest through
// save.
void main() {
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockWifiListNotifier mockWifiListNotifier;
  late MockPollingNotifier mockPollingNotifier;

  mockDependencyRegister();

  setUp(() {
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockWifiListNotifier = MockWifiListNotifier();
    mockPollingNotifier = MockPollingNotifier();
    initBetterActions();

    // Two main networks and one guest, all enabled.
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    final wifiState = WiFiState.fromMap(wifiListTestState);
    when(mockWifiListNotifier.build()).thenReturn(wifiState);
    when(mockWifiListNotifier.fetch(any)).thenAnswer((_) async => wifiState);
    when(mockWifiListNotifier.fetch()).thenAnswer((_) async => wifiState);
    when(mockWifiListNotifier.save()).thenAnswer((_) async => wifiState);
    when(mockWifiListNotifier.saveToggleEnabled(
            radios: anyNamed('radios'), enabled: anyNamed('enabled')))
        .thenAnswer((_) async {});
    when(mockPollingNotifier.build()).thenReturn(
        const CoreTransactionData(lastUpdate: 0, isReady: true, data: {}));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        accessPolicyProvider.overrideWithValue(AccessPolicy.full),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        wifiListProvider.overrideWith(() => mockWifiListNotifier),
        pollingProvider.overrideWith(() => mockPollingNotifier),
      ],
      child: const DashboardWiFiGrid(),
    ));
    await tester.pumpAndSettle();
  }

  List<AppSwitch> switches(WidgetTester tester) => tester
      .widgetList<AppSwitch>(find.descendant(
          of: find.byType(DashboardWiFiGrid), matching: find.byType(AppSwitch)))
      .toList();

  testWidgets('every network switch is live', (tester) async {
    await pump(tester);

    final all = switches(tester);
    expect(all, hasLength(3));
    expect(all.every((s) => s.onChanged != null), isTrue);
  });

  testWidgets('a main network asks first, then saves its radios',
      (tester) async {
    await pump(tester);

    switches(tester).first.onChanged!(false);
    await tester.pumpAndSettle();
    verifyNever(mockWifiListNotifier.saveToggleEnabled(
        radios: anyNamed('radios'), enabled: anyNamed('enabled')));

    await tester.tap(find.widgetWithText(AppTextButton, 'Ok'));
    await tester.pumpAndSettle();
    verify(mockWifiListNotifier.saveToggleEnabled(
            radios: anyNamed('radios'), enabled: false))
        .called(1);
  });

  testWidgets('the guest network asks first, then saves', (tester) async {
    await pump(tester);

    switches(tester).last.onChanged!(false);
    await tester.pumpAndSettle();
    verifyNever(mockWifiListNotifier.save());

    await tester.tap(find.widgetWithText(AppTextButton, 'Ok'));
    await tester.pumpAndSettle();
    verify(mockWifiListNotifier.setWiFiEnabled(false)).called(1);
    verify(mockWifiListNotifier.save()).called(1);
  });

  // Cancel pops null out of a dialog typed Future<bool>, so the toggle handler
  // dies on a TypeError before it reaches any save. No write leaves either way;
  // the error is recorded here as found, not endorsed, so that fixing it is a
  // deliberate change to this test rather than a silent one.
  testWidgets('cancelling saves nothing', (tester) async {
    await pump(tester);

    // The handler's future is dropped by the switch, so its error is caught in
    // a zone of its own rather than failing the test as an uncaught error.
    final errors = <Object>[];
    runZonedGuarded(() => switches(tester).first.onChanged!(false),
        (error, _) => errors.add(error));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppTextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(errors.single, isA<TypeError>());
    verifyNever(mockWifiListNotifier.saveToggleEnabled(
        radios: anyNamed('radios'), enabled: anyNamed('enabled')));
    verifyNever(mockWifiListNotifier.save());
  });
}
