// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mainWiFi': mainWiFi.map((x) => x.toMap()).toList(),
      'simpleWiFi': simpleWiFi.toMap(),
    };
  }

  factory WiFiState.fromMap(Map<String, dynamic> map) {
    return WiFiState(
      mainWiFi: List<WiFiItem>.from(
        map['mainWiFi'].map<WiFiItem>(
          (x) => WiFiItem.fromMap(x),
        ),
      ),
      simpleWiFi: WiFiItem.fromMap(map['simpleWiFi']),
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiState.fromJson(String source) =>
      WiFiState.fromMap(json.decode(source) as Map<String, dynamic>);
}
