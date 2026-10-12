import 'package:collection/collection.dart';
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

  /// Whether saving now would write IEEE 802.11h — the one write on this tab
  /// that reloads every radio and drops a client connected over Wi-Fi.
  ///
  /// The notifier reads it to decide what to send and the view reads it to
  /// decide whether to wait for the router to come back, so the two cannot
  /// disagree about a save. A steering-only save is applied at once and needs
  /// neither (#1661).
  bool get changesDfs => !const MapEquality<String, bool>().equals(
      settings.current.ieee80211hByRadio, settings.original.ieee80211hByRadio);

  @override
  Map<String, dynamic> toMap() => {
        'dfsEnabled': settings.current.isDfsEnabled,
        'clientSteering': settings.current.clientSteering,
        'nodeSteering': settings.current.nodeSteering,
        'isDirty': isDirty,
        'isLoading': status.isLoading,
      };
}
