import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/dynamic_routing.g.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/services/batch_tally.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

final uspStaticRoutingServiceProvider = Provider<UspStaticRoutingService>(
  (ref) => UspStaticRoutingService(ref.read(uspClientProvider)!),
);

/// Service layer for Static Routing — encapsulates codegen CRUD + transform.
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

  /// Batch save: diff original vs current, then Delete, Set and Add.
  ///
  /// The order is FW's (FWDEV#213): a Delete frees its route's slot and name
  /// before anything else is written, and a Set frees an old name before an
  /// Add takes it. The page checks the save in this same order
  /// ([StaticRouteUIModel.validateList]).
  ///
  /// A step that fails, fully or partly, stops the save: the next step was
  /// checked against a router the failed step was meant to change, and at 20
  /// routes an Add after a failed Delete is a 21st. It throws
  /// [UspCompleteFailureError] when nothing was written, otherwise
  /// [UspPartialFailureError]. A refusal that carries one of FWDEV#213's error
  /// names becomes an [InvalidInputError] whose `field` is that name, so the
  /// page can say which check FW applied.
  ///
  /// The page checks every value FW refuses before it saves: a refused Add
  /// reaches the app as a success and leaves a row without the refused leaf
  /// (bench 2026-10-21), so only a Set is ever seen to fail here.
  Future<({int added, int updated, int deleted})> saveBatch({
    required List<StaticRouteUIModel> original,
    required List<StaticRouteUIModel> current,
  }) async {
    final tally = BatchTally('[StaticRouting]');
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
        tally.record('Delete', UspResultParser.parseDeleteResult(result));
        tally.throwIfAnyFailed();
      }

      // 2. Update (same path, different content)
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
        tally.record('Update', UspResultParser.parseSetResult(result));
        tally.throwIfAnyFailed();
      }

      // 3. Add (instancePath == null → new)
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
        tally.record('Add', UspResultParser.parseAddResult(result));
        tally.throwIfAnyFailed();
      }

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } on UspCompleteFailureError catch (e) {
      throw _named(e.failures) ?? e;
    } on UspPartialFailureError catch (e) {
      throw _named(e.failures) ?? e;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  static InvalidInputError? _named(List<UspErrorDetail> failures) {
    final refusal = refusalNameIn(failures, StaticRouteRefusalNames.all);
    if (refusal == null) return null;
    return InvalidInputError(
      field: refusal.name,
      code: refusal.detail.errorCode,
      detail: refusal.detail.errorMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // NAT / Dynamic routing (RIP)
  // ---------------------------------------------------------------------------

  /// Whether RIP runs; NAT is its opposite (linksys/FWDEV#213).
  ///
  /// Call only where `DeviceCapability.dynamicRouting` holds: the router has
  /// the leaf, so a value that does not come back is a failed read. The WASM
  /// client resolves a failed Get with empty data, and the optional codegen
  /// field reads that as null.
  Future<bool> fetchRipEnabled() async {
    try {
      final enable = (await DynamicRouting.fetch(_usp)).enable;
      if (enable == null) {
        throw const NetworkError(detail: 'Device.Routing.RIP.Enable not read');
      }
      return enable;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// One Set of `Device.Routing.RIP.Enable`. FW turns NAT off with RIP on and
  /// back on with it off; `Device.NAT.InterfaceSetting` is not written.
  Future<void> saveRipEnabled(bool enabled) async {
    try {
      final result = await DynamicRouting.update(_usp, enable: enabled);
      final parsed = UspResultParser.parseSetResult(result);
      if (parsed case UspFailure(:final errorSummary, :final errors)) {
        throw UspCompleteFailureError(
          summary: 'Routing mode update failed: $errorSummary',
          failures: errors,
        );
      }
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
}
