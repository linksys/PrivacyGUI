import 'package:equatable/equatable.dart';

class NetworkAccountAssociation extends Equatable {
  final Network network;
  final String role;
  final bool owner;
  final bool defaultNetwork;

  const NetworkAccountAssociation({
    required this.network,
    required this.role,
    required this.owner,
    required this.defaultNetwork,
  });

  @override
  List<Object> get props => [network, role, owner, defaultNetwork];

  Map<String, dynamic> toJson() {
    return {
      'network': network.toJson(),
      'role': role,
      'owner': owner,
      'defaultNetwork': defaultNetwork,
    };
  }

  static NetworkAccountAssociation fromJson(Map<String, dynamic> json) {
    return NetworkAccountAssociation(
      network: Network.fromJson(json['network']),
      role: json['role'],
      owner: json['owner'],
      defaultNetwork: json['defaultNetwork'],
    );
  }
}

class Network extends Equatable {
  final String networkId;
  final String friendlyName;
  final NetworkOwner owner;
  final String routerModelNumber;
  final String routerHardwareVersion;
  final String routerSerialNumber;

  const Network({
    required this.networkId,
    required this.friendlyName,
    required this.owner,
    required this.routerModelNumber,
    required this.routerHardwareVersion,
    required this.routerSerialNumber,
  });

  @override
  List<Object> get props => [
        networkId,
        friendlyName,
        owner,
        routerModelNumber,
        routerHardwareVersion,
        routerSerialNumber
      ];

  Map<String, dynamic> toJson() {
    return {
      'networkId': networkId,
      'friendlyName': friendlyName,
      'owner': owner.toJson(),
      'routerModelNumber': routerModelNumber,
      'routerHardwareVersion': routerHardwareVersion,
      'routerSerialNumber': routerSerialNumber,
    };
  }

  static Network fromJson(Map<String, dynamic> json) {
    return Network(
      networkId: json['networkId'],
      friendlyName: json['friendlyName'],
      owner: NetworkOwner.fromJson(json['owner']),
      routerModelNumber: json['routerModelNumber'],
      routerHardwareVersion: json['routerHardwareVersion'],
      routerSerialNumber: json['routerSerialNumber'],
    );
  }
}

class NetworkOwner extends Equatable {
  final String accountId;
  final String username;
  final String firstName;
  final String lastName;
  final String alias;
  final String status;
  final DateTime? passwordLastUpdated;
  final DateTime? passwordComplexityLastChecked;
  final Preferences preferences;

  const NetworkOwner({
    required this.accountId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.alias,
    required this.status,
    required this.passwordLastUpdated,
    required this.passwordComplexityLastChecked,
    required this.preferences,
  });

  @override
  List<Object?> get props => [
        accountId,
        username,
        firstName,
        lastName,
        alias,
        status,
        passwordLastUpdated,
        passwordComplexityLastChecked,
        preferences,
      ];

  factory NetworkOwner.fromJson(Map<String, dynamic> json) {
    return NetworkOwner(
      accountId: json['accountId'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      alias: json['alias'],
      status: json['status'],
      passwordLastUpdated: json['passwordLastUpdated'] != null
          ? DateTime.parse(json['passwordLastUpdated'])
          : null,
      passwordComplexityLastChecked:
          json['passwordComplexityLastChecked'] != null
              ? DateTime.parse(json['passwordComplexityLastChecked'])
              : null,
      preferences: Preferences.fromJson(json['preferences']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'alias': alias,
      'status': status,
      'passwordLastUpdated': passwordLastUpdated?.toIso8601String(),
      'passwordComplexityLastChecked':
          passwordComplexityLastChecked?.toIso8601String(),
      'preferences': preferences.toJson(),
    };
  }
}

class Preferences extends Equatable {
  final Locale locale;
  final bool newsletterOptIn;
  final bool mfaEnabled;
  final Mobile? mobile;

  const Preferences({
    required this.locale,
    required this.newsletterOptIn,
    required this.mfaEnabled,
    required this.mobile,
  });

  @override
  List<Object?> get props => [locale, newsletterOptIn, mfaEnabled, mobile];

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      locale: Locale.fromJson(json['locale']),
      newsletterOptIn: json['newsletterOptIn'] == "true",
      mfaEnabled: json['mfaEnabled'],
      mobile: json['mobile'] != null ? Mobile.fromJson(json['mobile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale.toJson(),
      'newsletterOptIn': newsletterOptIn,
      'mfaEnabled': mfaEnabled,
      'mobile': mobile?.toJson(),
    };
  }
}

class Locale extends Equatable {
  final String language;
  final String country;

  const Locale({
    required this.language,
    required this.country,
  });

  @override
  List<Object?> get props => [language, country];

  factory Locale.fromJson(Map<String, dynamic> json) {
    return Locale(
      language: json['language'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'country': country,
    };
  }
}

class Mobile extends Equatable {
  final String countryCode;
  final String phoneNumber;

  const Mobile({
    required this.countryCode,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [countryCode, phoneNumber];

  static Mobile fromJson(Map<String, dynamic> json) {
    return Mobile(
      countryCode: json['countryCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
    };
  }
}
