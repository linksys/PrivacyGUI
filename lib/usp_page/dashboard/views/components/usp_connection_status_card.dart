import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';

class UspConnectionStatusCard extends StatelessWidget {
  final int activeCount;
  final int totalCount;

  const UspConnectionStatusCard({
    super.key,
    required this.activeCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
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
