import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/admin/views/dialogs/timezone_edit_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspTimeSettingsCard extends ConsumerWidget {
  const UspTimeSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeData = ref.watch(timeDataProvider).valueOrNull;
    if (timeData == null) return const CardSkeleton.info(rows: 2);
    final time = timeData.model;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'time';

    final tzInfo = matchTimezone(time.localTimeZone);
    final tzDisplay = tzInfo != null
        ? '${tzInfo.friendlyName} (${tzInfo.offsetDisplayText})'
        : time.localTimeZone.isNotEmpty
            ? time.localTimeZone
            : 'Not set';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Time Settings'),
              Row(
                children: [
                  AppBadge(
                    label: time.status,
                    color: time.isSynchronized
                        ? Theme.of(context)
                            .extension<AppColorScheme>()
                            ?.semanticSuccess
                        : Theme.of(context)
                            .extension<AppColorScheme>()
                            ?.semanticWarning,
                  ),
                  AppGap.sm(),
                  Semantics(
                    label: 'Edit time settings',
                    button: true,
                    child: AppIconButton(
                      icon: AppIcon.font(Icons.edit, size: 18),
                      onTap: isLoading
                          ? null
                          : () => _editTimezone(context, ref, time),
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          UspInfoRow(label: 'Timezone', value: tzDisplay),
          if (tzInfo != null && tzInfo.observesDST)
            UspInfoRow(
              label: 'Daylight Savings Time',
              value: inferDstEnabled(time.localTimeZone) ? 'On' : 'Off',
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
      mutation: () async {
        await ref.read(uspAdminProvider.notifier).updateTimezone(
              localTimeZone: result.localTimeZone,
            );
        if (result.ntpServer1 != null) {
          await ref
              .read(uspAdminProvider.notifier)
              .updateTimeSettings(ntpServer1: result.ntpServer1);
        }
      },
      successMessage: 'Time settings saved',
    );
  }
}
