import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/_index.dart';

void main() async {
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late InstantSafetyNotifier mockInstantSafetyNotifier;

  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantSafetyNotifier = MockInstantSafetyNotifier();
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));

    initBetterActions();
  });
  testLocalizations('Dashboard Menu View', (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });
  testLocalizations('Dashboard Menu View show bottom sheet',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations(
      'Dashboard Menu View show restart confirm dialog on mobile varients',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations(
      'Dashboard Menu View show restart confirm dialog on desktop varients',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        ],
      ),
    );
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);
}
