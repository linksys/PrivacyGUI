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

  /// Whether saving now would write IEEE 802.11h, which reloads every radio.
  bool get changesDfs => !const MapEquality<String, bool>().equals(
      settings.current.ieee80211hByRadio, settings.original.ieee80211hByRadio);

  /// Whether saving now would switch MLO, which restarts Wi-Fi for about 60 s
  /// (linksys/FWDEV#201).
  bool get changesMlo =>
      settings.current.mloEnabled != settings.original.mloEnabled;

  /// Whether saving now restarts Wi-Fi and drops a client connected over it:
  /// an MLO or DFS change (#1692).
  ///
  /// The view reads it to decide whether to wait for the router to come back
  /// and the notifier to decide how long the save waits, so the two cannot
  /// disagree about a save. A steering-only save is applied at once and needs
  /// neither (#1661).
  bool get restartsWifi => changesDfs || changesMlo;

  @override
  Map<String, dynamic> toMap() => {
        'dfsEnabled': settings.current.isDfsEnabled,
        'clientSteering': settings.current.clientSteering,
        'nodeSteering': settings.current.nodeSteering,
        'mloEnabled': settings.current.mloEnabled,
        'isDirty': isDirty,
        'isLoading': status.isLoading,
      };
}
