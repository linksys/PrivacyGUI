import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/wifi_main_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/_index.dart';
import '../../../common/di.dart';
import '../../../mocks/wifi_bundle_notifier_mocks.dart';
import '../../../test_data/wifi_bundle_test_state.dart';

void main() {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late MockWifiBundleNotifier mockWifiBundleNotifier;
  late WifiBundleState initialState;

  setUp(() {
    mockWifiBundleNotifier = MockWifiBundleNotifier();
    final settings = WifiBundleSettings.fromMap(wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(wifiBundleTestState['status'] as Map<String, dynamic>);
    initialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
    when(mockWifiBundleNotifier.build()).thenReturn(initialState);
    when(mockWifiBundleNotifier.state).thenReturn(initialState);
    when(mockWifiBundleNotifier.isDirty()).thenReturn(false);
  });

  testLocalizations('Dialog - Router Not Found', (tester, locale) async {
    when(mockWifiBundleNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw JNAPSideEffectError();
    });

    final widget = testableSingleRoute(
      overrides: [
        wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
      ],
      locale: locale,
      child: const WiFiMainView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Simulate a change to enable the save button
    final dirtyState = initialState.copyWith(
        settings: initialState.settings.update(initialState.settings.current.copyWith(advanced: initialState.settings.current.advanced.copyWith(isIptvEnabled: true)))
    );
    when(mockWifiBundleNotifier.isDirty()).thenReturn(true);
    when(mockWifiBundleNotifier.state).thenReturn(dirtyState);
    await tester.pump();

    // Tap save button
    final saveButtonFinder = find.byType(AppFilledButton);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Dialog - You have unsaved changes',
      (tester, locale) async {
    final settings = WifiBundleSettings.fromMap(wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(wifiBundleTestState['status'] as Map<String, dynamic>);
    final dirtySettings = settings.copyWith(advanced: settings.advanced.copyWith(isIptvEnabled: true));
    final dirtyState = WifiBundleState(
        settings: Preservable(original: settings, current: dirtySettings),
        status: status,
    );

    when(mockWifiBundleNotifier.isDirty()).thenReturn(true);
    when(mockWifiBundleNotifier.state).thenReturn(dirtyState);

    final widget = testableSingleRoute(
      overrides: [
        wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
      ],
      locale: locale,
      child: const WiFiMainView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Tap back button
    final backButtonFinder = find.byType(AppIconButton);
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();
  });
}
