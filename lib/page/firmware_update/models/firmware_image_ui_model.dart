import 'package:equatable/equatable.dart';

class FirmwareImageUIModel extends Equatable {
  final int instance;
  final String instancePath;
  final String name;
  final String version;
  final String status;
  final bool available;

  const FirmwareImageUIModel({
    required this.instance,
    required this.instancePath,
    required this.name,
    required this.version,
    required this.status,
    required this.available,
  });

  bool get isActive => status == 'Active';

  @override
  List<Object?> get props =>
      [instance, instancePath, name, version, status, available];
}
