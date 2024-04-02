// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class WANPort extends Equatable {
  final int portId;
  const WANPort({
    required this.portId,
  });

  WANPort copyWith({
    int? portId,
  }) {
    return WANPort(
      portId: portId ?? this.portId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'portId': portId,
    }..removeWhere((key, value) => value == null);
  }

  factory WANPort.fromJson(Map<String, dynamic> map) {
    return WANPort(
      portId: map['portId'] as int,
    );
  }

  @override
  List<Object?> get props => [portId];
}
