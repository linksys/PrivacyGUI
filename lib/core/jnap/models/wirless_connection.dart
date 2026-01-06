import 'dart:convert';

import 'package:equatable/equatable.dart';

class WirelessConnection extends Equatable {
  final String bssid;
  final bool isGuest;
  final String? radioID;
  final String band;
  final int signalDecibels;
  final int? txRate;
  final int? rxRate;
  final bool? isMLOCapable;

  const WirelessConnection({
    required this.bssid,
    required this.isGuest,
    this.radioID,
    required this.band,
    required this.signalDecibels,
    this.txRate,
    this.rxRate,
    this.isMLOCapable,
  });

  WirelessConnection copyWith({
    String? bssid,
    bool? isGuest,
    String? radioID,
    String? band,
    int? signalBecibels,
    int? txRate,
    int? rxRate,
    bool? isMLOCapable,
  }) {
    return WirelessConnection(
      bssid: bssid ?? this.bssid,
      isGuest: isGuest ?? this.isGuest,
      radioID: radioID ?? this.radioID,
      band: band ?? this.band,
      signalDecibels: signalBecibels ?? signalDecibels,
      txRate: txRate ?? this.txRate,
      rxRate: rxRate ?? this.rxRate,
      isMLOCapable: isMLOCapable ?? this.isMLOCapable,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bssid': bssid,
      'isGuest': isGuest,
      'radioID': radioID,
      'band': band,
      'signalDecibels': signalDecibels,
      'txRate': txRate,
      'rxRate': rxRate,
      'isMLOCapable': isMLOCapable,
    }..removeWhere((key, value) => value == null);
  }

  factory WirelessConnection.fromMap(Map<String, dynamic> map) {
    return WirelessConnection(
      bssid: map['bssid'] as String,
      isGuest: map['isGuest'] as bool,
      radioID: map['radioID'] != null ? map['radioID'] as String : null,
      band: map['band'] as String,
      signalDecibels: map['signalDecibels'] as int,
      txRate: map['txRate'] != null ? map['txRate'] as int : null,
      rxRate: map['rxRate'] != null ? map['rxRate'] as int : null,
      isMLOCapable:
          map['isMLOCapable'] != null ? map['isMLOCapable'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WirelessConnection.fromJson(String source) =>
      WirelessConnection.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      bssid,
      isGuest,
      radioID,
      band,
      signalDecibels,
      txRate,
      rxRate,
      isMLOCapable,
    ];
  }
}
