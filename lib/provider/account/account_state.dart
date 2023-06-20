// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/core/cloud/model/cloud_account.dart';

import 'package:linksys_moab/core/cloud/model/cloud_communication_method.dart';

class AccountState extends Equatable {
  final String id;
  final String username;
  final String password;
  final String status;
  final CAMobile? mobile;
  final bool mfaEnabled;
  final bool newsletterOptIn;
  final List<CommunicationMethod> methods;

  const AccountState({
    required this.id,
    required this.username,
    required this.password,
    required this.status,
    this.mobile,
    required this.mfaEnabled,
    required this.newsletterOptIn,
    required this.methods,
  });

  @override
  List<Object?> get props {
    return [
      id,
      username,
      password,
      status,
      mobile,
      mfaEnabled,
      newsletterOptIn,
      methods,
    ];
  }

  AccountState copyWith({
    String? id,
    String? username,
    String? password,
    String? status,
    CAMobile? mobile,
    bool? mfaEnabled,
    bool? newsletterOptIn,
    List<CommunicationMethod>? methods,
  }) {
    return AccountState(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      mobile: mobile ?? this.mobile,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      newsletterOptIn: newsletterOptIn ?? this.newsletterOptIn,
      methods: methods ?? this.methods,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'status': status,
      'mobile': mobile?.toJson(),
      'mfaEnabled': mfaEnabled,
      'newsletterOptIn': newsletterOptIn,
      'methods': methods.map((method) => method.toJson()).toList(),
    };
  }

  factory AccountState.fromJson(Map<String, dynamic> json) {
    return AccountState(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      status: json['status'],
      mobile: json['mobile'] != null ? CAMobile.fromJson(json['mobile']) : null,
      mfaEnabled: json['mfaEnabled'],
      newsletterOptIn: json['newsletterOptIn'],
      methods: (json['methods'] as List<dynamic>)
          .map((method) => CommunicationMethod.fromJson(method))
          .toList(),
    );
  }

  factory AccountState.empty() => const AccountState(
        id: '',
        username: '',
        password: '',
        status: '',
        mfaEnabled: false,
        newsletterOptIn: false,
        methods: [],
      );

  factory AccountState.fromCloudAccount(CAUserAccount userAccount) {
    return AccountState(
        id: userAccount.accountId,
        username: userAccount.username,
        password: '',
        status: userAccount.status,
        mfaEnabled: userAccount.preferences?.mfaEnabled ?? false,
        newsletterOptIn: userAccount.preferences?.newsletterOptIn == 'true',
        mobile: userAccount.preferences?.mobile,
        methods: const []);
  }
}
