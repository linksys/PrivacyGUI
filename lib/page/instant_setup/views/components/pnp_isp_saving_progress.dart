import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Progress indicator shown while ISP settings are being saved & verified.
///
/// Used by isp_settings (DHCP), pppoe, and static_ip views — they all stay
/// on their own page and watch the IspSaving phase, so the progress UI is
/// shared.
class PnpIspSavingProgress extends StatelessWidget {
  const PnpIspSavingProgress({super.key, required this.phase});

  final IspSaving phase;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (IspSaveStep.saving, loc(context).pnpIspSaveStepSaving),
      (IspSaveStep.checkingSettings, loc(context).pnpIspSaveStepVerifying),
      (
        IspSaveStep.checkingInternet,
        loc(context).checkingForInternet,
      ),
    ];
    final currentIdx = IspSaveStep.values.indexOf(phase.step);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoader(),
          AppGap.xxxl(),
          // Inner column shrinks to longest step label, so all step icons share
          // a single left baseline regardless of label length.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final (_, label) = entry.value;
              final isActive = idx == currentIdx;
              final isDone = idx < currentIdx;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon.font(
                      isDone
                          ? Icons.check_circle
                          : isActive
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                      size: 20,
                      color: isDone || isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    AppGap.sm(),
                    AppText.bodyMedium(label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
