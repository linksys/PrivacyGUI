import 'package:equatable/equatable.dart';

/// Transient status for the static routing page.
class StaticRoutingStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const StaticRoutingStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  StaticRoutingStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return StaticRoutingStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
