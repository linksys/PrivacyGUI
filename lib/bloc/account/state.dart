import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/model/cloud_account_info.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/network/http/model/cloud_preferences.dart';

class AccountState extends Equatable {
  const AccountState({
    required this.id,
    required this.groupId,
    required this.username,
    required this.status,
    required this.type,
    required this.authMode,
    required this.pref,
    required this.communicationMethods,
    this.isBiometricEnabled = false,
  });

  factory AccountState.empty() {
    return AccountState(
      id: '',
      groupId: '',
      username: '',
      status: '',
      type: '',
      authMode: '',
      pref: AccountPreference.empty(),
      communicationMethods: const [],
    );
  }

  final String id;
  final String groupId;
  final String username;
  final String status;
  final String type;
  final String authMode;
  final AccountPreference pref;
  final List<CommunicationMethod> communicationMethods;
  final bool isBiometricEnabled;

  AccountState copyWith({
    String? id,
    String? groupId,
    String? username,
    String? status,
    String? type,
    String? authMode,
    AccountPreference? pref,
    List<CommunicationMethod>? communicationMethods,
    bool? isBiometricEnabled,
  }) {
    return AccountState(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      username: username ?? this.username,
      status: status ?? this.status,
      type: type ?? this.type,
      authMode: authMode ?? this.authMode,
      pref: pref ?? this.pref,
      communicationMethods: communicationMethods ?? this.communicationMethods,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }

  AccountState copyWithAccountInfo(
      {required CloudAccountInfo info, bool isBiometricEnabled = false}) {
    return AccountState(
      id: info.id,
      groupId: '',
      username: info.username,
      status: info.status,
      type: info.type,
      authMode: info.authenticationMode,
      pref: AccountPreference.fromCloud(info.preferences),
      communicationMethods: info.communicationMethods,
      isBiometricEnabled: isBiometricEnabled,
    );
  }

  AccountState copyWithCreateAccountVerified(
      {required CloudAccountVerifyInfo info, bool isBiometricEnabled = false}) {
    return AccountState(
      id: info.id,
      groupId: '',
      username: info.username,
      status: info.status,
      type: info.type,
      authMode: info.authenticationMode,
      pref: AccountPreference.empty(),
      communicationMethods: const [],
      isBiometricEnabled: isBiometricEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        username,
        status,
        type,
        authMode,
        pref,
        communicationMethods,
        isBiometricEnabled,
      ];
}

class AccountPreference extends Equatable {
  const AccountPreference({
    required this.isoLanguageCode,
    required this.isoCountryCode,
    required this.timeZone,
    this.marketingOptIn = false,
  });

  factory AccountPreference.empty() {
    return const AccountPreference(
      isoLanguageCode: '',
      isoCountryCode: '',
      timeZone: '',
    );
  }

  factory AccountPreference.fromCloud(CloudPreferences pref) {
    return AccountPreference(
        isoLanguageCode: pref.isoLanguageCode,
        isoCountryCode: pref.isoCountryCode,
        timeZone: pref.timeZone);
  }

  final String isoLanguageCode;
  final String isoCountryCode;
  final String timeZone;
  final bool marketingOptIn;

  AccountPreference copyWith({
    String? isoLanguageCode,
    String? isoCountryCode,
    String? timeZone,
    bool? marketingOptIn,
  }) {
    return AccountPreference(
      isoLanguageCode: isoLanguageCode ?? this.isoLanguageCode,
      isoCountryCode: isoCountryCode ?? this.isoCountryCode,
      timeZone: timeZone ?? this.timeZone,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
    );
  }

  @override
  List<Object?> get props =>
      [isoLanguageCode, isoCountryCode, timeZone, marketingOptIn];
}
