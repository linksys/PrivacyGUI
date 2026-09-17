import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Router alias of the virtual `FirmwareImage` instance that reports the version
/// available for download, as opposed to the physical NAND banks (`fw1`/`fw2`).
/// The one spelling of this string — anything deciding "bank or not" compares
/// against it.
const kOtaFirmwareAlias = 'ota';

class FirmwareImageUIModel extends Equatable with DiagnosticLoggable {
  final int instance;
  final String instancePath;

  /// Router-assigned name for the slot: `fw1`/`fw2` for the physical NAND banks
  /// and `ota` for the virtual instance that carries the version available for
  /// download. Null on builds without the Linksys fwup stack, which report no
  /// Alias at all — such rows are still physical banks, so anything that has to
  /// exclude the virtual instance tests for `ota` rather than allow-listing
  /// `fw1`/`fw2`.
  final String? alias;
  final String name;
  final String version;
  final String status;
  final bool available;
  final bool isBootTarget;

  const FirmwareImageUIModel({
    this.instance = 0,
    required this.instancePath,
    this.alias,
    required this.name,
    required this.version,
    required this.status,
    required this.available,
    this.isBootTarget = false,
  });

  bool get isActive => status == 'Active';

  /// The virtual OTA instance rather than a bank the router can boot from.
  bool get isOta => alias == kOtaFirmwareAlias;

  @override
  String get diagnosticName => 'FirmwareImageUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instance': instance,
        'instancePath': instancePath,
        'alias': alias,
        'name': name,
        'version': version,
        'status': status,
        'available': available,
        'isBootTarget': isBootTarget,
      };
}
