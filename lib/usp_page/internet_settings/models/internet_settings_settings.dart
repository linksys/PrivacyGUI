import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';

/// User-editable internet settings.
///
/// Wraps [UspInternetSettingsForm] — only the form is dirty-checked.
class InternetSettingsSettings extends Equatable {
  final UspInternetSettingsForm form;

  const InternetSettingsSettings({required this.form});

  const InternetSettingsSettings.empty()
      : form = const UspInternetSettingsForm(
            connectionType: UspWanConnectionType.dhcp);

  InternetSettingsSettings copyWith({
    UspInternetSettingsForm? form,
  }) {
    return InternetSettingsSettings(
      form: form ?? this.form,
    );
  }

  @override
  List<Object?> get props => [form];
}
