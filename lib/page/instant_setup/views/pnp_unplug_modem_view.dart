import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Step 1 of modem restart flow — instruct user to unplug their modem.
class PnpUnplugModemView extends StatelessWidget {
  const PnpUnplugModemView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      onBackTap: () => context.pop(),
      bottomBar: UiKitBottomBarConfig(
        positiveLabel: loc(context).next,
        onPositiveTap: () => context.goNamed(RouteNamed.pnpModemLightsOff),
      ),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Assets.images.modemPlugged.svg(width: 200)),
            AppGap.xxxl(),

            AppText.headlineSmall(loc(context).pnpUnplugModemTitle),
            AppGap.md(),
            AppText.bodyMedium(loc(context).pnpUnplugModemDesc),
            AppGap.xxxl(),

            // Tip: Not sure which device?
            _buildTipCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: () => _showTipDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              AppIcon.font(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              AppGap.md(),
              Expanded(
                child: AppText.bodyMedium(
                  loc(context).pnpUnplugModemTip,
                ),
              ),
              AppIcon.font(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDialog(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (ctx) => AppDialog(
        titleText: loc(context).pnpUnplugModemTipTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).pnpUnplugModemTipDesc1),
            AppGap.md(),
            AppText.bodyMedium(loc(context).pnpUnplugModemTipDesc2),
          ],
        ),
        actions: [
          AppButton.text(
            label: loc(context).close,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
