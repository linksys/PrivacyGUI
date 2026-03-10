import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/usp_page/static_routing/services/usp_static_routing_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspStaticRoutingState extends Equatable {
  final List<StaticRouteUIModel> routes;
  final bool isMutating;

  const UspStaticRoutingState({
    required this.routes,
    this.isMutating = false,
  });

  UspStaticRoutingState copyWith({
    List<StaticRouteUIModel>? routes,
    bool? isMutating,
  }) {
    return UspStaticRoutingState(
      routes: routes ?? this.routes,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [routes, isMutating];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspStaticRoutingProvider = AsyncNotifierProvider.autoDispose<
    UspStaticRoutingNotifier, UspStaticRoutingState>(
  UspStaticRoutingNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspStaticRoutingNotifier
    extends AutoDisposeAsyncNotifier<UspStaticRoutingState> {
  @override
  Future<UspStaticRoutingState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final data = await StaticRouting.fetch(usp);
    final svc = ref.read(uspStaticRoutingServiceProvider);
    final routes = svc.buildRouteUIModels(data);

    logger.d('[USP] StaticRouting fetched — '
        'total: ${data.items.length}, static: ${routes.length}');

    return UspStaticRoutingState(routes: routes);
  }

  Future<void> _refreshRoutes() async {
    final usp = ref.read(uspServiceProvider)!;
    final data = await StaticRouting.fetch(usp);
    final svc = ref.read(uspStaticRoutingServiceProvider);
    final routes = svc.buildRouteUIModels(data);
    state = AsyncData(UspStaticRoutingState(routes: routes));
  }

  /// Add a new static route.
  Future<void> addRoute({
    required String name,
    required String destIpAddress,
    required String destSubnetMask,
    required String gatewayIpAddress,
    required String interfacePath,
    bool enabled = true,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await StaticRouting.add(
        usp,
        enable: enabled,
        destIpAddress: destIpAddress,
        destSubnetMask: destSubnetMask,
        gatewayIpAddress: gatewayIpAddress,
        interface_: interfacePath,
        alias: name,
      );
      logger.d('[USP] StaticRoute added — name: $name');
      await _refreshRoutes();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }

  /// Update an existing static route.
  Future<void> updateRoute({
    required String instancePath,
    required String name,
    required String destIpAddress,
    required String destSubnetMask,
    required String gatewayIpAddress,
    required String interfacePath,
    bool? enabled,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await StaticRouting.update(
        usp,
        StaticRouteUpdate(
          instancePath: instancePath,
          enable: enabled,
          destIpAddress: destIpAddress,
          destSubnetMask: destSubnetMask,
          gatewayIpAddress: gatewayIpAddress,
          interface_: interfacePath,
          alias: name,
        ),
      );
      logger.d('[USP] StaticRoute updated — $instancePath');
      await _refreshRoutes();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }

  /// Toggle enable/disable on a single route.
  Future<void> toggleRoute(String instancePath, bool enabled) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await StaticRouting.update(
        usp,
        StaticRouteUpdate(instancePath: instancePath, enable: enabled),
      );
      logger.d('[USP] StaticRoute toggled — $instancePath → $enabled');
      await _refreshRoutes();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }

  /// Delete a static route.
  Future<void> deleteRoute(String instancePath) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await StaticRouting.delete(usp, instancePath);
      logger.d('[USP] StaticRoute deleted — $instancePath');
      await _refreshRoutes();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }
}
