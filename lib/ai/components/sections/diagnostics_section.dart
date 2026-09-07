import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../ai_info_row.dart';

/// Network diagnostics result section.
///
/// Displays ping and traceroute results in a structured format.
class DiagnosticsSection extends StatelessWidget {
  /// Ping result (optional).
  final Map<String, dynamic>? pingResult;

  /// Traceroute result (optional).
  final Map<String, dynamic>? tracerouteResult;

  /// DNS lookup result (optional).
  final Map<String, dynamic>? dnsResult;

  const DiagnosticsSection({
    super.key,
    this.pingResult,
    this.tracerouteResult,
    this.dnsResult,
  });

  @override
  Widget build(BuildContext context) {
    final hasPing = pingResult != null;
    final hasTraceroute = tracerouteResult != null;
    final hasDns = dnsResult != null;

    if (!hasPing && !hasTraceroute && !hasDns) {
      return AppText.body(loc(context).noDiagnosticResultsAvailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPing) ...[
          _buildPingSection(context, pingResult!),
          if (hasTraceroute || hasDns) ...[
            AppGap.md(),
            const Divider(),
            AppGap.md(),
          ],
        ],
        if (hasDns) ...[
          _buildDnsSection(context, dnsResult!),
          if (hasTraceroute) ...[
            AppGap.md(),
            const Divider(),
            AppGap.md(),
          ],
        ],
        if (hasTraceroute) _buildTracerouteSection(context, tracerouteResult!),
      ],
    );
  }

  Widget _buildPingSection(BuildContext context, Map<String, dynamic> ping) {
    final host = ping['host'] as String? ?? loc(context).unknown;
    final sent = ping['sent'] as int? ?? 0;
    final received = ping['received'] as int? ?? 0;
    final avgTime = ping['avgTime'] as int? ?? 0;
    final minTime = ping['minTime'] as int?;
    final maxTime = ping['maxTime'] as int?;
    final successRate = sent > 0 ? (received / sent * 100).toInt() : 0;

    final isSuccess = received > 0;
    final statusColor = isSuccess ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: statusColor,
              size: 20,
            ),
            AppGap.sm(),
            AppText.titleSmall(loc(context).pingHost(host)),
          ],
        ),
        AppGap.sm(),
        AiInfoRow(
          label: loc(context).successRate,
          value: '$successRate% ($received/$sent)',
        ),
        if (received > 0) ...[
          AiInfoRow(label: loc(context).avgResponse, value: '${avgTime}ms'),
          if (minTime != null && maxTime != null)
            AiInfoRow(
              label: loc(context).minMax,
              value: '${minTime}ms / ${maxTime}ms',
            ),
        ],
      ],
    );
  }

  Widget _buildDnsSection(BuildContext context, Map<String, dynamic> dns) {
    final host = dns['host'] as String? ?? loc(context).unknown;
    final ips = (dns['ips'] as List?)?.cast<String>() ?? [];
    final server = dns['server'] as String?;
    final responseTime = dns['responseTime'] as int?;
    final isSuccess = ips.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 20,
            ),
            AppGap.sm(),
            AppText.titleSmall(loc(context).dnsLookupHost(host)),
          ],
        ),
        AppGap.sm(),
        if (isSuccess) ...[
          AiInfoRow(label: loc(context).resolvedIps, value: ips.join(', ')),
          if (server != null)
            AiInfoRow(label: loc(context).dnsServer, value: server),
          if (responseTime != null)
            AiInfoRow(
                label: loc(context).responseTime, value: '${responseTime}ms'),
        ] else
          AiInfoRow(
              label: loc(context).status, value: loc(context).failedToResolve),
      ],
    );
  }

  Widget _buildTracerouteSection(
      BuildContext context, Map<String, dynamic> traceroute) {
    final host = traceroute['host'] as String? ?? loc(context).unknown;
    final hops =
        (traceroute['hops'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isSuccess = hops.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 20,
            ),
            AppGap.sm(),
            AppText.titleSmall(loc(context).tracerouteTo(host)),
          ],
        ),
        AppGap.sm(),
        if (isSuccess) ...[
          AiInfoRow(label: loc(context).totalHops, value: '${hops.length}'),
          AppGap.sm(),
          ...hops.take(10).map((hop) => _buildHopRow(hop)),
          if (hops.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child:
                  AppText.bodySmall(loc(context).nMoreHops(hops.length - 10)),
            ),
        ] else
          AiInfoRow(
              label: loc(context).status, value: loc(context).tracerouteFailed),
      ],
    );
  }

  Widget _buildHopRow(Map<String, dynamic> hop) {
    final number = hop['hop'] as int? ?? 0;
    final host = hop['host'] as String? ?? '*';
    final ip = hop['ip'] as String? ?? '';
    final time = hop['time'] as int? ?? 0;
    final isSlow = time > 200;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: AppText.bodySmall('$number.'),
          ),
          Expanded(
            child: AppText.bodySmall(
              host == '*' ? '* * *' : (ip.isNotEmpty ? '$host ($ip)' : host),
            ),
          ),
          SizedBox(
            width: 60,
            child: AppText.bodySmall(
              host == '*' ? '-' : '${time}ms',
              color: isSlow ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }
}
