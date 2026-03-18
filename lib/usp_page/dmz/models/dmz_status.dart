import 'package:equatable/equatable.dart';

/// Transient (non-editable) status for the DMZ feature page.
class DmzStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const DmzStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  DmzStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return DmzStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage, fieldErrors];
}
