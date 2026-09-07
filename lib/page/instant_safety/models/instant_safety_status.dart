import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient (non-editable) status for the Instant Safety feature page.
class InstantSafetyStatus extends Equatable {
  /// Whether the page is still waiting for its first data.
  ///
  /// Defaults to `false` so that forgetting it fails safe. The View checks
  /// this *before* [error] (`instant_safety_view.dart`), so a status that
  /// carries an error while [isLoading] is still `true` renders an endless
  /// loader and never reaches the error view or its Retry button. Only
  /// `InstantSafetyFeatureState.initial()` should opt into `true`.
  final bool isLoading;

  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  final ServiceError? error;

  const InstantSafetyStatus({
    this.isLoading = false,
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
