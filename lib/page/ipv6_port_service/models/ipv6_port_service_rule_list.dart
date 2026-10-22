import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/has_unconfirmed_rows.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

/// Equatable wrapper around a list of [Ipv6PortServiceRuleUIModel].
///
/// Used as the `TSettings` type for `Preservable<Ipv6PortServiceRuleList>`
/// so dirty-checking (original vs current) works correctly.
class Ipv6PortServiceRuleList extends Equatable implements HasUnconfirmedRows {
  final List<Ipv6PortServiceRuleUIModel> rules;

  const Ipv6PortServiceRuleList({this.rules = const []});

  /// A row added on the page has no path until the router creates it (#1212):
  /// while one is here and the read after a save failed, the next save reads
  /// the router before it writes.
  @override
  bool get hasUnconfirmedRows => rules.any((r) => r.instancePath == null);

  @override
  List<Object?> get props => [rules];
}
