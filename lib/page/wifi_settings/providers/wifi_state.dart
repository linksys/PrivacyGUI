// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';

class WiFiState extends Equatable {
  final List<WiFiItem> mainWiFi;
  final GuestWiFiItem guestWiFi;

  const WiFiState({
    required this.mainWiFi,
    required this.guestWiFi,
  });

  WiFiState copyWith({
    List<WiFiItem>? mainWiFi,
    GuestWiFiItem? guestWiFi,
  }) {
    return WiFiState(
      mainWiFi: mainWiFi ?? this.mainWiFi,
      guestWiFi: guestWiFi ?? this.guestWiFi,
    );
  }

  @override
  List<Object> get props => [
        mainWiFi,
        guestWiFi,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mainWiFi': mainWiFi.map((x) => x.toMap()).toList(),
      'guestWiFi': guestWiFi.toMap(),
    };
  }

  factory WiFiState.fromMap(Map<String, dynamic> map) {
    return WiFiState(
      mainWiFi: List<WiFiItem>.from(
        map['mainWiFi'].map<WiFiItem>(
          (x) => WiFiItem.fromMap(x),
        ),
      ),
      guestWiFi: GuestWiFiItem.fromMap(map['guestWiFi']),
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiState.fromJson(String source) =>
      WiFiState.fromMap(json.decode(source) as Map<String, dynamic>);
}
