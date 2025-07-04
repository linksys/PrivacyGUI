// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/page/components/customs/timer_contdown_widget.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
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
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';
import 'remote_assistance/remote_assistance_dialog.dart';

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
    final sessionInfo = loginType == LoginType.remote
        ? ref.watch(remoteClientProvider).sessionInfo
        : null;
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
                  if (loginType == LoginType.remote)
                    Column(
                      children: [
                        _networkSelect(),
                        if (sessionInfo != null)
                          _sessionExpireCounter(sessionInfo),
                      ],
                    ),
                  if (loginType == LoginType.local)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: AppIconButton.noPadding(
                        icon: Icons.support_agent,
                        onTap: () {
                          showRemoteAssistanceDialog(context, ref);
                        },
                      ),
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
          AppText.labelLarge(
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

  Widget _sessionExpireCounter(GRASessionInfo sessionInfo) {
    final initialSeconds = (sessionInfo.expiredIn) * -1;
    return Row(
      children: [
        TimerCountdownWidget(
          initialSeconds: initialSeconds,
          title: 'Session',
        ),
        AppGap.small1(),
        SizedBox(
            width: 24,
            height: 24,
            child: AppIconButton.noPadding(
                onTap: () {
                  showSimpleAppDialog(
                    context,
                    title: loc(context).endRemoteAssistance,
                    content: AppText.bodyMedium(
                        loc(context).endRemoteAssistanceDesc),
                    actions: [
                      AppTextButton(
                        loc(context).cancel,
                        color: Theme.of(context).colorScheme.onSurface,
                        onTap: () {
                          context.pop();
                        },
                      ),
                      AppTextButton(
                        loc(context).ok,
                        color: Theme.of(context).colorScheme.error,
                        onTap: () {
                          context.pop();
                          ref.read(remoteClientProvider.notifier).endRemoteAssistance();
                          ref.read(authProvider.notifier).logout();
                        },
                      ),
                    ],
                  );
                },
                icon: LinksysIcons.close)),
      ],
    );
  }
}
