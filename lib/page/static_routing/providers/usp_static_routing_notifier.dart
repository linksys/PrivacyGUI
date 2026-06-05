import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_status.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';

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
  UspStaticRoutingService get _svc => ref.read(uspStaticRoutingServiceProvider);

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
      final routes = await _svc.fetch();

      logger.d('[USP][Network][Routing]: Fetched — '
          'static: ${routes.length}');

      return (
        StaticRouteList(routes: routes),
        const StaticRoutingStatus(),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Network][Routing]: Fetch failed', error: e);
      return (
        null,
        StaticRoutingStatus(error: e),
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
      final original = state.settings.original.routes;
      final current = state.settings.current.routes;

      await ref.read(uspMutationLockProvider).withLock(() async {
        final result = await _svc.saveBatch(
          original: original,
          current: current,
        );

        logger.d('[USP][Network][Routing]: Batch save — '
            'added: ${result.added}, updated: ${result.updated}, '
            'deleted: ${result.deleted}');
      });
    } on ServiceError catch (e) {
      logger.e('[USP][Network][Routing]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Local Mutations (synchronous — no network calls)
  // ---------------------------------------------------------------------------

  /// Add a new route locally.
  ///
  /// Resolves [StaticRouteUIModel.interfacePath] from [interfaceName] via the
  /// service layer so the view doesn't need to access the service directly.
  void addRoute(StaticRouteUIModel route) {
    assert(route.interfaceName.isNotEmpty, 'interfaceName must not be empty');
    final resolved = route.copyWith(
      interfacePath: _svc.mapDisplayToInterface(route.interfaceName),
    );
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        StaticRouteList(routes: [...current.routes, resolved]),
      ),
    );
  }

  /// Edit an existing route by index.
  ///
  /// Resolves [StaticRouteUIModel.interfacePath] from [interfaceName] via the
  /// service layer so the view doesn't need to access the service directly.
  void editRoute(int index, StaticRouteUIModel route) {
    assert(route.interfaceName.isNotEmpty, 'interfaceName must not be empty');
    final resolved = route.copyWith(
      interfacePath: _svc.mapDisplayToInterface(route.interfaceName),
    );
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes[index] = resolved;
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
