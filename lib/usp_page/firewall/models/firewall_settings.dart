import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/usp_page/firewall/services/usp_firewall_service.dart';

/// User-editable firewall settings.
///
/// Wraps the [FirewallUIModel] (presentation toggles) and the opaque
/// [FirewallRuleContext] (needed for building SET payloads on save).
class FirewallSettings extends Equatable {
  final FirewallUIModel model;
  final FirewallRuleContext ruleContext;

  const FirewallSettings({
    required this.model,
    required this.ruleContext,
  });

  const FirewallSettings.empty()
      : model = const FirewallUIModel(),
        ruleContext = FirewallRuleContext.empty;

  FirewallSettings copyWith({
    FirewallUIModel? model,
    FirewallRuleContext? ruleContext,
  }) {
    return FirewallSettings(
      model: model ?? this.model,
      ruleContext: ruleContext ?? this.ruleContext,
    );
  }

  @override
  List<Object?> get props => [model, ruleContext];
}
