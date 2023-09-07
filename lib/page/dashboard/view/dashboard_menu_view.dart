import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/network/_network.dart';
import 'package:linksys_app/provider/select_network/select_network_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
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
    final state = ref.watch(networkProvider);
    final hasMultiNetworks =
        ref.watch(selectNetworkProvider).when(data: (state) {
      return state.networks.length > 1;
    }, error: (error, stackTrace) {
      return false;
    }, loading: () {
      return false;
    }); // .networks.length > 1;
    // return AppTertiaryButton.noPadding('${state.selected?.deviceInfo?.modelNumber ?? '123'}', onTap: () {});
    return AppPageView.noNavigationBar(
      scrollable: true,
      child: EnabledOpacityWidget(
        enabled: state.selected?.deviceInfo != null,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.extraBig(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppCard(
                    image: AppTheme.of(context).images.devices.getByName(
                          routerIconTest(
                              modelNumber:
                                  state.selected?.deviceInfo?.modelNumber ??
                                      ''),
                        ),
                  ),
                  const AppGap.regular(),
                  Expanded(
                    child: InkWell(
                      onTap: hasMultiNetworks
                          ? () {
                              context.pushNamed(RouteNamed.selectNetwork);
                            }
                          : null,
                      child: Row(
                        children: [
                          AppText.titleMedium(
                            state.selected?.radioInfo?.first.settings.ssid ??
                                'Home',
                          ),
                          if (hasMultiNetworks)
                            AppIcon.regular(
                              icon: getCharactersIcons(context).chevronDown,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AppSection.withList(
                contentPadding: const AppEdgeInsets.big(),
                items: [
                  AppSectionItemData(
                      title: 'New Product',
                      iconData: getCharactersIcons(context).addDefault),
                  AppSectionItemData(
                      title: 'Settings',
                      iconData: getCharactersIcons(context).settingsDefault,
                      onTap: () {
                        shellNavigatorKey.currentContext!
                            .pushNamed(RouteNamed.dashboardSettings);
                      }),
                  AppSectionItemData(
                      title: 'Account',
                      iconData:
                          getCharactersIcons(context).administrationDefault,
                      onTap: () {
                        shellNavigatorKey.currentContext!
                            .pushNamed(RouteNamed.accountInfo);
                        // context.pushNamed(RouteNamed.accountInfo);
                      }),
                  AppSectionItemData(
                      title: 'Help',
                      iconData: getCharactersIcons(context).helpRound),
                ],
              ),
              const Spacer(),
              const AppGap.semiBig(),
                AppTertiaryButton.noPadding('Log out', onTap: () {
                  ref.read(authProvider.notifier).logout();
                }),
                const AppGap.semiBig(),
                FutureBuilder(
                    future: PackageInfo.fromPlatform()
                        .then((value) => value.version),
                    initialData: '-',
                    builder: (context, data) {
                      return AppText.bodyLarge(
                        'version ${data.data}',
                      );
                    }),
              AppTertiaryButton.noPadding('About Linksys', onTap: () {}),
              const AppGap.semiBig(),
            ],
          ),
        ),
      ),
    );
  }
}
