import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/node_wan_status_provider.dart';
import 'package:linksys_app/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/provider/dashboard/dashboard_home_provider.dart';
import 'package:linksys_app/provider/dashboard/dashboard_home_state.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/provider/smart_device_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/smart_device_prefs_helper.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final _ = ref.watch(networkProvider); //TODO: XXXXXX Remove this state
    final state = ref.watch(dashboardHomeProvider);
    final wanStatus = ref.watch(nodeWanStatusProvider);
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
          EnabledOpacityWidget(
            enabled: state.canDisplayScreen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _homeTitle(state, wanStatus == NodeWANStatus.online),
                const AppGap.big(),
                _networkInfoTiles(state),
                const AppGap.extraBig(),
                _speedTestTile(state),
              ],
            ),
          ),
          if (ref.read(deviceManagerProvider.notifier).isEmptyState())
            const AppFullScreenSpinner(),
        ],
      ),
    );
  }

  Widget _homeTitle(DashboardHomeState state, bool isOnline) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        AppText.displaySmall(
          state.mainWifiSsid,
        ),
        const AppGap.regular(),
        Row(
          children: [
            const AppText.titleLarge(
              'Internet ',
            ),
            AppText.titleLarge(
              isOnline ? 'online' : 'offline',
              color:
                  isOnline ? Theme.of(context).colorScheme.primary : Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _networkInfoTiles(DashboardHomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wifiInfoTile(state),
          const AppGap.regular(),
          _nodesInfoTile(state),
          const AppGap.regular(),
          _devicesInfoTile(state),
        ],
      ),
    );
  }

  Widget _wifiInfoTile(DashboardHomeState state) {
    int wifiCount = state.numOfWifi;
    List<Widget> icons = [];
    for (int i = 0; i < wifiCount; i++) {
      icons.add(_circleIcon(
          //TODO: XXXXXX Get wifi signal
          image: const AssetImage('assets/images/wifi_signal_3.png')));
    }
    return _infoTile(
      iconData: getCharactersIcons(context).wifiDefault,
      text: 'WiFi ($wifiCount)',
      onTap: () {
        context.pushNamed(RouteNamed.wifiShare);
      },
    );
  }

  Widget _nodesInfoTile(DashboardHomeState state) {
    final image =
        AppTheme.of(context).images.devices.getByName(state.masterIcon);
    return _infoTile(
      image: image,
      text: 'Nodes (${state.numOfNodes})',
      onTap: () {
        context.pushNamed(RouteNamed.settingsNodes);
      },
    );
  }

  Widget _devicesInfoTile(DashboardHomeState state) {
    return _infoTile(
      text: '${state.numOfOnlineExternalDevices} devices online',
      iconData: getCharactersIcons(context).devicesDefault,
      onTap: () {
        context.goNamed(RouteNamed.dashboardDevices);
      },
    );
  }

  Widget _circleIcon({ImageProvider? image, SvgPicture? svgPicture}) {
    // Check input only one kind of image
    assert(image != null || svgPicture != null);
    assert(!(image != null && svgPicture != null));

    Widget child = Container();
    final image0 = image;
    if (image0 != null) {
      child = Image(
        image: image0,
        width: 30,
        height: 30,
      );
    } else {
      child = svgPicture!;
    }
    return CircleAvatar(
      radius: 23,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: child,
      ),
    );
  }

  Widget _infoTile({
    required String text,
    IconData? iconData,
    ImageProvider? image,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          AppCard(
            iconData: iconData,
            image: image,
          ),
          const AppGap.regular(),
          AppText.labelLarge(text)
        ],
      ),
    );
  }

  Widget _speedTestTile(DashboardHomeState state) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: AppPadding(
          padding: const AppEdgeInsets.symmetric(
              horizontal: AppGapSize.regular, vertical: AppGapSize.semiSmall),
          child: _speedResult(state),
        ),
      ),
    );
  }

  Widget _speedResult(DashboardHomeState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                  mainAxisAlignment: MainAxisAlignment.start,
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
              GestureDetector(
                onTap: () {
                  // GoRouter helath check
                },
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: AppText.labelLarge(
                    'Go',
                  ),
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
              AppTertiaryButton(
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
              AppTertiaryButton('No', onTap: () {
                context.pop();
              })
            ],
          ),
        );
      }
    });
  }
}
