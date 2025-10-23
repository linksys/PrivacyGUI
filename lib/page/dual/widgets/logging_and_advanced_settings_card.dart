import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class LoggingAndAdvancedSettingsCard extends ConsumerWidget {
  final double twoColWidth;
  final double gutter;

  const LoggingAndAdvancedSettingsCard({
    super.key,
    required this.twoColWidth,
    required this.gutter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggingOptions =
        ref.watch(dualWANSettingsProvider).settings.loggingOptions;
    final notifier = ref.read(dualWANSettingsProvider.notifier);

    return AppInformationCard(
      title: loc(context).loggingAdvancedSettings,
      description: loc(context).loggingAdvancedSettingsDescription,
      content: Column(
        spacing: Spacing.large1,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).loggingOptions),
                const AppGap.medium(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logFailoverEvents),
                    AppSwitch(
                      value: loggingOptions?.failoverEvents ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;
                        notifier.updateLoggingOptions(
                            loggingOptions.copyWith(failoverEvents: value));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logWanUptime),
                    AppSwitch(
                      value: loggingOptions?.wanUptime ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;
                        notifier.updateLoggingOptions(
                            loggingOptions.copyWith(wanUptime: value));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logSpeedChecks),
                    AppSwitch(
                      value: loggingOptions?.speedChecks ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;
                        notifier.updateLoggingOptions(
                            loggingOptions.copyWith(speedChecks: value));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppText.labelMedium(loc(context).logThroughputData),
                    AppSwitch(
                      value: loggingOptions?.throughputData ?? false,
                      onChanged: (value) {
                        if (loggingOptions == null) return;
                        notifier.updateLoggingOptions(
                            loggingOptions.copyWith(throughputData: value));
                      },
                    ),
                  ],
                ),
                const Divider(
                  height: 24,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: AppOutlinedButton.fillWidth(
                    loc(context).viewLogs,
                    onTap: () {
                      context.pushNamed(RouteNamed.dualWANLog);
                    },
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: Spacing.small2,
              children: [
                AppText.labelLarge(loc(context).selfTestTools),
                const AppGap.medium(),
                AppOutlinedButton.fillWidth(
                  loc(context).connectionHealthCheck,
                  onTap: () {},
                ),
                AppOutlinedButton.fillWidth(
                  loc(context).failoverTest,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
