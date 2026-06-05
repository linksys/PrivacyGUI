import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient (non-editable) status for the firewall feature page.
class FirewallStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final ServiceError? error;

  const FirewallStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  FirewallStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return FirewallStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
