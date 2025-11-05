// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class SupportState extends Equatable {
  final String linksysToken;
  final String? clientDeviceId;

  const SupportState({
    required this.linksysToken,
    this.clientDeviceId,
  });

  factory SupportState.init() {
    return const SupportState(
      linksysToken: '',
    );
  }

  SupportState copyWith({
    String? linksysToken,
    String? clientDeviceId,
  }) {
    return SupportState(
      linksysToken: linksysToken ?? this.linksysToken,
      clientDeviceId: clientDeviceId ?? this.clientDeviceId,
    );
  }

  @override
  List<Object?> get props => [linksysToken, clientDeviceId];
}
