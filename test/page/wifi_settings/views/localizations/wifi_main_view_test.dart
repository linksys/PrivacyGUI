import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/_index.dart';
import '../../../../common/di.dart';
import '../../../../mocks/wifi_bundle_settings_notifier_mocks.dart';
import '../../../../test_data/wifi_bundle_test_state.dart';

void main() {
  late MockWifiBundleNotifier mockWifiBundleNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockWifiBundleNotifier = MockWifiBundleNotifier();

    final settings = WifiBundleSettings.fromMap(
        wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(
        wifiBundleTestState['status'] as Map<String, dynamic>);

    final initialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );

    when(mockWifiBundleNotifier.build()).thenReturn(initialState);
    when(mockWifiBundleNotifier.isDirty()).thenReturn(false);
  });

  group('Incredible-WiFi Views', () {
    testLocalizations('Incredible-WiFi - Main View Renders Correctly',
        (tester, locale) async {
      final widget = testableSingleRoute(
        overrides: [
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
        ],
        locale: locale,
        child: const WiFiMainView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify that the main view and tabs are rendered
      expect(find.byType(WiFiMainView), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens
    ]);

    testLocalizations(
        'Incredible-WiFi - Editing a setting marks state as dirty',
        (tester, locale) async {
      final settings = WifiBundleSettings.fromMap(
          wifiBundleTestState['settings'] as Map<String, dynamic>);
      final status = WifiBundleStatus.fromMap(
          wifiBundleTestState['status'] as Map<String, dynamic>);

      final dirtySettings = settings.copyWith(
          wifiList: settings.wifiList.copyWith(isSimpleMode: false));
      final dirtyState = WifiBundleState(
        settings: Preservable(original: settings, current: dirtySettings),
        status: status,
      );

      when(mockWifiBundleNotifier.build()).thenReturn(dirtyState);
      when(mockWifiBundleNotifier.state).thenReturn(dirtyState);
      when(mockWifiBundleNotifier.isDirty()).thenReturn(true);

      final widget = testableSingleRoute(
        overrides: [
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
        ],
        locale: locale,
        child: const WiFiMainView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify that the save button is enabled
      final saveButtonFinder = find.byType(AppFilledButton);
      expect(saveButtonFinder, findsOneWidget);
      final AppFilledButton button = tester.widget(saveButtonFinder);
      expect(button.onTap, isNotNull);
    });
  });
}
