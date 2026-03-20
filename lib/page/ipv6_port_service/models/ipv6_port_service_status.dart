import 'package:equatable/equatable.dart';

/// Transient status for the IPv6 port service page.
class Ipv6PortServiceStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const Ipv6PortServiceStatus({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  Ipv6PortServiceStatus copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return Ipv6PortServiceStatus(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
