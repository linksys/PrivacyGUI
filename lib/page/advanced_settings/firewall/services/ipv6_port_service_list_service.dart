import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/providers/empty_status.dart';

// Re-export PortRange for use in transformRulesToJNAP
export 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart'
    show PortRange;

/// Service for managing IPv6 port service rules.
/// Acts as pure adapter between JNAP layer and UI layer.
/// Transforms JNAP IPv6FirewallRule models to IPv6PortServiceRuleUI models and vice versa.
///
/// Architecture Layer: Application (Service)
/// - Depends on: Data layer (JNAP models)
/// - Used by: Presentation layer (Providers and Views)
/// - Never has direct JNAP imports in users (Provider/View)
class IPv6PortServiceListService {
  /// Fetches IPv6 port service rules from JNAP and transforms to UI models.
  ///
  /// Transformation pipeline:
  /// 1. JNAP IPv6FirewallRule (with portRanges list)
  /// 2. → IPv6PortServiceRuleUI (UI model for presentation)
  /// 3. → List returned to Presentation layer
  ///
  /// Parameters:
  /// - rules: List of JNAP IPv6FirewallRule objects
  ///
  /// Returns:
  /// - IPv6PortServiceRuleUIList with transformed UI models, EmptyStatus on success
  /// - null on error
  Future<(IPv6PortServiceRuleUIList?, EmptyStatus?)> fetchPortServiceRules(
    List<IPv6FirewallRule> rules,
  ) async {
    try {
      final uiRules = _transformRuleListToUI(rules);
      return (IPv6PortServiceRuleUIList(rules: uiRules), const EmptyStatus());
    } catch (e, stackTrace) {
      logger.e('Error fetching IPv6 port service rules',
          error: e, stackTrace: stackTrace);
      return (null, null);
    }
  }

  /// Private: Transforms list of JNAP IPv6FirewallRule to UI models
  ///
  /// Applies transformation to each rule:
  /// - JNAP IPv6FirewallRule has portRanges (list) field
  /// - UI IPv6PortServiceRuleUI maps portRanges to UI PortRangeUI list
  /// - Each field is validated and transformed
  ///
  /// Throws exception if transformation fails for any rule
  List<IPv6PortServiceRuleUI> _transformRuleListToUI(
      List<IPv6FirewallRule> rules) {
    return rules.map((rule) => _transformRuleToUI(rule)).toList();
  }

  /// Private: Transforms single JNAP IPv6FirewallRule to UI model
  ///
  /// Transformation details:
  /// - isEnabled → enabled
  /// - description → description (unchanged)
  /// - ipv6Address → ipv6Address (unchanged, validated as IPv6)
  /// - portRanges[] → portRanges[] (map each PortRange to PortRangeUI)
  ///
  /// Each PortRange transformation:
  /// - protocol → protocol (TCP/UDP/Both)
  /// - firstPort → firstPort (0-65535)
  /// - lastPort → lastPort (0-65535)
  ///
  /// Throws exception if any field cannot be transformed
  IPv6PortServiceRuleUI _transformRuleToUI(IPv6FirewallRule rule) {
    return IPv6PortServiceRuleUI(
      enabled: rule.isEnabled,
      description: rule.description,
      ipv6Address: rule.ipv6Address,
      portRanges: rule.portRanges
          .map((pr) => PortRangeUI(
                protocol: pr.protocol,
                firstPort: pr.firstPort,
                lastPort: pr.lastPort,
              ))
          .toList(),
    );
  }

  /// Transforms UI models back to JNAP models for saving.
  ///
  /// Reverse transformation pipeline:
  /// 1. IPv6PortServiceRuleUI (UI model)
  /// 2. → IPv6FirewallRule (JNAP model for transmission)
  ///
  /// Parameters:
  /// - rules: List of UI IPv6PortServiceRuleUI objects
  ///
  /// Returns:
  /// - List of JNAP IPv6FirewallRule objects ready for transmission
  List<IPv6FirewallRule> transformRulesToJNAP(
    List<IPv6PortServiceRuleUI> rules,
  ) {
    return rules.map((rule) => _transformRuleToJNAP(rule)).toList();
  }

  /// Private: Transforms single UI IPv6PortServiceRuleUI to JNAP model
  ///
  /// Transformation details:
  /// - enabled → isEnabled
  /// - description → description (unchanged)
  /// - ipv6Address → ipv6Address (unchanged)
  /// - portRanges[] → portRanges[] (map each PortRangeUI to PortRange)
  ///
  /// Each PortRange transformation:
  /// - protocol → protocol (TCP/UDP/Both)
  /// - firstPort → firstPort
  /// - lastPort → lastPort
  ///
  /// Throws exception if any field cannot be transformed
  IPv6FirewallRule _transformRuleToJNAP(IPv6PortServiceRuleUI rule) {
    return IPv6FirewallRule(
      isEnabled: rule.enabled,
      description: rule.description,
      ipv6Address: rule.ipv6Address,
      portRanges: rule.portRanges
          .map((pr) => PortRange(
                protocol: pr.protocol,
                firstPort: pr.firstPort,
                lastPort: pr.lastPort,
              ))
          .toList(),
    );
  }
}
