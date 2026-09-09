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
