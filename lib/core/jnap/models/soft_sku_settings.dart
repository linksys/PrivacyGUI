// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class SoftSKUSettings extends Equatable {
  final String modelNumber;
  const SoftSKUSettings({
    required this.modelNumber,
  });

  SoftSKUSettings copyWith({
    String? modelNumber,
  }) {
    return SoftSKUSettings(
      modelNumber: modelNumber ?? this.modelNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'modelNumber': modelNumber,
    };
  }

  factory SoftSKUSettings.fromMap(Map<String, dynamic> map) {
    return SoftSKUSettings(
      modelNumber: map['modelNumber'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SoftSKUSettings.fromJson(String source) => SoftSKUSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [modelNumber];
}
