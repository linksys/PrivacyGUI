import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

/// Transient status for the DHCP Reservations page notifier.
class DhcpReservationsStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final ServiceError? error;

  const DhcpReservationsStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  DhcpReservationsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    ServiceError? error,
    bool clearError = false,
  }) {
    return DhcpReservationsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error];
}
