import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;

/// Presentation Layer Model for a DHCP reservation.
///
/// [instancePath] is `null` for newly created (local-only) reservations
/// that have not yet been saved to the device.
class DhcpReservationUIModel extends Equatable with DiagnosticLoggable {
  final String? instancePath;

  /// MAC address (normalized to uppercase).
  final String mac;
  final String ip;
  final bool enable;

  /// Creates a DHCP reservation UI model. MAC is normalized to uppercase.
  DhcpReservationUIModel({
    this.instancePath,
    required String mac,
    required this.ip,
    required this.enable,
  }) : mac = mac.toUpperCase();

  DhcpReservationUIModel copyWith({
    String? instancePath,
    String? mac,
    String? ip,
    bool? enable,
  }) {
    return DhcpReservationUIModel(
      instancePath: instancePath ?? this.instancePath,
      mac: mac ?? this.mac,
      ip: ip ?? this.ip,
      enable: enable ?? this.enable,
    );
  }

  @override
  String get diagnosticName => 'DhcpReservationUIModel';

  /// Stable, kebab-case key for E2E `identifier` hooks
  /// (e.g. `dhcp-reservation-edit-<key>`). Reuses the single repo-wide
  /// derivation contract [ruleIdentifierKey]: the uppercase MAC is slugified
  /// (`AA:BB:CC:DD:EE:FF` → `aa-bb-cc-dd-ee-ff`); an empty MAC falls back to the
  /// saved instance number parsed from [instancePath], then a shared `'unnamed'`
  /// sentinel — so the result is always non-empty and kebab-case. Distinct
  /// across rows only when a discriminating tier (slug or instance number)
  /// fires; empty-MAC rows with no parseable instance number share `'unnamed'`.
  String get identifierKey => ruleIdentifierKey(mac, instancePath);

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'mac': mac,
        'ip': ip,
        'enable': enable,
      };
}
