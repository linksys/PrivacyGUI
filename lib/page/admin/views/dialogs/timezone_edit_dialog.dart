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
  TimeZoneInfo? selected = currentTz;
  String searchQuery = '';
  bool advancedExpanded = false;
  final ntpController = TextEditingController(text: current.ntpServer1);

  return showSubmitAppDialog<TimezoneEditResult>(
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

      // Whether the *selected* zone observes DST, which is all this row says
      // now — see the switch below.
      final observesDST = selected?.observesDST ?? false;

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
          // Daylight savings, as a read-only property of the selected zone
          // rather than a switch (#1609).
          //
          // It used to be writable, and that is what made a saved zone come
          // back wearing another zone's name. Switching it off wrote the
          // zone's no-DST POSIX string — and "Eastern Time without DST" is not
          // a distinguishable thing: it is the same clock rule as Panama, which
          // is exactly what the device's own `EST5` row is. So the zone read
          // back as Panama. Six of the eleven collisions could not be spelled
          // apart by any POSIX string for that reason.
          //
          // The list already carries both variants as separate entries, so
          // nothing is lost: "Eastern Time (USA & Canada)" and "Indiana East,
          // Colombia, Panama" are both there to pick. 1.x worked this way too —
          // its 40 zone ids bake DST into the entry and it had no switch. What
          // this removes is a capability 2.x invented, and with it an input the
          // data model cannot represent.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.bodyMedium(loc(context).daylightSavingsTime),
              ),
              // The `AppSwitch` this replaced carried `identifier:
              // 'admin-timezone-dst'`, and that identifier is deliberately not
              // carried over. It has no references in this repo, but the E2E
              // specs live in another one and harvest identifiers out of Dart
              // source text, so a spec may well tap it. Keeping the name on a
              // node that no longer does anything would make that spec tap a
              // dead control and fail somewhere unrelated — or pass vacuously.
              // Dropping it makes the lookup fail and point straight here. Any
              // spec that toggled daylight savings has to change regardless,
              // because the toggle is gone.
              KeyedSubtree(
                key: const Key('dstIndicator'),
                child: AppText.bodyMedium(
                  observesDST ? loc(context).on : loc(context).off,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
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
    event: () async {
      final ntpValue = ntpController.text.trim();
      final tz = selected!;
      final ntpServer1 = ntpValue != current.ntpServer1 ? ntpValue : null;

      // Writing nothing when the zone was not changed is load-bearing, not an
      // optimisation (#1609). The device may be holding a legacy `UTC±N`, which
      // is ambiguous — `UTC-8` resolves to Hong Kong although it may have been
      // saved as Singapore, and `UTC8` resolves to Pacific although the string
      // has no DST transitions in it. Writing the resolved zone's name back
      // would commit that guess: an edit that only touched the NTP server would
      // permanently relabel a Singapore router as Hong Kong, and switch daylight
      // savings on for a router deliberately left at fixed UTC-8.
      if (tz == currentTz) {
        return TimezoneEditResult.ntpOnly(ntpServer1: ntpServer1);
      }

      return TimezoneEditResult(
        // The name when the entry has one, so the choice reads back as itself;
        // the POSIX string for the three entries whose own offset or DST flag
        // disagrees with the tz database. Never both — they clobber each other
        // in the firmware (#1609).
        zoneName: tz.ianaName,
        localTimeZone: tz.ianaName == null
            ? tz.posixFor(dstEnabled: tz.observesDST)
            : null,
        ntpServer1: ntpServer1,
      );
    },
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
