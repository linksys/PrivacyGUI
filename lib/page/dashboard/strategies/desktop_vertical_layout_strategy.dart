import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Desktop vertical layout strategy.
///
/// Left column (3 col): Port → QuickPanel (ports displayed vertically)
/// Right column (expanded): Internet → Networks → VPN → WiFi
class DesktopVerticalLayoutStrategy extends DashboardLayoutStrategy {
  const DesktopVerticalLayoutStrategy();

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
            SizedBox(
              width: ctx.colWidth(3),
              child: Column(
                children: [
                  ctx.buildPortAndSpeed(const PortAndSpeedConfig(
                    direction: Axis.vertical,
                    showSpeedTest: false,
                    portsHeight: 752,
                    portsPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxl,
                    ),
                  )),
                  AppGap.lg(),
                  ctx.quickPanel,
                ],
              ),
            ),
            AppGap.gutter(),
            Expanded(
              child: Column(
                children: [
                  ctx.internetWidget,
                  AppGap.lg(),
                  ctx.networksWidget,
                  AppGap.lg(),
                  if (ctx.vpnTile != null) ...[
                    ctx.vpnTile!,
                    AppGap.lg(),
                  ],
                  ctx.wifiGrid,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
