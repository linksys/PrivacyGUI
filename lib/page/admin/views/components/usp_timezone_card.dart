import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/utils/local_time_ticker.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
            widget.timeSettings.currentLocalTime ||
        oldWidget.timeSettings.localTimeZone !=
            widget.timeSettings.localTimeZone) {
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
              children: [
                // Expanded, not `spaceBetween` with an intrinsic title: the
                // trailing group is a status capsule plus a 40px icon button and
                // it is inflexible, so a `Row` handed it unbounded width and gave
                // the title whatever was left — over by up to 19px in `pl` at
                // 320px (#1380). Expanding the title right-aligns the group for
                // free and turns the overflow into a wrap, guarded for readability
                // in test/page/_shared/page_surface_overflow_test.dart.
                //
                // This is half of that fix. The other half is `usp_admin_view`
                // keeping one column through the tablet band: 15 more locales were
                // over here at 601px, and no amount of flex fits a heading into the
                // 75px two columns of a 601px screen left it.
                Expanded(child: AppText.titleMedium(loc(context).timezone)),
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
                    // On the button rather than around it — see the note at the
                    // same shape in `usp_time_settings_card.dart`.
                    AppIconButton(
                      icon: AppIcon.font(Icons.edit, size: 18),
                      semanticLabel: loc(context).editTimezoneSettings,
                      onTap: widget.onEdit,
                    ),
                  ],
                ),
              ],
            ),
            AppGap.md(),
            DetailInfoBlock(
              children: [
                DetailInfoTile(
                  icon: Icons.public,
                  label: loc(context).timezone,
                  value: tzDisplay,
                ),
                if (tzInfo != null && tzInfo.observesDST)
                  DetailInfoTile(
                    icon: Icons.wb_sunny,
                    label: loc(context).daylightSavingsTimeLabel,
                    value: dstEnabled ? 'On' : 'Off',
                  ),
                DetailInfoTile(
                  icon: Icons.dns,
                  label: loc(context).ntpServer,
                  value: widget.timeSettings.ntpServer1.isNotEmpty
                      ? widget.timeSettings.ntpServer1
                      : '—',
                ),
                DetailInfoTile(
                  icon: Icons.access_time,
                  label: loc(context).localTime,
                  value: timeDisplay,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
