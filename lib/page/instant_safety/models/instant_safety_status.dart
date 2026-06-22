import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient (non-editable) status for the Instant Safety feature page.
class InstantSafetyStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  final ServiceError? error;

  const InstantSafetyStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  InstantSafetyStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return InstantSafetyStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
