import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;

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
    this.interfacePath = '',
  });

  /// Stable, kebab-case key for E2E `identifier` hooks (e.g.
  /// `static-route-edit-<key>`). Derived from the route name ("Web Server" →
  /// "web-server"); falls back to the saved instance number, then "unnamed",
  /// so it is always non-empty and never collides across rows.
  String get identifierKey => ruleIdentifierKey(name, instancePath);

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
