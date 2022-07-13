import 'package:equatable/equatable.dart';

///
/// {
///     "isoLanguageCode": "zh",
///     "isoCountryCode": "TW",
///     "timeZone": "Asia/Taipei"
///   }
///
class CloudPreferences extends Equatable {
  const CloudPreferences({
    required this.isoLanguageCode,
    required this.isoCountryCode,
    required this.timeZone,
  });

  factory CloudPreferences.fromJson(Map<String, dynamic> json) {
    return CloudPreferences(
        isoLanguageCode: json['isoLanguageCode'],
        isoCountryCode: json['isoCountryCode'],
        timeZone: json['timeZone']);
  }

  Map<String, dynamic> toJson() {
    return {
      'isoLanguageCode': isoLanguageCode,
      'isoCountryCode': isoCountryCode,
      'timeZone': timeZone,
    };
  }

  final String isoLanguageCode;
  final String isoCountryCode;
  final String timeZone;

  @override
  List<Object?> get props => [isoLanguageCode, isoCountryCode, timeZone,];
}
