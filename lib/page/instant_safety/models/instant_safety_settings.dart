import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';

/// User-editable Instant Safety settings.
class InstantSafetySettings extends Equatable {
  final SafeBrowsingType type;

  const InstantSafetySettings({required this.type});

  const InstantSafetySettings.empty() : type = SafeBrowsingType.off;

  bool get isEnabled => type != SafeBrowsingType.off;

  InstantSafetySettings copyWith({SafeBrowsingType? type}) {
    return InstantSafetySettings(type: type ?? this.type);
  }

  @override
  List<Object?> get props => [type];
}
