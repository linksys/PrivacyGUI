import 'package:equatable/equatable.dart';

class CloudSessionData extends Equatable {
  const CloudSessionData({required this.id, required this.expiration});

  factory CloudSessionData.fromJson(Map<String, dynamic> json) {
    return CloudSessionData(
      id: json['id'],
      expiration: json['expiration'],
    );
  }

  final String id;
  final String expiration;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expiration': expiration,
    };
  }

  @override
  List<Object?> get props => [id, expiration];
}
