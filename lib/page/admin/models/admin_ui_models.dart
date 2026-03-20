import 'package:equatable/equatable.dart';

/// Presentation Layer Model for admin user info.
class AdminUserUIModel extends Equatable {
  final String instancePath;
  final String username;
  final bool enable;

  const AdminUserUIModel({
    required this.instancePath,
    required this.username,
    required this.enable,
  });

  @override
  List<Object?> get props => [instancePath, username, enable];
}
