import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient (non-editable) status for the Administration page.
class AdministrationStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  final ServiceError? error;

  const AdministrationStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  const AdministrationStatus.loading()
      : isLoading = true,
        isSaving = false,
        error = null;

  AdministrationStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return AdministrationStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
