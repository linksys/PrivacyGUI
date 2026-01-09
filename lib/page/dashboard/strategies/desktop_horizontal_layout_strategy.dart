import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Desktop horizontal layout strategy.
///
/// Left column (expanded): Internet → Port → WiFi (stacked vertically)
/// Right column (4 col): Networks → VPN → QuickPanel
class DesktopHorizontalLayoutStrategy extends DashboardLayoutStrategy {
  const DesktopHorizontalLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ctx.title,
        AppGap.xl(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  ctx.internetWidget,
                  AppGap.lg(),
                  ctx.buildPortAndSpeed(const PortAndSpeedConfig(
                    direction: Axis.horizontal,
                    showSpeedTest: true,
                    portsHeight: 224,
                    speedTestHeight: 112,
                    portsPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxxl,
                    ),
                  )),
                  AppGap.lg(),
                  ctx.wifiGrid,
                ],
              ),
            ),
            AppGap.gutter(),
            SizedBox(
              width: ctx.colWidth(4),
              child: Column(
                children: [
                  ctx.networksWidget,
                  AppGap.lg(),
                  if (ctx.vpnTile != null) ...[
                    ctx.vpnTile!,
                    AppGap.lg(),
                  ],
                  ctx.quickPanel,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
