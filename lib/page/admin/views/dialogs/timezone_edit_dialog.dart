import 'package:flutter/material.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows a dialog to select a timezone from a searchable list with DST toggle.
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

  return showSubmitAppDialog<TimezoneEditResult>(
    context,
    scrollable: false,
    useRootNavigator: false,
    title: 'Edit Timezone',
    width: 400,
    checkPositiveEnabled: () => selected != null,
    contentBuilder: (context, setState, onSubmit) {
      final filtered = searchQuery.isEmpty
          ? kTimeZoneDefinitions
          : kTimeZoneDefinitions.where((tz) {
              final query = searchQuery.toLowerCase();
              return tz.description.toLowerCase().contains(query) ||
                  tz.offsetDisplayText.toLowerCase().contains(query);
            }).toList();

      final dstToggleEnabled = selected?.observesDST ?? false;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search field
          AppTextFormField(
            key: const Key('timezoneSearchField'),
            hintText: 'Search timezone...',
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
                child: AppText.bodyMedium(
                    'Automatically adjust for Daylight Savings Time'),
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
            height: 340,
            child: filtered.isEmpty
                ? Center(
                    child: AppText.bodyMedium('No timezones found'),
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
        ],
      );
    },
    event: () async {
      return TimezoneEditResult(
        localTimeZone: selected!.posixFor(dstEnabled: dstEnabled),
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
    return InkWell(
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
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class TimezoneEditResult {
  final String localTimeZone;

  const TimezoneEditResult({
    required this.localTimeZone,
  });
}
