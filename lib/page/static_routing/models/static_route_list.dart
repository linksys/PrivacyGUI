import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

/// Equatable wrapper around a list of [StaticRouteUIModel].
///
/// Used as the `TSettings` type for `Preservable<StaticRouteList>`
/// so dirty-checking (original vs current) works correctly.
class StaticRouteList extends Equatable {
  final List<StaticRouteUIModel> routes;

  const StaticRouteList({this.routes = const []});

  @override
  List<Object?> get props => [routes];
}
