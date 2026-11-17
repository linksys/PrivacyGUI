import 'package:equatable/equatable.dart';

/// Result of checking whether PnP setup wizard is needed.
///
/// This UI model is returned by [PnpStatusService.check()] and used
/// by the router to decide whether to route to the PnP flow or dashboard.
class PnpTriggerResult extends Equatable {
  /// True if the user has NOT completed PnP setup and the wizard should be shown.
  final bool needsPnp;

  const PnpTriggerResult({required this.needsPnp});

  /// Factory for when PnP is not needed (user already completed setup).
  factory PnpTriggerResult.notNeeded() =>
      const PnpTriggerResult(needsPnp: false);

  /// Factory for when PnP is needed (first-time setup or new router).
  factory PnpTriggerResult.needed() => const PnpTriggerResult(needsPnp: true);

  @override
  List<Object?> get props => [needsPnp];
}
