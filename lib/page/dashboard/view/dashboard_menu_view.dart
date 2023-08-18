import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/bloc/network/cubit.dart';
import 'package:linksys_app/bloc/network/state.dart';
import 'package:linksys_app/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';

import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/panel/general_card.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';

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
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        final hasMultiNetworks = state.networks.length > 1;

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
                    const AppGap.big(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppDeviceAvatar.extraLarge(
                          image: AppTheme.of(context).images.devices.getByName(
                                routerIconTest(
                                    modelNumber: state.selected?.deviceInfo
                                            ?.modelNumber ??
                                        ''),
                              ),
                        ),
                        const AppGap.regular(),
                        Expanded(
                          child: InkWell(
                            onTap: hasMultiNetworks
                                ? () {
                                    // ref
                                    //     .read(navigationsProvider.notifier)
                                    //     .push(SelectNetworkPath());
                                  }
                                : null,
                            child: Row(
                              children: [
                                AppText.subhead(
                                  state.selected?.radioInfo?.first.settings
                                          .ssid ??
                                      'Home',
                                ),
                                if (hasMultiNetworks)
                                  AppIcon.regular(
                                    icon:
                                        getCharactersIcons(context).chevronDown,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        AppIconButton(
                          icon: getCharactersIcons(context).bellDefault,
                          onTap: () {
                            // ref
                            //     .read(navigationsProvider.notifier)
                            //     .push(LinkupPath());
                          },
                        ),
                      ],
                    ),
                    AppSection.withList(
                      contentPadding: const AppEdgeInsets.big(),
                      items: [
                        AppSectionItemData(
                            title: 'WiFi',
                            iconData: getCharactersIcons(context).wifiDefault),
                        AppSectionItemData(
                            title: 'Set up',
                            iconData: getCharactersIcons(context).addDefault),
                        AppSectionItemData(
                            title: 'Account',
                            iconData: getCharactersIcons(context)
                                .administrationDefault,
                            onTap: () {
                              context.pushNamed(RouteNamed.accountInfo);
                            }),
                        AppSectionItemData(
                            title: 'Help',
                            iconData: getCharactersIcons(context).helpRound),
                      ],
                    ),
                    const AppGap.regular(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AppCard(
                          iconData: getCharactersIcons(context).infoRound,
                          title: 'Speed Test',
                        ),
                        AppCard(
                          iconData: getCharactersIcons(context).infoRound,
                          title: 'Speed Test',
                        ),
                        AppCard(
                          iconData: getCharactersIcons(context).infoRound,
                          title: 'Speed Test',
                        ),
                      ],
                    ),
                    const Spacer(),
                    AppTertiaryButton.noPadding('About Linksys', onTap: () {}),
                    const AppGap.semiBig(),
                  ],
                ),
              ),
            ));
      },
    );
  }
}
