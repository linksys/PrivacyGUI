/// Composed scenes for `usp_firewall_view` — the golden suite's three states and
/// the gate's one.
///
/// Moved here from `test/golden_test/page/firewall/fixtures/firewall_test_data.dart`
/// by #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate
/// may not import from `test/golden_test/` (#1361), and one fixture read by both
/// suites beats two that can disagree.
library;

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
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
  blockNATRedirection: true,
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
  blockNATRedirection: false,
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

/// The 12 named rules FLWRT 2.0.3 ships (FWDEV#204), so every switch can be
/// used. [without] drops rules by `Description`, for a router missing some.
FirewallChainRules namedChainRules({Set<String> without = const {}}) =>
    FirewallChainRules(items: [
      for (final d in const [
        'UDP_FORWARD_FOR_IGMP',
        'RULE_SPI_IPV4_INPUT',
        'RULE_SPI_IPV4_FORWARD',
        'RULE_SPI_IPV6_INPUT',
        'RULE_SPI_IPV6_FORWARD',
        'RULE_PING_IPV4',
        'RULE_IDENT_WAN',
        'RULE_LAN2WAN_IPSEC',
        'RULE_IPSEC_ESP',
        'RULE_LAN2WAN_PPTP',
        'RULE_LAN2WAN_L2TP',
        'RULE_NAT_REDIRECTION',
      ])
        if (!without.contains(d))
          FirewallChainRule(
            instancePath: 'Device.Firewall.Chain.1.Rule.$d.',
            enable: false,
            description: d,
            target: 'Accept',
          ),
    ]);

FirewallFeatureState dataState(
  FirewallUIModel model, {
  Set<FirewallSwitch> lockedSwitches = const {},
}) {
  final settings = FirewallSettings(model: model);
  return FirewallFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: FirewallStatus(isLoading: false, lockedSwitches: lockedSwitches),
  );
}

FirewallFeatureState dirtyState({bool isSaving = false}) {
  const original = FirewallSettings(model: allOnModel);
  const current = FirewallSettings(model: dirtyCurrentModel);
  return FirewallFeatureState(
    settings: Preservable(original: original, current: current),
    status: FirewallStatus(isLoading: false, isSaving: isSaving),
  );
}

/// A router missing one named rule: its switch is locked and reads off, the
/// rest work. Built through the service as a fetch builds it, so the model and
/// the locks cannot disagree the way a hand-picked model would.
FirewallFeatureState get missingNatRuleState {
  final rules = UspFirewallService.parseFirewallRules(
      namedChainRules(without: const {'RULE_NAT_REDIRECTION'}));
  return dataState(
    UspFirewallService.buildUIModel(rules: rules),
    lockedSwitches: FirewallRuleContext.fromMap(rules).lockedSwitches,
  );
}

/// A router with no named rule — the load error #1611 gave this page in place
/// of fabricated switches.
FirewallFeatureState get errorState => FirewallFeatureState(
      settings: Preservable(
        original: FirewallSettings.empty(),
        current: FirewallSettings.empty(),
      ),
      status: const FirewallStatus(
        isLoading: false,
        error: ResourceNotFoundError(
          detail: 'No known firewall rule on the router',
        ),
      ),
    );

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The router shape every `page.firewall` cell is measured against.
///
/// [allOnModel], and unusually for this family the choice is *not* a coverage
/// argument — it cannot be. All nine `SwitchBlock`s and the `NavLinkBlock` render
/// unconditionally: this page has no `if` in its content at all, so every model
/// produces the same ten rows and the same geometry. The nine booleans move a
/// thumb 20px inside a fixed-width track, which is not a width the sweep can see.
///
/// So the model is picked to be the honest one rather than the widest one — the
/// protective state a router ships in — and the *fixture* risk this page carries is
/// nil, which is why the case's premise names widget types and no count.
final gateFirewallState = dataState(allOnModel);
