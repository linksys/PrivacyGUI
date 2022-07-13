import 'package:equatable/equatable.dart';

import 'cloud_phone.dart';

///
/// {
///   "communicationMethods": [
///     {
///       "method": "EMAIL",
///       "targetValue": "+886900000000",
///       "phone": {
///         "country": "TW",
///         "countryCallingCode": "+886",
///         "phoneNumber": "900000000",
///        "full": "+886900000000"
///       }
///     }
///   ]
/// }
///
class CommunicationMethod extends Equatable {
  const CommunicationMethod({
    required this.method,
    required this.targetValue,
    this.phone,
  });

  factory CommunicationMethod.fromJson(Map<String, dynamic> json) {
    return CommunicationMethod(
        method: json['method'],
        targetValue: json['targetValue'],
        phone: json['phone'] == null ? null : CloudPhoneModel.fromJson(json['phone']));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'method': method,
      'targetValue': targetValue,
    };
    if (phone != null) {
      json.addAll({'phone': phone!.toJson()});
    }
    return json;
  }

  final String method;
  final String targetValue;
  final CloudPhoneModel? phone;

  @override
  List<Object?> get props => [method, targetValue, phone];
}
