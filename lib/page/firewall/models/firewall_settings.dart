import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';

/// User-editable firewall settings.
///
/// The rules a save writes against are not here: they are what the router
/// reported, not something the user edits, so the notifier reads them from
/// `firewallDataProvider` when it saves.
class FirewallSettings extends Equatable {
  final FirewallUIModel model;

  const FirewallSettings({required this.model});

  const FirewallSettings.empty() : model = const FirewallUIModel();

  FirewallSettings copyWith({FirewallUIModel? model}) {
    return FirewallSettings(model: model ?? this.model);
  }

  @override
  List<Object?> get props => [model];
}
