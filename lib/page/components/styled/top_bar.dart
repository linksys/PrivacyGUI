// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/page/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/page/dashboard/views/components/remote_assistance_animation.dart';
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
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/cloud/linksys_device_cloud_service.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'countdown_timer_widget.dart';

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
                  if (loginType == LoginType.local)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: AppIconButton.noPadding(
                        icon: Icons.support_agent,
                        onTap: () {
                          _showSessionDialog(context);
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

  void _showSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = true;
        return Consumer(
          builder: (context, ref, child) {
            return AlertDialog(
              title: AppText.titleMedium('Remote Assistance'),
              content: StatefulBuilder(builder: (context, setState) {
                if (isLoading) {
                  ref
                      .read(remoteClientProvider.notifier)
                      .initiateRemoteAssistance()
                      .then((_) {
                    setState(() {
                      isLoading = false;
                    });
                  });
                }
                return SizedBox(
                  width: 400,
                  height: 400,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRemoteAssistanceDialog(ref),
                );
              }),
              actions: [
                AppFilledButton(
                  'Close',
                  onTap: () {
                    ref
                        .read(remoteClientProvider.notifier)
                        .endRemoteAssistance();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRemoteAssistanceDialog(WidgetRef ref) {
    final state = ref.watch(remoteClientProvider);
    // final pin = state.pin;
    // // Error or no sessions, show a message to the user to contact a support agent
    // if (pin == null) {
    //   return Center(
    //     child: AppStyledText.link(
    //         'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to <a href="http://www.linksys.com/support" target="_blank">linksys.com/support</a> and click on Phone Call to get started.',
    //         color: Theme.of(context).colorScheme.primary,
    //         defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
    //         tags: const [
    //           'a'
    //         ],
    //         callbackTags: {
    //           'a': (tag, data) {
    //             final url = data['href'];
    //             if (url != null) {
    //               launchUrl(Uri.parse(url));
    //             }
    //           }
    //         }),
    //   );
    // }
    final sessionInfo = state.sessionInfo;
    // if status is PENDING, show pin code and status
    // if status is ACTIVE, show timer
    // if status is INVALID, invalid error message
    // in status is INITIATE, show spinner
    return switch (sessionInfo?.status ?? GRASessionStatus.initiate) {
      GRASessionStatus.pending => _buildPendingWidget(state),
      GRASessionStatus.active => _buildCountingWidget(state),
      GRASessionStatus.invalid => _buildInvalidWidget(),
      GRASessionStatus.initiate => _buildInitiateWidget(),
    };
  }

  Widget _buildInitiateWidget() {
    return Center(
      child: AppStyledText.link(
          'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to <a href="http://www.linksys.com/support" target="_blank">linksys.com/support</a> and click on Phone Call to get started.',
          color: Theme.of(context).colorScheme.primary,
          defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
          tags: const [
            'a'
          ],
          callbackTags: {
            'a': (tag, data) {
              final url = data['href'];
              if (url != null) {
                launchUrl(Uri.parse(url));
              }
            }
          }),
    );
  }

  Widget _buildPendingWidget(RemoteClientState state) {
    // PENDING TTL is 900 seconds only, but expiredIn is 3600 seconds, need to count down from 900 seconds
    final initialSeconds = (2700 + (state.sessionInfo?.expiredIn ?? 0)) * -1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge('Your pin code is:'),
        AppGap.large1(),
        Center(child: AppText.displayLarge(state.pin ?? '')),
        AppGap.large2(),
        TimerCountdownWidget(
          initialSeconds: initialSeconds,
          title: 'Pin code',
        ),
      ],
    );
  }

  Widget _buildInvalidWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge('Invalid session. Please contact a support agent.'),
      ],
    );
  }

  Widget _buildCountingWidget(RemoteClientState state) {
    final initialSeconds = (state.sessionInfo?.expiredIn ?? 0) * -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RemoteAssistanceAnimation(),
        AppText.labelLarge(
            'A Linksys support agent has remote access to your Linksys Smart Wi-Fi account and your home network.'),
        AppGap.large2(),
        TimerCountdownWidget(
          initialSeconds: initialSeconds,
          title: 'Session',
        ),
      ],
    );
  }
}

class TimerCountdownWidget extends StatelessWidget {
  final int initialSeconds;
  final String? title;
  const TimerCountdownWidget({
    Key? key,
    required this.initialSeconds,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (count) => initialSeconds - count,
      ).take(initialSeconds + 1),
      builder: (context, snapshot) {
        final secondsLeft = snapshot.data ?? initialSeconds;
        final display = secondsLeft > 0
            ? '$title expires in ${DateFormatUtils.formatTimeMSS(secondsLeft)}'
            : '$title expired';
        return AppText.bodyMedium(display);
      },
    );
  }
}
