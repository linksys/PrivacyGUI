part of 'cubit.dart';

enum MacFilterStatus {
  off,
  allow,
  deny,
}

class MacFilteringState extends Equatable {
  final MacFilterStatus status;
  final List<PDevice> selectedDevices;

  @override
  List<Object> get props => [status, selectedDevices];

  const MacFilteringState({
    required this.status,
    required this.selectedDevices,
  });

  factory MacFilteringState.init() {
    return const MacFilteringState(
      status: MacFilterStatus.off,
      selectedDevices: [],
    );
  }

  MacFilteringState copyWith({
    MacFilterStatus? status,
    List<PDevice>? selectedDevices,
  }) {
    return MacFilteringState(
      status: status ?? this.status,
      selectedDevices: selectedDevices ?? this.selectedDevices,
    );
  }
}
