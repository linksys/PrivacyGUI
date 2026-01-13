import 'package:flutter/widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_layout_context.dart';
import 'dashboard_layout_strategy.dart';

/// Tablet layout strategy for devices without LAN ports.
///
/// Two column layout with equal split:
/// Left: Networks → QuickPanel
/// Right: VPN → WiFi
///
/// Port section shows side-by-side with Internet at top.
class TabletLayoutStrategy extends DashboardLayoutStrategy {
  const TabletLayoutStrategy();

  @override
  Widget build(DashboardLayoutContext ctx) {
    return Column(
      children: [
        ctx.title,
        AppGap.xl(),
        // Port section: Side-by-Side (Internet Left, Port Right)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: ctx.internetWidget,
              ),
              AppGap.gutter(),
              Expanded(
                flex: 1,
                child: ctx.buildPortAndSpeed(const PortAndSpeedConfig(
                  direction: Axis.horizontal,
                  showSpeedTest: true,
                  portsPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                )),
              ),
            ],
          ),
        ),
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
