// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class GetTicketsResponse extends Equatable {
  final GetTicketsInfo info;
  final List<CloudTicket> data;

  const GetTicketsResponse({
    required this.info,
    required this.data,
  });

  GetTicketsResponse copyWith({
    GetTicketsInfo? info,
    List<CloudTicket>? data,
  }) {
    return GetTicketsResponse(
      info: info ?? this.info,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'info': info.toMap(),
      'data': data.map((x) => x.toMap()).toList(),
    };
  }

  factory GetTicketsResponse.fromMap(Map<String, dynamic> map) {
    return GetTicketsResponse(
      info: GetTicketsInfo.fromMap(map['info'] as Map<String, dynamic>),
      data: List<CloudTicket>.from(
        map['data'].map<CloudTicket>(
          (x) => CloudTicket.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GetTicketsResponse.fromJson(String source) =>
      GetTicketsResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [info, data];
}

class GetTicketsInfo extends Equatable {
  final int totalElements;
  final int pageSize;
  final List<LastEvaluatedKey> lastEvaluatedKeys;

  const GetTicketsInfo({
    required this.totalElements,
    required this.pageSize,
    required this.lastEvaluatedKeys,
  });

  GetTicketsInfo copyWith({
    int? totalElements,
    int? pageSize,
    List<LastEvaluatedKey>? lastEvaluatedKeys,
  }) {
    return GetTicketsInfo(
      totalElements: totalElements ?? this.totalElements,
      pageSize: pageSize ?? this.pageSize,
      lastEvaluatedKeys: lastEvaluatedKeys ?? this.lastEvaluatedKeys,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalElements': totalElements,
      'pageSize': pageSize,
      'lastEvaluatedKeys': lastEvaluatedKeys.map((x) => x.toMap()).toList(),
    };
  }

  factory GetTicketsInfo.fromMap(Map<String, dynamic> map) {
    return GetTicketsInfo(
      totalElements: map['totalElements'] as int,
      pageSize: map['pageSize'] as int,
      lastEvaluatedKeys: List<LastEvaluatedKey>.from(
        map['lastEvaluatedKeys'].map<LastEvaluatedKey>(
          (x) => LastEvaluatedKey.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GetTicketsInfo.fromJson(String source) =>
      GetTicketsInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [totalElements, pageSize, lastEvaluatedKeys];
}

class LastEvaluatedKey extends Equatable {
  final String key;
  final String value;

  const LastEvaluatedKey({
    required this.key,
    required this.value,
  });

  LastEvaluatedKey copyWith({
    String? key,
    String? value,
  }) {
    return LastEvaluatedKey(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'key': key,
      'value': value,
    };
  }

  factory LastEvaluatedKey.fromMap(Map<String, dynamic> map) {
    return LastEvaluatedKey(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory LastEvaluatedKey.fromJson(String source) =>
      LastEvaluatedKey.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [key, value];
}

class CloudTicket extends Equatable {
  final String ticketId;
  final String networkId;
  final String description;
  final String phoneRegionCode;
  final String phoneNumber;
  final String salesforceCaseNumber;
  final String status;
  final bool rmaEnabled;
  final String trackingUrl;
  final String createdAt;
  final String modifiedAt;
  final String emailAddress;
  final String firstName;
  final String lastName;

  const CloudTicket({
    required this.ticketId,
    required this.networkId,
    required this.description,
    required this.phoneRegionCode,
    required this.phoneNumber,
    required this.salesforceCaseNumber,
    required this.status,
    required this.rmaEnabled,
    required this.trackingUrl,
    required this.createdAt,
    required this.modifiedAt,
    required this.emailAddress,
    required this.firstName,
    required this.lastName,
  });

  CloudTicket copyWith({
    String? ticketId,
    String? networkId,
    String? description,
    String? phoneRegionCode,
    String? phoneNumber,
    String? salesforceCaseNumber,
    String? status,
    bool? rmaEnabled,
    String? trackingUrl,
    String? createdAt,
    String? modifiedAt,
    String? emailAddress,
    String? firstName,
    String? lastName,
  }) {
    return CloudTicket(
      ticketId: ticketId ?? this.ticketId,
      networkId: networkId ?? this.networkId,
      description: description ?? this.description,
      phoneRegionCode: phoneRegionCode ?? this.phoneRegionCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      salesforceCaseNumber: salesforceCaseNumber ?? this.salesforceCaseNumber,
      status: status ?? this.status,
      rmaEnabled: rmaEnabled ?? this.rmaEnabled,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      emailAddress: emailAddress ?? this.emailAddress,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ticketId': ticketId,
      'networkId': networkId,
      'description': description,
      'phoneRegionCode': phoneRegionCode,
      'phoneNumber': phoneNumber,
      'salesforceCaseNumber': salesforceCaseNumber,
      'status': status,
      'rmaEnabled': rmaEnabled,
      'trackingUrl': trackingUrl,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
      'emailAddress': emailAddress,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  factory CloudTicket.fromMap(Map<String, dynamic> map) {
    return CloudTicket(
      ticketId: map['ticketId'] as String,
      networkId: map['networkId'] as String,
      description: map['description'] as String,
      phoneRegionCode: map['phoneRegionCode'] as String,
      phoneNumber: map['phoneNumber'] as String,
      salesforceCaseNumber: map['salesforceCaseNumber'] as String,
      status: map['status'] as String,
      rmaEnabled: map['rmaEnabled'] as bool,
      trackingUrl: map['trackingUrl'] as String,
      createdAt: map['createdAt'] as String,
      modifiedAt: map['modifiedAt'] as String,
      emailAddress: map['emailAddress'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudTicket.fromJson(String source) =>
      CloudTicket.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      ticketId,
      networkId,
      description,
      phoneRegionCode,
      phoneNumber,
      salesforceCaseNumber,
      status,
      rmaEnabled,
      trackingUrl,
      createdAt,
      modifiedAt,
      emailAddress,
      firstName,
      lastName,
    ];
  }
}
