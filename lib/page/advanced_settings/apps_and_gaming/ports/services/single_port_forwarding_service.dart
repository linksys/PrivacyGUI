import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_state.dart';
import 'package:privacy_gui/utils.dart';

final singlePortForwardingServiceProvider =
    Provider<SinglePortForwardingService>((ref) {
  return SinglePortForwardingService(ref.watch(routerRepositoryProvider));
});

/// Service for managing Single Port Forwarding rules.
///
/// Handles communication with JNAP API and transforms between
/// JNAP data models and UI models.
class SinglePortForwardingService {
  final RouterRepository _routerRepository;

  SinglePortForwardingService(this._routerRepository);

  /// Fetches single port forwarding settings from the router.
  ///
  /// Returns a tuple containing:
  /// - [SinglePortForwardingRuleListUIModel]: List of forwarding rules as UI models
  /// - [SinglePortForwardingListStatus]: Additional metadata (max rules, router IP, etc.)
  ///
  /// Throws [ServiceError] if the operation fails.
  Future<(SinglePortForwardingRuleListUIModel, SinglePortForwardingListStatus)>
      fetchSettings({bool forceRemote = false}) async {
    try {
      // Fetch LAN settings to get router IP and subnet mask
      final lanSettingsResponse = await _routerRepository.send(
        JNAPAction.getLANSettings,
        auth: true,
        fetchRemote: forceRemote,
      );
      final lanSettings =
          RouterLANSettings.fromMap(lanSettingsResponse.output);
      final ipAddress = lanSettings.ipAddress;
      final subnetMask = NetworkUtils.prefixLengthToSubnetMask(
          lanSettings.networkPrefixLength);

      // Fetch single port forwarding rules
      final response = await _routerRepository.send(
        JNAPAction.getSinglePortForwardingRules,
        fetchRemote: forceRemote,
        auth: true,
      );

      // Transform JNAP models to UI models
      final jnapRules = List.from(response.output['rules'])
          .map((e) => SinglePortForwardingRule.fromMap(e))
          .toList();

      final uiRules = jnapRules
          .map((jnapRule) => _jnapRuleToUIModel(jnapRule))
          .toList();

      final int maxRules = response.output['maxRules'] ?? 50;
      final int maxDescriptionLength =
          response.output['maxDescriptionLength'] ?? 32;

      final status = SinglePortForwardingListStatus(
        maxRules: maxRules,
        maxDescriptionLength: maxDescriptionLength,
        routerIp: ipAddress,
        subnetMask: subnetMask,
      );

      return (SinglePortForwardingRuleListUIModel(rules: uiRules), status);
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Saves single port forwarding settings to the router.
  ///
  /// Transforms UI models to JNAP models and sends them to the router.
  ///
  /// Throws [ServiceError] if the operation fails.
  Future<void> saveSettings(
      SinglePortForwardingRuleListUIModel settings) async {
    try {
      // Transform UI models to JNAP models
      final jnapRules =
          settings.rules.map((uiRule) => _uiModelToJnapRule(uiRule)).toList();

      await _routerRepository.send(
        JNAPAction.setSinglePortForwardingRules,
        data: {'rules': jnapRules.map((e) => e.toMap()).toList()},
        auth: true,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Transforms a JNAP rule to a UI model
  SinglePortForwardingRuleUIModel _jnapRuleToUIModel(
      SinglePortForwardingRule jnapRule) {
    return SinglePortForwardingRuleUIModel(
      isEnabled: jnapRule.isEnabled,
      externalPort: jnapRule.externalPort,
      protocol: jnapRule.protocol,
      internalServerIPAddress: jnapRule.internalServerIPAddress,
      internalPort: jnapRule.internalPort,
      description: jnapRule.description,
    );
  }

  /// Transforms a UI model to a JNAP rule
  SinglePortForwardingRule _uiModelToJnapRule(
      SinglePortForwardingRuleUIModel uiModel) {
    return SinglePortForwardingRule(
      isEnabled: uiModel.isEnabled,
      externalPort: uiModel.externalPort,
      protocol: uiModel.protocol,
      internalServerIPAddress: uiModel.internalServerIPAddress,
      internalPort: uiModel.internalPort,
      description: uiModel.description,
    );
  }

  /// Maps JNAP errors to ServiceError
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      'ErrorInvalidIPAddress' => const InvalidIPAddressError(),
      'ErrorInvalidDestinationIPAddress' =>
        const InvalidDestinationIPAddressError(),
      'ErrorInvalidInput' => InvalidInputError(message: error.error),
      'ErrorRuleOverlap' => const RuleOverlapError(),
      _ => UnexpectedError(originalError: error, message: error.error),
    };
  }
}