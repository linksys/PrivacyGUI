import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;

/// Presentation Layer Model for a single forwarded-port rule
/// within a port trigger entry (child of `Device.NAT.PortTrigger.{i}.Rule.{i}`).
///
/// [instancePath] is `null` for locally-created forward rules not yet saved.
class PortTriggerForwardRuleUIModel extends Equatable with DiagnosticLoggable {
  final String? instancePath;
  final int forwardPort;
  final int forwardPortEndRange;
  final String forwardProtocol;

  const PortTriggerForwardRuleUIModel({
    this.instancePath,
    required this.forwardPort,
    this.forwardPortEndRange = 0,
    required this.forwardProtocol,
  });

  /// Display: "1024" or "1024-1030".
  String get portDisplay =>
      forwardPortEndRange == 0 || forwardPortEndRange == forwardPort
          ? '$forwardPort'
          : '$forwardPort-$forwardPortEndRange';

  @override
  String get diagnosticName => 'PortTriggerForwardRuleUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'forwardPort': forwardPort,
        'forwardPortEndRange': forwardPortEndRange,
        'forwardProtocol': forwardProtocol,
      };
}

/// Presentation Layer Model for a port triggering rule.
///
/// Maps to `Device.NAT.PortTrigger.{i}` (parent) with nested
/// `Rule.{i}` sub-table (children).
///
/// [instancePath] is `null` for newly created (local-only) rules.
class PortTriggeringRuleUIModel extends Equatable with DiagnosticLoggable {
  final String? instancePath;
  final bool enabled;
  final String description;
  final int triggerPort;
  final int triggerPortEndRange;
  final String triggerProtocol;
  final List<PortTriggerForwardRuleUIModel> forwardRules;

  const PortTriggeringRuleUIModel({
    this.instancePath,
    required this.enabled,
    required this.description,
    required this.triggerPort,
    this.triggerPortEndRange = 0,
    required this.triggerProtocol,
    this.forwardRules = const [],
  });

  PortTriggeringRuleUIModel copyWith({
    String? instancePath,
    bool? enabled,
    String? description,
    int? triggerPort,
    int? triggerPortEndRange,
    String? triggerProtocol,
    List<PortTriggerForwardRuleUIModel>? forwardRules,
  }) {
    return PortTriggeringRuleUIModel(
      instancePath: instancePath ?? this.instancePath,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
      triggerPort: triggerPort ?? this.triggerPort,
      triggerPortEndRange: triggerPortEndRange ?? this.triggerPortEndRange,
      triggerProtocol: triggerProtocol ?? this.triggerProtocol,
      forwardRules: forwardRules ?? this.forwardRules,
    );
  }

  /// Display name: description if available, otherwise "Unnamed trigger".
  String get displayName =>
      description.isNotEmpty ? description : 'Unnamed trigger';

  /// Stable, kebab-case key for E2E `identifier` hooks (e.g. `pf-edit-<key>`).
  /// See [ruleIdentifierKey] — description slug, then instance number, then
  /// "unnamed"; always non-empty and collision-free across rows.
  String get identifierKey => ruleIdentifierKey(description, instancePath);

  /// Trigger port display: "21" or "21-25".
  String get triggerPortDisplay =>
      triggerPortEndRange == 0 || triggerPortEndRange == triggerPort
          ? '$triggerPort'
          : '$triggerPort-$triggerPortEndRange';

  /// Forward port display (first rule): "1024-1030" or "—" if no rules.
  String get forwardPortDisplay =>
      forwardRules.isNotEmpty ? forwardRules.first.portDisplay : '—';

  /// Forward protocol (first rule) or "—" if no rules.
  String get forwardProtocolDisplay =>
      forwardRules.isNotEmpty ? forwardRules.first.forwardProtocol : '—';

  /// Trigger half of the summary: "Trigger: 21 TCP".
  String get triggerSummaryPart =>
      'Trigger: $triggerPortDisplay $triggerProtocol';

  /// Forward half of the summary: "Forward: 1024-1030 TCP".
  String get forwardSummaryPart =>
      'Forward: $forwardPortDisplay $forwardProtocolDisplay';

  /// Summary: "Trigger: 21 TCP -> Forward: 1024-1030 TCP".
  ///
  /// Diagnostics and other non-UI callers only. UI draws the arrow as an icon
  /// via `MapsToRow(source: triggerSummaryPart, target: forwardSummaryPart)`,
  /// because U+2192 has no glyph in the app's declared font set.
  String get summary => '$triggerSummaryPart -> $forwardSummaryPart';

  @override
  String get diagnosticName => 'PortTriggeringRuleUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'enabled': enabled,
        'description': description,
        'triggerPort': triggerPort,
        'triggerPortEndRange': triggerPortEndRange,
        'triggerProtocol': triggerProtocol,
        'forwardRules': forwardRules,
      };
}
