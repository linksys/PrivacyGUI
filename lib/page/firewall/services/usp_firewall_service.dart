import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';

final uspFirewallServiceProvider = Provider<UspFirewallService>(
  (ref) => UspFirewallService(ref.read(uspClientProvider)!),
);

/// The rule keys (see `_descToFeature`) behind each switch. A switch is
/// usable only when all of them are on the router: the same pairs
/// `buildSetPayload` writes together.
const _switchRuleKeys = <FirewallSwitch, List<String>>{
  FirewallSwitch.ipv4Firewall: ['spiV4Input', 'spiV4Forward'],
  FirewallSwitch.ipv6Firewall: ['spiV6Input', 'spiV6Forward'],
  FirewallSwitch.ipsec: ['ipsec1', 'ipsec2'],
  FirewallSwitch.pptp: ['pptp'],
  FirewallSwitch.l2tp: ['l2tp'],
  FirewallSwitch.anonymousRequests: ['anonymousRequests'],
  FirewallSwitch.multicast: ['multicast'],
  FirewallSwitch.natRedirection: ['natRedirection'],
  FirewallSwitch.ident: ['ident'],
};

/// [_switchRuleKeys], for tests that build a context holding every rule.
@visibleForTesting
List<String> debugRuleKeysOf(FirewallSwitch s) => _switchRuleKeys[s]!;

/// Opaque wrapper around parsed firewall rule data.
///
/// Notifiers and models hold this without knowing the inner codegen type.
/// Only [UspFirewallService] can create and consume it.
class FirewallRuleContext extends Equatable {
  final Map<String, FirewallChainRule> _ruleMap;
  const FirewallRuleContext._(this._ruleMap);

  /// Create from a pre-parsed rule map (used by data provider).
  const FirewallRuleContext.fromMap(Map<String, FirewallChainRule> ruleMap)
      : _ruleMap = ruleMap;

  /// Empty context for initial/loading state.
  static const empty = FirewallRuleContext._({});

  /// No rule on the router matched a known Linksys rule name, so no toggle
  /// can be read or written.
  bool get isEmpty => _ruleMap.isEmpty;

  /// The switches missing at least one of their rules on the router. Each
  /// would show a value the router never reported, and a save would skip it.
  Set<FirewallSwitch> get lockedSwitches => {
        for (final s in FirewallSwitch.values)
          if (!_switchRuleKeys[s]!.every(_ruleMap.containsKey)) s,
      };

  /// The parsed rules, for tests that hand a context to `buildSetPayload`.
  @visibleForTesting
  Map<String, FirewallChainRule> get debugRuleMap => _ruleMap;

  @override
  List<Object?> get props => [_ruleMap];
}

/// Service layer for Firewall — encapsulates codegen CRUD + transform.
///
/// Rule identification uses Description field matching against known
/// Linksys firewall rule names. Toggle logic varies by rule Target:
/// - Accept rules: feature ON = rule disabled (bypass rule inactive)
/// - Drop rules: block ON = rule enabled (drop rule active)
class UspFirewallService {
  final UspClient _usp;

  UspFirewallService(this._usp);
  // -------------------------------------------------------------------------
  // High-level API (for Notifier consumption)
  // -------------------------------------------------------------------------

  /// Parse chain rules and build UI model + opaque context.
  (FirewallUIModel, FirewallRuleContext) buildFromChainRules(
    FirewallChainRules rules,
  ) {
    final ruleMap = parseFirewallRules(rules);
    final model = buildUIModel(rules: ruleMap);
    return (model, FirewallRuleContext._(ruleMap));
  }

  /// Save changed firewall toggles. Returns the number of rules updated.
  Future<int> save({
    required FirewallUIModel original,
    required FirewallUIModel pending,
    required FirewallRuleContext context,
  }) async {
    try {
      final updates = buildSetPayload(
        original: original,
        pending: pending,
        rules: context._ruleMap,
      );
      // A changed toggle with no rule on the router has nothing to write.
      // Reporting that as a 0-rule save is how FW 2.0.2's missing rules went
      // unnoticed (#1611).
      if (updates.isEmpty && pending != original) {
        throw const ResourceNotFoundError(
          detail: 'No firewall rule on the router for the changed setting',
        );
      }
      // Update all firewall rules in batch
      if (updates.isNotEmpty) {
        final result = await FirewallChainRules.update(_usp, updates);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(
              :final errorSummary,
              :final successes,
              :final failures
            ):
            // Firewall rules are paired — partial success is unacceptable
            throw UspPartialFailureError(
              summary: 'Firewall update partial failure: $errorSummary',
              successPaths: successes.map((s) => s.requestedPath).toList(),
              failures: failures,
            );
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'Firewall update failed: $errorSummary',
              failures: errors,
            );
        }
      }
      return updates.length;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // -------------------------------------------------------------------------
  // Rule Description → feature key mapping
  // -------------------------------------------------------------------------

  /// Maps Rule Description strings to internal feature keys.
  static const _descToFeature = {
    'RULE_SPI_IPV4_INPUT': 'spiV4Input',
    'RULE_SPI_IPV4_FORWARD': 'spiV4Forward',
    'RULE_SPI_IPV6_INPUT': 'spiV6Input',
    'RULE_SPI_IPV6_FORWARD': 'spiV6Forward',
    'UDP_FORWARD_FOR_IGMP': 'multicast',
    'RULE_PING_IPV4': 'anonymousRequests',
    'RULE_IDENT_WAN': 'ident',
    'RULE_LAN2WAN_IPSEC': 'ipsec1',
    'RULE_IPSEC_ESP': 'ipsec2',
    'RULE_LAN2WAN_PPTP': 'pptp',
    'RULE_LAN2WAN_L2TP': 'l2tp',
    'RULE_NAT_REDIRECTION': 'natRedirection',
  };

  // -------------------------------------------------------------------------
  // Parse codegen rules
  // -------------------------------------------------------------------------

  /// Parse [FirewallChainRules] into a map of feature key → [FirewallChainRule].
  ///
  /// Matches each rule's Description against [_descToFeature].
  static Map<String, FirewallChainRule> parseFirewallRules(
    FirewallChainRules rules,
  ) {
    final map = <String, FirewallChainRule>{};
    for (final rule in rules.items) {
      final featureKey = _descToFeature[rule.description];
      if (featureKey == null) continue;
      map[featureKey] = rule;
    }
    return map;
  }

  // -------------------------------------------------------------------------
  // Build UI model
  // -------------------------------------------------------------------------

  /// Build [FirewallUIModel] from parsed rules.
  ///
  /// Toggle logic:
  /// - Accept rules (SPI, Ping, IDENT, Multicast, NAT redirection):
  ///   feature ON = !enable
  /// - Drop rules (IPSec, PPTP, L2TP): block = enable
  static FirewallUIModel buildUIModel({
    required Map<String, FirewallChainRule> rules,
  }) {
    // Accept rules: feature ON when rule is disabled. An absent rule reads off:
    // with nothing behind the switch, nothing is being filtered (#1611).
    bool acceptOff(String key) {
      final rule = rules[key];
      return rule != null && !rule.enable;
    }

    // Drop rules: block ON when rule is enabled
    bool dropOn(String key) => rules[key]?.enable ?? false;

    return FirewallUIModel(
      // SPI: use the INPUT rule as primary signal (paired rules stay in sync)
      isIPv4FirewallEnabled: acceptOff('spiV4Input'),
      isIPv6FirewallEnabled: acceptOff('spiV6Input'),
      blockIPSec: dropOn('ipsec1'),
      blockPPTP: dropOn('pptp'),
      blockL2TP: dropOn('l2tp'),
      blockAnonymousRequests: acceptOff('anonymousRequests'),
      blockMulticast: acceptOff('multicast'),
      blockIDENT: acceptOff('ident'),
      blockNATRedirection: acceptOff('natRedirection'),
    );
  }

  // -------------------------------------------------------------------------
  // Build SET payload
  // -------------------------------------------------------------------------

  /// Compare [original] and [pending] models and produce a list of
  /// [FirewallChainRuleUpdate] for changed rules.
  ///
  /// Only changed fields are included. Paired rules (SPI, IPSec) are
  /// kept in sync automatically.
  List<FirewallChainRuleUpdate> buildSetPayload({
    required FirewallUIModel original,
    required FirewallUIModel pending,
    required Map<String, FirewallChainRule> rules,
  }) {
    final updates = <FirewallChainRuleUpdate>[];

    void addAcceptRule(String key, bool featureOn) {
      final rule = rules[key];
      if (rule == null) return;
      // Accept rule: feature ON → disable rule
      updates.add(FirewallChainRuleUpdate(
        instancePath: rule.instancePath,
        enable: !featureOn,
      ));
    }

    void addDropRule(String key, bool block) {
      final rule = rules[key];
      if (rule == null) return;
      // Drop rule: block → enable rule
      updates.add(FirewallChainRuleUpdate(
        instancePath: rule.instancePath,
        enable: block,
      ));
    }

    // IPv4 SPI — paired rules 10+11
    if (pending.isIPv4FirewallEnabled != original.isIPv4FirewallEnabled) {
      addAcceptRule('spiV4Input', pending.isIPv4FirewallEnabled);
      addAcceptRule('spiV4Forward', pending.isIPv4FirewallEnabled);
    }

    // IPv6 SPI — paired rules 12+13
    if (pending.isIPv6FirewallEnabled != original.isIPv6FirewallEnabled) {
      addAcceptRule('spiV6Input', pending.isIPv6FirewallEnabled);
      addAcceptRule('spiV6Forward', pending.isIPv6FirewallEnabled);
    }

    // IPSec — paired rules 21+22
    if (pending.blockIPSec != original.blockIPSec) {
      addDropRule('ipsec1', pending.blockIPSec);
      addDropRule('ipsec2', pending.blockIPSec);
    }

    // PPTP — single rule 23
    if (pending.blockPPTP != original.blockPPTP) {
      addDropRule('pptp', pending.blockPPTP);
    }

    // L2TP — single rule 24
    if (pending.blockL2TP != original.blockL2TP) {
      addDropRule('l2tp', pending.blockL2TP);
    }

    // Anonymous requests — single rule 19
    if (pending.blockAnonymousRequests != original.blockAnonymousRequests) {
      addAcceptRule('anonymousRequests', pending.blockAnonymousRequests);
    }

    // Multicast — single rule 18
    if (pending.blockMulticast != original.blockMulticast) {
      addAcceptRule('multicast', pending.blockMulticast);
    }

    // IDENT — single rule 20
    if (pending.blockIDENT != original.blockIDENT) {
      addAcceptRule('ident', pending.blockIDENT);
    }

    // NAT redirection — single rule (FWDEV#204)
    if (pending.blockNATRedirection != original.blockNATRedirection) {
      addAcceptRule('natRedirection', pending.blockNATRedirection);
    }

    return updates;
  }
}
