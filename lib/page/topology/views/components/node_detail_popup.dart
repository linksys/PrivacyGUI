import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared popup content for mesh node details.
///
/// Used by both Dashboard topology card and Topology page.
class NodeDetailPopup extends StatelessWidget {
  final MeshNode node;
  final Map<String, dynamic>? metadata;
  final bool showDetailsButton;
  final VoidCallback? onDetailsTap;

  const NodeDetailPopup({
    super.key,
    required this.node,
    this.metadata,
    this.showDetailsButton = false,
    this.onDetailsTap,
  });

  /// Factory for use with AppTopology's detailBuilder.
  static Widget builder(
    BuildContext context,
    MeshNode node,
    Map<String, dynamic>? metadata, {
    bool showDetailsButton = false,
  }) {
    return NodeDetailPopup(
      node: node,
      metadata: metadata,
      showDetailsButton: showDetailsButton,
      onDetailsTap: showDetailsButton
          ? () {
              final deviceId = metadata?['deviceId'] as String? ?? '';
              if (deviceId.isNotEmpty) {
                GoRouter.of(context).pushNamed(
                  RouteNamed.uspNodeDetail,
                  queryParameters: {'deviceId': deviceId},
                );
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceId = metadata?['deviceId'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    final manufacturer = metadata?['manufacturer'] as String? ?? '';
    final serialNumber = metadata?['serialNumber'] as String? ?? '';
    final softwareVersion = metadata?['softwareVersion'] as String? ?? '';
    final isMaster = metadata?['isMaster'] as bool? ?? false;

    // Backhaul info for Slave nodes
    final backhaulLinkType = metadata?['backhaulLinkType'] as String?;
    final backhaulSignalStrength = metadata?['backhaulSignalStrength'] as int?;
    final backhaulUplinkRate = metadata?['backhaulUplinkRate'] as int?;
    final backhaulDownlinkRate = metadata?['backhaulDownlinkRate'] as int?;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(loc(context).role,
            isMaster ? loc(context).master : loc(context).slave),
        if (deviceId.isNotEmpty && deviceId.toUpperCase() != 'GATEWAY')
          _row('MAC', deviceId),
        if (model.isNotEmpty) _row(loc(context).model, model),
        if (manufacturer.isNotEmpty)
          _row(loc(context).manufacturer, manufacturer),
        if (serialNumber.isNotEmpty) _row('S/N', serialNumber),
        if (softwareVersion.isNotEmpty)
          _row(loc(context).firmware, softwareVersion),
        // Backhaul info for Slave nodes
        if (!isMaster) ...[
          if (backhaulLinkType != null && backhaulLinkType.isNotEmpty)
            _row('Backhaul', backhaulLinkType),
          if (backhaulSignalStrength != null && backhaulLinkType != 'Ethernet')
            _row('Signal', '$backhaulSignalStrength dBm'),
          if (backhaulUplinkRate != null && backhaulDownlinkRate != null)
            _row(
              'Speed',
              'Up: ${NetworkUtils.formatSpeed(backhaulUplinkRate)} / '
                  'Down: ${NetworkUtils.formatSpeed(backhaulDownlinkRate)}',
            )
          else if (backhaulUplinkRate != null)
            _row('Speed', 'Up: ${NetworkUtils.formatSpeed(backhaulUplinkRate)}')
          else if (backhaulDownlinkRate != null)
            _row('Speed',
                'Down: ${NetworkUtils.formatSpeed(backhaulDownlinkRate)}'),
        ],
        // Details button (optional)
        if (showDetailsButton && node.status == MeshNodeStatus.online)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: AppButton.text(
                label: loc(context).details,
                onTap: onDetailsTap,
                identifier: 'topology-node-detail-button',
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: AppText.bodySmall(label, color: Colors.grey),
          ),
          Expanded(child: AppText.bodySmall(value)),
        ],
      ),
    );
  }
}
