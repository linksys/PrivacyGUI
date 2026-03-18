import 'package:equatable/equatable.dart';

/// Transient status for the Port Forwarding detail page.
class PortForwardingPageStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const PortForwardingPageStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  PortForwardingPageStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return PortForwardingPageStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
