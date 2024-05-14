// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class SendSysinfoEmail extends Equatable {
  final List<String> addressList;

  const SendSysinfoEmail({
    required this.addressList,
  });

  SendSysinfoEmail copyWith({
    List<String>? addressList,
  }) {
    return SendSysinfoEmail(
      addressList: addressList ?? this.addressList,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'addressList': addressList,
    }..removeWhere((key, value) => value == null);
  }

  factory SendSysinfoEmail.fromJson(Map<String, dynamic> map) {
    return SendSysinfoEmail(
        addressList: List<String>.from(
      (map['addressList'] as List<String>),
    ));
  }

  @override
  List<Object?> get props => [addressList];
}
