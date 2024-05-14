// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class FirmwareAutoUpdateWindow extends Equatable {
  final int startMinute;
  final int durationMinutes;
  const FirmwareAutoUpdateWindow({
    required this.startMinute,
    required this.durationMinutes,
  });

  factory FirmwareAutoUpdateWindow.simple() =>
      const FirmwareAutoUpdateWindow(startMinute: 0, durationMinutes: 240);

  FirmwareAutoUpdateWindow copyWith({
    int? startMinute,
    int? durationMinutes,
  }) {
    return FirmwareAutoUpdateWindow(
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
    };
  }

  factory FirmwareAutoUpdateWindow.fromMap(Map<String, dynamic> map) {
    return FirmwareAutoUpdateWindow(
      startMinute: map['startMinute'],
      durationMinutes: map['durationMinutes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareAutoUpdateWindow.fromJson(String source) =>
      FirmwareAutoUpdateWindow.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [startMinute, durationMinutes];
}

class FirmwareUpdateSettings extends Equatable {
  static const firmwareUpdatePolicyManual = 'Manual';
  static const firmwareUpdatePolicyAuto = 'AutomaticallyCheckAndInstall';

  final String updatePolicy;
  final FirmwareAutoUpdateWindow autoUpdateWindow;
  const FirmwareUpdateSettings({
    required this.updatePolicy,
    required this.autoUpdateWindow,
  });

  FirmwareUpdateSettings copyWith({
    String? updatePolicy,
    FirmwareAutoUpdateWindow? autoUpdateWindow,
  }) {
    return FirmwareUpdateSettings(
      updatePolicy: updatePolicy ?? this.updatePolicy,
      autoUpdateWindow: autoUpdateWindow ?? this.autoUpdateWindow,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'updatePolicy': updatePolicy,
      'autoUpdateWindow': autoUpdateWindow.toMap(),
    };
  }

  factory FirmwareUpdateSettings.fromMap(Map<String, dynamic> map) {
    return FirmwareUpdateSettings(
      updatePolicy: map['updatePolicy'] as String,
      autoUpdateWindow: FirmwareAutoUpdateWindow.fromMap(
          map['autoUpdateWindow'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory FirmwareUpdateSettings.fromJson(String source) =>
      FirmwareUpdateSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [updatePolicy, autoUpdateWindow];
}
