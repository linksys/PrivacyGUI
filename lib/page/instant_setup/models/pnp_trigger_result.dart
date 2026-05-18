import 'package:equatable/equatable.dart';

/// Method by which the router was auto-configured (if any).
///
/// Used for analytics and to potentially customize the PnP wizard flow
/// based on how the router was initially set up.
enum AutoConfigurationMethod {
  /// No auto-configuration detected — standard user setup.
  none,

  /// Linksys Auto Parent feature configured the router.
  autoParent,

  /// Router shipped with pre-configured WiFi credentials.
  preConfigured,
}

/// Result of checking whether PnP setup wizard is needed.
///
/// This UI model is returned by [PnpStatusService.check()] and used
/// by the router to decide whether to route to the PnP flow or dashboard.
class PnpTriggerResult extends Equatable {
  /// True if the user has NOT completed PnP setup and the wizard should be shown.
  final bool needsPnp;

  /// How the router was auto-configured (for future use with TR-181).
  final AutoConfigurationMethod configurationMethod;

  const PnpTriggerResult({
    required this.needsPnp,
    this.configurationMethod = AutoConfigurationMethod.none,
  });

  /// Factory for when PnP is not needed (user already completed setup).
  factory PnpTriggerResult.notNeeded() =>
      const PnpTriggerResult(needsPnp: false);

  /// Factory for when PnP is needed (first-time setup or new router).
  factory PnpTriggerResult.needed({
    AutoConfigurationMethod method = AutoConfigurationMethod.none,
  }) =>
      PnpTriggerResult(needsPnp: true, configurationMethod: method);

  @override
  List<Object?> get props => [needsPnp, configurationMethod];
}
