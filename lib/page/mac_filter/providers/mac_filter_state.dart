import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

/// A device shown in the MAC Filter list editor / device picker.
class MacFilterDeviceUIModel extends Equatable {
  final String mac;
  final String displayName;
  final bool isPrivateMac;
  final String ipAddress;

  const MacFilterDeviceUIModel({
    required this.mac,
    required this.displayName,
    this.isPrivateMac = false,
    this.ipAddress = '',
  });

  @override
  List<Object?> get props => [mac, displayName, isPrivateMac, ipAddress];
}

/// What the service hands the notifier at load time.
class MacFilterFetchResult {
  final MacFilterMode mode;
  final List<String> macs;
  final List<MacFilterDeviceUIModel> connectedDevices;

  const MacFilterFetchResult({
    required this.mode,
    required this.macs,
    required this.connectedDevices,
  });
}

/// The MAC Filter page state: the mode, the configured list, the devices
/// available to pick from, and a busy flag while a write is in flight.
class MacFilterState extends Equatable {
  final MacFilterMode mode;
  final List<String> macs;
  final List<MacFilterDeviceUIModel> connectedDevices;
  final bool isBusy;

  const MacFilterState({
    required this.mode,
    required this.macs,
    required this.connectedDevices,
    this.isBusy = false,
  });

  bool get isEnabled => mode != MacFilterMode.disabled;

  MacFilterState copyWith({
    MacFilterMode? mode,
    List<String>? macs,
    List<MacFilterDeviceUIModel>? connectedDevices,
    bool? isBusy,
  }) {
    return MacFilterState(
      mode: mode ?? this.mode,
      macs: macs ?? this.macs,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [mode, macs, connectedDevices, isBusy];
}
