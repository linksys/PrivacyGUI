import 'answer_row.dart';
import 'diagnostic_selection_area.dart';
import 'instant_test_layout.dart';
import 'instant_test_page_header.dart';
import 'instant_test_style.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'details_disclosure.dart';
import 'dart:async';
import 'user_step_heading.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacy_gui/page/instant_verify/views/restart_helper.dart';
import 'package:privacy_gui/page/instant_verify/views/device_actions.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart' show MeshNodeInfo, BackhaulHealth;
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';

part 'help/help_shared.dart';
part 'help/flow_internet.dart';
part 'help/flow_speed.dart';
part 'help/flow_device.dart';
part 'help/flow_coverage.dart';
part 'help/flow_drops.dart';
part 'help/flow_two_routers.dart';

/// PRD v0.7 Tab 3: Help Me Fix It
///
/// Entry screen: 5 flow cards. Tapping one launches a guided step-by-step flow.
/// Back navigation returns to the card menu.
///
/// Item 5: _SessionSummaryCard — shows key diagnostic data at escalation screens.
/// Item 6: _SatisfactionPrompt — satisfaction rating at terminal screens.
class HelpMeFixItTab extends ConsumerStatefulWidget {
  /// When set, opening this tab immediately launches the indicated flow (1-5).
  /// -1 = reset to landing menu (fired when tab is re-tapped while active).
  final ValueNotifier<int?>? pendingFlowNotifier;

  /// Navigates to My Devices tab (Tab 1) — wired from pivot view.
  final VoidCallback? onNavigateToMyDevices;

  /// Carries the specific device selected in My Devices into the flow.
  final ValueNotifier<DiagnosticClient?>? pendingFlowDeviceNotifier;

  /// Single-page mode: when set, finishing/backing out of a flow calls this
  /// (return to the Instant-Test page) instead of falling back to the 6-card
  /// menu. The host owns the menu; this widget only renders the active flow.
  final VoidCallback? onExitToHome;

  final bool singlePage;
  final VoidCallback? onCheckAgain;
  final String exitLabel;
  final List<int>? flowPath;
  final ValueChanged<List<int>>? onFlowPathChanged;

  const HelpMeFixItTab({
    super.key,
    this.pendingFlowNotifier,
    this.pendingFlowDeviceNotifier,
    this.onNavigateToMyDevices,
    this.onExitToHome,
    this.singlePage = false,
    this.onCheckAgain,
    this.exitLabel = 'Back to Instant-Test',
    this.flowPath,
    this.onFlowPathChanged,
  });

  @override
  ConsumerState<HelpMeFixItTab> createState() => _HelpMeFixItTabState();
}

class _FlowVisit {
  _FlowVisit(this.flow, {this.device});
  final int flow;
  final DiagnosticClient? device;
  final key = UniqueKey();
  final back = ValueNotifier<VoidCallback?>(null);
  final indicator = ValueNotifier<String?>(null);
  void dispose() {
    back.dispose();
    indicator.dispose();
  }
}

class _HelpMeFixItTabState extends ConsumerState<HelpMeFixItTab> {
  final List<_FlowVisit> _visits = [];

  @override
  void initState() {
    super.initState();
    widget.pendingFlowNotifier?.addListener(_onPendingFlow);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.flowPath != null) { _syncFlowPath(); } else { _onPendingFlow(); }
    });
  }

  @override
  void didUpdateWidget(covariant HelpMeFixItTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flowPath != null) _syncFlowPath();
  }

  void _syncFlowPath() {
    final path = widget.flowPath!;
    var shared = 0;
    while (shared < path.length && shared < _visits.length &&
        path[shared] == _visits[shared].flow) { shared++; }
    if (shared == path.length && shared == _visits.length) return;
    _retire(_visits.sublist(shared));
    final device = widget.pendingFlowDeviceNotifier?.value;
    widget.pendingFlowDeviceNotifier?.value = null;
    setState(() {
      _visits.removeRange(shared, _visits.length);
      for (var i = shared; i < path.length; i++) {
        _visits.add(_FlowVisit(path[i], device: i == path.length - 1 ? device : null));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && path.isNotEmpty) _recordFlow(path.last);
    });
  }

  void _publishPath() => widget.onFlowPathChanged?.call(
      _visits.map((visit) => visit.flow).toList());

  void _retire(List<_FlowVisit> visits) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final visit in visits) { visit.dispose(); }
    });
  }

  @override
  void dispose() {
    widget.pendingFlowNotifier?.removeListener(_onPendingFlow);
    for (final visit in _visits) { visit.dispose(); }
    super.dispose();
  }

  void _onPendingFlow() {
    final flow = widget.pendingFlowNotifier?.value;
    if (flow == null || !mounted) return;
    widget.pendingFlowNotifier!.value = null;
    final device = widget.pendingFlowDeviceNotifier?.value;
    widget.pendingFlowDeviceNotifier?.value = null;
    _retire(List.of(_visits));
    setState(() {
      _visits.clear();
      if (flow != -1) _visits.add(_FlowVisit(flow, device: device));
    });
    if (flow != -1) _recordFlow(flow);
  }

  void _recordFlow(int flow) {
    const names = {1: 'internet_not_working', 2: 'internet_slow',
      3: 'device_connectivity', 30: 'device_connectivity', 31: 'device_slow', 32: 'device_drops',
      4: 'wifi_coverage', 5: 'connection_drops', 6: 'bridge_mode'};
    ref.read(instantVerifyPivotProvider.notifier)
        .recordFlowEntered(names[flow] ?? 'flow_$flow');
  }

  void _launchFlow(int flow) {
    _recordFlow(flow);
    setState(() => _visits.add(_FlowVisit(flow)));
    _publishPath();
  }

  void _exitFlow() {
    _retire(List.of(_visits));
    setState(_visits.clear);
    widget.onExitToHome?.call();
  }

  void _handleShellBack() {
    final back = _visits.last.back.value;
    if (back != null) {
      back();
    } else if (_visits.length > 1) {
      final removed = _visits.last;
      setState(() => _visits.removeLast());
      _retire([removed]);
      _publishPath();
    } else {
      _exitFlow();
    }
  }

  Widget _flow(_FlowVisit visit) {
    final back = visit.back;
    final indicator = visit.indicator;
    return switch (visit.flow) {
      1 => _Flow1(onDone: _exitFlow, onNavigateToFlow: _launchFlow, stepBackNotifier: back),
      2 => _Flow2(onDone: _exitFlow, onNavigateToFlow: _launchFlow, singlePage: widget.singlePage,
          stepBackNotifier: back, stepIndicatorNotifier: indicator),
      3 || 30 || 31 || 32 => _Flow3(onDone: _exitFlow,
          onNavigateToMyDevices: widget.onNavigateToMyDevices,
          initialConnected: visit.flow == 30 || visit.flow == 31,
          initialSlowDevice: visit.flow == 31,
          initialIssue: visit.flow == 32 ? _ConnectIssue.keepsDropping
              : visit.flow == 3 ? _ConnectIssue.cantConnect : null,
          initialDevice: visit.device, singlePage: widget.singlePage,
          stepBackNotifier: back, stepIndicatorNotifier: indicator),
      4 => _Flow4(onDone: _exitFlow, stepBackNotifier: back, singlePage: widget.singlePage),
      5 => _Flow5(onDone: _exitFlow, onNavigateToFlow: _launchFlow,
          stepBackNotifier: back, stepIndicatorNotifier: indicator, singlePage: widget.singlePage),
      6 => _Flow6BridgeMode(onDone: _exitFlow, stepBackNotifier: back, stepIndicatorNotifier: indicator),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_visits.isEmpty) {
      if (widget.onExitToHome != null) return const SizedBox.shrink();
      return _FlowMenu(onSelect: _launchFlow);
    }
    final active = _visits.last;
    // The connection check has its own re-check beside its result; a second
    // "Check again" here would do something different under the same name.
    final checkAgain = widget.onCheckAgain != null && active.flow != 1;
    return _FlowShell(
      title: _flowTitle(active.flow),
      onBack: _handleShellBack,
      backLabel: widget.singlePage
          ? (_visits.length > 1 ? _returnLabel(_visits[_visits.length - 2].flow) : widget.exitLabel)
          : 'Back to flows',
      stepIndicatorNotifier: active.indicator,
      stepBackNotifier: active.back,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Preserve each origin's selected device and result while visiting
        // another flow. Removed visits are disposed, including their timers.
        for (final visit in _visits)
          Offstage(
            key: visit.key,
            offstage: visit != active,
            child: ExcludeFocus(excluding: visit != active,
                child: TickerMode(enabled: visit == active, child: DiagnosticSelectionArea(child: _flow(visit)))),
          ),
        // One way back: the header arrow (density pass, QA #3). The footer
        // only offers re-checking after a fix.
        if (widget.singlePage && checkAgain) ...[
          const AppGap.large2(),
          const Divider(),
          const AppGap.small3(),
          Wrap(
              spacing: Spacing.small3,
              runSpacing: Spacing.small2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const AppText.bodyMedium('Tried a fix?'),
                AppOutlinedButton('Check again',
                    onTap: widget.onCheckAgain, icon: LinksysIcons.refresh),
              ]),
        ],
        const AppGap.large2(),
        _linksysSupportTile(context),
      ]),
    );
  }

  static String _returnLabel(int flow) => switch (flow) {
    1 => 'Back to internet check',
    2 => 'Back to speed check',
    5 => 'Back to connection check',
    _ => 'Back to previous help',
  };

  static String _flowTitle(int flow) => switch (flow) {
        1 => 'My internet isn\'t working',
        2 => 'My internet is slow',
        3 || 30 => 'Device connectivity issues',
        31 => 'One device is slow',
        32 => 'Device keeps disconnecting',
        4 => 'WiFi doesn\'t reach a room',
        5 => 'My connection keeps cutting out',
        6 => 'Two routers / Combo gateway',
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
          child: const AppText.titleMedium('What are you running into?'),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText.titleSmall(
                    'Is it affecting one specific device or everything?'),
                const AppGap.small3(),
                Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('One specific device',
                    onTap: () => widget.onSelect(3), // → Flow 3
                    icon: LinksysIcons.genericDevice,
                  ),
                ),
                const AppGap.small2(),
                Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Everything in my home',
                onTap: () => setState(() => _showAllFlows = true),
                icon: LinksysIcons.devices),
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
      (1, LinksysIcons.signalWifiOff, 'My internet isn\'t working',
          'Websites won\'t load, devices can\'t get online'),
      (2, LinksysIcons.networkCheck, 'My internet is slow',
          'Videos buffer, downloads are sluggish'),
      (3, LinksysIcons.devices, 'Device connectivity issues',
          'A device won\'t connect or keeps dropping off WiFi'),
      (4, LinksysIcons.signalWifi0Bar, 'WiFi doesn\'t reach a room',
          'Weak signal in part of your home'),
      (5, LinksysIcons.networkCheck, 'My connection keeps cutting out',
          'Internet drops and comes back on its own'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: AppText.titleMedium('What are you running into?'),
        ),
        for (final (index, icon, title, subtitle) in flows)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 28),
              title: AppText.labelLarge(title),
              subtitle: AppText.bodySmall(subtitle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              trailing: Icon(LinksysIcons.chevronRight,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  final ValueNotifier<VoidCallback?> stepBackNotifier;
  final String backLabel;
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _FlowShell(
      {required this.stepBackNotifier,
      required this.title,
      required this.onBack,
      required this.child,
      this.stepIndicatorNotifier,
      this.backLabel = 'Back to flows'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<VoidCallback?>(
          valueListenable: stepBackNotifier,
          builder: (_, stepBack, __) => InstantTestPageHeader(
            title: title, onBack: onBack,
            backLabel: stepBack != null && backLabel != 'Back to flows'
                ? 'Back to previous step' : backLabel,
            subtitle: stepIndicatorNotifier == null ? null
                : ValueListenableBuilder<String?>(
                    valueListenable: stepIndicatorNotifier!,
                    builder: (_, indicator, __) => indicator == null
                        ? const SizedBox.shrink()
                        : AppText.labelSmall(indicator)),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: InstantTestLayout.scrollPadding(context),
            // Every flow and its footer share one column (QA #2 fixed focus).
            child: InstantTestFocusColumn(children: [child]),
          ),
        ),
      ],
    );
  }
}
