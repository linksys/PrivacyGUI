import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/firebase/notification_helper.dart';
import 'package:privacy_gui/firebase/notification_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/buttons/popup_button.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class NotificationPopupWidget extends ConsumerStatefulWidget {
  const NotificationPopupWidget({super.key});

  @override
  ConsumerState<NotificationPopupWidget> createState() =>
      _NotificationPopupWidgetState();
}

class _NotificationPopupWidgetState
    extends ConsumerState<NotificationPopupWidget> {
  StreamSubscription? tokenSubscription;
  @override
  void initState() {
    super.initState();
    tokenSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      ref.read(notificationProvider.notifier).saveToken(token);
    });
  }

  @override
  void dispose() {
    super.dispose();
    tokenSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final hasNew =
        ref.watch(notificationProvider.select((value) => value.hasNew));
    return AppPopupButton(
        button: Badge(
          isLabelVisible: hasNew,
          child: const Icon(
            LinksysIcons.notifications,
            size: 20,
          ),
        ),
        builder: (controller) {
          final isEnabled = ref.watch(
              notificationProvider.select((value) => value.token != null));
          final notifications = ref.watch(
              notificationProvider.select((value) => value.notifications));
          return Container(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSwitchTriggerTile(
                  padding: const EdgeInsets.all(8.0),
                  value: isEnabled,
                  title: AppText.bodyLarge('Enable Push Notification'),
                  subtitle: AppText.bodySmall(
                    'Experiential',
                    color: Colors.grey,
                  ),
                  onChanged: (value) {},
                  event: (value) async {
                    if (value) {
                      await initCloudMessage((token) {
                        ref
                            .read(notificationProvider.notifier)
                            .saveToken(token);
                      });
                    } else {
                      await removeCloudMessage();
                      ref.read(notificationProvider.notifier).saveToken(null);
                    }
                    controller.markNeedBuilds();
                  },
                ),
                const Divider(
                  height: 1,
                ),
                ...[
                  ..._buildNotifications(notifications),
                  AppTextButton(
                    loc(context).clear,
                    onTap: () {
                      ref.read(notificationProvider.notifier).clear();
                      controller.close();
                    },
                  ),
                ]
              ],
            ),
          );
        });
  }

  List<Widget> _buildNotifications(List<NotificationItem> notifications) {
    final formatter = DateFormat();

    return [
      ...notifications
          .map((e) => ListTile(
                title: AppText.labelLarge(e.title),
                subtitle: AppText.labelSmall(e.message ?? ''),
                trailing: AppText.bodySmall(
                  formatter.format(
                    DateTime.fromMillisecondsSinceEpoch(e.sentTime),
                  ),
                ),
              ))
          .toList(),
    ];
  }
}
