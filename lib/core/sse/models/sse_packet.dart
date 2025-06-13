import 'dart:convert';

import 'package:equatable/equatable.dart';

///  Custom SSE Packet format
///
///  id: event id
///  data: event data
///  eventType: event type
///  retry: retry count
///  timestamp: event timestamp
///  message: event message
/// 
class SSEPacket extends Equatable {
  final String id;
  final String data;
  final String eventType;
  final int retry;
  final int timestamp;
  final String message;
  const SSEPacket({
    required this.id,
    required this.data,
    required this.eventType,
    required this.retry,
    required this.timestamp,
    required this.message,
  });

  SSEPacket copyWith({
    String? id,
    String? data,
    String? eventType,
    int? retry,
    int? timestamp,
    String? message,
  }) {
    return SSEPacket(
      id: id ?? this.id,
      data: data ?? this.data,
      eventType: eventType ?? this.eventType,
      retry: retry ?? this.retry,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
    );
  }

  factory SSEPacket.fromMap(Map<String, dynamic> map) {
    return SSEPacket(
      id: map['id'],
      data: map['data'],
      eventType: map['eventType'],
      retry: map['retry'],
      timestamp: map['timestamp'],
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'eventType': eventType,
      'retry': retry,
      'timestamp': timestamp,
      'message': message,
    };
  }

  factory SSEPacket.fromJson(String source) =>
      SSEPacket.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
  @override
  String toString() =>
      'SSEPacket(id: $id, data: $data, eventType: $eventType, retry: $retry, timestamp: $timestamp, message: $message)';

  @override
  List<Object?> get props => [
        id,
        data,
        eventType,
        retry,
        timestamp,
        message,
      ];
}