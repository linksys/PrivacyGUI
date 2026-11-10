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

  /// The reservation's name (`StaticAddress.{i}.X_LINKSYS_Name`), which FW
  /// hands the client as its host name (linksys/FWDEV#211). `''` when the
  /// reservation has none, or the router does not report the leaf.
  final String name;

  /// Creates a DHCP reservation UI model. MAC is normalized to uppercase.
  DhcpReservationUIModel({
    this.instancePath,
    required String mac,
    required this.ip,
    required this.enable,
    this.name = '',
  }) : mac = mac.toUpperCase();

  DhcpReservationUIModel copyWith({
    String? instancePath,
    String? mac,
    String? ip,
    bool? enable,
    String? name,
  }) {
    return DhcpReservationUIModel(
      instancePath: instancePath ?? this.instancePath,
      mac: mac ?? this.mac,
      ip: ip ?? this.ip,
      enable: enable ?? this.enable,
      name: name ?? this.name,
    );
  }

  /// FW's longest reservation name (linksys/FWDEV#211, feed_usp#54).
  static const nameMaxLength = 63;

  static final _nameLabel =
      RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$');

  /// FW's rule for a reservation name (linksys/FWDEV#211): empty, or at most
  /// 63 letters, digits and `-` with no `-` at either end, and not the name of
  /// any of [others] (the pool's other reservations). Returns one of
  /// [DhcpReservationNameErrors], or null when FW would accept [name].
  ///
  /// An empty name is always accepted here: the service does not send it
  /// (FW counts `''` as a name in its uniqueness check).
  static String? validateName(
      String name, Iterable<DhcpReservationUIModel> others) {
    if (name.isEmpty) return null;
    if (name.length > nameMaxLength) return DhcpReservationNameErrors.tooLong;
    if (!_nameLabel.hasMatch(name)) return DhcpReservationNameErrors.invalid;
    if (others.any((r) => r.name == name)) {
      return DhcpReservationNameErrors.inUse;
    }
    return null;
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
        'name': name,
      };
}

/// Error keys returned by [DhcpReservationUIModel.validateName]. The view maps
/// them to l10n strings.
class DhcpReservationNameErrors {
  static const tooLong = 'reservationNameTooLong';
  static const invalid = 'reservationNameInvalid';
  static const inUse = 'reservationNameInUse';
}

/// The messages dhcpmngr refuses a reservation write with (linksys/feed_usp#54
/// `9004-linksys-211_lan_pool_and_reservation_validation.patch`): the refused
/// leaf's `errorMessage`, under 7012 on a Set and 7004 on an Add. The service
/// reads them off a refusal and the page shows each with its own message.
class DhcpReservationRefusalNames {
  static const invalidMac = 'Invalid reservation MAC address';
  static const invalidIp = 'Invalid reservation IP address';
  static const ipConflict = 'IP address conflicts with existing entries';
  static const invalidName = 'Invalid reservation description';

  static const all = [invalidMac, invalidIp, ipConflict, invalidName];
}
