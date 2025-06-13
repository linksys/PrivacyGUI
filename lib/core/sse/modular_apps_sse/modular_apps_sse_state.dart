// create a state class for SSE connection
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/sse/models/sse_packet.dart';

class SSEConnectionState extends Equatable {
  final bool isConnected;
  final List<SSEPacket> packets;
  final String? lastEventId;
  const SSEConnectionState({
    this.isConnected = false,
    this.packets = const [],
    this.lastEventId,
  });

  SSEConnectionState copyWith(
      {bool? isConnected, List<SSEPacket>? packets, String? lastEventId}) {
    return SSEConnectionState(
        isConnected: isConnected ?? this.isConnected,
        packets: packets ?? this.packets,
        lastEventId: lastEventId ?? this.lastEventId);
  }

  factory SSEConnectionState.fromMap(Map<String, dynamic> map) {
    return SSEConnectionState(
      isConnected: map['isConnected'],
      packets: map['packets'].map((x) => SSEPacket.fromMap(x)).toList(),
      lastEventId: map['lastEventId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isConnected': isConnected,
      'packets': packets,
      'lastEventId': lastEventId,
    };
  }

  factory SSEConnectionState.fromJson(String source) =>
      SSEConnectionState.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [isConnected, packets, lastEventId];
}