// View ID: STSEL
// Reference: lib/page/health_check/views/speed_test_selection.dart
//
// ## Test Cases
//
// | Test ID          | Description                                             |
// |------------------|---------------------------------------------------------|
// | STSEL-INIT-01    | Verify initial state with both options enabled.        |
// | STSEL-DISABLED-01| Verify state when router speed test is not supported.  |

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/health_check/views/speed_test_selection.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/health_check_state_data.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  // Test ID: STSEL-INIT-01
  testThemeLocalizations(
    'Verify initial state with both options enabled.',
    (tester, screen) async {
      // Mock connectivity as behind router (enables Internet to Device option)
      when(testHelper.mockConnectivityNotifier.build()).thenReturn(
        const ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(
            routerType: RouterType.behindManaged,
          ),
        ),
      );
      // Mock speed test module as supported
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckInitStateWithModules),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const SpeedTestSelectionView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Verify both options are visible
      expect(find.text(testHelper.loc(context).speedTest), findsOneWidget);
      expect(find.text(testHelper.loc(context).speedTestInternetToRouter),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).speedTestInternetToDevice),
          findsOneWidget);
    },
    goldenFilename: 'STSEL-INIT-01-both_enabled',
    helper: testHelper,
    screens: responsiveAllScreens,
  );

  // Test ID: STSEL-DISABLED-01
  testThemeLocalizations(
    'Verify state when router speed test is not supported.',
    (tester, screen) async {
      // Mock connectivity as behind router
      when(testHelper.mockConnectivityNotifier.build()).thenReturn(
        const ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(
            routerType: RouterType.behindManaged,
          ),
        ),
      );
      // Mock speed test module as NOT supported (empty modules list)
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        HealthCheckState.fromJson(healthCheckInitState),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const SpeedTestSelectionView(),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Both cards should be visible but Internet to Router should be disabled
      expect(find.text(testHelper.loc(context).speedTestInternetToRouter),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).speedTestInternetToDevice),
          findsOneWidget);
    },
    goldenFilename: 'STSEL-DISABLED-01-router_test_disabled',
    helper: testHelper,
    screens: responsiveAllScreens,
  );
}
