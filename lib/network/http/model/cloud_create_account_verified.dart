import 'package:equatable/equatable.dart';

import 'cloud_preferences.dart';

///
/// {
///   "token": "string",
///   "authenticationMode": "PASSWORD",
///   "password": "string",
///   "preferences": {
///     "isoLanguageCode": "zh",
///     "isoCountryCode": "TW",
///     "timeZone": "Asia/Taipei"
///   },
///   "generateCert": true
/// }
///
class CreateAccountVerified extends Equatable {
  const CreateAccountVerified({
    required this.token,
    required this.authenticationMode,
    this.password,
    required this.preferences,
    this.generateCert = true,
  });

  factory CreateAccountVerified.fromJson(Map<String, dynamic> json) {
    return CreateAccountVerified(
      token: json['token'],
      authenticationMode: json['authenticationMode'],
      password: json['password'],
      preferences: CloudPreferences.fromJson(json['preferences']),
      generateCert: json['generateCert'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'token': token,
      'authenticationMode': authenticationMode,
      'preferences': preferences.toJson(),
      'generateCert': generateCert,
    };
    if (password != null) {
      json.addAll({'password': password});
    }
    return json;
  }

  final String token;
  final String authenticationMode;
  final String? password;
  final CloudPreferences preferences;
  final bool generateCert;

  @override
  List<Object?> get props => [token, authenticationMode, password, preferences];
}
