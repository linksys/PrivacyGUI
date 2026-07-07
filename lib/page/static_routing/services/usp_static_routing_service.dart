import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final uspStaticRoutingServiceProvider = Provider<UspStaticRoutingService>(
  (ref) => UspStaticRoutingService(ref.read(uspClientProvider)!),
);

/// Service layer for Static Routing — encapsulates codegen CRUD + transform + validation.
class UspStaticRoutingService {
  final UspClient _usp;

  UspStaticRoutingService(this._usp);

  static const _interfaceMap = {
    'Device.IP.Interface.1': 'LAN',
    'Device.IP.Interface.2': 'Internet',
  };

  static const _reverseInterfaceMap = {
    'LAN': 'Device.IP.Interface.1',
    'Internet': 'Device.IP.Interface.2',
  };

  static const interfaceOptions = ['LAN', 'Internet'];

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch static routes and transform to UI models.
  Future<List<StaticRouteUIModel>> fetch() async {
    try {
      final data = await StaticRouting.fetch(_usp);
      return buildRouteUIModels(data);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Batch save: diff original vs current, execute delete/add/update.
  ///
  /// Lenient mode: partial success is acceptable for batch operations,
  /// only log warnings. Complete failure still throws.
  Future<({int added, int updated, int deleted})> saveBatch({
    required List<StaticRouteUIModel> original,
    required List<StaticRouteUIModel> current,
  }) async {
    try {
      // 1. Delete (in original, not in current)
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();

      // Delete in reverse instance order to avoid firmware renumbering issues
      for (final r in toDelete.reversed) {
        final result = await StaticRouting.delete(_usp, [r.instancePath!]);
        final parsed = UspResultParser.parseDeleteResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(:final successes, :final failures):
            logger.w(
                '[StaticRouting]: Batch delete partial: ${successes.length} ok, ${failures.length} failed');
            break;
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'Static routing batch delete failed: $errorSummary',
              failures: errors,
            );
        }
      }

      // 2. Add (instancePath == null → new)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      if (toAdd.isNotEmpty) {
        final result = await StaticRouting.add(
          _usp,
          toAdd
              .map((r) => {
                    'Enable': r.enabled,
                    'DestIPAddress': r.destIpAddress,
                    'DestSubnetMask': r.destSubnetMask,
                    'GatewayIPAddress': r.gatewayIpAddress,
                    'Interface': mapDisplayToInterface(r.interfaceName),
                    'Alias': r.name,
                  })
              .toList(),
        );
        final parsed = UspResultParser.parseAddResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(:final successes, :final failures):
            logger.w(
                '[StaticRouting]: Batch add partial: ${successes.length} ok, ${failures.length} failed');
            break;
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'Static routing batch add failed: $errorSummary',
              failures: errors,
            );
        }
      }

      // 3. Update (same path, different content)
      final originalByPath = <String, StaticRouteUIModel>{
        for (final r in original)
          if (r.instancePath != null) r.instancePath!: r,
      };

      final toUpdate = <StaticRouteUpdate>[];
      for (final cur in current) {
        if (cur.instancePath == null) continue;
        final orig = originalByPath[cur.instancePath!];
        if (orig == null) continue;
        if (cur != orig) {
          toUpdate.add(StaticRouteUpdate(
            instancePath: cur.instancePath!,
            enable: cur.enabled,
            destIpAddress: cur.destIpAddress,
            destSubnetMask: cur.destSubnetMask,
            gatewayIpAddress: cur.gatewayIpAddress,
            interface_: mapDisplayToInterface(cur.interfaceName),
            alias: cur.name,
          ));
        }
      }

      if (toUpdate.isNotEmpty) {
        final result = await StaticRouting.update(_usp, toUpdate);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(:final successes, :final failures):
            logger.w(
                '[StaticRouting]: Batch update partial: ${successes.length} ok, ${failures.length} failed');
            break;
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'Static routing batch update failed: $errorSummary',
              failures: errors,
            );
        }
      }

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Transform
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate a route entry. Returns a map of field → error message.
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
    } else if (gateway.isNotEmpty &&
        interfaceName != null &&
        lanIp != null &&
        lanSubnetMask != null) {
      // Validate gateway subnet based on interface selection.
      final lanSubnetRule = HostValidForGivenRouterIPAddressAndSubnetMaskRule(
        lanIp,
        lanSubnetMask,
      );
      final isInLan = lanSubnetRule.validate(gateway);
      if (interfaceName == 'LAN' && !isInLan) {
        errors['gateway'] = 'Gateway must be within LAN subnet';
      } else if (interfaceName == 'Internet' && isInLan) {
        errors['gateway'] = 'Gateway must be outside LAN subnet';
      }
    }
    return errors;
  }
}
