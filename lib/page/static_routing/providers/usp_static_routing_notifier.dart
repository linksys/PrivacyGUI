import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable.dart';
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

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspStaticRoutingNotifier
    extends AutoDisposeNotifier<StaticRoutingFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<StaticRouteList,
            StaticRoutingStatus, StaticRoutingFeatureState> {
  UspStaticRoutingService get _svc => ref.read(uspStaticRoutingServiceProvider);

  bool get _offersRip =>
      ref.read(deviceCapabilitiesProvider).has(DeviceCapability.dynamicRouting);

  @override
  StaticRoutingFeatureState build() {
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
      // Only where the router offers it: an image without linksys-ripd has no
      // Device.Routing.RIP (feed_usp#56), and the page still lists routes.
      final ripEnabled = _offersRip ? await _svc.fetchRipEnabled() : null;

      logger.d('[USP][Network][Routing]: Fetched — '
          'static: ${routes.length}, rip: $ripEnabled');

      return (
        StaticRouteList(routes: routes, ripEnabled: ripEnabled),
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
  // save — check the list first, re-read the router after a failed write
  // ---------------------------------------------------------------------------

  /// Checks the list as it will be sent before anything is written: FW refuses
  /// a duplicate name or a 21st route (FWDEV#213), and a refused Add still
  /// leaves a broken row behind, so the page is the guard. A failed check
  /// throws an [InvalidInputError] whose `field` is the
  /// [StaticRoutingErrorKeys] key, and keeps the edits.
  ///
  /// A save that fails after it started writing reads the router back, and
  /// shows what it holds only if that differs from what the page loaded: a
  /// refused Set keeps the leaves it took (bench 2026-10-21), and routes Added
  /// before a later step failed would otherwise be Added again by a second
  /// Save. A save that wrote nothing, or whose read-back fails, keeps the
  /// edits for a retry. The error reaches the page either way.
  ///
  /// This is not the detection constitution Article IV Rule 2 keeps for
  /// `Preservable` (a device changed by someone else mid-edit, #1279): it runs
  /// only after this page's own save failed, and asks whether that save wrote
  /// anything. The error type cannot say, since a refused Edit is a complete
  /// failure that still wrote its rename.
  @override
  Future<StaticRoutingFeatureState> save() async {
    final problem = StaticRouteUIModel.validateList(
      original: state.settings.original.routes,
      current: state.settings.current.routes,
    );
    if (problem != null) throw InvalidInputError(field: problem);
    try {
      return await super.save();
    } on ServiceError {
      final (router, _) = await performFetch(forceRemote: true);
      if (router != null && router != state.settings.original) {
        state = state.copyWith(
          settings: Preservable(original: router, current: router),
        );
      }
      rethrow;
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
      final original = state.settings.original;
      final current = state.settings.current;

      await ref.read(uspMutationLockProvider).withLock(() async {
        final result = await _svc.saveBatch(
          original: original.routes,
          current: current.routes,
        );

        logger.d('[USP][Network][Routing]: Batch save — '
            'added: ${result.added}, updated: ${result.updated}, '
            'deleted: ${result.deleted}');

        // After the routes, so a refused route save leaves NAT as it was: RIP
        // on turns NAT off. Its own Set, which takes about 8 s to answer
        // (bench 2026-10-21) inside the page's saving state.
        final rip = current.ripEnabled;
        if (rip != null && rip != original.ripEnabled) {
          await _svc.saveRipEnabled(rip);
        }
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

  /// Choose Dynamic routing (true) or NAT (false). Sent with the page's Save,
  /// like every other field on it; there is no confirmation, as on 1.0.
  void setRipEnabled(bool enabled) {
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(ripEnabled: enabled)),
    );
  }

  /// Add a new route locally.
  ///
  /// Fills [StaticRouteUIModel.interfacePath] through the service layer so the
  /// view doesn't need to access the service directly. It holds the display
  /// name until a save: the path a route is written with is resolved then.
  void addRoute(StaticRouteUIModel route) {
    assert(route.interfaceName.isNotEmpty, 'interfaceName must not be empty');
    final resolved = route.copyWith(
      interfacePath: _svc.mapDisplayToInterface(route.interfaceName),
    );
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(routes: [...current.routes, resolved]),
      ),
    );
  }

  /// Edit an existing route by index.
  ///
  /// Fills [StaticRouteUIModel.interfacePath] through the service layer so the
  /// view doesn't need to access the service directly. It holds the display
  /// name until a save: the path a route is written with is resolved then.
  void editRoute(int index, StaticRouteUIModel route) {
    assert(route.interfaceName.isNotEmpty, 'interfaceName must not be empty');
    final resolved = route.copyWith(
      interfacePath: _svc.mapDisplayToInterface(route.interfaceName),
    );
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes[index] = resolved;
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(routes: routes)),
    );
  }

  /// Toggle enable/disable on a route by index.
  void toggleRoute(int index, bool enabled) {
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes[index] = routes[index].copyWith(enabled: enabled);
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(routes: routes)),
    );
  }

  /// Delete a route by index.
  void deleteRoute(int index) {
    final routes = List<StaticRouteUIModel>.from(state.settings.current.routes);
    routes.removeAt(index);
    state = state.copyWith(
      settings: state.settings
          .update(state.settings.current.copyWith(routes: routes)),
    );
  }
}
