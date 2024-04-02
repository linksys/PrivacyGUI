import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:linksys_app/page/components/styled/notification_popup_widget.dart';
import 'package:linksys_app/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:linksys_app/page/select_network/_select_network.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/util/debug_mixin.dart';
import 'package:linksys_widgets/theme/custom_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

class TopBar extends ConsumerStatefulWidget {
  const TopBar({super.key});

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
      child: GestureDetector(
        onTap: () {
          if (increase()) {
            context.pushNamed(RouteNamed.debug);
          }
        },
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, right: 24, top: 14, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ResponsiveLayout.isLayoutBreakpoint(context)
                        ? SvgPicture(
                            CustomTheme.of(context).images.linksysLogoBlack,
                            width: 20,
                            height: 20,
                          )
                        : const Center(),
                    Wrap(
                      children: [
                        if (loginType == LoginType.remote) _networkSelect(),
                        if (loginType != LoginType.none)
                          const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: NotificationPopupWidget(),
                          ),
                        const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: GeneralSettingsWidget(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Divider(
                height: 1,
              )
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
            dashboardHomeState.mainWifiSsid,
            overflow: TextOverflow.fade,
          ),
        ],
      ),
    );
  }
}
