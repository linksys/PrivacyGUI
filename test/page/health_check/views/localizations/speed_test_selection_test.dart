import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/page/health_check/views/speed_test_selection.dart';

import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../../test_data/dashboard_manager_test_state.dart';

void main() {
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;

  mockDependencyRegister();

  setUp(() {
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
  });

  for (final supported in [true, false]) {
    testLocalizations(
        'Speed test selection - speed check '
        '${supported ? 'supported' : 'unsupported'}', (tester, locale) async {
      when(mockDashboardManagerNotifier.isHealthCheckModuleSupported(any))
          .thenReturn(supported);
      await tester.pumpWidget(testableSingleRoute(
        overrides: [
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const SpeedTestSelectionView(),
      ));
    });
  }
}
