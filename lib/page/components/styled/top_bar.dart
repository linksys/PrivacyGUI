// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
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
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';

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
    final isRemote = loginType == LoginType.remote;
    final isPollingDone = ref.watch(deviceManagerProvider).deviceList.isNotEmpty;
    if (isRemote && isPollingDone) {
      _startRemoteAssistance(context);
    }
    final sessionInfo =
        isRemote ? ref.watch(remoteClientProvider).sessionInfo : null;
    final expiredCountdown =
        isRemote ? ref.watch(remoteClientProvider).expiredCountdown : null;
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
                  if (isRemote)
                    Column(
                      children: [
                        _networkSelect(),
                        if (sessionInfo != null)
                          _sessionExpireCounter(sessionInfo, expiredCountdown),
                      ],
                    ),
                  // TODO: Add the button back when remote assistance is ready
                  // if (loginType == LoginType.local)
                  //   Padding(
                  //     padding: EdgeInsets.symmetric(horizontal: 4.0),
                  //     child: AppIconButton.noPadding(
                  //       icon: Icons.support_agent,
                  //       onTap: () {
                  //         showRemoteAssistanceDialog(context, ref);
                  //       },
                  //     ),
                  //   ),
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

  Widget _sessionExpireCounter(GRASessionInfo sessionInfo, int? expiredCountdown) {
    var display = loc(context).remoteAssistanceSessionExpired;
    if (sessionInfo.status != GRASessionStatus.active) {
      return AppText.bodyMedium(display);
    }
    final count = expiredCountdown ?? sessionInfo.expiredIn;
    if (count > 0) {
      display = loc(context).remoteAssistanceSessionExpiresIn(
          DateFormatUtils.formatTimeMSS(count));
    }
    return AppText.bodyMedium(display);
  }

  void _startRemoteAssistance(BuildContext context) {
    ref.read(remoteClientProvider.notifier).initiateRemoteAssistanceCA();
    ref.listen(
        remoteClientProvider.select((value) => value.sessionInfo?.status),
        (previous, next) {
      if (previous == GRASessionStatus.active &&
          next != GRASessionStatus.active) {
        showSimpleAppDialog(
          context,
          dismissible: false,
          content:
              AppText.bodyMedium(loc(context).remoteAssistanceSessionExpired),
          actions: [
            AppTextButton(
              loc(context).ok,
              onTap: () {
                context.pop();
                ref.read(remoteClientProvider.notifier).endRemoteAssistance();
                ref.read(authProvider.notifier).logout();
              },
            )
          ],
        );
      }
    });
  }
}
