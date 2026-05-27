import 'package:equatable/equatable.dart';

class FirmwareImageUIModel extends Equatable {
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
  List<Object?> get props =>
      [instance, instancePath, name, version, status, available, isBootTarget];
}
