part of 'help_page.dart';

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

enum _Flow1Phase { running, gatewayFail, internetFail, dnsFail, allOk, unavailable }

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
  bool _isRestarting = false;
  bool _restarted = false;
  int _runs = 0;
  DateTime? _checkedAt;
  Timer? _minimumTimer;

  /// Local probes can finish within a frame. Without a visible running state
  /// a re-check that returns the same result looks like a dead button.
  static const _minimumCheck = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    final run = ++_runs;
    setState(() {
      _phase = _Flow1Phase.running;
      _gatewayOk = false;
      _internetOk = false;
      _dnsOk = false;
    });
    final shown = Completer<void>();
    _minimumTimer?.cancel();
    _minimumTimer = Timer(_minimumCheck, shown.complete);
    final phase = await _probe(run);
    await shown.future;
    if (!mounted || run != _runs) return;
    setState(() {
      _phase = phase;
      _checkedAt = DateTime.now();
    });
  }

  Future<_Flow1Phase> _probe(int run) async {
    bool current() => mounted && run == _runs;
    final svc = ref.read(browserDiagnosticServiceProvider);
    try {
      final gateway = await svc.pingGateway();
      if (current()) setState(() => _gatewayOk = gateway.reachable);
      if (!gateway.reachable) return _Flow1Phase.gatewayFail;
      final publicIp = await svc.pingPublicIp();
      if (current()) setState(() => _internetOk = publicIp.reachable);
      if (!publicIp.reachable) return _Flow1Phase.internetFail;
      final dns = await svc.checkDns();
      if (current()) setState(() => _dnsOk = dns.resolved);
      return dns.resolved ? _Flow1Phase.allOk : _Flow1Phase.dnsFail;
    } catch (_) {
      return _Flow1Phase.unavailable;
    }
  }

  Future<void> _restart() async {
    if (!mounted) return;
    final restarted = await _confirmAndRestart(context, ref);
    if (!mounted || !restarted) return;
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
    // The result and its next step share the first card (density pass).
    final lead = _resultHeader(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_phase == _Flow1Phase.running)
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [lead, ..._running(context)])),
      if (_phase == _Flow1Phase.gatewayFail) ..._gatewayFailPath(context, lead),
      if (_phase == _Flow1Phase.internetFail) ..._internetFailPath(context, lead),
      if (_phase == _Flow1Phase.dnsFail) ..._dnsFailPath(context, lead),
      if (_phase == _Flow1Phase.allOk) ..._allOkPath(context, lead),
      if (_phase == _Flow1Phase.unavailable)
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          lead,
          _leadDivider,
          Semantics(header: true,
              child: AppText.titleSmall('Try the connection check again')),
          const AppGap.small2(),
          const AppText.bodyMedium("We couldn't complete the check, so no connection result is available yet."),
          const AppGap.small3(),
          AppOutlinedButton('Try connection check again', onTap: _runDiagnostics,
              icon: LinksysIcons.refresh),
        ])),
    ]);
  }

  static const _leadDivider = Divider(height: Spacing.large2);

  Widget _resultHeader(BuildContext context) {
    final outcome = switch (_phase) {
      _Flow1Phase.running => 'Running diagnostics…',
      _Flow1Phase.unavailable => 'Connection check could not finish',
      _Flow1Phase.allOk => 'Your router can reach the internet',
      _Flow1Phase.gatewayFail => "Your device can't reach the router",
      _Flow1Phase.internetFail => "Your router can't reach the internet",
      _Flow1Phase.dnsFail => "Your router is online, but websites aren't loading",
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_phase != _Flow1Phase.running) ...[
            Icon(_phase == _Flow1Phase.allOk
                ? LinksysIcons.checkCircle : LinksysIcons.infoCircle,
                color: _phase == _Flow1Phase.allOk
                    ? InstantTestTone.good.color(context)
                    : InstantTestTone.problem.color(context),
                size: 20),
            const AppGap.small2(),
          ],
          Expanded(child: AppText.titleSmall(outcome)),
        ]),
        if (_runs > 1 && _phase != _Flow1Phase.running && _checkedAt != null) ...[
          const AppGap.small1(),
          AppText.bodySmall(
              'Checked again at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_checkedAt!))}',
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
        const AppGap.small3(),
        DetailsDisclosure(label: 'View test details', child: Column(children: [
        _checkRow(context, 'This device reached your router',
            (_phase == _Flow1Phase.running || _phase == _Flow1Phase.unavailable) && !_gatewayOk
                ? null
                : _gatewayOk),
        _checkRow(context, 'Your router reached the internet',
            (_phase == _Flow1Phase.running || _phase == _Flow1Phase.unavailable) && _gatewayOk && !_internetOk
                ? null
                : (_gatewayOk ? _internetOk : null)),
        _checkRow(context, 'Websites are loading',
            (_phase == _Flow1Phase.running || _phase == _Flow1Phase.unavailable) && _internetOk
                ? null
                : (_internetOk ? _dnsOk : null)),
        ])),
      ],
    );
  }

  Widget _checkRow(BuildContext context, String label, bool? result) {
    Widget indicator;
    if (result == null) {
      indicator = _phase == _Flow1Phase.running
          ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(LinksysIcons.remove, size: 18);
    } else if (result) {
      indicator = Icon(LinksysIcons.checkCircle,
          color: InstantTestTone.good.color(context), size: 18);
    } else {
      indicator = Icon(LinksysIcons.close,
          color: InstantTestTone.problem.color(context), size: 18);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        indicator,
        const AppGap.small3(),
        Expanded(child: AppText.bodyMedium(result == null && _phase != _Flow1Phase.running
            ? '$label — Not run' : label)),
      ]),
    );
  }

  List<Widget> _running(BuildContext context) => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
            AppGap.small2(),
            Expanded(child: AppText.bodyMedium('Checking your connection…')),
          ]),
        ),
      ];

  List<Widget> _gatewayFailPath(BuildContext context, Widget lead) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            _leadDivider,
            Semantics(header: true,
                child: AppText.titleSmall('Check your connection to the router')),
            const AppGap.small2(),
            const AppText.bodyMedium('Your device can\'t reach your router. This is usually a WiFi or cable issue between your device and the router.'),
            const AppGap.small3(),
            GuidedSteps(steps: [
              'Make sure you\'re connected to your Linksys WiFi network (not a neighbor\'s)',
              'If you\'re using a wired connection, check that the Ethernet cable is firmly plugged in at both ends',
              'Move closer to your router and try again',
            ]),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Check again',
                onTap: _runDiagnostics,
                icon: LinksysIcons.refresh),
            ),
          ],
        )),

      ];

  List<Widget> _internetFailPath(BuildContext context, Widget lead) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            _leadDivider,
            Semantics(header: true,
                child: AppText.titleSmall('Check the connection to your modem')),
            const AppGap.small2(),
            const AppText.bodyMedium('Your router is reachable but can\'t get to the internet. The issue is likely between your router and the box from your internet company (modem).'),
            const AppGap.small3(),
            GuidedSteps(steps: [
              'Find the box from your internet company (Comcast, Spectrum, AT&T, etc.) — it\'s separate from your Linksys router',
              'Check that the cable between that box and your Linksys router is firmly plugged in at both ends',
              'Look for lights on that box — if all lights are off or blinking red, the issue is with your internet service',
            ]),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Check again',
                onTap: _runDiagnostics,
                icon: LinksysIcons.refresh),
            ),
          ],
        )),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true,
                child: AppText.titleSmall(
                    'If cables are fine, contact your internet provider')),
            const AppGap.small2(),
            _ispScript(context,
                'My router is connected to your equipment but the internet isn\'t working. I checked all the cables. Please check if there\'s an outage or provisioning issue.'),
            const _SessionSummaryCard(websiteStatus: 'Not checked in this test'),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done — my internet is working now',
                onTap: widget.onDone),
            ),
          ],
        )),

      ];

  List<Widget> _dnsFailPath(BuildContext context, Widget lead) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            _leadDivider,
            Semantics(header: true,
                child: AppText.titleSmall('Try restarting your router')),
            const AppGap.small2(),
            const AppText.bodyMedium('Your router can reach the internet but domain names aren\'t resolving. This can often be fixed by restarting your router.'),
            const AppGap.small3(),
            const AppText.bodyMedium(
              'Restarting clears DNS cache issues and usually resolves this.',
            ),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Restart Router',
                onTap: _restart,
                icon: LinksysIcons.restartAlt),
            ),
            if (_restarted) ...[
              const AppGap.small2(),
              AppText.bodyMedium('Diagnostics ran again after restart.',
                  color: InstantTestTone.good.color(context)),
            ],
          ],
        )),
        if (_restarted) ...[
          _stepCard(context, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true,
                  child: AppText.titleSmall('If restarting didn\'t fix it:')),
              const AppGap.small2(),
              _ispScript(context,
                  'My router is connected and has an IP address, but websites won\'t load and domain names can\'t be resolved. I restarted my router but the problem persists.'),
              const _SessionSummaryCard(websiteStatus: 'Not loading'),
              const AppGap.small3(),
              Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done — my internet is working now',
                onTap: widget.onDone),
              ),
              const _SatisfactionPrompt(),
            ],
          )),
        ],

      ];

  List<Widget> _allOkPath(BuildContext context, Widget lead) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            _leadDivider,
            // One line leads into the choice; the likely next step is primary.
            const AppText.bodyMedium(
              'The connection looks healthy from the router\'s side, so the '
              'problem is probably on one device, or it comes and goes.',
            ),
            const AppGap.small3(),
            Wrap(spacing: Spacing.small3, runSpacing: Spacing.small2, children: [
              AppFilledButton('Yes — troubleshoot a specific device',
                  onTap: () => widget.onNavigateToFlow?.call(30),
                  icon: LinksysIcons.devices),
              AppOutlinedButton('Still seeing issues — test again',
                  onTap: _runDiagnostics,
                  icon: LinksysIcons.refresh),
            ]),
          ],
        )),
      ];
}

