// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';

class WiFiListSettings extends Equatable {
  final List<WiFiItem> mainWiFi;
  final GuestWiFiItem guestWiFi;
  final bool isSimpleMode;
  final WiFiItem simpleModeWifi;

  const WiFiListSettings({
    required this.mainWiFi,
    required this.guestWiFi,
    this.isSimpleMode = true,
    required this.simpleModeWifi,
  });

  @override
  List<Object> get props => [
        mainWiFi,
        guestWiFi,
        isSimpleMode,
        simpleModeWifi,
      ];

  // copyWith, toMap, fromMap, etc.
  WiFiListSettings copyWith({
    List<WiFiItem>? mainWiFi,
    GuestWiFiItem? guestWiFi,
    bool? isSimpleMode,
    WiFiItem? simpleModeWifi,
  }) {
    return WiFiListSettings(
      mainWiFi: mainWiFi ?? this.mainWiFi,
      guestWiFi: guestWiFi ?? this.guestWiFi,
      isSimpleMode: isSimpleMode ?? this.isSimpleMode,
      simpleModeWifi: simpleModeWifi ?? this.simpleModeWifi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mainWiFi': mainWiFi.map((x) => x.toMap()).toList(),
      'guestWiFi': guestWiFi.toMap(),
      'isSimpleMode': isSimpleMode,
      'simpleModeWifi': simpleModeWifi.toMap(),
    };
  }

  factory WiFiListSettings.fromMap(Map<String, dynamic> map) {
    return WiFiListSettings(
      mainWiFi: List<WiFiItem>.from(
        map['mainWiFi'].map<WiFiItem>(
          (x) => WiFiItem.fromMap(x),
        ),
      ),
      guestWiFi: GuestWiFiItem.fromMap(map['guestWiFi'] ?? {}),
      isSimpleMode: map['isSimpleMode'] as bool? ?? true,
      simpleModeWifi: WiFiItem.fromMap(map['simpleModeWifi'] ?? {}),
    );
  }
}

class WiFiListStatus extends Equatable {
  final bool canDisableMainWiFi;

  const WiFiListStatus({
    this.canDisableMainWiFi = true,
  });

  @override
  List<Object> get props => [canDisableMainWiFi];

  // copyWith, toMap, fromMap
  WiFiListStatus copyWith({
    bool? canDisableMainWiFi,
  }) {
    return WiFiListStatus(
      canDisableMainWiFi: canDisableMainWiFi ?? this.canDisableMainWiFi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'canDisableMainWiFi': canDisableMainWiFi,
    };
  }

  factory WiFiListStatus.fromMap(Map<String, dynamic> map) {
    return WiFiListStatus(
      canDisableMainWiFi: map['canDisableMainWiFi'] as bool? ?? true,
    );
  }
}
