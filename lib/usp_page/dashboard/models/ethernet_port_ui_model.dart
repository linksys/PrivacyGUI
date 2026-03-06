import 'package:equatable/equatable.dart';

/// A wired device connected to an Ethernet port.
class WiredDeviceInfo extends Equatable {
  final String hostName;
  final String macAddress;
  final String ipAddress;

  const WiredDeviceInfo({
    required this.hostName,
    required this.macAddress,
    required this.ipAddress,
  });

  String get displayName =>
      hostName.isNotEmpty ? hostName : macAddress;

  @override
  List<Object?> get props => [hostName, macAddress, ipAddress];
}

/// Presentation Layer Model for a physical Ethernet port.
class EthernetPortUIModel extends Equatable {
  final String name;
  final String label;
  final bool isWan;
  final bool isUp;
  final String instancePath;
  final int currentBitRate;
  final List<WiredDeviceInfo> connectedDevices;

  const EthernetPortUIModel({
    required this.name,
    required this.label,
    required this.isWan,
    required this.isUp,
    required this.instancePath,
    required this.currentBitRate,
    this.connectedDevices = const [],
  });

  /// Formatted speed label for display.
  String get speedLabel {
    if (!isUp || currentBitRate <= 0) return '—';
    if (currentBitRate >= 1000) {
      return currentBitRate % 1000 == 0
          ? '${currentBitRate ~/ 1000} Gbps'
          : '${(currentBitRate / 1000).toStringAsFixed(1)} Gbps';
    }
    return '$currentBitRate Mbps';
  }

  @override
  List<Object?> get props => [
        name,
        label,
        isWan,
        isUp,
        instancePath,
        currentBitRate,
        connectedDevices,
      ];
}
