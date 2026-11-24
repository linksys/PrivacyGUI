import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/usp_formatters.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A device's Download and Upload totals on the device detail page's
/// connection card (#1927).
///
/// The bytes the device received and sent through the router, from its Hosts
/// rows' `WANStats`, added up over every interface it is shown with. They are
/// a running total, not a rate: FL-WRT 2.0 adds a connection only once it has
/// ended plus about 2 minutes, and counts traffic to the router itself too,
/// so the labels say Download and Upload, never internet or WAN use.
///
/// A null total has no row. The caller shows this widget only for a device
/// with `ClientDevice.hasDataUsed`, so a device the router has no counter
/// for has no rows at all.
class DeviceDataUsedTiles extends StatelessWidget {
  /// Bytes received over every interface (`ClientDevice.totalBytesReceived`).
  final int? bytesReceived;

  /// Bytes sent over every interface (`ClientDevice.totalBytesSent`).
  final int? bytesSent;

  const DeviceDataUsedTiles({
    super.key,
    required this.bytesReceived,
    required this.bytesSent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bytesReceived != null)
          DetailInfoTile(
            icon: Icons.arrow_downward,
            label: loc(context).download,
            value: UspFormatters.formatBytes(bytesReceived!),
          ),
        if (bytesReceived != null && bytesSent != null) AppGap.md(),
        if (bytesSent != null)
          DetailInfoTile(
            icon: Icons.arrow_upward,
            label: loc(context).upload,
            value: UspFormatters.formatBytes(bytesSent!),
          ),
        AppGap.sm(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.restart_alt,
                size: 16, color: colorScheme.onSurfaceVariant),
            AppGap.sm(),
            Expanded(
              child: AppText.bodySmall(
                loc(context).sinceRouterLastRestarted,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
