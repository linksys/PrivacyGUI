import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';

/// Immutable state for the USP Admin page.
class UspAdminState extends Equatable {
  final AdminUserUIModel adminUser;
  final TimeSettingsUIModel timeSettings;
  final DateTime timeFetchedAt;

  const UspAdminState({
    required this.adminUser,
    required this.timeSettings,
    required this.timeFetchedAt,
  });

  UspAdminState copyWith({
    AdminUserUIModel? adminUser,
    TimeSettingsUIModel? timeSettings,
    DateTime? timeFetchedAt,
  }) {
    return UspAdminState(
      adminUser: adminUser ?? this.adminUser,
      timeSettings: timeSettings ?? this.timeSettings,
      timeFetchedAt: timeFetchedAt ?? this.timeFetchedAt,
    );
  }

  @override
  List<Object?> get props => [adminUser, timeSettings, timeFetchedAt];
}
