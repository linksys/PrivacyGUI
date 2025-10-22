import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/timezone_notifier_mocks.dart';
import '../../../../test_data/timezone_test_state.dart';

void main() {
  late MockTimezoneNotifier mockTimezoneNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockTimezoneNotifier = MockTimezoneNotifier();

    when(mockTimezoneNotifier.build())
        .thenReturn(TimezoneState.fromMap(timezoneTestState));
    when(mockTimezoneNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return TimezoneState.fromMap(timezoneTestState);
    });
    when(mockTimezoneNotifier.isDirty()).thenReturn(false); // Default to not dirty
  });

  testLocalizations('Timezone view', (tester, locale) async {
    final widget = testableSingleRoute(
      overrides: [
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 3780)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 3780)),
  ]);

  testLocalizations('Timezone view - dirty state', (tester, locale) async {
    when(mockTimezoneNotifier.isDirty()).thenReturn(true); // Simulate dirty state
    final widget = testableSingleRoute(
      overrides: [
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
      ],
      locale: locale,
      child: const TimezoneView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 3780)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 3780)),
  ]);
}
