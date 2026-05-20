import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_static_routing.dart';
import '../fixtures/static_routing_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'static_routing',
      view: () => const UspStaticRoutingView(),
      shell: ShellType.custom,
      states: {
        'routes_list': (overrides) => overrides.addAll(
              staticRoutingOverrides(dataState([route1, route2])),
            ),
        'empty': (overrides) => overrides.addAll(
              staticRoutingOverrides(emptyState()),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              staticRoutingOverrides(dirtyState()),
            ),
        'saving': (overrides) => overrides.addAll(
              staticRoutingOverrides(dirtyState(isSaving: true)),
            ),
      },
    ),
  );
}
