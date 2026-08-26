/// Composed scenes for `usp_firewall_view` — the golden suite's three states and
/// the gate's one.
///
/// Moved here from `test/golden_test/page/firewall/fixtures/firewall_test_data.dart`
/// by #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate
/// may not import from `test/golden_test/` (#1361), and one fixture read by both
/// suites beats two that can disagree.
library;

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

const allOnModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: true,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

const allOffModel = FirewallUIModel(
  isIPv4FirewallEnabled: false,
  isIPv6FirewallEnabled: false,
  blockIPSec: true,
  blockPPTP: true,
  blockL2TP: true,
  blockAnonymousRequests: false,
  blockMulticast: false,
  blockIDENT: false,
);

const dirtyCurrentModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: false,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

FirewallFeatureState dataState(FirewallUIModel model) {
  final settings = FirewallSettings(
    model: model,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const FirewallStatus(isLoading: false),
  );
}

FirewallFeatureState dirtyState({bool isSaving = false}) {
  final original = FirewallSettings(
    model: allOnModel,
    ruleContext: FirewallRuleContext.empty,
  );
  final current = FirewallSettings(
    model: dirtyCurrentModel,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: original, current: current),
    status: FirewallStatus(isLoading: false, isSaving: isSaving),
  );
}

FirewallFeatureState get errorState => FirewallFeatureState(
      settings: Preservable(
        original: FirewallSettings.empty(),
        current: FirewallSettings.empty(),
      ),
      status: const FirewallStatus(
        isLoading: false,
        error: ConnectivityError(detail: 'Connection failed'),
      ),
    );

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The router shape every `page.firewall` cell is measured against.
///
/// [allOnModel], and unusually for this family the choice is *not* a coverage
/// argument — it cannot be. All eight `SwitchBlock`s and the `NavLinkBlock` render
/// unconditionally: this page has no `if` in its content at all, so every model
/// produces the same nine rows and the same geometry. The eight booleans move a
/// thumb 20px inside a fixed-width track, which is not a width the sweep can see.
///
/// So the model is picked to be the honest one rather than the widest one — the
/// protective state a router ships in — and the *fixture* risk this page carries is
/// nil, which is why the case's premise names widget types and no count.
final gateFirewallState = dataState(allOnModel);
