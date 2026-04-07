import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';

/// Main entry point for the Instant Verify pivot.
///
/// Takes over [menuInstantVerify] inside the authenticated PrivacyGUI.
/// Tab structure (PRD v0.7):
///   0: Instant-Test   — one-touch automated diagnostics + auto-fix actions
///   1: My Devices     — device list with signal quality + device-specific help
///   2: My Network     — mesh nodes, internet connection, WiFi overview
///   3: Help Me Fix It — 5 guided flows for issues needing investigation
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
        title: const Text('Instant Help'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Instant-Test'),
            Tab(text: 'My Devices'),
            Tab(text: 'My Network'),
            Tab(text: 'Help Me Fix It'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(
            onViewClients: () => _tabController.animateTo(1),
            onNavigateToFlow: (flowIndex) => _tabController.animateTo(3),
          ),
          const _ComingSoonTab(
            label: 'My Devices',
            description:
                'See all connected devices, check signal quality, and get device-specific help.',
          ),
          const _ComingSoonTab(
            label: 'My Network',
            description:
                'See your mesh nodes, internet connection, and WiFi overview.',
          ),
          const _ComingSoonTab(
            label: 'Help Me Fix It',
            description:
                '5 guided flows: internet not working, slow internet, device issues, weak signal, and connection drops.',
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
