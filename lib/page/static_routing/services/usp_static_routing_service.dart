import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

final uspStaticRoutingServiceProvider = Provider<UspStaticRoutingService>(
  (ref) => UspStaticRoutingService(ref.read(uspClientProvider)!),
);

/// Service layer for Static Routing — encapsulates codegen CRUD + transform.
class UspStaticRoutingService {
  /// The display name of each interface a route can use, by `Alias`.
  static const _displayByAlias = {'lan': 'LAN', 'wan': 'Internet'};

  final UspClient _usp;

  UspStaticRoutingService(this._usp);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch static routes and transform to UI models.
  Future<List<StaticRouteUIModel>> fetch() async {
    try {
      final results = await Future.wait([
        StaticRouting.fetch(_usp),
        _interfaceNames(),
      ]);
      return buildRouteUIModels(
          results[0] as StaticRouting, results[1] as Map<String, String>);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// `Device.IP.Interface.{i}` → display name, for the lan and wan interfaces
  /// as the router names them by `Alias`.
  Future<Map<String, String>> _interfaceNames() async {
    final aliases = await _usp.get(['Device.IP.Interface.*.Alias']);
    return {
      for (final entry in aliases.entries)
        if (_displayByAlias[entry.value] case final name?)
          if (RegExp(r'^(Device\.IP\.Interface\.\d+)\.Alias$')
                  .firstMatch(entry.key)
              case final match?)
            match.group(1)!: name,
    };
  }

  /// The interface path a route with [displayName] is written with, or
  /// [displayName] itself when it is not one this page names.
  static String _interfacePathOf(
      String displayName, Map<String, String> interfaceNames) {
    for (final entry in interfaceNames.entries) {
      if (entry.value == displayName) return entry.key;
    }
    return displayName;
  }

  /// The router new routes are added under: the first one the router lists
  /// (one on the bench).
  Future<String> _routerPath() async {
    final router = (await StaticRouting.fetch(_usp)).items.firstOrNull;
    if (router == null) {
      throw const ResourceNotFoundError(
          detail: 'No Device.Routing.Router on the router');
    }
    return router.instancePath;
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
        final result =
            await StaticRouting.deleteForwardings(_usp, [r.instancePath!]);
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

      // A route is written with the path of the interface its display name
      // names now, resolved by Alias.
      final toAdd = current.where((r) => r.instancePath == null).toList();
      final originalByPath = <String, StaticRouteUIModel>{
        for (final r in original)
          if (r.instancePath != null) r.instancePath!: r,
      };
      final toChange = [
        for (final cur in current)
          if (cur.instancePath != null &&
              originalByPath[cur.instancePath!] != null &&
              cur != originalByPath[cur.instancePath!])
            cur,
      ];
      final interfaceNames = toAdd.isEmpty && toChange.isEmpty
          ? const <String, String>{}
          : await _interfaceNames();

      // 2. Add (instancePath == null → new)
      if (toAdd.isNotEmpty) {
        final routerPath = await _routerPath();
        final result = await StaticRouting.addForwardings(
          _usp,
          toAdd
              .map((r) => StaticRouteAdd(
                    parentInstancePath: routerPath,
                    enable: r.enabled,
                    destIpAddress: r.destIpAddress,
                    destSubnetMask: r.destSubnetMask,
                    gatewayIpAddress: r.gatewayIpAddress,
                    interface_:
                        _interfacePathOf(r.interfaceName, interfaceNames),
                    alias: r.name,
                  ))
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
      final toUpdate = [
        for (final cur in toChange)
          StaticRouteUpdate(
            instancePath: cur.instancePath!,
            enable: cur.enabled,
            destIpAddress: cur.destIpAddress,
            destSubnetMask: cur.destSubnetMask,
            gatewayIpAddress: cur.gatewayIpAddress,
            interface_: _interfacePathOf(cur.interfaceName, interfaceNames),
            alias: cur.name,
          ),
      ];

      if (toUpdate.isNotEmpty) {
        final result = await StaticRouting.updateForwardings(_usp, toUpdate);
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
  ///
  /// [interfaceNames] maps an interface path to its display name; a route on
  /// any other interface shows its path.
  List<StaticRouteUIModel> buildRouteUIModels(
    StaticRouting data,
    Map<String, String> interfaceNames,
  ) {
    return data.items
        .expand((router) => router.forwardings)
        .where((r) => r.origin == 'Static')
        .map((r) => StaticRouteUIModel(
              instancePath: r.instancePath,
              enabled: r.enable,
              name: r.alias,
              destIpAddress: r.destIpAddress,
              destSubnetMask: r.destSubnetMask,
              gatewayIpAddress: r.gatewayIpAddress,
              interfaceName: _interfaceNameOf(r.interface_, interfaceNames),
              interfacePath: r.interface_,
            ))
        .toList();
  }

  /// The display name of the interface at [path], or [path] itself when it
  /// is not one this page names. A route's `Interface` may or may not carry
  /// a trailing dot.
  static String _interfaceNameOf(
      String path, Map<String, String> interfaceNames) {
    for (final entry in interfaceNames.entries) {
      if (ensureTrailingDot(entry.key) == ensureTrailingDot(path)) {
        return entry.value;
      }
    }
    return path;
  }

  /// The page's copy of a route keeps only the display name; the path it is
  /// written with is resolved at save time.
  String mapDisplayToInterface(String displayName) => displayName;
}
