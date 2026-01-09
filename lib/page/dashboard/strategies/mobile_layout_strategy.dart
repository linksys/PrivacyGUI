import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Mobile layout strategy - single column, all components stacked vertically.
class MobileLayoutStrategy extends DashboardLayoutStrategy {
  const MobileLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ctx.title,
        AppGap.xl(),
        ctx.internetWidget,
        AppGap.lg(),
        ctx.buildPortAndSpeed(const PortAndSpeedConfig(
          direction: Axis.horizontal,
          showSpeedTest: true,
          portsPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
        )),
        AppGap.lg(),
        ctx.networksWidget,
        if (ctx.vpnTile != null) ...[
          AppGap.lg(),
          ctx.vpnTile!,
        ],
        AppGap.lg(),
        ctx.quickPanel,
        AppGap.lg(),
        ctx.wifiGrid,
        AppGap.lg(),
      ],
    );
  }
}
