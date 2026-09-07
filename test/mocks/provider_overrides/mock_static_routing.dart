/// Provider overrides for `usp_static_routing_view`.
///
/// Moved out of `test/golden_test/golden_framework/mocks/` by #1380 (wave 4) so the
/// layout gate can reach it — `static_routing_scene_data.dart` says why a move and not
/// a copy. The class below is unchanged from what the golden suite has been using; the
/// argument to [staticRoutingOverrides] became optional so the gate can take the
/// default scene without naming it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_status.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';

import '../test_data/scenes/static_routing_scene_data.dart';

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

/// Overrides for `usp_static_routing_view`, defaulting to [gateStaticRoutingState].
///
/// `lanDataProvider` is deliberately *not* overridden: the view reads it inside
/// `_showAddDialog`/`_showEditDialog` to validate a gateway against the LAN subnet,
/// which is a tap away from the page's own build path and out of both suites' default
/// states.
List<Override> staticRoutingOverrides([StaticRoutingFeatureState? state]) => [
      uspStaticRoutingProvider.overrideWith(
        () => FixedStaticRoutingNotifier(state ?? gateStaticRoutingState),
      ),
    ];
