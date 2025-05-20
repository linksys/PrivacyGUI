import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/views/shared_widgets.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class VPNStatusTile extends ConsumerStatefulWidget {
  const VPNStatusTile({super.key});

  @override
  ConsumerState<VPNStatusTile> createState() => _VPNStatusTile();
}

class _VPNStatusTile extends ConsumerState<VPNStatusTile> {
  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnProvider);
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;
    final statistics = vpnState.status.statistics;
    final uptimeInt = ref.watch(
        vpnProvider.select((value) => value.status.statistics?.uptime ?? 0));
    final uptime = uptimeInt > 0
        ? DateFormatUtils.formatDuration(Duration(seconds: uptimeInt), null)
        : '--';
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    return AppCard(
      padding: EdgeInsets.all(Spacing.large2),
      onTap: isBridge
          ? null
          : () {
              context.pushNamed(RouteNamed.settingsVPN);
            },
      child: isLoading
          ? AppSpinner()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.titleMedium(loc(context).vpn),
                    const AppGap.small2(),
                    AppSwitch(
                        value:
                            vpnState.settings.serviceSettings?.enabled ?? false,
                        onChanged: (value) {
                          final settings = vpnState.settings.serviceSettings ??
                              VPNServiceSetSettings(
                                  enabled: false, autoConnect: false);
                          final notifier = ref.read(vpnProvider.notifier);
                          notifier
                              .setVPNService(settings.copyWith(enabled: value));

                          doSomethingWithSpinner(context, notifier.save());
                        })
                  ],
                ),
                vpnStatus(
                    context,
                    isBridge
                        ? IPsecStatus.unknown
                        : vpnState.status.tunnelStatus),
                if (!isBridge &&
                    vpnState.status.tunnelStatus == IPsecStatus.connected) ...[
                  AppGap.medium(),
                  // VPN statistics
                  buildStatRow(loc(context).vpnUptime, uptime),
                  const AppGap.small2(),
                  Row(
                    children: [
                      Expanded(
                          child: Column(
                        children: [
                          buildStatRow(loc(context).vpnBytesReceived,
                              '${statistics?.bytesReceived ?? '--'}'),
                          buildStatRow(loc(context).vpnPacketsReceived,
                              '${statistics?.packetsReceived ?? '--'}'),
                        ],
                      )),
                      const AppGap.gutter(),
                      Expanded(
                          child: Column(
                        children: [
                          buildStatRow(loc(context).vpnBytesSent,
                              '${statistics?.bytesSent ?? '--'}'),
                          buildStatRow(loc(context).vpnPacketsSent,
                              '${statistics?.packetsSent ?? '--'}'),
                        ],
                      )),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
