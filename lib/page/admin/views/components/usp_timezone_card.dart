import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspTimezoneCard extends StatelessWidget {
  final TimeSettingsUIModel timeSettings;
  final VoidCallback onEdit;

  const UspTimezoneCard({
    super.key,
    required this.timeSettings,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tzInfo = matchTimezone(timeSettings.localTimeZone);
    final dstEnabled = inferDstEnabled(timeSettings.localTimeZone);
    final tzDisplay = tzInfo != null
        ? '${tzInfo.friendlyName} (${tzInfo.offsetDisplayText})'
        : timeSettings.localTimeZone.isNotEmpty
            ? timeSettings.localTimeZone
            : 'Not set';

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.titleMedium('Timezone'),
                Semantics(
                  label: 'Edit timezone settings',
                  button: true,
                  child: AppIconButton(
                    icon: AppIcon.font(Icons.chevron_right),
                    onTap: onEdit,
                  ),
                ),
              ],
            ),
            AppGap.md(),
            UspInfoRow(
              label: 'Timezone',
              value: tzDisplay,
            ),
            if (tzInfo != null && tzInfo.observesDST)
              UspInfoRow(
                label: 'Daylight Savings Time',
                value: dstEnabled ? 'On' : 'Off',
              ),
            UspInfoRow(
              label: 'NTP Server',
              value: timeSettings.ntpServer1.isNotEmpty
                  ? timeSettings.ntpServer1
                  : '—',
            ),
            UspInfoRow(
              label: 'Status',
              value: timeSettings.status,
            ),
          ],
        ),
      ),
    );
  }
}
