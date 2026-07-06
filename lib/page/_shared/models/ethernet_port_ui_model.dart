import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// A wired device connected to an Ethernet port.
class WiredDeviceInfo extends Equatable with DiagnosticLoggable {
  final String hostName;
  final String macAddress;
  final String ipAddress;

  const WiredDeviceInfo({
    required this.hostName,
    required this.macAddress,
    required this.ipAddress,
  });

  String get displayName => hostName.isNotEmpty ? hostName : macAddress;

  @override
  String get diagnosticName => 'WiredDeviceInfo';

  @override
  Map<String, Object?> get namedProps => {
        'hostName': hostName,
        'macAddress': macAddress,
        'ipAddress': ipAddress,
      };
}

/// Presentation Layer Model for a physical Ethernet port.
class EthernetPortUIModel extends Equatable with DiagnosticLoggable {
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
  String get diagnosticName => 'EthernetPortUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'name': name,
        'label': label,
        'isWan': isWan,
        'isUp': isUp,
        'instancePath': instancePath,
        'currentBitRate': currentBitRate,
        'connectedDevices': connectedDevices,
      };
}
