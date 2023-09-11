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
/// OR
///   {
///     "id": "00000000-0000-0000-0000-000000000001",
///     "method": "EMAIL",
///     "targetValue": "foo***@example.com"
///   }
///
class CommunicationMethod extends Equatable {
  const CommunicationMethod({
    this.id,
    required this.method,
    required this.target,
    this.phone,
  });

  factory CommunicationMethod.fromJson(Map<String, dynamic> json) {
    return CommunicationMethod(
        id: json['id'],
        method: json['method'],
        target: json['target'],
        phone: json['phone'] == null
            ? null
            : CloudPhoneModel.fromJson(json['phone']));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'method': method,
      'target': target,
    };
    if (id != null) {
      json.addAll({'id': id});
    }
    if (phone != null) {
      json.addAll({'phone': phone!.toJson()});
    }
    return json;
  }

  final String? id;
  final String method;
  final String target;
  final CloudPhoneModel? phone;

  @override
  List<Object?> get props => [id, method, target, phone];

  @override
  bool? get stringify => true;
}
