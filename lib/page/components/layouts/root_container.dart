// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/firebase/notification_helper.dart';
import 'package:linksys_app/firebase/notification_provider.dart';
import 'package:linksys_app/page/components/layouts/idle_checker.dart';
import 'package:linksys_app/providers/root/root_config.dart';
import 'package:linksys_app/providers/root/root_provider.dart';
import 'package:linksys_widgets/theme/material/color_schemes_ext.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/banner/banner_view.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/customs/debug_overlay_view.dart';
import 'package:linksys_app/page/components/customs/no_network_bottom_modal.dart';
import 'package:linksys_app/page/components/layouts/mobile_layout.dart';
import 'package:linksys_app/page/components/styled/banner_provider.dart';
import 'package:linksys_app/providers/app_settings/app_settings_provider.dart';
import 'package:linksys_app/providers/connectivity/connectivity_provider.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/widgets/fab/expandable_fab.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';

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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildFab(),
                ),
                // !TODO need to revisit
                if (_showLocaleList) _localeList()
              ],
            ),
          ),
        ),
      );
    }));
  }

  Widget _buildFab() {
    return ExpandableFab(
      icon: Symbols.settings,
      distance: 64,
      children: [
        _buildThemeSettings(),
        _buildLocaleSetting(),
      ],
    );
  }

  Widget _buildThemeSettings() {
    return ActionButton(
      icon: Icon(ref.read(appSettingsProvider).themeMode == ThemeMode.system
          ? Symbols.auto_awesome
          : ref.read(appSettingsProvider).themeMode == ThemeMode.dark
              ? Symbols.dark_mode
              : Symbols.light_mode),
      onPressed: () {
        final appSettings = ref.read(appSettingsProvider);
        final nextThemeMode = appSettings.themeMode == ThemeMode.system
            ? ThemeMode.dark
            : appSettings.themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.system;
        ref.read(appSettingsProvider.notifier).state =
            appSettings.copyWith(themeMode: nextThemeMode);
      },
    );
  }

  Widget _buildLocaleSetting() {
    return ActionButton(
      icon: const Icon(Symbols.translate),
      onPressed: () async {
        setState(() {
          _showLocaleList = true;
        });
      },
    );
  }

  // NEED TO revisit
  Widget _localeList() {
    const localeList = AppLocalizations.supportedLocales;
    saveLocale(Locale locale) {
      final appSettings = ref.read(appSettingsProvider);

      ref.read(appSettingsProvider.notifier).state =
          appSettings.copyWith(locale: locale);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        child: ListView.builder(
            itemCount: localeList.length,
            itemBuilder: (context, index) {
              final locale = localeList[index];
              return ListTile(
                hoverColor:
                    Theme.of(context).colorScheme.background.withOpacity(.5),
                title: AppText.labelLarge(locale.toString()),
                onTap: () {
                  saveLocale(locale);
                  setState(() {
                    _showLocaleList = false;
                  });
                },
              );
            }),
      ),
    );
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
