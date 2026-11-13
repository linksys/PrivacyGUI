import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_setting_steps_provider.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setting_step_pages.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// The PnP setting steps are one list per layer (#1511 P4): `kPnpSettingSteps`
/// (the flow's — inclusion condition and draft) and `pnpSettingStepPages` (the
/// page's — label and view), because a provider may not import a view. These
/// keep them one list in effect.
void main() {
  test('both lists name the same steps, in the same order', () {
    expect(
      pnpSettingStepPages.map((p) => p.id),
      kPnpSettingSteps.map((s) => s.id),
      reason: 'a step added to one list and not the other is a step the flow '
          'plans and no page shows, or a page no plan reaches',
    );
  });

  test('no setting step takes Your Network\'s id', () {
    expect(kPnpSettingSteps.map((s) => s.id),
        isNot(contains(PnpFlowPlan.yourNetworkStepId)));
  });

  test('every step has its route under /pnp/pnpConfig, named for its id', () {
    final config = pnpRoute.routes
        .whereType<GoRoute>()
        .singleWhere((r) => r.name == RouteNamed.pnpConfig);
    final steps = {
      for (final r in config.routes.whereType<GoRoute>()) r.path: r.name,
    };

    for (final id in [
      ...kPnpSettingSteps.map((s) => s.id),
      PnpFlowPlan.yourNetworkStepId,
    ]) {
      expect(steps[id], RouteNamed.pnpStep(id), reason: id);
    }
  });
}
