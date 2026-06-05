import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient (non-editable) status for the local network feature page.
///
/// Includes per-field validation errors from cascade validation.
class LocalNetworkStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final ServiceError? error;

  /// Per-field validation errors (field key → error message).
  /// null value = no error for that field.
  final Map<String, String?> validationErrors;

  /// Number of fully-locked octets derived from the current subnet mask.
  /// Used by the view to lock IP pool field prefixes.
  final int lockedOctetCount;

  const LocalNetworkStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.validationErrors = const {},
    this.lockedOctetCount = 0,
  });

  bool get hasValidationErrors => validationErrors.values.any((e) => e != null);

  LocalNetworkStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
    Map<String, String?>? validationErrors,
    int? lockedOctetCount,
  }) {
    return LocalNetworkStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      validationErrors: validationErrors ?? this.validationErrors,
      lockedOctetCount: lockedOctetCount ?? this.lockedOctetCount,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSaving, error, validationErrors, lockedOctetCount];
}
