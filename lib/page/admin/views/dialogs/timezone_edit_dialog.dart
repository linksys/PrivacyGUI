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
  final currentTz = matchTimezone(current.localTimeZone);
  TimeZoneInfo? selected = currentTz;
  bool dstEnabled = inferDstEnabled(current.localTimeZone);
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

      final dstToggleEnabled = selected?.observesDST ?? false;

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
          // DST toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.bodyMedium(loc(context).daylightSavingsTime),
              ),
              AppSwitch(
                key: const Key('dstToggle'),
                value: dstEnabled,
                onChanged: dstToggleEnabled
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
                            if (!tz.observesDST) {
                              dstEnabled = false;
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
    event: () async {
      final ntpValue = ntpController.text.trim();
      return TimezoneEditResult(
        localTimeZone: selected!.posixFor(dstEnabled: dstEnabled),
        ntpServer1: ntpValue != current.ntpServer1 ? ntpValue : null,
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
          label: 'Advanced settings',
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
  final String localTimeZone;
  final String? ntpServer1;

  const TimezoneEditResult({
    required this.localTimeZone,
    this.ntpServer1,
  });
}
