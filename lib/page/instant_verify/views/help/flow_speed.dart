part of 'help_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Flow 2: My internet is slow
// ═══════════════════════════════════════════════════════════════════════════

class _Flow2 extends ConsumerStatefulWidget {
  final bool singlePage;
  final VoidCallback onDone;
  final ValueChanged<int> onNavigateToFlow;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _Flow2({this.singlePage = false, required this.onDone, required this.onNavigateToFlow, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow2> createState() => _Flow2State();
}

class _Flow2State extends ConsumerState<_Flow2> {
  // 0=run test, 1=result+plan-match, 2=all-or-one, 3=restart+retest, 4=isp, 5=gaming
  int _step = 0;
  bool _isRunning = false;
  SpeedTestResult? _speedResult;
  String? _speedError;
  bool _isRestarting = false;
  SpeedTestResult? _postRestartResult;
  // Smart QoS (CAKE bufferbloat shaping) — proto: local toggle, not wired to the
  // live smartqos JNAP action yet. The gaming/latency path is its home (bufferbloat
  // = latency-under-load). Backend: linksys/JNAP#11.


  // Item 2: within-flow back navigation
  final List<int> _stepHistory = [];

  void _pushStep(int newStep) {
    setState(() {
      _stepHistory.add(_step);
      _step = newStep;
    });
    _syncStepBackNotifier();
  }

  void _stepBack() {
    if (_stepHistory.isNotEmpty) {
      setState(() => _step = _stepHistory.removeLast());
      _syncStepBackNotifier();
    }
  }

  void _syncStepBackNotifier() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    final current = _stepHistory.length + 1;
    // Branching flows have no fixed length — show "Step N", not "of 4"
    // (a fixed denominator falsely implies more steps remain on short paths).
    widget.stepIndicatorNotifier?.value = null;
  }

  double? get _mbps => _speedResult?.downloadMbps;

  String _tier(double mbps) {
    if (mbps < 5) return 'Barely enough for one video call';
    if (mbps < 25) return 'Basic browsing and streaming for 1–2 people';
    if (mbps < 100) return 'Good for most households';
    return 'Fast — handles many devices at once';
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      // Return to the run view so the existing "Running speed test…" spinner
      // shows immediately — re-running from the result view previously flashed
      // a blank page before results reappeared (Q-21).
      _step = 0;
      _isRunning = true;
      _speedResult = null;
      _speedError = null;
      _postRestartResult = null;
    });
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final result = await svc.runInternetSpeedTest();
      if (!mounted) return;
      setState(() { _speedResult = result; _isRunning = false; _step = 1; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speedError = 'The speed check could not finish. Try again; no speed conclusion is available.';
        _isRunning = false;
        _step = 0;
      });
    }
  }

  Future<void> _restartAndRetest() async {
    if (!mounted) return;
    final restarted = await _confirmAndRestart(context, ref);
    if (!mounted || !restarted) return;
    setState(() => _isRestarting = false);
    // Re-run speed test after restart
    setState(() => _isRunning = true);
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final result = await svc.runInternetSpeedTest();
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _speedResult = null;
        _postRestartResult = null;
        _speedError = 'The speed check after restart could not finish. Try again; no speed conclusion is available.';
        _step = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(_step),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_speedError != null) _infoBox(context, _speedError!),
          if (_step == 0) ..._step0(context, state),
          if (_step == 1 && _speedResult != null) ..._step1(context),
          if (_step == 2 || (widget.singlePage && _step == 1 && _speedResult != null)) ..._step2(context),
          if (_step == 3) ..._step3(context, state),
          if (_step == 4) ..._step4(context),
          if (_step == 5) ..._step5Gaming(context),
        ],
      ),
    );
  }

  List<Widget> _step0(BuildContext context, InstantVerifyPivotState state) {
    final weakWifi = state.deviceScores.isNotEmpty &&
        state.deviceScores.first.score < 40;
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Run a speed test'),
      if (weakWifi)
        _infoBox(
          context,
          'Your device has a weak WiFi connection. This reading may be lower than your actual internet speed. Move closer to your router, then run again.',
          icon: LinksysIcons.error,
          color: InstantTestTone.warning.color(context),
        ),
      const AppGap.small3(),

          const AppGap.small3(),
          if (_isRunning) ...[
            const Row(children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              AppGap.small3(),
              AppText.bodyMedium('Running speed test (~20 seconds)…'),
            ]),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Check my speed',
                onTap: _runSpeedTest,
                icon: LinksysIcons.networkCheck),
            ),
          ],
        ],
      )),
    ];
  }

  /// Returns a plain-English description of what activities this speed supports.
  String _speedCapability(double mbps) {
    if (mbps >= 100) return 'Plenty fast — handles 4K streaming, gaming, and video calls for the whole household.';
    if (mbps >= 50) return 'Good — supports HD streaming, gaming, and video calls on multiple devices at once.';
    if (mbps >= 25) return 'Solid — handles HD video, gaming, and calls for 1–2 people at a time.';
    if (mbps >= 10) return 'Basic — works for browsing and standard streaming, but may struggle with multiple devices.';
    if (mbps >= 5) return 'Limited — enough for light browsing and calls, but video may buffer.';
    return 'Very slow — video calls and streaming will likely have trouble.';
  }

  List<Widget> _step1(BuildContext context) {
    final mbps = _mbps!;
    // Flag as potentially problematic only below 10 Mbps — not marginal slow
    final actuallyProblematic = mbps < 10;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.titleSmall('Here\'s what your connection can do'),
          const AppGap.small3(),
          // Lead with capability, not raw number
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (actuallyProblematic
                      ? InstantTestTone.warning
                      : InstantTestTone.good)
                  .container(context),
              borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
              border: Border.all(
                  color: (actuallyProblematic
                          ? InstantTestTone.warning
                          : InstantTestTone.good)
                      .color(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(_speedCapability(mbps),
                    color: (actuallyProblematic
                            ? InstantTestTone.warning
                            : InstantTestTone.good)
                        .onContainer(context)),
                const AppGap.small1(),

              ],
            ),
          ),
          const AppGap.small2(),
          DetailsDisclosure(label: 'View speed test details', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Show all three metrics — PRD D-35 requires upload visibility
                AppText.bodySmall(
                  '${mbps.toStringAsFixed(0)} Mbps down · '
                  '${_speedResult!.uploadMbps.toStringAsFixed(0)} Mbps up · '
                  '${_speedResult!.latencyMs}ms latency',
                  selectable: true,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),          AppText.bodySmall(
            'This measures your speed from this device through your browser to the internet. '
            'Browser-based tests are typically slower than your router\'s built-in speed test — '
            'that\'s normal. Results also vary by time of day and how many devices are active.',
            selectable: true,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          ])),
        ],
      )),

      // The single page places scope choices beside the result.
      if (!widget.singlePage) _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.titleSmall('Does this feel fast enough for what you\'re trying to do?'),
          const AppGap.small3(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Yes — it feels fine',
                onTap: widget.onDone),
          ),
          const AppGap.small2(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('No — something still feels slow',
              // "Still slow" → check specific devices / factors
              onTap: () => _pushStep(2),
            ),
          ),
          const AppGap.small2(),
          AppTextButton('Run test again',
                onTap: _runSpeedTest,
                icon: LinksysIcons.refresh),
        ],
      )),
      if (widget.singlePage)
        AppTextButton('Run test again',
                onTap: _runSpeedTest,
                icon: LinksysIcons.refresh),
    ];
  }

  List<Widget> _step2(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    final weakDevices = state.issueDevices;
    final jitterMs = _speedResult?.jitterMs ?? 0;
    final highJitter = jitterMs > 20;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Let\'s figure out what\'s slow'),
          const AppGap.small3(),

          // Show jitter warning if relevant (gaming/call lag)
          if (highJitter) ...[
            _infoBox(context,
                'Your connection has variable response time (${jitterMs}ms). '
                'This causes the stuttering you feel during games and video calls '
                'even when your download speed looks fine.',
                icon: LinksysIcons.uptime,
                color: InstantTestTone.warning.color(context)),
            const AppGap.small3(),
          ],

          // Show weak device signal if we detected any
          if (weakDevices.isNotEmpty) ...[
            _infoBox(context,
                '${weakDevices.length} device${weakDevices.length == 1 ? "" : "s"} on your network '
                '${weakDevices.length == 1 ? "has" : "have"} a weak WiFi signal. '
                'A weak signal reduces speed even when your overall internet is fine.',
                icon: LinksysIcons.signalWifi0Bar,
                color: InstantTestTone.warning.color(context)),
            const AppGap.small3(),
          ],

          UserStepHeading('Where is it slow?'),
          const AppGap.small2(),

          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Everything in my home is slow',
                onTap: () => _pushStep(3),
                icon: LinksysIcons.devices),
          ),
          const AppGap.small2(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Just one specific device',
              // Route to Flow 3 pre-set to "connected but slow" — skips "can it connect?" step
              onTap: () => widget.onNavigateToFlow(31),
              icon: LinksysIcons.genericDevice,
            ),
          ),
          const AppGap.small2(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Games or video calls are laggy',
                onTap: () => _pushStep(5),
                icon: LinksysIcons.stadiaController),
          ),
        ],
      )),
    ];
  }

  List<Widget> _step3(BuildContext context, InstantVerifyPivotState state) {
    // D-45: Surface VerdictEngine findings before restart suggestion
    final weakDevices = state.issueDevices;
    final wireless = state.clients.where((c) => c.isWireless).toList();
    final bandCrowded = wireless.length >= 4 &&
        wireless.where((c) => c.band.contains('2.4')).length / wireless.length >= 0.6;
    final weakNodes = state.weakBackhaulNodes;
    final hasFindings = weakDevices.isNotEmpty || bandCrowded || weakNodes.isNotEmpty;

    return [
      if (hasFindings)
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('Before restarting, here\'s what we noticed:'),
            const AppGap.small3(),
            if (weakDevices.isNotEmpty)
              _checklistItem(context,
                  '${weakDevices.length} device${weakDevices.length == 1 ? '' : 's'} '
                  '${weakDevices.length == 1 ? 'has' : 'have'} a weak WiFi signal'),
            if (bandCrowded)
              _checklistItem(context,
                  'Most of your devices are on the slower 2.4 GHz band'),
            if (weakNodes.isNotEmpty)
              _checklistItem(context,
                  '${weakNodes.map((n) => n.name).join(', ')} '
                  '${weakNodes.length == 1 ? 'has' : 'have'} a weak connection to your router'),
            const AppGap.small2(),
            AppText.bodySmall('These may be causing the slowness.',
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        )),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(
            hasFindings
                ? 'If none of these apply, try restarting your router'
                : 'Try restarting your router'),
          const AppGap.small2(),
          const AppText.bodyMedium('Restarting can clear congestion and improve speeds.'),
          const AppGap.small3(),
          SizedBox(
            width: double.infinity,
            child: _isRunning
                ? const _LoadingButton(label: 'Testing speed after restart…')
                : AppFilledButton('Restart + Run Speed Test Again',
                onTap: _restartAndRetest,
                icon: LinksysIcons.restartAlt),
          ),
          const AppGap.small2(),
          AppTextButton('Skip — already restarted',
                onTap: () => _pushStep(4)),
        ],
      )),
    ];
  }

  List<Widget> _step4(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Contact your internet provider'),
            const AppGap.small2(),
            const AppText.bodyMedium(
              'Since restarting didn\'t fix it, the issue is likely outside your router.',
            ),
            const AppGap.small3(),
            _ispScript(context,
                'My internet is slower than what I\'m paying for — only ${_postRestartResult?.downloadMbps.toStringAsFixed(0) ?? _mbps?.toStringAsFixed(0) ?? '?'} Mbps. I restarted my router but the problem persists.'),
            _SessionSummaryCard(speedStatus: (_postRestartResult ?? _speedResult) == null
                ? 'Not completed in this test'
                : '${(_postRestartResult ?? _speedResult)!.downloadMbps.toStringAsFixed(0)} Mbps down'),
            const AppGap.medium(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
            ),
            const _SatisfactionPrompt(),
          ],
        )),

      ];

  // Item 7: Gaming/latency path
  List<Widget> _step5Gaming(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Latency / lag troubleshooting'),
          const AppGap.small2(),
          _infoBox(context,
              'Gaming and video calls are sensitive to latency and jitter, not just download speed. '
              'High latency causes lag even with fast internet.'),
          const AppGap.small3(),
          GuidedSteps(steps: [
              'Connect the device with an Ethernet cable if possible — wired is always better for gaming',
              'If on WiFi, move the device closer to your router or a child node',
              'Close bandwidth-heavy apps on other devices (streaming, downloads)',
            ]),
          if (state.speedTest != null && state.speedTest!.jitterMs > 20) ...[
            const AppGap.small2(),
            _infoBox(context,
                'Your connection has high jitter (${state.speedTest!.jitterMs}ms). '
                'This causes the stuttering you feel in games and video calls. '
                'Restarting your router often improves jitter.',
                icon: LinksysIcons.error,
                color: InstantTestTone.warning.color(context)),
          ],
          if (state.isMeshNetwork && state.weakBackhaulNodes.isNotEmpty) ...[
            const AppGap.small2(),
            _infoBox(context,
                'One of your child nodes has a weak connection to your router. '
                'Devices connected through that node will experience higher latency.',
                icon: LinksysIcons.error,
                color: InstantTestTone.warning.color(context)),
          ],
          const AppGap.small3(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Restart Router',
                onTap: () => _confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
          ),
          const AppGap.small2(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
          ),
          const _SatisfactionPrompt(),
        ],
      )),

    ];
  }
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
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiers.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tiers[i].$3
                    ? InstantTestTone.info.container(context)
                    : null,
                borderRadius: i == 0
                    ? BorderRadius.vertical(
                        top: CustomTheme.of(context).radius.medium)
                    : i == tiers.length - 1
                        ? BorderRadius.vertical(
                            bottom: CustomTheme.of(context).radius.medium)
                        : null,
              ),
              child: Row(
                children: [
                  if (tiers[i].$3)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(LinksysIcons.circle, size: 8),
                    )
                  else
                    const SizedBox(width: 18),
                  const AppGap.small1(),
                  SizedBox(
                    width: 90,
                    child: tiers[i].$3
                        ? AppText.labelMedium(tiers[i].$1,
                            color: InstantTestTone.info.onContainer(context))
                        : AppText.bodySmall(tiers[i].$1),
                  ),
                  Expanded(
                    child: tiers[i].$3
                        ? AppText.labelMedium(tiers[i].$2,
                            color: InstantTestTone.info.onContainer(context))
                        : AppText.bodySmall(tiers[i].$2,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

