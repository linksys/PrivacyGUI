import 'package:equatable/equatable.dart';

/// UI model for a single static route entry.
class StaticRouteUIModel extends Equatable {
  final String instancePath;
  final bool enabled;
  final String name;
  final String destIpAddress;
  final String destSubnetMask;
  final String gatewayIpAddress;
  final String interfaceName;
  final String interfacePath;

  const StaticRouteUIModel({
    required this.instancePath,
    required this.enabled,
    required this.name,
    required this.destIpAddress,
    required this.destSubnetMask,
    required this.gatewayIpAddress,
    required this.interfaceName,
    required this.interfacePath,
  });

  @override
  List<Object?> get props => [
        instancePath,
        enabled,
        name,
        destIpAddress,
        destSubnetMask,
        gatewayIpAddress,
        interfaceName,
        interfacePath,
      ];
}
