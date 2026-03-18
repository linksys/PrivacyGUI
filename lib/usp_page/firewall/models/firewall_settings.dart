import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';

/// User-editable firewall settings.
///
/// Wraps the [FirewallUIModel] (presentation toggles) and the parsed
/// [ruleMap] (needed for building SET payloads on save).
class FirewallSettings extends Equatable {
  final FirewallUIModel model;
  final Map<String, FirewallChainRule> ruleMap;

  const FirewallSettings({
    required this.model,
    required this.ruleMap,
  });

  const FirewallSettings.empty()
      : model = const FirewallUIModel(),
        ruleMap = const {};

  FirewallSettings copyWith({
    FirewallUIModel? model,
    Map<String, FirewallChainRule>? ruleMap,
  }) {
    return FirewallSettings(
      model: model ?? this.model,
      ruleMap: ruleMap ?? this.ruleMap,
    );
  }

  @override
  List<Object?> get props => [model, ruleMap];
}
