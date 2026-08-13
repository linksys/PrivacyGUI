import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/utils/local_time_ticker.dart';
import 'package:privacy_gui/page/admin/views/dialogs/timezone_edit_dialog.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspTimeSettingsCard extends ConsumerStatefulWidget {
  const UspTimeSettingsCard({super.key});

  @override
  ConsumerState<UspTimeSettingsCard> createState() =>
      _UspTimeSettingsCardState();
}

class _UspTimeSettingsCardState extends ConsumerState<UspTimeSettingsCard>
    with LocalTimeTicker {
  String? _lastRawTime;
  String? _lastTimeZone;

  void _syncIfChanged(TimeData timeData) {
    if (timeData.model.currentLocalTime == _lastRawTime &&
        timeData.model.localTimeZone == _lastTimeZone) {
      return;
    }
    _lastRawTime = timeData.model.currentLocalTime;
    _lastTimeZone = timeData.model.localTimeZone;
    syncTime(timeData.model.parsedLocalTime, fetchedAt: timeData.fetchedAt);
  }

  @override
  void dispose() {
    disposeTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeData = ref.watch(timeDataProvider).valueOrNull;
    if (timeData == null) return const CardSkeleton.info(rows: 2);
    final time = timeData.model;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'time';
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    _syncIfChanged(timeData);

    final tzInfo = matchTimezone(time.localTimeZone);
    final tzDisplay = tzInfo != null
        ? tzInfo.friendlyName
        : time.localTimeZone.isNotEmpty
            ? time.localTimeZone
            : 'Not set';
    final offsetDisplay = tzInfo?.offsetDisplayText ?? '';

    final timeDisplay = currentTime != null
        ? TimeSettingsUIModel.formatDateTime(currentTime!)
        : time.formattedDateTime;

    return DashboardCardTemplate(
      title: loc(context).timeSettings,
      trailing: Semantics(
        label: loc(context).editTimeSettings,
        button: true,
        child: AppIconButton(
          icon: AppIcon.font(Icons.edit, size: 18),
          onTap: isLoading ? null : () => _editTimezone(context, ref, time),
        ),
      ),
      detailRoute: RouteNamed.uspAdmin,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero block - Clock with current time
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon.font(
                    Icons.schedule,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                AppGap.lg(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleLarge(timeDisplay),
                      AppGap.xxs(),
                      // Same shape as `usp_lan_info_card`'s hero row and the
                      // same 61.4px column, but the fix is the opposite one,
                      // because a capsule cannot take a second line: `AppBadge`
                      // already ellipsizes its own label (`Flexible` +
                      // `maxLines: 1` inside it) and only ever failed to,
                      // because this single-child `Row` handed it *unbounded*
                      // width and its inner `Flexible` had nothing to bind
                      // against. The `Row` did nothing else — the enclosing
                      // `Column` is already `CrossAxisAlignment.start`, so the
                      // badge shrink-wraps identically without it — so it is
                      // removed rather than given a `Flexible`. §2.10a point 2's
                      // ellipsis-vs-wrap choice, decided by what the child *is*.
                      AppBadge(
                        label: time.isSynchronized
                            ? loc(context).synchronized
                            : time.status,
                        color: time.isSynchronized
                            ? appColors?.semanticSuccess
                            : appColors?.semanticWarning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppGap.sm(),
          // Timezone info
          InfoGrid(
            items: [
              InfoGridItem(label: loc(context).timezone, value: tzDisplay),
              if (offsetDisplay.isNotEmpty)
                InfoGridItem(
                    label: loc(context).utcOffset, value: offsetDisplay),
              if (tzInfo != null && tzInfo.observesDST)
                InfoGridItem(
                  // Deliberately unlocalized, and recorded as arguable in
                  // §2.10d point 6 rather than fixed here: unlike the `Enabled`
                  // value on `lan_info`, `DST` has no ARB key, so localizing it
                  // means adding one plus 26 translations — and several locales
                  // spell it as a word rather than an initialism
                  // (`Sommerzeit`), which is a width change in a cell this
                  // branch has not measured. The value beside it is localized.
                  label: 'DST',
                  value: inferDstEnabled(time.localTimeZone)
                      ? loc(context).on
                      : loc(context).off,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editTimezone(
      BuildContext context, WidgetRef ref, TimeSettingsUIModel settings) async {
    final result = await showTimezoneEditDialog(
      context,
      current: settings,
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'time',
      mutation: () => ref.read(uspAdminProvider.notifier).updateTimezone(
            localTimeZone: result.localTimeZone,
            ntpServer1: result.ntpServer1,
          ),
      successMessage: loc(context).timeSettingsSaved,
    );
  }
}
