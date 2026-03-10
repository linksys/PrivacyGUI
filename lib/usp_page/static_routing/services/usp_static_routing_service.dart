import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/utils.dart';

final uspStaticRoutingServiceProvider = Provider<UspStaticRoutingService>(
  (ref) => UspStaticRoutingService(),
);

/// Transforms codegen [StaticRouting] data into [StaticRouteUIModel] list.
///
/// Responsibilities:
/// - Filter by Origin == "Static" (exclude kernel/DHCP routes)
/// - Map TR-181 interface paths to display names
/// - Validate route fields
class UspStaticRoutingService {
  static const _interfaceMap = {
    'Device.IP.Interface.1': 'LAN',
    'Device.IP.Interface.2': 'Internet',
  };

  static const _reverseInterfaceMap = {
    'LAN': 'Device.IP.Interface.1',
    'Internet': 'Device.IP.Interface.2',
  };

  static const interfaceOptions = ['LAN', 'Internet'];

  /// Build UI models from codegen data, filtering to static routes only.
  List<StaticRouteUIModel> buildRouteUIModels(StaticRouting data) {
    return data.items
        .where((r) => r.origin == 'Static')
        .map((r) => StaticRouteUIModel(
              instancePath: r.instancePath,
              enabled: r.enable,
              name: r.alias,
              destIpAddress: r.destIpAddress,
              destSubnetMask: r.destSubnetMask,
              gatewayIpAddress: r.gatewayIpAddress,
              interfaceName: _interfaceMap[r.interface_] ?? r.interface_,
              interfacePath: r.interface_,
            ))
        .toList();
  }

  /// Convert display name back to TR-181 interface path.
  String mapDisplayToInterface(String displayName) {
    return _reverseInterfaceMap[displayName] ?? displayName;
  }

  /// Validate a route entry. Returns a map of field → error message.
  Map<String, String> validateRoute({
    required String name,
    required String destIp,
    required String subnetMask,
    required String gateway,
  }) {
    final errors = <String, String>{};
    if (name.isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.length > 32) {
      errors['name'] = 'Name must be 32 characters or less';
    }
    if (destIp.isEmpty) {
      errors['destIp'] = 'Destination IP is required';
    } else if (!NetworkUtils.isValidIpAddress(destIp)) {
      errors['destIp'] = 'Invalid IP address';
    }
    if (subnetMask.isEmpty) {
      errors['subnetMask'] = 'Subnet mask is required';
    } else if (!NetworkUtils.isValidSubnetMask(subnetMask)) {
      errors['subnetMask'] = 'Invalid subnet mask';
    }
    if (gateway.isNotEmpty && !NetworkUtils.isValidIpAddress(gateway)) {
      errors['gateway'] = 'Invalid IP address';
    }
    return errors;
  }
}
