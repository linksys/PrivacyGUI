import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class PnpAutoMasterWaitingView extends StatelessWidget {
  final bool showConnectionError;
  final VoidCallback? onRetry;

  const PnpAutoMasterWaitingView({
    super.key,
    this.showConnectionError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return showConnectionError
        ? _buildConnectionErrorView(context)
        : _buildWaitingView(context);
  }

  Widget _buildWaitingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppSpinner(semanticLabel: 'Auto Master waiting spinner'),
          const AppGap.medium(),
          Icon(
            LinksysIcons.settings,
            semanticLabel: 'settings icon',
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.medium(),
          AppText.headlineSmall(loc(context).pnpAutoMasterWaitingTitle),
          const AppGap.small2(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AppText.bodyMedium(
              loc(context).pnpAutoMasterWaitingDesc,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LinksysIcons.signalWifiOff,
              semanticLabel: 'wifi off icon',
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const AppGap.medium(),
            AppText.headlineSmall(loc(context).routerNotFound),
            const AppGap.small2(),
            AppText.bodyMedium(loc(context).notConnectedToRouter),
            const AppGap.medium(),
            AppBulletList(children: [
              AppText.bodySmall(loc(context).routerNotFoundDesc1),
              AppText.bodySmall(loc(context).routerNotFoundDesc3),
            ]),
            const AppGap.large3(),
            AppFilledButton(
              loc(context).tryAgain,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
