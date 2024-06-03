// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';

enum CallbackViewType {
  request(type: 'request'),
  callLog(type: 'callLog'),
  ;

  final String type;

  const CallbackViewType({required this.type});

  static CallbackViewType resolve(String type) {
    return switch (type) {
      'request' => CallbackViewType.request,
      'callLog' => CallbackViewType.callLog,
      _ => CallbackViewType.callLog,
    };
  }
}

class SupportState extends Equatable {
  final String linksysToken;
  final String? clientDeviceId;
  final List<Ticket> ticketList;
  final bool hasOpenTicket;
  final CallbackViewType callbackViewType;
  final bool justCreatedANewIssue;

  const SupportState({
    required this.linksysToken,
    this.clientDeviceId,
    this.ticketList = const [],
    this.hasOpenTicket = false,
    this.callbackViewType = CallbackViewType.callLog,
    this.justCreatedANewIssue = false,
  });

  factory SupportState.init() {
    return const SupportState(
      linksysToken: '',
    );
  }

  SupportState copyWith({
    String? linksysToken,
    String? clientDeviceId,
    List<Ticket>? ticketList,
    bool? hasOpenTicket,
    CallbackViewType? callbackViewType,
    bool? justCreatedANewIssue,
  }) {
    return SupportState(
      linksysToken: linksysToken ?? this.linksysToken,
      clientDeviceId: clientDeviceId ?? this.clientDeviceId,
      ticketList: ticketList ?? this.ticketList,
      hasOpenTicket: hasOpenTicket ?? this.hasOpenTicket,
      callbackViewType: callbackViewType ?? this.callbackViewType,
      justCreatedANewIssue: justCreatedANewIssue ?? this.justCreatedANewIssue,
    );
  }

  @override
  List<Object?> get props {
    return [
      linksysToken,
      clientDeviceId,
      ticketList,
      hasOpenTicket,
      callbackViewType,
      justCreatedANewIssue,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'linksysToken': linksysToken,
      'clientDeviceId': clientDeviceId,
      'ticketList': ticketList.map((e) => e.toMap()).toList(),
      'hasOpenTicket': hasOpenTicket,
      'callbackViewType': callbackViewType.type,
      'justCreatedANewIssue': justCreatedANewIssue,
    };
  }

  factory SupportState.fromMap(Map<String, dynamic> map) {
    return SupportState(
      linksysToken: map['linksysToken'] as String,
      clientDeviceId: map['clientDeviceId'] != null
          ? map['clientDeviceId'] as String
          : null,
      ticketList: (map['ticketList'] as List<Map<String, dynamic>>)
          .map((e) => Ticket.fromMap(e))
          .toList(),
      hasOpenTicket: map['hasOpenTicket'] as bool,
      callbackViewType: CallbackViewType.resolve(map['callbackViewType']),
      justCreatedANewIssue: map['justCreatedANewIssue'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory SupportState.fromJson(String source) =>
      SupportState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class Ticket extends Equatable {
  final String ticketId;
  final String description;
  final String salesforceCaseNumber;
  final String status;
  final String trackingUrl;
  final String createdAt;
  final String modifiedAt;

  const Ticket({
    required this.ticketId,
    required this.description,
    required this.salesforceCaseNumber,
    required this.status,
    required this.trackingUrl,
    required this.createdAt,
    required this.modifiedAt,
  });

  Ticket copyWith({
    String? ticketId,
    String? description,
    String? salesforceCaseNumber,
    String? status,
    String? trackingUrl,
    String? createdAt,
    String? modifiedAt,
  }) {
    return Ticket(
      ticketId: ticketId ?? this.ticketId,
      description: description ?? this.description,
      salesforceCaseNumber: salesforceCaseNumber ?? this.salesforceCaseNumber,
      status: status ?? this.status,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ticketId': ticketId,
      'description': description,
      'salesforceCaseNumber': salesforceCaseNumber,
      'status': status,
      'trackingUrl': trackingUrl,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      ticketId: map['ticketId'] as String,
      description: map['description'] as String,
      salesforceCaseNumber: map['salesforceCaseNumber'] as String,
      status: map['status'] as String,
      trackingUrl: map['trackingUrl'] as String,
      createdAt: map['createdAt'] as String,
      modifiedAt: map['modifiedAt'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ticket.fromJson(String source) => Ticket.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      ticketId,
      description,
      salesforceCaseNumber,
      status,
      trackingUrl,
      createdAt,
      modifiedAt,
    ];
  }
}
