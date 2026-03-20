import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

/// Equatable wrapper around a list of [Ipv6PortServiceRuleUIModel].
///
/// Used as the `TSettings` type for `Preservable<Ipv6PortServiceRuleList>`
/// so dirty-checking (original vs current) works correctly.
class Ipv6PortServiceRuleList extends Equatable {
  final List<Ipv6PortServiceRuleUIModel> rules;

  const Ipv6PortServiceRuleList({this.rules = const []});

  @override
  List<Object?> get props => [rules];
}
