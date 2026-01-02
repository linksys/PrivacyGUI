// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';

/// State class for InstantVerify feature
///
/// Uses UI Models instead of JNAP Models to maintain layer separation.
class InstantVerifyState extends Equatable {
  final WANConnectionUIModel? wanConnection;
  final RadioInfoUIModel radioInfo;
  final GuestRadioSettingsUIModel guestRadioSettings;
  final WanExternalUIModel? wanExternal;
  final bool isRunning;

  const InstantVerifyState({
    this.wanConnection,
    required this.radioInfo,
    required this.guestRadioSettings,
    this.wanExternal,
    this.isRunning = false,
  });

  /// Initial state factory constructor
  const InstantVerifyState.initial()
      : wanConnection = null,
        radioInfo = const RadioInfoUIModel.initial(),
        guestRadioSettings = const GuestRadioSettingsUIModel.initial(),
        wanExternal = null,
        isRunning = false;

  InstantVerifyState copyWith({
    WANConnectionUIModel? wanConnection,
    RadioInfoUIModel? radioInfo,
    GuestRadioSettingsUIModel? guestRadioSettings,
    WanExternalUIModel? wanExternal,
    bool? isRunning,
  }) {
    return InstantVerifyState(
      wanConnection: wanConnection ?? this.wanConnection,
      radioInfo: radioInfo ?? this.radioInfo,
      guestRadioSettings: guestRadioSettings ?? this.guestRadioSettings,
      wanExternal: wanExternal ?? this.wanExternal,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wanConnection': wanConnection?.toMap(),
      'radioInfo': radioInfo.toMap(),
      'guestRadioSettings': guestRadioSettings.toMap(),
      'wanExternal': wanExternal?.toMap(),
      'isRunning': isRunning,
    }..removeWhere((key, value) => value == null);
  }

  factory InstantVerifyState.fromMap(Map<String, dynamic> map) {
    return InstantVerifyState(
      wanConnection: map['wanConnection'] == null
          ? null
          : WANConnectionUIModel.fromMap(
              map['wanConnection'] as Map<String, dynamic>),
      radioInfo:
          RadioInfoUIModel.fromMap(map['radioInfo'] as Map<String, dynamic>),
      guestRadioSettings: GuestRadioSettingsUIModel.fromMap(
          map['guestRadioSettings'] as Map<String, dynamic>),
      wanExternal: map['wanExternal'] == null
          ? null
          : WanExternalUIModel.fromMap(
              map['wanExternal'] as Map<String, dynamic>),
      isRunning: map['isRunning'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantVerifyState.fromJson(String source) =>
      InstantVerifyState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props =>
      [wanConnection, radioInfo, guestRadioSettings, wanExternal, isRunning];
}
