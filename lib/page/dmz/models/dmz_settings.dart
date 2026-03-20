import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';

/// User-editable DMZ settings.
///
/// Wraps the [DmzUIModel] (presentation data) and [instancePath]
/// (needed for save to decide add vs. update).
class DmzSettings extends Equatable {
  final DmzUIModel model;

  /// Instance path of the existing DMZ entry, or null if none exists.
  final String? instancePath;

  const DmzSettings({
    required this.model,
    this.instancePath,
  });

  const DmzSettings.empty()
      : model = const DmzUIModel.disabled(),
        instancePath = null;

  /// True when there is no existing DMZ entry on the router.
  bool get isNewEntry => instancePath == null;

  DmzSettings copyWith({
    DmzUIModel? model,
    String? instancePath,
    bool clearInstancePath = false,
  }) {
    return DmzSettings(
      model: model ?? this.model,
      instancePath:
          clearInstancePath ? null : (instancePath ?? this.instancePath),
    );
  }

  @override
  List<Object?> get props => [model, instancePath];
}
