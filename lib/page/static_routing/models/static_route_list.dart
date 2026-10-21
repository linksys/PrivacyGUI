import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/has_unconfirmed_rows.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';

/// Equatable wrapper around a list of [StaticRouteUIModel].
///
/// Used as the `TSettings` type for `Preservable<StaticRouteList>`
/// so dirty-checking (original vs current) works correctly.
class StaticRouteList extends Equatable implements HasUnconfirmedRows {
  final List<StaticRouteUIModel> routes;

  const StaticRouteList({this.routes = const []});

  /// A row added on the page has no path until the router creates it (#1212):
  /// while one is here and the read after a save failed, the next save reads
  /// the router before it writes.
  @override
  bool get hasUnconfirmedRows => routes.any((r) => r.instancePath == null);

  @override
  List<Object?> get props => [routes];
}
