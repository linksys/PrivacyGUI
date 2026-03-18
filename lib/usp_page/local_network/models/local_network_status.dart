import 'package:equatable/equatable.dart';

/// Transient (non-editable) status for the local network feature page.
///
/// Includes per-field validation errors from cascade validation.
class LocalNetworkStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  /// Per-field validation errors (field key → error message).
  /// null value = no error for that field.
  final Map<String, String?> validationErrors;

  const LocalNetworkStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.validationErrors = const {},
  });

  bool get hasValidationErrors =>
      validationErrors.values.any((e) => e != null);

  LocalNetworkStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    Map<String, String?>? validationErrors,
  }) {
    return LocalNetworkStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSaving, errorMessage, validationErrors];
}
