// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class ExpressForwardingSettings extends Equatable {
  final bool isExpressForwardingSupported;
  final bool? isExpressForwardingEnabled;
  const ExpressForwardingSettings({
    required this.isExpressForwardingSupported,
    this.isExpressForwardingEnabled,
  });

  ExpressForwardingSettings copyWith({
    bool? isExpressForwardingSupported,
    bool? isExpressForwardingEnabled,
  }) {
    return ExpressForwardingSettings(
      isExpressForwardingSupported:
          isExpressForwardingSupported ?? this.isExpressForwardingSupported,
      isExpressForwardingEnabled:
          isExpressForwardingEnabled ?? this.isExpressForwardingEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isExpressForwardingSupported': isExpressForwardingSupported,
      'isExpressForwardingEnabled': isExpressForwardingEnabled,
    };
  }

  factory ExpressForwardingSettings.fromMap(Map<String, dynamic> map) {
    return ExpressForwardingSettings(
      isExpressForwardingSupported: map['isExpressForwardingSupported'] as bool,
      isExpressForwardingEnabled: map['isExpressForwardingEnabled'] != null
          ? map['isExpressForwardingEnabled'] as bool
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExpressForwardingSettings.fromJson(String source) =>
      ExpressForwardingSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props =>
      [isExpressForwardingSupported, isExpressForwardingEnabled];

  Map<String, dynamic> toSetSettingsMap() {
    return <String, dynamic>{
      'isExpressForwardingEnabled': isExpressForwardingEnabled ?? false,
    };
  }
}
