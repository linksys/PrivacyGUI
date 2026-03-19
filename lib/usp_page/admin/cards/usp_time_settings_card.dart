import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/usp_page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/usp_page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/time_settings_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspTimeSettingsCard extends ConsumerWidget {
  const UspTimeSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeData = ref.watch(timeDataProvider).valueOrNull;
    if (timeData == null) return const CardSkeleton.info(rows: 3);
    final time = timeData.model;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'time';

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
                  AppIconButton(
                    icon: AppIcon.font(Icons.edit, size: 18),
                    onTap: isLoading
                        ? null
                        : () => _showTimeSettingsDialog(context, ref, time),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          UspInfoRow(label: 'Current Time', value: time.formattedDateTime),
          UspInfoRow(label: 'Timezone', value: time.localTimeZone),
          UspInfoRow(label: 'NTP Server 1', value: time.ntpServer1),
          if (time.ntpServer2.isNotEmpty)
            UspInfoRow(label: 'NTP Server 2', value: time.ntpServer2),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: AppText.labelLarge('Time Client'),
              ),
              Expanded(
                child: AppText.bodyMedium(time.enable ? 'Enabled' : 'Disabled'),
              ),
              AppSwitch(
                value: time.enable,
                scale: 0.8,
                onChanged: isLoading
                    ? null
                    : (value) => performUspMutation(
                          context,
                          ref,
                          loadingKey: 'time',
                          mutation: () => ref
                              .read(timeDataProvider.notifier)
                              .updateTimeSettings(enable: value),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showTimeSettingsDialog(
      BuildContext context, WidgetRef ref, TimeSettingsUIModel settings) async {
    final result = await showDialog<TimeSettingsDialogResult>(
      context: context,
      builder: (_) => TimeSettingsDialog(settings: settings),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'time',
      mutation: () => ref.read(timeDataProvider.notifier).updateTimeSettings(
            enable: result.enable,
            ntpServer1: result.ntpServer1,
            ntpServer2: result.ntpServer2,
          ),
      successMessage: 'Time settings saved',
    );
  }
}
