import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  bool _findingsExpanded = false;
  int _restartCountdown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instantVerifyPivotProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderBar(state: state),
          const SizedBox(height: 16),
          _StatusCard(
            state: state,
            findingsExpanded: _findingsExpanded,
            onToggleFindings: () =>
                setState(() => _findingsExpanded = !_findingsExpanded),
            onAction: _handleAction,
          ),
          if (state.issueDevices.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DeviceIssuesCard(state: state),
          ],
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Run Tests Again'),
              onPressed: state.phase == PivotLoadPhase.loading
                  ? null
                  : () {
                      setState(() => _findingsExpanded = false);
                      ref.read(instantVerifyPivotProvider.notifier).fetch();
                    },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleAction(String actionKey) async {
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    if (actionKey == VerdictEngine.actionRestartRouter) {
      final confirmed = await _confirmRestart(context);
      if (confirmed == true) {
        await notifier.restartRouter();
        _startRestartCountdown();
      }
    } else if (actionKey == VerdictEngine.actionFirmwareUpdate) {
      final confirmed = await _confirmFirmwareUpdate(context);
      if (confirmed == true) {
        await notifier.triggerFirmwareUpdate();
      }
    }
  }

  void _startRestartCountdown() {
    setState(() => _restartCountdown = 120);
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _restartCountdown--);
      return _restartCountdown > 0;
    });
  }

  Future<bool?> _confirmRestart(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart Router?'),
        content: const Text(
          'All devices will disconnect for about 2 minutes while your router restarts. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmFirmwareUpdate(BuildContext context) {
    final state = ref.read(instantVerifyPivotProvider);
    final version = state.availableFirmwareVersion ?? 'latest version';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Install $version?'),
        content: const Text(
          'Your router will restart during the update. All devices will lose internet '
          'for about 5 minutes.\n\nMake sure your router stays plugged in during the update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}

// ── Header bar ────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _HeaderBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final model = state.routerModel ?? 'Router';
    final fw = state.routerFirmware;
    final wan = state.wanConnected ? 'Connected' : 'Disconnected';
    final upDays = state.uptimeSeconds > 0
        ? '${state.uptimeSeconds ~/ 86400}d ${(state.uptimeSeconds % 86400) ~/ 3600}h'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(model,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (fw != null)
                  Text('FW: $fw',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                _chip(context, wan,
                    state.wanConnected ? Colors.green : Colors.red),
                if (upDays != null)
                  Text('Up: $upDays',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  final bool findingsExpanded;
  final VoidCallback onToggleFindings;
  final Future<void> Function(String actionKey) onAction;

  const _StatusCard({
    required this.state,
    required this.findingsExpanded,
    required this.onToggleFindings,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Loading state
    if (state.phase == PivotLoadPhase.loading) {
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              const Text('Checking your connection...',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            Text('Running diagnostics — this takes about 30 seconds.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final verdict = state.verdict;

    // All clear state
    if (verdict == null || verdict.isAllClear) {
      return _card(
        context,
        borderColor: Colors.green,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your connection looks healthy',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    if (verdict != null && verdict.checksRun > 0)
                      Text('${verdict.checksRun} checks passed',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Internet speed, WiFi signal, and your router all look normal.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            if (state.verdictIsPreliminary) ...[
              const SizedBox(height: 8),
              _PreliminaryBadge(),
            ],
            const Divider(height: 24),
            const Text('Still having trouble?',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Restart Router'),
                  onPressed: () => onAction(VerdictEngine.actionRestartRouter),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.devices, size: 16),
                  label: const Text('Check Devices'),
                  onPressed: null, // navigates to Clients tab — wired from parent
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Findings present
    final primary = verdict.primaryFinding!;
    final visible = verdict.visibleFindings;
    final hidden = verdict.hiddenFindings;
    final borderColor = _priorityColor(context, primary.priority);

    return _card(
      context,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _priorityIcon(primary.priority),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                primary.headline,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(primary.explanation,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ),

          // Primary action button
          if (primary.hasAutoFix) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: FilledButton.icon(
                icon: Icon(_actionIcon(primary.actionKey!), size: 16),
                label: Text(primary.actionLabel!),
                onPressed: () => onAction(primary.actionKey!),
              ),
            ),
          ],

          if (state.verdictIsPreliminary) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: _PreliminaryBadge(),
            ),
          ],

          // Secondary findings (always show up to 2)
          if (visible.length > 1) ...[
            const Divider(height: 24),
            const Text('Also found:',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 8),
            ...visible.skip(1).map((f) => _FindingRow(
                  finding: f,
                  onAction: onAction,
                )),
          ],

          // Hidden findings expandable
          if (hidden.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onToggleFindings,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(
                    findingsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    findingsExpanded
                        ? 'Show less'
                        : '${hidden.length} more ${hidden.length == 1 ? 'finding' : 'findings'}',
                    style: TextStyle(
                        color: scheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),
            if (findingsExpanded)
              ...hidden.map((f) => _FindingRow(
                    finding: f,
                    onAction: onAction,
                  )),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context,
      {required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor?.withValues(alpha: 0.4) ??
              Theme.of(context).colorScheme.outlineVariant,
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Color _priorityColor(BuildContext context, VerdictPriority priority) {
    switch (priority) {
      case VerdictPriority.critical:
        return Theme.of(context).colorScheme.error;
      case VerdictPriority.warning:
        return Colors.orange;
      case VerdictPriority.info:
        return Colors.blue;
      case VerdictPriority.allClear:
        return Colors.green;
    }
  }

  Widget _priorityIcon(VerdictPriority priority) {
    switch (priority) {
      case VerdictPriority.critical:
        return const Icon(Icons.error, color: Colors.red, size: 22);
      case VerdictPriority.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange, size: 22);
      case VerdictPriority.info:
        return const Icon(Icons.info_outline, color: Colors.blue, size: 22);
      case VerdictPriority.allClear:
        return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }
  }

  IconData _actionIcon(String actionKey) {
    switch (actionKey) {
      case VerdictEngine.actionRestartRouter:
        return Icons.refresh;
      case VerdictEngine.actionFirmwareUpdate:
        return Icons.system_update;
      default:
        return Icons.play_arrow;
    }
  }
}

// ── Finding row (secondary findings) ─────────────────────────────────────────

class _FindingRow extends StatelessWidget {
  final VerdictFinding finding;
  final Future<void> Function(String actionKey) onAction;

  const _FindingRow({required this.finding, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(finding.headline,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                if (finding.hasAutoFix)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => onAction(finding.actionKey!),
                    child: Text(finding.actionLabel!,
                        style: TextStyle(
                            fontSize: 12, color: scheme.primary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon() {
    switch (finding.priority) {
      case VerdictPriority.critical:
        return const Icon(Icons.error, color: Colors.red, size: 18);
      case VerdictPriority.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange, size: 18);
      case VerdictPriority.info:
        return const Icon(Icons.info_outline, color: Colors.blue, size: 18);
      case VerdictPriority.allClear:
        return const Icon(Icons.check_circle_outline,
            color: Colors.green, size: 18);
    }
  }
}

// ── Device issues card ────────────────────────────────────────────────────────

class _DeviceIssuesCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _DeviceIssuesCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final issueDevices = state.issueDevices;

    // All far vs all interference — determine advice
    final tooFarCount = issueDevices
        .where((d) => (d.client.signalDecibels ?? 0) < -75)
        .length;
    final advice = tooFarCount > issueDevices.length / 2
        ? 'Try moving your router to a more central location to improve their signal.'
        : 'Check for thick walls, metal objects, or appliances between these devices and your router.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Devices with weak WiFi',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...issueDevices.take(5).map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      d.client.displayNameWithOui,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d.client.band,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  if (d.client.signalDecibels != null)
                    Text(
                      '${d.client.signalDecibels} dBm',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                ]),
              )),
          if (issueDevices.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '+${issueDevices.length - 5} more devices',
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 8),
          Text(advice,
              style: TextStyle(
                  fontSize: 13, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Preliminary badge ────────────────────────────────────────────────────────

class _PreliminaryBadge extends StatelessWidget {
  const _PreliminaryBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Speed test in progress...',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
