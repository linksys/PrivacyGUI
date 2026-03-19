import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

Future<void> showEthernetPortDetailDialog(
  BuildContext context,
  EthernetPortUIModel port,
) {
  return showSimpleAppDialog(
    context,
    title: port.label,
    content: _EthernetPortDetailContent(port: port),
    actions: [
      AppButton.text(
        label: 'Close',
        onTap: () => context.pop(),
      ),
    ],
  );
}

class _EthernetPortDetailContent extends StatelessWidget {
  final EthernetPortUIModel port;

  const _EthernetPortDetailContent({required this.port});

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UspInfoRow(label: 'Interface', value: port.name),
        UspInfoRow(label: 'Status', value: port.isUp ? 'Up' : 'Down'),
        UspInfoRow(label: 'Speed', value: port.speedLabel),
        if (port.connectedDevices.isNotEmpty) ...[
          AppGap.md(),
          AppText.labelLarge('Connected Devices'),
          AppGap.sm(),
          ...port.connectedDevices.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(d.displayName),
                    if (d.macAddress.isNotEmpty)
                      AppText.bodySmall(
                        'MAC  ${d.macAddress}',
                        color: secondaryTextColor,
                      ),
                    if (d.ipAddress.isNotEmpty)
                      AppText.bodySmall(
                        'IP  ${d.ipAddress}',
                        color: secondaryTextColor,
                      ),
                  ],
                ),
              )),
        ] else if (!port.isWan) ...[
          AppGap.md(),
          AppText.bodySmall(
            'No connected devices',
            color: secondaryTextColor,
          ),
        ],
      ],
    );
  }
}
