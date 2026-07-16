import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

class FirmwareImageUIModel extends Equatable with DiagnosticLoggable {
  final int instance;
  final String instancePath;
  final String name;
  final String version;
  final String status;
  final bool available;
  final bool isBootTarget;

  const FirmwareImageUIModel({
    this.instance = 0,
    required this.instancePath,
    required this.name,
    required this.version,
    required this.status,
    required this.available,
    this.isBootTarget = false,
  });

  bool get isActive => status == 'Active';

  @override
  String get diagnosticName => 'FirmwareImageUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instance': instance,
        'instancePath': instancePath,
        'name': name,
        'version': version,
        'status': status,
        'available': available,
        'isBootTarget': isBootTarget,
      };
}
