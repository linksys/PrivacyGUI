import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

/// Combined settings for the Port Forwarding page.
///
/// Wraps both port forwarding rules and port triggering rules
/// into a single Equatable settings object for Preservable<T>.
class PortForwardingPageSettings extends Equatable {
  final List<PortForwardingRuleUIModel> forwardingRules;
  final List<PortTriggeringRuleUIModel> triggeringRules;

  const PortForwardingPageSettings({
    this.forwardingRules = const [],
    this.triggeringRules = const [],
  });

  @override
  List<Object?> get props => [forwardingRules, triggeringRules];
}
