import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/static_routing/models/static_route_list.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_status.dart';

/// Composed FeatureState for the static routing page.
class StaticRoutingFeatureState
    extends FeatureState<StaticRouteList, StaticRoutingStatus> {
  const StaticRoutingFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory StaticRoutingFeatureState.initial() {
    return StaticRoutingFeatureState(
      settings: Preservable(
        original: const StaticRouteList(),
        current: const StaticRouteList(),
      ),
      status: const StaticRoutingStatus(isLoading: true),
    );
  }

  @override
  StaticRoutingFeatureState copyWith({
    Preservable<StaticRouteList>? settings,
    StaticRoutingStatus? status,
  }) {
    return StaticRoutingFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
