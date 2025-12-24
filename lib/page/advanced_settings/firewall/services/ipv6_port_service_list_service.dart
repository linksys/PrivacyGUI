import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
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
  /// Fetches IPv6 firewall rules from device via JNAP and transforms to UI models.
  ///
  /// This method encapsulates the entire fetch operation:
  /// 1. Executes JNAP action to retrieve IPv6 firewall rules
  /// 2. Parses JNAP response into data layer models
  /// 3. Transforms data models to UI models
  ///
  /// Parameters:
  /// - ref: Riverpod ref for accessing router repository
  /// - forceRemote: Whether to force remote fetch (bypass cache)
  ///
  /// Returns:
  /// - IPv6PortServiceRuleUIList with transformed UI models, EmptyStatus on success
  /// - (null, null) if fetch or transformation fails
  Future<(IPv6PortServiceRuleUIList?, EmptyStatus?)> fetchRulesFromDevice(
    Ref ref, {
    bool forceRemote = false,
  }) async {
    try {
      final repo = ref.read(routerRepositoryProvider);

      // Execute JNAP action to retrieve IPv6 firewall rules
      final result = await repo.send(
        JNAPAction.getIPv6FirewallRules,
        auth: true,
        fetchRemote: forceRemote,
      );

      // Parse Data layer model (JNAP response)
      final dataModel = IPv6FirewallRuleList.fromMap(result.output);

      // Transform to Application layer UI model
      final (uiRules, status) = await fetchPortServiceRules(dataModel.rules);

      if (uiRules == null) {
        return (null, null);
      }

      return (uiRules, status);
    } catch (e, stackTrace) {
      logger.e('Error fetching IPv6 port service rules from device',
          error: e, stackTrace: stackTrace);
      return (null, null);
    }
  }

  /// Saves UI rules to device via JNAP.
  ///
  /// This method encapsulates the entire save operation:
  /// 1. Transforms UI models back to JNAP models
  /// 2. Builds JNAP request payload
  /// 3. Executes JNAP action to save rules to device
  ///
  /// Parameters:
  /// - ref: Riverpod ref for accessing router repository
  /// - rules: List of UI models to save
  ///
  /// Throws exception if save fails
  Future<void> saveRulesToDevice(
    Ref ref,
    List<IPv6PortServiceRuleUI> rules,
  ) async {
    try {
      final repo = ref.read(routerRepositoryProvider);

      // Transform UI rules back to JNAP models
      final jnapRules = transformRulesToJNAP(rules);

      // Build JNAP model for transmission
      final dataModel = IPv6FirewallRuleList(rules: jnapRules);

      // Execute JNAP action to save IPv6 firewall rules
      await repo.send(
        JNAPAction.setIPv6FirewallRules,
        auth: true,
        fetchRemote: true,
        data: dataModel.toMap(),
      );
    } catch (e, stackTrace) {
      logger.e('Error saving IPv6 port service rules to device',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches IPv6 port service rules from JNAP and transforms to UI models.
  ///
  /// Transformation pipeline:
  /// 1. JNAP IPv6FirewallRule (with portRanges list)
  /// 2. → IPv6PortServiceRuleUI (UI model for presentation)
  /// 3. → List returned to Presentation layer
  ///
  /// This method implements partial success handling:
  /// - If some rules fail transformation, valid rules are still returned
  /// - Failed rules are logged with their index and error details
  /// - Empty list returns (null, null) to indicate failure
  ///
  /// Error handling covers:
  /// - Null or invalid rules input
  /// - Invalid protocol values (must be TCP/UDP/Both)
  /// - Out-of-range port numbers
  /// - Malformed IPv6 addresses
  /// - Incomplete rule data
  ///
  /// Parameters:
  /// - rules: List of JNAP IPv6FirewallRule objects
  ///
  /// Returns:
  /// - IPv6PortServiceRuleUIList with transformed UI models (may be partial), EmptyStatus on success
  /// - (null, null) if all rules fail transformation or input is invalid
  Future<(IPv6PortServiceRuleUIList?, EmptyStatus?)> fetchPortServiceRules(
    List<IPv6FirewallRule> rules,
  ) async {
    try {
      // Validate input (rules parameter is already guaranteed non-null)

      if (rules.isEmpty) {
        logger.d('Empty IPv6 port service rules list');
        return (
          IPv6PortServiceRuleUIList(rules: const []),
          const EmptyStatus()
        );
      }

      // Transform rules with partial success handling
      final (validRules, failedIndices) =
          _transformRuleListToUIWithErrors(rules);

      // Log failures if any occurred
      if (failedIndices.isNotEmpty) {
        logger.w(
          'Some IPv6 port service rules failed transformation',
          error: 'Failed indices: ${failedIndices.join(", ")}',
        );
      }

      // Return null if no valid rules were transformed
      if (validRules.isEmpty) {
        logger.e('All IPv6 port service rules failed transformation');
        return (null, null);
      }

      logger.d(
          'Successfully transformed ${validRules.length}/${rules.length} IPv6 port service rules');
      return (
        IPv6PortServiceRuleUIList(rules: validRules),
        const EmptyStatus()
      );
    } catch (e, stackTrace) {
      logger.e('Error fetching IPv6 port service rules',
          error: e, stackTrace: stackTrace);
      return (null, null);
    }
  }

  /// Private: Transforms list of JNAP IPv6FirewallRule to UI models with error recovery.
  ///
  /// This method implements partial success handling:
  /// - Attempts to transform each rule individually
  /// - Collects valid rules and failed rule indices
  /// - Logs detailed error information for each failure
  /// - Returns both valid rules and list of failed indices
  ///
  /// Returns: Tuple of (List<IPv6PortServiceRuleUI>, List<int>)
  /// - First element: List of successfully transformed rules
  /// - Second element: List of indices of rules that failed transformation
  (List<IPv6PortServiceRuleUI>, List<int>) _transformRuleListToUIWithErrors(
    List<IPv6FirewallRule> rules,
  ) {
    final validRules = <IPv6PortServiceRuleUI>[];
    final failedIndices = <int>[];

    for (int i = 0; i < rules.length; i++) {
      try {
        final rule = _transformRuleToUI(rules[i]);
        validRules.add(rule);
      } catch (e) {
        logger.w(
          'Failed to transform IPv6 port service rule at index $i',
          error: e.toString(),
        );
        failedIndices.add(i);
      }
    }

    return (validRules, failedIndices);
  }

  /// Private: Transforms single JNAP IPv6FirewallRule to UI model with validation.
  ///
  /// Transformation details:
  /// - isEnabled → enabled
  /// - description → description (unchanged)
  /// - ipv6Address → ipv6Address (validated as IPv6)
  /// - portRanges[] → portRanges[] (validates each PortRange)
  ///
  /// Each PortRange validation:
  /// - protocol must be TCP/UDP/Both
  /// - firstPort must be 0-65535
  /// - lastPort must be 0-65535
  /// - firstPort must be <= lastPort
  ///
  /// Throws exception if any field cannot be transformed or is invalid
  IPv6PortServiceRuleUI _transformRuleToUI(IPv6FirewallRule rule) {
    // Validate description is present
    if (rule.description.isEmpty) {
      throw Exception('Rule description is missing or empty');
    }

    // Validate IPv6 address is present
    if (rule.ipv6Address.isEmpty) {
      throw Exception('Rule IPv6 address is missing or empty');
    }

    // Validate port ranges list
    if (rule.portRanges.isEmpty) {
      throw Exception('Rule has no port ranges');
    }

    // Transform port ranges with validation
    final transformedRanges = <PortRangeUI>[];
    for (int i = 0; i < rule.portRanges.length; i++) {
      final pr = rule.portRanges[i];
      _validatePortRange(pr, i);
      transformedRanges.add(PortRangeUI(
        protocol: pr.protocol,
        firstPort: pr.firstPort,
        lastPort: pr.lastPort,
      ));
    }

    return IPv6PortServiceRuleUI(
      enabled: rule.isEnabled,
      description: rule.description,
      ipv6Address: rule.ipv6Address,
      portRanges: transformedRanges,
    );
  }

  /// Private: Validates a single port range entry.
  ///
  /// Ensures:
  /// - Protocol is TCP, UDP, or Both
  /// - Port numbers are in valid range (0-65535)
  /// - firstPort <= lastPort
  ///
  /// Parameters:
  /// - [portRange]: The PortRange to validate
  /// - [index]: Index for error messages
  ///
  /// Throws exception if validation fails
  void _validatePortRange(PortRange portRange, int index) {
    // Validate protocol
    const validProtocols = ['TCP', 'UDP', 'Both'];
    if (!validProtocols.contains(portRange.protocol)) {
      throw Exception(
        'Port range at index $index has invalid protocol: ${portRange.protocol}. Must be TCP, UDP, or Both.',
      );
    }

    // Validate port numbers
    const minPort = 0;
    const maxPort = 65535;

    if (portRange.firstPort < minPort || portRange.firstPort > maxPort) {
      throw Exception(
        'Port range at index $index has invalid firstPort: ${portRange.firstPort}. Must be 0-65535.',
      );
    }

    if (portRange.lastPort < minPort || portRange.lastPort > maxPort) {
      throw Exception(
        'Port range at index $index has invalid lastPort: ${portRange.lastPort}. Must be 0-65535.',
      );
    }

    // Validate port order
    if (portRange.firstPort > portRange.lastPort) {
      throw Exception(
        'Port range at index $index is invalid: firstPort (${portRange.firstPort}) > lastPort (${portRange.lastPort}).',
      );
    }
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

final ipv6PortServiceListServiceProvider = Provider<IPv6PortServiceListService>(
  (ref) => IPv6PortServiceListService(),
);
