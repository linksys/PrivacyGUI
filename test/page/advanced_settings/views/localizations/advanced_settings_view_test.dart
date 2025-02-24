import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/advanced_settings_view.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/dashboard_home_notifier_mocks.dart';
import '../../../../test_data/dashboard_home_test_state.dart';

void main() {
  late DashboardHomeNotifier mockDashboardHomeNotifier;

  setUp(() {
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
  });

  testLocalizations('AdvancedSettings - init', (tester, locale) async {
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateData));
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
      ],
      locale: locale,
      child: const AdvancedSettingsView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('AdvancedSettings - birdge mode', (tester, locale) async {
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateDataInBridge));
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
      ],
      locale: locale,
      child: const AdvancedSettingsView(),
    );
    await tester.pumpWidget(widget);
  });
}
