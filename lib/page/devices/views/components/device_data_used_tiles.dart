import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/usp_formatters.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart'
    hide ConnectionType;
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
/// A device shown across interfaces also gets an (i) at the end of the
/// caption. It opens each interface's own counters, so the card keeps one
/// total.
///
/// A null total has no row. The caller shows this widget only for a device
/// with [ClientDevice.hasDataUsed], so a device the router has no counter
/// for has no rows at all.
class DeviceDataUsedTiles extends StatelessWidget {
  final ClientDevice device;

  const DeviceDataUsedTiles({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final received = device.totalBytesReceived;
    final sent = device.totalBytesSent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (received != null)
          DetailInfoTile(
            icon: Icons.arrow_downward,
            label: loc(context).download,
            value: UspFormatters.formatBytes(received),
          ),
        if (received != null && sent != null) AppGap.md(),
        if (sent != null)
          DetailInfoTile(
            icon: Icons.arrow_upward,
            label: loc(context).upload,
            value: UspFormatters.formatBytes(sent),
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
            if (device.hasMultipleInterfaces) ...[
              AppGap.sm(),
              _PerInterfaceInfo(device: device),
            ],
          ],
        ),
      ],
    );
  }
}

/// `(i)`: each interface's own Download and Upload, one Hosts row each. Opens
/// on tap as well as on hover, so it works on touch. A row with no counter
/// reads "—".
class _PerInterfaceInfo extends StatelessWidget {
  const _PerInterfaceInfo({required this.device});

  final ClientDevice device;

  static const _absentValue = '—';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = Theme.of(context)
        .extension<AppDesignTheme>()
        ?.surfaceElevated
        .contentColor;
    final rows = [
      (
        isWifi: device.isWifi,
        mac: device.mac,
        received: device.bytesReceived,
        sent: device.bytesSent
      ),
      for (final interface in device.additionalInterfaces)
        (
          isWifi: interface.isWifi,
          mac: interface.mac,
          received: interface.bytesReceived,
          sent: interface.bytesSent,
        ),
    ];
    String bytes(int? value) =>
        value == null ? _absentValue : UspFormatters.formatBytes(value);

    return Semantics(
      identifier: 'device-detail-data-used-per-interface',
      child: AppTooltip(
        // To the left: the (i) ends the caption's row at the card's right
        // edge, so a tooltip opening up or right is cut off by a phone's
        // screen (measured at 320px).
        position: AxisDirection.left,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) AppGap.sm(),
              AppText.labelSmall(
                '${rows[i].isWifi ? loc(context).wifi : loc(context).ethernet}'
                ' · ${rows[i].mac}',
                color: contentColor,
              ),
              AppGap.xxs(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward, size: 14, color: contentColor),
                  AppGap.xxs(),
                  AppText.bodySmall(bytes(rows[i].received),
                      color: contentColor),
                  AppGap.md(),
                  Icon(Icons.arrow_upward, size: 14, color: contentColor),
                  AppGap.xxs(),
                  AppText.bodySmall(bytes(rows[i].sent), color: contentColor),
                ],
              ),
            ],
          ],
        ),
        child: AppIcon.font(
          Icons.info_outline,
          size: BlockConstants.iconSm,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
