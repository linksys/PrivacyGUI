// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';

class WiFiState extends Equatable {
  final List<WiFiItem> mainWiFi;
  final WiFiItem simpleWiFi;

  const WiFiState({
    required this.mainWiFi,
    required this.simpleWiFi,
  });

  WiFiState copyWith({
    List<WiFiItem>? mainWiFi,
    WiFiItem? simpleWiFi,
  }) {
    return WiFiState(
      mainWiFi: mainWiFi ?? this.mainWiFi,
      simpleWiFi: simpleWiFi ?? this.simpleWiFi,
    );
  }

  @override
  List<Object> get props => [
        mainWiFi,
        simpleWiFi,
      ];
}
