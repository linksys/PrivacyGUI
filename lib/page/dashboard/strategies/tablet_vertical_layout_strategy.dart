import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Tablet layout with vertical ports.
///
/// Custom layout optimized for vertical port display:
/// - Top: Internet
/// - Middle: Networks
/// - Bottom: Split row (Port left | WiFi + QuickPanel right)
class TabletVerticalLayoutStrategy extends DashboardLayoutStrategy {
  const TabletVerticalLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    return Column(
      children: [
        ctx.title,
        AppGap.xl(),
        ctx.internetWidget,
        AppGap.lg(),
        ctx.networksWidget,
        AppGap.lg(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: ctx.buildPortAndSpeed(const PortAndSpeedConfig(
                  direction: Axis.vertical,
                  showSpeedTest: false,
                  portsHeight: 752,
                  portsPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxl,
                  ),
                )),
              ),
              AppGap.gutter(),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (ctx.vpnTile != null) ...[
                      ctx.vpnTile!,
                      AppGap.lg(),
                    ],
                    ctx.wifiGrid,
                    AppGap.lg(),
                    ctx.quickPanel,
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
