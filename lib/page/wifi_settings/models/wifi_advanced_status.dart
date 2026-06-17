import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient (non-editable) status for the WiFi Advanced feature page.
class WifiAdvancedStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;

  /// Typed error from the last fetch. The View localizes it via
  /// `localizeServiceError`; null means no error.
  final ServiceError? error;

  const WifiAdvancedStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  const WifiAdvancedStatus.loading()
      : isLoading = true,
        isSaving = false,
        error = null;

  WifiAdvancedStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return WifiAdvancedStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
