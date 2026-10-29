import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/has_service_error.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';

/// Transient (non-editable) status for the firewall feature page.
class FirewallStatus extends Equatable implements HasServiceError {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  @override
  final ServiceError? error;

  /// Switches whose rule is not on the router. Each would show a value the
  /// router never reported, and a save would write nothing for it (#1611).
  final Set<FirewallSwitch> lockedSwitches;

  const FirewallStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.lockedSwitches = const {},
  });

  FirewallStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
    Set<FirewallSwitch>? lockedSwitches,
  }) {
    return FirewallStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      lockedSwitches: lockedSwitches ?? this.lockedSwitches,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error, lockedSwitches];
}
