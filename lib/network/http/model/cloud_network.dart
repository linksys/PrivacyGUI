import 'package:equatable/equatable.dart';

@Deprecated('MOAB version')
class CloudNetwork extends Equatable {
  final String networkGroupId;
  final String networkId;
  final String serialNumber;
  final String macAddress;
  final String ownerId;
  final String region;

  @override
  List<Object?> get props => [
        networkGroupId,
        networkId,
        serialNumber,
        macAddress,
        ownerId,
        region,
      ];

  const CloudNetwork({
    required this.networkGroupId,
    required this.networkId,
    required this.serialNumber,
    required this.macAddress,
    required this.ownerId,
    required this.region,
  });

  CloudNetwork copyWith({
    String? networkGroupId,
    String? networkId,
    String? serialNumber,
    String? macAddress,
    String? ownerId,
    String? region,
  }) {
    return CloudNetwork(
      networkGroupId: networkGroupId ?? this.networkGroupId,
      networkId: networkId ?? this.networkId,
      serialNumber: serialNumber ?? this.serialNumber,
      macAddress: macAddress ?? this.macAddress,
      ownerId: ownerId ?? this.ownerId,
      region: region ?? this.region,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'networkGroupId': networkGroupId,
      'networkId': networkId,
      'serialNumber': serialNumber,
      'macAddress': macAddress,
      'ownerId': ownerId,
      'region': region,
    };
  }

  factory CloudNetwork.fromJson(Map<String, dynamic> json) {
    return CloudNetwork(
      networkGroupId: json['networkGroupId'],
      networkId: json['networkId'],
      serialNumber: json['serialNumber'],
      macAddress: json['macAddress'],
      ownerId: json['ownerId'],
      region: json['region'],
    );
  }
}
