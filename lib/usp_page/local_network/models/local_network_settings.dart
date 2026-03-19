import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_ui_model.dart';

/// User-editable local network settings.
///
/// Wraps the [LocalNetworkUIModel] (router info + DHCP config).
class LocalNetworkSettings extends Equatable {
  final LocalNetworkUIModel model;

  const LocalNetworkSettings({required this.model});

  const LocalNetworkSettings.empty()
      : model = const LocalNetworkUIModel.initial();

  LocalNetworkSettings copyWith({
    LocalNetworkUIModel? model,
  }) {
    return LocalNetworkSettings(
      model: model ?? this.model,
    );
  }

  @override
  List<Object?> get props => [model];
}
