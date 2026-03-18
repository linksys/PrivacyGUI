import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_status.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/usp_page/static_routing/services/usp_static_routing_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspStaticRoutingProvider = AutoDisposeNotifierProvider<
    UspStaticRoutingNotifier, StaticRoutingFeatureState>(
  UspStaticRoutingNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspStaticRoutingProvider = AutoDisposeProvider<
    PreservableContract<StaticRouteList, StaticRoutingStatus>>(
  (ref) => ref.watch(uspStaticRoutingProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspStaticRoutingNotifier
    extends AutoDisposeNotifier<StaticRoutingFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<StaticRouteList,
            StaticRoutingStatus, StaticRoutingFeatureState> {
  UspStaticRoutingService get _svc =>
      ref.read(uspStaticRoutingServiceProvider);

  @override
  StaticRoutingFeatureState build() {
    // SSE invalidation: re-fetch when static routes change externally.
    // Uses the framework's onSseInvalidation() — skips if dirty.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull == InvalidationDomain.staticRouting) {
        onSseInvalidation();
      }
    });

    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return StaticRoutingFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(StaticRouteList?, StaticRoutingStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final usp = ref.read(uspServiceProvider)!;
      final data = await StaticRouting.fetch(usp);
      final routes = _svc.buildRouteUIModels(data);

      logger.d('[USP][Network][Routing] Fetched — '
          'total: ${data.items.length}, static: ${routes.length}');

      return (
        StaticRouteList(routes: routes),
        const StaticRoutingStatus(),
      );
    } catch (e) {
      logger.e('[USP][Network][Routing] Fetch failed', error: e);
      return (
        null,
        StaticRoutingStatus(errorMessage: '$e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — diff original vs current, batch API calls
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final usp = ref.read(uspServiceProvider)!;
      final original = state.settings.original.routes;
      final current = state.settings.current.routes;

      await ref.read(uspMutationLockProvider).withLock(() async {
        // 1. Determine items to delete (in original, not in current)
        final currentPaths = <String>{
          for (final r in current)
            if (r.instancePath != null) r.instancePath!,
        };
        final toDelete = original
            .where((r) =>
                r.instancePath != null &&
                !currentPaths.contains(r.instancePath))
            .toList();

        for (var i = 0; i < toDelete.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          await StaticRouting.delete(usp, toDelete[i].instancePath!);
        }

        // 2. Determine items to add (instancePath == null → new)
        final toAdd = current.where((r) => r.instancePath == null).toList();

        for (var i = 0; i < toAdd.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          final r = toAdd[i];
          await StaticRouting.add(
            usp,
            enable: r.enabled,
            destIpAddress: r.destIpAddress,
            destSubnetMask: r.destSubnetMask,
            gatewayIpAddress: r.gatewayIpAddress,
            interface_: _svc.mapDisplayToInterface(r.interfaceName),
            alias: r.name,
          );
        }

        // 3. Determine items to update (same path, different content)
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
              interface_: _svc.mapDisplayToInterface(cur.interfaceName),
              alias: cur.name,
            ));
          }
        }

        if (toUpdate.isNotEmpty) {
          await StaticRouting.updateMany(usp, toUpdate);
        }

        logger.d('[USP][Network][Routing] Batch save — '
            'added: ${toAdd.length}, updated: ${toUpdate.length}, '
            'deleted: ${toDelete.length}');
      });
    } catch (e) {
      logger.e('[USP][Network][Routing] Save failed', error: e);
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Local Mutations (synchronous — no network calls)
  // ---------------------------------------------------------------------------

  /// Add a new route locally.
  void addRoute(StaticRouteUIModel route) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        StaticRouteList(routes: [...current.routes, route]),
      ),
    );
  }

  /// Edit an existing route by index.
  void editRoute(int index, StaticRouteUIModel route) {
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes[index] = route;
    state = state.copyWith(
      settings: state.settings.update(StaticRouteList(routes: routes)),
    );
  }

  /// Toggle enable/disable on a route by index.
  void toggleRoute(int index, bool enabled) {
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes[index] = routes[index].copyWith(enabled: enabled);
    state = state.copyWith(
      settings: state.settings.update(StaticRouteList(routes: routes)),
    );
  }

  /// Delete a route by index.
  void deleteRoute(int index) {
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes.removeAt(index);
    state = state.copyWith(
      settings: state.settings.update(StaticRouteList(routes: routes)),
    );
  }
}
