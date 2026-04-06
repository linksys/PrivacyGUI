import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';

/// Main entry point for the Instant Verify pivot.
///
/// Takes over [menuInstantVerify] inside the authenticated PrivacyGUI.
/// Tab structure:
///   0: Overview       — customer self-service (auto-run diagnostics + actions)
///   1: Clients        — device table + radio config + WiFi quality (agent/advanced)
///   2: Network        — WAN, connectivity, ping, traceroute, ports (agent/advanced)
///   3: Tools          — restart, Ookla speed test, logs, email (agent)
class InstantVerifyPivotView extends ConsumerStatefulWidget {
  const InstantVerifyPivotView({super.key});

  @override
  ConsumerState<InstantVerifyPivotView> createState() =>
      _InstantVerifyPivotViewState();
}

class _InstantVerifyPivotViewState
    extends ConsumerState<InstantVerifyPivotView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instant Verify'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Clients'),
            Tab(text: 'Network'),
            Tab(text: 'Tools'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const OverviewTab(),
          const _ComingSoonTab(
            label: 'Clients & Wireless',
            description:
                'Device list with WiFi signal quality, radio configuration, and local speed test.',
          ),
          const _ComingSoonTab(
            label: 'Network & Connectivity',
            description:
                'WAN status, IPv4/IPv6, DNS, firewall, port status, ping, and traceroute.',
          ),
          const _ComingSoonTab(
            label: 'Tools',
            description:
                'Restart router, Ookla speed test, debug logs, and email diagnostic report.',
          ),
        ],
      ),
    );
  }
}

/// Placeholder shown for tabs not yet implemented.
class _ComingSoonTab extends StatelessWidget {
  final String label;
  final String description;

  const _ComingSoonTab({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction,
              size: 48, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
