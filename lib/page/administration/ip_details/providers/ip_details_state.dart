import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/device.dart';

class IpDetailsState extends Equatable {
  final String ipv4WANType;
  final String ipv6WANType;
  final String ipv4WANAddress;
  final String ipv6WANAddress;
  final RawDevice? masterNode;
  final List<RawDevice> slaveNodes;
  final bool ipv4Renewing;
  final bool ipv6Renewing;
  final String? error;

  @override
  List<Object?> get props => [
        ipv4WANType,
        ipv4WANAddress,
        ipv4Renewing,
        ipv6WANType,
        ipv6WANAddress,
        ipv6Renewing,
        masterNode,
        slaveNodes,
        error
      ];

  const IpDetailsState({
    required this.ipv4WANType,
    required this.ipv6WANType,
    required this.ipv4WANAddress,
    required this.ipv6WANAddress,
    this.masterNode,
    this.slaveNodes = const [],
    this.ipv4Renewing = false,
    this.ipv6Renewing = false,
    this.error,
  });

  factory IpDetailsState.init() {
    return const IpDetailsState(
      ipv4WANType: '',
      ipv6WANType: '',
      ipv4WANAddress: '',
      ipv6WANAddress: '',
      masterNode: null,
      slaveNodes: [],
      ipv4Renewing: false,
      ipv6Renewing: false,
      error: null,
    );
  }

  IpDetailsState copyWith({
    String? ipv4WANType,
    String? ipv6WANType,
    String? ipv4WANAddress,
    String? ipv6WANAddress,
    RawDevice? masterNode,
    List<RawDevice>? slaveNodes,
    bool? ipv4Renewing,
    bool? ipv6Renewing,
    String? error,
  }) {
    return IpDetailsState(
      ipv4WANType: ipv4WANType ?? this.ipv4WANType,
      ipv6WANType: ipv6WANType ?? this.ipv6WANType,
      ipv4WANAddress: ipv4WANAddress ?? this.ipv4WANAddress,
      ipv6WANAddress: ipv6WANAddress ?? this.ipv6WANAddress,
      masterNode: masterNode ?? this.masterNode,
      slaveNodes: slaveNodes ?? this.slaveNodes,
      ipv4Renewing: ipv4Renewing ?? this.ipv4Renewing,
      ipv6Renewing: ipv6Renewing ?? this.ipv6Renewing,
      error: error ?? this.error,
    );
  }
}
