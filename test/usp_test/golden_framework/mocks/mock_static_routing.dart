import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_status.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';

class FixedStaticRoutingNotifier extends UspStaticRoutingNotifier {
  final StaticRoutingFeatureState _fixedState;

  FixedStaticRoutingNotifier(this._fixedState);

  @override
  StaticRoutingFeatureState build() => _fixedState;

  @override
  Future<(StaticRouteList?, StaticRoutingStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void addRoute(StaticRouteUIModel route) {}

  @override
  void editRoute(int index, StaticRouteUIModel route) {}

  @override
  void toggleRoute(int index, bool enabled) {}

  @override
  void deleteRoute(int index) {}
}

/// Returns provider overrides for static routing golden tests.
List<Override> staticRoutingOverrides(StaticRoutingFeatureState state) => [
      uspStaticRoutingProvider
          .overrideWith(() => FixedStaticRoutingNotifier(state)),
    ];
