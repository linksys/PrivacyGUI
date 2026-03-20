import 'package:equatable/equatable.dart';

/// UI model for a single static route entry.
///
/// [instancePath] is `null` for newly created (local-only) routes
/// that have not yet been saved to the device.
class StaticRouteUIModel extends Equatable {
  final String? instancePath;
  final bool enabled;
  final String name;
  final String destIpAddress;
  final String destSubnetMask;
  final String gatewayIpAddress;
  final String interfaceName;
  final String interfacePath;

  const StaticRouteUIModel({
    this.instancePath,
    required this.enabled,
    required this.name,
    required this.destIpAddress,
    required this.destSubnetMask,
    required this.gatewayIpAddress,
    required this.interfaceName,
    required this.interfacePath,
  });

  StaticRouteUIModel copyWith({
    String? instancePath,
    bool? enabled,
    String? name,
    String? destIpAddress,
    String? destSubnetMask,
    String? gatewayIpAddress,
    String? interfaceName,
    String? interfacePath,
  }) {
    return StaticRouteUIModel(
      instancePath: instancePath ?? this.instancePath,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
      destIpAddress: destIpAddress ?? this.destIpAddress,
      destSubnetMask: destSubnetMask ?? this.destSubnetMask,
      gatewayIpAddress: gatewayIpAddress ?? this.gatewayIpAddress,
      interfaceName: interfaceName ?? this.interfaceName,
      interfacePath: interfacePath ?? this.interfacePath,
    );
  }

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
