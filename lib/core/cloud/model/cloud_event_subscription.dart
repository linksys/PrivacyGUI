// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum CloudEventType {
  deviceLeftNetwork('Device Left Network Notification', 'DEVICE_LEFT_NETWORK'),
  jnapReboot('Reboot Notification', 'JNAP_REBOOT'),
  linksysPrecursor('Precursor Notification', 'LINKSYS_PRECURSOR'),
  routerOffline('Router Offline Notification', 'ROUTER_OFFLINE'),
  ;

  final String name;
  final String value;
  const CloudEventType(this.name, this.value);
}

class CloudEventSubscription extends Equatable {
  final String? eventSubscriptionId;
  final String name;
  final CloudEventType eventType;
  final List<(String, String)> timeFilters;

  const CloudEventSubscription({
    this.eventSubscriptionId,
    required this.name,
    required this.eventType,
    required this.timeFilters,
  });

  factory CloudEventSubscription.create({required CloudEventType eventType}) {
    final format = DateFormat('yyyy-MM-ddThh:mm:ssZ');
    final startAt = DateTime.now();
    final endAt = startAt.copyWith(year: startAt.year + 10);
    return CloudEventSubscription(
      name: eventType.name,
      eventType: eventType,
      timeFilters: [
        (format.format(startAt), format.format(endAt)),
      ],
    );
  }

  CloudEventSubscription copyWith({
    String? eventSubscriptionId,
    String? name,
    CloudEventType? eventType,
    List<(String, String)>? timeFilters,
  }) {
    return CloudEventSubscription(
      eventSubscriptionId: eventSubscriptionId ?? this.eventSubscriptionId,
      name: name ?? this.name,
      eventType: eventType ?? this.eventType,
      timeFilters: timeFilters ?? this.timeFilters,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'eventSubscriptionId': eventSubscriptionId,
      'name': name,
      'eventType': eventType.value,
      'timeFilters': timeFilters
          .map(
            (timeFilter) => {
              'timeFilter': {
                'startAt': timeFilter.$1,
                'endAt': timeFilter.$2,
              },
            },
          )
          .toList(),
    }..removeWhere((key, value) => value == null);
  }

  factory CloudEventSubscription.fromMap(Map<String, dynamic> map) {
    return CloudEventSubscription(
      eventSubscriptionId: map['eventSubscriptionId'] as String?,
      name: map['name'] as String,
      eventType: CloudEventType.values
          .firstWhere((type) => type.value == map['eventType']),
      timeFilters: List<(String, String)>.from(
        (map['timeFilters'] as List)
            .map((e) => e['timeFilter'])
            .map((e) => (e['startAt'], e['endAt'])),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudEventSubscription.fromJson(String source) =>
      CloudEventSubscription.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        eventSubscriptionId,
        name,
        eventType,
        timeFilters,
      ];
}
