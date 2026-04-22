import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';

/// Composed FeatureState for the WiFi Advanced tab.
class WifiAdvancedFeatureState
    extends FeatureState<WifiAdvancedSettings, WifiAdvancedStatus> {
  const WifiAdvancedFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory WifiAdvancedFeatureState.initial() {
    return WifiAdvancedFeatureState(
      settings: Preservable(
        original: const WifiAdvancedSettings.empty(),
        current: const WifiAdvancedSettings.empty(),
      ),
      status: const WifiAdvancedStatus.loading(),
    );
  }

  @override
  WifiAdvancedFeatureState copyWith({
    Preservable<WifiAdvancedSettings>? settings,
    WifiAdvancedStatus? status,
  }) {
    return WifiAdvancedFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'dfsEnabled': settings.current.isDfsEnabled,
        'isDirty': isDirty,
        'isLoading': status.isLoading,
      };
}
