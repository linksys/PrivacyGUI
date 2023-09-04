// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class CloudEventAction extends Equatable {
  final String actionType;
  final String startAt;
  final String endAt;
  final String timestoTrigger;
  final String triggerInterval;
  final String payload;
  const CloudEventAction({
    required this.actionType,
    required this.startAt,
    required this.endAt,
    required this.timestoTrigger,
    required this.triggerInterval,
    required this.payload,
  });

  @override
  List<Object> get props {
    return [
      actionType,
      startAt,
      endAt,
      timestoTrigger,
      triggerInterval,
      payload,
    ];
  }

  CloudEventAction copyWith({
    String? actionType,
    String? startAt,
    String? endAt,
    String? timestoTrigger,
    String? triggerInterval,
    String? payload,
  }) {
    return CloudEventAction(
      actionType: actionType ?? this.actionType,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timestoTrigger: timestoTrigger ?? this.timestoTrigger,
      triggerInterval: triggerInterval ?? this.triggerInterval,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'actionType': actionType,
      'startAt': startAt,
      'endAt': endAt,
      'timestoTrigger': timestoTrigger,
      'triggerInterval': triggerInterval,
      'payload': payload,
    };
  }

  factory CloudEventAction.fromMap(Map<String, dynamic> map) {
    return CloudEventAction(
      actionType: map['actionType'] as String,
      startAt: map['startAt'] as String,
      endAt: map['endAt'] as String,
      timestoTrigger: map['timestoTrigger'] as String,
      triggerInterval: map['triggerInterval'] as String,
      payload: map['payload'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudEventAction.fromJson(String source) =>
      CloudEventAction.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
