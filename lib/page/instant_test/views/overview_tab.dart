import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantTestProvider);
    final verdict = state.verdict;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isRestarting)
            const Center(child: CircularProgressIndicator()),
          if (state.phase == InstantTestLoadPhase.loading && !state.isRestarting)
            _StaggeredChecklistProgress(state: state),
          if (verdict == null && state.phase == InstantTestLoadPhase.idle)
            ElevatedButton(
              onPressed: () => ref.read(instantTestProvider.notifier).fetch(),
              child: Text(loc(context).instantTestRunButton),
            ),
          if (verdict != null) ...[
            if (state.verdictIsPreliminary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(label: Text(loc(context).instantTestPreliminaryBadge)),
              ),
            // Verdict findings
            if (verdict.isAllClear)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(loc(context).instantTestAllChecksPassed),
              ),
            for (final finding in verdict.findings)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: _priorityIcon(finding.priority),
                      title: Text(finding.headline),
                      subtitle: Text(finding.explanation),
                    ),
                    if (finding.actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: ElevatedButton(
                          onPressed: () => _handleAction(
                              context, ref, finding.actionKey ?? ''),
                          child: Text(finding.actionLabel!),
                        ),
                      ),
                  ],
                ),
              ),
            // Checklist summary (D-41 staggered, D-35 speed details)
            const SizedBox(height: 12),
            _ChecklistSummary(state: state),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                loc(context).instantTestChecksRun(verdict.checksRun),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String actionKey) async {
    if (actionKey == VerdictEngine.actionRestartRouter) {
      try {
        await ref.read(instantTestProvider.notifier).restartRouter();
        if (!context.mounted) return;
        await showRecoveryDialog(
          context,
          ref,
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: const Duration(seconds: 60),
          title: 'Router is rebooting',
          message:
              'All connected devices will be temporarily disconnected. Please wait.',
          successMessage: 'Router reboot complete',
        );
        if (context.mounted) {
          ref.read(instantTestProvider.notifier).fetch(forceSpeedTest: true);
        }
      } catch (_) {}
    }
  }

  Widget _priorityIcon(VerdictPriority priority) {
    switch (priority) {
      case VerdictPriority.critical:
        return const Icon(Icons.error, color: Colors.red);
      case VerdictPriority.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case VerdictPriority.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case VerdictPriority.allClear:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
}

// ── D-41: Staggered reveal during loading ────────────────────────────────────

/// Shows progressive check labels while USP providers are loading.
/// Staggered timing creates the feel of sequential diagnostics.
class _StaggeredChecklistProgress extends StatefulWidget {
  final InstantTestState state;
  const _StaggeredChecklistProgress({required this.state});

  @override
  State<_StaggeredChecklistProgress> createState() =>
      _StaggeredChecklistProgressState();
}

class _StaggeredChecklistProgressState
    extends State<_StaggeredChecklistProgress> {
  int _revealed = 0;

  @override
  void initState() {
    super.initState();
    _staggerReveal();
  }

  void _staggerReveal() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _revealed = 1); // Router
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _revealed = 2); // Internet
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _revealed = 3); // Speed
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Checking router…', 'Checking internet…', 'Running speed test…'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _revealed == 0 ? 'Starting diagnostics…' : labels[(_revealed - 1).clamp(0, 2)],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

// ── Checklist summary ─────────────────────────────────────────────────────────

enum _CheckDisplayState { pending, pass, fail, skipped, available }

class _ChecklistSummary extends StatefulWidget {
  final InstantTestState state;
  const _ChecklistSummary({required this.state});

  @override
  State<_ChecklistSummary> createState() => _ChecklistSummaryState();
}

class _ChecklistSummaryState extends State<_ChecklistSummary> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = widget.state;
    final wan = s.wanStatus;

    // Firmware state
    final fwAvailable = s.firmwareUpdateAvailable == true;
    final fwLabel =
        fwAvailable ? 'Software update available' : 'Software is up to date';
    final fwState =
        fwAvailable ? _CheckDisplayState.available : _CheckDisplayState.pass;

    // Speed display — D-35: show download + upload + latency
    final speedDetail = s.speedTest == null
        ? 'Not completed'
        : '↓ ${s.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps  '
            '↑ ${s.speedTest!.uploadMbps.toStringAsFixed(0)} Mbps  '
            '${s.speedTest!.latencyMs}ms delay';

    // Device quality summary
    final issueCount = s.deviceScores.where((d) => d.isIssue).length;
    final deviceDetail = s.clients.isEmpty
        ? 'No devices found'
        : '${s.clients.length} device${s.clients.length == 1 ? '' : 's'} — '
            '${issueCount == 0 ? 'all signals OK' : '$issueCount with weak signal'}';

    final rows = <_SummaryRow>[
      _SummaryRow(
        label: 'Router reached',
        state: _CheckDisplayState.pass,
        detail: s.meshNodes.isNotEmpty ? s.meshNodes.first.model : '',
        expandedDetail:
            'We connected to your router. '
            'Your device can communicate with your router over WiFi or Ethernet.',
      ),
      _SummaryRow(
        label: 'Internet connected',
        state: wan == null
            ? _CheckDisplayState.pending
            : wan.isUp
                ? _CheckDisplayState.pass
                : _CheckDisplayState.fail,
        detail: wan == null
            ? 'Checking…'
            : wan.isUp
                ? wan.ipAddress.isNotEmpty ? 'Connected · ${wan.ipAddress}' : 'Connected'
                : 'No internet service',
        expandedDetail: wan?.isUp == true
            ? 'Your router has an active connection to your internet provider.'
            : 'Your router is not receiving a signal from your internet provider. '
              'Check that the cable from your provider\'s box is firmly plugged in.',
      ),
      _SummaryRow(
        label: 'Websites loading',
        state: s.dnsCheck == null
            ? _CheckDisplayState.skipped
            : s.dnsCheck!.resolved
                ? _CheckDisplayState.pass
                : _CheckDisplayState.fail,
        detail: s.dnsCheck == null
            ? 'Not tested'
            : s.dnsCheck!.resolved
                ? 'Internet reachable'
                : 'Internet not responding',
        expandedDetail: s.dnsCheck?.resolved == true
            ? 'We confirmed websites are reachable from your router.'
            : 'Website lookups failed — websites may not load even though your router shows connected.',
      ),
      _SummaryRow(
        label: 'Speed check',
        state: s.speedTest == null
            ? _CheckDisplayState.skipped
            : _CheckDisplayState.pass,
        detail: speedDetail,
        expandedDetail: s.speedTest == null
            ? 'The speed test did not complete. Try running again.'
            : 'Speed test complete. See My Network tab for the three-leg breakdown.',
      ),
      _SummaryRow(
        label: 'Devices checked',
        state: s.clients.isEmpty
            ? _CheckDisplayState.skipped
            : _CheckDisplayState.pass,
        detail: deviceDetail,
        expandedDetail: s.clients.isEmpty
            ? 'No connected devices were detected.'
            : issueCount == 0
                ? 'All devices have a good connection.'
                : '$issueCount device${issueCount == 1 ? ' has' : 's have'} a weak signal — tap My Devices for details.',
      ),
      _SummaryRow(
        label: fwLabel,
        state: fwState,
        detail: fwAvailable ? (s.firmwareVersion ?? '') : '',
        expandedDetail: fwAvailable
            ? 'A newer version of your router\'s software is available. Updates improve performance and security.'
            : 'Your router is running the latest software.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test details',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final expanded = _expandedIndex == i;
            return _SummaryRowTile(
              row: row,
              expanded: expanded,
              onTap: () => setState(
                  () => _expandedIndex = expanded ? null : i),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final _CheckDisplayState state;
  final String detail;
  final String expandedDetail;

  const _SummaryRow({
    required this.label,
    required this.state,
    required this.detail,
    this.expandedDetail = '',
  });
}

class _SummaryRowTile extends StatelessWidget {
  final _SummaryRow row;
  final bool expanded;
  final VoidCallback onTap;

  const _SummaryRowTile({
    required this.row,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.expandedDetail.isNotEmpty ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stateIcon(row.state),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      if (row.detail.isNotEmpty)
                        Text(row.detail,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                    ],
                  ),
                ),
                if (row.expandedDetail.isNotEmpty)
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            if (expanded && row.expandedDetail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4, bottom: 2),
                child: Text(
                  row.expandedDetail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stateIcon(_CheckDisplayState state) {
    switch (state) {
      case _CheckDisplayState.pass:
        return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case _CheckDisplayState.fail:
        return const Icon(Icons.cancel, color: Colors.red, size: 18);
      case _CheckDisplayState.available:
        return const Icon(Icons.info, color: Colors.orange, size: 18);
      case _CheckDisplayState.skipped:
        return Icon(Icons.remove_circle_outline,
            color: Colors.grey.shade400, size: 18);
      case _CheckDisplayState.pending:
        return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2));
    }
  }
}
