import 'package:equatable/equatable.dart';

/// Transient (non-editable) status for the Instant Safety feature page.
class InstantSafetyStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const InstantSafetyStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  InstantSafetyStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return InstantSafetyStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
