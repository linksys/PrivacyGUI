// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/firebase/notification_provider.dart';
import 'package:linksys_app/page/components/layouts/idle_checker.dart';
import 'package:linksys_app/providers/root/root_config.dart';
import 'package:linksys_app/providers/root/root_provider.dart';
import 'package:linksys_widgets/widgets/banner/banner_view.dart';

import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_app/page/components/customs/no_network_bottom_modal.dart';
import 'package:linksys_app/page/components/styled/banner_provider.dart';
import 'package:linksys_app/providers/connectivity/connectivity_provider.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class AppRootContainer extends ConsumerStatefulWidget {
  final Widget? child;
  final LinksysRouteConfig? routeConfig;
  const AppRootContainer({
    super.key,
    this.child,
    this.routeConfig,
  });

  @override
  ConsumerState<AppRootContainer> createState() => _AppRootContainerState();
}

class _AppRootContainerState extends ConsumerState<AppRootContainer> {
  final _link = LayerLink();

  bool _showLocaleList = false;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() => !mounted).then((value) => _registerNotification());
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Root Container:: build: ${widget.routeConfig}');
    final fwUpdate = ref.watch(firmwareUpdateProvider);
    final rootConfig = ref.watch(rootProvider);
    return LayoutBuilder(builder: ((context, constraints) {
      return IdleChecker(
        idleTime: const Duration(minutes: 5),
        onIdle: () {
          logger.d('Idled!');
        },
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: CompositedTransformTarget(
            link: _link,
            child: Stack(
              children: [
                _buildLayout(Container(child: widget.child ?? const Center()),
                    constraints),
                ..._handleConnectivity(ref),
                ..._handleBanner(ref),
                _handleSpinner(rootConfig),
                !showDebugPanel
                    ? const Center()
                    : CompositedTransformFollower(
                        link: _link,
                        targetAnchor: Alignment.topRight,
                        followerAnchor: Alignment.topRight,
                        child: IgnorePointer(
                          ignoring: true,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: MediaQueryUtils.getTopSafeAreaPadding(
                                    context)),
                            child: const OverlayInfoView(),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  Widget _handleSpinner(AppRootConfig config) {
    if (config.spinnerTag != null) {
      return AppFullScreenSpinner();
    } else {
      return Center();
    }
  }

  Widget _buildLayout(Widget child, BoxConstraints constraints) {
    return child;
  }

  List<Widget> _handleBanner(WidgetRef ref) {
    final bannerInfo = ref.watch(bannerProvider);
    if (bannerInfo.isDiaplay) {
      return [
        AppBanner(
          style: bannerInfo.style,
          text: bannerInfo.text,
        )
      ];
    } else {
      return [];
    }
  }

  List<Widget> _handleConnectivity(WidgetRef ref) {
    final ignoreConnectivity =
        (widget.routeConfig?.ignoreConnectivityEvent ?? false) || kIsWeb;
    final ignoreCloudOffline =
        (widget.routeConfig?.ignoreCloudOfflineEvent ?? false) || kIsWeb;
    if (!ignoreConnectivity) {
      final connectivity = ref.watch(connectivityProvider
          .select((value) => (value.hasInternet, value.connectivityInfo.type)));
      final hasInternet = connectivity.$1;
      final connectivityType = connectivity.$2;
      if (!hasInternet || connectivityType == ConnectivityResult.none) {
        logger.i('No internet access: $hasInternet, $connectivityType');
        return [const NoInternetConnectionModal()];
      }
    }
    if (!ignoreCloudOffline) {
      final cloudOffline = ref.watch(connectivityProvider
          .select((value) => value.cloudAvailabilityInfo?.isCloudOk ?? false));
      if (!cloudOffline) {
        logger.i('cloud unavailable: $cloudOffline');
        return [const NoInternetConnectionModal()];
      }
    }
    return [];
  }

  void _registerNotification() {
    ref.read(notificationProvider.notifier).load();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.d(
          '[Notification][WEB] Got a message whilst in the foreground! $message');
      logger.d('[Notification][WEB] Message data: ${message.data}');

      if (message.notification != null) {
        logger.d(
            '[Notification][WEB] Message also contained a notification: ${message.notification}');
        saveNotificationMessage(message);
      }
    });
  }

  void saveNotificationMessage(RemoteMessage message) {
    if (message.notification?.title == null &&
        message.notification?.body == null) {
      return;
    }
    ref.read(notificationProvider.notifier).onReceiveNotification(
        message.notification?.title,
        message.notification?.body,
        message.sentTime?.millisecondsSinceEpoch);
  }
}
