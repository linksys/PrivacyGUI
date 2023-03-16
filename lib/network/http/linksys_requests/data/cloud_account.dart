import 'package:equatable/equatable.dart';

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
    return {
      'notifications': notifications,
    };
  }

  factory CANotifications.fromJson(Map<String, dynamic> json) {
    return CANotifications(
      notifications: List.from(json['notifications']),
    );
  }

  @override
  List<Object> get props => [notifications];
}

class CAMobile extends Equatable {
  final String? countryCode;
  final String? phoneNumber;

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

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
    };
  }

  factory CAMobile.fromJson(Map<String, dynamic> json) {
    return CAMobile(
      countryCode: json['countryCode'],
      phoneNumber: json['phoneNumber'],
    );
  }

  @override
  List<Object?> get props => [countryCode, phoneNumber];
}

class CALocal extends Equatable {
  final String? language;
  final String? country;

  const CALocal({
    this.language,
    this.country,
  });

  CALocal copyWith({
    String? language,
    String? country,
  }) {
    return CALocal(
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

  factory CALocal.fromJson(Map<String, dynamic> json) {
    return CALocal(
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
  final CALocal? locale;
  final CAMobile? mobile;
  final CANotifications? notifications;

  const CAPreferences({
    this.locale,
    this.mobile,
    this.notifications,
  });

  CAPreferences copyWith({
    CALocal? locale,
    CAMobile? mobile,
    CANotifications? notifications,
  }) {
    return CAPreferences(
      locale: locale ?? this.locale,
      mobile: mobile ?? this.mobile,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale?.toJson(),
      'mobile': mobile?.toJson(),
      'notifications': notifications?.toJson(),
    }..removeWhere((key, value) => value == null);
  }

  factory CAPreferences.fromJson(Map<String, dynamic> json) {
    return CAPreferences(
      locale: json['locale'],
      mobile: json['mobile'],
      notifications: json['notifications'],
    );
  }

  @override
  List<Object?> get props => [locale];
}
