import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_data_service.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

/// Test data builder for Firewall + DMZ tests.
///
/// Provides factory methods for the UI models, the fetch result returned by
/// [UspFirewallDataService], and the composed [FirewallData] L1 state.
class FirewallTestData {
  // ---------------------------------------------------------------------------
  // UI models
  // ---------------------------------------------------------------------------

  static FirewallUIModel createFirewallUIModel({
    bool isIPv4FirewallEnabled = true,
    bool isIPv6FirewallEnabled = true,
    bool blockIPSec = false,
    bool blockPPTP = false,
    bool blockL2TP = false,
    bool blockAnonymousRequests = false,
    bool blockMulticast = false,
    bool blockIDENT = false,
    bool blockNATRedirection = false,
  }) =>
      FirewallUIModel(
        isIPv4FirewallEnabled: isIPv4FirewallEnabled,
        isIPv6FirewallEnabled: isIPv6FirewallEnabled,
        blockIPSec: blockIPSec,
        blockPPTP: blockPPTP,
        blockL2TP: blockL2TP,
        blockAnonymousRequests: blockAnonymousRequests,
        blockMulticast: blockMulticast,
        blockIDENT: blockIDENT,
        blockNATRedirection: blockNATRedirection,
      );

  static DmzUIModel createDmzUIModel({
    bool isEnabled = false,
    String destIp = '',
    DmzSourceType sourceType = DmzSourceType.any,
    String sourcePrefix = '',
  }) =>
      DmzUIModel(
        isEnabled: isEnabled,
        destIp: destIp,
        sourceType: sourceType,
        sourcePrefix: sourcePrefix,
      );

  static DmzUIModel createEnabledDmzUIModel({
    String destIp = '192.168.1.50',
  }) =>
      createDmzUIModel(isEnabled: true, destIp: destIp);

  // ---------------------------------------------------------------------------
  // Summaries (charts / cards)
  // ---------------------------------------------------------------------------

  static FirewallRuleSummary createRuleSummary({
    String target = 'Drop',
    bool enabled = true,
  }) =>
      FirewallRuleSummary(target: target, enabled: enabled);

  /// Two rules with opposite targets — enough to exercise the target
  /// distribution chart without depending on real rule descriptions.
  static List<FirewallRuleSummary> createRuleSummaries() => [
        createRuleSummary(target: 'Drop', enabled: true),
        createRuleSummary(target: 'Accept', enabled: false),
      ];

  static DmzEntrySummary createDmzSummary({
    bool enable = true,
    String destIp = '192.168.1.50',
  }) =>
      DmzEntrySummary(enable: enable, destIp: destIp);

  static List<DmzEntrySummary> createDmzSummaries() => [createDmzSummary()];

  // ---------------------------------------------------------------------------
  // Chain rules / rule context
  // ---------------------------------------------------------------------------

  /// The 12 named rules FLWRT 2.0.3 adds to `Device.Firewall.Chain.1`, at the
  /// instance numbers and default `Enable` values read off M60
  /// `2.0.3.26100921` (FWDEV#204).
  static FirewallChainRules createNamedChainRules({
    Set<String> without = const {},
  }) =>
      FirewallChainRules(
        items: [
          for (final (i, desc, enable, target) in const [
            (11, 'UDP_FORWARD_FOR_IGMP', true, 'Accept'),
            (21, 'RULE_SPI_IPV4_INPUT', false, 'Accept'),
            (22, 'RULE_SPI_IPV4_FORWARD', false, 'Accept'),
            (23, 'RULE_SPI_IPV6_INPUT', false, 'Accept'),
            (24, 'RULE_SPI_IPV6_FORWARD', false, 'Accept'),
            (25, 'RULE_PING_IPV4', false, 'Accept'),
            (26, 'RULE_IDENT_WAN', false, 'Accept'),
            (27, 'RULE_LAN2WAN_IPSEC', false, 'Drop'),
            (28, 'RULE_IPSEC_ESP', false, 'Drop'),
            (29, 'RULE_LAN2WAN_PPTP', false, 'Drop'),
            (30, 'RULE_LAN2WAN_L2TP', false, 'Drop'),
            (31, 'RULE_NAT_REDIRECTION', true, 'Accept'),
          ])
            if (!without.contains(desc))
              FirewallChainRule(
                instancePath: 'Device.Firewall.Chain.1.Rule.$i.',
                enable: enable,
                description: desc,
                target: target,
              ),
        ],
      );

  /// A context holding every named rule, the way the firewall page sees a
  /// router it can read.
  ///
  /// [without] drops rules by `Description`, for a router missing some of them.
  static FirewallRuleContext createNamedRuleContext({
    Set<String> without = const {},
  }) =>
      FirewallRuleContext.fromMap(
        UspFirewallService.parseFirewallRules(
            createNamedChainRules(without: without)),
      );

  // ---------------------------------------------------------------------------
  // Service fetch result
  // ---------------------------------------------------------------------------

  /// Result returned by a mocked [UspFirewallDataService.fetch].
  ///
  /// [FirewallRuleContext] is opaque to every consumer except the save path, so
  /// the empty context is the right default here — pass one built with
  /// `FirewallRuleContext.fromMap` only when a test actually saves.
  static FirewallDataFetchResult createFetchResult({
    FirewallUIModel? firewallModel,
    FirewallRuleContext? ruleContext,
    List<FirewallRuleSummary>? ruleSummaries,
    DmzUIModel? dmzModel,
    List<DmzEntrySummary>? dmzSummaries,
  }) =>
      FirewallDataFetchResult(
        firewallModel: firewallModel ?? createFirewallUIModel(),
        ruleContext: ruleContext ?? FirewallRuleContext.empty,
        ruleSummaries: ruleSummaries ?? createRuleSummaries(),
        dmzModel: dmzModel ?? createDmzUIModel(),
        dmzSummaries: dmzSummaries ?? const [],
      );

  // ---------------------------------------------------------------------------
  // FirewallData (L1)
  // ---------------------------------------------------------------------------

  static FirewallData createFirewallData({
    FirewallUIModel? firewallModel,
    FirewallRuleContext? ruleContext,
    List<FirewallRuleSummary>? ruleSummaries,
    DmzUIModel? dmzModel,
    List<DmzEntrySummary>? dmzSummaries,
  }) =>
      FirewallData(
        firewallModel: firewallModel ?? createFirewallUIModel(),
        ruleContext: ruleContext ?? FirewallRuleContext.empty,
        ruleSummaries: ruleSummaries ?? createRuleSummaries(),
        dmzModel: dmzModel ?? createDmzUIModel(),
        dmzSummaries: dmzSummaries ?? const [],
      );

  /// IPv4 SPI firewall off — the state the mascot's `firewallDisabled` trigger
  /// and the security health dimension both react to.
  static FirewallData createFirewallDisabledData() => createFirewallData(
        firewallModel: createFirewallUIModel(isIPv4FirewallEnabled: false),
      );
}
