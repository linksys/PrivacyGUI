// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';

import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';

class InstantVerifyState extends Equatable {
  final WANConnectionInfo? wanConnection;
  final GetRadioInfo radioInfo;
  final GuestRadioSettings guestRadioSettings;

  const InstantVerifyState({
    this.wanConnection,
    required this.radioInfo,
    required this.guestRadioSettings,
  });

  InstantVerifyState copyWith({
    WANConnectionInfo? wanConnection,
    GetRadioInfo? radioInfo,
    GuestRadioSettings? guestRadioSettings,
  }) {
    return InstantVerifyState(
      wanConnection: wanConnection ?? this.wanConnection,
      radioInfo: radioInfo ?? this.radioInfo,
      guestRadioSettings: guestRadioSettings ?? this.guestRadioSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wanConnection': wanConnection?.toMap(),
      'radioInfo': radioInfo.toMap(),
      'guestRadioSettings': guestRadioSettings.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory InstantVerifyState.fromMap(Map<String, dynamic> map) {
    return InstantVerifyState(
      wanConnection: map['wanConnection'] == null
          ? null
          : WANConnectionInfo.fromMap(
              map['wanConnection'] as Map<String, dynamic>),
      radioInfo: GetRadioInfo.fromMap(map['radioInfo'] as Map<String, dynamic>),
      guestRadioSettings: GuestRadioSettings.fromMap(map['guestRadioSettings']),
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantVerifyState.fromJson(String source) =>
      InstantVerifyState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [wanConnection, radioInfo];
}