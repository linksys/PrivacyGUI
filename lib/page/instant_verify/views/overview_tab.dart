import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final VoidCallback? onViewClients;
  final void Function(int flowIndex)? onNavigateToFlow;
  const OverviewTab({super.key, this.onViewClients, this.onNavigateToFlow});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  bool _findingsExpanded = false;
  bool _checksExpanded = false;
  int _restartCountdown = 0;
  bool _hasRestarted = false;

  @override
  void initState() {
    super.initState();
    // Only auto-run on first mount (idle phase). Tab switches preserve state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phase = ref.read(instantVerifyPivotProvider).phase;
      if (phase == PivotLoadPhase.idle) {
        ref.read(instantVerifyPivotProvider.notifier).fetch();
      }
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
          _ConnectionChip(state: state),
          const SizedBox(height: 8),
          // Router light guide link (PRD v0.7 S-1)
          _LightGuideLink(
            showInlineCallout: state.phase != PivotLoadPhase.idle &&
                state.phase != PivotLoadPhase.loading &&
                !state.wanConnected,
          ),
          const SizedBox(height: 8),
          _StatusCard(
            state: state,
            findingsExpanded: _findingsExpanded,
            checksExpanded: _checksExpanded,
            onToggleFindings: () =>
                setState(() => _findingsExpanded = !_findingsExpanded),
            onToggleChecks: () =>
                setState(() => _checksExpanded = !_checksExpanded),
            onAction: _handleAction,
            onViewClients: widget.onViewClients,
            onNavigateToFlow: widget.onNavigateToFlow,
            hasRestarted: _hasRestarted,
          ),
          if (state.issueDevices.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DeviceIssuesCard(state: state),
          ],
          if (state.isMeshNetwork) ...[
            const SizedBox(height: 16),
            _MeshCard(state: state),
          ],
          // Restart countdown with reassurance (PRD v0.7 D-23)
          if (_restartCountdown > 0) ...[
            const SizedBox(height: 16),
            _RestartCountdown(secondsRemaining: _restartCountdown),
          ],
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_hasRestarted ? 'Check Again' : 'Run Again'),
              onPressed: state.phase == PivotLoadPhase.loading ||
                      state.phase == PivotLoadPhase.jnapLoaded ||
                      _restartCountdown > 0
                  ? null
                  : () {
                      setState(() {
                        _findingsExpanded = false;
                        _checksExpanded = false;
                      });
                      ref.read(instantVerifyPivotProvider.notifier).fetch();
                    },
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Center(
              child: FilledButton.tonal(
                onPressed: () => _showScenarioPicker(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Test scenarios'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleAction(String actionKey) async {
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    if (actionKey == VerdictEngine.actionRestartRouter) {
      // Post-restart escalation (PRD v0.7 D-26): don't offer restart again
      if (_hasRestarted) return;
      final confirmed = await _confirmRestart(context);
      if (confirmed == true) {
        await notifier.restartRouter();
        setState(() => _hasRestarted = true);
        _startRestartCountdown();
      }
    } else if (actionKey == VerdictEngine.actionFirmwareUpdate) {
      final confirmed = await _confirmFirmwareUpdate(context);
      if (confirmed == true) {
        await notifier.triggerFirmwareUpdate();
      }
    } else if (actionKey == VerdictEngine.actionBridgeModeHelp) {
      // Navigate to bridge mode / two-router guidance flow (Flow 6)
      widget.onNavigateToFlow?.call(5); // 0-indexed → Help Me Fix It flow 6
    }
  }

  void _startRestartCountdown() {
    setState(() => _restartCountdown = 120);
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _restartCountdown--);
      if (_restartCountdown <= 0) {
        // Countdown done — start polling for router to come back online.
        // (Fix: Item 10 — the "auto-reload" promise is now fulfilled)
        _pollForReconnection();
        return false;
      }
      return true;
    });
  }

  /// After restart countdown, poll every 5s until the router responds,
  /// then automatically re-run the full diagnostic test.
  Future<void> _pollForReconnection() async {
    const maxPolls = 24; // 2 more minutes (5s × 24 = 120s)
    final svc = ref.read(browserDiagnosticServiceProvider);
    for (var i = 0; i < maxPolls; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      try {
        final ping = await svc.pingGateway();
        if (ping.reachable) {
          // Router is back — run tests automatically
          ref.read(instantVerifyPivotProvider.notifier).fetch(forceSpeedTest: true);
          return;
        }
      } catch (_) {}
    }
    // If still unreachable after 2 more minutes, enable "Run Again" so user can retry
    if (mounted) setState(() => _restartCountdown = 0);
  }

  Future<bool?> _confirmRestart(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart Router?'),
        content: const Text(
          'All devices will disconnect for about 2 minutes.\n\n'
          'If you\'re on WiFi, this page will go blank. '
          'Wait 2 minutes, reconnect to your WiFi, then return to 192.168.1.1.',
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
          'This update takes about 5 minutes.\n\n'
          'During the update:\n'
          '\u2022 Your WiFi will turn off\n'
          '\u2022 All devices will disconnect\n'
          '\u2022 This page will stop responding\n\n'
          'Your router will restart automatically when done. '
          'Your devices will reconnect on their own.\n\n'
          'Don\'t unplug your router during the update.',
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

  void _showScenarioPicker(BuildContext context) {
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final scenarios = [
          _ScenarioItem(
            index: 0,
            icon: Icons.cable_outlined,
            color: Colors.red,
            title: 'No internet connection',
            subtitle: 'WAN disconnected — critical finding + cable check',
          ),
          _ScenarioItem(
            index: 1,
            icon: Icons.public_off,
            color: Colors.orange,
            title: 'Websites aren\'t loading',
            subtitle: 'Connected to ISP, DNS failure — restart CTA',
          ),
          _ScenarioItem(
            index: 2,
            icon: Icons.slow_motion_video,
            color: Colors.orange,
            title: 'Slow internet + weak WiFi',
            subtitle: '3 Mbps / 148ms latency + 2 weak devices + firmware + uptime',
          ),
          _ScenarioItem(
            index: 3,
            icon: Icons.memory,
            color: Colors.deepOrange,
            title: 'Router overloaded + mesh issues',
            subtitle: 'CPU 88% / Mem 90% + zombie node + ethernet no-link',
          ),
          _ScenarioItem(
            index: 4,
            icon: Icons.lock_outline,
            color: Colors.blue,
            title: 'Configuration blocks',
            subtitle: '2.4 GHz crowd + schedule + privacy + PMF + DHCP 92%',
          ),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Scenarios',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      'Load mock data to exercise each workflow without a router.',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...scenarios.map((s) => ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: s.color.withValues(alpha: 0.12),
                  child: Icon(s.icon, size: 18, color: s.color),
                ),
                title: Text(s.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text(s.subtitle,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 2),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _findingsExpanded = false;
                    _checksExpanded = false;
                  });
                  notifier.loadMockScenario(s.index);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

class _ScenarioItem {
  final int index;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ScenarioItem({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// ── Header bar ────────────────────────────────────────────────────────────────

// ── Slim connection chip — replaces the full header bar on Tab 0 ──────────────
// Metadata (model/FW/SN/uptime) moved to the AppBar ⓘ icon in the pivot view.

class _ConnectionChip extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _ConnectionChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading;
    final label = isLoading ? 'Checking...' : _HeaderBar._connectionLabel(state);
    final color = isLoading ? Colors.grey : _HeaderBar._connectionColor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

// ── Header bar (preserved for backward compat — metadata now in AppBar ⓘ) ──────

class _HeaderBar extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _HeaderBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLoading = state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading;

    final model = state.routerModel ?? 'Router';
    final fw = state.routerFirmware;
    final serial = state.routerSerial;
    final mac = state.routerMac;
    final upDays = state.uptimeSeconds > 0
        ? '${state.uptimeSeconds ~/ 86400}d ${(state.uptimeSeconds % 86400) ~/ 3600}h'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: model + WAN chip
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(model,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (!isLoading)
                      _chip(context, _connectionLabel(state), _connectionColor(state))
                    else
                      _chip(context, 'Checking...', Colors.grey),
                    if (upDays != null && !isLoading)
                      Text('Up $upDays',
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          // Row 2: FW, Serial, MAC
          if (fw != null || serial != null || mac != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 2,
              children: [
                if (fw != null)
                  _metaText(context, 'FW: $fw'),
                if (serial != null)
                  _metaText(context, 'S/N: $serial'),
                if (mac != null)
                  _metaText(context, 'MAC: $mac'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Precise label based on what was actually tested (item 50).
  /// Each state represents exactly what the diagnostics confirmed:
  ///   - WAN status (JNAP) = router's WAN port / connection to modem
  ///   - WAN IP = ISP assigned an address
  ///   - DNS check (browser) = internet and name resolution working
  static String _connectionLabel(InstantVerifyPivotState state) {
    // DNS result is the highest confidence — it confirms end-to-end internet
    if (state.dnsCheck != null) {
      return state.dnsCheck!.resolved
          ? 'Internet: Working'
          : 'Connected to ISP \u2014 websites aren\'t loading';
    }
    // WAN status from JNAP — router sees modem/ISP line
    if (state.wanStatus != null) {
      return state.wanConnected
          ? 'Connected to ISP'   // WAN up, DNS not yet run
          : 'Not connected to ISP';
    }
    return 'Checking...';
  }

  static Color _connectionColor(InstantVerifyPivotState state) {
    if (state.dnsCheck != null) {
      return state.dnsCheck!.resolved ? Colors.green : Colors.orange;
    }
    if (state.wanStatus != null) {
      return state.wanConnected ? Colors.blue : Colors.red;
    }
    return Colors.grey;
  }

  Widget _metaText(BuildContext context, String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant));
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
  final bool checksExpanded;
  final VoidCallback onToggleFindings;
  final VoidCallback onToggleChecks;
  final Future<void> Function(String actionKey) onAction;
  final VoidCallback? onViewClients;
  final void Function(int flowIndex)? onNavigateToFlow;
  final bool hasRestarted;

  const _StatusCard({
    required this.state,
    required this.findingsExpanded,
    required this.checksExpanded,
    required this.onToggleFindings,
    required this.onToggleChecks,
    required this.onAction,
    this.onViewClients,
    this.onNavigateToFlow,
    this.hasRestarted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Loading / preliminary state — show individual check progress
    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading ||
        (state.phase == PivotLoadPhase.jnapLoaded &&
            state.verdictIsPreliminary)) {
      return _card(
        context,
        child: _ChecklistProgress(state: state),
      );
    }

    final verdict = state.verdict;

    // All clear state — "We didn't detect any issues" + flow cards (PRD v0.7 D-16)
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
                    const Text("We didn't detect any issues",
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
            const SizedBox(height: 16),
            Text(
              'Still having a problem? Tell us what\'s happening and we\'ll help:',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            // Flow cards — 2x2 grid + 1 (PRD v0.7)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlowCard(
                  icon: Icons.public_off,
                  label: 'My internet\nisn\'t working',
                  onTap: () => onNavigateToFlow?.call(0),
                ),
                _FlowCard(
                  icon: Icons.slow_motion_video,
                  label: 'My internet\nis slow',
                  onTap: () => onNavigateToFlow?.call(1),
                ),
                _FlowCard(
                  icon: Icons.wifi_off,
                  label: 'A device won\'t\nconnect',
                  onTap: () => onNavigateToFlow?.call(2),
                ),
                _FlowCard(
                  icon: Icons.signal_wifi_bad,
                  label: 'WiFi doesn\'t\nreach a room',
                  onTap: () => onNavigateToFlow?.call(3),
                ),
                _FlowCard(
                  icon: Icons.sync_problem,
                  label: 'My connection\nkeeps cutting out',
                  onTap: () => onNavigateToFlow?.call(4),
                ),
              ],
            ),
            _CheckResultsExpand(
              state: state,
              expanded: checksExpanded,
              onToggle: onToggleChecks,
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

          // Primary action button — or ISP escalation after restart (D-26)
          if (hasRestarted && primary.postRestartEscalation != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  primary.postRestartEscalation!,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ] else if (primary.hasAutoFix) ...[
            const SizedBox(height: 12),
            if ((visible.length > 1 || hidden.isNotEmpty) && primary.hasAutoFix)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 4),
                child: Text(
                  'Start here — fixing this may help the others too',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: FilledButton.icon(
                icon: Icon(_actionIcon(primary.actionKey!), size: 16),
                label: Text(primary.actionLabel!),
                onPressed: () => onAction(primary.actionKey!),
              ),
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

          _CheckResultsExpand(
            state: state,
            expanded: checksExpanded,
            onToggle: onToggleChecks,
          ),
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
      case VerdictEngine.actionBridgeModeHelp:
        return Icons.device_hub;
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
          ...issueDevices.take(5).map((d) => _DeviceIssueRow(score: d)),
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

// ── Device issue row ──────────────────────────────────────────────────────────

class _DeviceIssueRow extends StatelessWidget {
  final DeviceScore score;
  const _DeviceIssueRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final client = score.client;

    // Determine primary issue reason
    final bool weakSignal =
        client.signalDecibels != null && client.signalDecibels! < -75;
    final bool slowRate = (client.txRateMbps != null && client.txRateMbps! < 10) ||
        (client.rxRateMbps != null && client.rxRateMbps! < 10);

    // Build detail string: signal + rate
    final parts = <String>[];
    if (client.signalDecibels != null) {
      parts.add('${client.signalDecibels} dBm');
    }
    if (client.txRateMbps != null || client.rxRateMbps != null) {
      final tx = client.txRateMbps;
      final rx = client.rxRateMbps;
      if (tx != null && rx != null) {
        parts.add('↓${rx}  ↑${tx} Mbps');
      } else if (tx != null) {
        parts.add('↑${tx} Mbps');
      }
    }
    final detail = parts.join('  ·  ');

    final issueColor =
        weakSignal && slowRate ? Colors.red : Colors.orange.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: issueColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                client.displayNameWithOui,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              client.band,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ]),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 2),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 11,
                  color: weakSignal || slowRate
                      ? issueColor
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mesh network card ─────────────────────────────────────────────────────────

class _MeshCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _MeshCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nodes = state.meshNodes;
    final deviceCount = nodes.length;

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
          Row(children: [
            const Icon(Icons.hub_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              'Mesh Network — $deviceCount device${deviceCount == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ]),
          const SizedBox(height: 12),
          ...nodes.map((node) => _MeshNodeRow(
                node: node,
                clientCount: state.clientCountForNode(node.deviceId),
              )),
        ],
      ),
    );
  }
}

class _MeshNodeRow extends StatelessWidget {
  final MeshNodeInfo node;
  final int clientCount;
  const _MeshNodeRow({required this.node, required this.clientCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // ── Role icon + color ──────────────────────────────────────────────────
    final IconData roleIcon;
    final Color roleColor;
    if (node.isController) {
      roleIcon = Icons.router;
      roleColor = scheme.primary;
    } else if (node.hasWiredBackhaul) {
      roleIcon = Icons.cable;
      roleColor = Colors.green;
    } else {
      switch (node.backhaulHealth) {
        case BackhaulHealth.strong:
          roleIcon = Icons.wifi;
          roleColor = Colors.green;
        case BackhaulHealth.moderate:
          roleIcon = Icons.wifi;
          roleColor = Colors.orange;
        case BackhaulHealth.weak:
        case BackhaulHealth.critical:
          roleIcon = Icons.warning_amber;
          roleColor = Colors.red;
        case BackhaulHealth.unknown:
          roleIcon = Icons.wifi;
          roleColor = Colors.green;
      }
    }

    // ── Backhaul health label + detail for child nodes ─────────────────────
    String? healthLabel;
    String? healthDetail;
    Color healthColor = scheme.onSurfaceVariant;

    if (!node.isController) {
      final speed = node.backhaulSpeedMbps;
      final rssi = node.backhaulApRssi ?? node.backhaulRssi;

      // Build compact data string: "201 Mbps · -33 dBm"
      final parts = <String>[];
      if (speed != null) parts.add('$speed Mbps');
      if (rssi != null) parts.add('$rssi dBm');
      final dataStr = parts.join(' · ');

      switch (node.backhaulHealth) {
        case BackhaulHealth.strong:
          healthLabel = 'Good connection';
          healthDetail = dataStr.isNotEmpty ? dataStr : null;
          healthColor = Colors.green.shade700;
        case BackhaulHealth.moderate:
          healthLabel = 'Moderate';
          healthDetail = '${dataStr.isNotEmpty ? '$dataStr — ' : ''}'
              'may cause occasional slowness under load';
          healthColor = Colors.orange.shade700;
        case BackhaulHealth.weak:
          healthLabel = 'Weak backhaul';
          healthDetail = '${dataStr.isNotEmpty ? '$dataStr — ' : ''}'
              'likely causing slowness, jitter, or drops. '
              'Move ${node.name} closer to the main router.';
          healthColor = Colors.red.shade700;
        case BackhaulHealth.critical:
          healthLabel = 'Critical backhaul';
          healthDetail = '${dataStr.isNotEmpty ? '$dataStr — ' : ''}'
              'backhaul too poor to be reliable. '
              'Move ${node.name} much closer to the main router, '
              'or connect it by Ethernet cable.';
          healthColor = Colors.red.shade800;
        case BackhaulHealth.unknown:
          healthLabel = node.hasWiredBackhaul ? 'Wired — optimal' : null;
          healthDetail = dataStr.isNotEmpty ? dataStr : null;
          healthColor = Colors.green.shade700;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(roleIcon, size: 18, color: roleColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row + role badge + client count
                Row(children: [
                  // Role badge: "Parent" or "Child"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: node.isController
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      node.isController ? 'Parent' : 'Child',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: node.isController
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      node.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (clientCount > 0)
                    Text(
                      '$clientCount device${clientCount == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                ]),

                // Model + backhaul health
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  children: [
                    if (node.model != null)
                      Text(node.model!,
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    if (node.model != null && healthLabel != null)
                      Text('·',
                          style: TextStyle(color: scheme.outlineVariant, fontSize: 11)),
                    if (healthLabel != null)
                      Text(healthLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: healthColor)),
                  ],
                ),

                // Health detail (only for moderate/weak/critical)
                if (healthDetail != null &&
                    node.backhaulHealth != BackhaulHealth.strong &&
                    node.backhaulHealth != BackhaulHealth.unknown) ...[
                  const SizedBox(height: 3),
                  Text(
                    healthDetail,
                    style: TextStyle(
                        fontSize: 11,
                        color: healthColor,
                        height: 1.3),
                  ),
                ] else if (healthDetail != null &&
                    (node.backhaulHealth == BackhaulHealth.strong ||
                        node.backhaulHealth == BackhaulHealth.unknown)) ...[
                  const SizedBox(height: 3),
                  Text(
                    healthDetail,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Check results expand (post-completion) ────────────────────────────────────

class _CheckResultsExpand extends StatelessWidget {
  final InstantVerifyPivotState state;
  // expanded and onToggle kept for API compat but toggle is removed — always visible
  final bool expanded;
  final VoidCallback onToggle;

  const _CheckResultsExpand({
    required this.state,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Test details',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        _ChecklistSummary(state: state),
      ],
    );
  }
}

class _ChecklistSummary extends StatefulWidget {
  final InstantVerifyPivotState state;
  const _ChecklistSummary({required this.state});

  @override
  State<_ChecklistSummary> createState() => _ChecklistSummaryState();
}

class _ChecklistSummaryState extends State<_ChecklistSummary> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = widget.state;

    // Firmware 3-state (PRD v0.7): pass / update available / not a failure
    final bool fwUpToDate = !state.firmwareUpdateAvailable;
    final String fwLabel = state.firmwareUpdateAvailable
        ? 'Software update available'
        : 'Software is up to date';
    // Use a special "available" state icon — not pass, not fail
    final _CheckDisplayState fwState = state.firmwareUpdateAvailable
        ? _CheckDisplayState.available
        : _CheckDisplayState.pass;

    final rows = <_SummaryRow>[
      _SummaryRow(
        label: 'Router reached',
        state: _CheckDisplayState.pass,
        detail: state.routerModel ?? '',
        expandedDetail:
            'We connected to your router at 192.168.1.1. '
            'This means your device can communicate with your router over WiFi or Ethernet.',
      ),
      _SummaryRow(
        label: 'Internet connected',
        state: state.wanConnected ? _CheckDisplayState.pass : _CheckDisplayState.fail,
        detail: state.wanConnected ? 'Connected' : 'No internet service',
        expandedDetail: state.wanConnected
            ? 'Your router has an active connection to your internet provider. '
              'Data can flow between your home and the internet.'
            : 'Your router is not receiving a signal from your internet provider. '
              'Check that the cable from your provider\'s box to your router is firmly plugged in.',
      ),
      _SummaryRow(
        label: 'Websites loading',
        state: state.dnsCheck == null
            ? _CheckDisplayState.skipped
            : state.dnsCheck!.resolved
                ? _CheckDisplayState.pass
                : _CheckDisplayState.fail,
        detail: state.dnsCheck == null
            ? 'Not tested'
            : state.dnsCheck!.resolved
                ? 'Internet reachable'
                : 'Internet not responding',
        expandedDetail: state.dnsCheck?.resolved == true
            ? 'We sent a request to look up a website address (like google.com). '
              'Your router found it \u2014 websites should load normally.'
            : 'We tried to look up a website address and your router couldn\'t find it. '
              'This means websites may not load even though your router shows connected.',
      ),
      _SummaryRow(
        label: 'Speed check',
        state: state.speedTest == null ? _CheckDisplayState.skipped : _CheckDisplayState.pass,
        detail: state.speedTest == null
            ? 'Not completed'
            : '\u2193 ${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps  '
                '\u2191 ${state.speedTest!.uploadMbps.toStringAsFixed(0)} Mbps  '
                '${state.speedTest!.latencyMs}ms delay',
        expandedDetail: state.speedTest != null
            ? 'Speed measured from this device — other devices in your home may be faster or slower. '
              'Speed can vary based on time of day, how many devices are active, '
              'and your distance from the router.'
            : 'The speed test did not complete. Try running again.',
      ),
      _SummaryRow(
        label: 'Devices checked',
        state: state.clients.isNotEmpty ? _CheckDisplayState.pass : _CheckDisplayState.skipped,
        detail: state.clients.isEmpty
            ? 'No devices found'
            : '${state.clients.length} device${state.clients.length == 1 ? '' : 's'} \u2014 '
                '${state.issueDevices.length} with weak signal',
        expandedDetail: state.clients.isEmpty
            ? 'No connected devices were detected.'
            : 'We checked the WiFi signal strength and speed for each connected device. '
              '${state.issueDevices.isEmpty ? 'All devices have a good connection.' : '${state.issueDevices.length} device${state.issueDevices.length == 1 ? ' has' : 's have'} a weak signal \u2014 tap My Devices for details.'}',
      ),
      _SummaryRow(
        label: fwLabel,
        state: fwState,
        detail: fwUpToDate ? '' : state.availableFirmwareVersion ?? '',
        expandedDetail: fwUpToDate
            ? 'Your router is running the latest software. '
              'Updates improve performance and security.'
            : 'A newer version of your router\'s software is available. '
              'Updates improve performance, fix bugs, and improve security.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _SummaryRowWidget(
            row: row,
            isExpanded: _expandedIndex == index,
            onTap: () => setState(() {
              _expandedIndex = _expandedIndex == index ? null : index;
            }),
          );
        }).toList(),
      ),
    );
  }
}

enum _CheckDisplayState { pass, fail, skipped, available }

class _SummaryRow {
  final String label;
  final _CheckDisplayState state;
  final String detail;
  final String expandedDetail;
  const _SummaryRow({
    required this.label,
    required this.state,
    required this.detail,
    required this.expandedDetail,
  });
}

class _SummaryRowWidget extends StatelessWidget {
  final _SummaryRow row;
  final bool isExpanded;
  final VoidCallback onTap;
  const _SummaryRowWidget({
    required this.row,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    IconData iconData;
    Color iconColor;
    switch (row.state) {
      case _CheckDisplayState.pass:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
      case _CheckDisplayState.fail:
        iconData = Icons.cancel;
        iconColor = Colors.red;
      case _CheckDisplayState.skipped:
        iconData = Icons.remove_circle_outline;
        iconColor = scheme.outlineVariant;
      case _CheckDisplayState.available:
        iconData = Icons.arrow_circle_up;
        iconColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Row(children: [
              Icon(iconData, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(row.label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              if (row.detail.isNotEmpty)
                Text(
                  row.detail,
                  style: TextStyle(
                      fontSize: 12,
                      color: row.state == _CheckDisplayState.fail
                          ? Colors.red.shade700
                          : scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ]),
          ),
        ),
        // Progressive disclosure (PRD v0.7 S-5)
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 12, right: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                row.expandedDetail,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Checklist progress (loading + preliminary phase) ─────────────────────────

enum _CheckStatus { pending, running, pass, fail }

class _ChecklistProgress extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _ChecklistProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    final step = state.browserTestStep;

    final routerStatus = state.phase == PivotLoadPhase.idle ||
            state.phase == PivotLoadPhase.loading
        ? _CheckStatus.running
        : _CheckStatus.pass;

    final internetStatus = state.phase == PivotLoadPhase.loading ||
            state.phase == PivotLoadPhase.idle
        ? _CheckStatus.pending
        : state.wanConnected
            ? _CheckStatus.pass
            : _CheckStatus.fail;

    _CheckStatus gatewayStatus;
    String gatewayDetail = '';
    if (state.phase == PivotLoadPhase.loading ||
        state.phase == PivotLoadPhase.idle) {
      gatewayStatus = _CheckStatus.pending;
    } else if (step == 'gateway') {
      gatewayStatus = _CheckStatus.running;
    } else if (state.gatewayPing != null) {
      gatewayStatus =
          state.gatewayPing!.reachable ? _CheckStatus.pass : _CheckStatus.fail;
      if (state.gatewayPing!.reachable &&
          state.gatewayPing!.latencyMs != null) {
        gatewayDetail = '${state.gatewayPing!.latencyMs}ms';
      } else if (!state.gatewayPing!.reachable) {
        gatewayDetail = 'Could not reach router';
      }
    } else if (step == 'dns' ||
        step.startsWith('speed') ||
        step == 'complete') {
      gatewayStatus = _CheckStatus.pass;
    } else {
      gatewayStatus = _CheckStatus.pending;
    }

    _CheckStatus dnsStatus;
    String dnsDetail = '';
    if (state.phase == PivotLoadPhase.loading ||
        state.phase == PivotLoadPhase.idle ||
        step == 'gateway' ||
        step == 'idle') {
      dnsStatus = _CheckStatus.pending;
    } else if (step == 'dns') {
      dnsStatus = _CheckStatus.running;
    } else if (state.dnsCheck != null) {
      dnsStatus =
          state.dnsCheck!.resolved ? _CheckStatus.pass : _CheckStatus.fail;
      dnsDetail = state.dnsCheck!.resolved
          ? 'Internet reachable'
          : 'Internet not responding';
    } else if (step.startsWith('speed') || step == 'complete') {
      dnsStatus = _CheckStatus.pass;
    } else {
      dnsStatus = _CheckStatus.pending;
    }

    _CheckStatus speedStatus;
    String speedDetail = '';
    if (!step.startsWith('speed') && step != 'complete' && state.speedTest == null) {
      speedStatus = _CheckStatus.pending;
    } else if (step.startsWith('speed:')) {
      speedStatus = _CheckStatus.running;
      final substep = step.split(':').last;
      speedDetail = switch (substep) {
        'latency' => 'Measuring latency...',
        'download' => 'Testing download speed...',
        'upload' => 'Testing upload speed...',
        _ => 'Running speed test...',
      };
    } else if (state.speedTest != null) {
      speedStatus = _CheckStatus.pass;
      speedDetail =
          '${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps down';
    } else if (step == 'error') {
      speedStatus = _CheckStatus.fail;
      speedDetail = 'Speed test could not complete';
    } else {
      speedStatus = _CheckStatus.pending;
    }

    final deviceStatus = state.phase == PivotLoadPhase.loading ||
            state.phase == PivotLoadPhase.idle
        ? _CheckStatus.pending
        : _CheckStatus.pass;
    final deviceDetail = state.clients.isEmpty
        ? ''
        : '${state.clients.length} device${state.clients.length == 1 ? '' : 's'} found';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Checking your connection',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _CheckRow(label: 'Router', status: routerStatus,
            detail: state.routerModel ?? ''),
        _CheckRow(
            label: 'Internet',
            status: internetStatus,
            detail: state.wanConnected
                ? 'Connected'
                : state.phase == PivotLoadPhase.loading
                    ? ''
                    : 'No internet service'),
        _CheckRow(
            label: 'Gateway response',
            status: gatewayStatus,
            detail: gatewayDetail),
        _CheckRow(
            label: 'Website access', status: dnsStatus, detail: dnsDetail),
        _CheckRow(
            label: 'Speed test', status: speedStatus, detail: speedDetail),
        _CheckRow(
            label: 'Your devices',
            status: deviceStatus,
            detail: deviceDetail),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final _CheckStatus status;
  final String detail;

  const _CheckRow({
    required this.label,
    required this.status,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget icon;
    Color labelColor = scheme.onSurface;

    switch (status) {
      case _CheckStatus.pending:
        icon = Icon(Icons.radio_button_unchecked,
            size: 18, color: scheme.outlineVariant);
        labelColor = scheme.onSurfaceVariant;
      case _CheckStatus.running:
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: scheme.primary),
        );
      case _CheckStatus.pass:
        icon = const Icon(Icons.check_circle, size: 18, color: Colors.green);
      case _CheckStatus.fail:
        icon = const Icon(Icons.cancel, size: 18, color: Colors.red);
        labelColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        icon,
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  fontSize: 14)),
        ),
        Expanded(
          child: Text(
            detail,
            style: TextStyle(
                fontSize: 13,
                color: status == _CheckStatus.fail
                    ? Colors.red.shade700
                    : scheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

// ── Router light guide (PRD v0.7 S-1) ───────────────────────────────────────

class _LightGuideLink extends StatelessWidget {
  final bool showInlineCallout;
  const _LightGuideLink({this.showInlineCallout = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline WAN-down callout
        if (showInlineCallout)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No internet connection detected.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Check your router's light. What color is it?",
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showLightGuide(context),
                  child: Text(
                    'What does my light mean?',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Persistent link (always visible)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: Icon(Icons.lightbulb_outline, size: 16, color: scheme.primary),
            label: Text(
              'What does my router light mean?',
              style: TextStyle(fontSize: 12, color: scheme.primary),
            ),
            onPressed: () => _showLightGuide(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  static void _showLightGuide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'What does my router light mean?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
            // LED patterns from Pinnacle LED spec r20260109a
            _lightRow(Colors.white, 'Solid white',
                'Everything is fine \u2014 connected to internet',
                animated: false),
            _lightRow(Colors.white, 'Pulsing white',
                'Starting up or WPS pairing in progress \u2014 wait about a minute',
                animated: true, animationType: 'pulse'),
            _lightRow(Colors.white, 'Flashing white',
                'Factory reset in progress \u2014 do not unplug',
                animated: true, animationType: 'flash'),
            _lightRow(Colors.blue, 'Pulsing blue',
                'Booting up \u2014 wait about a minute',
                animated: true, animationType: 'pulse'),
            _lightRow(Colors.red, 'Solid red',
                'No internet \u2014 check your cables',
                animated: false),
            _lightRow(Colors.yellow.shade700, 'Solid yellow',
                'Needs attention \u2014 a check found a problem',
                animated: false),
            _lightRow(Colors.green, 'Solid green',
                'Instant-Test passed \u2014 everything looks good',
                animated: false),
            _lightRow(Colors.black, 'Off',
                'No power, or Night Mode is enabled',
                animated: false),
          ],
        ),
        ),
      ),
    );
  }

  static Widget _lightRow(Color color, String label, String meaning, {
    bool animated = false,
    String animationType = 'pulse', // 'pulse' or 'flash'
  }) {
    final isBlack = color == Colors.black;
    final isWhite = color == Colors.white;

    Widget dot = Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: (isWhite || isBlack)
            ? Border.all(color: Colors.grey.shade400, width: 1)
            : null,
      ),
    );

    // For animated entries show a visual hint
    if (animated) {
      dot = Stack(
        alignment: Alignment.center,
        children: [
          dot,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: animationType == 'flash' ? Colors.white : Colors.white54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 0.5),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dot,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (animated) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        animationType == 'flash' ? 'flashing' : 'pulsing',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ]),
                Text(meaning,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flow card (all-clear state — PRD v0.7 D-16) ────────────────────────────

class _FlowCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FlowCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 155,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restart countdown with reassurance (PRD v0.7 D-23) ─────────────────────

class _RestartCountdown extends StatelessWidget {
  final int secondsRemaining;
  const _RestartCountdown({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Restarting your router\u2026  $timeStr remaining',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            "Don't worry \u2014 this is normal. Your devices will "
            'disconnect for a couple minutes, then reconnect '
            "on their own. You don't need to do anything.\n\n"
            'This page will reload automatically when your '
            'router is back online.',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
