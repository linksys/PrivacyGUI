// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/styled/remote_assistance/end_remote_assistance_and_logout.dart';
import 'package:privacy_gui/page/components/styled/remote_assistance/remote_assistance_dialog.dart';
import 'package:privacy_gui/page/components/widgets/brand_asset_widget.dart';
import 'package:privacy_gui/providers/brand_asset_provider.dart';
import 'package:privacy_gui/providers/global_model_number_provider.dart';
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
    final isPollingDone =
        ref.watch(deviceManagerProvider).deviceList.isNotEmpty;
    if (isRemote && isPollingDone) {
      _startRemoteAssistance(context);
    }
    // Only the one value the session line draws, not the whole provider. This
    // build() calls initiateRemoteAssistanceCA, and that call writes state even
    // when it finds nothing to track. Watching the whole provider turned every
    // such write into a rebuild straight back into the call: one sessions read
    // per cloud round trip once a session had ended (#1637). With nothing being
    // tracked, this value sits at null or 0, so those writes change nothing here.
    final secondsLeft = isRemote
        ? ref.watch(
            remoteClientProvider.select((state) => state.sessionSecondsLeft))
        : null;

    // Get model number from global state
    final modelNumber = ref.watch(globalModelNumberProvider);

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
              Row(
                children: [
                  // Brand logo (icon)
                  ref
                      .watch(brandAssetProvider(
                          (modelNumber: modelNumber, asset: BrandAsset.logo)))
                      .when(
                        data: (path) {
                          if (path != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BrandAssetWidget(
                                  path: path,
                                  height: 48,
                                ),
                                AppGap.small2(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                  // Brand text logo or fallback text
                  ref
                      .watch(brandAssetProvider((
                        modelNumber: modelNumber,
                        asset: BrandAsset.textLogo
                      )))
                      .when(
                        data: (textLogoPath) {
                          if (textLogoPath != null) {
                            // Use brand text logo if available
                            return BrandAssetWidget(
                              path: textLogoPath,
                              height: 32,
                              color: Color(neutralTonal.get(100)),
                              colorFilter: ColorFilter.mode(
                                Color(neutralTonal.get(100)),
                                BlendMode.srcIn,
                              ),
                            );
                          } else {
                            // Fallback to text if no text logo available
                            return AppText.titleLarge(loc(context).appTitle,
                                color: Color(neutralTonal.get(100)));
                          }
                        },
                        loading: () => AppText.titleLarge(loc(context).appTitle,
                            color: Color(neutralTonal.get(100))),
                        error: (_, __) => AppText.titleLarge(
                            loc(context).appTitle,
                            color: Color(neutralTonal.get(100))),
                      ),
                ],
              ),
              MenuHolder(type: MenuDisplay.top),
              Wrap(
                children: [
                  if (isRemote)
                    Column(
                      children: [
                        _networkSelect(),
                        if (secondsLeft != null)
                          _sessionExpireCounter(secondsLeft),
                      ],
                    ),
                  if (BuildConfig.enableRemoteAssistance &&
                      loginType == LoginType.local)
                    Padding(
                      padding: EdgeInsets.all(4.0),
                      child: AppIconButton.noPadding(
                        icon: Icons.support_agent,
                        color: Color(neutralTonal.get(100)),
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

  Widget _sessionExpireCounter(int secondsLeft) {
    return AppText.bodyMedium(
      secondsLeft > 0
          ? loc(context).remoteAssistanceSessionExpiresIn(
              DateFormatUtils.formatTimeMSS(secondsLeft))
          // The short form: this sits in the top bar, which gives the text no
          // width to wrap into, and the full explanation is in the dialog
          // shown alongside.
          : loc(context).remoteAssistanceSessionEnded,
      color: Color(neutralTonal.get(100)),
    );
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
              onTap: () async {
                context.pop();
                await endRemoteAssistanceAndLogout(ref);
              },
            )
          ],
        );
      }
    });
  }
}
