import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
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

    _syncIfChanged(timeData);

    final tzInfo = matchTimezone(time.localTimeZone);
    final tzDisplay = tzInfo != null
        ? '${tzInfo.friendlyName} (${tzInfo.offsetDisplayText})'
        : time.localTimeZone.isNotEmpty
            ? time.localTimeZone
            : 'Not set';

    final timeDisplay = currentTime != null
        ? TimeSettingsUIModel.formatDateTime(currentTime!)
        : time.formattedDateTime;

    return DashboardCardTemplate(
      title: 'Time Settings',
      titleBadge: AppBadge(
        label: time.status,
        color: time.isSynchronized
            ? Theme.of(context).extension<AppColorScheme>()?.semanticSuccess
            : Theme.of(context).extension<AppColorScheme>()?.semanticWarning,
      ),
      trailing: Semantics(
        label: 'Edit time settings',
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
          UspInfoRow(label: 'Timezone', value: tzDisplay),
          if (tzInfo != null && tzInfo.observesDST)
            UspInfoRow(
              label: 'Daylight Savings Time',
              value: inferDstEnabled(time.localTimeZone) ? 'On' : 'Off',
            ),
          UspInfoRow(
            label: 'Local Time',
            value: timeDisplay,
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
      successMessage: 'Time settings saved',
    );
  }
}
