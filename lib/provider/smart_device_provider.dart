import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/cloud/model/cloud_account.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_action.dart';
import 'package:linksys_app/core/cloud/model/cloud_event_subscription.dart';
import 'package:linksys_app/notification/notification_receiver.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinksysSmartDevice extends Equatable {
  final String? deviceToken;
  final String? id;
  final String? secret;
  final bool isVerified;

  const LinksysSmartDevice({
    this.deviceToken,
    this.id,
    this.secret,
    this.isVerified = false,
  });

  LinksysSmartDevice copyWith({
    String? deviceToken,
    String? id,
    String? secret,
    bool? isVerified,
  }) {
    return LinksysSmartDevice(
      deviceToken: deviceToken ?? this.deviceToken,
      id: id ?? this.id,
      secret: secret ?? this.secret,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceToken': deviceToken,
      'id': id,
      'secret': secret,
      'isVerified': isVerified,
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
      ];
}

final smartDeviceProvider =
    NotifierProvider<SmartDeviceNotifier, LinksysSmartDevice>(
        () => SmartDeviceNotifier());

class SmartDeviceNotifier extends Notifier<LinksysSmartDevice> {
  @override
  LinksysSmartDevice build() => const LinksysSmartDevice();

  init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(pSmartDeviceId);
    final secret = prefs.getString(pSmartDeviceSecret);
    final isVerified = prefs.getBool(pSmartDeviceVerified) ?? false;
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
          prefs.setString(pSmartDeviceId, id);
        }
        if (secret != null) {
          prefs.setString(pSmartDeviceSecret, secret);
        }
      });
      state = state.copyWith(id: id, secret: secret);
    });
  }

  Future verifySmartDevice(String verificationToken) {
    final cloud = ref.read(cloudRepositoryProvider);
    return cloud.verifySmartDevice(verificationToken).then((isVerified) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(pSmartDeviceVerified, isVerified);
      });
      state = state.copyWith(isVerified: isVerified);
    });
  }

  Future startVerifyAndCreateEventFlow(String verificationToken) async {
    await verifySmartDevice(verificationToken);
    await updateNotificationPreferences();
    final defaultSubscriptionEvents = [CloudEventType.deviceLeftNetwork];
    final subscriptions = await queryNetworkEventSubscriptions();
    for (var event in defaultSubscriptionEvents) {
      final eventSubscriptionId = subscriptions
              .firstWhereOrNull((element) => element.eventType == event)
              ?.eventSubscriptionId ??
          await createNetworkEventSubscription(
        
              CloudEventType.deviceLeftNetwork);
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
        .then((value) => (value.getString(prefSelectedNetworkId)) ?? '')
        .then((networkId) => cloud.queryNetworkEventSubscriptions(networkId));
  }

  Future<String> createNetworkEventSubscription(
      CloudEventType type) {
    final cloud = ref.read(cloudRepositoryProvider);
    return SharedPreferences.getInstance()
        .then((value) => (value.getString(prefSelectedNetworkId)) ?? '')
        .then((networkId) => cloud.createNetworkEventSubscription(networkId,
            CloudEventSubscription.create(eventType: type)));
  }

  Future<bool> createNetworkEventAction(String eventSubscriptionId) {
    final cloud = ref.read(cloudRepositoryProvider);
    final smartDeviceId = state.id;
    final format = DateFormat('yyyy-MM-ddThh:mm:ssZ');
    final startAt = DateTime.now();
    final endAt = startAt.copyWith(year: startAt.year + 10);
    final cloudEventAction = CloudEventAction(
        actionType: 'NOTIFICATION',
        startAt: format.format(startAt),
        endAt: format.format(endAt),
        timestoTrigger: '1',
        triggerInterval: '12',
        payload: '{"type": "PUSH","value": "$smartDeviceId"}');
    return cloud.createNetworkEventAction(
        eventSubscriptionId, cloudEventAction);
  }
}
