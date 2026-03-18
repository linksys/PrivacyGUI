import 'package:equatable/equatable.dart';

/// Transient (non-editable) status for the DMZ feature page.
class DmzStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const DmzStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  DmzStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return DmzStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
