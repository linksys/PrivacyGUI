import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_state.dart';

final portRangeTriggeringServiceProvider =
    Provider<PortRangeTriggeringService>((ref) {
  return PortRangeTriggeringService(ref.watch(routerRepositoryProvider));
});

/// Service for managing Port Range Triggering rules.
///
/// Handles communication with JNAP API and transforms between
/// JNAP data models and UI models.
class PortRangeTriggeringService {
  final RouterRepository _routerRepository;

  PortRangeTriggeringService(this._routerRepository);

  /// Fetches port range triggering settings from the router.
  ///
  /// Returns a tuple containing:
  /// - [PortRangeTriggeringRuleListUIModel]: List of triggering rules as UI models
  /// - [PortRangeTriggeringListStatus]: Additional metadata (max rules, max description length)
  ///
  /// Throws [ServiceError] if the operation fails.
  Future<(PortRangeTriggeringRuleListUIModel, PortRangeTriggeringListStatus)>
      fetchSettings({bool forceRemote = false}) async {
    try {
      // Fetch port range triggering rules
      final response = await _routerRepository.send(
        JNAPAction.getPortRangeTriggeringRules,
        fetchRemote: forceRemote,
        auth: true,
      );

      // Transform JNAP models to UI models
      final jnapRules = List.from(response.output['rules'])
          .map((e) => PortRangeTriggeringRule.fromMap(e))
          .toList();

      final uiRules =
          jnapRules.map((jnapRule) => _jnapRuleToUIModel(jnapRule)).toList();

      final int maxRules = response.output['maxRules'] ?? 50;
      final int maxDescriptionLength =
          response.output['maxDescriptionLength'] ?? 32;

      final status = PortRangeTriggeringListStatus(
        maxRules: maxRules,
        maxDescriptionLength: maxDescriptionLength,
      );

      return (PortRangeTriggeringRuleListUIModel(rules: uiRules), status);
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Saves port range triggering settings to the router.
  ///
  /// Transforms UI models to JNAP models and sends them to the router.
  ///
  /// Throws [ServiceError] if the operation fails.
  Future<void> saveSettings(PortRangeTriggeringRuleListUIModel settings) async {
    try {
      // Transform UI models to JNAP models
      final jnapRules =
          settings.rules.map((uiRule) => _uiModelToJnapRule(uiRule)).toList();

      await _routerRepository.send(
        JNAPAction.setPortRangeTriggeringRules,
        data: {'rules': jnapRules.map((e) => e.toMap()).toList()},
        auth: true,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Transforms a JNAP rule to a UI model
  PortRangeTriggeringRuleUIModel _jnapRuleToUIModel(
      PortRangeTriggeringRule jnapRule) {
    return PortRangeTriggeringRuleUIModel(
      isEnabled: jnapRule.isEnabled,
      firstTriggerPort: jnapRule.firstTriggerPort,
      lastTriggerPort: jnapRule.lastTriggerPort,
      firstForwardedPort: jnapRule.firstForwardedPort,
      lastForwardedPort: jnapRule.lastForwardedPort,
      description: jnapRule.description,
    );
  }

  /// Transforms a UI model to a JNAP rule
  PortRangeTriggeringRule _uiModelToJnapRule(
      PortRangeTriggeringRuleUIModel uiModel) {
    return PortRangeTriggeringRule(
      isEnabled: uiModel.isEnabled,
      firstTriggerPort: uiModel.firstTriggerPort,
      lastTriggerPort: uiModel.lastTriggerPort,
      firstForwardedPort: uiModel.firstForwardedPort,
      lastForwardedPort: uiModel.lastForwardedPort,
      description: uiModel.description,
    );
  }

  /// Maps JNAP errors to ServiceError
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      'ErrorInvalidInput' => InvalidInputError(message: error.error),
      'ErrorRuleOverlap' => const RuleOverlapError(),
      _ => UnexpectedError(originalError: error, message: error.error),
    };
  }
}
