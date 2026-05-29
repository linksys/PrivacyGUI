import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Step 2 of modem restart flow — ensure modem lights are off.
class PnpModemLightsOffView extends StatelessWidget {
  const PnpModemLightsOffView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      onBackTap: () => context.pop(),
      child: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Assets.images.modemDevice.svg(width: 160)),
                AppGap.xxxl(),
                AppText.headlineSmall(loc(context).pnpModemLightsOffTitle),
                AppGap.md(),
                AppText.bodyMedium(loc(context).pnpModemLightsOffDesc),
                AppGap.xxxl(),
                _buildTipCard(context),
                AppGap.xxxl(),
                AppButton.primary(
                  label: loc(context).next,
                  onTap: () => context.goNamed(RouteNamed.pnpWaitingModem),
                ),
              ],
            ),
          ),
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
                  loc(context).pnpModemLightsOffTip,
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
        titleText: loc(context).pnpModemLightsOffTipTitle,
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).pnpModemLightsOffTipDesc),
            AppGap.lg(),
            _buildStep(context, '1', loc(context).pnpModemLightsOffTipStep1),
            AppGap.md(),
            _buildStep(context, '2', loc(context).pnpModemLightsOffTipStep2),
            AppGap.md(),
            _buildStep(context, '3', loc(context).pnpModemLightsOffTipStep3),
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

  Widget _buildStep(BuildContext context, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AppText.labelSmall(
            number,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        AppGap.md(),
        Expanded(child: AppText.bodyMedium(text)),
      ],
    );
  }
}
