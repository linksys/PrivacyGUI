// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class CAUserAccount extends Equatable {
  final String accountId;
  final String username;
  final String? emailAddress;
  final String? password;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? cdnUsername;
  final String alias;
  final String status;
  final String? gender;
  final CAPreferences? preferences;

  const CAUserAccount({
    required this.accountId,
    required this.username,
    this.emailAddress,
    this.password,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.cdnUsername,
    required this.alias,
    required this.status,
    this.gender,
    required this.preferences,
  });

  factory CAUserAccount.fromJson(Map<String, dynamic> json) {
    return CAUserAccount(
      accountId: json['accountId'],
      username: json['username'],
      emailAddress: json['emailAddress'],
      password: json['password'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      cdnUsername: json['cdnUsername'],
      alias: json['alias'],
      status: json['status'],
      gender: json['gender'],
      preferences: json['preferences'] != null
          ? CAPreferences.fromJson(json['preferences'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'username': username,
        'emailAddress': emailAddress,
        'password': password,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'cdnUsername': cdnUsername,
        'alias': alias,
        'status': status,
        'gender': gender,
        'preferences': preferences?.toJson(),
      }..removeWhere((key, value) => value == null);

  @override
  List<Object?> get props {
    return [
      accountId,
      username,
      emailAddress,
      password,
      firstName,
      middleName,
      lastName,
      cdnUsername,
      alias,
      status,
      gender,
      preferences,
    ];
  }
}

class CANotification extends Equatable {
  final String? type;
  final String? value;

  const CANotification({
    this.type,
    this.value,
  });

  CANotification copyWith({
    String? type,
    String? value,
  }) {
    return CANotification(
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  factory CANotification.fromJson(Map<String, dynamic> json) {
    return CANotification(
      type: json['type'],
      value: json['value'],
    );
  }

  @override
  List<Object?> get props => [type, value];
}

class CANotifications extends Equatable {
  final List<CANotification> notifications;

  const CANotifications({
    this.notifications = const [],
  });

  CANotifications copyWith({
    List<CANotification>? notifications,
  }) {
    return CANotifications(
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {'notification': notifications.map((e) => e.toJson()).toList()};
  }

  factory CANotifications.fromJson(Map<String, dynamic> json) {
    return CANotifications(
      notifications: List.from(json['notification'])
          .map((e) => CANotification.fromJson(e))
          .toList(),
    );
  }

  @override
  List<Object> get props => [notifications];
}

class CAMobile extends Equatable {
  final String? countryCode;
  final String? phoneNumber;

  String? get fullFormat => '$countryCode$phoneNumber';
  const CAMobile({
    this.countryCode,
    this.phoneNumber,
  });

  CAMobile copyWith({
    String? countryCode,
    String? phoneNumber,
  }) {
    return CAMobile(
      countryCode: countryCode ?? this.countryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
    };
  }

  factory CAMobile.fromMap(Map<String, dynamic> json) {
    return CAMobile(
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CAMobile.fromJson(String source) =>
      CAMobile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [countryCode, phoneNumber];
}

class CALocale extends Equatable {
  final String? language;
  final String? country;

  const CALocale({
    this.language,
    this.country,
  });

  CALocale copyWith({
    String? language,
    String? country,
  }) {
    return CALocale(
      language: language ?? language,
      country: country ?? country,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'country': country,
    };
  }

  factory CALocale.fromJson(Map<String, dynamic> json) {
    return CALocale(
      language: json['language'],
      country: json['country'],
    );
  }

  @override
  List<Object?> get props => [language, country];
}

///
/// {
///   "locale": {
///     "language": "en",
///     "country": "US"
///   },
///   "newsletterOptIn": "false",
///   "fakeSubscription": false,
///   "notifications": {
///     "notification": [
///
///     ]
///   },
///   "mfaEnabled": false,
///   "mobile": {
///     "countryCode": "+886",
///     "phoneNumber": "908720012"
///  }
/// }
///
class CAPreferences extends Equatable {
  final String? newsletterOptIn;
  final bool? fakeSubscription;
  final bool? mfaEnabled;
  final CALocale? locale;
  final CAMobile? mobile;
  final CANotifications? notifications;

  const CAPreferences({
    this.newsletterOptIn,
    this.fakeSubscription,
    this.mfaEnabled,
    this.locale,
    this.mobile,
    this.notifications,
  });

  CAPreferences copyWith({
    String? newsletterOptIn,
    bool? fakeSubscription,
    bool? mfaEnabled,
    CALocale? locale,
    CAMobile? mobile,
    CANotifications? notifications,
  }) {
    return CAPreferences(
      newsletterOptIn: newsletterOptIn ?? this.newsletterOptIn,
      fakeSubscription: fakeSubscription ?? this.fakeSubscription,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      locale: locale ?? this.locale,
      mobile: mobile ?? this.mobile,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newsletterOptIn': newsletterOptIn,
      'fakeSubscription': fakeSubscription,
      'mfaEnabled': mfaEnabled,
      'locale': locale?.toJson(),
      'mobile': mobile?.toMap(),
      'notifications': notifications?.toJson(),
    }..removeWhere((key, value) => value == null);
  }

  factory CAPreferences.fromJson(Map<String, dynamic> json) {
    return CAPreferences(
      newsletterOptIn: json['newsletterOptIn'],
      fakeSubscription: json['fakeSubscription'],
      mfaEnabled: json['mfaEnabled'],
      locale: json['locale'] != null ? CALocale.fromJson(json['locale']) : null,
      mobile: json['mobile'] != null ? CAMobile.fromMap(json['mobile']) : null,
      notifications: json['notifications'] != null
          ? CANotifications.fromJson(json['notifications'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        newsletterOptIn,
        fakeSubscription,
        mfaEnabled,
        locale,
        mobile,
        notifications,
      ];
}
