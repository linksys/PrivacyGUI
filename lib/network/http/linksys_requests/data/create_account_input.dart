import 'package:equatable/equatable.dart';
import 'package:linksys_moab/network/http/linksys_requests/data/cloud_account.dart';

class CreateAccountInput extends Equatable {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final CAPreferences? preferences;

  const CreateAccountInput({
    required this.username,
    required this.password,
    this.firstName = '-',
    this.lastName = '-',
    this.preferences,
  });

  CreateAccountInput copyWith({
    String? username,
    String? password,
    String? firstName,
    String? lastName,
    CAPreferences? preferences,
  }) {
    return CreateAccountInput(
      username: username ?? this.username,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'preferences': preferences,
    };
  }

  factory CreateAccountInput.fromJson(Map<String, dynamic> json) {
    return CreateAccountInput(
      username: json['username'],
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      preferences: json['preferences'],
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        firstName,
        lastName,
        preferences,
      ];
}
