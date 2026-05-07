import 'package:equatable/equatable.dart';

/// Transient (non-editable) status for the WiFi Advanced feature page.
class WifiAdvancedStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const WifiAdvancedStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  const WifiAdvancedStatus.loading()
      : isLoading = true,
        isSaving = false,
        errorMessage = null;

  WifiAdvancedStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return WifiAdvancedStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
