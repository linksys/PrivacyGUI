// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linksys_app/constants/_constants.dart';

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        () => NotificationNotifier());

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    return const NotificationState(lastSeen: 0, notifications: []);
  }

  void load() {
    SharedPreferences.getInstance().then((prefs) {
      final sn = prefs.getString(pCurrentSN) ?? '';
      final key = _getKey(sn, pNotifications);
      final keyLastSeen = _getKey(sn, pNotificationLastSeen);
      final lastSeen = prefs.getInt(keyLastSeen) ?? 0;
      final notifications = prefs.getStringList(key) ?? [];
      final token = prefs.getString(pDeviceToken);
      state = state.copyWith(
        token: token,
        lastSeen: lastSeen,
        notifications:
            notifications.map((e) => NotificationItem.fromJson(e)).toList(),
      );
    });
  }

  void clear() {
    SharedPreferences.getInstance().then((prefs) {
      final sn = prefs.getString(pCurrentSN) ?? '';
      final key = _getKey(sn, pNotifications);
      if (prefs.containsKey(key)) {
        prefs.remove(key);
      }
      state = state.copyWith(hasNew: false, notifications: []);
    });
  }

  void onReceiveNotification(String? title, String? message, int? sentTime) {
    SharedPreferences.getInstance().then((prefs) {
      final data = {
        'title': title ?? '',
        'message': message ?? '',
        'sentTime': sentTime ?? DateTime.now().millisecondsSinceEpoch,
      };
      final sn = prefs.getString(pCurrentSN) ?? '';
      final key = _getKey(sn, pNotifications);
      final list = prefs.getStringList(key) ?? [];
      list.add(jsonEncode(data));
      prefs.setStringList(key, list);
      state = state.copyWith(
          hasNew: true,
          notifications:
              list.map((e) => NotificationItem.fromJson(e)).toList());
    });
  }

  void saveToken(String? token) {
    logger.d('[Notification][WEB] token - $token');
    SharedPreferences.getInstance().then((prefs) {
      if (token == null) {
        prefs.remove(pDeviceToken);
        state = state.removeToken();
      } else {
        prefs.setString(pDeviceToken, token);

        final master = ref.read(deviceManagerProvider).masterDevice;
        final cloud = ref.read(cloudRepositoryProvider);

        cloud
            .deviceRegistrations(
                serialNumber: master.unit.serialNumber ?? '',
                modelNumber: master.model.modelNumber ?? '',
                macAddress: master.getMacAddress())
            .then((deviceToken) {
          cloud.associateSmartDevice(
              linksysToken: deviceToken,
              serialNumber: master.unit.serialNumber ?? '',
              fcmToken: token);
        });

        state = state.copyWith(token: 'token');
      }
    });
  }

  String _getKey(String sn, String key) {
    return '$sn-$key';
  }
}

class NotificationState extends Equatable {
  final String? token;
  final int lastSeen;
  final bool hasNew;
  final List<NotificationItem> notifications;

  const NotificationState({
    this.token,
    required this.lastSeen,
    this.hasNew = false,
    required this.notifications,
  });

  NotificationState copyWith({
    String? token,
    int? lastSeen,
    bool? hasNew,
    List<NotificationItem>? notifications,
  }) {
    return NotificationState(
      token: token ?? this.token,
      lastSeen: lastSeen ?? this.lastSeen,
      hasNew: hasNew ?? this.hasNew,
      notifications: notifications ?? this.notifications,
    );
  }

  NotificationState removeToken() {
    return NotificationState(
        lastSeen: lastSeen, notifications: notifications, hasNew: hasNew);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lastSeen': lastSeen,
      'hasNew': hasNew,
      'notifications': notifications.map((x) => x.toMap()).toList(),
    };
  }

  factory NotificationState.fromMap(Map<String, dynamic> map) {
    return NotificationState(
      lastSeen: map['lastSeen'] as int,
      hasNew: map['hasNew'] as bool,
      notifications: List<NotificationItem>.from(
        (map['notifications'] as List<int>).map<NotificationItem>(
          (x) => NotificationItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationState.fromJson(String source) =>
      NotificationState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [lastSeen, hasNew, notifications];
}

class NotificationItem extends Equatable {
  final String title;
  final String? message;
  final int sentTime;
  const NotificationItem({
    required this.title,
    this.message,
    required this.sentTime,
  });

  NotificationItem copyWith({
    String? title,
    String? message,
    int? sentTime,
  }) {
    return NotificationItem(
      title: title ?? this.title,
      message: message ?? this.message,
      sentTime: sentTime ?? this.sentTime,
    );
  }

  @override
  List<Object?> get props => [title, message, sentTime];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'sentTime': sentTime,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      title: map['title'] as String,
      message: map['message'] != null ? map['message'] as String : null,
      sentTime: map['sentTime'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationItem.fromJson(String source) =>
      NotificationItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}