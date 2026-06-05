import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient status for the IPv6 port service page.
class Ipv6PortServiceStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final ServiceError? error;

  const Ipv6PortServiceStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  Ipv6PortServiceStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return Ipv6PortServiceStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
