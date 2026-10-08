import '../models/diagnostic_client.dart';
import '../models/router_light.dart';
import 'instant_test_layout.dart';
import 'instant_test_style.dart';
import 'symptom_chooser.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/label/text_label.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'details_disclosure.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/restart_helper.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final Widget? leading;
  final VoidCallback? onViewNetwork;
  final VoidCallback? onViewClients;
  final VoidCallback? onTroubleshootWeakDevices;
  final ValueChanged<DiagnosticClient>? onTroubleshootDevice;
  final void Function(int flowIndex)? onNavigateToFlow;
  /// When false, the in-body "Something else?" symptom cards are hidden — the
  /// single-page host supplies its own workflow chooser instead.
  final bool showProblemCards;
  const OverviewTab({
    super.key,
    this.leading,
    this.onViewNetwork,
    this.onViewClients,
    this.onTroubleshootWeakDevices,
    this.onTroubleshootDevice,
    this.onNavigateToFlow,
    this.showProblemCards = true,
  });

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  bool _findingsExpanded = false;
  bool _checksExpanded = false;
  int _restartCountdown = 0;
  final _resultKey = GlobalKey();

  /// The run takes about 20 seconds and users scroll on to "What needs
  /// help?" meanwhile, so the result appears out of view (QA). Bring it back.
  void _revealResult(PivotLoadPhase? previous, PivotLoadPhase next) {
    if (next != PivotLoadPhase.complete ||
        previous == null ||
        previous == PivotLoadPhase.complete) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      SemanticsService.announce(
          'Instant-Test finished. Results are ready.', Directionality.of(context));
    });
  }

  /// Ticks once a second while the speed-test cooldown is active so the
  /// "Run Again" button can show a live countdown.
  Timer? _cooldownTicker;

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
  void dispose() {
    _cooldownTicker?.cancel();
    super.dispose();
  }

  /// Drive a 1s rebuild loop while the speed-test cooldown is counting down.
  void _ensureCooldownTicker() {
    if (_cooldownTicker != null) return;
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    if (notifier.speedTestCooldownRemaining <= 0) return;
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted ||
          ref.read(instantVerifyPivotProvider.notifier)
                  .speedTestCooldownRemaining <=
              0) {
        t.cancel();
        _cooldownTicker = null;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    ref.listen(instantVerifyPivotProvider.select((s) => s.phase), _revealResult);

    // Density pass (QA 2026-10-07 #3/#5): one column, one result card that
    // also lists everything else we found, compact problem choices, and the
    // light guide and support in the footer.
    return SingleChildScrollView(
      padding: InstantTestLayout.scrollPadding(context),
      child: InstantTestFocusColumn(
        children: [
          Align(alignment: Alignment.centerRight, child: _runAgain(state)),
          // Inline WAN-down callout (PRD v0.7 S-1); the guide link is in the footer.
          _LightGuideLink(
            showLink: false,
            showInlineCallout: state.wanStatus != null && state.errorMessage == null &&
                state.phase != PivotLoadPhase.idle &&
                state.phase != PivotLoadPhase.loading &&
                !state.wanConnected,
          ),
          _StatusCard(
            key: _resultKey,
            state: state,
            findingsExpanded: _findingsExpanded,
            checksExpanded: _checksExpanded,
            onToggleFindings: () =>
                setState(() => _findingsExpanded = !_findingsExpanded),
            onToggleChecks: () =>
                setState(() => _checksExpanded = !_checksExpanded),
            onAction: _handleAction,
            onTroubleshootDevice: widget.onTroubleshootDevice,
            onTroubleshootWeakDevices: widget.onTroubleshootWeakDevices,
            onViewNetwork: widget.onViewNetwork,
            onViewClients: widget.onViewClients,
            onNavigateToFlow: widget.onNavigateToFlow,
            showProblemCards: widget.showProblemCards,
            hasRestarted: state.hasRestartedThisSession,
          ),
          if (state.recentPriorRestart &&
              state.verdict != null &&
              state.verdict!.findings.isNotEmpty) ...[
            const AppGap.small3(),
            // Non-blocking warning: Instant-Privacy's warning card without
            // the error border.
            AppSettingCard(
              title:
                  'You restarted your router recently but the problem came back. '
                  'This usually means the issue isn\'t something a restart can fix.',
              leading: Icon(LinksysIcons.uptime,
                  color: InstantTestTone.warning.color(context)),
            ),
          ],
          // Restart countdown with reassurance (PRD v0.7 D-23)
          if (_restartCountdown > 0) ...[
            const AppGap.medium(),
            _RestartCountdown(secondsRemaining: _restartCountdown),
          ],
          if (widget.leading != null) ...[
            const AppGap.large2(),
            widget.leading!,
          ],
          const AppGap.large2(),
          const Divider(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Spacing.medium,
            children: [
              const _LightGuideLink(),
              Wrap(spacing: Spacing.small1, children: [
                AppText.bodySmall('Still need help?',
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const AppText.bodySmall(
                    'www.linksys.com/support  •  1-800-326-7114',
                    selectable: true),
              ]),
            ],
          ),
          // Internal validation builds (deploy_local.sh sets force=local) get the
          // mock-failure scenario picker; customer Jenkins builds (force!=local)
          // do not. Replaces the old kDebugMode guard, which release builds strip.
          if (BuildConfig.forceCommandType == ForceCommand.local) ...[
            const AppGap.small2(),
            Center(
              child: FilledButton.tonal(
                onPressed: () => _showScenarioPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LinksysIcons.troubleshoot, size: 16),
                    const AppGap.small2(),
                    AppText.labelLarge('Test scenarios',
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer),
                  ],
                ),
              ),
            ),
          ],
          const AppGap.large2(),
        ],
      ),
    );
  }

  Widget _runAgain(InstantVerifyPivotState state) {
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    final cooldown = notifier.speedTestCooldownRemaining;
    // Keep the live countdown ticking while cooling down.
    if (cooldown > 0) _ensureCooldownTicker();
    final baseLabel = state.hasRestartedThisSession ? 'Check Again' : 'Run Again';
    final isBusy = state.phase == PivotLoadPhase.loading ||
        state.phase == PivotLoadPhase.jnapLoaded ||
        _restartCountdown > 0;
    return AppTextButton(
      cooldown > 0 ? '$baseLabel (${cooldown}s)' : baseLabel,
      icon: LinksysIcons.refresh,
      // Disabled while a run is in flight OR during the 15s anti-hammer
      // cooldown after a speed test.
      onTap: isBusy || cooldown > 0
          ? null
          : () {
              setState(() {
                _findingsExpanded = false;
                _checksExpanded = false;
              });
              // Explicit user re-run → force the speed test (bypass the 3-min
              // passive throttle). The provider still enforces the 15s hard
              // cooldown as the backstop.
              notifier.fetch(forceSpeedTest: true);
              // Start ticking so the button shows the cooldown.
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _ensureCooldownTicker());
            },
    );
  }

  Future<void> _handleAction(String actionKey) async {
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    if (actionKey == VerdictEngine.actionRestartRouter) {
      // Shared confirm + singleton guard; countdown runs only on actual restart.
      await confirmAndRestart(context, ref, onRestarted: _startRestartCountdown);
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

  Future<bool?> _confirmFirmwareUpdate(BuildContext context) {
    final state = ref.read(instantVerifyPivotProvider);
    final version = state.availableFirmwareVersion ?? 'latest version';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText.titleLarge('Install $version?'),
        content: const AppText.bodyMedium(
          'This update takes about 5 minutes.\n\n'
          'During the update:\n'
          '• Your WiFi will turn off\n'
          '• All devices will disconnect\n'
          '• This page will stop responding\n\n'
          'Your router will restart automatically when done. '
          'Your devices will reconnect on their own.\n\n'
          'Don\'t unplug your router during the update.',
        ),
        actions: [
          AppTextButton('Cancel',
                onTap: () => Navigator.pop(ctx, false)),
          AppFilledButton('Update Now',
                onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
  }

  void _showScenarioPicker(BuildContext context) {
    final notifier = ref.read(instantVerifyPivotProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      // Scroll-controlled so the sheet can grow past the default ~50% height
      // and scroll — otherwise the lower scenarios get clipped on short windows.
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: CustomTheme.of(context).radius.large),
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        const scenarios = [
          _ScenarioItem(
            index: 0,
            icon: LinksysIcons.ethernet,
            tone: InstantTestTone.problem,
            title: 'No internet connection',
            subtitle: 'WAN disconnected — critical finding + cable check',
          ),
          _ScenarioItem(
            index: 1,
            icon: LinksysIcons.publicOff,
            tone: InstantTestTone.warning,
            title: 'Websites aren\'t loading',
            subtitle: 'Connected to ISP, DNS failure — restart CTA',
          ),
          _ScenarioItem(
            index: 2,
            icon: LinksysIcons.networkCheck,
            tone: InstantTestTone.warning,
            title: 'Slow internet + weak WiFi',
            subtitle: '3 Mbps / 148ms latency + 2 weak devices + firmware + uptime',
          ),
          _ScenarioItem(
            index: 3,
            icon: LinksysIcons.router,
            tone: InstantTestTone.warning,
            title: 'Router overloaded + mesh issues',
            subtitle: 'CPU 88% / Mem 90% + zombie node + ethernet no-link',
          ),
          _ScenarioItem(
            index: 4,
            icon: LinksysIcons.encrypted,
            tone: InstantTestTone.info,
            title: 'Configuration blocks',
            subtitle: '2.4 GHz crowd + schedule + privacy + PMF + DHCP 92%',
          ),
        ];
        return Padding(
          padding: EdgeInsets.only(
            bottom: Spacing.large3 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            // Cap at 80% of screen; the list scrolls within this.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.large1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium('Test Scenarios',
                        color: scheme.onSurface),
                    const AppGap.small1(),
                    AppText.bodySmall(
                      'Load mock data to exercise each workflow without a router.',
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const AppGap.small3(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: scenarios.map((s) => ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: s.tone.container(ctx),
                  child: Icon(s.icon, size: 18, color: s.tone.onContainer(ctx)),
                ),
                title: AppText.bodyMedium(s.title),
                subtitle: AppText.bodySmall(s.subtitle,
                    color: scheme.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.large1, vertical: 2),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _findingsExpanded = false;
                    _checksExpanded = false;
                  });
                  final router = GoRouter.maybeOf(context);
                  if (router != null &&
                      router.routeInformationProvider.value.uri.path != '/instant-prototype') {
                    // Reviewer fixtures must never share the live action provider.
                    router.go('/instant-prototype?overview=${s.index}');
                  } else {
                    notifier.loadMockScenario(s.index);
                  }
                },
              )).toList(),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _ScenarioItem {
  final int index;
  final IconData icon;
  final InstantTestTone tone;
  final String title;
  final String subtitle;
  const _ScenarioItem({
    required this.index,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
  });
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
  final ValueChanged<DiagnosticClient>? onTroubleshootDevice;
  final VoidCallback? onTroubleshootWeakDevices;
  final VoidCallback? onViewNetwork;
  final void Function(int flowIndex)? onNavigateToFlow;
  final bool showProblemCards;
  final bool hasRestarted;

  const _StatusCard({
    super.key,
    required this.state,
    required this.findingsExpanded,
    required this.checksExpanded,
    required this.onToggleFindings,
    required this.onToggleChecks,
    required this.onAction,
    this.onViewClients,
    this.onTroubleshootDevice,
    this.onTroubleshootWeakDevices,
    this.onViewNetwork,
    this.onNavigateToFlow,
    this.showProblemCards = true,
    this.hasRestarted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (state.errorMessage != null ||
        (state.phase == PivotLoadPhase.complete && state.verdict == null)) {
      // Device and node data can still be current when the run fails.
      final more = _moreRows(context, devicesUnderPrimary: false);
      return _card(context, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(liveRegion: true, child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleMedium("We couldn't finish checking your connection"),
              AppGap.small2(),
              AppText.bodyMedium('Make sure this device is connected to your router, then choose Run Again. You can also choose a problem below for guided help.'),
            ],
          )),
          if (more.isNotEmpty) ...[
            const AppGap.small2(),
            ..._moreSection(more),
          ],
        ],
      ));
    }

    // Loading / preliminary state — show individual check progress
    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading ||
        state.phase == PivotLoadPhase.jnapLoaded) {
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChecklistProgress(state: state),
          ],
        ),
      );
    }

    final verdict = state.verdict;

    // Note: a failed/incomplete speed test now surfaces as a real VerdictEngine
    // warning finding ("We couldn't finish the speed test"), so it shows at the
    // top alongside any other findings and the Speed-check row flags amber.
    // No special-case card needed here.

    // All clear state — "We didn't detect any issues" + flow cards (PRD v0.7 D-16)
    if (verdict!.isAllClear) {
      final good = InstantTestTone.good.color(context);
      final more = _moreRows(context, devicesUnderPrimary: false);
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LinksysIcons.checkCircle, color: good, size: 24),
              const AppGap.small2(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText.titleMedium("We didn't detect any issues"),
                    if (verdict.checksRun > 0)
                      AppText.bodySmall(_checksPassedLabel(state),
                          color: good),
                  ],
                ),
              ),
            ]),
            // No verdict finding, but a weak device or WiFi node is still
            // worth a look.
            if (more.isNotEmpty) ...[
              const AppGap.small2(),
              ..._moreSection(more),
            ],
            const AppGap.medium(),
            if (showProblemCards)
              _problemCards(context,
                  'Still having a problem? Tell us what\'s happening and we\'ll help:'),
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
    // Device links belong to device findings (check 7) only; under an
    // unrelated finding such as router load they read as its fix.
    final devicesUnderPrimary = onTroubleshootDevice != null &&
        primary.checkNumber == 7 &&
        state.issueDevices.isNotEmpty;
    final more =
        _moreRows(context, devicesUnderPrimary: devicesUnderPrimary);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _priorityIcon(context, primary.priority),
            const AppGap.small2(),
            Expanded(
              child: AppText.titleMedium(
                primary.summary ?? primary.headline,
              ),
            ),
          ]),
          const AppGap.small1(),
          // One paragraph: the measured fact (when the title is a summary),
          // then what it means.
          Padding(
            padding: const EdgeInsets.only(left: Spacing.large3),
            child: AppText.bodyMedium(
                primary.summary != null
                    ? '${primary.headline}. ${primary.explanation}'
                    : primary.explanation,
                color: scheme.onSurfaceVariant),
          ),

          if (devicesUnderPrimary) ...[
            const AppGap.small2(),
            for (final device in state.issueDevices.map((score) => score.client))
              Padding(
                padding: const EdgeInsets.only(left: Spacing.large3),
                child: AppTextButton(
                  _helpLabel(device),
                  onTap: () => onTroubleshootDevice!(device),
                ),
              ),
          ],

          // Primary action button — or ISP escalation after restart (D-26)
          if (hasRestarted && primary.postRestartEscalation != null) ...[
            const AppGap.small3(),
            Padding(
              padding: const EdgeInsets.only(left: Spacing.large3),
              // Info card with a colored icon, as Instant-Privacy.
              child: AppSettingCard(
                title: primary.postRestartEscalation!,
                leading: Icon(LinksysIcons.infoCircle,
                    color: InstantTestTone.info.color(context)),
              ),
            ),
          ],

          // One action row: the fix, then everything else we found.
          const AppGap.small3(),
          ..._moreSection(more,
              fix: primary.hasAutoFix &&
                      !(hasRestarted && primary.postRestartEscalation != null)
                  ? AppFilledButton(primary.actionLabel!,
                      onTap: () => onAction(primary.actionKey!),
                      icon: _actionIcon(primary.actionKey!))
                  : null),

          // U-01: keep the Fix-flow entry cards reachable even when a finding is
          // shown — the customer's problem may differ from what we detected.
          if (showProblemCards) ...[
            const Divider(height: 24),
            _problemCards(context,
                'Something else? Tell us what\'s happening and we\'ll help:'),
            const AppGap.small2(),
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

  static String _moreLabel(int count) =>
      '$count more ${count == 1 ? 'thing' : 'things'} we found';

  /// The action row (the fix, if any, then the "more" toggle) and, when
  /// open, the list below it.
  List<Widget> _moreSection(List<Widget> more, {Widget? fix}) => [
        if (fix != null || more.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: Spacing.large3),
            child: Wrap(
              spacing: Spacing.medium,
              runSpacing: Spacing.small2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (fix != null) fix,
                if (more.isNotEmpty)
                  AppTextButton(
                      findingsExpanded
                          ? 'Hide ${_moreLabel(more.length)}'
                          : _moreLabel(more.length),
                      icon: findingsExpanded
                          ? LinksysIcons.arrowDropUp
                          : LinksysIcons.arrowDropDown,
                      onTap: onToggleFindings),
              ],
            ),
          ),
        if (findingsExpanded && more.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(left: Spacing.large3, top: Spacing.small2),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < more.length; i++) ...[
                    if (i > 0) const Divider(height: Spacing.medium),
                    more[i],
                  ],
                ]),
          ),
      ];

  /// Names are enough unless two devices share one; then the MAC tells
  /// them apart.
  String _helpLabel(DiagnosticClient device) {
    final sameName = state.issueDevices
        .where((score) => score.client.displayName == device.displayName)
        .length;
    return sameName > 1
        ? 'Help ${device.displayName} (${device.macAddress})'
        : 'Help ${device.displayName}';
  }

  /// Everything found besides the top result, one row and one action each:
  /// other findings, devices with weak WiFi, and WiFi nodes with a weak link
  /// to the router. Replaces the separate devices and mesh cards.
  List<Widget> _moreRows(BuildContext context,
      {required bool devicesUnderPrimary}) {
    final listDevices = !devicesUnderPrimary && state.issueDevices.isNotEmpty;
    final verdict = state.verdict;
    final findings = (verdict == null || verdict.isAllClear
            ? const <VerdictFinding>[]
            : verdict.findings.skip(1))
        .where((f) => !(listDevices && f.aboutIssueDevices));
    final weakNodes = state.meshNodes.where((n) =>
        !n.isController &&
        (n.backhaulHealth == BackhaulHealth.weak ||
            n.backhaulHealth == BackhaulHealth.critical));
    return [
      for (final finding in findings)
        _FindingRow(finding: finding, onAction: onAction),
      if (listDevices)
        for (final score in state.issueDevices.take(5))
          _MoreRow(
            tone: InstantTestTone.warning,
            title: _deviceTitle(score.client),
            detail: [
              if (score.client.signalDecibels != null)
                '${score.client.signalDecibels} dBm',
              if (score.client.band.isNotEmpty) 'on ${score.client.band}',
            ].join(' '),
            action: onTroubleshootDevice == null
                ? null
                : AppTextButton.noPadding(_helpLabel(score.client),
                    onTap: () => onTroubleshootDevice!(score.client)),
          ),
      if (listDevices && state.issueDevices.length > 5)
        _MoreRow(
          tone: InstantTestTone.warning,
          title: '${state.issueDevices.length - 5} more devices need help',
          action: onTroubleshootWeakDevices == null
              ? null
              : AppTextButton.noPadding('Troubleshoot these devices',
                  onTap: onTroubleshootWeakDevices),
        ),
      for (final node in weakNodes)
        _MoreRow(
          tone: node.backhaulHealth == BackhaulHealth.critical
              ? InstantTestTone.problem
              : InstantTestTone.warning,
          title: '${node.name} has a weak connection to the router',
          detail: 'Move it closer to the router, or connect it with an Ethernet cable.',
          action: onViewNetwork == null
              ? null
              : AppTextButton.noPadding('View WiFi nodes',
                  onTap: onViewNetwork),
        ),
    ];
  }

  static String _deviceTitle(DiagnosticClient client) {
    final weak = client.signalDecibels != null && client.signalDecibels! < -75;
    return weak
        ? '${client.displayName} has a weak WiFi signal'
        : '${client.displayName} has a slow WiFi connection';
  }

  // Shared "what's wrong?" entry cards (U-01). Reachable from BOTH the all-clear
  // state AND any findings/warning state — previously they only rendered when
  // all-clear, so the moment a finding appeared the customer lost the overview
  // path into the other Fix flows.
  Widget _problemCards(BuildContext context, String heading) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(heading, color: scheme.onSurfaceVariant),
        const AppGap.small3(),
        // Flow cards as Menu tiles (two-line titles).
        SymptomTileGrid(
          titleLines: 2,
          children: [
            for (final (index, icon, label) in const [
              (0, LinksysIcons.publicOff, 'My internet\nisn\'t working'),
              (1, LinksysIcons.networkCheck, 'My internet\nis slow'),
              (2, LinksysIcons.signalWifiOff, 'A device won\'t\nconnect'),
              (3, LinksysIcons.signalWifi0Bar, 'WiFi doesn\'t\nreach a room'),
              (4, LinksysIcons.signalWifiNone,
                  'My connection\nkeeps cutting out'),
            ])
              SymptomTile(
                iconData: icon,
                title: label,
                titleLines: 2,
                onTap: () => onNavigateToFlow?.call(index),
              ),
          ],
        ),
      ],
    );
  }

  // The dashboard internet-status pattern: a default AppCard; the status is
  // carried by the colored icon beside the headline, not the border.
  Widget _card(BuildContext context, {required Widget child}) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.medium),
      child: child,
    );
  }

  static InstantTestTone _priorityTone(VerdictPriority priority) {
    switch (priority) {
      case VerdictPriority.critical:
        return InstantTestTone.problem;
      case VerdictPriority.warning:
        return InstantTestTone.warning;
      case VerdictPriority.info:
        return InstantTestTone.info;
      case VerdictPriority.allClear:
        return InstantTestTone.good;
    }
  }

  Widget _priorityIcon(BuildContext context, VerdictPriority priority) {
    final tone = _priorityTone(priority);
    return Icon(tone.icon, color: tone.color(context), size: 24);
  }

  IconData _actionIcon(String actionKey) {
    switch (actionKey) {
      case VerdictEngine.actionRestartRouter:
        return LinksysIcons.refresh;
      case VerdictEngine.actionFirmwareUpdate:
        return LinksysIcons.cloudDownload;
      case VerdictEngine.actionBridgeModeHelp:
        return LinksysIcons.networkNode;
      default:
        return LinksysIcons.chevronRight;
    }
  }
}

// ── Finding row (secondary findings) ─────────────────────────────────────────

class _FindingRow extends StatelessWidget {
  final VerdictFinding finding;
  final Future<void> Function(String actionKey) onAction;

  const _FindingRow({required this.finding, required this.onAction});

  @override
  Widget build(BuildContext context) => _MoreRow(
        tone: _StatusCard._priorityTone(finding.priority),
        title: finding.headline,
        action: finding.hasAutoFix
            ? AppTextButton.noPadding(finding.actionLabel!,
                onTap: () => onAction(finding.actionKey!))
            : null,
      );
}

// ── One row in "more things we found" ─────────────────────────────────────────

class _MoreRow extends StatelessWidget {
  final InstantTestTone tone;
  final String title;
  final String? detail;
  final Widget? action;
  const _MoreRow(
      {required this.tone, required this.title, this.detail, this.action});

  /// An Instant-Admin row inside the result card: no border of its own,
  /// colored status icon, title and detail, and the row's action trailing.
  @override
  Widget build(BuildContext context) {
    return AppListCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      leading: Icon(tone.icon, color: tone.color(context)),
      title: AppText.labelLarge(title),
      description: detail != null && detail!.isNotEmpty
          ? AppText.bodySmall(detail!,
              color: Theme.of(context).colorScheme.onSurfaceVariant)
          : null,
      trailing: action,
    );
  }
}

// ── Check results expand (post-completion) ────────────────────────────────────

class _CheckResultsExpand extends StatelessWidget {
  final InstantVerifyPivotState state;
  // Legacy host arguments; disclosure state belongs to the mounted details.
  final bool expanded;
  final VoidCallback onToggle;

  const _CheckResultsExpand({
    required this.state,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsDisclosure(
      label: 'View test details',
      child: _ChecklistSummary(state: state),
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
    final rows = _summaryRows(widget.state);

    return AppCard(
      padding: const EdgeInsets.all(Spacing.small3),
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

/// Headline count for the checks listed under "View test details", so the
/// number always matches rows the user can open (QA: "which 13 items?").
String _checksPassedLabel(InstantVerifyPivotState state) {
  final rows = _summaryRows(state);
  final passed = rows.where((r) =>
      r.state == _CheckDisplayState.pass ||
      r.state == _CheckDisplayState.available).length;
  final notRun = [
    for (final r in rows)
      if (r.state == _CheckDisplayState.skipped) r.shortLabel,
  ];
  return '$passed of ${rows.length} checks passed'
      '${notRun.isEmpty ? '' : ' · Not run: ${notRun.join(', ')}'}';
}

List<_SummaryRow> _summaryRows(InstantVerifyPivotState state) {
    // Firmware 3-state (PRD v0.7): pass / update available / not a failure
    final missingDeviceMeasurements = state.clients.any((client) => client.isWireless && (client.signalDecibels == null || client.txRateMbps == null));
    final bool fwUpToDate = !state.firmwareUpdateAvailable;
    final String fwLabel = state.firmwareUpdateAvailable
        ? 'Firmware update available'
        : state.firmwareUpdate == null || state.firmwareUpdate!.isEmpty
            ? 'Firmware not checked'
            : 'No firmware update found';
    // Use a special "available" state icon — not pass, not fail
    final _CheckDisplayState fwState = state.firmwareUpdateAvailable
        ? _CheckDisplayState.available
        : state.firmwareUpdate == null || state.firmwareUpdate!.isEmpty
            ? _CheckDisplayState.skipped
            : _CheckDisplayState.pass;

    // "Internet connected" must reflect real reachability, not just the JNAP
    // WAN status — which can report Connected even with the WAN cable unplugged
    // (Q-04). Prefer the actual internet reachability test (DNS lookup, or the
    // public-DNS fallback that distinguishes ISP-DNS-down from internet-down).
    // Fall back to the JNAP signal only before the reachability test has run.
    final internetUntested = state.dnsCheck == null && (state.wanStatus == null || state.wanConnected);
    final bool internetReachable = state.dnsCheck == null
        ? state.wanConnected
        : (state.dnsCheck!.resolved || (state.publicDnsCheck?.resolved ?? false));

    // The router's real address is the one the browser reached it at.
    final String routerAddress = Uri.base.host;

    return <_SummaryRow>[
      _SummaryRow(
        label: 'Router reached',
        state: state.deviceInfo == null ? _CheckDisplayState.skipped : _CheckDisplayState.pass,
        detail: state.routerModel ?? '',
        expandedDetail: state.deviceInfo == null
            ? 'Router information was unavailable. Run the checks again.'
            : 'We connected to your router${routerAddress.isNotEmpty ? ' at $routerAddress' : ''}. '
            'This means your device can communicate with your router over WiFi or Ethernet.',
      ),
      _SummaryRow(
        label: 'Internet connected',
        state: internetUntested ? _CheckDisplayState.skipped : internetReachable ? _CheckDisplayState.pass : _CheckDisplayState.fail,
        detail: internetUntested ? 'Not confirmed' : internetReachable ? 'Connected' : 'No internet service',
        expandedDetail: internetUntested
            ? 'Internet access was not confirmed by this run. Choose Internet isn\'t working for help.'
            : internetReachable
            ? 'The connection check reached the internet.'
            : 'We could not confirm internet access. Choose Internet isn\'t working for guided checks.',
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
        expandedDetail: state.dnsCheck == null
            ? 'Website access was not checked. Run the checks again or choose Internet isn\'t working for help.'
            : state.dnsCheck?.resolved == true
            ? 'We sent a request to look up a website address (like google.com). '
              'Your router found it — websites should load normally.'
            : 'We tried to look up a website address and your router couldn\'t find it. '
              'This means websites may not load even though your router shows connected.',
      ),
      _SummaryRow(
        label: 'Speed check',
        // Flag high latency (>100ms) as a warning so the row visually matches
        // the "High lag detected" finding — otherwise a green pass row makes
        // the warning seem to come from nowhere.
        // Failed (ran but didn't complete) → warning, not a neutral "skipped".
        state: state.speedTestFailed
            ? _CheckDisplayState.warning
            : state.speedTest == null
                ? _CheckDisplayState.skipped
                : (state.speedTest!.latencyMs > 100
                    ? _CheckDisplayState.warning
                    : _CheckDisplayState.pass),
        detail: state.speedTestFailed
            ? "Didn't complete — try again"
            : state.speedTest == null
                ? 'Not completed'
                : '↓ ${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps  '
                    '↑ ${state.speedTest!.uploadMbps.toStringAsFixed(0)} Mbps  '
                    '${state.speedTest!.latencyMs} ms delay'
                    '${state.speedTest!.latencyMs > 100 ? ' — high lag' : ''}',
        expandedDetail: 'The speed test did not complete. Try running again.',
        expandedWidget: state.speedTest != null
            ? _SpeedGauge(
                downloadMbps: state.speedTest!.downloadMbps,
                uploadMbps: state.speedTest!.uploadMbps,
                latencyMs: state.speedTest!.latencyMs,
              )
            : null,
      ),
      _SummaryRow(
        label: 'Devices checked',
        shortLabel: 'Devices',
        // Flag amber when any device has a weak signal — matches the
        // "weak WiFi" finding so the row reflects the top-level warning.
        state: state.clients.isEmpty
            ? _CheckDisplayState.skipped
            : (state.issueDevices.isNotEmpty
                ? _CheckDisplayState.warning
                : missingDeviceMeasurements ? _CheckDisplayState.skipped : _CheckDisplayState.pass),
        detail: state.clients.isEmpty
            ? 'No devices found'
            : '${state.clients.length} device${state.clients.length == 1 ? '' : 's'} — '
                '${state.issueDevices.isNotEmpty ? '${state.issueDevices.length} may need help' : missingDeviceMeasurements ? 'Some measurements unavailable' : 'No issues detected'}',
        expandedDetail: state.clients.isEmpty
            ? 'No connected devices were detected.'
            : 'We reviewed the connection measurements available from your router. '
              '${state.issueDevices.isEmpty ? 'No device issues were detected in those measurements. Some devices may not report signal or speed.' : '${state.issueDevices.length} device${state.issueDevices.length == 1 ? ' may' : 's may'} have a weak signal or a slow WiFi connection. Choose One device is slow to select a device and get help.'}',
      ),
      _SummaryRow(
        label: fwLabel,
        shortLabel: 'Firmware',
        state: fwState,
        detail: fwUpToDate ? '' : state.availableFirmwareVersion ?? '',
        expandedDetail: state.firmwareUpdate == null || state.firmwareUpdate!.isEmpty
            ? 'Your router did not provide an update result. Try running the checks again.'
            : fwUpToDate
            ? 'Your router did not report an available update. '
              'Updates improve performance and security.'
            : 'A newer version of your router\'s firmware is available. '
              'Updates improve performance, fix bugs, and improve security.',
      ),
    ];
}

enum _CheckDisplayState { pass, fail, warning, skipped, available }

class _SummaryRow {
  final String label;
  final String? _shortLabel;
  final _CheckDisplayState state;
  final String detail;
  final String expandedDetail;
  /// When set, shown instead of expandedDetail text in the expanded panel.
  final Widget? expandedWidget;
  /// Stable name for summaries, where [label] varies with the result.
  String get shortLabel => _shortLabel ?? label;
  const _SummaryRow({
    required this.label,
    String? shortLabel,
    required this.state,
    required this.detail,
    required this.expandedDetail,
    this.expandedWidget,
  }) : _shortLabel = shortLabel;
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
    final radius = CustomTheme.of(context).radius.asBorderRadius();

    IconData iconData;
    Color iconColor;
    switch (row.state) {
      case _CheckDisplayState.pass:
        iconData = InstantTestTone.good.icon;
        iconColor = InstantTestTone.good.color(context);
      case _CheckDisplayState.fail:
        iconData = LinksysIcons.close;
        iconColor = InstantTestTone.problem.color(context);
      case _CheckDisplayState.warning:
        iconData = InstantTestTone.warning.icon;
        iconColor = InstantTestTone.warning.color(context);
      case _CheckDisplayState.skipped:
        iconData = LinksysIcons.remove;
        iconColor = scheme.outlineVariant;
      case _CheckDisplayState.available:
        iconData = LinksysIcons.cloudDownload;
        iconColor = InstantTestTone.info.color(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: radius.small,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Spacing.small2, top: 2),
            child: Row(children: [
              Icon(iconData, size: 16, color: iconColor),
              const AppGap.small2(),
              Expanded(
                child: AppText.bodySmall(row.label),
              ),
              if (row.detail.isNotEmpty)
                Flexible(
                  flex: 2,
                  child: AppText.bodySmall(
                    row.detail,
                    color: row.state == _CheckDisplayState.fail
                        ? InstantTestTone.problem.color(context)
                        : scheme.onSurfaceVariant,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const AppGap.small1(),
              Icon(
                isExpanded ? LinksysIcons.arrowDropUp : LinksysIcons.arrowDropDown,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ]),
          ),
        ),
        // Progressive disclosure (PRD v0.7 S-5)
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(
                left: Spacing.large2, bottom: Spacing.small3, right: Spacing.small2),
            // Indented under its row inside the summary card; no third
            // nested frame.
            child: row.expandedWidget ??
                AppText.bodySmall(
                  row.expandedDetail,
                  color: scheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}

// ── Checklist progress (loading + preliminary phase) ─────────────────────────

enum _CheckStatus { pending, running, pass, fail, skipped }

class _ChecklistProgress extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _ChecklistProgress({required this.state});

  @override
  Widget build(BuildContext context) {
    final step = state.browserTestStep;

    // Progress follows received evidence, without simulated success timers.
    final routerStatus = (state.phase == PivotLoadPhase.idle ||
                state.phase == PivotLoadPhase.loading)
            ? _CheckStatus.running
            : _CheckStatus.pass;

    final internetStatus = (state.phase == PivotLoadPhase.loading ||
                state.phase == PivotLoadPhase.idle)
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
        gatewayDetail = '${state.gatewayPing!.latencyMs} ms';
      } else if (!state.gatewayPing!.reachable) {
        gatewayDetail = 'Could not reach router';
      }
    } else if (step == 'dns' || step.startsWith('speed') || step == 'complete') {
      gatewayStatus = _CheckStatus.pending;
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
      dnsStatus = _CheckStatus.pending;
    } else {
      dnsStatus = _CheckStatus.pending;
    }

    _CheckStatus speedStatus;
    String speedDetail = '';
    if (!step.startsWith('speed') && step != 'complete' && state.speedTest == null) {
      speedStatus = _CheckStatus.pending;
    } else if (step.startsWith('speed')) {
      speedStatus = _CheckStatus.running;
      final substep = step.split(':').last;
      speedDetail = switch (substep) {
        'latency' => 'Measuring response time…',
        'download' => 'Testing download speed…',
        'upload' => 'Testing upload speed…',
        _ => 'Running speed test…',
      };
    } else if (state.speedTest != null) {
      speedStatus = state.speedTest!.latencyMs > 100 ? _CheckStatus.fail : _CheckStatus.pass;
      speedDetail =
          '${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps down';
    } else if (step == 'error') {
      speedStatus = _CheckStatus.fail;
      speedDetail = 'Speed test could not complete';
    } else {
      speedStatus = _CheckStatus.pending;
    }

    final deviceStatus = (state.phase == PivotLoadPhase.loading ||
                state.phase == PivotLoadPhase.idle)
            ? _CheckStatus.pending
            : state.issueDevices.isNotEmpty ? _CheckStatus.fail
            : state.clients.isEmpty || state.clients.any((c) => c.isWireless && (c.signalDecibels == null || c.txRateMbps == null))
                ? _CheckStatus.skipped : _CheckStatus.pass;
    final deviceDetail = state.clients.isEmpty
        ? ''
        : '${state.clients.length} device${state.clients.length == 1 ? '' : 's'} found';

    final statuses = [routerStatus, internetStatus, gatewayStatus, dnsStatus,
        speedStatus, deviceStatus];
    final finished = statuses
        .where((s) => s != _CheckStatus.pending && s != _CheckStatus.running)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall progress is a bar that fills as checks finish. A second
        // spinner above the per-check spinners read as two competing
        // animations (QA feedback).
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.small2),
            child: Column(
              children: [
                Semantics(
                  label: '$finished of ${statuses.length} checks finished',
                  child: ClipRRect(
                    borderRadius:
                        CustomTheme.of(context).radius.asBorderRadius().small,
                    child: LinearProgressIndicator(
                        value: finished / statuses.length,
                        minHeight: 8,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const AppGap.small3(),
                const AppText.titleMedium(
                  'Checking your connection',
                ),
                const AppGap.small1(),
                AppText.bodySmall(
                  'Running your network checks…',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
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
            label: 'Router response',
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
        icon = Icon(LinksysIcons.circle,
            size: 18, color: scheme.outlineVariant);
        labelColor = scheme.onSurfaceVariant;
      case _CheckStatus.skipped:
        icon = Icon(LinksysIcons.remove, size: 18, color: scheme.onSurfaceVariant);
      case _CheckStatus.running:
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: scheme.primary),
        );
      case _CheckStatus.pass:
        icon = Icon(InstantTestTone.good.icon,
            size: 18, color: InstantTestTone.good.color(context));
      case _CheckStatus.fail:
        final problem = InstantTestTone.problem.color(context);
        icon = Icon(LinksysIcons.close, size: 18, color: problem);
        labelColor = problem;
    }

    final statusLabel = switch (status) {
      _CheckStatus.pending => 'Waiting',
      _CheckStatus.skipped => 'Measurements unavailable',
      _CheckStatus.running => 'Checking',
      _CheckStatus.pass => 'Passed',
      _CheckStatus.fail => 'Needs attention',
    };
    return Semantics(
      label: '$label: $statusLabel',
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.small3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          icon,
          const AppGap.small2(),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppText.bodyMedium(label, color: labelColor),
            AppText.bodySmall(detail.isEmpty ? statusLabel : detail,
                color: scheme.onSurfaceVariant),
          ])),
        ]),
      ),
    );
  }
}

// ── Router light guide (PRD v0.7 S-1) ───────────────────────────────────────

class _LightGuideLink extends StatelessWidget {
  final bool showInlineCallout;
  final bool showLink;
  const _LightGuideLink({this.showInlineCallout = false, this.showLink = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inline WAN-down callout: a blocking warning, so Instant-Privacy's
        // warning card with the error border.
        if (showInlineCallout)
          AppSettingCard(
            title: 'No internet connection detected.',
            description: "Check your router's light. What color is it?",
            leading: Icon(
              InstantTestTone.problem.icon,
              color: Theme.of(context).colorScheme.error,
            ),
            trailing: AppTextButton.noPadding(
              'What does my light mean?',
              onTap: () => _showLightGuide(context),
            ),
            borderColor: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.only(bottom: Spacing.small2),
          ),
        if (showLink)
          AppTextButton('What does my router light mean?',
            icon: LinksysIcons.lightBulb,
            onTap: () => _showLightGuide(context),
          ),
      ],
    );
  }

  static void _showLightGuide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Centered, content-sized modal (RM-8/J-07) — was a draggable bottom sheet
    // that cut off rows and forced a scroll. A dialog shows the whole guide.
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: CustomTheme.of(ctx).radius.asBorderRadius().large,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.large2, Spacing.medium, Spacing.small3, Spacing.large1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  Expanded(
                    child: AppText.titleMedium(
                      'What does my router light mean?',
                      color: scheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LinksysIcons.close),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const AppGap.small2(),
            // LED patterns from Pinnacle LED spec r20260109a. Dots show the
            // physical LED colors; white and off are outlined.
            _lightRow(ctx, RouterLightColor.white, 'Solid white',
                'Everything is fine — connected to internet',
                animated: false, outlined: true),
            _lightRow(ctx, RouterLightColor.white, 'Pulsing white',
                'Starting up or WPS pairing in progress — wait about a minute',
                animated: true, animationType: 'pulse', outlined: true),
            _lightRow(ctx, RouterLightColor.white, 'Flashing white',
                'Factory reset in progress — do not unplug',
                animated: true, animationType: 'flash', outlined: true),
            _lightRow(ctx, RouterLightColor.blue, 'Pulsing blue',
                'Booting up — wait about a minute',
                animated: true, animationType: 'pulse'),
            _lightRow(ctx, RouterLightColor.red, 'Solid red',
                'No internet — check your cables',
                animated: false),
            _lightRow(ctx, RouterLightColor.yellow, 'Solid yellow',
                'Needs attention — a check found a problem',
                animated: false),
            _lightRow(ctx, RouterLightColor.green, 'Solid green',
                'Instant-Test passed — everything looks good',
                animated: false),
            _lightRow(ctx, RouterLightColor.off, 'Off',
                'No power, or Night Mode is enabled',
                animated: false, outlined: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _lightRow(
    BuildContext context,
    Color color,
    String label,
    String meaning, {
    bool animated = false,
    String animationType = 'pulse', // 'pulse' or 'flash'
    bool outlined = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).colorSchemeExt;

    // The physical LED color; white and off get an outline ring.
    Widget dot = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: CircleAvatar(
        radius: 8,
        backgroundColor: outlined ? scheme.outline : color,
        child: outlined
            ? CircleAvatar(radius: 7, backgroundColor: color)
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
            child: CircleAvatar(
              radius: 3.5,
              backgroundColor: scheme.outline,
              child: CircleAvatar(
                radius: 3,
                backgroundColor: animationType == 'flash'
                    ? scheme.surface
                    : ext.surfaceContainerHigh!,
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
          const AppGap.small3(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  AppText.labelMedium(label),
                  if (animated) ...[
                    const AppGap.small2(),
                    AppLabelText(
                      label: animationType == 'flash' ? 'flashing' : 'pulsing',
                      labelColor: scheme.onSurfaceVariant,
                    ),
                  ],
                ]),
                AppText.bodySmall(meaning, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ],
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

    // Instant-Privacy's info card: default AppCard, the colored indicator
    // (a spinner while the router restarts) above the text.
    return AppCard(
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
            const AppGap.small2(),
            Expanded(
              child: AppText.labelLarge(
                'Restarting your router…  $timeStr remaining',
              ),
            ),
          ]),
          const AppGap.small3(),
          const AppText.bodySmall(
            "Don't worry — this is normal. Your devices will "
            'disconnect for a couple minutes, then reconnect '
            "on their own. You don't need to do anything.\n\n"
            'This page will reload automatically when your '
            'router is back online.',
          ),
        ],
      ),
    );
  }
}

// ── Speed gauge widget shown in the speed row expanded panel ─────────────────

class _SpeedGauge extends StatelessWidget {
  final double downloadMbps;
  final double uploadMbps;
  final int latencyMs;

  const _SpeedGauge({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.latencyMs,
  });

  static const double _maxMbps = 1000;

  InstantTestTone _latencyTone(int ms) {
    if (ms <= 50) return InstantTestTone.good;
    if (ms <= 100) return InstantTestTone.warning;
    return InstantTestTone.problem;
  }

  String _latencyLabel(int ms) {
    if (ms <= 50) return 'Great';
    if (ms <= 100) return 'OK';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latColor = _latencyTone(latencyMs).color(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GaugeRow(
          label: 'Download',
          value: '${downloadMbps.toStringAsFixed(0)} Mbps',
          fraction: (downloadMbps / _maxMbps).clamp(0.0, 1.0),
          color: InstantTestTone.info.color(context),
        ),
        const AppGap.small2(),
        _GaugeRow(
          label: 'Upload',
          value: '${uploadMbps.toStringAsFixed(0)} Mbps',
          fraction: (uploadMbps / _maxMbps).clamp(0.0, 1.0),
          color: scheme.secondary,
        ),
        const AppGap.small2(),
        Row(children: [
          SizedBox(
            width: 72,
            child: AppText.bodySmall('Latency',
                color: scheme.onSurfaceVariant),
          ),
          CircleAvatar(radius: 4, backgroundColor: latColor),
          const AppGap.small2(),
          AppText.bodySmall('$latencyMs ms —${_latencyLabel(latencyMs)}',
              color: scheme.onSurfaceVariant),
        ]),
        const AppGap.small2(),
        AppText.bodySmall(
          'Speed measured from this device. '
          'Results can vary by time of day and WiFi distance.',
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _GaugeRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color color;

  const _GaugeRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      SizedBox(
        width: 72,
        child: AppText.bodySmall(label, color: scheme.onSurfaceVariant),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: CustomTheme.of(context).radius.asBorderRadius().small,
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            color: color,
            backgroundColor:
                Theme.of(context).colorSchemeExt.surfaceContainerHighest!,
          ),
        ),
      ),
      const AppGap.small2(),
      AppText.bodySmall(value, color: scheme.onSurfaceVariant),
    ]);
  }
}
