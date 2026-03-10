import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';

class UspConnectionStatusCard extends ConsumerWidget {
  final int? activeCount;
  final int? totalCount;

  const UspConnectionStatusCard({
    super.key,
    this.activeCount,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashDevices = ref.watch(uspDashboardProvider).valueOrNull?.deviceModels;
    final activeCount = this.activeCount ??
        dashDevices?.where((d) => d.isActive).length ?? 0;
    final totalCount = this.totalCount ?? dashDevices?.length ?? 0;
    return AppCard(
      child: Row(
        children: [
          UspStatusDot(isActive: true, size: 12),
          AppGap.sm(),
          AppText.titleSmall('USP Connected'),
          const Spacer(),
          AppText.bodyMedium(
            '$activeCount device${activeCount != 1 ? 's' : ''} online',
          ),
        ],
      ),
    );
  }
}
