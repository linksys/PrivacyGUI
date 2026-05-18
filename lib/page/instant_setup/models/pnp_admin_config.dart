import 'package:equatable/equatable.dart';

/// Admin password configuration collected during PnP wizard.
class PnpAdminConfig extends Equatable {
  final String newPassword;
  final String confirmPassword;

  /// The instance path of the admin user (e.g. Device.Users.User.1.).
  final String adminUserInstancePath;

  const PnpAdminConfig({
    required this.newPassword,
    required this.confirmPassword,
    required this.adminUserInstancePath,
  });

  bool get isValid =>
      newPassword.isNotEmpty &&
      newPassword == confirmPassword &&
      newPassword.length >= 8;

  PnpAdminConfig copyWith({
    String? newPassword,
    String? confirmPassword,
  }) {
    return PnpAdminConfig(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      adminUserInstancePath: adminUserInstancePath,
    );
  }

  @override
  List<Object?> get props =>
      [newPassword, confirmPassword, adminUserInstancePath];
}
