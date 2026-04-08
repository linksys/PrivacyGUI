import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';

/// PRD v0.7 Tab 3: Help Me Fix It
///
/// Entry screen: 5 flow cards. Tapping one launches a guided step-by-step flow.
/// Back navigation returns to the card menu.
class HelpMeFixItTab extends ConsumerStatefulWidget {
  /// When set, opening this tab immediately launches the indicated flow (1-5).
  /// After consuming the value, the notifier is reset to null.
  final ValueNotifier<int?>? pendingFlowNotifier;

  const HelpMeFixItTab({super.key, this.pendingFlowNotifier});

  @override
  ConsumerState<HelpMeFixItTab> createState() => _HelpMeFixItTabState();
}

class _HelpMeFixItTabState extends ConsumerState<HelpMeFixItTab> {
  int? _activeFlow;

  @override
  void initState() {
    super.initState();
    widget.pendingFlowNotifier?.addListener(_onPendingFlow);
    // Tab 3 may be built AFTER the notifier was set (TabBarView lazy build).
    // Check on first frame so we catch a pending value set before this initState ran.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPendingFlow());
  }

  @override
  void dispose() {
    widget.pendingFlowNotifier?.removeListener(_onPendingFlow);
    super.dispose();
  }

  void _onPendingFlow() {
    final flow = widget.pendingFlowNotifier?.value;
    if (flow != null && mounted) {
      setState(() => _activeFlow = flow);
      widget.pendingFlowNotifier!.value = null; // consume
    }
  }

  void _launchFlow(int flow) => setState(() => _activeFlow = flow);
  void _exitFlow() => setState(() => _activeFlow = null);

  @override
  Widget build(BuildContext context) {
    if (_activeFlow == null) {
      return _FlowMenu(onSelect: _launchFlow);
    }

    Widget flowWidget;
    switch (_activeFlow!) {
      case 1:
        flowWidget = _Flow1(onDone: _exitFlow);
      case 2:
        flowWidget = _Flow2(
          onDone: _exitFlow,
          onNavigateToFlow: _launchFlow,
        );
      case 3:
        flowWidget = _Flow3(onDone: _exitFlow);
      case 4:
        flowWidget = _Flow4(onDone: _exitFlow);
      case 5:
        flowWidget = _Flow5(
          onDone: _exitFlow,
          onNavigateToFlow: _launchFlow,
        );
      default:
        flowWidget = const SizedBox.shrink();
    }

    return _FlowShell(
      title: _flowTitle(_activeFlow!),
      onBack: _exitFlow,
      child: flowWidget,
    );
  }

  static String _flowTitle(int flow) => switch (flow) {
        1 => 'My internet isn\'t working',
        2 => 'My internet is slow',
        3 => 'Device connectivity issues',
        4 => 'WiFi doesn\'t reach a room',
        5 => 'My connection keeps cutting out',
        _ => 'Help Me Fix It',
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow Menu — with pre-qualifier to route device-specific issues to Flow 3
// ═══════════════════════════════════════════════════════════════════════════

class _FlowMenu extends StatefulWidget {
  final ValueChanged<int> onSelect;
  const _FlowMenu({required this.onSelect});

  @override
  State<_FlowMenu> createState() => _FlowMenuState();
}

class _FlowMenuState extends State<_FlowMenu> {
  /// null = show qualifier, true = show all flows, false = went to Flow 3
  bool? _showAllFlows;

  @override
  Widget build(BuildContext context) {
    // Pre-qualifier: "Is this happening on one device or everything?" (Item 13)
    if (_showAllFlows == null) {
      return _qualifier(context);
    }
    return _flowCards(context);
  }

  Widget _qualifier(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'What are you running into?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Is it affecting one specific device or everything?',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onSelect(3), // → Flow 3
                    icon: const Icon(Icons.smartphone),
                    label: const Text('One specific device'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _showAllFlows = true),
                    icon: const Icon(Icons.devices),
                    label: const Text('Everything in my home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _flowCards(BuildContext context) {
    final flows = [
      (1, Icons.wifi_off, 'My internet isn\'t working',
          'Websites won\'t load, devices can\'t get online'),
      (2, Icons.speed, 'My internet is slow',
          'Videos buffer, downloads are sluggish'),
      (3, Icons.devices, 'Device connectivity issues',
          'A device won\'t connect or keeps dropping off WiFi'),
      (4, Icons.signal_wifi_bad, 'WiFi doesn\'t reach a room',
          'Weak signal in part of your home'),
      (5, Icons.sync_problem, 'My connection keeps cutting out',
          'Internet drops and comes back on its own'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'What are you running into?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        for (final (index, icon, title, subtitle) in flows)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 28),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(subtitle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => widget.onSelect(index),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow Shell
// ═══════════════════════════════════════════════════════════════════════════

class _FlowShell extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  const _FlowShell(
      {required this.title, required this.onBack, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              tooltip: 'Back to flows',
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets + helpers
// ═══════════════════════════════════════════════════════════════════════════

Widget _stepCard(BuildContext context, Widget child) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );

Widget _infoBox(BuildContext context, String text,
    {IconData icon = Icons.info_outline, Color? color}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18,
            color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
            child:
                SelectableText(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );
}

Widget _checklistItem(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box_outline_blank, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: SelectableText(text,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );

/// ISP or Linksys support script — always SelectableText so customer can copy it.
Widget _ispScript(BuildContext context, String script) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Say to your provider:',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SelectableText('"$script"',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );

/// Always show at the bottom of a dead-end screen — never leave customers stranded.
Widget _linksysSupportTile(BuildContext context) => Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.headset_mic,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Still need help?',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            SelectableText(
              'Contact Linksys Support:\nwww.linksys.com/support  •  1-800-326-7114',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );

/// Centralised restart confirmation. Shows a dialog, then calls restartRouter().
Future<void> _confirmAndRestart(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restart your router?'),
      content: const Text(
          'All devices will disconnect for about 2 minutes.\n\n'
          'If you\'re on WiFi, this page will go blank. '
          'Wait 2 minutes, reconnect to your WiFi, then return to 192.168.1.1.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Restart'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(instantVerifyPivotProvider.notifier).restartRouter();
  }
}

class _LoadingButton extends StatelessWidget {
  final String label;
  const _LoadingButton({required this.label});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2)),
        label: Text(label),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow 1: My internet isn't working
//
// Auto-runs 3 layered checks on entry:
//   Layer 1 — Gateway ping: Can this device reach the Linksys router?
//   Layer 2 — Public IP ping: Can we reach a public IP (1.1.1.1/8.8.8.8)?
//   Layer 3 — DNS check: Can domain names resolve?
//
// Branching based on which layer first fails.
// ═══════════════════════════════════════════════════════════════════════════

enum _Flow1Phase { running, gatewayFail, internetFail, dnsFail, allOk }

class _Flow1 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const _Flow1({required this.onDone});

  @override
  ConsumerState<_Flow1> createState() => _Flow1State();
}

class _Flow1State extends ConsumerState<_Flow1> {
  _Flow1Phase _phase = _Flow1Phase.running;
  bool _gatewayOk = false;
  bool _internetOk = false;
  bool _dnsOk = false;
  bool _isRestarting = false;
  bool _restarted = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _phase = _Flow1Phase.running);
    final svc = ref.read(browserDiagnosticServiceProvider);

    // Layer 1: Gateway
    final gateway = await svc.pingGateway();
    if (!mounted) return;
    setState(() => _gatewayOk = gateway.reachable);

    if (!gateway.reachable) {
      setState(() => _phase = _Flow1Phase.gatewayFail);
      return;
    }

    // Layer 2: Public IP (no DNS)
    final publicIp = await svc.pingPublicIp();
    if (!mounted) return;
    setState(() => _internetOk = publicIp.reachable);

    if (!publicIp.reachable) {
      setState(() => _phase = _Flow1Phase.internetFail);
      return;
    }

    // Layer 3: DNS
    final dns = await svc.checkDns();
    if (!mounted) return;
    setState(() => _dnsOk = dns.resolved);
    setState(() => _phase = dns.resolved ? _Flow1Phase.allOk : _Flow1Phase.dnsFail);
  }

  Future<void> _restart() async {
    if (!mounted) return;
    await _confirmAndRestart(context, ref);
    if (!mounted) return;
    setState(() {
      _restarted = true;
      _isRestarting = false;
    });
    // After restart, re-run diagnostics
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _runDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _diagnosticProgressCard(context),
        const SizedBox(height: 4),
        if (_phase == _Flow1Phase.running) ..._running(context),
        if (_phase == _Flow1Phase.gatewayFail) ..._gatewayFailPath(context),
        if (_phase == _Flow1Phase.internetFail) ..._internetFailPath(context),
        if (_phase == _Flow1Phase.dnsFail) ..._dnsFailPath(context),
        if (_phase == _Flow1Phase.allOk) ..._allOkPath(context),
      ],
    );
  }

  Widget _diagnosticProgressCard(BuildContext context) {
    return _stepCard(context, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Running diagnostics…',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _checkRow(context, 'Your device → Router',
            _phase == _Flow1Phase.running && !_gatewayOk
                ? null
                : _gatewayOk),
        _checkRow(context, 'Router → Internet',
            _phase == _Flow1Phase.running && _gatewayOk && !_internetOk
                ? null
                : (_gatewayOk ? _internetOk : null)),
        _checkRow(context, 'DNS (website names)',
            _phase == _Flow1Phase.running && _internetOk
                ? null
                : (_internetOk ? _dnsOk : null)),
      ],
    ));
  }

  Widget _checkRow(BuildContext context, String label, bool? result) {
    Widget indicator;
    if (result == null) {
      indicator = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else if (result) {
      indicator =
          const Icon(Icons.check_circle, color: Colors.green, size: 18);
    } else {
      indicator = const Icon(Icons.cancel, color: Colors.red, size: 18);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        indicator,
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }

  List<Widget> _running(BuildContext context) => [
        _infoBox(context, 'Checking your connection…', icon: Icons.search),
      ];

  List<Widget> _gatewayFailPath(BuildContext context) => [
        _infoBox(context,
            'Your device can\'t reach your router. This is usually a WiFi or cable issue between your device and the router.',
            icon: Icons.wifi_off, color: Colors.orange),
        const SizedBox(height: 8),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Check your connection to the router',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _checklistItem(context,
                'Make sure you\'re connected to your Linksys WiFi network (not a neighbor\'s)'),
            _checklistItem(context,
                'If you\'re using a wired connection, check that the Ethernet cable is firmly plugged in at both ends'),
            _checklistItem(context,
                'Move closer to your router and try again'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.refresh),
                label: const Text('Check again'),
              ),
            ),
          ],
        )),
        _linksysSupportTile(context),
      ];

  List<Widget> _internetFailPath(BuildContext context) => [
        _infoBox(context,
            'Your router is reachable but can\'t get to the internet. The issue is likely between your router and the box from your internet company (modem).',
            icon: Icons.cloud_off, color: Colors.red),
        const SizedBox(height: 8),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Check the connection to your modem',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _checklistItem(context,
                'Find the box from your internet company (Comcast, Spectrum, AT&T, etc.) — it\'s separate from your Linksys router'),
            _checklistItem(context,
                'Check that the cable between that box and your Linksys router is firmly plugged in at both ends'),
            _checklistItem(context,
                'Look for lights on that box — if all lights are off or blinking red, the issue is with your internet service'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.refresh),
                label: const Text('Check again'),
              ),
            ),
          ],
        )),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('If cables are fine, contact your internet provider',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ispScript(context,
                'My router shows it\'s connected but has no internet. I checked the cables. Please check if there\'s an outage in my area.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onDone,
                child: const Text('Done — my internet is working now'),
              ),
            ),
          ],
        )),
        _linksysSupportTile(context),
      ];

  List<Widget> _dnsFailPath(BuildContext context) => [
        _infoBox(context,
            'Your router can reach the internet but domain names aren\'t resolving. This can often be fixed by restarting your router.',
            icon: Icons.dns, color: Colors.orange),
        const SizedBox(height: 8),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Try restarting your router',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Restarting clears DNS cache issues and usually resolves this.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restart Router'),
              ),
            ),
            if (_restarted) ...[
              const SizedBox(height: 8),
              const Text('Diagnostics ran again after restart.',
                  style: TextStyle(color: Colors.green)),
            ],
          ],
        )),
        if (_restarted) ...[
          _stepCard(context, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('If restarting didn\'t fix it:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _ispScript(context,
                  'My internet is connected but websites won\'t load. My router shows it\'s online. I restarted my router but the problem persists.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onDone,
                  child: const Text('Done — my internet is working now'),
                ),
              ),
            ],
          )),
        ],
        _linksysSupportTile(context),
      ];

  List<Widget> _allOkPath(BuildContext context) => [
        _infoBox(context,
            'Everything looks fine right now — your device can reach the internet and DNS is working.',
            icon: Icons.check_circle, color: Colors.green),
        const SizedBox(height: 8),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What are you still seeing?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onDone,
                icon: const Icon(Icons.check),
                label: const Text('It\'s working now'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runDiagnostics,
                icon: const Icon(Icons.refresh),
                label: const Text('Test again — still having issues'),
              ),
            ),
          ],
        )),
        _linksysSupportTile(context),
      ];
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow 2: My internet is slow
// ═══════════════════════════════════════════════════════════════════════════

class _Flow2 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<int> onNavigateToFlow;
  const _Flow2({required this.onDone, required this.onNavigateToFlow});

  @override
  ConsumerState<_Flow2> createState() => _Flow2State();
}

class _Flow2State extends ConsumerState<_Flow2> {
  // 0=run test, 1=result+plan-match, 2=all-or-one, 3=restart+retest, 4=isp
  int _step = 0;
  bool _isRunning = false;
  SpeedTestResult? _speedResult;
  bool _isRestarting = false;
  SpeedTestResult? _postRestartResult;

  double? get _mbps => _speedResult?.downloadMbps;

  String _tier(double mbps) {
    if (mbps < 5) return 'Barely enough for one video call';
    if (mbps < 25) return 'Basic browsing and streaming for 1–2 people';
    if (mbps < 100) return 'Good for most households';
    return 'Fast — handles many devices at once';
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      _isRunning = true;
      _speedResult = null;
      _postRestartResult = null;
    });
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final result = await svc.runInternetSpeedTest();
      setState(() => _speedResult = result);
    } catch (_) {
      setState(() => _speedResult = null);
    } finally {
      setState(() {
        _isRunning = false;
        _step = 1;
      });
    }
  }

  Future<void> _restartAndRetest() async {
    if (!mounted) return;
    await _confirmAndRestart(context, ref);
    if (!mounted) return;
    setState(() => _isRestarting = false);
    // Re-run speed test after restart
    setState(() => _isRunning = true);
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final result = await svc.runInternetSpeedTest();
      setState(() {
        _postRestartResult = result;
        _isRunning = false;
        // If still slow after restart, go to ISP path
        if (result.downloadMbps < 25) {
          _step = 4;
        } else {
          _step = 1; // Show improved result
          _speedResult = result;
        }
      });
    } catch (_) {
      setState(() {
        _isRunning = false;
        _step = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_step == 0) ..._step0(context, state),
        if (_step == 1 && _speedResult != null) ..._step1(context),
        if (_step == 2) ..._step2(context),
        if (_step == 3) ..._step3(context),
        if (_step == 4) ..._step4(context),
      ],
    );
  }

  List<Widget> _step0(BuildContext context, InstantVerifyPivotState state) {
    final weakWifi = state.deviceScores.isNotEmpty &&
        state.deviceScores.first.score < 40;
    return [
      if (weakWifi)
        _infoBox(
          context,
          'Your device has a weak WiFi connection. This reading may be lower than your actual internet speed. Move closer to your router, then run again.',
          icon: Icons.warning_amber,
          color: Colors.orange,
        ),
      const SizedBox(height: 12),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Run a speed test',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_isRunning) ...[
            const Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Running speed test (~20 seconds)…'),
            ]),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _runSpeedTest,
                icon: const Icon(Icons.speed),
                label: const Text('Check my speed'),
              ),
            ),
          ],
        ],
      )),
    ];
  }

  List<Widget> _step1(BuildContext context) {
    final mbps = _mbps!;
    final slow = mbps < 25;
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your speed result',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SelectableText('${mbps.toStringAsFixed(0)} Mbps',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: slow ? Colors.orange : Colors.green,
                      )),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_tier(mbps),
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Speed measured from this device. Speed can vary based on time of day, '
            'how many devices are active, and your distance from the router. '
            'A device experiencing issues may be faster or slower than this reading.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          _SpeedTierTable(currentMbps: mbps),
        ],
      )),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Is this close to what you\'re paying for?',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Check your internet plan to see what speed you should be getting.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('No — it\'s slower than expected'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  // Speed is fine — may be a device-specific issue
                  widget.onNavigateToFlow(3);
                },
                child: const Text('Yes — seems normal'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _runSpeedTest,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Run again'),
          ),
        ],
      )),
    ];
  }

  List<Widget> _step2(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Is it all devices or just one?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _step = 3),
                icon: const Icon(Icons.devices),
                label: const Text('All devices are slow'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onNavigateToFlow(3),
                icon: const Icon(Icons.smartphone),
                label: const Text('Just one device — go to Device Issues'),
              ),
            ),
          ],
        )),
      ];

  List<Widget> _step3(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Try restarting your router',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Restarting can clear congestion and improve speeds.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _isRunning
                  ? const _LoadingButton(label: 'Testing speed after restart…')
                  : FilledButton.icon(
                      onPressed: _restartAndRetest,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Restart + Run Speed Test Again'),
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _step = 4),
              child: const Text('Skip — already restarted'),
            ),
          ],
        )),
      ];

  List<Widget> _step4(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact your internet provider',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Since restarting didn\'t fix it, the issue is likely outside your router.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _ispScript(context,
                'My internet is slower than what I\'m paying for. My speed test shows ${_postRestartResult?.downloadMbps.toStringAsFixed(0) ?? _mbps?.toStringAsFixed(0) ?? '?'} Mbps. I restarted my router but the problem persists.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onDone,
                child: const Text('Done'),
              ),
            ),
          ],
        )),
        _linksysSupportTile(context),
      ];
}

class _SpeedTierTable extends StatelessWidget {
  final double currentMbps;
  const _SpeedTierTable({required this.currentMbps});

  @override
  Widget build(BuildContext context) {
    final tiers = [
      ('< 5 Mbps', 'Barely enough for one video call', currentMbps < 5),
      ('5–25 Mbps', 'Basic browsing and streaming for 1–2 people',
          currentMbps >= 5 && currentMbps < 25),
      ('25–100 Mbps', 'Good for most households',
          currentMbps >= 25 && currentMbps < 100),
      ('100+ Mbps', 'Fast — handles many devices at once',
          currentMbps >= 100),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiers.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tiers[i].$3
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.4)
                    : null,
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(7))
                    : i == tiers.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(7))
                        : null,
              ),
              child: Row(
                children: [
                  if (tiers[i].$3)
                    const Icon(Icons.arrow_right, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 90,
                    child: Text(tiers[i].$1,
                        style: TextStyle(
                            fontWeight: tiers[i].$3
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(tiers[i].$2,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: tiers[i].$3
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: tiers[i].$3
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow 3: Device connectivity issues
// ═══════════════════════════════════════════════════════════════════════════

enum _DeviceType { phone, laptop, smartHome, gaming, other }
enum _ConnectState { canConnect, cantConnect }
enum _ConnectIssue { keepsDropping, slowOnDevice, other }

class _Flow3 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const _Flow3({required this.onDone});

  @override
  ConsumerState<_Flow3> createState() => _Flow3State();
}

class _Flow3State extends ConsumerState<_Flow3> {
  // 0=can-connect?, 1a=issue-type (if connected), 1b=device-type (if not connected), 2a=keeps-dropping, 2b=path-A or 2c=path-B
  int _step = 0;
  _ConnectState? _connectState;
  _ConnectIssue? _connectIssue;
  _DeviceType? _deviceType;
  bool _isDisablingMacFilter = false;
  bool _macFilterDisabled = false;
  // null = not yet answered, true = can see SSID, false = can't see SSID (Item 12)
  bool? _canSeeSsid;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_step == 0) ..._step0(context),
        if (_step == 1 && _connectState == _ConnectState.canConnect) ..._step1Connected(context),
        if (_step == 2 && _connectIssue == _ConnectIssue.keepsDropping) ..._keepsDroppingFlow(context, state),
        if (_step == 1 && _connectState == _ConnectState.cantConnect) ..._step1CantConnect(context),
        if (_step == 3) ..._pathA(context, state),
        if (_step == 4) ..._pathB(context, state),
      ],
    );
  }

  List<Widget> _step0(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Can your device connect to your WiFi?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SelectableText(
              'It may show as connected but have no internet, or it may not connect at all.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _connectState = _ConnectState.canConnect;
                  _step = 1;
                }),
                icon: const Icon(Icons.wifi),
                label: const Text('Yes — it\'s connected but something is wrong'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _connectState = _ConnectState.cantConnect;
                  _step = 1;
                }),
                icon: const Icon(Icons.wifi_off),
                label: const Text('No — it won\'t connect at all'),
              ),
            ),
          ],
        )),
      ];

  List<Widget> _step1Connected(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What\'s happening?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _connectIssue = _ConnectIssue.keepsDropping;
                  _step = 2;
                }),
                icon: const Icon(Icons.sync_problem),
                label: const Text('It keeps dropping off WiFi'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _connectIssue = _ConnectIssue.slowOnDevice;
                  _step = 2; // Will redirect to slow-device advice
                }),
                icon: const Icon(Icons.speed),
                label: const Text('It\'s connected but internet is slow on this device'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _connectIssue = _ConnectIssue.other;
                  _step = 1; // Show device type picker
                  _connectState = _ConnectState.cantConnect;
                }),
                icon: const Icon(Icons.help_outline),
                label: const Text('Something else'),
              ),
            ),
          ],
        )),
        if (_step == 2 && _connectIssue == _ConnectIssue.slowOnDevice) ...[
          _stepCard(context, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoBox(context,
                  'For slow speed on a specific device, go to My Devices → tap the device to see its signal quality and get tailored advice.',
                  icon: Icons.info_outline),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onDone,
                  child: const Text('Go to My Devices'),
                ),
              ),
            ],
          )),
        ],
      ];

  List<Widget> _keepsDroppingFlow(BuildContext context, InstantVerifyPivotState state) {
    final deviceSignal = state.deviceScores.isNotEmpty
        ? state.deviceScores.first
        : null;
    final weakSignal = deviceSignal != null && deviceSignal.score < 40;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device keeps dropping WiFi',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (weakSignal)
            _infoBox(
              context,
              'We noticed this device has a weak WiFi signal. Moving it closer to your router may stop the drops.',
              icon: Icons.signal_wifi_statusbar_connected_no_internet_4,
              color: Colors.orange,
            ),
          const SizedBox(height: 8),
          _checklistItem(context,
              'Move the device closer to your router — intermittent drops are often caused by weak signal'),
          _checklistItem(context,
              'Check if the device is connecting to the 2.4 GHz band — it has longer range but is more prone to interference'),
          _checklistItem(context,
              'Try forgetting your WiFi network on this device, then reconnect fresh'),
          _checklistItem(context,
              'Check if other devices on the same band also drop — if yes, it\'s likely a router issue'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmAndRestart(context, ref),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart Router'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onDone,
              child: const Text('Device stopped dropping'),
            ),
          ),
        ],
      )),
      _linksysSupportTile(context),
    ];
  }

  List<Widget> _step1CantConnect(BuildContext context) {
    // Step 1a (Item 12): Ask if the customer can see the SSID before showing credentials.
    // Use the actual SSID name so the question is specific, not generic.
    final state = ref.watch(instantVerifyPivotProvider);
    final ssid = state.wifiSsid;
    final ssidLabel = ssid != null ? '"$ssid"' : 'your network name';

    if (_canSeeSsid == null) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Can you see $ssidLabel in your device\'s WiFi list?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SelectableText(
              'Open your device\'s WiFi settings and look for the network name above.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _canSeeSsid = true),
                child: const Text('Yes — I can see it'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _canSeeSsid = false),
                child: const Text('No — I don\'t see it'),
              ),
            ),
          ],
        )),
      ];
    }

    // Customer can't see the SSID at all — different problem from wrong password
    if (_canSeeSsid == false) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network not visible',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _infoBox(context,
                'If the network name isn\'t showing on your device, the issue is with your router\'s WiFi broadcast — not the password.'),
            const SizedBox(height: 12),
            _checklistItem(context,
                'Make sure your router is powered on and the WiFi light is on'),
            _checklistItem(context,
                'Check that WiFi is enabled in your router settings'),
            _checklistItem(context,
                'Move your device closer to the router and check again'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmAndRestart(context, ref),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restart Router'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _canSeeSsid = null),
                child: const Text('Back'),
              ),
            ),
          ],
        )),
        _linksysSupportTile(context),
      ];
    }

    // Customer CAN see the SSID — now show device type picker
    final types = [
      (_DeviceType.phone, 'Phone or tablet'),
      (_DeviceType.laptop, 'Laptop or computer'),
      (_DeviceType.smartHome,
          'Smart home device (thermostat, camera, smart bulb, speaker)'),
      (_DeviceType.gaming, 'Gaming console or TV'),
      (_DeviceType.other, 'Something else'),
    ];

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What kind of device is it?',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final (type, label) in types)
            RadioListTile<_DeviceType>(
              value: type,
              groupValue: _deviceType,
              title: Text(label),
              onChanged: (v) => setState(() => _deviceType = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _deviceType == null
                  ? null
                  : () => setState(() =>
                      _step = _deviceType == _DeviceType.smartHome ? 4 : 3),
              child: const Text('Continue'),
            ),
          ),
        ],
      )),
    ];
  }

  List<Widget> _pathA(BuildContext context, InstantVerifyPivotState state) {
    final ssid = state.wifiSsid ?? '(see router settings)';
    final password = state.wifiPassword ?? '(see router settings)';
    final macActive = state.isMacFilterEnabled && !_macFilterDisabled;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check your WiFi details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _wifiCredRow(context, 'Network name', ssid),
          const SizedBox(height: 6),
          _wifiCredRow(context, 'Password', password),
          const SizedBox(height: 12),
          _checklistItem(context,
              'Make sure you\'re selecting the right network name above'),
          _checklistItem(
              context, 'Check that caps lock is off when entering the password'),
          _checklistItem(context,
              'Try forgetting the network on your device and reconnecting'),
        ],
      )),
      if (macActive)
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBox(
              context,
              'Your router has a device blocklist turned on.\n\nThis controls which devices can connect — it may be blocking this device.\n\nTurning it off lets any device join using your WiFi password. Your password is still required.',
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _isDisablingMacFilter
                    ? const _LoadingButton(label: 'Turning off…')
                    : FilledButton(
                        onPressed: _disableMacFilter,
                        child: const Text('Turn off blocklist'),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Leave it on'),
                ),
              ),
            ]),
          ],
        )),
      if (_macFilterDisabled)
        _infoBox(context, 'Device blocklist turned off. Try connecting again.',
            icon: Icons.check_circle_outline, color: Colors.green),
      const SizedBox(height: 8),
      _stepCard(context, Column(children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmAndRestart(context, ref),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Try restarting your router'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.onDone,
            child: const Text('Device is connected now'),
          ),
        ),
      ])),
      _linksysSupportTile(context),
    ];
  }

  List<Widget> _pathB(BuildContext context, InstantVerifyPivotState state) {
    final ssid = state.wifiSsid ?? '(see router settings)';
    final password = state.wifiPassword ?? '(see router settings)';
    final wpa3Only = state.isWpa3Only;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connect your smart home device',
              style: Theme.of(context)
                  .textTheme
                  ?.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _checklistItem(context,
              'Make sure your phone is on the same WiFi network you want the device on — not a guest network'),
          _checklistItem(context,
              'Use the 2.4 GHz network if your router has separate names for 2.4 and 5 GHz'),
          const SizedBox(height: 8),
          _wifiCredRow(context, 'Network name', ssid),
          const SizedBox(height: 6),
          _wifiCredRow(context, 'Password', password),
        ],
      )),
      if (wpa3Only)
        _stepCard(context,
            _infoBox(
              context,
              'Some older smart home devices don\'t support the latest WiFi security standard. If this device keeps failing:\n\nGo to My Network → WiFi Security and check if "WPA2 compatibility" is enabled.',
            )),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: widget.onDone,
          child: const Text('Device is connected now'),
        ),
      ),
      _linksysSupportTile(context),
    ];
  }

  Widget _wifiCredRow(BuildContext context, String label, String value) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ),
          Expanded(
            child: SelectableText(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      );

  Future<void> _disableMacFilter() async {
    setState(() => _isDisablingMacFilter = true);
    await ref.read(instantVerifyPivotProvider.notifier).disableMacFilter();
    setState(() {
      _isDisablingMacFilter = false;
      _macFilterDisabled = true;
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow 4: WiFi doesn't reach a room (unchanged)
// ═══════════════════════════════════════════════════════════════════════════

enum _RouterPlacement { center, corner, enclosed }

class _Flow4 extends StatefulWidget {
  final VoidCallback onDone;
  const _Flow4({required this.onDone});

  @override
  State<_Flow4> createState() => _Flow4State();
}

class _Flow4State extends State<_Flow4> {
  int _step = 0;
  _RouterPlacement? _placement;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) ..._step0(context),
          if (_step == 1) ..._step1(context),
        ],
      );

  List<Widget> _step0(BuildContext context) {
    final options = [
      (_RouterPlacement.center, 'Center of my home or close to it'),
      (_RouterPlacement.corner, 'Near a wall, door, or in a corner'),
      (_RouterPlacement.enclosed, 'Inside a closet, cabinet, or behind the TV'),
    ];
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where is your router right now?',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final (val, label) in options)
            RadioListTile<_RouterPlacement>(
              value: val,
              groupValue: _placement,
              title: Text(label),
              onChanged: (v) => setState(() => _placement = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _placement == null ? null : () => setState(() => _step = 1),
              child: const Text('Continue'),
            ),
          ),
        ],
      )),
    ];
  }

  List<Widget> _step1(BuildContext context) {
    String advice = switch (_placement) {
      _RouterPlacement.enclosed =>
        'Move your router out into the open. Enclosures block WiFi signals significantly — even a shelf in the open can double your range.',
      _RouterPlacement.corner =>
        'Move your router toward the center of your home — halfway between the router and the room with weak signal.',
      _ =>
        'Your placement is good. The issue may be building materials (concrete, brick, or metal studs between rooms).',
    };

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Placement tip',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText(advice,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      )),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick tips',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _tipRow(context, Icons.check, 'Keep your router elevated — on a shelf or table, not the floor'),
          _tipRow(context, Icons.check, 'Point antennas vertically if your router has them'),
          _tipRow(context, Icons.check, 'Keep it away from microwaves, baby monitors, and cordless phones'),
          _tipRow(context, Icons.close, 'Don\'t put it inside a cabinet, closet, or entertainment unit'),
        ],
      )),
      _stepCard(context,
          _infoBox(
            context,
            'If you live in an apartment building or dense area, interference from neighboring WiFi networks can cause weak signal — even with perfect placement.',
          )),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Need more coverage?',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText(
            'Adding a Linksys satellite node in that room extends your WiFi coverage using the same network name and password — your devices connect automatically.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      )),
      SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: widget.onDone, child: const Text('Done')),
      ),
      _linksysSupportTile(context),
    ];
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color: icon == Icons.check ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Expanded(
                child: SelectableText(text,
                    style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Flow 5: My connection keeps cutting out
// ═══════════════════════════════════════════════════════════════════════════

enum _DropFrequency { everyFewMinutes, fewTimesDay }
enum _DropScope { wholeInternet, specificDevices }

class _Flow5 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<int> onNavigateToFlow;
  const _Flow5({required this.onDone, required this.onNavigateToFlow});

  @override
  ConsumerState<_Flow5> createState() => _Flow5State();
}

class _Flow5State extends ConsumerState<_Flow5> {
  int _step = 0;
  _DropFrequency? _frequency;
  _DropScope? _scope;

  bool _isMonitoring = false;
  int _dropsDetected = 0;
  int _checksCompleted = 0;
  static const int _totalChecks = 5;

  Timer? _monitorTimer;
  bool? _restartFixed; // null=not done, true=fixed, false=still dropping

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _startMonitor() async {
    setState(() {
      _isMonitoring = true;
      _dropsDetected = 0;
      _checksCompleted = 0;
    });
    final svc = ref.read(browserDiagnosticServiceProvider);
    _monitorTimer = Timer.periodic(const Duration(seconds: 24), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final ping = await svc.pingGateway();
      if (!mounted) return;
      setState(() {
        _checksCompleted++;
        if (!ping.reachable) _dropsDetected++;
        if (_checksCompleted >= _totalChecks) {
          timer.cancel();
          _isMonitoring = false;
          _step = 3;
        }
      });
    });
  }

  Future<void> _restartAndCheck() async {
    if (!mounted) return;
    await _confirmAndRestart(context, ref);
    if (!mounted) return;
    // Run post-restart drop check
    setState(() {
      _isMonitoring = true;
      _checksCompleted = 0;
      _dropsDetected = 0;
    });
    final svc = ref.read(browserDiagnosticServiceProvider);
    int drops = 0;
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      final ping = await svc.pingGateway();
      if (!ping.reachable) drops++;
      if (!mounted) return;
      setState(() {
        _checksCompleted = i + 1;
        _dropsDetected = drops;
      });
    }
    if (!mounted) return;
    setState(() {
      _isMonitoring = false;
      _restartFixed = drops == 0;
      _step = 4;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) ..._step0(context),
          if (_step == 1) ..._step1Scope(context),
          if (_step == 2) ..._step2Monitor(context),
          if (_step == 3) ..._step3Result(context),
          if (_step == 4) ..._step4PostRestart(context),
        ],
      );

  List<Widget> _step0(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How often does it drop?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioListTile<_DropFrequency>(
              value: _DropFrequency.everyFewMinutes,
              groupValue: _frequency,
              title: const Text('Every few minutes'),
              onChanged: (v) => setState(() => _frequency = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<_DropFrequency>(
              value: _DropFrequency.fewTimesDay,
              groupValue: _frequency,
              title: const Text('A few times a day'),
              onChanged: (v) => setState(() => _frequency = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _frequency == null
                    ? null
                    : () => setState(() => _step = 1),
                child: const Text('Continue'),
              ),
            ),
          ],
        )),
      ];

  List<Widget> _step1Scope(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Is it everything or specific devices?',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioListTile<_DropScope>(
              value: _DropScope.wholeInternet,
              groupValue: _scope,
              title: const Text('My whole internet goes out — all devices stop at once'),
              onChanged: (v) => setState(() => _scope = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<_DropScope>(
              value: _DropScope.specificDevices,
              groupValue: _scope,
              title: const Text('Just specific devices lose connection'),
              onChanged: (v) => setState(() => _scope = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 12),
            if (_scope == _DropScope.specificDevices) ...[
              _infoBox(
                context,
                'This sounds like a device issue rather than a whole-network problem. The Device connectivity issues flow will help.',
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onNavigateToFlow(3),
                  icon: const Icon(Icons.devices),
                  label: const Text('Go to Device connectivity issues'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _scope == null
                      ? null
                      : () => setState(() => _step = 2),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ],
        )),
      ];

  List<Widget> _step2Monitor(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Run a 2-minute connection test',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _infoBox(
              context,
              'We\'ll check every ~25 seconds whether your router can reach the internet. This runs for about 2 minutes. Keep this page open.',
            ),
            const SizedBox(height: 12),
            if (!_isMonitoring && _checksCompleted == 0) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startMonitor,
                  icon: const Icon(Icons.monitor_heart),
                  label: const Text('Start connection test'),
                ),
              ),
            ] else if (_isMonitoring) ...[
              Row(children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text(
                    'Monitoring… (check ${_checksCompleted + 1} of $_totalChecks)'),
              ]),
              if (_dropsDetected > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$_dropsDetected drop${_dropsDetected == 1 ? '' : 's'} detected so far',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ],
        )),
      ];

  List<Widget> _step3Result(BuildContext context) {
    final hasDrops = _dropsDetected > 0;
    final isFrequent = _frequency == _DropFrequency.everyFewMinutes;

    if (hasDrops) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                  '$_dropsDetected drop${_dropsDetected == 1 ? '' : 's'} detected during the test'),
            ]),
            const SizedBox(height: 12),
            Text('Restarting your router clears up most drop issues.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restartAndCheck,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restart Router'),
              ),
            ),
          ],
        )),
      ];
    }

    if (isFrequent) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('No drops caught during the test.')),
            ]),
            const SizedBox(height: 8),
            SelectableText(
              'The drops happen frequently but we didn\'t catch one right now. Try restarting your router — this fixes most intermittent drop issues.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restartAndCheck,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restart Router'),
              ),
            ),
          ],
        )),
      ];
    }

    // A few times a day, no drops
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('No drops detected right now.')),
          ]),
          const SizedBox(height: 8),
          SelectableText(
            'Intermittent drops that happen a few times a day are hard to catch in a short test. Try restarting your router as a first step — it resolves most intermittent issues.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _checklistItem(context,
              'Check if the drops happen at a specific time (heavy usage periods like evenings can cause congestion)'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _restartAndCheck,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart Router'),
            ),
          ),
          const SizedBox(height: 8),
          Text('If drops continue after a restart:',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          _ispScript(context,
              'My connection drops several times a day. I restarted my router but the problem persists.'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onDone,
              child: const Text('Done'),
            ),
          ),
        ],
      )),
      _linksysSupportTile(context),
    ];
  }

  List<Widget> _step4PostRestart(BuildContext context) {
    if (_isMonitoring) {
      return [
        _stepCard(context,
            Row(children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              const Text('Checking connection after restart…'),
            ])),
      ];
    }

    if (_restartFixed == true) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Looks like the restart fixed it!')),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: widget.onDone, child: const Text('Done')),
            ),
          ],
        )),
      ];
    }

    final freq = _frequency == _DropFrequency.everyFewMinutes
        ? 'every few minutes'
        : 'several times a day';

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Still dropping after restart',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText(
            'Since restarting didn\'t fix it, the issue is likely outside your router.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _ispScript(context,
              'My connection drops $freq. I restarted my router but the problem persists.'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onDone,
              child: const Text('I\'ll call my provider'),
            ),
          ),
        ],
      )),
      _linksysSupportTile(context),
    ];
  }
}
