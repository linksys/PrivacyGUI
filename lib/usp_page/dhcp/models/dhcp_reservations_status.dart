import 'package:equatable/equatable.dart';

/// Transient status for the DHCP Reservations page notifier.
class DhcpReservationsStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const DhcpReservationsStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  DhcpReservationsStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return DhcpReservationsStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
