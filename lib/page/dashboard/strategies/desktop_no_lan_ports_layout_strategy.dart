import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Desktop layout for devices without LAN ports.
///
/// Top row: Internet (8 col) | Port (4 col)
/// Bottom row: Networks + QuickPanel (4 col) | VPN + WiFi (8 col)
class DesktopNoLanPortsLayoutStrategy extends DashboardLayoutStrategy {
  const DesktopNoLanPortsLayoutStrategy();

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
              width: ctx.colWidth(8),
              child: ctx.internetWidget,
            ),
            AppGap.gutter(),
            SizedBox(
              width: ctx.colWidth(4),
              child: ctx.buildPortAndSpeed(const PortAndSpeedConfig(
                direction: Axis.horizontal,
                showSpeedTest: true,
                portsHeight: 120,
                speedTestHeight: 132,
                portsPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
              )),
            ),
          ],
        ),
        AppGap.lg(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: ctx.colWidth(4),
              child: Column(
                children: [
                  ctx.networksWidget,
                  AppGap.lg(),
                  ctx.quickPanel,
                ],
              ),
            ),
            AppGap.gutter(),
            SizedBox(
              width: ctx.colWidth(8),
              child: Column(
                children: [
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
