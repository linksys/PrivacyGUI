import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// How the DMZ host is given (linksys/FWDEV#204).
///
/// The router keeps one of `DestIP` and `X_LINKSYS_DestMACAddress`, never both.
/// A host given by MAC stays the DMZ host when DHCP gives its address to
/// another device; a host given by IP does not.
enum DmzDestinationType {
  /// `DestIP`: whatever device holds this address.
  ip,

  /// `X_LINKSYS_DestMACAddress`: this device, whatever its address.
  mac,
}

/// How the source IP restriction is configured.
enum DmzSourceType {
  /// No restriction — all source IPs are allowed (0.0.0.0/0 or empty).
  any,

  /// Restrict to a specific CIDR range (e.g. 192.168.1.0/24).
  cidr,
}

/// Error keys [UspDmzService.validateForm] returns, by field (`destIp`,
/// `destMac`, `sourcePrefix`). The view maps each to its l10n string.
class DmzErrorKeys {
  static const destIpRequired = 'destIpRequired';
  static const invalidIpAddress = 'invalidIpAddress';
  static const destMacRequired = 'destMacRequired';
  static const invalidMacAddress = 'invalidMacAddress';
  static const cidrRequired = 'cidrRequired';
}

/// UI-facing representation of the DMZ configuration.
///
/// The router's TR-181 model is multi-instance (`Device.Firewall.DMZ.{i}.`)
/// but DMZ is practically a single-entry feature: either 0 or 1 entry exists.
/// This model abstracts that into a simple enable/disable + settings view.
class DmzUIModel extends Equatable with DiagnosticLoggable {
  /// Whether the DMZ entry exists and is enabled.
  final bool isEnabled;

  /// How the DMZ host is given: by [destIp] or by [destMac].
  final DmzDestinationType destinationType;

  /// Destination host IP address.
  final String destIp;

  /// Destination host MAC address.
  ///
  /// Kept beside [destIp] while the page is open, so switching the type and
  /// back does not lose what was typed; only the one [destinationType] names
  /// is saved.
  final String destMac;

  /// Source restriction type.
  final DmzSourceType sourceType;

  /// CIDR string when [sourceType] is [DmzSourceType.cidr].
  final String sourcePrefix;

  const DmzUIModel({
    required this.isEnabled,
    this.destinationType = DmzDestinationType.ip,
    required this.destIp,
    this.destMac = '',
    required this.sourceType,
    required this.sourcePrefix,
  });

  /// Default disabled state (no DMZ entry on router).
  const DmzUIModel.disabled()
      : isEnabled = false,
        destinationType = DmzDestinationType.ip,
        destIp = '',
        destMac = '',
        sourceType = DmzSourceType.any,
        sourcePrefix = '';

  DmzUIModel copyWith({
    bool? isEnabled,
    DmzDestinationType? destinationType,
    String? destIp,
    String? destMac,
    DmzSourceType? sourceType,
    String? sourcePrefix,
  }) {
    return DmzUIModel(
      isEnabled: isEnabled ?? this.isEnabled,
      destinationType: destinationType ?? this.destinationType,
      destIp: destIp ?? this.destIp,
      destMac: destMac ?? this.destMac,
      sourceType: sourceType ?? this.sourceType,
      sourcePrefix: sourcePrefix ?? this.sourcePrefix,
    );
  }

  @override
  String get diagnosticName => 'DmzUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'isEnabled': isEnabled,
        'destinationType': destinationType.name,
        'destIp': destIp,
        'destMac': destMac,
        'sourceType': sourceType.name,
        'sourcePrefix': sourcePrefix,
      };
}
