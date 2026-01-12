import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A widget that displays a network port status with connection speed.
class PortStatusWidget extends StatelessWidget {
  const PortStatusWidget({
    super.key,
    required this.connection,
    required this.label,
    required this.isWan,
    required this.hasLanPorts,
  });

  /// The connection speed string (e.g., "1Gbps"), or null if disconnected.
  final String? connection;

  /// The label for this port (e.g., "LAN 1", "WAN").
  final String label;

  /// Whether this is a WAN port.
  final bool isWan;

  /// Whether the device has LAN ports (affects layout).
  final bool hasLanPorts;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileLayout;

    // Build port label with status icon
    final portLabelWidgets = [
      AppIcon.font(
        connection == null
            ? AppFontIcons.circle
            : AppFontIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.green,
      ),
      if (hasLanPorts) ...[
        AppGap.sm(),
        AppText.labelMedium(label),
      ],
    ];

    // Port image - use colorFilter for connected state (green)
    final isConnected = connection != null;
    final portColor = isConnected
        ? Theme.of(context).extension<AppColorScheme>()?.semanticSuccess ??
            Colors.green
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    final portImage = Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: isConnected
          ? Assets.images.imgPortOn.svg(
              width: 40,
              height: 40,
              colorFilter: ColorFilter.mode(portColor, BlendMode.srcIn),
              semanticsLabel: 'port status image',
            )
          : Assets.images.imgPortOff.svg(
              width: 40,
              height: 40,
              colorFilter: ColorFilter.mode(portColor, BlendMode.srcIn),
              semanticsLabel: 'port status image',
            ),
    );

    // Connection speed info
    Widget? connectionInfo;
    if (connection != null) {
      connectionInfo = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            hasLanPorts ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(
                AppFontIcons.bidirectional,
                color: Theme.of(context).colorScheme.primary,
              ),
              hasLanPorts
                  ? AppText.bodySmall(connection!)
                  : AppText.bodyMedium(connection!),
            ],
          ),
          AppText.bodySmall(
            loc(context).connectedSpeed,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // WAN label
    final wanLabel = isWan ? AppText.labelMedium(loc(context).internet) : null;

    // Build appropriate layout based on hasLanPorts
    if (hasLanPorts) {
      return _buildVerticalLayout(
        context,
        isMobile,
        portLabelWidgets,
        portImage,
        connectionInfo,
        wanLabel,
      );
    } else {
      return _buildHorizontalLayout(
        context,
        isMobile,
        portLabelWidgets,
        portImage,
        connectionInfo,
        wanLabel,
      );
    }
  }

  Widget _buildVerticalLayout(
    BuildContext context,
    bool isMobile,
    List<Widget> portLabelWidgets,
    Widget portImage,
    Widget? connectionInfo,
    Widget? wanLabel,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            isMobile
                ? Column(children: portLabelWidgets)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: portLabelWidgets,
                  ),
          ],
        ),
        portImage,
        if (connectionInfo != null) connectionInfo,
        if (wanLabel != null) wanLabel,
      ],
    );
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    bool isMobile,
    List<Widget> portLabelWidgets,
    Widget portImage,
    Widget? connectionInfo,
    Widget? wanLabel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                isMobile
                    ? Column(children: portLabelWidgets)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: portLabelWidgets,
                      ),
              ],
            ),
            portImage,
          ],
        ),
        AppGap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (connectionInfo != null) connectionInfo,
              if (wanLabel != null) wanLabel,
            ],
          ),
        ),
      ],
    );
  }
}
