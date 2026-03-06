import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/usp_page/dashboard/models/time_settings_ui_model.dart';

/// Immutable state for the USP Admin page.
class UspAdminState extends Equatable {
  final AdminUserUIModel adminUser;
  final TimeSettingsUIModel timeSettings;

  const UspAdminState({
    required this.adminUser,
    required this.timeSettings,
  });

  UspAdminState copyWith({
    AdminUserUIModel? adminUser,
    TimeSettingsUIModel? timeSettings,
  }) {
    return UspAdminState(
      adminUser: adminUser ?? this.adminUser,
      timeSettings: timeSettings ?? this.timeSettings,
    );
  }

  @override
  List<Object?> get props => [adminUser, timeSettings];
}
