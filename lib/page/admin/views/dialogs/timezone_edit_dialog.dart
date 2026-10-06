import 'package:flutter/material.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows a dialog to select a timezone from a searchable list with DST toggle
/// and an optional Advanced section for NTP server configuration.
///
/// [zones] is the list to offer — the device's own catalogue
/// (`timeZoneCatalogueProvider`, linksys/FWDEV#198) — and the caller resolves
/// its card against the same list, so the preselection matches what the card
/// shows. Required, with no default: a default would let a caller skip the
/// device catalogue without noticing.
///
/// Returns a [TimezoneEditResult] if saved, or null if cancelled.
Future<TimezoneEditResult?> showTimezoneEditDialog(
  BuildContext context, {
  required TimeSettingsUIModel current,
  required List<TimeZoneInfo> zones,
}) {
  final resolved = resolveCurrentTimezone(current, zones: zones);
  final currentTz = resolved.zone;
  final currentDst = resolved.dstOn;
  TimeZoneInfo? selected = currentTz;
  bool dstEnabled = currentDst;
  String searchQuery = '';
  bool advancedExpanded = false;
  final ntpController = TextEditingController(text: current.ntpServer1);

  return showSubmitAppDialog<TimezoneEditResult?>(
    context,
    scrollable: false,
    useRootNavigator: false,
    title: loc(context).editTimezone,
    checkPositiveEnabled: () => selected != null,
    contentBuilder: (context, setState, onSubmit) {
      final filtered = searchQuery.isEmpty
          ? zones
          : zones.where((tz) {
              final query = searchQuery.toLowerCase();
              final desc = tz.description.toLowerCase();
              final offset = tz.offsetDisplayText.toLowerCase();
              if (desc.contains(query) || offset.contains(query)) return true;
              // Allow "+8" to match "+08", "-5" to match "-05", etc.
              final m = RegExp(r'^[+-](\d{1,2})$').firstMatch(query);
              if (m != null) {
                final padded = query[0] + m.group(1)!.padLeft(2, '0');
                return offset.contains(padded);
              }
              return false;
            }).toList();

      // Operable only on a zone that observes DST: the firmware refuses DST on
      // for one that does not (ErrorTimeZoneDoesNotObserveDST).
      final canSwitch = selected?.observesDST ?? false;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search field
          AppTextFormField(
            key: const Key('timezoneSearchField'),
            hintText: loc(context).searchTimezone,
            prefixIcon: const Icon(Icons.search, size: 20),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          AppGap.md(),
          // Saved with the zone in one `SetTimeSettings` call, so switching it
          // off keeps the zone's own ID and only sends DST false — Eastern Time
          // with DST off stays Eastern Time (linksys/FWDEV#198).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.bodyMedium(loc(context).daylightSavingsTime),
              ),
              AppSwitch(
                key: const Key('dstToggle'),
                identifier: 'admin-timezone-dst',
                value: dstEnabled,
                onChanged: canSwitch
                    ? (value) {
                        setState(() {
                          dstEnabled = value;
                        });
                      }
                    : null,
              ),
            ],
          ),
          AppGap.md(),
          // Timezone list
          SizedBox(
            height: 300,
            child: filtered.isEmpty
                ? Center(
                    child: AppText.bodyMedium(loc(context).noTimezonesFound),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tz = filtered[index];
                      final isSelected = tz == selected;
                      return _TimezoneListTile(
                        timezone: tz,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            selected = tz;
                            // A zone without daylight savings must not carry a
                            // stale `true` into the save.
                            if (!tz.observesDST) dstEnabled = false;
                          });
                        },
                      );
                    },
                  ),
          ),
          // Advanced section (collapsible)
          _AdvancedSection(
            expanded: advancedExpanded,
            onToggle: () {
              setState(() {
                advancedExpanded = !advancedExpanded;
              });
            },
            ntpController: ntpController,
          ),
        ],
      );
    },
    event: () async => buildTimezoneEditResult(
      selected: selected!,
      dstEnabled: dstEnabled,
      currentTz: currentTz,
      currentDst: currentDst,
      ntpValue: ntpController.text.trim(),
      currentNtp: current.ntpServer1,
    ),
  );
}

class _TimezoneListTile extends StatelessWidget {
  final TimeZoneInfo timezone;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimezoneListTile({
    required this.timezone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'admin-timezone-item-${timezone.timeZoneID}',
      label: '${timezone.friendlyName}, ${timezone.offsetDisplayText}',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(timezone.friendlyName),
                    AppText.bodySmall(
                      timezone.offsetDisplayText,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController ntpController;

  const _AdvancedSection({
    required this.expanded,
    required this.onToggle,
    required this.ntpController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: loc(context).advancedSettings,
          expanded: expanded,
          button: true,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ),
                  AppGap.xs(),
                  AppText.labelLarge(loc(context).advanced),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          AppGap.sm(),
          AppTextFormField(
            key: const Key('ntpServerField'),
            controller: ntpController,
            label: loc(context).ntpServer,
          ),
        ],
      ],
    );
  }
}

/// Decides what a Save should write, or that it should write nothing.
///
/// Top-level and pure so the dialog and its tests run the *same* code.
///
/// Returns null when nothing changed at all. That is not a shortcut: both call
/// sites already guard `result == null` for a cancelled dialog, and "you pressed
/// Save but changed nothing" needs exactly the same handling. Returning an
/// all-null [TimezoneEditResult] instead is what made a no-change Save reach
/// `updateTimezone`, trip its nothing-to-write guard, and show the user a failure
/// snackbar for a normal interaction.
TimezoneEditResult? buildTimezoneEditResult({
  required TimeZoneInfo selected,
  required bool dstEnabled,
  required TimeZoneInfo? currentTz,
  required bool currentDst,
  required String ntpValue,
  required String currentNtp,
}) {
  final ntpServer1 = ntpValue != currentNtp ? ntpValue : null;
  // A zone without DST is saved with DST false whatever the switch last held:
  // the firmware refuses `true` for it (ErrorTimeZoneDoesNotObserveDST).
  final dstToSave = selected.observesDST && dstEnabled;
  final zoneUnchanged = selected == currentTz && dstToSave == currentDst;

  if (zoneUnchanged) {
    // Writing the resolved zone back when it was not chosen would commit a
    // guess: when the device cannot name its zone, the one shown is our own
    // resolution of it. So an edit that only touched the NTP server must leave
    // the zone alone, and an edit that touched nothing must write nothing at all.
    return ntpServer1 == null
        ? null
        : TimezoneEditResult.ntpOnly(ntpServer1: ntpServer1);
  }

  return TimezoneEditResult(
    // Sent verbatim — a zone without DST keeps its -NO-DST suffix, and the bare
    // standard string is ErrorUnknownTimeZone on the device.
    zone: (id: selected.timeZoneID, autoAdjustForDst: dstToSave),
    ntpServer1: ntpServer1,
  );
}

class TimezoneEditResult {
  /// The zone and DST setting to save through `SetTimeSettings`, or null when
  /// the zone was not changed.
  final TimeZoneSelection? zone;

  final String? ntpServer1;

  /// A zone change, saved through `SetTimeSettings` with its DST setting.
  const TimezoneEditResult(
      {required TimeZoneSelection this.zone, this.ntpServer1});

  /// The zone was not changed, so it is not written.
  ///
  /// A separate constructor rather than a nullable [zone] parameter: it is what
  /// stops a zone the device could not name being committed as a guess.
  const TimezoneEditResult.ntpOnly({this.ntpServer1}) : zone = null;
}
