import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/has_unconfirmed_rows.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

/// Combined settings for the Port Forwarding page.
///
/// Wraps both port forwarding rules and port triggering rules
/// into a single Equatable settings object for Preservable<T>.
class PortForwardingPageSettings extends Equatable
    implements HasUnconfirmedRows {
  final List<PortForwardingRuleUIModel> forwardingRules;
  final List<PortTriggeringRuleUIModel> triggeringRules;

  const PortForwardingPageSettings({
    this.forwardingRules = const [],
    this.triggeringRules = const [],
  });

  /// A row added on the page has no path until the router creates it (#1212):
  /// while one is here and the read after a save failed, the next save reads
  /// the router before it writes.
  @override
  bool get hasUnconfirmedRows =>
      forwardingRules.any((r) => r.instancePath == null) ||
      triggeringRules.any((r) => r.instancePath == null);

  @override
  List<Object?> get props => [forwardingRules, triggeringRules];
}
