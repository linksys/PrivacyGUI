import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Builds a stable, kebab-case key for E2E `identifier` hooks on rule rows
/// across features — port-forwarding, port-triggering, static-routing, and DHCP
/// reservations all derive their row key here. Prefers the [nameField] slug
/// (a localizable-free discriminator: a description, a route name, or a MAC —
/// "Web Server" → "web-server", "AA:BB:CC:DD:EE:FF" → "aa-bb-cc-dd-ee-ff"), so
/// tests can target a specific row by name instead of by index. When that slug
/// is empty it falls back to the saved instance number parsed from
/// [instancePath] — tolerating the trailing `.` every generated layer emits
/// (e.g. `Device.NAT.PortMapping.2.` → "2") — then to a shared `'unnamed'`
/// sentinel. The tier order is slug → instance number → `'unnamed'`; the result
/// is always non-empty, but two rows only get distinct keys when a
/// discriminating tier (slug or instance number) fires — a run of empty-name
/// rows with no parseable instance number all share the `'unnamed'` sentinel.
String ruleIdentifierKey(String nameField, String? instancePath) {
  final slug = nameField
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isNotEmpty) return slug;
  // Instance paths are dot-terminated in every generated layer
  // (`final p = '$basePath$id.'`), so tolerate an optional trailing `.`.
  final instance = instancePath == null
      ? null
      : RegExp(r'(\d+)\.?$').firstMatch(instancePath)?.group(1);
  return instance ?? 'unnamed';
}

/// Presentation Layer Model for a port forwarding rule.
///
/// Covers both single port and port range forwarding from
/// `Device.NAT.PortMapping`. When [externalPortEndRange] is 0 or equal to
/// [externalPort] the rule is a single-port forward; otherwise it is a
/// port-range forward.
///
/// [instancePath] is `null` for newly created (local-only) rules
/// that have not yet been saved to the device.
class PortForwardingRuleUIModel extends Equatable with DiagnosticLoggable {
  final String? instancePath;
  final String description;
  final int externalPort;
  final int externalPortEndRange; // 0 = single port
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortForwardingRuleUIModel({
    this.instancePath,
    required this.description,
    required this.externalPort,
    this.externalPortEndRange = 0,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });

  PortForwardingRuleUIModel copyWith({
    String? instancePath,
    String? description,
    int? externalPort,
    int? externalPortEndRange,
    int? internalPort,
    String? internalClient,
    String? protocol,
    bool? enabled,
  }) {
    return PortForwardingRuleUIModel(
      instancePath: instancePath ?? this.instancePath,
      description: description ?? this.description,
      externalPort: externalPort ?? this.externalPort,
      externalPortEndRange: externalPortEndRange ?? this.externalPortEndRange,
      internalPort: internalPort ?? this.internalPort,
      internalClient: internalClient ?? this.internalClient,
      protocol: protocol ?? this.protocol,
      enabled: enabled ?? this.enabled,
    );
  }

  /// True when this is a single-port forward (no range).
  bool get isSinglePort =>
      externalPortEndRange == 0 || externalPortEndRange == externalPort;

  /// True when this is a port-range forward.
  bool get isPortRange => !isSinglePort;

  /// Display name: description if available, otherwise "Unnamed rule".
  String get displayName =>
      description.isNotEmpty ? description : 'Unnamed rule';

  /// Stable, kebab-case key for E2E `identifier` hooks (e.g. `pf-edit-<key>`).
  /// Derived from the description ("Web Server" → "web-server"); falls back to
  /// the saved instance number, then a shared "unnamed" sentinel, so it is
  /// always non-empty. Distinct across rows only when a discriminating tier
  /// (description slug or instance number) fires.
  String get identifierKey => ruleIdentifierKey(description, instancePath);

  /// External port display: "8080" or "3074-3080".
  String get portRangeDisplay =>
      isSinglePort ? '$externalPort' : '$externalPort-$externalPortEndRange';

  /// Summary: "8080 -> 192.168.1.100:80" or "3074-3080 -> 192.168.1.50:3074".
  ///
  /// Diagnostics and other non-UI callers only. UI draws the arrow as an icon
  /// via `MapsToRow(source: portRangeDisplay, target: internalTargetDisplay)`,
  /// because U+2192 has no glyph in the app's declared font set.
  String get portSummary => '$portRangeDisplay -> $internalTargetDisplay';

  /// Internal target display: "192.168.1.100:80".
  String get internalTargetDisplay => '$internalClient:$internalPort';

  @override
  String get diagnosticName => 'PortForwardingRuleUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'description': description,
        'externalPort': externalPort,
        'externalPortEndRange': externalPortEndRange,
        'internalPort': internalPort,
        'internalClient': internalClient,
        'protocol': protocol,
        'enabled': enabled,
      };
}
