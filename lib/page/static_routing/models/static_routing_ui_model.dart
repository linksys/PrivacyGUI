import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

/// Error keys returned by [StaticRouteUIModel.validateRoute].
/// Use these to map to l10n strings in the View layer.
class StaticRoutingErrorKeys {
  static const nameRequired = 'nameRequired';
  static const nameTooLong = 'nameTooLong';
  static const destIpRequired = 'destIpRequired';
  static const invalidIpAddress = 'invalidIpAddress';
  static const subnetMaskRequired = 'subnetMaskRequired';
  static const invalidSubnetMask = 'invalidSubnetMask';
  static const gatewayMustBeWithinLanSubnet = 'gatewayMustBeWithinLanSubnet';
  static const gatewayMustBeOutsideLanSubnet = 'gatewayMustBeOutsideLanSubnet';
}

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

  /// The interface choices the route dialog offers, as display names.
  static const interfaceOptions = ['LAN', 'Internet'];

  /// Validate a route entry. Returns a map of field → [StaticRoutingErrorKeys]
  /// key.
  ///
  /// When [lanIp] and [lanSubnetMask] are provided, validates gateway subnet:
  /// - LAN interface: gateway must be within LAN subnet
  /// - Internet interface: gateway must be outside LAN subnet
  static Map<String, String> validateRoute({
    required String name,
    required String destIp,
    required String subnetMask,
    required String gateway,
    String? interfaceName,
    String? lanIp,
    String? lanSubnetMask,
  }) {
    final errors = <String, String>{};
    if (name.isEmpty) {
      errors['name'] = StaticRoutingErrorKeys.nameRequired;
    } else if (name.length > 32) {
      errors['name'] = StaticRoutingErrorKeys.nameTooLong;
    }
    if (destIp.isEmpty) {
      errors['destIp'] = StaticRoutingErrorKeys.destIpRequired;
    } else if (!NetworkUtils.isValidIpAddress(destIp)) {
      errors['destIp'] = StaticRoutingErrorKeys.invalidIpAddress;
    }
    if (subnetMask.isEmpty) {
      errors['subnetMask'] = StaticRoutingErrorKeys.subnetMaskRequired;
    } else if (!NetworkUtils.isValidSubnetMask(subnetMask)) {
      errors['subnetMask'] = StaticRoutingErrorKeys.invalidSubnetMask;
    }
    if (gateway.isNotEmpty && !NetworkUtils.isValidIpAddress(gateway)) {
      errors['gateway'] = StaticRoutingErrorKeys.invalidIpAddress;
    } else if (gateway.isNotEmpty &&
        interfaceName != null &&
        lanIp != null &&
        lanIp.isNotEmpty &&
        lanSubnetMask != null &&
        lanSubnetMask.isNotEmpty &&
        NetworkUtils.isValidIpAddress(lanIp) &&
        NetworkUtils.isValidSubnetMask(lanSubnetMask)) {
      // Validate gateway subnet based on interface selection.
      final lanSubnetRule = HostValidForGivenRouterIPAddressAndSubnetMaskRule(
        lanIp,
        lanSubnetMask,
      );
      final isInLan = lanSubnetRule.validate(gateway);
      if (interfaceName == 'LAN' && !isInLan) {
        errors['gateway'] = StaticRoutingErrorKeys.gatewayMustBeWithinLanSubnet;
      } else if (interfaceName == 'Internet' && isInLan) {
        errors['gateway'] =
            StaticRoutingErrorKeys.gatewayMustBeOutsideLanSubnet;
      }
    }
    return errors;
  }

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

  /// [interfacePath] is left out: the route is written with the path its
  /// [interfaceName] resolves to at save time, so a path re-derived by an edit
  /// is not a change to the route.
  @override
  List<Object?> get props => [
        instancePath,
        enabled,
        name,
        destIpAddress,
        destSubnetMask,
        gatewayIpAddress,
        interfaceName,
      ];
}
