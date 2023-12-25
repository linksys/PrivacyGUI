import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/node_wan_status_provider.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/dashboard/dashboard_home_provider.dart';
import 'package:linksys_app/provider/dashboard/dashboard_home_state.dart';
import 'package:linksys_app/provider/devices/topology_provider.dart';
import 'package:linksys_app/provider/smart_device_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/smart_device_prefs_helper.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class DashboardHomeView extends ConsumerStatefulWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends ConsumerState<DashboardHomeView> {
  @override
  void initState() {
    super.initState();
    _pushNotificationCheck();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardHomeProvider);
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;
    return StyledAppPageView(
      scrollable: true,
      backState: StyledBackState.none,
      padding: const AppEdgeInsets.only(
        top: AppGapSize.big,
        left: AppGapSize.regular,
        right: AppGapSize.regular,
        bottom: AppGapSize.regular,
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _homeTitle(state.mainWifiSsid, wanStatus == NodeWANStatus.online,
                  isLoading, state.isFirstPolling),
              const AppGap.big(),
              _networkInfoTiles(state, isLoading),
              const AppGap.extraBig(),
              _speedTestTile(state, isLoading),
            ],
          ),
          // if (isLoading)
          //   const AppFullScreenSpinner(),
        ],
      ),
    );
  }

  Widget _homeTitle(
      String ssid, bool isOnline, bool isLoading, bool isFirstPolling) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        _ssid(ssid, isLoading),
        const AppGap.regular(),
        Stack(
          children: [
            AnimatedOpacity(
              opacity: isFirstPolling ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(),
              ),
            ),
            AnimatedOpacity(
              opacity: isFirstPolling ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  const AppText.titleLarge(
                    'Internet ',
                  ),
                  AppText.titleLarge(
                    isOnline ? 'online' : 'offline',
                    color: isOnline
                        ? Theme.of(context).colorScheme.primary
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ssid(String ssid, bool isLoading) {
    return isLoading
        ? Shimmer(
            gradient: _shimmerGradient,
            child: AppText.displaySmall(
              ssid,
            ),
          )
        : AppText.displaySmall(
            ssid,
          );
  }

  Widget _networkInfoTiles(DashboardHomeState state, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: _wifiInfoTile(state.numOfWifi, isLoading)),
          Flexible(child: _nodesInfoTile(state, isLoading)),
          Flexible(
              child: _devicesInfoTile(
                  state.numOfOnlineExternalDevices, isLoading)),
        ],
      ),
    );
  }

  Widget _wifiInfoTile(int wifiCount, bool isLoading) {
    return _infoTile(
      iconData: getCharactersIcons(context).wifiDefault,
      text: 'WiFi $wifiCount',
      isLoading: isLoading,
      onTap: () {
        context.pushNamed(RouteNamed.wifiShare);
      },
    );
  }

  Widget _nodesInfoTile(DashboardHomeState state, bool isLoading) {
    final image =
        AppTheme.of(context).images.devices.getByName(state.masterIcon);
    return _infoTile(
      image: image,
      text: 'Nodes ${state.numOfNodes}',
      isLoading: isLoading,
      onTap: () {
        ref.read(topologySelectedIdProvider.notifier).state = '';
        context.pushNamed(RouteNamed.settingsNodes);
      },
    );
  }

  Widget _devicesInfoTile(int numOfOnlineExternalDevices, bool isLoading) {
    return _infoTile(
      text: '$numOfOnlineExternalDevices devices',
      iconData: getCharactersIcons(context).devicesDefault,
      isLoading: isLoading,
      onTap: () {
        context.goNamed(RouteNamed.dashboardDevices);
      },
    );
  }

  Widget _infoTile({
    required String text,
    IconData? iconData,
    ImageProvider? image,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return isLoading
        ? Card(
            elevation: 10,
            child: Shimmer(
              gradient: _shimmerGradient,
              child: AppCard(
                iconData: iconData,
                image: image,
                title: text,
              ),
            ),
          )
        : InkWell(
            onTap: onTap,
            child: AppCard(
              iconData: iconData,
              image: image,
              title: text,
            ),
          );
  }

  Widget _speedTestTile(DashboardHomeState state, bool isLoading) {
    return GestureDetector(
        onTap: () => context.goNamed(RouteNamed.dashboardSpeedTest),
        child: SizedBox(
          width: double.infinity,
          height: 160,
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: AppPadding(
              padding: const AppEdgeInsets.symmetric(
                  horizontal: AppGapSize.regular, vertical: AppGapSize.regular),
              child: isLoading
                  ? Shimmer(
                      gradient: _shimmerGradient,
                      child: _speedResult(state),
                    )
                  : _speedResult(state),
            ),
          ),
        )
        );
  }

  get _shimmerGradient => LinearGradient(
        colors: [
          Colors.grey,
          Colors.grey[300]!,
          Colors.grey,
        ],
        stops: const [
          0.1,
          0.3,
          0.4,
        ],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        tileMode: TileMode.clamp,
      );

  Widget _speedResult(DashboardHomeState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleLarge('Speed'),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(
                          icon: getCharactersIcons(context).arrowUp,
                        ),
                        const AppGap.semiSmall(),
                        AppText.titleLarge(state.uploadResult.value),
                      ],
                    ),
                    Text('${state.uploadResult.unit}ps'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(
                          icon: getCharactersIcons(context).arrowDown,
                        ),
                        const AppGap.semiSmall(),
                        AppText.titleLarge(state.downloadResult.value),
                      ],
                    ),
                    Text('${state.downloadResult.unit}ps'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pushNotificationCheck() {
    if (kIsWeb) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (GoRouter.of(context).routerDelegate.currentConfiguration.fullPath !=
        RoutePath.dashboardHome) {
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      final isPushPromptShown = prefs.getBool(
              SmartDevicesPrefsHelper.getNidKey(prefs, key: pShowPushPrompt)) ??
          false;
      if (!isPushPromptShown) {
        prefs.setBool(
            SmartDevicesPrefsHelper.getNidKey(prefs, key: pShowPushPrompt),
            true);
        showAdaptiveDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: AppText.bodyLarge('Push Notification'),
            content: AppText.bodyLarge(
                'Do you want to receive Linksys push notifications?'),
            actions: [
              AppTextButton(
                'Yes',
                onTap: () {
                  final deviceToken = prefs.getString(pDeviceToken);
                  if (deviceToken != null) {
                    ref
                        .read(smartDeviceProvider.notifier)
                        .registerSmartDevice(deviceToken);
                  } else {}
                  context.pop();
                },
              ),
              AppTextButton('No', onTap: () {
                context.pop();
              })
            ],
          ),
        );
      }
    });
  }
}
