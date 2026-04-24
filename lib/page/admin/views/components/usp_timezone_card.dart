import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/utils/local_time_ticker.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspTimezoneCard extends StatefulWidget {
  final TimeSettingsUIModel timeSettings;
  final DateTime? fetchedAt;
  final VoidCallback onEdit;

  const UspTimezoneCard({
    super.key,
    required this.timeSettings,
    this.fetchedAt,
    required this.onEdit,
  });

  @override
  State<UspTimezoneCard> createState() => _UspTimezoneCardState();
}

class _UspTimezoneCardState extends State<UspTimezoneCard>
    with LocalTimeTicker {
  @override
  void initState() {
    super.initState();
    syncTime(widget.timeSettings.parsedLocalTime, fetchedAt: widget.fetchedAt);
  }

  @override
  void didUpdateWidget(UspTimezoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeSettings.currentLocalTime !=
        widget.timeSettings.currentLocalTime) {
      syncTime(widget.timeSettings.parsedLocalTime,
          fetchedAt: widget.fetchedAt);
    }
  }

  @override
  void dispose() {
    disposeTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tzInfo = matchTimezone(widget.timeSettings.localTimeZone);
    final dstEnabled = inferDstEnabled(widget.timeSettings.localTimeZone);
    final tzDisplay = tzInfo != null
        ? '${tzInfo.friendlyName} (${tzInfo.offsetDisplayText})'
        : widget.timeSettings.localTimeZone.isNotEmpty
            ? widget.timeSettings.localTimeZone
            : 'Not set';

    final timeDisplay = currentTime != null
        ? TimeSettingsUIModel.formatDateTime(currentTime!)
        : widget.timeSettings.formattedDateTime;

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
                Row(
                  children: [
                    AppBadge(
                      label: widget.timeSettings.status,
                      color: widget.timeSettings.isSynchronized
                          ? Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticSuccess
                          : Theme.of(context)
                              .extension<AppColorScheme>()
                              ?.semanticWarning,
                    ),
                    AppGap.sm(),
                    Semantics(
                      label: 'Edit timezone settings',
                      button: true,
                      child: AppIconButton(
                        icon: AppIcon.font(Icons.edit, size: 18),
                        onTap: widget.onEdit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppGap.xl(),
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
              value: widget.timeSettings.ntpServer1.isNotEmpty
                  ? widget.timeSettings.ntpServer1
                  : '—',
            ),
            UspInfoRow(
              label: 'Local Time',
              value: timeDisplay,
            ),
          ],
        ),
      ),
    );
  }
}
