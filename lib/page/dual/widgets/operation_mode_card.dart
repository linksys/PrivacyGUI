import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/card/selection_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class OperationModeCard extends ConsumerWidget {
  final double twoColWidth;

  const OperationModeCard({
    Key? key,
    required this.twoColWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(dualWANSettingsProvider).settings.mode;
    final balanceRatio =
        ref.watch(dualWANSettingsProvider).settings.balanceRatio;
    final notifier = ref.read(dualWANSettingsProvider.notifier);
    final gutter = ResponsiveLayout.columnPadding(context);

    return AppInformationCard(
      title: loc(context).dualWanOperationMode,
      description: loc(context).dualWanOperationModeDescription,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.medium,
        children: [
          Wrap(
            spacing: gutter,
            runSpacing: gutter,
            children: [
              SizedBox(
                width: twoColWidth - gutter / 2 - 6,
                child: AppSelectionCard(
                  value: DualWANMode.failover,
                  groupValue: mode,
                  title: DualWANMode.failover.toDisplayString(context),
                  label: 'Recommended',
                  description: loc(context).dualWanFailoverDescription,
                  onTap: () {
                    notifier.updateOperationMode(DualWANMode.failover);
                  },
                ),
              ),
              SizedBox(
                width: twoColWidth - gutter / 2 - 6,
                child: AppSelectionCard(
                  value: DualWANMode.loadBalanced,
                  groupValue: mode,
                  title: DualWANMode.loadBalanced.toDisplayString(context),
                  label: 'Advanced',
                  description: loc(context).dualWanLoadBalancingDescription,
                  onTap: () {
                    notifier.updateOperationMode(DualWANMode.loadBalanced);
                  },
                ),
              ),
            ],
          ),
          if (mode == DualWANMode.loadBalanced) ...[
            AppCard(
              color: Theme.of(context).colorScheme.primary.withAlpha(0x10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: Spacing.small2,
                children: [
                  AppText.labelLarge(loc(context).dualWanLoadBalanceRatio),
                  AppDropdownButton<DualWANBalanceRatio>(
                    selected: balanceRatio,
                    items: DualWANBalanceRatio.values,
                    label: (value) => value.toDisplayString(context),
                    onChanged: (value) {
                      notifier.updateBalanceRatio(value);
                    },
                  ),
                  AppText.bodySmall(
                    loc(context).dualWanLoadBalanceRatioDescription,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
