import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

// --- Composite Settings ---
class WifiBundleSettings extends Equatable {
  final WiFiListSettings wifiList;
  final WifiAdvancedSettingsState advanced;
  final InstantPrivacySettings privacy;

  const WifiBundleSettings({
    required this.wifiList,
    required this.advanced,
    required this.privacy,
  });

  @override
  List<Object?> get props => [wifiList, advanced, privacy];

  WifiBundleSettings copyWith({
    WiFiListSettings? wifiList,
    WifiAdvancedSettingsState? advanced,
    InstantPrivacySettings? privacy,
  }) {
    return WifiBundleSettings(
      wifiList: wifiList ?? this.wifiList,
      advanced: advanced ?? this.advanced,
      privacy: privacy ?? this.privacy,
    );
  }

  factory WifiBundleSettings.fromMap(Map<String, dynamic> map) {
    return WifiBundleSettings(
      wifiList: WiFiListSettings.fromMap(map['wifiList'] as Map<String, dynamic>),
      advanced: WifiAdvancedSettingsState.fromMap(map['advanced'] as Map<String, dynamic>),
      privacy: InstantPrivacySettings.fromMap(map['privacy'] as Map<String, dynamic>),
    );
  }
}

// --- Composite Status ---
class WifiBundleStatus extends Equatable {
  final WiFiListStatus wifiList;
  // Advanced settings does not have a separate status object
  final InstantPrivacyStatus privacy;

  const WifiBundleStatus({
    required this.wifiList,
    required this.privacy,
  });

  @override
  List<Object?> get props => [wifiList, privacy];

  WifiBundleStatus copyWith({
    WiFiListStatus? wifiList,
    InstantPrivacyStatus? privacy,
  }) {
    return WifiBundleStatus(
      wifiList: wifiList ?? this.wifiList,
      privacy: privacy ?? this.privacy,
    );
  }

  factory WifiBundleStatus.fromMap(Map<String, dynamic> map) {
    return WifiBundleStatus(
      wifiList: WiFiListStatus.fromMap(map['wifiList'] as Map<String, dynamic>),
      privacy: InstantPrivacyStatus.fromMap(map['privacy'] as Map<String, dynamic>),
    );
  }
}

// --- Final Composed FeatureState ---
class WifiBundleState extends FeatureState<WifiBundleSettings, WifiBundleStatus> {
  const WifiBundleState({
    required super.settings,
    required super.status,
  });

  @override
  WifiBundleState copyWith({
    Preservable<WifiBundleSettings>? settings,
    WifiBundleStatus? status,
  }) {
    return WifiBundleState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    // Not strictly necessary for this refactoring, as serialization is handled by sub-models.
    return {};
  }
}
