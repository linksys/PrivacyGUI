import 'package:equatable/equatable.dart';

/// A device shown in the MAC Filter / Instant Privacy list editor and picker.
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
