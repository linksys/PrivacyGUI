// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';

class WiFiState extends Equatable {
  final List<WiFiItem> mainWiFi;
  final GuestWiFiItem guestWiFi;
  final bool canDisableMainWiFi;
  final bool isSimpleMode;
  final WiFiItem simpleModeWifi;

  const WiFiState({
    required this.mainWiFi,
    required this.guestWiFi,
    this.canDisableMainWiFi = true,
    this.isSimpleMode = true,
    required this.simpleModeWifi,
  });

  WiFiState copyWith({
    List<WiFiItem>? mainWiFi,
    GuestWiFiItem? guestWiFi,
    bool? canDisableMainWiFi,
    bool? isSimpleMode,
    WiFiItem? simpleModeWifi,
  }) {
    return WiFiState(
      mainWiFi: mainWiFi ?? this.mainWiFi,
      guestWiFi: guestWiFi ?? this.guestWiFi,
      canDisableMainWiFi: canDisableMainWiFi ?? this.canDisableMainWiFi,
      isSimpleMode: isSimpleMode ?? this.isSimpleMode,
      simpleModeWifi: simpleModeWifi ?? this.simpleModeWifi,
    );
  }

  @override
  List<Object> get props => [
        mainWiFi,
        guestWiFi,
        canDisableMainWiFi,
        isSimpleMode,
        simpleModeWifi,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mainWiFi': mainWiFi.map((x) => x.toMap()).toList(),
      'guestWiFi': guestWiFi.toMap(),
      'canDisableMainWiFi': canDisableMainWiFi,
      'isSimpleMode': isSimpleMode,
      'simpleModeWifi': simpleModeWifi.toMap(),
    };
  }

  factory WiFiState.fromMap(Map<String, dynamic> map) {
    return WiFiState(
      mainWiFi: List<WiFiItem>.from(
        map['mainWiFi'].map<WiFiItem>(
          (x) => WiFiItem.fromMap(x),
        ),
      ),
      guestWiFi: GuestWiFiItem.fromMap(map['guestWiFi'] ?? {}),
      canDisableMainWiFi: map['canDisableMainWiFi'],
      isSimpleMode: map['isSimpleMode'] as bool? ?? true,
      simpleModeWifi: WiFiItem.fromMap(map['simpleModeWifi'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiState.fromJson(String source) =>
      WiFiState.fromMap(json.decode(source) as Map<String, dynamic>);
}