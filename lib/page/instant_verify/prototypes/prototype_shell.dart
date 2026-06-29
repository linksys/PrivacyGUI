import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_pivot_view.dart';
import 'package:privacy_gui/page/instant_verify/views/my_devices_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';

/// PROTOTYPE-ONLY entry point. Reachable at `#/instant-prototype`.
///
/// Wraps the front-end prototypes in a ProviderScope that overrides the engine
/// with [MockInstantVerifyPivotNotifier], so every child reads believable mock
/// data and no JNAP / router call ever fires. Lets Deven compare two layout
/// directions (plus the current 4-tab baseline) side by side via a switcher.
class PrototypeRoot extends StatelessWidget {
  const PrototypeRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        instantVerifyPivotProvider
            .overrideWith(MockInstantVerifyPivotNotifier.new),
      ],
      child: const _PrototypeShell(),
    );
  }
}

enum _Layout {
  protoA('A · 2-tab + glance'),
  protoB('B · Verify side-nav'),
  current('Current · 4-tab');

  const _Layout(this.label);
  final String label;
}

class _PrototypeShell extends ConsumerStatefulWidget {
  const _PrototypeShell();

  @override
  ConsumerState<_PrototypeShell> createState() => _PrototypeShellState();
}

class _PrototypeShellState extends ConsumerState<_PrototypeShell> {
  _Layout _layout = _Layout.protoA;

  @override
  void initState() {
    super.initState();
    // Ensure mock data loads regardless of which layout mounts first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instantVerifyPivotProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant-Test — Front-End Prototypes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_Layout>(
                segments: _Layout.values
                    .map((l) => ButtonSegment<_Layout>(
                          value: l,
                          label: Text(l.label),
                        ))
                    .toList(),
                selected: {_layout},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _layout = s.first),
              ),
            ),
          ),
        ),
      ),
      body: switch (_layout) {
        _Layout.protoA => const _ProtoA(),
        _Layout.protoB => const _ProtoB(),
        // Current shipping shell — now reading the same mock data.
        _Layout.current => const InstantVerifyPivotView(),
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Prototype A — lean customer view: 2 tabs (Test + Help) + a network glance
// ════════════════════════════════════════════════════════════════════════

class _ProtoA extends StatefulWidget {
  const _ProtoA();

  @override
  State<_ProtoA> createState() => _ProtoAState();
}

class _ProtoAState extends State<_ProtoA> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _flow = ValueNotifier<int?>(null);
  final _flowDevice = ValueNotifier<DiagnosticClient?>(null);

  @override
  void dispose() {
    _tab.dispose();
    _flow.dispose();
    _flowDevice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _NetworkGlance(),
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Instant-Test'),
            Tab(text: 'Help Me Fix It'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              OverviewTab(
                // No My Devices tab here — send "view devices" to the glance
                // (no-op) and route findings into the Help tab.
                onViewClients: () {},
                onNavigateToFlow: (flowIndex) {
                  _flow.value = flowIndex + 1;
                  _tab.animateTo(1);
                },
              ),
              HelpMeFixItTab(
                pendingFlowNotifier: _flow,
                pendingFlowDeviceNotifier: _flowDevice,
                onNavigateToMyDevices: () => _tab.animateTo(0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Customer-safe network glance — status words + counts only, no MACs/IPs.
class _NetworkGlance extends ConsumerWidget {
  const _NetworkGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);
    final scheme = Theme.of(context).colorScheme;

    final connected = (state.wanStatus?['wanStatus'] == 'Connected');
    final download = state.speedTest?.downloadMbps;
    final devices = state.clients.length;
    final nodes = state.meshNodes.length;

    final Color tone = !connected
        ? scheme.error
        : (download != null && download < 25)
            ? Colors.orange
            : Colors.green;

    Widget chip(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        );

    return Material(
      color: scheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(connected ? Icons.public : Icons.public_off, 'Internet',
                connected ? 'Online' : 'Offline'),
            chip(Icons.speed, 'Download',
                download != null ? '${download.toStringAsFixed(0)} Mbps' : '—'),
            chip(Icons.devices, 'Devices', '$devices'),
            chip(Icons.router, 'Mesh nodes', '$nodes'),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Prototype B — Instant-Test primary, Verify depth + items on a side rail
// ════════════════════════════════════════════════════════════════════════

class _ProtoB extends StatefulWidget {
  const _ProtoB();

  @override
  State<_ProtoB> createState() => _ProtoBState();
}

class _ProtoBState extends State<_ProtoB> {
  int _index = 0;
  final _flow = ValueNotifier<int?>(null);
  final _flowDevice = ValueNotifier<DiagnosticClient?>(null);

  @override
  void dispose() {
    _flow.dispose();
    _flowDevice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelType: NavigationRailLabelType.all,
          leading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Icon(Icons.bolt, size: 28),
          ),
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.speed_outlined),
                selectedIcon: Icon(Icons.speed),
                label: Text('Instant-Test')),
            NavigationRailDestination(
                icon: Icon(Icons.devices_outlined),
                selectedIcon: Icon(Icons.devices),
                label: Text('Devices')),
            NavigationRailDestination(
                icon: Icon(Icons.lan_outlined),
                selectedIcon: Icon(Icons.lan),
                label: Text('Network')),
            NavigationRailDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: Text('Verify')),
            NavigationRailDestination(
                icon: Icon(Icons.help_outline),
                selectedIcon: Icon(Icons.help),
                label: Text('Help Me')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: [
              // 0 — Instant-Test is the primary/top destination.
              OverviewTab(
                onViewClients: () => setState(() => _index = 1),
                onNavigateToFlow: (flowIndex) {
                  _flow.value = flowIndex + 1;
                  setState(() => _index = 4);
                },
              ),
              MyDevicesTab(
                onNavigateToFlow: (flowIndex, {DiagnosticClient? device}) {
                  _flowDevice.value = device;
                  _flow.value = flowIndex;
                  setState(() => _index = 4);
                },
              ),
              const MyNetworkTab(),
              const _VerifyToolsPanel(),
              HelpMeFixItTab(
                pendingFlowNotifier: _flow,
                pendingFlowDeviceNotifier: _flowDevice,
                onNavigateToMyDevices: () => setState(() => _index = 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Technician "Verify Tools" depth — ping/traceroute, ethernet ports, mesh
/// topology, router load. Reads the same mock engine state.
class _VerifyToolsPanel extends ConsumerWidget {
  const _VerifyToolsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget card(String title, Widget child) => Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        );

    final cpu = state.routerHealth?['cpuLoad'];
    final mem = state.routerHealth?['memoryLoad'];
    final wanPort = state.ethernetPorts?['wanPortConnection'];
    final lanPorts =
        (state.ethernetPorts?['lanPortConnections'] as List?)?.cast<String>() ??
            const <String>[];

    return ListView(
      children: [
        card(
          'Connectivity tools',
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => notifier.startPing('8.8.8.8'),
                icon: const Icon(Icons.network_ping),
                label: const Text('Ping 8.8.8.8'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => notifier.startTraceroute('8.8.8.8'),
                icon: const Icon(Icons.route),
                label: const Text('Traceroute 8.8.8.8'),
              ),
            ],
          ),
        ),
        if (state.pingOutput != null)
          card('Ping output', SelectableText(state.pingOutput!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        if (state.tracerouteOutput != null)
          card('Traceroute output', SelectableText(state.tracerouteOutput!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        card(
          'Router load',
          Row(
            children: [
              Expanded(
                  child: Text('CPU: ${cpu ?? '—'}%',
                      style: TextStyle(
                          color: (cpu is int && cpu > 80)
                              ? scheme.error
                              : scheme.onSurface))),
              Expanded(
                  child: Text('Memory: ${mem ?? '—'}%',
                      style: TextStyle(
                          color: (mem is int && mem > 80)
                              ? scheme.error
                              : scheme.onSurface))),
            ],
          ),
        ),
        card(
          'Ethernet ports',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WAN: ${wanPort ?? '—'}'),
              const SizedBox(height: 4),
              for (var i = 0; i < lanPorts.length; i++)
                Text('LAN ${i + 1}: ${lanPorts[i]}',
                    style: TextStyle(
                        color: lanPorts[i] == 'Connected'
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant)),
            ],
          ),
        ),
        card(
          'Mesh topology',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final n in state.meshNodes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(n.isController ? Icons.router : Icons.wifi,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(n.name)),
                      Text(
                        n.isController
                            ? 'Controller'
                            : (n.backhaulSpeedMbps != null
                                ? '${n.backhaulSpeedMbps} Mbps backhaul'
                                : 'Satellite'),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
