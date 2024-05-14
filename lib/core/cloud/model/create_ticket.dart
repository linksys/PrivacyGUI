import 'package:equatable/equatable.dart';

class CreateTicketInput extends Equatable {
  final String emailAddress;
  final String firstName;
  final String lastName;
  final String phoneRegionCode;
  final String phoneNumber;
  final String description;

  const CreateTicketInput({
    required this.emailAddress,
    required this.firstName,
    required this.lastName,
    required this.phoneRegionCode,
    required this.phoneNumber,
    required this.description,
  });

  CreateTicketInput copyWith({
    String? emailAddress,
    String? firstName,
    String? lastName,
    String? phoneRegionCode,
    String? phoneNumber,
    String? description,
  }) {
    return CreateTicketInput(
      emailAddress: emailAddress ?? this.emailAddress,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneRegionCode: phoneRegionCode ?? this.phoneRegionCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'emailAddress': emailAddress,
      'firstName': firstName,
      'lastName': lastName,
      'phoneRegionCode': phoneRegionCode,
      'phoneNumber': phoneNumber,
      'description': description,
    };
  }

  factory CreateTicketInput.fromJson(Map<String, dynamic> json) {
    return CreateTicketInput(
      emailAddress: json['emailAddress'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneRegionCode: json['phoneRegionCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
      description: json['description'] as String,
    );
  }

  @override
  List<Object?> get props {
    return [
      emailAddress,
      firstName,
      lastName,
      phoneRegionCode,
      phoneNumber,
      description,
    ];
  }
}
