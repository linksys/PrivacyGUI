import 'dart:convert';

import 'package:equatable/equatable.dart';

class SpeedStatus extends Equatable {
  final int primaryDownloadSpeed;
  final int primaryUploadSpeed;
  final int secondaryDownloadSpeed;
  final int secondaryUploadSpeed;

  const SpeedStatus({
    this.primaryDownloadSpeed = 0,
    this.primaryUploadSpeed = 0,
    this.secondaryDownloadSpeed = 0,
    this.secondaryUploadSpeed = 0,
  });

  SpeedStatus copyWith({
    int? primaryDownloadSpeed,
    int? primaryUploadSpeed,
    int? secondaryDownloadSpeed,
    int? secondaryUploadSpeed,
  }) {
    return SpeedStatus(
      primaryDownloadSpeed: primaryDownloadSpeed ?? this.primaryDownloadSpeed,
      primaryUploadSpeed: primaryUploadSpeed ?? this.primaryUploadSpeed,
      secondaryDownloadSpeed:
          secondaryDownloadSpeed ?? this.secondaryDownloadSpeed,
      secondaryUploadSpeed: secondaryUploadSpeed ?? this.secondaryUploadSpeed,
    );
  }

  factory SpeedStatus.fromMap(Map<String, dynamic> map) {
    return SpeedStatus(
      primaryDownloadSpeed: map['primaryDownloadSpeed'],
      primaryUploadSpeed: map['primaryUploadSpeed'],
      secondaryDownloadSpeed: map['secondaryDownloadSpeed'],
      secondaryUploadSpeed: map['secondaryUploadSpeed'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SpeedStatus.fromJson(String source) =>
      SpeedStatus.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'primaryDownloadSpeed': primaryDownloadSpeed,
      'primaryUploadSpeed': primaryUploadSpeed,
      'secondaryDownloadSpeed': secondaryDownloadSpeed,
      'secondaryUploadSpeed': secondaryUploadSpeed,
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        primaryDownloadSpeed,
        primaryUploadSpeed,
        secondaryDownloadSpeed,
        secondaryUploadSpeed,
      ];
}