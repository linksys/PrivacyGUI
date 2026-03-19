import 'package:equatable/equatable.dart';

/// Transient (non-editable) status for the firewall feature page.
class FirewallStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const FirewallStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  FirewallStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return FirewallStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
