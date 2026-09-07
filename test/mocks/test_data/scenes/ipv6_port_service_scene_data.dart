/// Composed scenes for `usp_ipv6_port_service_view` — the golden suite's three states
/// and the gate's one.
///
/// Moved here from
/// `test/golden_test/page/ipv6_port_service/fixtures/ipv6_port_service_test_data.dart`
/// by #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate
/// may not import from `test/golden_test/` (#1361), and one fixture read by both
/// suites beats two that can disagree.
library;

import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_feature_state.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_rule_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

const testRules = [
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.26.',
    enabled: true,
    description: 'Web Server',
    ipv6Address: '2001:db8::1',
    protocol: 'TCP',
    startPort: 80,
    endPort: 80,
  ),
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.27.',
    enabled: true,
    description: 'Game Console',
    ipv6Address: '2001:db8::2',
    protocol: 'Both',
    startPort: 3000,
    endPort: 3100,
  ),
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.28.',
    enabled: false,
    description: 'SSH Access',
    ipv6Address: '2001:db8::3',
    protocol: 'TCP',
    startPort: 22,
    endPort: 22,
  ),
];

Ipv6PortServiceFeatureState dataState({
  List<Ipv6PortServiceRuleUIModel> rules = testRules,
}) {
  final settings = Ipv6PortServiceRuleList(rules: rules);
  return Ipv6PortServiceFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const Ipv6PortServiceStatus(),
  );
}

Ipv6PortServiceFeatureState dirtyState() {
  const original = Ipv6PortServiceRuleList(rules: testRules);
  final current = Ipv6PortServiceRuleList(
    rules: const [
      ...testRules,
      Ipv6PortServiceRuleUIModel(
        enabled: true,
        description: 'New Rule',
        ipv6Address: '2001:db8::ff',
        protocol: 'UDP',
        startPort: 8080,
        endPort: 8080,
      ),
    ],
  );
  return Ipv6PortServiceFeatureState(
    settings: Preservable(original: original, current: current),
    status: const Ipv6PortServiceStatus(),
  );
}

Ipv6PortServiceFeatureState emptyState() {
  const settings = Ipv6PortServiceRuleList();
  return const Ipv6PortServiceFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: Ipv6PortServiceStatus(),
  );
}

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The two rules the gate sweeps.
///
/// `testRules`' three would render three near-identical cards; these two render the
/// two *shapes* the card has, and every field is picked for what it does to the row
/// rather than for what it says:
///
/// - the first carries a **full-form** IPv6 address. `2001:db8::1` is 11 characters
///   and the compressed form the golden fixture happens to hold; a router reporting a
///   SLAAC address reports all eight groups, and 39 characters is the string the
///   `Expanded` column has to fit beside a switch and two icon buttons. The port
///   *range* is here for the same reason: `portDisplay` returns `32400-32499` where a
///   single port returns `80`.
/// - the second has an **empty description**, which is not a gap in the fixture but
///   the one locale-varying string on the card: `_buildRuleCard` falls back to
///   `loc(context).unnamed` for rules the router reports without one. Every other
///   line here — address, protocol, port — is router data and reads identically in
///   all 26 locales, so without this row the card's 234 cells would differ only in
///   the page title and the `rules` heading.
/// - it is also the `enabled: false` row, so both switch states are measured.
const _gateRules = [
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.26.',
    enabled: true,
    description: 'Living Room Media Server',
    ipv6Address: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
    protocol: 'Both',
    startPort: 32400,
    endPort: 32499,
  ),
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.27.',
    enabled: false,
    description: '',
    ipv6Address: '2001:db8::2',
    protocol: 'TCP',
    startPort: 22,
    endPort: 22,
  ),
];

/// The router shape every `page.ipv6_port_service` cell is measured against.
///
/// Clean and non-empty, which is [dataState] with [_gateRules] rather than any of the
/// three golden states, for the two reasons `kPortForwardingPageCase` gives at the
/// same fork:
///
/// - not `emptyState()`: an empty rule list renders one [DetailEmptyBlock] and no
///   card at all, so the sweep would measure a page whose densest widget is absent.
/// - not `dirtyState()`: a dirty page adds the `UiKitBottomBarConfig` save bar, which
///   is ui_kit's own chrome and out of scope for #1380 — the same stance
///   `dmz_scene_data.dart` records for this family.
final gateIpv6PortServiceState = dataState(rules: _gateRules);
