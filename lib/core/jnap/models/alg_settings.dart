// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class ALGSettings extends Equatable {
  final bool isSIPEnabled;
  const ALGSettings({
    required this.isSIPEnabled,
  });

  ALGSettings copyWith({
    bool? isSIPEnabled,
  }) {
    return ALGSettings(
      isSIPEnabled: isSIPEnabled ?? this.isSIPEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isSIPEnabled': isSIPEnabled,
    };
  }

  factory ALGSettings.fromMap(Map<String, dynamic> map) {
    return ALGSettings(
      isSIPEnabled: map['isSIPEnabled'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory ALGSettings.fromJson(String source) => ALGSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isSIPEnabled];
}
