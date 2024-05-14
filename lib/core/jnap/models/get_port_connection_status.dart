// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class GetPortConnectionStatus extends Equatable {
  final List<PortConnectionStatus> portConnectionStatus;

  const GetPortConnectionStatus({
    required this.portConnectionStatus,
  });

  GetPortConnectionStatus copyWith({
    List<PortConnectionStatus>? portConnectionStatus,
  }) {
    return GetPortConnectionStatus(
      portConnectionStatus: portConnectionStatus ?? this.portConnectionStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'portConnectionStatus':
          portConnectionStatus.map((x) => x.toJson()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  factory GetPortConnectionStatus.fromJson(Map<String, dynamic> map) {
    return GetPortConnectionStatus(
      portConnectionStatus: List<PortConnectionStatus>.from(
        map['portConnectionStatus'].map<PortConnectionStatus>(
          (x) => PortConnectionStatus.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [portConnectionStatus];
}

class PortConnectionStatus extends Equatable {
  final int portId;
  final String connectionState;

  const PortConnectionStatus({
    required this.portId,
    required this.connectionState,
  });

  PortConnectionStatus copyWith({
    int? portId,
    String? connectionState,
  }) {
    return PortConnectionStatus(
      portId: portId ?? this.portId,
      connectionState: connectionState ?? this.connectionState,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'portId': portId,
      'connectionState': connectionState,
    }..removeWhere((key, value) => value == null);
  }

  factory PortConnectionStatus.fromJson(Map<String, dynamic> map) {
    return PortConnectionStatus(
      portId: map['portId'] as int,
      connectionState: map['connectionState'] as String,
    );
  }

  @override
  List<Object?> get props => [portId, connectionState];
}
