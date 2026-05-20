import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_result.dart';

class TracerouteDetailCard extends StatelessWidget {
  final TracerouteCheckUIModel result;

  const TracerouteDetailCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hops = result.hops;

    if (hops.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route, size: 20, color: colorScheme.primary),
                  AppGap.sm(),
                  AppText.labelLarge('Traceroute to ${result.targetHost}'),
                ],
              ),
              AppGap.md(),
              // Header row
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: AppText.labelSmall('#',
                        color: colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    flex: 2,
                    child: AppText.labelSmall('Host',
                        color: colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(
                    width: 80,
                    child: AppText.labelSmall('RTT',
                        color: colorScheme.onSurfaceVariant,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Hop rows
              ...hops.map((hop) => _buildHopRow(context, hop)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHopRow(BuildContext context, TracerouteHopUIModel hop) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSlow = hop.isSlow;
    final isUnreachable = hop.isUnreachable;

    final textColor = isSlow
        ? colorScheme.error
        : isUnreachable
            ? colorScheme.onSurfaceVariant
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: AppText.bodySmall(
              '${hop.hopNumber}',
              color: textColor,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  hop.host.isNotEmpty
                      ? hop.host
                      : (hop.hostAddress.isNotEmpty ? hop.hostAddress : '*'),
                  color: textColor,
                ),
                if (hop.host.isNotEmpty && hop.hostAddress.isNotEmpty)
                  AppText.labelSmall(
                    hop.hostAddress,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSlow)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child:
                        Icon(Icons.warning, size: 14, color: colorScheme.error),
                  ),
                AppText.bodySmall(
                  isUnreachable ? '*' : '${hop.avgRoundTrip} ms',
                  color: textColor,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
