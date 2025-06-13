// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/material/color_tonal_palettes.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/select_network/_select_network.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/debug_mixin.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class TopBar extends ConsumerStatefulWidget {
  final void Function(int)? onMenuClick;
  const TopBar({
    super.key,
    this.onMenuClick,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> with DebugObserver {
  @override
  Widget build(BuildContext context) {
    final loginType =
        ref.watch(authProvider.select((value) => value.value?.loginType)) ??
            LoginType.none;
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: () {
          if (increase()) {
            // context.pushNamed(RouteNamed.debug);
            Utils.exportLogFile(context);
          }
        },
        child: Container(
          color: Color(neutralTonal.get(6)),
          height: 64,
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.titleLarge(loc(context).appTitle,
                  color: Color(neutralTonal.get(100))),
              MenuHolder(type: MenuDisplay.top),
              Wrap(
                children: [
                  if (loginType == LoginType.remote) _networkSelect(),
                  // if (loginType != LoginType.none)
                  //   const Padding(
                  //     padding: EdgeInsets.all(4.0),
                  //     child: NotificationPopupWidget(),
                  //   ),
                  if (loginType == LoginType.local) ...[
                    AppIconButton(
                      icon: LinksysIcons.autoAwesomeMosaic,
                      onTap: () {
                        context.pushNamed(RouteNamed.dashboardModularApps);
                      },
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: GeneralSettingsWidget(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _networkSelect() {
    final dashboardHomeState = ref.watch(dashboardHomeProvider);

    final hasMultiNetworks =
        ref.watch(selectNetworkProvider).when(data: (state) {
      return state.networks.length > 1;
    }, error: (error, stackTrace) {
      return false;
    }, loading: () {
      return false;
    });
    return InkWell(
      onTap: hasMultiNetworks
          ? () {
              ref.read(selectNetworkProvider.notifier).refreshCloudNetworks();
              context.pushNamed(RouteNamed.selectNetwork);
            }
          : null,
      child: Row(
        children: [
          AppText.labelMedium(
            dashboardHomeState.mainSSID,
            overflow: TextOverflow.fade,
            color: Color(
              neutralTonal.get(100),
            ),
          ),
        ],
      ),
    );
  }
}
