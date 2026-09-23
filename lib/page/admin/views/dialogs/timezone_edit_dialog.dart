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
/// Returns a [TimezoneEditResult] if saved, or null if cancelled.
Future<TimezoneEditResult?> showTimezoneEditDialog(
  BuildContext context, {
  required TimeSettingsUIModel current,
}) {
  final currentTz = resolveTimezone(
    zoneName: current.localTimeZoneName,
    localTimeZone: current.localTimeZone,
    reportedOffsetMinutes: current.reportedOffsetMinutes,
  );
  final currentDst = dstInEffect(
    zoneName: current.localTimeZoneName,
    localTimeZone: current.localTimeZone,
    reportedOffsetMinutes: current.reportedOffsetMinutes,
  );
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
          ? kTimeZoneDefinitions
          : kTimeZoneDefinitions.where((tz) {
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

      // Operable only where the firmware will take the string we would write —
      // see `TimeZoneInfo.standardTimePosix` for the four zones it will not.
      final canSwitch = selected?.canSwitchDstOff ?? false;

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
          // Daylight savings stays a switch (#1609), but what switching it off
          // *writes* has changed, and that is what makes it safe.
          //
          // It used to write `posixNoDST` — a bare `UTC±N`, an offset with no
          // identity. Eleven of those strings are each shared by two or three
          // zones, so the saved zone came back as whichever one `matchTimezone`
          // reached first: pick Eastern Time, switch daylight savings off, and
          // the card said "Indiana East, Colombia, Panama". It now writes
          // `standardTimePosix`, the zone's own abbreviation, which is
          // unambiguous because `matchTimezone` tries `timeZoneID` first and
          // these strings are the ids. The sibling non-DST zone is not in
          // competition either: it writes its IANA name, on the other leaf.
          //
          // Disabled on four zones the firmware will not take a standard-time
          // string for — see `TimeZoneInfo.standardTimePosix`.
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
                            // A zone that cannot report daylight savings, or
                            // cannot be switched out of it, must not carry a
                            // stale `true` into the save.
                            if (!tz.canSwitchDstOff) {
                              dstEnabled = tz.observesDST;
                            }
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
/// Top-level and pure so the dialog and its tests run the *same* code. It used to
/// live inline in the `event` callback with a copy of it in the test file, and the
/// copy was already an incomplete mirror — it omitted the legacy-POSIX fallback,
/// so a test for one of the three unnamed entries would have passed against
/// behaviour the dialog does not have.
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
  final zoneUnchanged = selected == currentTz && dstEnabled == currentDst;

  if (zoneUnchanged) {
    // Writing the resolved zone back when it was not chosen would commit a
    // guess: a legacy `UTC±N` is ambiguous — `UTC-8` resolves to Hong Kong
    // although it may have been saved as Singapore, and `UTC8` resolves to
    // Pacific although the string has no DST transitions in it. So an edit that
    // only touched the NTP server must leave the timezone leaves alone, and an
    // edit that touched nothing must write nothing at all.
    return ntpServer1 == null
        ? null
        : TimezoneEditResult.ntpOnly(ntpServer1: ntpServer1);
  }

  // Daylight savings off on a zone that observes it is the one case that goes out
  // as a POSIX string: there is no IANA zone meaning "Eastern Time but ignore the
  // DST rule", so the identity channel cannot express it. `standardTimePosix`
  // can, and unambiguously — `matchTimezone` tries `timeZoneID` first and these
  // strings are the ids.
  final offOnADstZone = selected.observesDST && !dstEnabled;
  final posix = offOnADstZone ? selected.standardTimePosix : null;

  return TimezoneEditResult(
    // The name otherwise, so the choice reads back as itself. Falls through to
    // the legacy POSIX form for the three entries whose own offset or DST flag
    // disagrees with the tz database and so have no faithful name. Never both —
    // the two leaves clobber each other in the firmware.
    zoneName: posix == null ? selected.ianaName : null,
    localTimeZone: posix ??
        (selected.ianaName == null
            ? selected.posixFor(dstEnabled: dstEnabled)
            : null),
    ntpServer1: ntpServer1,
  );
}

class TimezoneEditResult {
  /// The IANA zone name to write, when the chosen entry has one.
  final String? zoneName;

  /// The POSIX string to write instead, for an entry with no IANA name.
  final String? localTimeZone;

  final String? ntpServer1;

  /// Exactly one timezone leaf, because the firmware wires them to clobber each
  /// other — see `UspAdminService.updateTimezone`.
  const TimezoneEditResult({
    this.zoneName,
    this.localTimeZone,
    this.ntpServer1,
  }) : assert(
          (zoneName == null) != (localTimeZone == null),
          'exactly one timezone leaf is written — see UspAdminService',
        );

  /// The zone was not changed, so neither leaf is written.
  ///
  /// A separate constructor rather than a third null: the invariant above is
  /// what stops an ambiguous legacy value being committed as a guess, and
  /// relaxing it would let that back in silently.
  const TimezoneEditResult.ntpOnly({this.ntpServer1})
      : zoneName = null,
        localTimeZone = null;
}
