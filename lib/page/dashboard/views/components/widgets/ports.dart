import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/port_status_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying port status (LAN + WAN).
///
/// Extracted from [DashboardHomePortAndSpeed] for Bento Grid atomic usage.
class DashboardPorts extends ConsumerWidget {
  const DashboardPorts({
    super.key,
    this.direction,
  });

  /// Direction of port layout. If null, auto-detects based on width.
  final Axis? direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 150,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;

    // Auto-detect direction if not specified
    final effectiveDirection = direction ??
        (context.colWidth(6) > MediaQuery.of(context).size.width * 0.5
            ? Axis.vertical
            : Axis.horizontal);
    final isVertical = effectiveDirection == Axis.vertical;

    // Build LAN port widgets
    final lanPorts = state.lanPortConnections.mapIndexed((index, e) {
      final port = PortStatusWidget(
        connection: e == 'None' ? null : e,
        label: loc(context).indexedPort(index + 1),
        isWan: false,
        hasLanPorts: hasLanPort,
      );
      return isVertical
          ? Padding(padding: const EdgeInsets.only(bottom: 16.0), child: port)
          : Expanded(child: port);
    }).toList();

    // Build WAN port widget
    final wanPort = PortStatusWidget(
      connection:
          state.wanPortConnection == 'None' ? null : state.wanPortConnection,
      label: loc(context).wan,
      isWan: true,
      hasLanPorts: hasLanPort,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: isVertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...lanPorts,
                wanPort,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lanPorts,
                Expanded(child: wanPort),
              ],
            ),
    );
  }
}
