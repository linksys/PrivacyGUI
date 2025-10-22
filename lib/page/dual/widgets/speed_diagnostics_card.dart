import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class SpeedDiagnosticsCard extends ConsumerWidget {
  const SpeedDiagnosticsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speedStatus = ref.watch(dualWANSettingsProvider).status.speedStatus;
    
    return AppInformationCard(
      headerIcon: const Icon(Icons.monitor_heart),
      title: loc(context).speedTestsDiagnostics,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: Spacing.small2,
        children: [
          AppOutlinedButton.fillWidth(
            loc(context).testPrimaryWanSpeed,
            onTap: () {},
          ),
          const AppGap.medium(),
          AppOutlinedButton.fillWidth(
            loc(context).testSecondaryWanSpeed,
            onTap: () {},
          ),
          const AppGap.medium(),
          AppFilledButton.fillWidth(
            loc(context).testBothConnections,
            onTap: () {},
          ),
          const AppGap.large2(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyMedium(loc(context).primaryWanSpeed),
              AppText.bodyMedium(NetworkUtils.formatBits(
                  speedStatus?.primaryDownloadSpeed ?? 0,
                  decimals: 2)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.bodyMedium(loc(context).secondaryWanSpeed),
              AppText.bodyMedium(NetworkUtils.formatBits(
                  speedStatus?.secondaryDownloadSpeed ?? 0,
                  decimals: 2)),
            ],
          ),
        ],
      ),
    );
  }
}
