import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_provider.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

// Flow 3 uses USP whitelist semantics (D-R3): "allow this device" not "blocklist".
// D-42: step counter + AnimatedSwitcher + no inline Back buttons (shell arrow only).

class HelpMeFixItTab extends ConsumerStatefulWidget {
  /// When set, opening this tab immediately launches the indicated flow.
  /// -1 = reset to landing (tab re-tapped while in a flow).
  final ValueNotifier<int?>? pendingFlowNotifier;

  /// Navigates to My Devices tab.
  final VoidCallback? onNavigateToMyDevices;

  /// Carries the specific device selected in My Devices into the flow.
  final ValueNotifier<DeviceUIModel?>? pendingFlowDeviceNotifier;

  const HelpMeFixItTab({
    super.key,
    this.pendingFlowNotifier,
    this.pendingFlowDeviceNotifier,
    this.onNavigateToMyDevices,
  });

  @override
  ConsumerState<HelpMeFixItTab> createState() => _HelpMeFixItTabState();
}

class _HelpMeFixItTabState extends ConsumerState<HelpMeFixItTab> {
  int? _activeFlow;
  final _flowStepBackNotifier = ValueNotifier<VoidCallback?>(null);
  final _stepIndicatorNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    widget.pendingFlowNotifier?.addListener(_onPendingFlow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPendingFlow());
  }

  @override
  void dispose() {
    widget.pendingFlowNotifier?.removeListener(_onPendingFlow);
    _flowStepBackNotifier.dispose();
    _stepIndicatorNotifier.dispose();
    super.dispose();
  }

  void _onPendingFlow() {
    final flow = widget.pendingFlowNotifier?.value;
    if (flow == null || !mounted) return;
    widget.pendingFlowNotifier!.value = null;
    if (flow == -1) {
      setState(() => _activeFlow = null);
    } else {
      setState(() => _activeFlow = flow);
    }
  }

  void _launchFlow(int flow) {
    const flowNames = {1: 'internet_not_working', 2: 'internet_slow', 3: 'device_connectivity', 4: 'wifi_coverage', 5: 'connection_drops', 6: 'bridge_mode'};
    ref.read(instantTestProvider.notifier).setFlowEntered(flowNames[flow] ?? 'flow_$flow');
    setState(() => _activeFlow = flow);
  }

  void _exitFlow() {
    _flowStepBackNotifier.value = null;
    _stepIndicatorNotifier.value = null;
    setState(() => _activeFlow = null);
  }

  void _handleShellBack() {
    final stepBack = _flowStepBackNotifier.value;
    if (stepBack != null) {
      stepBack();
    } else {
      _exitFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeFlow == null) {
      return _FlowMenu(onSelect: _launchFlow);
    }

    Widget flowWidget;
    switch (_activeFlow!) {
      case 1:
        flowWidget = _Flow1(onDone: _exitFlow, onNavigateToFlow: _launchFlow, stepBackNotifier: _flowStepBackNotifier);
      case 2:
        flowWidget = _Flow2(onDone: _exitFlow, onNavigateToFlow: _launchFlow, stepBackNotifier: _flowStepBackNotifier, stepIndicatorNotifier: _stepIndicatorNotifier);
      case 3:
        flowWidget = _Flow3(onDone: _exitFlow, onNavigateToMyDevices: widget.onNavigateToMyDevices, stepBackNotifier: _flowStepBackNotifier, stepIndicatorNotifier: _stepIndicatorNotifier);
      case 30:
        final device = widget.pendingFlowDeviceNotifier?.value;
        widget.pendingFlowDeviceNotifier?.value = null;
        flowWidget = _Flow3(onDone: _exitFlow, onNavigateToMyDevices: widget.onNavigateToMyDevices, initialConnected: true, initialDevice: device, stepBackNotifier: _flowStepBackNotifier, stepIndicatorNotifier: _stepIndicatorNotifier);
      case 31:
        flowWidget = _Flow3(onDone: _exitFlow, onNavigateToMyDevices: widget.onNavigateToMyDevices, initialConnected: true, initialSlowDevice: true, stepBackNotifier: _flowStepBackNotifier, stepIndicatorNotifier: _stepIndicatorNotifier);
      case 4:
        flowWidget = _Flow4(onDone: _exitFlow, stepBackNotifier: _flowStepBackNotifier);
      case 5:
        flowWidget = _Flow5(onDone: _exitFlow, onNavigateToFlow: _launchFlow, stepBackNotifier: _flowStepBackNotifier, stepIndicatorNotifier: _stepIndicatorNotifier);
      case 6:
        flowWidget = _Flow6BridgeMode(onDone: _exitFlow, stepBackNotifier: _flowStepBackNotifier, stepIndicatorNotifier: _stepIndicatorNotifier);
      default:
        flowWidget = const SizedBox.shrink();
    }

    return _FlowShell(
      title: _flowTitle(_activeFlow!),
      onBack: _handleShellBack,
      stepIndicatorNotifier: _stepIndicatorNotifier,
      child: flowWidget,
    );
  }

  static String _flowTitle(int flow) => switch (flow) {
        1 => 'My internet isn\'t working',
        2 => 'My internet is slow',
        3 => 'Device connectivity issues',
        4 => 'WiFi doesn\'t reach a room',
        5 => 'My connection keeps cutting out',
        6 => 'Two routers / Combo gateway',
        _ => 'Help Me Fix It',
      };
}

// ── Flow Menu ────────────────────────────────────────────────────────────────

class _FlowMenu extends StatefulWidget {
  final ValueChanged<int> onSelect;
  const _FlowMenu({required this.onSelect});

  @override
  State<_FlowMenu> createState() => _FlowMenuState();
}

class _FlowMenuState extends State<_FlowMenu> {
  bool? _showAllFlows;

  @override
  Widget build(BuildContext context) {
    if (_showAllFlows == null) return _qualifier(context);
    return _flowCards(context);
  }

  Widget _qualifier(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text('What are you running into?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Is it affecting one specific device or everything?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => widget.onSelect(3), icon: const Icon(Icons.smartphone), label: const Text('One specific device'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => _showAllFlows = true), icon: const Icon(Icons.devices), label: const Text('Everything in my home'))),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _flowCards(BuildContext context) {
    final flows = [
      (1, Icons.wifi_off, 'My internet isn\'t working', 'Websites won\'t load, devices can\'t get online'),
      (2, Icons.speed, 'My internet is slow', 'Videos buffer, downloads are sluggish'),
      (3, Icons.devices, 'Device connectivity issues', 'A device won\'t connect or keeps dropping off WiFi'),
      (4, Icons.signal_wifi_bad, 'WiFi doesn\'t reach a room', 'Weak signal in part of your home'),
      (5, Icons.sync_problem, 'My connection keeps cutting out', 'Internet drops and comes back on its own'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('What are you running into?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
        for (final (index, icon, title, subtitle) in flows)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => widget.onSelect(index),
            ),
          ),
      ],
    );
  }
}

// ── Flow Shell (D-42: step counter via ValueListenableBuilder) ────────────────

class _FlowShell extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _FlowShell({required this.title, required this.onBack, required this.child, this.stepIndicatorNotifier});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, tooltip: 'Back to flows'),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: stepIndicatorNotifier != null
              ? ValueListenableBuilder<String?>(
                  valueListenable: stepIndicatorNotifier!,
                  builder: (_, indicator, __) => indicator != null
                      ? Text(indicator, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
                      : const SizedBox.shrink(),
                )
              : null,
        ),
      ),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    ]);
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _stepCard(BuildContext context, Widget child) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );

Widget _infoBox(BuildContext context, String text, {IconData icon = Icons.info_outline, Color? color}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: color ?? Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(child: SelectableText(text, style: Theme.of(context).textTheme.bodyMedium)),
    ]),
  );
}

Widget _checklistItem(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.arrow_right, size: 20, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 4),
        Expanded(child: SelectableText(text, style: Theme.of(context).textTheme.bodyMedium)),
      ]),
    );

class _ClickChecklistItem extends StatefulWidget {
  final String text;
  const _ClickChecklistItem(this.text);

  @override
  State<_ClickChecklistItem> createState() => _ClickChecklistItemState();
}

class _ClickChecklistItemState extends State<_ClickChecklistItem> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _done = !_done),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(_done ? Icons.check_box : Icons.check_box_outline_blank, size: 20, color: _done ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(decoration: _done ? TextDecoration.lineThrough : TextDecoration.none, color: _done ? Theme.of(context).colorScheme.onSurfaceVariant : null))),
        ]),
      ),
    );
  }
}

Widget _ispScript(BuildContext context, String script) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Say to your provider:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SelectableText('"$script"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
      ]),
    );

Widget _linksysSupportTile(BuildContext context) => Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.headset_mic, size: 20, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text('Still need help?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))]),
          const SizedBox(height: 6),
          SelectableText('Contact Linksys Support:\nwww.linksys.com/support  •  1-800-326-7114', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );

/// Restart with Connection Recovery (D-R1). Checks hasRestartedThisSession first.
Future<void> _confirmAndRestart(BuildContext context, WidgetRef ref) async {
  final state = ref.read(instantTestProvider);
  if (state.hasRestartedThisSession) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You\'ve already restarted this session. If the issue persists, contact Linksys Support.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restart your router?'),
      content: const Text('All devices will disconnect for about 2 minutes.\n\nIf you\'re on WiFi, this page will go blank. Wait 2 minutes, reconnect to your WiFi, then return to 192.168.1.1.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Restart')),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    try {
      await ref.read(instantTestProvider.notifier).restartRouter();
      if (!context.mounted) return;
      await showRecoveryDialog(context, ref, trigger: RecoveryTrigger.operationalReboot, cooldown: const Duration(seconds: 60), title: 'Router is rebooting', message: 'All connected devices will be temporarily disconnected. Please wait.', successMessage: 'Router reboot complete');
    } catch (_) {}
  }
}

class _LoadingButton extends StatelessWidget {
  final String label;
  const _LoadingButton({required this.label});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: null, icon: const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)), label: Text(label));
}

// ── Flow 1: My internet isn't working ────────────────────────────────────────

enum _Flow1Phase { running, gatewayFail, internetFail, dnsFail, allOk }

class _Flow1 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<int>? onNavigateToFlow;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  const _Flow1({required this.onDone, this.onNavigateToFlow, this.stepBackNotifier});

  @override
  ConsumerState<_Flow1> createState() => _Flow1State();
}

class _Flow1State extends ConsumerState<_Flow1> {
  _Flow1Phase _phase = _Flow1Phase.running;
  bool _gatewayOk = false;
  bool _internetOk = false;
  bool _dnsOk = false;
  bool _restarted = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _phase = _Flow1Phase.running);
    final svc = ref.read(browserDiagnosticServiceProvider);
    final gateway = await svc.pingGateway();
    if (!mounted) return;
    setState(() => _gatewayOk = gateway.reachable);
    if (!gateway.reachable) { setState(() => _phase = _Flow1Phase.gatewayFail); return; }
    final publicIp = await svc.pingPublicIp();
    if (!mounted) return;
    setState(() => _internetOk = publicIp.reachable);
    if (!publicIp.reachable) { setState(() => _phase = _Flow1Phase.internetFail); return; }
    final dns = await svc.checkDns();
    if (!mounted) return;
    setState(() { _dnsOk = dns.resolved; _phase = dns.resolved ? _Flow1Phase.allOk : _Flow1Phase.dnsFail; });
  }

  Future<void> _restart() async {
    if (!mounted) return;
    await _confirmAndRestart(context, ref);
    if (!mounted) return;
    setState(() { _restarted = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _runDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _diagnosticProgressCard(context),
      const SizedBox(height: 4),
      if (_phase == _Flow1Phase.running) ..._running(context),
      if (_phase == _Flow1Phase.gatewayFail) ..._gatewayFailPath(context),
      if (_phase == _Flow1Phase.internetFail) ..._internetFailPath(context),
      if (_phase == _Flow1Phase.dnsFail) ..._dnsFailPath(context),
      if (_phase == _Flow1Phase.allOk) ..._allOkPath(context),
    ]);
  }

  Widget _diagnosticProgressCard(BuildContext context) {
    return _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Running diagnostics…', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      _checkRow(context, 'This device reached your router', _phase == _Flow1Phase.running && !_gatewayOk ? null : _gatewayOk),
      _checkRow(context, 'Your router reached the internet', _phase == _Flow1Phase.running && _gatewayOk && !_internetOk ? null : (_gatewayOk ? _internetOk : null)),
      _checkRow(context, 'Websites are loading', _phase == _Flow1Phase.running && _internetOk ? null : (_internetOk ? _dnsOk : null)),
    ]));
  }

  Widget _checkRow(BuildContext context, String label, bool? result) {
    Widget indicator;
    if (result == null) {
      indicator = const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (result) {
      indicator = const Icon(Icons.check_circle, color: Colors.green, size: 18);
    } else {
      indicator = const Icon(Icons.cancel, color: Colors.red, size: 18);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [indicator, const SizedBox(width: 10), Text(label, style: Theme.of(context).textTheme.bodyMedium)]));
  }

  List<Widget> _running(BuildContext context) => [_infoBox(context, 'Checking your connection…', icon: Icons.search)];

  List<Widget> _gatewayFailPath(BuildContext context) => [
        _infoBox(context, 'Your device can\'t reach your router. This is usually a WiFi or cable issue between your device and the router.', icon: Icons.wifi_off, color: Colors.orange),
        const SizedBox(height: 8),
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Check your connection to the router', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _checklistItem(context, 'Make sure you\'re connected to your Linksys WiFi network (not a neighbor\'s)'),
          _checklistItem(context, 'If you\'re using a wired connection, check that the Ethernet cable is firmly plugged in at both ends'),
          _checklistItem(context, 'Move closer to your router and try again'),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _runDiagnostics, icon: const Icon(Icons.refresh), label: const Text('Check again'))),
        ])),
        _linksysSupportTile(context),
      ];

  List<Widget> _internetFailPath(BuildContext context) => [
        _infoBox(context, 'Your router is reachable but can\'t get to the internet. The issue is likely between your router and the box from your internet company (modem).', icon: Icons.cloud_off, color: Colors.red),
        const SizedBox(height: 8),
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Check the connection to your modem', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _checklistItem(context, 'Find the box from your internet company — it\'s separate from your Linksys router'),
          _checklistItem(context, 'Check that the cable between that box and your Linksys router is firmly plugged in at both ends'),
          _checklistItem(context, 'Look for lights on that box — if all lights are off or blinking red, the issue is with your internet service'),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _runDiagnostics, icon: const Icon(Icons.refresh), label: const Text('Check again'))),
        ])),
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('If cables are fine, contact your internet provider', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _ispScript(context, 'My router is connected to your equipment but the internet isn\'t working. I checked all the cables. Please check if there\'s an outage or provisioning issue.'),
          const _SessionSummaryCard(),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done — my internet is working now'))),
        ])),
        _linksysSupportTile(context),
      ];

  List<Widget> _dnsFailPath(BuildContext context) => [
        _infoBox(context, 'Your router can reach the internet but domain names aren\'t resolving. This can often be fixed by restarting your router.', icon: Icons.dns, color: Colors.orange),
        const SizedBox(height: 8),
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Try restarting your router', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Restarting clears DNS cache issues and usually resolves this.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _restart, icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
          if (_restarted) ...[const SizedBox(height: 8), const Text('Diagnostics ran again after restart.', style: TextStyle(color: Colors.green))],
        ])),
        if (_restarted)
          _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('If restarting didn\'t fix it:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ispScript(context, 'My router is connected and has an IP address, but websites won\'t load and domain names can\'t be resolved. I restarted my router but the problem persists.'),
            const _SessionSummaryCard(),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done — my internet is working now'))),
            const _SatisfactionPrompt(),
          ])),
        _linksysSupportTile(context),
      ];

  List<Widget> _allOkPath(BuildContext context) => [
        _infoBox(context, 'Everything looks fine right now — your router can reach the internet and websites are loading.', icon: Icons.check_circle, color: Colors.green),
        const SizedBox(height: 8),
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Still seeing an issue?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('The connection looks healthy from the router\'s side. This can happen if the problem is intermittent or affects only one device.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Is this happening on just one device?', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => widget.onNavigateToFlow?.call(30), icon: const Icon(Icons.devices, size: 16), label: const Text('Yes — troubleshoot a specific device'))),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _runDiagnostics, icon: const Icon(Icons.refresh, size: 16), label: const Text('Still seeing issues — test again'))),
        ])),
        _linksysSupportTile(context),
      ];
}

// ── Flow 2: My internet is slow ───────────────────────────────────────────────

class _Flow2 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<int> onNavigateToFlow;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _Flow2({required this.onDone, required this.onNavigateToFlow, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow2> createState() => _Flow2State();
}

class _Flow2State extends ConsumerState<_Flow2> {
  int _step = 0;
  bool _isRunning = false;
  SpeedTestResult? _speedResult;
  SpeedTestResult? _postRestartResult;
  final List<int> _stepHistory = [];

  void _pushStep(int newStep) {
    setState(() { _stepHistory.add(_step); _step = newStep; });
    _syncStepBackNotifier();
  }

  void _stepBack() {
    if (_stepHistory.isNotEmpty) { setState(() => _step = _stepHistory.removeLast()); _syncStepBackNotifier(); }
  }

  void _syncStepBackNotifier() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    final current = _stepHistory.length + 1;
    widget.stepIndicatorNotifier?.value = current > 1 ? 'Step $current of 4' : null;
  }

  double? get _mbps => _speedResult?.downloadMbps;

  String _speedCapability(double mbps) {
    if (mbps >= 100) return 'Plenty fast — handles 4K streaming, gaming, and video calls for the whole household.';
    if (mbps >= 50) return 'Good — supports HD streaming, gaming, and video calls on multiple devices at once.';
    if (mbps >= 25) return 'Solid — handles HD video, gaming, and calls for 1–2 people at a time.';
    if (mbps >= 10) return 'Basic — works for browsing and standard streaming, but may struggle with multiple devices.';
    if (mbps >= 5) return 'Limited — enough for light browsing and calls, but video may buffer.';
    return 'Very slow — video calls and streaming will likely have trouble.';
  }

  Future<void> _runSpeedTest() async {
    setState(() { _isRunning = true; _speedResult = null; _postRestartResult = null; });
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final result = await svc.runInternetSpeedTest();
      setState(() => _speedResult = result);
    } catch (_) {
      setState(() => _speedResult = null);
    } finally {
      setState(() { _isRunning = false; _step = 1; });
    }
  }

  Future<void> _restartAndRetest() async {
    if (!mounted) return;
    await _confirmAndRestart(context, ref);
    if (!mounted) return;
    setState(() => _isRunning = true);
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final result = await svc.runInternetSpeedTest();
      setState(() {
        _postRestartResult = result;
        _isRunning = false;
        if (result.downloadMbps < 25) { _step = 4; } else { _step = 1; _speedResult = result; }
      });
    } catch (_) {
      setState(() { _isRunning = false; _step = 4; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantTestProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(_step),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) ..._step0(context, state),
          if (_step == 1 && _speedResult != null) ..._step1(context),
          if (_step == 2) ..._step2(context, state),
          if (_step == 3) ..._step3(context, state),
          if (_step == 4) ..._step4(context),
          if (_step == 5) ..._step5Gaming(context, state),
        ],
      ),
    );
  }

  List<Widget> _step0(BuildContext context, InstantTestState state) {
    // USP: device scores computed from DeviceUIModel
    final weakWifi = state.deviceScores.isNotEmpty && state.deviceScores.first.score < 40;
    return [
      if (weakWifi)
        _infoBox(context, 'Your device has a weak WiFi connection. This reading may be lower than your actual internet speed. Move closer to your router, then run again.', icon: Icons.warning_amber, color: Colors.orange),
      const SizedBox(height: 12),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Run a speed test', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (_isRunning) ...[
          const Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 10), Text('Running speed test (~20 seconds)…')]),
        ] else ...[
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _runSpeedTest, icon: const Icon(Icons.speed), label: const Text('Check my speed'))),
        ],
      ])),
    ];
  }

  List<Widget> _step1(BuildContext context) {
    final mbps = _mbps!;
    final actuallyProblematic = mbps < 10;
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Here\'s what your connection can do', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: actuallyProblematic ? Colors.orange.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: actuallyProblematic ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_speedCapability(mbps), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            // D-35: show download + upload + latency
            SelectableText(
              '${mbps.toStringAsFixed(0)} Mbps down · ${_speedResult!.uploadMbps.toStringAsFixed(0)} Mbps up · ${_speedResult!.latencyMs}ms latency',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        SelectableText('This measures your speed from this device through your browser to the internet.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Does this feel fast enough?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Yes — it feels fine'))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _pushStep(2), child: const Text('No — something still feels slow'))),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _runSpeedTest, icon: const Icon(Icons.refresh, size: 16), label: const Text('Run test again')),
      ])),
    ];
  }

  List<Widget> _step2(BuildContext context, InstantTestState state) {
    final weakDevices = state.deviceScores.where((s) => s.isIssue).map((s) => s.device).toList();
    final jitterMs = _speedResult?.jitterMs ?? 0;
    final highJitter = jitterMs > 20;
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Let\'s figure out what\'s slow', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (highJitter) ...[_infoBox(context, 'Your connection has variable response time (${jitterMs}ms). This causes the stuttering you feel during games and video calls even when your download speed looks fine.', icon: Icons.timer_outlined, color: Colors.orange), const SizedBox(height: 10)],
        if (weakDevices.isNotEmpty) ...[_infoBox(context, '${weakDevices.length} device${weakDevices.length == 1 ? "" : "s"} on your network ${weakDevices.length == 1 ? "has" : "have"} a weak WiFi signal. A weak signal reduces speed even when your overall internet is fine.', icon: Icons.signal_wifi_statusbar_connected_no_internet_4, color: Colors.orange), const SizedBox(height: 10)],
        Text('Where is it slow?', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _pushStep(3), icon: const Icon(Icons.devices), label: const Text('Everything in my home is slow'))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => widget.onNavigateToFlow(31), icon: const Icon(Icons.smartphone), label: const Text('Just one specific device'))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _pushStep(5), icon: const Icon(Icons.sports_esports), label: const Text('Games or video calls are laggy'))),
      ])),
    ];
  }

  List<Widget> _step3(BuildContext context, InstantTestState state) {
    final weakDevices = state.deviceScores.where((s) => s.isIssue).map((s) => s.device).toList();
    // USP: use DeviceUIModel.isWifi and .band
    final wireless = state.clients.where((c) => c.isWifi).toList();
    final bandCrowded = wireless.length >= 4 && wireless.where((c) => (c.band ?? '').contains('2.4')).length / wireless.length >= 0.6;
    // USP: weak backhaul from NodeUIModel
    final weakNodes = state.meshNodes.where((n) => !n.isMaster && n.backhaulSignalStrength != null && n.backhaulSignalStrength! < -70).toList();
    final hasFindings = weakDevices.isNotEmpty || bandCrowded || weakNodes.isNotEmpty;
    return [
      if (hasFindings)
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Before restarting, here\'s what we noticed:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (weakDevices.isNotEmpty) _checklistItem(context, '${weakDevices.length} device${weakDevices.length == 1 ? '' : 's'} ${weakDevices.length == 1 ? 'has' : 'have'} a weak WiFi signal'),
          if (bandCrowded) _checklistItem(context, 'Most of your devices are on the slower 2.4 GHz band'),
          if (weakNodes.isNotEmpty) _checklistItem(context, '${weakNodes.map((n) => n.displayName).join(', ')} ${weakNodes.length == 1 ? 'has' : 'have'} a weak connection to your router'),
          const SizedBox(height: 8),
          Text('These may be causing the slowness.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ])),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(hasFindings ? 'If none of these apply, try restarting your router' : 'Try restarting your router', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Restarting can clear congestion and improve speeds.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: _isRunning ? const _LoadingButton(label: 'Testing speed after restart…') : FilledButton.icon(onPressed: _restartAndRetest, icon: const Icon(Icons.restart_alt), label: const Text('Restart + Run Speed Test Again'))),
        const SizedBox(height: 8),
        TextButton(onPressed: () => _pushStep(4), child: const Text('Skip — already restarted')),
      ])),
    ];
  }

  List<Widget> _step4(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contact your internet provider', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Since restarting didn\'t fix it, the issue is likely outside your router.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          _ispScript(context, 'My internet is slower than what I\'m paying for — only ${_postRestartResult?.downloadMbps.toStringAsFixed(0) ?? _mbps?.toStringAsFixed(0) ?? '?'} Mbps. I restarted my router but the problem persists.'),
          const _SessionSummaryCard(),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
          const _SatisfactionPrompt(),
        ])),
        _linksysSupportTile(context),
      ];

  List<Widget> _step5Gaming(BuildContext context, InstantTestState state) {
    final weakNodes = state.meshNodes.where((n) => !n.isMaster && n.backhaulSignalStrength != null && n.backhaulSignalStrength! < -70).toList();
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Latency / lag troubleshooting', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _infoBox(context, 'Gaming and video calls are sensitive to latency and jitter, not just download speed. High latency causes lag even with fast internet.'),
        const SizedBox(height: 12),
        _checklistItem(context, 'Connect the device with an Ethernet cable if possible — wired is always better for gaming'),
        _checklistItem(context, 'If on WiFi, move the device closer to your router or a child node'),
        _checklistItem(context, 'Close bandwidth-heavy apps on other devices (streaming, downloads)'),
        if (state.speedTest != null && state.speedTest!.jitterMs > 20) ...[
          const SizedBox(height: 8),
          _infoBox(context, 'Your connection has high jitter (${state.speedTest!.jitterMs}ms). This causes the stuttering you feel in games and video calls. Restarting your router often improves jitter.', icon: Icons.warning_amber, color: Colors.orange),
        ],
        if (state.meshNodes.length > 1 && weakNodes.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoBox(context, 'One of your child nodes has a weak connection to your router. Devices connected through that node will experience higher latency.', icon: Icons.warning_amber, color: Colors.orange),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _confirmAndRestart(context, ref), icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
        const _SatisfactionPrompt(),
      ])),
      _linksysSupportTile(context),
    ];
  }
}

// ── Flow 3: Device connectivity issues ───────────────────────────────────────

// _DeviceType removed — device-type question was replaced by inline picker (D-42 + Yarnin #7G)
enum _ConnectState { canConnect, cantConnect, wired }
enum _ConnectIssue { keepsDropping, slowOnDevice, other }

class _Flow3 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final VoidCallback? onNavigateToMyDevices;
  final bool initialConnected;
  final bool initialSlowDevice;
  // USP: DeviceUIModel instead of DiagnosticClient
  final DeviceUIModel? initialDevice;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _Flow3({required this.onDone, this.onNavigateToMyDevices, this.initialConnected = false, this.initialSlowDevice = false, this.initialDevice, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow3> createState() => _Flow3State();
}

class _Flow3State extends ConsumerState<_Flow3> {
  int _step = 0;
  _ConnectState? _connectState;
  _ConnectIssue? _connectIssue;
  bool _isDisablingMacFilter = false;
  bool _macFilterDisabled = false;
  bool? _canSeeSsid;
  DeviceUIModel? _selectedDevice;
  final List<int> _stepHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSlowDevice) {
      _step = 2; _connectState = _ConnectState.canConnect; _connectIssue = _ConnectIssue.slowOnDevice;
    } else if (widget.initialConnected) {
      _step = 1; _connectState = _ConnectState.canConnect;
    }
    _selectedDevice = widget.initialDevice;
  }

  void _pushStep(int newStep) {
    setState(() { _stepHistory.add(_step); _step = newStep; });
    _syncStepBackNotifier();
  }

  void _stepBack() {
    if (_stepHistory.isNotEmpty) { setState(() => _step = _stepHistory.removeLast()); _syncStepBackNotifier(); }
  }

  void _syncStepBackNotifier() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    final current = _stepHistory.length + 1;
    widget.stepIndicatorNotifier?.value = current > 1 ? 'Step $current of 4' : null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantTestProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey('${_step}_${_connectState?.index}_${_connectIssue?.index}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) ..._step0(context),
          if (_step == 1 && _connectState == _ConnectState.canConnect) ..._step1Connected(context),
          if (_step == 2 && _connectIssue == _ConnectIssue.keepsDropping) ..._keepsDroppingFlow(context, state),
          if (_step == 2 && _connectIssue == _ConnectIssue.slowOnDevice) ..._slowDevicePath(context, state),
          if (_step == 1 && _connectState == _ConnectState.cantConnect) ..._step1CantConnect(context, state),
          if (_step == 1 && _connectState == _ConnectState.wired) ..._step1Wired(context),
          if (_step == 3 && _connectIssue == _ConnectIssue.other) ..._pathOther(context, state),
          if (_step == 3 && _connectIssue != _ConnectIssue.other) ..._pathA(context, state),
          if (_step == 4) ..._pathB(context, state),
        ],
      ),
    );
  }

  List<Widget> _step0(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Can your device connect to your WiFi?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText('It may show as connected but have no internet, or it may not connect at all.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { setState(() => _connectState = _ConnectState.canConnect); _pushStep(1); }, icon: const Icon(Icons.wifi), label: const Text('Yes — it\'s connected but something is wrong'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { setState(() => _connectState = _ConnectState.cantConnect); _pushStep(1); }, icon: const Icon(Icons.wifi_off), label: const Text('No — it won\'t connect at all'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { setState(() => _connectState = _ConnectState.wired); _pushStep(1); }, icon: const Icon(Icons.settings_ethernet), label: const Text('No — my device uses an Ethernet cable'))),
        ])),
      ];

  List<Widget> _step1Wired(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Wired device troubleshooting', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText('Check each item as you try it:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _checklistItem(context, 'Check the Ethernet cable is firmly plugged in at both ends'),
          _checklistItem(context, 'Try a different Ethernet port on the router'),
          _checklistItem(context, 'Try a different cable if you have one'),
          _checklistItem(context, 'Check if the port light on the router is on when plugged in'),
          _checklistItem(context, 'Restart the device and try again'),
        ])),
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Still not working?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _confirmAndRestart(context, ref), icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
          const SizedBox(height: 8),
          FilledButton(onPressed: widget.onDone, child: const Text('Device is connected now')),
        ])),
        _linksysSupportTile(context),
      ];

  List<Widget> _step1Connected(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('What\'s happening?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { setState(() => _connectIssue = _ConnectIssue.keepsDropping); _pushStep(2); }, icon: const Icon(Icons.sync_problem), label: const Text('It keeps dropping off WiFi'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { setState(() => _connectIssue = _ConnectIssue.slowOnDevice); _pushStep(2); }, icon: const Icon(Icons.speed), label: const Text('It\'s connected but internet is slow on this device'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { setState(() => _connectIssue = _ConnectIssue.other); _pushStep(3); }, icon: const Icon(Icons.help_outline), label: const Text('Something else'))),
        ])),
      ];

  List<Widget> _slowDevicePath(BuildContext context, InstantTestState state) {
    return [
      if (_selectedDevice == null) _devicePickerCard(context, state)
      else ..._deviceAnalysisCards(context, state, _selectedDevice!),
    ];
  }

  Widget _devicePickerCard(BuildContext context, InstantTestState state) {
    final colors = Theme.of(context).colorScheme;
    // USP: filter isWifi devices
    final clients = state.clients.where((c) => c.isWifi).toList();
    final isLoading = state.phase == InstantTestLoadPhase.loading;
    // Auto-fetch if idle with no clients
    if (state.phase == InstantTestLoadPhase.idle && clients.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(instantTestProvider.notifier).fetch();
      });
    }
    return _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Which device is slow?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Select it to get specific advice based on its signal and connection.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 12),
      if (isLoading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()))
      else if (clients.isEmpty)
        Text('No wireless devices detected. Only wired devices are connected, or your router didn\'t report any wireless clients.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))
      else
        for (final c in clients)
          InkWell(
            onTap: () => setState(() => _selectedDevice = c),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(Icons.devices, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  // USP: signalStrength (dBm), band
                  Text('${c.band ?? 'WiFi'}${c.signalStrength != null ? "  ·  ${c.signalStrength} dBm" : ""}', style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                ])),
                Icon(Icons.chevron_right, size: 18, color: colors.outlineVariant),
              ]),
            ),
          ),
    ]));
  }

  List<Widget> _deviceAnalysisCards(BuildContext context, InstantTestState state, DeviceUIModel device) {
    final colors = Theme.of(context).colorScheme;
    // USP field mapping
    final signal = device.signalStrength; // RSSI dBm
    final band = device.band ?? '';
    final txRateMbps = device.downlinkRate != null ? device.downlinkRate! / 1000000 : null;
    // Find which mesh node
    final nodeId = state.clientToNodeId[device.mac];
    final node = nodeId != null ? state.meshNodes.cast<NodeUIModel?>().firstWhere((n) => n?.deviceId == nodeId, orElse: () => null) : null;

    final findings = <_SlowDeviceFinding>[];

    if (signal != null && signal < -75) {
      final critical = signal < -82;
      findings.add(_SlowDeviceFinding(icon: Icons.signal_wifi_off, color: critical ? Colors.red : Colors.orange, title: critical ? 'Very weak signal ($signal dBm)' : 'Weak signal ($signal dBm)', detail: critical ? 'Signal is barely enough to stay connected. Move the device much closer to your router or the nearest mesh node.' : 'Weak signal is the most likely cause of slowness. Moving closer to your router or a mesh node should help significantly.', fix: 'Move closer to your router or a mesh node'));
    }

    if (band.contains('2.4') && txRateMbps != null && txRateMbps > 80) {
      findings.add(_SlowDeviceFinding(icon: Icons.wifi, color: Colors.orange, title: 'On slower 2.4 GHz — capable of 5 GHz', detail: 'This device has a fast link rate (${txRateMbps.toStringAsFixed(0)} Mbps) so it\'s likely 5 GHz capable, but it\'s on the slower 2.4 GHz band. Forget the WiFi network and reconnect — it should join 5 GHz.', fix: 'Forget WiFi and reconnect to join the 5 GHz band'));
    } else if (band.contains('2.4') && (signal == null || signal >= -75)) {
      findings.add(_SlowDeviceFinding(icon: Icons.wifi, color: Colors.orange, title: 'On 2.4 GHz (slower band)', detail: 'The 2.4 GHz band is slower than 5 GHz. If your router broadcasts a separate 5 GHz network, try connecting to that instead.', fix: 'Connect to the 5 GHz network if available'));
    }

    if (node != null && !node.isMaster) {
      // USP: backhaulSignalStrength instead of backhaulHealth enum
      final isWeakBackhaul = node.backhaulSignalStrength != null && node.backhaulSignalStrength! < -70;
      final isCriticalBackhaul = node.backhaulSignalStrength != null && node.backhaulSignalStrength! < -82;
      if (isWeakBackhaul || isCriticalBackhaul) {
        final phyMbps = node.backhaulPhyRate > 0 ? node.backhaulPhyRate : null;
        findings.add(_SlowDeviceFinding(icon: Icons.hub_outlined, color: Colors.orange, title: 'Connected through ${node.displayName} — weak backhaul', detail: 'The mesh node this device uses has a slow connection back to the main router${phyMbps != null ? " ($phyMbps Mbps)" : ""}. The bottleneck is in the backhaul, not this device. Move ${node.displayName} closer to the main router, or connect it with an Ethernet cable.', fix: 'Move ${node.displayName} closer to the main router or use Ethernet'));
      }
    }

    if (txRateMbps != null && txRateMbps < 12 && (signal == null || signal >= -75)) {
      findings.add(_SlowDeviceFinding(icon: Icons.speed, color: Colors.orange, title: 'Very slow WiFi link (${txRateMbps.toStringAsFixed(0)} Mbps)', detail: 'The WiFi link speed to this device is very low despite a reasonable signal. This can be caused by interference, an older device, or the device being far from the router.', fix: 'Try restarting the device or moving it closer'));
    }

    final hasIssues = findings.isNotEmpty;
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.devices, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(device.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          TextButton(onPressed: () => setState(() => _selectedDevice = null), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)), child: const Text('Change')),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 12, children: [
          _metaChip(context, colors, band.isNotEmpty ? band : 'WiFi'),
          if (signal != null) _metaChip(context, colors, '$signal dBm'),
          if (txRateMbps != null) _metaChip(context, colors, '↑${txRateMbps.toStringAsFixed(0)} Mbps'),
          if (node != null) _metaChip(context, colors, node.isMaster ? 'On main router' : 'Via ${node.displayName}'),
        ]),
      ])),
      if (!hasIssues)
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.check_circle_outline, color: Colors.green, size: 18), SizedBox(width: 8), Text('WiFi connection looks good from router\'s side', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))]),
          const SizedBox(height: 8),
          Text('Signal, band, and link rate look fine. The slowness may be:\n  • Background apps or downloads on the device\n  • Your ISP\'s speed (run Instant-Test to check)\n  • Network congestion — too many devices active at once', style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant, height: 1.4)),
        ]))
      else
        for (final f in findings)
          _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(f.icon, size: 18, color: f.color), const SizedBox(width: 8), Expanded(child: Text(f.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: f.color)))]),
            const SizedBox(height: 6),
            Text(f.detail, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: f.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Row(children: [Icon(Icons.arrow_right, size: 16, color: f.color), const SizedBox(width: 4), Expanded(child: Text(f.fix, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: f.color)))]),
            ),
          ])),
      _linksysSupportTile(context),
    ];
  }

  Widget _metaChip(BuildContext context, ColorScheme colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500)),
    );
  }

  List<Widget> _keepsDroppingFlow(BuildContext context, InstantTestState state) {
    final weakDevices = state.deviceScores.where((s) => s.isIssue).map((s) => s.device).toList();
    // USP: wifiDataProvider for SSID unification detection
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final radios = wifiData?.radioModels ?? <WifiRadioUIModel>[];
    final ssids = radios.expand((r) => r.accessPoints).map((ap) => ap.ssidName).where((s) => s.isNotEmpty).toSet();
    final isUnifiedSsid = ssids.length <= 1;

    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Device keeps dropping WiFi', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Check each item as you try it:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        const _ClickChecklistItem('Move the device closer to your router or a child node'),
        _ClickChecklistItem(isUnifiedSsid
            ? 'Your router handles band switching automatically — moving closer helps your device pick the faster band'
            : 'Check if the device is on 2.4 GHz — try switching to 5 GHz (look for your 5 GHz network name in WiFi settings)'),
        const _ClickChecklistItem('Forget this WiFi network on the device, then reconnect fresh'),
        const _ClickChecklistItem('Check if other devices also drop — if yes, try restarting your router'),
        if (weakDevices.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoBox(context, '${weakDevices.length} device${weakDevices.length == 1 ? "" : "s"} on your network ${weakDevices.length == 1 ? "has" : "have"} a weak WiFi signal right now. Weak signal causes drops even when the device appears connected.', icon: Icons.signal_wifi_bad, color: Colors.orange),
        ],
      ])),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Things we can try from here', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        // Force reconnect — deauthClient not available in USP yet
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OutlinedButton.icon(
            onPressed: null, // USP deauth not implemented
            icon: const Icon(Icons.wifi_off_outlined, size: 18),
            label: const Text('Force reconnect a device'),
          ),
          const SizedBox(height: 4),
          Text('Force reconnect coming soon — not yet available on USP firmware.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => _confirmAndRestart(context, ref), icon: const Icon(Icons.restart_alt), label: const Text('Restart Router')),
        const SizedBox(height: 8),
        FilledButton(onPressed: widget.onDone, child: const Text('Device stopped dropping')),
      ])),
      const _SatisfactionPrompt(),
      _linksysSupportTile(context),
    ];
  }

  List<Widget> _step1CantConnect(BuildContext context, InstantTestState state) {
    // USP: read SSID from wifiDataProvider
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final ssid = wifiData?.radioModels.expand((r) => r.accessPoints).where((ap) => !ap.isGuest).map((ap) => ap.ssidName).where((s) => s.isNotEmpty).firstOrNull;
    final ssidLabel = ssid != null ? '"$ssid"' : 'your network name';

    if (_canSeeSsid == null) {
      return [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Can you see $ssidLabel in your device\'s WiFi list?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectableText('Open your device\'s WiFi settings and look for the network name above.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => setState(() => _canSeeSsid = true), child: const Text('Yes — I can see it'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => setState(() => _canSeeSsid = false), child: const Text('No — I don\'t see it'))),
        ])),
      ];
    }

    if (_canSeeSsid == false) {
      return [_ssidNotVisibleCard(context, state)];
    }

    return _pathA(context, state);
  }

  Widget _ssidNotVisibleCard(BuildContext context, InstantTestState state) {
    final colors = Theme.of(context).colorScheme;
    // USP: wifiDataProvider for radio active/disabled state
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final radios = wifiData?.radioModels ?? <WifiRadioUIModel>[];
    final hasRadioData = radios.isNotEmpty;

    final activeBands = radios.where((r) => r.enable).map((r) => r.band).toList();
    final disabledBands = radios.where((r) => !r.enable).map((r) => r.band).toList();
    // Check WPA3-only from security mode
    final wpa3Only = radios.expand((r) => r.accessPoints).any((ap) => ap.securityMode.toLowerCase().contains('wpa3') && !ap.securityMode.toLowerCase().contains('wpa2'));

    final findings = <_SsidFinding>[];
    if (disabledBands.isNotEmpty) {
      findings.add(_SsidFinding(icon: Icons.wifi_off, color: Colors.red, title: '${disabledBands.join(' and ')} radio is turned off', detail: 'The ${disabledBands.join('/')} band is disabled in your router settings. Enable it under WiFi settings.', isBlocker: true));
    }
    if (wpa3Only) {
      findings.add(_SsidFinding(icon: Icons.lock, color: Colors.orange, title: 'WPA3-only security — older devices can\'t connect', detail: 'Devices made before 2019 (and many smart home devices) don\'t support WPA3. Switch to WPA2/WPA3 mixed mode in your WiFi Security settings.', isBlocker: false));
    }

    final has6Ghz = (activeBands + disabledBands).any((b) => b.contains('6'));
    final has5Ghz = (activeBands + disabledBands).any((b) => b.contains('5') && !b.contains('6'));
    final has24Ghz = (activeBands + disabledBands).any((b) => b.contains('2.4'));

    return _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('We checked your router\'s WiFi — here\'s what we found', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      if (hasRadioData) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WiFi radios — actively broadcasting:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colors.onSurfaceVariant)),
            const SizedBox(height: 6),
            if (has24Ghz) _radioStatusRow(context, '2.4 GHz', disabledBands.any((b) => b.contains('2.4'))),
            if (has5Ghz) _radioStatusRow(context, '5 GHz', disabledBands.any((b) => b.contains('5') && !b.contains('6'))),
            if (has6Ghz) _radioStatusRow(context, '6 GHz', disabledBands.any((b) => b.contains('6'))),
            if (!has24Ghz && !has5Ghz && !has6Ghz) Text('Radio data not available', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      if (findings.isEmpty)
        _infoBox(context, hasRadioData ? 'Your router\'s WiFi radios are active and broadcasting. If your device still doesn\'t see the network, try:\n  • Moving your device closer to the router or a mesh node\n  • Turning WiFi off and back on on the device\n  • Forgetting and re-scanning for networks' : 'We didn\'t detect an obvious cause. Try moving your device closer to the router, then check again. A router restart often helps.')
      else
        for (final f in findings) ...[_ssidFindingTile(context, f), const SizedBox(height: 8)],
      if (has6Ghz) ...[
        _infoBox(context, '6 GHz WiFi (WiFi 6E/7) requires a compatible device — most phones and laptops from 2021 or earlier won\'t see the 6 GHz network at all.', icon: Icons.info_outline),
        const SizedBox(height: 12),
      ],
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _confirmAndRestart(context, ref), icon: const Icon(Icons.restart_alt, size: 18), label: const Text('Restart Router'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => setState(() => _canSeeSsid = null), child: const Text('Back'))),
    ]));
  }

  Widget _radioStatusRow(BuildContext context, String band, bool disabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(disabled ? Icons.cancel : Icons.check_circle, size: 14, color: disabled ? Colors.red : Colors.green),
        const SizedBox(width: 6),
        Text(band, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Text(disabled ? 'Disabled' : 'Active', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: disabled ? Colors.red : Colors.green)),
      ]),
    );
  }

  Widget _ssidFindingTile(BuildContext context, _SsidFinding f) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: f.color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8), border: Border.all(color: f.color.withValues(alpha: 0.25))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(f.icon, size: 18, color: f.color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: f.isBlocker ? f.color : null)),
          const SizedBox(height: 3),
          Text(f.detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
        ])),
      ]),
    );
  }

  List<Widget> _pathOther(BuildContext context, InstantTestState state) {
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('General troubleshooting', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Your device is connected but something doesn\'t seem right. Try these general steps:', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        const _ClickChecklistItem('Restart the affected device (phone, laptop, etc.)'),
        const _ClickChecklistItem('Forget this WiFi network on the device and reconnect'),
        const _ClickChecklistItem('Check if the problem happens on other devices too'),
        const _ClickChecklistItem('Try opening a website in a private/incognito window'),
      ])),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('If those didn\'t help', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _confirmAndRestart(context, ref), icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
      ])),
      _linksysSupportTile(context),
    ];
  }

  List<Widget> _pathA(BuildContext context, InstantTestState state) {
    // USP: SSID from wifiDataProvider, password not available (show placeholder)
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final ssid = wifiData?.radioModels.expand((r) => r.accessPoints).where((ap) => !ap.isGuest).map((ap) => ap.ssidName).where((s) => s.isNotEmpty).firstOrNull ?? '(see router settings)';
    final password = '(see router settings)'; // WiFi password not exposed in USP data model
    // USP: Instant Privacy = whitelist model (D-R3)
    final privacyState = ref.watch(uspInstantPrivacyProvider).valueOrNull;
    final macActive = (privacyState?.isEnabled ?? false) && !_macFilterDisabled;
    final wpa3Only = wifiData?.radioModels.expand((r) => r.accessPoints).any((ap) => ap.securityMode.toLowerCase().contains('wpa3') && !ap.securityMode.toLowerCase().contains('wpa2')) ?? false;

    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Check your WiFi details', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _wifiCredRow(context, 'Network name', ssid),
        const SizedBox(height: 6),
        _wifiCredRow(context, 'Password', password),
        const SizedBox(height: 12),
        _checklistItem(context, 'Make sure you\'re selecting the exact network name shown above'),
        _checklistItem(context, 'Check that caps lock is off when entering the password'),
        _checklistItem(context, 'Try forgetting the network on your device and reconnecting'),
        _checklistItem(context, 'If your router has separate 2.4 GHz and 5 GHz networks, try the 2.4 GHz one — some devices only support it'),
      ])),
      if (wpa3Only)
        _stepCard(context, _infoBox(context, 'Your router is set to WPA3-only security. Older devices (phones before 2019, many smart home devices) can\'t connect with this setting. Go to WiFi Settings and enable WPA2/WPA3 compatibility mode.')),
      // USP D-R3: Instant Privacy with whitelist semantics
      if (macActive)
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoBox(context, 'Instant Privacy is on — your router only allows pre-approved devices to connect.\n\nThis device may not be on the allowed list. Tapping "Allow All Devices" turns off Instant Privacy so any device can join using your WiFi password.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _isDisablingMacFilter ? const _LoadingButton(label: 'Allowing…') : FilledButton(onPressed: _disableInstantPrivacy, child: const Text('Allow All Devices'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Leave it on'))),
          ]),
        ])),
      if (_macFilterDisabled)
        _infoBox(context, 'Instant Privacy turned off. Try connecting again.', icon: Icons.check_circle_outline, color: Colors.green),
      const SizedBox(height: 8),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Still not connecting?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('If the steps above haven\'t worked, restarting your router often fixes connection issues that nothing else does.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _confirmAndRestart(context, ref), icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Device is connected now'))),
      ])),
      const _SatisfactionPrompt(),
      _linksysSupportTile(context),
    ];
  }

  List<Widget> _pathB(BuildContext context, InstantTestState state) {
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final ssid = wifiData?.radioModels.expand((r) => r.accessPoints).where((ap) => !ap.isGuest).map((ap) => ap.ssidName).where((s) => s.isNotEmpty).firstOrNull ?? '(see router settings)';
    final password = '(see router settings)';
    final wpa3Only = wifiData?.radioModels.expand((r) => r.accessPoints).any((ap) => ap.securityMode.toLowerCase().contains('wpa3') && !ap.securityMode.toLowerCase().contains('wpa2')) ?? false;

    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Connect your smart home device', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _checklistItem(context, 'Make sure your phone is on the same WiFi network you want the device on — not a guest network'),
        _checklistItem(context, 'Use the 2.4 GHz network if your router has separate names for 2.4 and 5 GHz'),
        const SizedBox(height: 8),
        _wifiCredRow(context, 'Network name', ssid),
        const SizedBox(height: 6),
        _wifiCredRow(context, 'Password', password),
      ])),
      if (wpa3Only)
        _stepCard(context, _infoBox(context, 'Some older smart home devices don\'t support the latest WiFi security standard. If this device keeps failing:\n\nGo to WiFi Settings and check if "WPA2 compatibility" is enabled.')),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Device is connected now'))),
      _linksysSupportTile(context),
    ];
  }

  Widget _wifiCredRow(BuildContext context, String label, String value) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Expanded(child: SelectableText(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      ]);

  // USP D-R3: disable = turn off Instant Privacy whitelist
  Future<void> _disableInstantPrivacy() async {
    setState(() => _isDisablingMacFilter = true);
    try {
      await ref.read(uspInstantPrivacyProvider.notifier).disable();
      setState(() { _isDisablingMacFilter = false; _macFilterDisabled = true; });
    } catch (_) {
      setState(() => _isDisablingMacFilter = false);
    }
  }
}

// ── Flow 4: WiFi doesn't reach a room ────────────────────────────────────────

enum _RouterPlacement { center, corner, enclosed }

class _Flow4 extends StatefulWidget {
  final VoidCallback onDone;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  const _Flow4({required this.onDone, this.stepBackNotifier});

  @override
  State<_Flow4> createState() => _Flow4State();
}

class _Flow4State extends State<_Flow4> {
  int _step = 0;
  _RouterPlacement? _placement;

  void _goToStep1() {
    setState(() => _step = 1);
    widget.stepBackNotifier?.value = () { setState(() => _step = 0); widget.stepBackNotifier?.value = null; };
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (_step == 0) ..._step0(context), if (_step == 1) ..._step1(context)]);

  List<Widget> _step0(BuildContext context) {
    final options = [(_RouterPlacement.center, 'Center of my home or close to it'), (_RouterPlacement.corner, 'Near a wall, door, or in a corner'), (_RouterPlacement.enclosed, 'Inside a closet, cabinet, or behind the TV')];
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Where is your router right now?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final (val, label) in options)
          RadioListTile<_RouterPlacement>(value: val, groupValue: _placement, title: Text(label), onChanged: (v) => setState(() => _placement = v), contentPadding: EdgeInsets.zero, dense: true),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _placement == null ? null : _goToStep1, child: const Text('Continue'))),
      ])),
    ];
  }

  List<Widget> _step1(BuildContext context) {
    String advice = switch (_placement) {
      _RouterPlacement.enclosed => 'Move your router out into the open. Enclosures block WiFi signals significantly — even a shelf in the open can double your range.',
      _RouterPlacement.corner => 'Move your router toward the center of your home — halfway between the router and the room with weak signal.',
      _ => 'Your placement is good. The issue may be building materials (concrete, brick, or metal studs between rooms).',
    };
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Placement tip', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 8), SelectableText(advice, style: Theme.of(context).textTheme.bodyMedium)])),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick tips', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _tipRow(context, Icons.check, 'Keep your router elevated — on a shelf or table, not the floor'),
        _tipRow(context, Icons.check, 'Point antennas vertically if your router has them'),
        _tipRow(context, Icons.check, 'Keep it away from microwaves, baby monitors, and cordless phones'),
        _tipRow(context, Icons.close, 'Don\'t put it inside a cabinet, closet, or entertainment unit'),
      ])),
      _stepCard(context, _infoBox(context, 'If you live in an apartment building or dense area, interference from neighboring WiFi networks can cause weak signal — even with perfect placement.')),
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Need more coverage?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SelectableText('Adding a Linksys child node in that room extends your WiFi coverage using the same network name and password — your devices connect automatically.', style: Theme.of(context).textTheme.bodyMedium),
      ])),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
      const _SatisfactionPrompt(),
      _linksysSupportTile(context),
    ];
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: icon == Icons.check ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

// ── Flow 5: My connection keeps cutting out ───────────────────────────────────

enum _DropFrequency { everyFewMinutes, fewTimesDay }
enum _DropScope { wholeInternet, specificDevices }

class _Flow5 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<int> onNavigateToFlow;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _Flow5({required this.onDone, required this.onNavigateToFlow, this.stepBackNotifier, this.stepIndicatorNotifier});

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
  bool? _restartFixed;
  final List<int> _stepHistory = [];

  void _pushStep(int newStep) { setState(() { _stepHistory.add(_step); _step = newStep; }); _syncStepBackNotifier(); }
  void _stepBack() { if (_stepHistory.isNotEmpty) { setState(() => _step = _stepHistory.removeLast()); _syncStepBackNotifier(); } }
  void _syncStepBackNotifier() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    final current = _stepHistory.length + 1;
    widget.stepIndicatorNotifier?.value = current > 1 ? 'Step $current of 5' : null;
  }

  @override
  void dispose() { _monitorTimer?.cancel(); super.dispose(); }

  Future<void> _startMonitor() async {
    setState(() { _isMonitoring = true; _dropsDetected = 0; _checksCompleted = 0; });
    final svc = ref.read(browserDiagnosticServiceProvider);
    _monitorTimer = Timer.periodic(const Duration(seconds: 24), (timer) async {
      if (!mounted) { timer.cancel(); return; }
      final ping = await svc.pingGateway();
      if (!mounted) return;
      bool shouldAdvance = false;
      setState(() {
        _checksCompleted++;
        if (!ping.reachable) _dropsDetected++;
        if (_checksCompleted >= _totalChecks) { timer.cancel(); _isMonitoring = false; shouldAdvance = true; }
      });
      if (shouldAdvance && mounted) _pushStep(3);
    });
  }

  Future<void> _restartAndCheck() async {
    if (!mounted) return;
    await _confirmAndRestart(context, ref);
    if (!mounted) return;
    setState(() { _isMonitoring = true; _checksCompleted = 0; _dropsDetected = 0; });
    final svc = ref.read(browserDiagnosticServiceProvider);
    int drops = 0;
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      final ping = await svc.pingGateway();
      if (!ping.reachable) drops++;
      if (!mounted) return;
      setState(() { _checksCompleted = i + 1; _dropsDetected = drops; });
    }
    if (!mounted) return;
    setState(() { _isMonitoring = false; _restartFixed = drops == 0; });
    _pushStep(4);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(key: ValueKey(_step), crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_step == 0) ..._step0(context),
          if (_step == 1) ..._step1Scope(context),
          if (_step == 2) ..._step2Monitor(context),
          if (_step == 3) ..._step3Result(context),
          if (_step == 4) ..._step4PostRestart(context),
        ]),
      );

  List<Widget> _step0(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How often does it drop?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          RadioListTile<_DropFrequency>(value: _DropFrequency.everyFewMinutes, groupValue: _frequency, title: const Text('Every few minutes'), onChanged: (v) => setState(() => _frequency = v), contentPadding: EdgeInsets.zero, dense: true),
          RadioListTile<_DropFrequency>(value: _DropFrequency.fewTimesDay, groupValue: _frequency, title: const Text('A few times a day'), onChanged: (v) => setState(() => _frequency = v), contentPadding: EdgeInsets.zero, dense: true),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _frequency == null ? null : () => _pushStep(1), child: const Text('Continue'))),
        ])),
      ];

  List<Widget> _step1Scope(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Is it everything or specific devices?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          RadioListTile<_DropScope>(value: _DropScope.wholeInternet, groupValue: _scope, title: const Text('My whole internet goes out — all devices stop at once'), onChanged: (v) => setState(() => _scope = v), contentPadding: EdgeInsets.zero, dense: true),
          RadioListTile<_DropScope>(value: _DropScope.specificDevices, groupValue: _scope, title: const Text('Just specific devices lose connection'), onChanged: (v) => setState(() => _scope = v), contentPadding: EdgeInsets.zero, dense: true),
          const SizedBox(height: 12),
          if (_scope == _DropScope.specificDevices) ...[
            _infoBox(context, 'This sounds like a device issue rather than a whole-network problem. The Device connectivity issues flow will help.'),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => widget.onNavigateToFlow(3), icon: const Icon(Icons.devices), label: const Text('Go to Device connectivity issues'))),
          ] else ...[
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _scope == null ? null : () => _pushStep(2), child: const Text('Continue'))),
          ],
        ])),
      ];

  List<Widget> _step2Monitor(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Run a 2-minute connection test', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoBox(context, 'We\'ll check every ~25 seconds whether your router can reach the internet. This runs for about 2 minutes. Keep this page open.'),
          const SizedBox(height: 12),
          if (!_isMonitoring && _checksCompleted == 0) ...[
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _startMonitor, icon: const Icon(Icons.monitor_heart), label: const Text('Start connection test'))),
          ] else if (_isMonitoring) ...[
            Row(children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10), Text('Monitoring… (check ${_checksCompleted + 1} of $_totalChecks)')]),
            if (_dropsDetected > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('$_dropsDetected drop${_dropsDetected == 1 ? '' : 's'} detected so far', style: const TextStyle(color: Colors.orange))),
          ],
        ])),
      ];

  List<Widget> _step3Result(BuildContext context) {
    final hasDrops = _dropsDetected > 0;
    final isFrequent = _frequency == _DropFrequency.everyFewMinutes;
    if (hasDrops) {
      return [_stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.warning_amber, color: Colors.orange, size: 20), const SizedBox(width: 8), Text('$_dropsDetected drop${_dropsDetected == 1 ? '' : 's'} detected during the test')]),
        const SizedBox(height: 12),
        Text('Restarting your router clears up most drop issues.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _restartAndCheck, icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
      ]))];
    }
    if (isFrequent) {
      return [_stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 8), Expanded(child: Text('No drops caught during the test.'))]),
        const SizedBox(height: 8),
        SelectableText('The drops happen frequently but we didn\'t catch one right now. Try restarting your router — this fixes most intermittent drop issues.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _restartAndCheck, icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
      ]))];
    }
    return [_stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 8), Expanded(child: Text('No drops detected right now.'))]),
      const SizedBox(height: 8),
      SelectableText('Intermittent drops that happen a few times a day are hard to catch in a short test. Try restarting your router as a first step — it resolves most intermittent issues.', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 12),
      _checklistItem(context, 'Check if the drops happen at a specific time (heavy usage periods like evenings can cause congestion)'),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _restartAndCheck, icon: const Icon(Icons.restart_alt), label: const Text('Restart Router'))),
      const SizedBox(height: 8),
      Text('If drops continue after a restart:', style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      _ispScript(context, 'My connection drops several times a day. I restarted my router but the problem persists.'),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
    ])), _linksysSupportTile(context)];
  }

  List<Widget> _step4PostRestart(BuildContext context) {
    if (_isMonitoring) {
      return [_stepCard(context, Row(children: [const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 10), const Text('Checking connection after restart…')]))];
    }
    if (_restartFixed == true) {
      return [_stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 8), Expanded(child: Text('Looks like the restart fixed it!'))]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
        const _SatisfactionPrompt(),
      ]))];
    }
    final freq = _frequency == _DropFrequency.everyFewMinutes ? 'every few minutes' : 'several times a day';
    // USP: wanStatus.addressingType instead of wanConnectionType
    final wanType = ref.watch(instantTestProvider).wanStatus?.addressingType.toUpperCase();
    final isPppoe = wanType == 'PPPOE';
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Still dropping after restart', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SelectableText('Since restarting didn\'t fix it, the issue is likely outside your router.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        _ispScript(context, isPppoe ? 'My DSL/fiber connection drops for about a minute every few hours and reconnects on its own. I think it\'s a PPPoE session issue. I restarted my router but the problem persists.' : 'My connection drops $freq. I restarted my router but the problem persists.'),
        const _SessionSummaryCard(),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('I\'ll call my provider'))),
        const _SatisfactionPrompt(),
      ])),
      _linksysSupportTile(context),
    ];
  }
}

// ── Session summary card ──────────────────────────────────────────────────────

class _SessionSummaryCard extends ConsumerWidget {
  const _SessionSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantTestProvider);
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    // USP: routerModel from meshNodes
    final masterNode = state.meshNodes.cast<NodeUIModel?>().firstWhere((n) => n?.isMaster == true, orElse: () => null);
    if (masterNode != null) rows.add(_summaryRow(context, 'Router', masterNode.model));
    if (state.wanStatus != null) rows.add(_summaryRow(context, 'WAN', state.wanStatus!.isUp ? 'Connected' : 'Not connected'));
    if (state.wanStatus?.ipAddress.isNotEmpty == true) rows.add(_summaryRow(context, 'WAN IP', state.wanStatus!.ipAddress));
    if (state.dnsCheck != null) rows.add(_summaryRow(context, 'Websites', state.dnsCheck!.resolved ? 'Loading' : 'Not loading'));
    if (state.speedTest != null) rows.add(_summaryRow(context, 'Speed', '${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps down'));
    if (state.firmwareVersion != null) rows.add(_summaryRow(context, 'Software', state.firmwareVersion!));

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What to tell the agent:', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...rows,
      ]),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(width: 72, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Expanded(child: SelectableText(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ── Satisfaction prompt (hidden until mechanism is defined) ───────────────────

class _SatisfactionPrompt extends StatelessWidget {
  const _SatisfactionPrompt();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Flow 6: Two routers / Combo gateway ──────────────────────────────────────

// _NatOption enum values drive navigation directly via _pushStep(1-4), not via stored value

class _Flow6BridgeMode extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _Flow6BridgeMode({required this.onDone, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow6BridgeMode> createState() => _Flow6BridgeModeState();
}

class _Flow6BridgeModeState extends ConsumerState<_Flow6BridgeMode> {
  int _step = 0;
  final List<int> _stepHistory = [];

  void _pushStep(int s) { setState(() { _stepHistory.add(_step); _step = s; }); _syncNotifiers(); }
  void _stepBack() { if (_stepHistory.isNotEmpty) setState(() => _step = _stepHistory.removeLast()); _syncNotifiers(); }
  void _syncNotifiers() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    final current = _stepHistory.length + 1;
    widget.stepIndicatorNotifier?.value = current > 1 ? 'Step $current of 2' : null;
  }

  bool _isCgnatIp(String? ip) {
    if (ip == null || ip.isEmpty) return false;
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final first = int.tryParse(parts[0]) ?? 0;
    final second = int.tryParse(parts[1]) ?? 0;
    return first == 100 && second >= 64 && second <= 127;
  }

  @override
  Widget build(BuildContext context) {
    // USP: wanStatus.ipAddress instead of wanIpAddress
    final wanIp = ref.watch(instantTestProvider).wanStatus?.ipAddress;
    final isCgnat = _isCgnatIp(wanIp);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(key: ValueKey(_step), crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_step == 0) ..._step0(context, isCgnat),
        if (_step == 1) ..._stepBridgeMode(context),
        if (_step == 2) ..._stepApMode(context),
        if (_step == 3) ..._stepCallIsp(context, isCgnat),
        if (_step == 4) ..._stepLeaveAsIs(context),
      ]),
    );
  }

  List<Widget> _step0(BuildContext context, bool isCgnat) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Two routers detected', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (isCgnat)
            _infoBox(context, 'Your internet company is using a shared IP address (Carrier-Grade NAT). This is managed by your provider — you can\'t change it on the router.', icon: Icons.info_outline)
          else
            _infoBox(context, 'Your Linksys router is connected behind another router — usually your internet company\'s gateway device. This creates a "double router" situation that can cause issues with port forwarding, gaming, and VoIP calls. Your internet works, but some features are limited.'),
          const SizedBox(height: 12),
          Text('What would you like to do?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (!isCgnat) ...[
            ListTile(leading: const Icon(Icons.settings_ethernet), title: const Text('Enable bridge mode on the ISP gateway'), subtitle: const Text('Best option — makes your router the only router'), onTap: () => _pushStep(1), contentPadding: EdgeInsets.zero, dense: true),
            const Divider(height: 12),
            ListTile(leading: const Icon(Icons.wifi), title: const Text('Switch Linksys to WiFi access point mode'), subtitle: const Text('Good for extending WiFi — ISP gateway handles routing'), onTap: () => _pushStep(2), contentPadding: EdgeInsets.zero, dense: true),
            const Divider(height: 12),
          ],
          ListTile(leading: const Icon(Icons.phone), title: Text(isCgnat ? 'Contact my internet provider for a dedicated IP' : 'Leave it as two routers — contact my internet provider'), subtitle: Text(isCgnat ? 'Required if you need port forwarding or gaming features' : 'If you need port forwarding, gaming, or VoIP to work'), onTap: () => _pushStep(3), contentPadding: EdgeInsets.zero, dense: true),
          if (!isCgnat) ...[
            const Divider(height: 12),
            ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text('Leave as-is — internet is working fine'), subtitle: const Text('OK if you don\'t need port forwarding'), onTap: () => _pushStep(4), contentPadding: EdgeInsets.zero, dense: true),
          ],
        ])),
      ];

  List<Widget> _stepBridgeMode(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enabling bridge mode', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoBox(context, 'Bridge mode turns off the routing features on your internet company\'s gateway so your Linksys can handle everything. The steps depend on your internet provider\'s equipment.'),
          const SizedBox(height: 12),
          _checklistItem(context, 'Log into your internet company\'s gateway — usually at 192.168.100.1 or printed on the device'),
          _checklistItem(context, 'Look for settings labelled "Bridge Mode", "IP Passthrough", or "DMZ". The name varies by provider.'),
          _checklistItem(context, 'Enter your Linksys router\'s MAC address (shown in My Network tab) when prompted'),
          _checklistItem(context, 'Save and wait 2 minutes — both devices will restart'),
          _checklistItem(context, 'Run the Instant-Test again to confirm you now have a public IP address'),
          const SizedBox(height: 12),
          SelectableText('Not sure how? Search "[your internet provider] enable bridge mode" — or call them and say: "I want to put my gateway into bridge mode so my third-party router handles everything."', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
        ])),
        const _SatisfactionPrompt(),
        _linksysSupportTile(context),
      ];

  List<Widget> _stepApMode(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Switch Linksys to access point mode', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoBox(context, 'In access point mode, your Linksys handles WiFi but your internet company\'s gateway handles routing. This is simpler than bridge mode and works well if you just need better WiFi coverage.'),
          const SizedBox(height: 8),
          _infoBox(context, 'Note: In AP mode, features like parental controls, device prioritization, and port forwarding on the Linksys won\'t work — those stay on the ISP gateway.', icon: Icons.warning_amber, color: Colors.orange),
          const SizedBox(height: 12),
          _checklistItem(context, 'Open the Linksys app and go to Router Settings'),
          _checklistItem(context, 'Look for "Operation Mode" or "Network Mode" and select "Access Point"'),
          _checklistItem(context, 'Connect the Linksys to your internet company\'s gateway with an Ethernet cable'),
          _checklistItem(context, 'Your devices will connect to the Linksys WiFi and get internet through the gateway'),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
        ])),
        const _SatisfactionPrompt(),
        _linksysSupportTile(context),
      ];

  List<Widget> _stepCallIsp(BuildContext context, bool isCgnat) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contact your internet provider', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(isCgnat ? 'Your provider manages the shared IP system — only they can assign you a dedicated public IP.' : 'Your internet provider can help you put their device into bridge mode.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          _ispScript(context, isCgnat ? 'I have a Linksys router but I\'m getting a shared IP address. I need a public static or dynamic IP to use port forwarding and online gaming. Can you assign me a dedicated IP?' : 'I connected my Linksys router to your gateway and my network has two routers. I\'d like to put your gateway into bridge mode so my Linksys handles everything. Can you walk me through that?'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Done'))),
        ])),
        _linksysSupportTile(context),
      ];

  List<Widget> _stepLeaveAsIs(BuildContext context) => [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Leaving as two routers', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoBox(context, 'That\'s fine! Two routers (double-NAT) works for normal browsing, streaming, and most everyday use. You\'ll only notice issues if you need port forwarding, host game servers, or use business VoIP.'),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.onDone, child: const Text('Got it — my internet is working'))),
        ])),
        const _SatisfactionPrompt(),
      ];
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _SlowDeviceFinding {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String fix;
  const _SlowDeviceFinding({required this.icon, required this.color, required this.title, required this.detail, required this.fix});
}

class _SsidFinding {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final bool isBlocker;
  const _SsidFinding({required this.icon, required this.color, required this.title, required this.detail, required this.isBlocker});
}
