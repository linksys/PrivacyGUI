part of '../help_me_fix_it_tab.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Flow 5: My connection keeps cutting out
// ═══════════════════════════════════════════════════════════════════════════

enum _DropFrequency { everyFewMinutes, fewTimesDay }
enum _DropScope { wholeInternet, specificDevices }

class _Flow5 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<int> onNavigateToFlow;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  final bool singlePage;
  const _Flow5({this.singlePage = false, required this.onDone, required this.onNavigateToFlow, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow5> createState() => _Flow5State();
}

class _Flow5State extends ConsumerState<_Flow5> {
  int _step = 0;
  int _monitorGeneration = 0;
  bool _probeInFlight = false;
  String? _monitorError;
  _DropFrequency? _frequency;
  _DropScope? _scope;

  bool _isMonitoring = false;
  int _dropsDetected = 0;
  int _checksCompleted = 0;
  static const int _totalChecks = 5;

  Timer? _monitorTimer;
  bool? _restartFixed; // null=not done, true=fixed, false=still dropping

  // Item 2: within-flow back navigation
  final List<int> _stepHistory = [];

  void _pushStep(int newStep) {
    setState(() {
      if (!widget.singlePage) _stepHistory.add(_step);
      _step = newStep;
    });
    _syncStepBackNotifier();
  }

  void _stepBack() {
    if (_stepHistory.isNotEmpty) {
      // Stepping back out of the live monitor must stop it — otherwise the
      // periodic timer keeps firing and re-runs the 2-minute test (Q-18).
      _monitorTimer?.cancel();
      _monitorGeneration++;
      setState(() {
        _isMonitoring = false;
        _step = _stepHistory.removeLast();
      });
      _syncStepBackNotifier();
    }
  }

  void _syncStepBackNotifier() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    widget.stepIndicatorNotifier?.value = null;
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
      _monitorGeneration++;
    super.dispose();
  }

  Future<void> _startMonitor() async {
    if (_isMonitoring) return;
    final generation = ++_monitorGeneration;
    setState(() {
      _isMonitoring = true;
      _dropsDetected = 0;
      _checksCompleted = 0;
      _monitorError = null;
    });
    final svc = ref.read(browserDiagnosticServiceProvider);
    _monitorTimer = Timer.periodic(const Duration(seconds: 24), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_probeInFlight || generation != _monitorGeneration) return;
      _probeInFlight = true;
      final GatewayPingResult ping;
      try { ping = await svc.pingGateway(); }
      catch (_) {
        timer.cancel();
        if (mounted && generation == _monitorGeneration) {
          setState(() {
            _isMonitoring = false;
            _checksCompleted = 0;
            _monitorError = 'The connection check could not finish. Try again; no conclusion is available.';
          });
        }
        return;
      }
      finally { _probeInFlight = false; }
      if (!mounted || generation != _monitorGeneration) return;
      bool shouldAdvance = false;
      setState(() {
        _checksCompleted++;
        if (!ping.reachable) _dropsDetected++;
        if (_checksCompleted >= _totalChecks) {
          timer.cancel();
          _isMonitoring = false;
          shouldAdvance = true;
        }
      });
      if (shouldAdvance && mounted) _pushStep(3);
    });
  }

  Future<void> _restartAndCheck() async {
    if (!mounted) return;
    final restarted = await _confirmAndRestart(context, ref);
    if (!mounted || !restarted) return;
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
    });
    _pushStep(4);
  }

  @override
  Widget build(BuildContext context) => widget.singlePage
      ? _singlePage(context)
      : AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(
          key: ValueKey(_step),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step == 0) ..._step0(context),
            if (_step == 1) ..._step1Scope(context),
            if (_step == 2) ..._step2Monitor(context),
            if (_step == 3) ..._step3Result(context),
            if (_step == 4) ..._step4PostRestart(context),
          ],
        ),
      );

  void _resetResult() {
    _step = 0;
    _checksCompleted = 0;
    _dropsDetected = 0;
    _monitorError = null;
  }

  Widget _singlePage(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserStepHeading('Check for connection drops'),
        const AppGap.small2(),
        const AppText.bodyMedium('Keep this page open for a two-minute connection check. A short test may miss occasional drops.'),
        const AppGap.small3(),
        const AppText.titleSmall('How often does it drop?'),
        const AppGap.small2(),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final item in const [(_DropFrequency.everyFewMinutes, 'Every few minutes'), (_DropFrequency.fewTimesDay, 'A few times a day')])
            ChoiceChip(label: AppText.bodyMedium(item.$2), selected: _frequency == item.$1,
              onSelected: _isMonitoring ? null : (_) => setState(() { _frequency = item.$1; _resetResult(); })),
        ]),
        const AppGap.large1(),
        const AppText.titleSmall('Which devices are affected?'),
        const AppGap.small2(),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final item in const [(_DropScope.wholeInternet, 'All devices'), (_DropScope.specificDevices, 'Specific devices')])
            ChoiceChip(label: AppText.bodyMedium(item.$2), selected: _scope == item.$1,
              onSelected: _isMonitoring ? null : (_) => setState(() { _scope = item.$1; _resetResult(); })),
        ]),
      ])),
      if (_scope == _DropScope.specificDevices)
        AppOutlinedButton('Choose the affected device',
                onTap: () => widget.onNavigateToFlow(32),
                icon: LinksysIcons.devices)
      else if (_step == 3) ..._step3Result(context)
      else if (_step == 4) ..._step4PostRestart(context)
      else ...[
        if (_monitorError != null) AppText.bodyMedium(_monitorError!),
        ..._step2Monitor(context),
      ],
    ],
  );

  List<Widget> _step0(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('How often does it drop?'),
            const AppGap.small2(),
            RadioListTile<_DropFrequency>(
              value: _DropFrequency.everyFewMinutes,
              groupValue: _frequency,
              title: const AppText.bodyMedium('Every few minutes'),
              onChanged: (v) => setState(() => _frequency = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<_DropFrequency>(
              value: _DropFrequency.fewTimesDay,
              groupValue: _frequency,
              title: const AppText.bodyMedium('A few times a day'),
              onChanged: (v) => setState(() => _frequency = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Continue',
                onTap: _frequency == null
                    ? null
                    : () => _pushStep(1)),
            ),
          ],
        )),
      ];

  List<Widget> _step1Scope(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('Is it everything or specific devices?'),
            const AppGap.small2(),
            RadioListTile<_DropScope>(
              value: _DropScope.wholeInternet,
              groupValue: _scope,
              title: const AppText.bodyMedium('My whole internet goes out — all devices stop at once'),
              onChanged: (v) => setState(() => _scope = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<_DropScope>(
              value: _DropScope.specificDevices,
              groupValue: _scope,
              title: const AppText.bodyMedium('Just specific devices lose connection'),
              onChanged: (v) => setState(() => _scope = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const AppGap.small3(),
            if (_scope == _DropScope.specificDevices) ...[
              _infoBox(
                context,
                'This sounds like a device issue rather than a whole-network problem. The Device connectivity issues flow will help.',
              ),
              const AppGap.small2(),
              Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Go to Device connectivity issues',
                onTap: () => widget.onNavigateToFlow(3),
                icon: LinksysIcons.devices),
              ),
            ] else ...[
              Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Continue',
                onTap: _scope == null
                      ? null
                      : () => _pushStep(2)),
              ),
            ],
          ],
        )),
      ];

  List<Widget> _step2Monitor(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Run a 2-minute connection test'),
            const AppGap.small2(),
            _infoBox(
              context,
              'We check the connection from this device to your router every 24 seconds for two minutes. This does not test your internet provider. Keep this page open.',
            ),
            const AppGap.small3(),
            if (widget.singlePage && (_frequency == null || _scope == null)) ...[
              const AppText.bodyMedium('Select frequency and affected devices above to start the check.'),
              const AppGap.small3(),
            ],
            if (!_isMonitoring && _checksCompleted == 0) ...[
              SizedBox(
                width: widget.singlePage ? null : double.infinity,
                child: AppFilledButton('Start connection test',
                onTap: widget.singlePage && (_frequency == null || _scope == null)
                      ? null : _startMonitor,
                icon: LinksysIcons.networkCheck),
              ),
            ] else if (_isMonitoring) ...[
              Row(children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const AppGap.small3(),
                AppText.bodyMedium(
                    'Monitoring… (check ${_checksCompleted + 1} of $_totalChecks)'),
              ]),
              if (_dropsDetected > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppText.bodyMedium(
                    '$_dropsDetected drop${_dropsDetected == 1 ? '' : 's'} detected so far',
                    color: InstantTestTone.warning.color(context),
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
              Icon(LinksysIcons.error,
                  color: InstantTestTone.warning.color(context), size: 20),
              const AppGap.small2(),
              AppText.bodyMedium(
                  '$_dropsDetected drop${_dropsDetected == 1 ? '' : 's'} detected during the test'),
            ]),
            const AppGap.small3(),
            const AppText.bodyMedium('Restarting your router clears up most drop issues.'),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Restart Router',
                onTap: _restartAndCheck,
                icon: LinksysIcons.restartAlt),
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
            Row(children: [
              Icon(LinksysIcons.checkCircle,
                  color: InstantTestTone.good.color(context), size: 20),
              const AppGap.small2(),
              const Expanded(child: AppText.bodyMedium('No drops caught during the test.')),
            ]),
            const AppGap.small2(),
            const AppText.bodyMedium(
              'The drops happen frequently but we didn\'t catch one right now. Try restarting your router — this fixes most intermittent drop issues.',
              selectable: true,
            ),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Restart Router',
                onTap: _restartAndCheck,
                icon: LinksysIcons.restartAlt),
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
          Row(children: [
            Icon(LinksysIcons.checkCircle,
                color: InstantTestTone.good.color(context), size: 20),
            const AppGap.small2(),
            const Expanded(child: AppText.bodyMedium('No drops detected right now.')),
          ]),
          const AppGap.small2(),
          const AppText.bodyMedium(
            'Intermittent drops that happen a few times a day are hard to catch in a short test. Try restarting your router as a first step — it resolves most intermittent issues.',
            selectable: true,
          ),
          const AppGap.small3(),
          _checklistItem(context,
              'Check if the drops happen at a specific time (heavy usage periods like evenings can cause congestion)'),
          const AppGap.small2(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Restart Router',
                onTap: _restartAndCheck,
                icon: LinksysIcons.restartAlt),
          ),
          const AppGap.small2(),
          const AppText.labelMedium('If drops continue after a restart:'),
          const AppGap.small2(),
          _ispScript(context,
              'My connection drops several times a day. I restarted my router but the problem persists.'),
          const AppGap.small3(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
          ),
        ],
      )),

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
              const AppGap.small3(),
              const AppText.bodyMedium('Checking connection after restart…'),
            ])),
      ];
    }

    if (_restartFixed == true) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LinksysIcons.checkCircle,
                  color: InstantTestTone.good.color(context), size: 20),
              const AppGap.small2(),
              const Expanded(
                  child: AppText.bodyMedium('Looks like the restart fixed it!')),
            ]),
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
    }

    final freq = _frequency == _DropFrequency.everyFewMinutes
        ? 'every few minutes'
        : 'several times a day';

    // Item 1: PPPoE-specific ISP script
    final isPppoe = ref.watch(instantVerifyPivotProvider).wanConnectionType?.toUpperCase() == 'PPPOE';

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.titleSmall('Still dropping after restart'),
          const AppGap.small2(),
          const AppText.bodyMedium(
            'Since restarting didn\'t fix it, the issue is likely outside your router.',
            selectable: true,
          ),
          const AppGap.small3(),
          _ispScript(context, isPppoe
              ? 'My DSL/fiber connection drops for about a minute every few hours and reconnects on its own. I think it\'s a PPPoE session issue. I restarted my router but the problem persists.'
              : 'My connection drops $freq. I restarted my router but the problem persists.'),
          const _SessionSummaryCard(),
          const AppGap.medium(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('I\'ll call my provider',
                onTap: widget.onDone),
          ),
          const _SatisfactionPrompt(),
        ],
      )),

    ];
  }
}

