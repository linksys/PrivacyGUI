import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';

class SpeedTestResultCard extends StatelessWidget {
  final SpeedTestResult speedTest;

  const SpeedTestResultCard({super.key, required this.speedTest});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final downloadMbps = speedTest.downloadMbps;
    final uploadMbps = speedTest.uploadMbps;
    final uploadSupported = speedTest.hasUpload;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppText.labelLarge('Speed Test Results'),
                const Spacer(),
                if (speedTest.hasLatency)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.network_ping,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      AppGap.xs(),
                      AppText.bodySmall(
                        '${speedTest.latencyMs} ms',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
              ],
            ),
            AppGap.lg(),
            Row(
              children: [
                Expanded(
                  child: SpeedGauge(
                    label: 'Download',
                    value: downloadMbps,
                    icon: Icons.download,
                    color: colorScheme.primary,
                  ),
                ),
                AppGap.lg(),
                Expanded(
                  child: uploadSupported
                      ? SpeedGauge(
                          label: 'Upload',
                          value: uploadMbps,
                          icon: Icons.upload,
                          color: colorScheme.tertiary,
                        )
                      : Column(
                          children: [
                            Icon(
                              Icons.upload,
                              color: colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                            AppGap.sm(),
                            AppText.bodySmall(
                              'N/A',
                              color: colorScheme.onSurfaceVariant,
                            ),
                            AppGap.xs(),
                            AppText.labelSmall('Upload'),
                          ],
                        ),
                ),
              ],
            ),
            if (!uploadSupported) ...[
              AppGap.md(),
              AppText.bodySmall(
                'Upload test not supported on this firmware.',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SpeedGauge extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const SpeedGauge({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        AppGap.sm(),
        AppText.headlineSmall(
          value.toStringAsFixed(1),
          color: color,
        ),
        AppText.bodySmall('Mbps'),
        AppGap.xs(),
        AppText.labelSmall(label),
      ],
    );
  }
}
