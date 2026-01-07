import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Tablet layout with horizontal ports.
///
/// Vertical stack for port section (Internet on top, Port below).
/// Solves overflow for wide port widgets on narrower tablet screens.
class TabletHorizontalLayoutStrategy extends DashboardLayoutStrategy {
  const TabletHorizontalLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    return Column(
      children: [
        ctx.title,
        AppGap.xl(),
        // Vertical stack: Internet Top, Port Bottom
        ctx.internetWidget,
        AppGap.lg(),
        ctx.buildPortAndSpeed(const PortAndSpeedConfig(
          direction: Axis.horizontal,
          showSpeedTest: true,
          portsHeight: 224,
          speedTestHeight: 112,
          portsPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxl,
          ),
        )),
        AppGap.lg(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    ctx.networksWidget,
                    AppGap.lg(),
                    ctx.quickPanel,
                  ],
                ),
              ),
              AppGap.gutter(),
              Expanded(
                flex: 1,
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
        ),
      ],
    );
  }
}
