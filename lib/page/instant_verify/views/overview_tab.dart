import '../models/diagnostic_client.dart';
import '../models/router_light.dart';
import 'diagnostic_selection_area.dart';
import 'instant_test_style.dart';
import 'symptom_chooser.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_menu_view.dart'
    show AppMenuCard;
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/label/text_label.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// Opens a help flow by its route number; "Also found" rows use it to
  /// lead into the workflow that fixes them.
  final ValueChanged<int>? onOpenHelp;
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
    this.onOpenHelp,
    this.showProblemCards = true,
  });

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
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
    // WAN down: the light check follows the result as the next step.
    final lightCheck = state.wanStatus != null &&
        state.errorMessage == null &&
        state.phase != PivotLoadPhase.idle &&
        state.phase != PivotLoadPhase.loading &&
        !state.wanConnected;

    // Density pass (QA 2026-10-07 #3/#5): one column, one result card that
    // also lists everything else we found, compact problem choices, and the
    // light guide and support in the footer.
    return StyledAppPageView(
      title: loc(context).instantTest,
      scrollable: true,
      // The local preview opens here with nothing underneath.
      backState: Navigator.of(context).canPop()
          ? StyledBackState.enabled
          : StyledBackState.none,
      child: (context, constraints) => DiagnosticSelectionArea(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(
            key: _resultKey,
            // Run Again re-runs this result's checks, so it lives on the card.
            runAgain: _runAgain(state),
            state: state,
            onAction: _handleAction,
            onTroubleshootDevice: widget.onTroubleshootDevice,
            onTroubleshootWeakDevices: widget.onTroubleshootWeakDevices,
            onViewNetwork: widget.onViewNetwork,
            onViewClients: widget.onViewClients,
            onNavigateToFlow: widget.onNavigateToFlow,
            onOpenHelp: widget.onOpenHelp,
            showProblemCards: widget.showProblemCards,
            hasRestarted: state.hasRestartedThisSession,
          ),
          // WAN down: the next step after the result (PRD v0.7 S-1).
          // Otherwise the general guide link is in the footer.
          if (lightCheck) ...[
            const AppGap.small2(),
            const _LightGuideLink(showLink: false, showInlineCallout: true),
          ],
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
              if (!lightCheck) const _LightGuideLink(),
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
      )),
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
  final Future<void> Function(String actionKey) onAction;
  final VoidCallback? onViewClients;
  final ValueChanged<DiagnosticClient>? onTroubleshootDevice;
  final VoidCallback? onTroubleshootWeakDevices;
  final VoidCallback? onViewNetwork;
  final void Function(int flowIndex)? onNavigateToFlow;
  final ValueChanged<int>? onOpenHelp;
  final bool showProblemCards;
  final bool hasRestarted;

  /// Re-runs the checks this card reports; shown at the card's top right.
  final Widget? runAgain;

  const _StatusCard({
    super.key,
    this.runAgain,
    required this.state,
    required this.onAction,
    this.onViewClients,
    this.onTroubleshootDevice,
    this.onTroubleshootWeakDevices,
    this.onViewNetwork,
    this.onNavigateToFlow,
    this.onOpenHelp,
    this.showProblemCards = true,
    this.hasRestarted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (state.errorMessage != null ||
        (state.phase == PivotLoadPhase.complete && state.verdict == null)) {
      // Device and node data can still be current when the run fails.
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
          if (runAgain != null) ...[const AppGap.small2(), runAgain!],
          _results(primary: null, devicesUnderPrimary: false),
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
    // top alongside any other findings and the Speed row flags amber.
    // No special-case card needed here.

    // All clear state — "We didn't detect any issues" + flow cards (PRD v0.7 D-16)
    if (verdict!.isAllClear) {
      final good = InstantTestTone.good.color(context);
      return _card(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LinksysIcons.checkCircle, color: good, size: 24),
              const AppGap.small2(),
              // The count is under "What we checked" below.
              const Expanded(
                child: AppText.titleMedium("We didn't detect any issues"),
              ),
              if (runAgain != null) runAgain!,
            ]),
            _results(primary: null, devicesUnderPrimary: false),
            if (showProblemCards) ...[
              const AppGap.medium(),
              _problemCards(context,
                  'Still having a problem? Tell us what\'s happening and we\'ll help:'),
            ],
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
            if (runAgain != null) runAgain!,
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

          // The fix for the headline finding.
          if (_fixShown(primary)) ...[
            const AppGap.small3(),
            Padding(
              padding: const EdgeInsets.only(left: Spacing.large3),
              child: AppFilledButton(primary.actionLabel!,
                  onTap: () => onAction(primary.actionKey!),
                  icon: _actionIcon(primary.actionKey!)),
            ),
          ],

          _results(primary: primary, devicesUnderPrimary: devicesUnderPrimary),

          // U-01: keep the Fix-flow entry cards reachable even when a finding is
          // shown — the customer's problem may differ from what we detected.
          if (showProblemCards) ...[
            const Divider(height: 24),
            _problemCards(context,
                'Something else? Tell us what\'s happening and we\'ll help:'),
            const AppGap.small2(),
          ],
        ],
      ),
    );
  }

  bool _fixShown(VerdictFinding primary) =>
      primary.hasAutoFix &&
      !(hasRestarted && primary.postRestartEscalation != null);

  Widget _results(
          {required VerdictFinding? primary,
          required bool devicesUnderPrimary}) =>
      _CheckResults(
        state: state,
        primary: primary,
        fixShown:
            primary != null && _fixShown(primary) ? primary.actionKey : null,
        listDevices: !devicesUnderPrimary,
        onAction: onAction,
        onOpenHelp: onOpenHelp,
        onTroubleshootDevice: onTroubleshootDevice,
        onTroubleshootWeakDevices: onTroubleshootWeakDevices,
      );

  /// Names are enough unless two devices share one; then the MAC tells
  /// them apart.
  String _helpLabel(DiagnosticClient device) =>
      'Help ${_deviceName(state, device)}';

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
        // Flow cards as Menu tiles.
        SymptomTileGrid(
          children: [
            for (final (index, icon, label) in const [
              (0, LinksysIcons.publicOff, 'My internet\nisn\'t working'),
              (1, LinksysIcons.networkCheck, 'My internet\nis slow'),
              (2, LinksysIcons.signalWifiOff, 'A device won\'t\nconnect'),
              (3, LinksysIcons.signalWifi0Bar, 'WiFi doesn\'t\nreach a room'),
              (4, LinksysIcons.signalWifiNone,
                  'My connection\nkeeps cutting out'),
            ])
              AppMenuCard(
                iconData: icon,
                title: label,
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

/// Names are enough unless two devices share one; then the MAC tells
/// them apart.
String _deviceName(InstantVerifyPivotState state, DiagnosticClient device) {
  final sameName = state.issueDevices
      .where((score) => score.client.displayName == device.displayName)
      .length;
  return sameName > 1
      ? '${device.displayName} (${device.macAddress})'
      : device.displayName;
}

// ── What we checked ──────────────────────────────────────────────────────────

enum _CheckDisplayState { pass, fail, warning, skipped, notice }

/// One problem under an area: opens its help flow, or carries its own
/// action when its fix is a single step (an update, a restart).
class _Issue {
  final String text;
  final String? detail;
  final VoidCallback? onTap;
  final Widget? action;
  const _Issue(this.text, {this.detail, this.onTap, this.action});
}

/// One part of the network: what we measured, and any problems in it.
class _Area {
  final String label;
  final _CheckDisplayState state;
  final String result;

  /// Shown only when the area could not be checked.
  final String? explanation;
  final List<_Issue> issues;
  const _Area(this.label, this.state, this.result,
      {this.explanation, this.issues = const []});
}

/// Every check, grouped by the part of the network it looks at: router,
/// internet, speed, devices (wired and WiFi) and, when the network has
/// them, WiFi nodes. A problem is listed once, under its area, and leads
/// to its fix; the headline problem is the card's title instead.
class _CheckResults extends StatelessWidget {
  final InstantVerifyPivotState state;
  final VerdictFinding? primary;

  /// The action the card's fix button already offers.
  final String? fixShown;

  /// False when the weak devices are already listed under the headline.
  final bool listDevices;
  final Future<void> Function(String actionKey) onAction;
  final ValueChanged<int>? onOpenHelp;
  final ValueChanged<DiagnosticClient>? onTroubleshootDevice;
  final VoidCallback? onTroubleshootWeakDevices;

  const _CheckResults({
    required this.state,
    required this.primary,
    required this.fixShown,
    required this.listDevices,
    required this.onAction,
    this.onOpenHelp,
    this.onTroubleshootDevice,
    this.onTroubleshootWeakDevices,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final areas = _areas(state, primary: primary, issueFor: _issue,
        deviceIssues: listDevices ? _deviceIssues() : const []);
    return Padding(
      padding: const EdgeInsets.only(left: Spacing.large3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: Spacing.large2),
          Semantics(
              header: true, child: const AppText.titleSmall('What we checked')),
          AppText.bodySmall(_areasLabel(areas), color: scheme.onSurfaceVariant),
          const AppGap.small2(),
          for (var i = 0; i < areas.length; i++) ...[
            if (i > 0) const Divider(height: Spacing.medium),
            _AreaRow(area: areas[i]),
          ],
        ],
      ),
    );
  }

  _Issue _issue(VerdictFinding finding) {
    final flow = finding.helpFlow;
    if (flow != null && onOpenHelp != null) {
      return _Issue(finding.headline, onTap: () => onOpenHelp!(flow));
    }
    return _Issue(finding.headline,
        action: finding.hasAutoFix && finding.actionKey != fixShown
            ? AppTextButton.noPadding(finding.actionLabel!,
                onTap: () => onAction(finding.actionKey!))
            : null);
  }

  List<_Issue> _deviceIssues() => [
        for (final score in state.issueDevices.take(5))
          _Issue(
            _deviceTitle(score.client, _deviceName(state, score.client)),
            detail: [
              if (score.client.signalDecibels != null)
                '${score.client.signalDecibels} dBm',
              if (score.client.band.isNotEmpty) 'on ${score.client.band}',
            ].join(' '),
            onTap: onTroubleshootDevice == null
                ? null
                : () => onTroubleshootDevice!(score.client),
          ),
        if (state.issueDevices.length > 5)
          _Issue('${state.issueDevices.length - 5} more devices need help',
              onTap: onTroubleshootWeakDevices),
      ];

  static String _deviceTitle(DiagnosticClient client, String name) {
    final weak = client.signalDecibels != null && client.signalDecibels! < -75;
    return weak
        ? '$name has a weak WiFi signal'
        : '$name has a slow WiFi connection';
  }
}

/// "3 of 5 look good", naming what could not be checked, so the count
/// always matches the rows shown (QA: "which 13 items?").
String _areasLabel(List<_Area> areas) {
  final good = areas
      .where((a) =>
          a.state == _CheckDisplayState.pass ||
          a.state == _CheckDisplayState.notice)
      .length;
  final notRun = [
    for (final a in areas)
      if (a.state == _CheckDisplayState.skipped) a.label,
  ];
  return '$good of ${areas.length} look good'
      '${notRun.isEmpty ? '' : ' · Not checked: ${notRun.join(', ')}'}';
}

_CheckDisplayState _stateFor(VerdictPriority priority) => switch (priority) {
      VerdictPriority.critical => _CheckDisplayState.fail,
      VerdictPriority.warning => _CheckDisplayState.warning,
      VerdictPriority.info => _CheckDisplayState.notice,
      VerdictPriority.allClear => _CheckDisplayState.pass,
    };

/// The worse of two states, failure first.
_CheckDisplayState _worse(_CheckDisplayState a, _CheckDisplayState b) {
  const order = [
    _CheckDisplayState.fail,
    _CheckDisplayState.warning,
    _CheckDisplayState.skipped,
    _CheckDisplayState.notice,
    _CheckDisplayState.pass,
  ];
  return order.indexOf(a) <= order.indexOf(b) ? a : b;
}

List<_Area> _areas(
  InstantVerifyPivotState state, {
  required VerdictFinding? primary,
  required _Issue Function(VerdictFinding) issueFor,
  required List<_Issue> deviceIssues,
}) {
  final verdict = state.verdict;
  final findings = verdict?.findings ?? const <VerdictFinding>[];
  final checks = verdict?.checks ?? const <VerdictCheck>[];
  VerdictCheck? check(String label) =>
      checks.where((c) => c.label == label).firstOrNull;

  // Findings in an area: the worst sets its state; all but the headline are
  // listed under it. Weak devices are listed by name instead of as a count.
  _CheckDisplayState worst(VerdictArea area, _CheckDisplayState base) =>
      findings
          .where((f) => f.area == area)
          .map((f) => _stateFor(f.priority))
          .fold(base, _worse);
  List<_Issue> issues(VerdictArea area) => [
        for (final f in findings)
          if (f.area == area &&
              !identical(f, primary) &&
              !(f.aboutIssueDevices && deviceIssues.isNotEmpty))
            issueFor(f),
      ];

  // ── Router: reached, load, time since restart, software ──
  final reached = state.deviceInfo != null;
  final load = check('Router load');
  final uptime = check('Time since restart');
  final routerIssues = issues(VerdictArea.router);
  final firmwareChecked =
      state.firmwareUpdate != null && state.firmwareUpdate!.isNotEmpty;
  final router = _Area(
    'Router',
    reached ? worst(VerdictArea.router, _CheckDisplayState.pass)
        : _CheckDisplayState.skipped,
    reached
        ? [
            if (state.routerModel != null) state.routerModel!,
            // A measurement already named by a problem isn't repeated.
            if (load != null && load.status == VerdictCheckStatus.pass)
              load.result,
            if (uptime != null && uptime.status == VerdictCheckStatus.pass)
              'Up ${uptime.result.toLowerCase()}',
            if (!firmwareChecked)
              "Update check didn't run"
            else if (!state.firmwareUpdateAvailable)
              'Software up to date',
          ].join(' · ')
        : 'Not reached',
    explanation: reached
        ? null
        : 'Router information was unavailable. Run the checks again.',
    issues: routerIssues,
  );

  // ── Internet: connection and websites ──
  final dns = state.dnsCheck;
  final internetDown = dns == null
      ? state.wanStatus != null && !state.wanConnected
      : !(dns.resolved || (state.publicDnsCheck?.resolved ?? false));
  final internet = _Area(
    'Internet',
    dns == null && !internetDown
        ? _CheckDisplayState.skipped
        : worst(
            VerdictArea.internet,
            internetDown || !dns!.resolved
                ? _CheckDisplayState.fail
                : _CheckDisplayState.pass),
    internetDown
        ? 'No internet service'
        : dns == null
            ? 'Not confirmed'
            : dns.resolved
                ? 'Connected · websites loading'
                : "Connected, but websites aren't loading",
    explanation: dns == null && !internetDown
        ? "Internet access wasn't confirmed by this run. Choose Internet isn't working for help."
        : null,
    issues: issues(VerdictArea.internet),
  );

  // ── Speed ──
  final speed = state.speedTest;
  final speedArea = _Area(
    'Speed',
    state.speedTestFailed
        ? _CheckDisplayState.warning
        : speed == null
            ? _CheckDisplayState.skipped
            : worst(
                VerdictArea.speed,
                speed.latencyMs > 100
                    ? _CheckDisplayState.warning
                    : _CheckDisplayState.pass),
    state.speedTestFailed
        ? "Didn't complete"
        : speed == null
            ? 'Not completed'
            : '↓ ${speed.downloadMbps.toStringAsFixed(0)} Mbps  '
                '↑ ${speed.uploadMbps.toStringAsFixed(0)} Mbps  '
                '${speed.latencyMs} ms delay',
    explanation: speed == null
        ? 'The speed test did not complete. Try running again.'
        : null,
    issues: issues(VerdictArea.speed),
  );

  // ── Devices: wired and WiFi, and what affects them joining ──
  final clients = state.clients;
  final wired = clients.where((c) => !c.isWireless).length;
  final missingMeasurements = clients.any((c) =>
      c.isWireless && (c.signalDecibels == null || c.txRateMbps == null));
  final deviceArea = [...deviceIssues, ...issues(VerdictArea.devices)];
  final devices = _Area(
    'Devices',
    clients.isEmpty
        ? _CheckDisplayState.skipped
        : worst(
            VerdictArea.devices,
            state.issueDevices.isNotEmpty
                ? _CheckDisplayState.warning
                : missingMeasurements
                    ? _CheckDisplayState.skipped
                    : _CheckDisplayState.pass),
    clients.isEmpty
        ? 'No devices found'
        : [
            '${clients.length - wired} on WiFi',
            if (wired > 0) '$wired wired',
            if (deviceArea.isEmpty)
              missingMeasurements
                  ? 'Some measurements unavailable'
                  : 'No problems found',
          ].join(' · '),
    explanation: clients.isEmpty ? 'No connected devices were detected.' : null,
    issues: deviceArea,
  );

  // ── WiFi nodes: only when the network has them ──
  final children = state.meshNodes.where((n) => !n.isController).length;
  final nodeIssues = issues(VerdictArea.nodes);

  return [
    router,
    internet,
    speedArea,
    devices,
    if (children > 0)
      _Area(
        'WiFi nodes',
        worst(VerdictArea.nodes, _CheckDisplayState.pass),
        [
          '$children node${children == 1 ? '' : 's'}',
          if (nodeIssues.isEmpty &&
              !findings.any((f) => f.area == VerdictArea.nodes))
            'connected well',
        ].join(' · '),
        issues: nodeIssues,
      ),
  ];
}

/// One area: status icon, name and result, then each problem in it.
class _AreaRow extends StatelessWidget {
  final _Area area;
  const _AreaRow({required this.area});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (iconData, iconColor) = switch (area.state) {
      _CheckDisplayState.pass => (
          InstantTestTone.good.icon,
          InstantTestTone.good.color(context)
        ),
      _CheckDisplayState.fail => (
          LinksysIcons.close,
          InstantTestTone.problem.color(context)
        ),
      _CheckDisplayState.warning => (
          InstantTestTone.warning.icon,
          InstantTestTone.warning.color(context)
        ),
      _CheckDisplayState.skipped => (LinksysIcons.remove, scheme.onSurfaceVariant),
      _CheckDisplayState.notice => (
          InstantTestTone.info.icon,
          InstantTestTone.info.color(context)
        ),
    };

    return AppListCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      leading: Icon(iconData, color: iconColor),
      title: AppText.labelLarge(area.label),
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The icon carries the color; colored small text misses the
          // contrast minimum.
          if (area.result.isNotEmpty)
            AppText.bodySmall(area.result, color: scheme.onSurfaceVariant),
          if (area.explanation != null)
            AppText.bodySmall(area.explanation!,
                color: scheme.onSurfaceVariant),
          for (final issue in area.issues) _IssueLine(issue: issue),
        ],
      ),
    );
  }
}

/// A problem under its area. A line that opens a help flow is one button
/// with a chevron; one with its own fix shows that action.
class _IssueLine extends StatelessWidget {
  final _Issue issue;
  const _IssueLine({required this.issue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = Padding(
      padding: const EdgeInsets.only(top: Spacing.small2),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(issue.text),
              if (issue.detail != null && issue.detail!.isNotEmpty)
                AppText.bodySmall(issue.detail!,
                    color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        if (issue.onTap != null)
          Icon(LinksysIcons.chevronRight, color: scheme.primary)
        else if (issue.action != null)
          issue.action!,
      ]),
    );
    if (issue.onTap == null) return line;
    // Announced as one button, as the problem choices are.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(onTap: issue.onTap, child: line),
      ),
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
          // The result card already reports "No internet connection
          // detected"; this is the next step, not a second error.
          // One tappable row with a chevron, like Instant-Admin's Time zone
          // row, so it fits phone widths without a squeezed trailing button.
          MergeSemantics(
            child: Semantics(
              button: true,
              child: AppSettingCard(
                title: "Check your router's light",
                description:
                    'Its color shows where the connection stops. See what each light means.',
                leading: Icon(
                  LinksysIcons.lightBulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                trailing: const Icon(LinksysIcons.chevronRight),
                onTap: () => _showLightGuide(context),
              ),
            ),
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

