import 'package:equatable/equatable.dart';

class DMZStatus extends Equatable {
  final String ipAddress;
  final String subnetMask;

  const DMZStatus({
    this.ipAddress = '192.168.1.1',
    this.subnetMask = '255.255.0.0',
  });

  @override
  List<Object> get props => [ipAddress, subnetMask];

  DMZStatus copyWith({
    String? ipAddress,
    String? subnetMask,
  }) {
    return DMZStatus(
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ipAddress': ipAddress,
      'subnetMask': subnetMask,
    };
  }

  factory DMZStatus.fromMap(Map<String, dynamic> map) {
    return DMZStatus(
      ipAddress: map['ipAddress'] ?? '192.168.1.1',
      subnetMask: map['subnetMask'] ?? '255.255.0.0',
    );
  }
}
