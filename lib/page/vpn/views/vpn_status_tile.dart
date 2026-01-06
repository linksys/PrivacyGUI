import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/views/shared_widgets.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    if (isLoading) {
      return AppCard(
        child: SizedBox(
          width: double.infinity,
          height: 150,
          child: const LoadingTile(),
        ),
      );
    }

    Widget content = Padding(
      padding: const EdgeInsets.all(AppSpacing
          .xxl), // Spacing.large2 usually corresponds to xxl or lg? Assuming xxl/xl based on 24px/32px. privacygui Spacing.large2 = 24. ui_kit AppSpacing.lg=16, xl=24, xxl=32. I'll use xl.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.titleMedium(loc(context).vpn),
              AppGap.sm(),
              AppSwitch(
                  value: vpnState.settings.serviceSettings.enabled,
                  onChanged: (value) {
                    final settings = vpnState.settings.serviceSettings;
                    final notifier = ref.read(vpnProvider.notifier);
                    notifier.setVPNService(settings.copyWith(enabled: value));

                    doSomethingWithSpinner(context, notifier.save());
                  })
            ],
          ),
          vpnStatus(context,
              isBridge ? IPsecStatus.unknown : vpnState.status.tunnelStatus),
          if (!isBridge &&
              vpnState.status.tunnelStatus == IPsecStatus.connected) ...[
            AppGap.lg(),
            // VPN statistics
            buildStatRow(loc(context).vpnUptime, uptime),
            AppGap.sm(),
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
                AppGap.xxl(), // gutter
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

    if (!isBridge) {
      // Make card tappable
      return AppCard(
        onTap: () {
          context.pushNamed(RouteNamed.settingsVPN);
        },
        child: content,
      );
    }

    return AppCard(child: content);
  }
}
