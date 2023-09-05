// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/util/smart_device_prefs_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_action.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_subscription.dart';
import 'package:linksys_app/notification/notification_receiver.dart';

const defaultSubscriptionEvents = CloudEventType.values;

class NetworkEventSubscrition extends Equatable {
  final String subscriptionId;
  final CloudEventAction? eventAction;
  final CloudEventType type;
  const NetworkEventSubscrition({
    required this.subscriptionId,
    required this.eventAction,
    required this.type,
  });

  NetworkEventSubscrition copyWith({
    String? subscriptionId,
    CloudEventAction? eventAction,
    CloudEventType? type,
  }) {
    return NetworkEventSubscrition(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      eventAction: eventAction ?? this.eventAction,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subscriptionId': subscriptionId,
      'eventAction': eventAction?.toMap(),
      'type': type.value,
    };
  }

  factory NetworkEventSubscrition.fromMap(Map<String, dynamic> map) {
    return NetworkEventSubscrition(
      subscriptionId: map['subscriptionId'] as String,
      eventAction:
          CloudEventAction.fromMap(map['eventAction'] as Map<String, dynamic>),
      type: CloudEventType.values
          .firstWhere((element) => element.value == map['type']),
    );
  }

  String toJson() => json.encode(toMap());

  factory NetworkEventSubscrition.fromJson(String source) =>
      NetworkEventSubscrition.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        subscriptionId,
        eventAction,
        type,
      ];
}

class LinksysSmartDevice extends Equatable {
  final String? deviceToken;
  final String? id;
  final String? secret;
  final bool isVerified;
  final List<NetworkEventSubscrition> subscriptions;

  const LinksysSmartDevice({
    this.deviceToken,
    this.id,
    this.secret,
    this.isVerified = false,
    this.subscriptions = const [],
  });

  LinksysSmartDevice copyWith({
    String? deviceToken,
    String? id,
    String? secret,
    bool? isVerified,
    List<NetworkEventSubscrition>? subscriptions,
  }) {
    return LinksysSmartDevice(
      deviceToken: deviceToken ?? this.deviceToken,
      id: id ?? this.id,
      secret: secret ?? this.secret,
      isVerified: isVerified ?? this.isVerified,
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceToken': deviceToken,
      'id': id,
      'secret': secret,
      'isVerified': isVerified,
      'subscriptions': subscriptions.map((e) => e.toMap()).toList(),
    };
  }

  factory LinksysSmartDevice.fromMap(Map<String, dynamic> map) {
    return LinksysSmartDevice(
      deviceToken:
          map['deviceToken'] != null ? map['deviceToken'] as String : null,
      id: map['id'] != null ? map['id'] as String : null,
      secret: map['secret'] != null ? map['secret'] as String : null,
      isVerified: map['isVerified'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory LinksysSmartDevice.fromJson(String source) =>
      LinksysSmartDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        id,
        secret,
        deviceToken,
        isVerified,
        subscriptions,
      ];
}

final smartDeviceProvider =
    NotifierProvider<SmartDeviceNotifier, LinksysSmartDevice>(
        () => SmartDeviceNotifier());

class SmartDeviceNotifier extends Notifier<LinksysSmartDevice> {
  @override
  LinksysSmartDevice build() => const LinksysSmartDevice();

  init() async {
    if (state.deviceToken != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(
        SmartDevicesPrefsHelper.getNidKey(prefs, key: pSmartDeviceId));
    final secret = prefs.getString(
        SmartDevicesPrefsHelper.getNidKey(prefs, key: pSmartDeviceSecret));
    final isVerified = prefs.getBool(SmartDevicesPrefsHelper.getNidKey(prefs,
            key: pSmartDeviceVerified)) ??
        false;
    final deviceToken = prefs.getString(pDeviceToken);
    state = LinksysSmartDevice(
      deviceToken: deviceToken,
      id: id,
      secret: secret,
      isVerified: isVerified,
    );
  }

  Future registerSmartDevice(String deviceToken) async {
    final cloud = ref.read(cloudRepositoryProvider);
    final packageInfo = await PackageInfo.fromPlatform();
    final appType = Platform.isIOS
        ? (packageInfo.packageName.endsWith('ee')
            ? 'ENTERPRISE'
            : 'DISTRIBUTION')
        : null;
    onSmartDeviceVerification = (token) {
      startVerifyAndCreateEventFlow(token);
    };
    cloud.registerSmartDevice(deviceToken, appType: appType).then((response) {
      final id = response.$1;
      final secret = response.$2;
      SharedPreferences.getInstance().then((prefs) {
        if (id != null) {
          prefs.setString(
              SmartDevicesPrefsHelper.getNidKey(prefs, key: pSmartDeviceId),
              id);
        }
        if (secret != null) {
          prefs.setString(
              SmartDevicesPrefsHelper.getNidKey(prefs, key: pSmartDeviceSecret),
              secret);
        }
      });
      state = state.copyWith(id: id, secret: secret);
    });
  }

  void fetchEventSubscriptions() async {
    final subscriptions = await queryNetworkEventSubscriptions();
    state = state.copyWith(subscriptions: []);
    for (var event in defaultSubscriptionEvents) {
      // Check subscriptions
      final eventSubscriptionId = subscriptions
              .firstWhereOrNull((element) => element.eventType == event)
              ?.eventSubscriptionId ??
          await createNetworkEventSubscription(
              CloudEventType.deviceLeftNetwork);

      final eventAction = await queryNetworkEventAction(eventSubscriptionId);
      state = state.copyWith(subscriptions: [
        ...state.subscriptions,
        NetworkEventSubscrition(
            subscriptionId: eventSubscriptionId,
            eventAction: eventAction,
            type: event)
      ]);
    }
  }

  Future verifySmartDevice(String verificationToken) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.verifySmartDevice(verificationToken).then((isVerified) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(
            SmartDevicesPrefsHelper.getNidKey(prefs, key: pSmartDeviceVerified),
            isVerified);
      });
      state = state.copyWith(isVerified: isVerified);
    });
  }

  Future startVerifyAndCreateEventFlow(String verificationToken) async {
    await verifySmartDevice(verificationToken);
    await updateNotificationPreferences();
    final subscriptions = await queryNetworkEventSubscriptions();
    for (var event in defaultSubscriptionEvents) {
      final eventSubscriptionId = subscriptions
              .firstWhereOrNull((element) => element.eventType == event)
              ?.eventSubscriptionId ??
          await createNetworkEventSubscription(
              CloudEventType.deviceLeftNetwork);

      await queryNetworkEventAction(eventSubscriptionId).then((value) {
            if (value != null) {
              state = state.copyWith(subscriptions: [
                ...state.subscriptions,
                NetworkEventSubscrition(
                    subscriptionId: eventSubscriptionId,
                    eventAction: value,
                    type: event)
              ]);
            }
          }) ??
          await createNetworkEventAction(eventSubscriptionId);
    }
  }

  Future updateNotificationPreferences() {
    final cloud = ref.read(cloudRepositoryProvider);
    final smartDeviceId = state.id;

    return cloud.getPreferences().then((preferences) {
      final notifications =
          preferences.notifications ?? const CANotifications();
      final updated = notifications.copyWith(notifications: [
        ...notifications.notifications,
        CANotification(type: 'PUSH', value: smartDeviceId),
      ]);
      cloud.setPreferences(CAPreferences(notifications: updated));
    });
  }

  Future<List<CloudEventSubscription>> queryNetworkEventSubscriptions() {
    final cloud = ref.read(cloudRepositoryProvider);
    return SharedPreferences.getInstance()
        .then((value) => (value.getString(pSelectedNetworkId)) ?? '')
        .then((networkId) => cloud.queryNetworkEventSubscriptions(networkId));
  }

  Future<String> createNetworkEventSubscription(CloudEventType type) {
    final cloud = ref.read(cloudRepositoryProvider);
    return SharedPreferences.getInstance()
        .then((value) => (value.getString(pSelectedNetworkId)) ?? '')
        .then((networkId) => cloud.createNetworkEventSubscription(
            networkId, CloudEventSubscription.create(eventType: type)));
  }

  Future<CloudEventAction?> createNetworkEventAction(
      String eventSubscriptionId) {
    final cloud = ref.read(cloudRepositoryProvider);
    final smartDeviceId = state.id;
    final format = DateFormat('yyyy-MM-ddThh:mm:ssZ');
    final startAt = DateTime.now();
    final endAt = startAt.copyWith(year: startAt.year + 10);
    final cloudEventAction = CloudEventAction(
        actionType: 'NOTIFICATION',
        startAt: format.format(startAt),
        endAt: format.format(endAt),
        timestoTrigger: 1,
        triggerInterval: 12,
        payload: '{"type": "PUSH","value": "$smartDeviceId"}');
    return cloud
        .createNetworkEventAction(eventSubscriptionId, cloudEventAction)
        .then((value) => value ? cloudEventAction : null)
        .then((value) {
      if (value != null) {
        final updatedEventSubscription = state.subscriptions.map((e) {
          if (e.subscriptionId == eventSubscriptionId) {
            return e.copyWith(eventAction: value);
          }
          return e;
        }).toList();
        state = state.copyWith(subscriptions: updatedEventSubscription);
      }
      return value;
    });
  }

  Future<CloudEventAction?> queryNetworkEventAction(
      String eventSubscriptionId) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud
        .getNetworkEventAction(eventSubscriptionId)
        .then((value) => value.isEmpty ? null : value[0]);
  }

  Future<bool> deleteNetworkEventAction(String eventSubscriptionId) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.deleteNetworkEventAction(eventSubscriptionId).then(
      (value) {
        if (value) {
          final updatedSubscription = state.subscriptions.map((e) {
            if (e.subscriptionId == eventSubscriptionId) {
              return NetworkEventSubscrition(
                  subscriptionId: e.subscriptionId,
                  eventAction: null,
                  type: e.type);
            }
            return e;
          }).toList();
          state = state.copyWith(subscriptions: updatedSubscription);
        }
        logger.d(state);
        return value;
      },
    );
  }
}
