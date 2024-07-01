// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';

class WiFiState extends Equatable {
  final List<WiFiItem> mainWiFi;
  final WiFiItem simpleWiFi;
  final bool mloSettingsConflict;

  const WiFiState({
    required this.mainWiFi,
    required this.simpleWiFi,
    this.mloSettingsConflict = false,
  });

  WiFiState copyWith({
    List<WiFiItem>? mainWiFi,
    WiFiItem? simpleWiFi,
    bool? mloSettingsConflict,
  }) {
    return WiFiState(
      mainWiFi: mainWiFi ?? this.mainWiFi,
      simpleWiFi: simpleWiFi ?? this.simpleWiFi,
      mloSettingsConflict: mloSettingsConflict ?? this.mloSettingsConflict,
    );
  }

  @override
  List<Object> get props => [
        mainWiFi,
        simpleWiFi,
        mloSettingsConflict,
      ];
}
