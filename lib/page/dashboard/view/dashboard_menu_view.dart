import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/provider/app_settings/app_settings_provider.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/dashboard/dashboard_home_provider.dart';
import 'package:linksys_app/provider/select_network/select_network_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DashboardMenuView extends ConsumerStatefulWidget {
  const DashboardMenuView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardMenuView> createState() => _DashboardMenuViewState();
}

class _DashboardMenuViewState extends ConsumerState<DashboardMenuView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardHomeState = ref.watch(dashboardHomeProvider);
    final hasMultiNetworks =
        ref.watch(selectNetworkProvider).when(data: (state) {
      return state.networks.length > 1;
    }, error: (error, stackTrace) {
      return false;
    }, loading: () {
      return false;
    }); // .networks.length > 1;
    // return AppTextButton.noPadding('${state.selected?.deviceInfo?.modelNumber ?? '123'}', onTap: () {});
    final isCloudLogin =
        ref.read(authProvider).value?.loginType == LoginType.remote;
    return AppPageView.noNavigationBar(
      scrollable: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.extraBig(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: AppCard(
                        // Get image by master node's model number
                        image: CustomTheme.of(context).images.devices.getByName(
                              routerIconTest(
                                modelNumber: ref
                                        .read(deviceManagerProvider)
                                        .deviceList
                                        .firstOrNull
                                        ?.model
                                        .modelNumber ??
                                    '',
                              ),
                            ),
                        maxWidth: 120,
                        maxHeight: 120,
                        minHeight: 60,
                        minWidth: 60),
                  ),
                  const AppGap.regular(),
                  InkWell(
                    onTap: hasMultiNetworks
                        ? () {
                            ref
                                .read(selectNetworkProvider.notifier)
                                .refreshCloudNetworks();

                            _navigateTo(RouteNamed.selectNetwork);
                          }
                        : null,
                    child: Row(
                      children: [
                        AppText.titleMedium(
                          dashboardHomeState.mainWifiSsid,
                          overflow: TextOverflow.fade,
                        ),
                        if (hasMultiNetworks)
                          AppIcon.regular(
                            icon: getCharactersIcons(context).chevronDown,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppGap.regular(),
            AppSection.withList(
              contentPadding: const EdgeInsets.only(),
              items: [
                AppSectionItemData(
                    title: 'Settings',
                    iconData: getCharactersIcons(context).settingsDefault,
                    onTap: () {
                      _navigateTo(RouteNamed.dashboardSettings);
                    }),
                AppSectionItemData(
                    title: 'Safe Browsing',
                    iconData: getCharactersIcons(context).shieldDefault,
                    onTap: () {
                      _navigateTo(RouteNamed.safeBrowsing);
                    }),
                AppSectionItemData(
                    title: 'Speed Test',
                    iconData: getCharactersIcons(context).securityDefault,
                    onTap: () {
                      _navigateTo(RouteNamed.speedTestSelection);
                    }),
                if (isCloudLogin)
                  AppSectionItemData(
                      title: 'Account',
                      iconData:
                          getCharactersIcons(context).administrationDefault,
                      onTap: () {
                        _navigateTo(RouteNamed.accountInfo);
                      }),
                AppSectionItemData(
                    title: 'Help',
                    iconData: getCharactersIcons(context).helpRound),
                // AppSectionItemData(
                //     title: 'Linksys LinkUp',
                //     iconData: getCharactersIcons(context).bellDefault,
                //     onTap: () {
                //       _navigateTo(RouteNamed.linkup);
                //     }),
              ],
            ),
            const Spacer(),
            
            const AppGap.semiBig(),
            AppTextButton.noPadding('Log out', onTap: () {
              ref.read(authProvider.notifier).logout();
            }),
            AppTextButton.noPadding('About Linksys', onTap: () {}),
            FutureBuilder(
                future:
                    PackageInfo.fromPlatform().then((value) => value.version),
                initialData: '-',
                builder: (context, data) {
                  return AppText.bodyLarge(
                    'version ${data.data}',
                  );
                }),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String name) {
    if (kIsWeb) {
      if (shellNavigatorKey.currentContext!.canPop()) {
        shellNavigatorKey.currentContext!.pushReplacementNamed(name);
      } else {
        shellNavigatorKey.currentContext!.pushNamed(name);
      }
    } else {
      shellNavigatorKey.currentContext!.pushNamed(name);
    }
  }
}
