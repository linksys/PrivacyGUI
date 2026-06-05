import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient status for the Port Forwarding detail page.
class PortForwardingPageStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final ServiceError? error;

  const PortForwardingPageStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  PortForwardingPageStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return PortForwardingPageStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
