import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart'
    if (dart.library.io) 'package:privacy_gui/util/url_helper/url_helper_mobile.dart'
    if (dart.library.html) 'package:privacy_gui/util/url_helper/url_helper_web.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Widget for external speed test links (Fast.com, Cloudflare).
class ExternalSpeedTestLinks extends StatelessWidget {
  final DashboardHomeState state;

  const ExternalSpeedTestLinks({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final horizontalLayout = state.isHorizontalLayout;
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isVerticalDesktop =
        hasLanPort && !horizontalLayout && !context.isMobileLayout;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(12).copyWith(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, horizontalLayout, hasLanPort),
          AppGap.xs(),
          Flexible(
            child: isVerticalDesktop
                ? _buildVerticalButtons(context)
                : _buildHorizontalButtons(context),
          ),
          AppGap.xs(),
          AppText.bodyExtraSmall(loc(context).speedTestExternalOthers),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool horizontalLayout, bool hasLanPort) {
    final speedTitle = AppText.titleMedium(loc(context).speedTextTileStart);
    final infoIcon = InkWell(
      child: AppIcon.font(
        AppFontIcons.infoCircle,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => openUrl('https://support.linksys.com/kb/article/79-en/'),
    );
    final speedDesc =
        AppText.labelSmall(loc(context).speedTestExternalTileLabel);

    final showRowHeader =
        context.isMobileLayout || (hasLanPort && horizontalLayout);

    if (showRowHeader) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: speedTitle),
          infoIcon,
          speedDesc,
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: speedTitle),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            infoIcon,
            AppGap.sm(),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: speedDesc,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalButtons(BuildContext context) {
    return SizedBox(
      width: 144,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          AppButton(
            label: loc(context).speedTestExternalTileCloudFlare,
            onTap: () => openUrl('https://speed.cloudflare.com/'),
          ),
          AppButton(
            label: loc(context).speedTestExternalTileFast,
            onTap: () => openUrl('https://www.fast.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: AppSpacing.lg,
      children: [
        Expanded(
          child: AppButton(
            label: loc(context).speedTestExternalTileCloudFlare,
            onTap: () => openUrl('https://speed.cloudflare.com/'),
          ),
        ),
        Expanded(
          child: AppButton(
            label: loc(context).speedTestExternalTileFast,
            onTap: () => openUrl('https://www.fast.com'),
          ),
        ),
      ],
    );
  }
}
