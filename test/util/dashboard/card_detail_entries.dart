/// The registered cards that enter no detail page, so publish no hook.
///
/// Listed rather than inferred, so that a card which *gains* an entry fails the
/// meta-test in `dashboard_card_identifier_widget_test.dart` instead of quietly
/// rendering an unasserted button.
///
/// Shared rather than restated, because it has two readers that must agree:
/// that identifier test, which pins *which* cards have a detail entry, and
/// `dashboard_card_presented_navigation_test.dart`, which measures what the
/// button does and enumerates its cases as the presented cards minus this set
/// (#1453). A copy in the second file would not follow an edit to the first, and
/// a card gaining an entry would then drop out of the navigation cases with
/// nothing failing.
const Set<String> kCardsWithoutDetailEntry = {
  'stats_panel',
  'ethernet_ports',
  'device_analytics',
  'network_health',
  'wifi_performance',
};
