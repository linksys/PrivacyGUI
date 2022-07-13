import 'package:equatable/equatable.dart';

///
/// {
///   "country": "TW",
///   "countryCallingCode": "+886",
///   "phoneNumber": "900000000",
///   "full": "+886900000000"
/// }
///
class CloudPhoneModel extends Equatable {
  const CloudPhoneModel({
    required this.country,
    required this.countryCallingCode,
    required this.phoneNumber,
  }) : full = '$countryCallingCode$phoneNumber';

  factory CloudPhoneModel.fromJson(Map<String, dynamic> json) {
    return CloudPhoneModel(
        country: json['country'],
        countryCallingCode: json['countryCallingCode'],
        phoneNumber: json['phoneNumber']);
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'countryCallingCode': countryCallingCode,
      'phoneNumber': phoneNumber,
      'full': full,
    };
  }

  final String country;
  final String countryCallingCode;
  final String phoneNumber;
  final String full;

  @override
  List<Object?> get props => [country, countryCallingCode, phoneNumber, full];
}
