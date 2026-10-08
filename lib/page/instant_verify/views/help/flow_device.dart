part of '../help_me_fix_it_tab.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Flow 3: Device connectivity issues
// ═══════════════════════════════════════════════════════════════════════════

enum _DeviceType { phone, laptop, smartHome, gaming, other }
enum _ConnectState { canConnect, cantConnect, wired }
enum _ConnectIssue { keepsDropping, slowOnDevice, other, cantConnect }

class _Flow3 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  /// Called to navigate to My Devices tab (Tab 1) directly.
  final VoidCallback? onNavigateToMyDevices;
  /// When true, skip step 0 ("can your device connect?") and start directly
  /// at the connected-but-something-wrong path.
  final bool initialConnected;
  /// When true (from Flow 2 "Just one specific device"), skip straight to the
  /// slow-device path with device picker — don't ask "what's happening?"
  final bool initialSlowDevice;
  final _ConnectIssue? initialIssue;
  /// The specific device that was selected in My Devices — pre-populates
  /// device-specific analysis in the slow device path.
  final DiagnosticClient? initialDevice;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  final bool singlePage;
  const _Flow3({this.singlePage = false, required this.onDone, this.onNavigateToMyDevices, this.initialConnected = false, this.initialSlowDevice = false, this.initialIssue, this.initialDevice, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow3> createState() => _Flow3State();
}

class _Flow3State extends ConsumerState<_Flow3> {
  // 0=can-connect?, 1a=issue-type (if connected), 1b=device-type (if not connected), 2a=keeps-dropping, 2b=path-A or 2c=path-B
  int _step = 0;
  _ConnectState? _connectState;
  _ConnectIssue? _connectIssue;
  _DeviceType? _deviceType;
  String _deviceQuery = '';
  int _devicePage = 0;
  static const _devicesPerPage = 8;
  bool _isDisablingMacFilter = false;
  bool _macFilterDisabled = false;
  // null = not yet answered, true = can see SSID, false = can't see SSID (Item 12)
  bool? _canSeeSsid;

  /// The problem came from the chosen symptom or a chip, not the default.
  bool _problemAnswered = false;

  /// Device selected in My Devices or chosen via inline picker.
  /// Enables device-specific analysis in _slowDevicePath().
  DiagnosticClient? _selectedDevice;

  // Item 2: within-flow back navigation
  final List<int> _stepHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSlowDevice) {
      _step = 2;
      _connectState = _ConnectState.canConnect;
      _connectIssue = _ConnectIssue.slowOnDevice;
    } else if (widget.initialConnected) {
      _step = 1;
      _connectState = _ConnectState.canConnect;
    }
    if (widget.singlePage) _connectIssue = widget.initialIssue ?? _connectIssue ?? _ConnectIssue.other;
    _problemAnswered = widget.initialIssue != null || widget.initialSlowDevice;
    _selectedDevice = widget.initialDevice;
  }

  void _pushStep(int newStep) {
    setState(() {
      if (!widget.singlePage) _stepHistory.add(_step);
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
    widget.stepIndicatorNotifier?.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    if (widget.singlePage) return _singlePage(context, state);
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
          if (_step == 1 && _connectState == _ConnectState.cantConnect) ..._step1CantConnect(context),
          if (_step == 1 && _connectState == _ConnectState.wired) ..._step1Wired(context),
          if (_step == 3 && _connectIssue == _ConnectIssue.other) ..._pathOther(context, state),
          if (_step == 3 && _connectIssue != _ConnectIssue.other) ..._pathA(context, state),
          if (_step == 4) ..._pathB(context, state),
        ],
      ),
    );
  }

  Widget _singlePage(BuildContext context, InstantVerifyPivotState state) {
    final loading = state.phase == PivotLoadPhase.idle || state.phase == PivotLoadPhase.loading;
    final selectedPresent = _selectedDevice != null &&
        state.clients.any((c) => c.macAddress == _selectedDevice!.macAddress);
    final matches = state.clients.where((device) =>
        device.displayNameWithOui.toLowerCase().contains(_deviceQuery.toLowerCase()) ||
        device.macAddress.toLowerCase().contains(_deviceQuery.toLowerCase())).toList();
    final lastPage = matches.isEmpty ? 0 : (matches.length - 1) ~/ _devicesPerPage;
    final page = _devicePage.clamp(0, lastPage);
    final visible = matches.skip(page * _devicesPerPage).take(_devicesPerPage);
    final theme = Theme.of(context);
    final choices = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      if (state.clients.length > _devicesPerPage) ...[
        TextField(
          decoration: const InputDecoration(labelText: 'Find a device', prefixIcon: Icon(LinksysIcons.search), border: OutlineInputBorder()),
          onChanged: (value) => setState(() { _deviceQuery = value; _devicePage = 0; }),
        ),
        const AppGap.small3(),
      ],
      if (loading) const LinearProgressIndicator(),
      if (!loading && state.clients.isEmpty)
        const AppText.bodyMedium('No device list is available. This does not tell us whether your device is connected.'),
      if (state.clients.isNotEmpty && matches.isEmpty)
        const AppText.bodyMedium('No devices match your search.'),
      for (final device in visible) ...[
        Material(
          color: _selectedDevice?.macAddress == device.macAddress
              ? theme.colorScheme.secondaryContainer : Colors.transparent,
          borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
          child: ListTile(
            key: ValueKey('device-choice-${device.macAddress}'),
            selected: _selectedDevice?.macAddress == device.macAddress,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            // Same radio look as the kit's AppRadioList. The tile is the one
            // control: it handles taps, focus and the selected state, so the
            // radio adds no extra Tab stop or screen-reader node.
            leading: ExcludeFocus(
                child: ExcludeSemantics(
                    child: IgnorePointer(
                        child: Radio<String>(
                            value: device.macAddress,
                            groupValue: _selectedDevice?.macAddress,
                            onChanged: loading ? null : (_) {})))),
            title: AppText.bodyMedium(device.displayNameWithOui, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: AppText.bodySmall(device.isWireless ? 'WiFi' : 'Ethernet',
                color: theme.colorScheme.onSurfaceVariant),
            onTap: loading ? null : () => setState(() {
              _selectedDevice = device;
              _connectState = device.isWireless ? _ConnectState.canConnect : _ConnectState.wired;
              _canSeeSsid = null;
              _step = 2;
            }),
          ),
        ),
        const AppGap.small1(),
      ],
      if (matches.length > _devicesPerPage)
        Row(children: [
          Expanded(child: AppText.bodyMedium('${page * _devicesPerPage + 1}–${page * _devicesPerPage + visible.length} of ${matches.length}')),
          IconButton(tooltip: 'Previous devices', onPressed: page == 0 ? null : () => setState(() => _devicePage = page - 1),
              icon: const RotatedBox(quarterTurns: 2, child: Icon(LinksysIcons.chevronRight))),
          IconButton(tooltip: 'Next devices', onPressed: page == lastPage ? null : () => setState(() => _devicePage = page + 1), icon: const Icon(LinksysIcons.chevronRight)),
        ]),
      const Divider(height: 24),
      const AppText.titleSmall('Device not listed?'),
      AppTextButton("I don't see my device",
                onTap: () => setState(() {
        _selectedDevice = null;
        _connectState = _ConnectState.cantConnect;
        _canSeeSsid = null;
        _step = 1;
      })),
      AppTextButton('My device uses an Ethernet cable',
                onTap: () => setState(() {
        _selectedDevice = null;
        _connectState = _ConnectState.wired;
        _step = 1;
      })),
    ]);
    // Option A (QA #2): answered questions collapse to one line above the
    // current step, so the next action is always the card below them.
    final selected = _selectedDevice != null && selectedPresent ? _selectedDevice! : null;
    final unlisted = _selectedDevice == null && _connectState == _ConnectState.cantConnect;
    final wired = _selectedDevice == null && _connectState == _ConnectState.wired;
    final Widget deviceStep = selected != null || unlisted || wired
        ? AnswerRow(
            // A new answer closes the change controls.
            key: ValueKey('answer-device-${selected?.macAddress ?? _connectState}'),
            label: 'Device',
            value: selected?.displayNameWithOui ??
                (unlisted ? 'Not in the list' : 'Uses an Ethernet cable'),
            detail: selected == null ? null : (selected.isWireless ? 'WiFi' : 'Ethernet'),
            changeLabel: 'Change device',
            choices: choices)
        : _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            UserStepHeading('Which device needs help?'),
            const AppGap.small2(),
            choices,
          ]));
    const issues = [
      (_ConnectIssue.cantConnect, "Won't connect"),
      (_ConnectIssue.slowOnDevice, 'Slow connection'),
      (_ConnectIssue.keepsDropping, 'Keeps disconnecting'),
      (_ConnectIssue.other, 'Something else'),
    ];
    final issueChips = Wrap(spacing: Spacing.small2, runSpacing: Spacing.small2, children: [
      for (final item in issues) ChoiceChip(label: AppText.bodyMedium(item.$2), selected: _connectIssue == item.$1,
          onSelected: (_) => setState(() { _connectIssue = item.$1; _problemAnswered = true; _step = 2; })),
    ]);
    final problemStep = selected == null || _connectState == _ConnectState.wired
        ? null
        : _problemAnswered
            ? AnswerRow(
                key: ValueKey('answer-problem-$_connectIssue'),
                label: 'Problem',
                value: issues.firstWhere((item) => item.$1 == _connectIssue).$2,
                changeLabel: 'Change problem',
                choices: issueChips)
            : _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // All problems stay visible (QA): a collapsed picker under a
                // "Something else" heading hid what the section was for.
                const AppText.titleSmall("What's happening with this device?"),
                const AppGap.small2(),
                issueChips,
              ]));
    final help = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_selectedDevice != null && !selectedPresent)
        _infoBox(context, 'The selected device is not in the latest list. Its connection status is unknown.'),
      if (problemStep != null) problemStep,
      if (_connectState == _ConnectState.cantConnect) ...[
        _infoBox(context, 'A device can be missing because it is offline or the router has incomplete information. Check its WiFi settings below.'),
        ..._step1CantConnect(context),
      ] else if (_connectState == _ConnectState.wired) ..._step1Wired(context)
      else if (_selectedDevice != null && selectedPresent) ...[
        if (_connectIssue == _ConnectIssue.cantConnect) ..._step1CantConnect(context)
        else if (_connectIssue == _ConnectIssue.keepsDropping) ..._keepsDroppingFlow(context, state)
        else if (_connectIssue == _ConnectIssue.other) ..._pathOther(context, state)
        else ..._deviceAnalysisCards(context, state,
            state.clients.firstWhere((c) => c.macAddress == _selectedDevice!.macAddress)),
      ],
    ]);
    return InstantTestFocusColumn(children: [deviceStep, help]);
  }

  List<Widget> _step0(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('Can your device connect to your WiFi?'),
            const AppGap.small2(),
            AppText.bodySmall(
              'It may show as connected but have no internet, or it may not connect at all.',
              selectable: true,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Yes — it\'s connected but something is wrong',
                onTap: () {
                  setState(() => _connectState = _ConnectState.canConnect);
                  _pushStep(1);
                },
                icon: LinksysIcons.wifi),
            ),
            const AppGap.small2(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('No — it won\'t connect at all',
                onTap: () {
                  setState(() => _connectState = _ConnectState.cantConnect);
                  _pushStep(1);
                },
                icon: LinksysIcons.signalWifiOff),
            ),
            const AppGap.small2(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('No — my device uses an Ethernet cable',
                onTap: () {
                  setState(() => _connectState = _ConnectState.wired);
                  _pushStep(1);
                },
                icon: LinksysIcons.ethernet),
            ),
          ],
        )),
      ];

  List<Widget> _step1Wired(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Wired device troubleshooting'),
            const AppGap.small2(),
            AppText.bodySmall(
              'Try a step, then check whether the connection improves.',
              selectable: true,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const AppGap.small3(),
            GuidedSteps(steps: [
              'Check the Ethernet cable is firmly plugged in at both ends',
              'Try a different Ethernet port on the router',
              'Try a different cable if you have one',
              'Check if the port light on the router is on when plugged in',
              'Restart the device and try again',
            ]),
          ],
        )),
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Still not working?'),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Restart Router',
                onTap: () => _confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
            ),
            const AppGap.small2(),
            AppFilledButton('Problem solved',
                onTap: widget.onDone),
          ],
        )),

      ];

  List<Widget> _step1Connected(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('What\'s happening?'),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('It keeps dropping off WiFi',
                onTap: () {
                  setState(() => _connectIssue = _ConnectIssue.keepsDropping);
                  _pushStep(2);
                },
                icon: LinksysIcons.networkCheck),
            ),
            const AppGap.small2(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('It\'s connected but internet is slow on this device',
                onTap: () {
                  setState(() => _connectIssue = _ConnectIssue.slowOnDevice);
                  _pushStep(2); // Will redirect to slow-device advice
                },
                icon: LinksysIcons.networkCheck),
            ),
            const AppGap.small2(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Something else',
                onTap: () {
                  setState(() => _connectIssue = _ConnectIssue.other);
                  _pushStep(3);
                },
                icon: LinksysIcons.help),
            ),
          ],
        )),
      ];

  /// Device-specific slow internet path — checks signal, band, node backhaul.
  List<Widget> _slowDevicePath(BuildContext context, InstantVerifyPivotState state) {
    return [
      if (_selectedDevice == null)
        // ── No device selected — show inline picker ──────────────────────
        _devicePickerCard(context, state)
      else
        // ── Device known — show specific analysis ─────────────────────────
        ..._deviceAnalysisCards(context, state, _selectedDevice!),
    ];
  }

  /// Inline device picker — replaces "Go to My Devices" to avoid the loop.
  Widget _devicePickerCard(BuildContext context, InstantVerifyPivotState state) {
    final colors = Theme.of(context).colorScheme;
    final clients = state.clients.where((c) => c.isWireless).toList();
    final isLoading = state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading;

    // Auto-fetch if data hasn't been loaded yet — don't require user to go back
    if (state.phase == PivotLoadPhase.idle && clients.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(instantVerifyPivotProvider.notifier).fetch();
      });
    }

    return _stepCard(context, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserStepHeading('Which device is slow?'),
        const AppGap.small1(),
        AppText.bodySmall('Select it to get specific advice based on its signal and connection.',
            color: colors.onSurfaceVariant),
        const AppGap.small3(),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (clients.isEmpty)
          AppText.bodySmall('No wireless devices detected. Only wired devices are connected, or your router didn\'t report any wireless clients.',
              color: colors.onSurfaceVariant)
        else
          for (final c in clients)
            InkWell(
              onTap: () => setState(() => _selectedDevice = c),
              borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Icon(LinksysIcons.devices, size: 18, color: colors.onSurfaceVariant),
                  const AppGap.small3(),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppText.bodySmall(c.displayNameWithOui),
                      AppText.bodySmall(
                        '${c.band}${c.signalDecibels != null ? "  ·  ${c.signalDecibels} dBm" : ""}',
                        color: colors.onSurfaceVariant,
                      ),
                    ]),
                  ),
                  Icon(LinksysIcons.chevronRight, size: 18, color: colors.outlineVariant),
                ]),
              ),
            ),
      ],
    ));
  }

  /// Device-specific analysis — uses live signal/band/rate/node data.
  List<Widget> _deviceAnalysisCards(
      BuildContext context, InstantVerifyPivotState state, DiagnosticClient device) {
    final colors = Theme.of(context).colorScheme;
    final signal = device.signalDecibels;
    final band = device.band;
    final txRate = device.txRateMbps;

    // Find which mesh node this device is on
    final nodeId = state.clientToNodeId[device.macAddress];
    final node = nodeId != null
        ? state.meshNodes.cast<MeshNodeInfo?>().firstWhere(
            (n) => n?.deviceId == nodeId, orElse: () => null)
        : null;

    // ── Build ranked findings ─────────────────────────────────────────────
    final findings = <_SlowDeviceFinding>[];

    // 1. Weak signal
    if (signal != null && signal < -75) {
      final critical = signal < -82;
      findings.add(_SlowDeviceFinding(
        icon: LinksysIcons.signalWifiOff,
        color: (critical ? InstantTestTone.problem : InstantTestTone.warning)
            .color(context),
        title: critical ? 'Very weak signal ($signal dBm)' : 'Weak signal ($signal dBm)',
        detail: critical
            ? 'Signal is barely enough to stay connected. Move the device much closer '
              'to your router or the nearest mesh node.'
            : 'Weak signal is the most likely cause of slowness. '
              'Moving closer to your router or a mesh node should help significantly.',
        fix: 'Move closer to your router or a mesh node',
      ));
    }

    // 2. Stuck on 2.4 GHz when capable of 5 GHz
    if (band.contains('2.4') && txRate != null && txRate > 80) {
      findings.add(_SlowDeviceFinding(
        icon: LinksysIcons.wifi,
        color: InstantTestTone.warning.color(context),
        title: 'On slower 2.4 GHz — capable of 5 GHz',
        detail: 'This device has a fast link rate (${txRate}Mbps) so it\'s likely '
            '5 GHz capable, but it\'s on the slower 2.4 GHz band. '
            'Forget the WiFi network and reconnect — it should join 5 GHz.',
        fix: 'Forget WiFi and reconnect to join the 5 GHz band',
      ));
    } else if (band.contains('2.4') && (signal == null || signal >= -75)) {
      findings.add(_SlowDeviceFinding(
        icon: LinksysIcons.wifi,
        color: InstantTestTone.warning.color(context),
        title: 'On 2.4 GHz (slower band)',
        detail: 'The 2.4 GHz band is slower than 5 GHz. '
            'If your router broadcasts a separate 5 GHz network, '
            'try connecting to that instead.',
        fix: 'Connect to the 5 GHz network if available',
      ));
    }

    // 3. Connected through weak backhaul node
    if (node != null && !node.isController) {
      final health = node.backhaulHealth;
      if (health == BackhaulHealth.weak || health == BackhaulHealth.critical) {
        final speed = node.backhaulSpeedMbps;
        findings.add(_SlowDeviceFinding(
          icon: LinksysIcons.networkNode,
          color: InstantTestTone.warning.color(context),
          title: 'Connected through ${node.name} — weak backhaul',
          detail: 'The mesh node this device uses has a slow connection back to '
              'the main router${speed != null ? " ($speed Mbps)" : ""}. '
              'The bottleneck is in the backhaul, not this device. '
              'Move ${node.name} closer to the main router, or connect it '
              'with an Ethernet cable.',
          fix: 'Move ${node.name} closer to the main router or use Ethernet',
        ));
      }
    }

    // 4. Low link rate for the band (5 GHz should be 100+, 2.4 GHz should be 30+)
    if (txRate != null && (signal == null || signal >= -75)) {
      final threshold = band.contains('5') ? 100 : 30;
      if (txRate < threshold) {
        findings.add(_SlowDeviceFinding(
          icon: LinksysIcons.networkCheck,
          color: InstantTestTone.warning.color(context),
          title: 'Slow link rate for ${band.contains('5') ? '5 GHz' : '2.4 GHz'} ($txRate Mbps)',
          detail: 'This device is connected at $txRate Mbps — much lower than '
              'expected for ${band.contains('5') ? '5 GHz (typically 400–1200 Mbps)' : '2.4 GHz (typically 50–150 Mbps)'}. '
              'This can be caused by interference, distance, or an older WiFi chip.',
          fix: 'Try restarting the device or moving it closer to the router',
        ));
      }
    }

    // 5. No issues found from router's perspective
    final hasIssues = findings.isNotEmpty;

    return [
      // Device summary header
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LinksysIcons.devices, size: 18, color: colors.primary),
            const AppGap.small2(),
            Expanded(
              child: AppText.labelLarge(widget.singlePage ? 'Connection check' : device.displayNameWithOui),
            ),
            if (!widget.singlePage) AppTextButton('Switch Device',
              onTap: () => setState(() => _selectedDevice = null),
            ),
          ]),
          const AppGap.small3(),
          AppText.bodyMedium(signal == null ? 'Signal information is unavailable.'
              : '${_signalLabel(signal, includeReading: false)} WiFi signal'),
          DetailsDisclosure(key: ValueKey(device.macAddress), label: 'Connection details', child: Column(children: [
          _deviceMetaRow(context, colors, label: 'Band', value: band),
          if (signal != null)
            _deviceMetaRow(context, colors,
                label: 'Signal', value: _signalLabel(signal)),
          if (txRate != null)
            _deviceMetaRow(context, colors,
                label: 'Link rate', value: _linkRateLabel(txRate)),
          if (node != null)
            _deviceMetaRow(context, colors,
                label: 'Connected to',
                value: node.isController ? 'Main router' : node.name),
          ])),
        ],
      )),

      // Findings
      if (!hasIssues)
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LinksysIcons.checkCircle,
                color: InstantTestTone.good.color(context), size: 18),
            const AppGap.small2(),
            const Expanded(child: AppText.labelMedium('No issue found in the available checks')),
          ]),
          const AppGap.small3(),
          DetailsDisclosure(label: 'What we checked', child: Column(children: [
          // Speed test result
          if (state.speedTest != null) ...[
            _allClearDataRow(context, colors,
              icon: LinksysIcons.networkCheck,
              label: 'Internet speed',
              value: '${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps down · '
                     '${state.speedTest!.uploadMbps.toStringAsFixed(0)} Mbps up',
              note: state.speedTest!.downloadMbps < 25
                  ? 'Speed is low — this may be an ISP issue, not your device. '
                    'Contact your internet provider if this is consistently slow.'
                  : 'Speed looks fine — the issue is likely on the device itself.',
            ),
            Divider(height: 20, color: colors.outlineVariant),
          ],
          // Active device count
          if (state.clients.isNotEmpty) ...[
            _allClearDataRow(context, colors,
              icon: LinksysIcons.devices,
              label: 'Devices active',
              value: '${state.clients.length} device${state.clients.length == 1 ? '' : 's'} connected',
              note: state.clients.length > 10
                  ? 'Many devices are connected. Heavy activity on other devices '
                    '(streaming, downloads) can reduce speed for everyone.'
                  : 'Device count is normal — network congestion is unlikely.',
            ),
            Divider(height: 20, color: colors.outlineVariant),
          ],
          // Band distribution
          if (state.wirelessDeviceCount > 0) ...[
            _allClearDataRow(context, colors,
              icon: LinksysIcons.wifi,
              label: 'Band distribution',
              value: '${state.twoPointFourGhzCount} on 2.4 GHz · '
                     '${state.fiveGhzCount} on 5 GHz',
              note: 'If other devices are on 2.4 GHz and streaming, they may be '
                    'competing for bandwidth with this device.',
            ),
          ],
          ])),
          const AppGap.small3(),
          AppText.bodySmall(
            'If the device still feels slow, try closing background apps and '
            'running a speed test directly on that device.',
            color: colors.onSurfaceVariant,
          ),
        ]))
      else ...[
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const UserStepHeading('Try this first'),
          const AppGap.small3(),
          AppText.bodyLarge(findings.first.fix),
          DetailsDisclosure(label: 'Why this might help', child: AppText.bodyMedium(findings.first.detail)),
          if (findings.length > 1)
            DetailsDisclosure(label: 'More things to try', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final f in findings.skip(1)) ...[
                AppText.titleSmall(f.fix),
                AppText.bodyMedium(f.detail),
                const AppGap.small3(),
              ]],
            )),
        ])),
      ],

    ];
  }

  Widget _allClearDataRow(BuildContext context, ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
    required String note,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const AppGap.small1(),
        AppText.bodySmall(label, color: colors.onSurfaceVariant),
        const Spacer(),
        AppText.labelMedium(value, color: colors.onSurface),
      ]),
      const AppGap.small1(),
      AppText.bodySmall(note, color: colors.onSurfaceVariant),
    ]);
  }

  /// Labeled device-attribute row: "Label" left, value right. Replaces the
  /// old unlabeled chips so each value is self-explanatory.
  Widget _deviceMetaRow(BuildContext context, ColorScheme colors,
      {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: AppText.bodySmall(label, color: colors.onSurfaceVariant),
          ),
          Expanded(
            child: AppText.bodySmall(value, color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  /// Customer-friendly signal description with the dBm in parentheses.
  String _signalLabel(int dBm, {bool includeReading = true}) {
    final quality = dBm >= -60
        ? 'Strong'
        : dBm >= -70
            ? 'Good'
            : dBm >= -75
                ? 'Weak'
                : 'Very weak';
    return includeReading ? '$quality ($dBm dBm)' : quality;
  }

  /// Format a link rate (Mbps) cleanly — promotes to Gbps at >= 1000.
  String _linkRateLabel(int mbps) {
    if (mbps >= 1000) {
      final gbps = mbps / 1000;
      // Trim trailing .0 (e.g. "1 Gbps" not "1.0 Gbps")
      final s = gbps.toStringAsFixed(1);
      return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s} Gbps';
    }
    return '$mbps Mbps';
  }

  List<Widget> _keepsDroppingFlow(BuildContext context, InstantVerifyPivotState state) {
    // Find any weak-signal devices in the current client list
    final weakDevices = state.issueDevices;
    final hasChannelData = state.channelInfo != null;

    // Detect unified SSID (same name on all bands → user can't manually switch)
    final radios = state.radioInfo?['radios'] as List? ?? [];
    final ssids = radios
        .map((r) => ((r as Map<String, dynamic>)['settings']
            as Map<String, dynamic>?)?['ssid'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .toSet();
    final isUnifiedSsid = ssids.length <= 1;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Device keeps dropping WiFi'),
          const AppGap.small2(),
          AppText.bodySmall('Try a step, then check whether the connection improves.',
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const AppGap.small3(),
          GuidedSteps(steps: [
            'Move the device closer to your router or a child node',
            if (!isUnifiedSsid) 'Try your other WiFi network if your router has separate network names.',
            'Forget this WiFi network on the device, then reconnect fresh. Have your WiFi password ready.',
            'Check if other devices also drop — if yes, try restarting your router',
          ]),
          if (weakDevices.isNotEmpty) ...[
            const AppGap.small2(),
            _infoBox(context,
                '${weakDevices.length} device${weakDevices.length == 1 ? "" : "s"} on your network '
                '${weakDevices.length == 1 ? "has" : "have"} a weak WiFi signal right now. '
                'Weak signal causes drops even when the device appears connected.',
                icon: LinksysIcons.signalWifi0Bar,
                color: InstantTestTone.warning.color(context)),
          ],
        ],
      )),

      // Active actions — things the tool can do right now
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Things we can try from here'),
          const AppGap.small3(),

          // Force reconnect — deauthenticates the device so it re-associates fresh
          Builder(builder: (ctx) {
            final hasDevices = state.phase == PivotLoadPhase.jnapLoaded ||
                state.phase == PivotLoadPhase.complete;
            final wirelessCount = state.clients.where((c) => c.isWireless).length;
            final enabled = hasDevices && wirelessCount > 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppOutlinedButton('Force reconnect a device',
                onTap: enabled ? () => _showDeauthPicker(ctx, state) : null,
                icon: LinksysIcons.signalWifiOff),
                const AppGap.small1(),
                AppText.bodySmall(
                  !hasDevices
                      ? 'Loading device list…'
                      : wirelessCount == 0
                          ? 'No wireless devices detected on your network.'
                          : 'Disconnects the device from WiFi for a moment — it reconnects fresh, '
                            'which often clears a dropping connection.',
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ],
            );
          }),

          if (hasChannelData) ...[
            const AppGap.small3(),
            AppOutlinedButton('Optimize my WiFi channels',
                onTap: () => _optimizeChannels(context),
                icon: LinksysIcons.wifi),
            const AppGap.small1(),
            AppText.bodySmall(
              'Interference from nearby networks can cause drops. Your router '
              'will scan for the clearest channels and switch automatically — '
              'this takes about a minute.',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],

          const AppGap.small3(),
          AppOutlinedButton('Restart Router',
                onTap: () => _confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
          const AppGap.small2(),
          AppFilledButton('Device stopped dropping',
                onTap: widget.onDone),
        ],
      )),
      const _SatisfactionPrompt(),

    ];
  }

  /// Show a picker of wireless devices, then deauth the selected one.
  /// If we already have a device context (e.g. from My Devices → Troubleshoot),
  /// skip the picker and deauth that device directly.
  void _showDeauthPicker(BuildContext context, InstantVerifyPivotState state) {
    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText.bodyMedium('Still loading devices — please wait a moment and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final wirelessClients = state.clients.where((c) => c.isWireless).toList();
    if (wirelessClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText.bodyMedium('No wireless devices found in the device list.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If we arrived with a specific device context, use it directly.
    if (_selectedDevice != null && _selectedDevice!.isWireless) {
      _doDeauth(context, _selectedDevice!.macAddress, _selectedDevice!.displayNameWithOui);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: CustomTheme.of(context).radius.large)),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('Which device is dropping?'),
            const AppGap.small3(),
            ...wirelessClients.map((c) => ListTile(
                  leading: const Icon(LinksysIcons.smartPhone),
                  title: AppText.bodyMedium(c.displayNameWithOui),
                  subtitle: AppText.bodySmall('${c.band} · ${c.signalDecibels ?? "??"} dBm'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    _doDeauth(context, c.macAddress, c.displayNameWithOui);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _doDeauth(BuildContext context, String mac, String name) =>
      confirmAndDeauth(context, ref, mac: mac, displayName: name);

  /// Run the router's real auto channel optimization (firmware RF scan picks
  /// the genuinely clearest channels — replaces the old hardcoded 6/36
  /// suggestion). Shows a ~1-minute progress dialog, then the result with a
  /// subtle before→after for the curious.
  Future<void> _optimizeChannels(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const AppText.titleLarge('Optimize WiFi channels?'),
        content: const AppText.bodyMedium(
          'Your router will scan for clearer channels and switch automatically. '
          'This may briefly disconnect devices or cause a short slowdown '
          'while the change takes effect.'),
        actions: [
          AppTextButton('Cancel',
                onTap: () => Navigator.of(dlg).pop(false)),
          AppFilledButton('Optimize',
                onTap: () => Navigator.of(dlg).pop(true)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Non-dismissible progress dialog while the router scans.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlg) => const AlertDialog(
        content: Row(children: [
          SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
          AppGap.medium(),
          Expanded(
            child: AppText.bodyMedium(
                'Scanning for the clearest WiFi channels…\nThis takes about a minute.'),
          ),
        ]),
      ),
    );

    final result =
        await ref.read(instantVerifyPivotProvider.notifier).optimizeChannels();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress
    if (!context.mounted) return;

    final (title, body) = switch (result.status) {
      ChannelOptimizeStatus.optimized => (
          'Your WiFi channels are tuned',
          'We moved your WiFi to clearer channels to reduce interference.'
              '${result.changes.isNotEmpty ? '\n\n${result.changes.map((c) => '• ${c.band}: channel ${c.from} → ${c.to}').join('\n')}' : ''}'
        ),
      ChannelOptimizeStatus.alreadyOptimal => (
          'Already on the best channels',
          'Your WiFi is already using the clearest channels available — no change needed.'
        ),
      ChannelOptimizeStatus.error => (
          'Couldn\'t optimize right now',
          'We couldn\'t finish the channel scan. Please try again in a moment.'
        ),
    };

    await showDialog<void>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: AppText.titleLarge(title),
        content: AppText.bodyMedium(body),
        actions: [
          AppFilledButton('Done',
                onTap: () => Navigator.of(dlg).pop()),
        ],
      ),
    );
  }

  // ── SSID not visible — smart diagnostic using live router data ──────────────
  Widget _ssidNotVisibleCard(BuildContext context, WidgetRef ref, InstantVerifyPivotState state) {
    final colors = Theme.of(context).colorScheme;
    final radios = state.radioInfo?['radios'] as List? ?? [];

    // ── Parse live radio state ─────────────────────────────────────────────
    // Bands confirmed active on this router
    final activeBands = <String>[];
    final disabledBands = <String>[];
    bool? hiddenSsid;
    for (final r in radios) {
      final band = (r as Map<String, dynamic>)['band'] as String? ?? '';
      if (band.isEmpty) continue;
      final settings = r['settings'] as Map<String, dynamic>? ?? {};
      final isEnabled = settings['isEnabled'] as bool? ?? settings['enabled'] as bool?;
      if (isEnabled == false) {
        disabledBands.add(band);
      } else {
        activeBands.add(band);
      }
      // broadcastSsid: false means the network is hidden
      final broadcast = settings['broadcastSsid'] as bool? ?? settings['isBroadcastEnabled'] as bool?;
      if (broadcast == false) hiddenSsid = true;
    }
    final hasRadioData = radios.isNotEmpty;

    // ── Channel data ───────────────────────────────────────────────────────
    // DFS channels on 5 GHz: 52–64 and 100–140. Some older devices and drivers
    // can't see or join DFS channels while radar detection is active.
    final dfsChannels = <String>[];
    final channelList = (state.channelInfo?['selectedChannels'] as List? ?? []);
    if (channelList.isNotEmpty) {
      final channels = (channelList.first as Map<String, dynamic>?)?['channels'] as List? ?? [];
      for (final ch in channels) {
        final band = (ch as Map<String, dynamic>)['band'] as String? ?? '';
        final num = int.tryParse(ch['channel']?.toString() ?? '') ?? 0;
        if (band.contains('5') && ((num >= 52 && num <= 64) || (num >= 100 && num <= 140))) {
          dfsChannels.add('5 GHz ch $num');
        }
      }
    }

    // ── Security ───────────────────────────────────────────────────────────
    final wpa3Only = state.isWpa3Only;

    // ── WiFi schedule ──────────────────────────────────────────────────────
    final scheduleBlocking = state.wirelessSchedule != null &&
        (state.wirelessSchedule!['isEnabled'] as bool? ?? false);

    // ── Build findings list ────────────────────────────────────────────────
    final findings = <_SsidFinding>[];

    if (scheduleBlocking) {
      findings.add(_SsidFinding(
        icon: LinksysIcons.uptime,
        tone: InstantTestTone.warning,
        title: 'WiFi schedule is active',
        detail: 'Your router has a schedule that turns off WiFi at certain times. '
            'Check your schedule settings — WiFi may be turned off right now.',
        isBlocker: true,
      ));
    }

    if (disabledBands.isNotEmpty) {
      findings.add(_SsidFinding(
        icon: LinksysIcons.signalWifiOff,
        tone: InstantTestTone.problem,
        title: '${disabledBands.join(' and ')} radio is turned off',
        detail: 'The ${disabledBands.join('/')} band is disabled in your router settings. '
            'Enable it under WiFi settings.',
        isBlocker: true,
      ));
    }

    if (hiddenSsid == true) {
      findings.add(_SsidFinding(
        icon: LinksysIcons.visibilityOff,
        tone: InstantTestTone.warning,
        title: 'Network name is hidden (SSID broadcast off)',
        detail: 'Your router is not broadcasting the network name. '
            'Devices need to be configured manually to join a hidden network, '
            'or you can turn SSID broadcast back on in WiFi settings.',
        isBlocker: true,
      ));
    }

    if (wpa3Only) {
      findings.add(_SsidFinding(
        icon: LinksysIcons.encrypted,
        tone: InstantTestTone.warning,
        title: 'WPA3-only security — older devices can\'t connect',
        detail: 'Devices made before 2019 (and many smart home devices) don\'t '
            'support WPA3. Switch to WPA2/WPA3 mixed mode in your WiFi Security settings.',
        isBlocker: false,
      ));
    }

    if (dfsChannels.isNotEmpty) {
      findings.add(_SsidFinding(
        icon: LinksysIcons.networkCheck,
        tone: InstantTestTone.info,
        title: 'Operating on DFS channel (${dfsChannels.join(', ')})',
        detail: 'DFS channels are shared with radar systems. Some older laptops, '
            'phones, and smart home devices can\'t see or connect to DFS channels. '
            'Switching to a non-DFS channel (36, 40, 44, or 48) may help.',
        isBlocker: false,
      ));
    }

    // What bands does this router support?
    final allBands = {...activeBands, ...disabledBands}.toList();
    final has6Ghz = allBands.any((b) => b.contains('6'));
    final has5Ghz = allBands.any((b) => b.contains('5') && !b.contains('6'));
    final has24Ghz = allBands.any((b) => b.contains('2.4'));

    return _stepCard(context, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.titleSmall('We checked your router\'s WiFi — here\'s what we found'),
        const AppGap.small2(),

        DetailsDisclosure(label: 'WiFi radio details', child: Column(children: [
        // Bands summary
        if (hasRadioData) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorSchemeExt.surfaceContainerLow!,
              borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium('WiFi radios — actively broadcasting:',
                    color: colors.onSurfaceVariant),
                const AppGap.small1(),
                if (has24Ghz)
                  _radioStatusRow(context, '2.4 GHz', disabledBands.any((b) => b.contains('2.4'))),
                if (has5Ghz)
                  _radioStatusRow(context, '5 GHz', disabledBands.any((b) => b.contains('5') && !b.contains('6'))),
                if (has6Ghz)
                  _radioStatusRow(context, '6 GHz', disabledBands.any((b) => b.contains('6'))),
                if (!has24Ghz && !has5Ghz && !has6Ghz)
                  AppText.bodySmall('Radio data not available',
                      color: colors.onSurfaceVariant),
              ],
            ),
          ),
          const AppGap.small3(),
        ],

        ])),

        // Findings
        if (findings.isEmpty) ...[
          _infoBox(context,
              hasRadioData
                  ? 'Your router\'s WiFi radios are active and broadcasting. '
                    'If your device still doesn\'t see the network, try:\n'
                    '  • Moving your device closer to the router or a mesh node\n'
                    '  • Turning WiFi off and back on on the device\n'
                    '  • Forgetting and re-scanning for networks'
                  : 'We didn\'t detect an obvious cause. Try moving your device closer to '
                    'the router, then check again. A router restart often helps.'),
          const AppGap.small3(),
        ] else ...[
          for (final f in findings) ...[
            _ssidFindingTile(context, f),
            const AppGap.small2(),
          ],
        ],

        // Note about device compatibility
        if (has6Ghz) ...[
          _infoBox(context,
              '6 GHz WiFi (WiFi 6E/7) requires a compatible device — most phones and '
              'laptops from 2021 or earlier won\'t see the 6 GHz network at all. '
              'Check if your device supports WiFi 6E.',
              icon: LinksysIcons.infoCircle),
          const AppGap.small3(),
        ],

        // Restart action
        Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Restart Router',
                onTap: () => _confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
        ),
        const AppGap.small2(),
        Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Back',
                onTap: () => setState(() => _canSeeSsid = null)),
        ),
      ],
    ));
  }

  Widget _radioStatusRow(BuildContext context, String band, bool disabled) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(
          disabled ? LinksysIcons.close : LinksysIcons.checkCircle,
          size: 14,
          color: (disabled ? InstantTestTone.problem : InstantTestTone.good)
              .color(context),
        ),
        const AppGap.small1(),
        AppText.bodySmall(band),
        const AppGap.small1(),
        AppText.bodySmall(disabled ? 'Disabled' : 'Active',
            color: (disabled ? InstantTestTone.problem : InstantTestTone.good)
                .color(context)),
      ]),
    );
  }

  Widget _ssidFindingTile(BuildContext context, _SsidFinding f) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: f.tone.container(context),
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
        border: Border.all(color: f.tone.color(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(f.icon, size: 18, color: f.tone.onContainer(context)),
          const AppGap.small3(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(f.title,
                    color: f.tone.onContainer(context)),
                const AppGap.small1(),
                AppText.bodySmall(f.detail,
                    color: f.tone.onContainer(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── end SSID not visible ──────────────────────────────────────────────────

  List<Widget> _step1CantConnect(BuildContext context) {
    // Step 1a (Item 12): Ask if the customer can see the SSID before showing credentials.
    // Use the actual SSID name so the question is specific, not generic.
    final state = ref.watch(instantVerifyPivotProvider);
    final ssid = state.wifiSsid;
    final ssidLabel = ssid != null ? '"$ssid"' : 'your network name';

    if (widget.singlePage) {
      return [
        _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UserStepHeading('Check the WiFi network name'),
          const AppGap.small3(),
          AppText.bodyLarge('Can you see $ssidLabel in your device\'s WiFi list?'),
          const AppGap.medium(),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const AppText.bodyMedium('Yes — I can see it'), selected: _canSeeSsid == true,
                onSelected: (_) => setState(() => _canSeeSsid = true)),
            ChoiceChip(label: const AppText.bodyMedium('No — I don\'t see it'), selected: _canSeeSsid == false,
                onSelected: (_) => setState(() => _canSeeSsid = false)),
          ]),
        ])),
        if (_canSeeSsid == false) _ssidNotVisibleCard(context, ref, state)
        else if (_canSeeSsid == true) ..._pathA(context, state),
      ];
    }

    if (_canSeeSsid == null) {
      return [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall('Can you see $ssidLabel in your device\'s WiFi list?'),
            const AppGap.small2(),
            AppText.bodySmall(
              'Open your device\'s WiFi settings and look for the network name above.',
              selectable: true,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Yes — I can see it',
                onTap: () => setState(() => _canSeeSsid = true)),
            ),
            const AppGap.small2(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('No — I don\'t see it',
                onTap: () => setState(() => _canSeeSsid = false)),
            ),
          ],
        )),
      ];
    }

    // Customer can't see the SSID at all — smart diagnostic using live router data
    if (_canSeeSsid == false) {
      return [_ssidNotVisibleCard(context, ref, state)];
    }

    // Customer CAN see the SSID — show combined connection help (no device type needed)
    return _pathA(context, state);
  }

  /// "Something else" path — device is connected but issue doesn't fit other categories.
  /// Shows general troubleshooting steps + support escalation.
  List<Widget> _pathOther(BuildContext context, InstantVerifyPivotState state) {
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('General troubleshooting'),
          const AppGap.small2(),
          const AppText.bodyMedium(
            'Your device is connected but something doesn\'t seem right. '
            'Try these general steps:',
          ),
          const AppGap.small3(),
          const GuidedSteps(steps: [
            'Restart the affected device (phone, laptop, etc.)',
            'Forget this WiFi network on the device and reconnect. Have your WiFi password ready.',
            'Check if the problem happens on other devices too',
            'Try opening a website in a private/incognito window',
          ]),
        ],
      )),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('If those didn\'t help'),
          const AppGap.small3(),
          Align(
              alignment: Alignment.centerLeft,
              child: AppOutlinedButton('Restart Router',
                onTap: () => _confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
          ),
        ],
      )),

    ];
  }

  List<Widget> _pathA(BuildContext context, InstantVerifyPivotState state) {
    final ssid = state.wifiSsid ?? '(see router settings)';
    final password = state.wifiPassword ?? '(see router settings)';
    final macActive = state.isMacFilterEnabled && !_macFilterDisabled;
    final wpa3Only = state.isWpa3Only;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Check your WiFi details'),
          const AppGap.small3(),
          _wifiCredRow(context, 'Network name', ssid),
          const AppGap.small1(),
          _wifiCredRow(context, 'Password', password),
          const AppGap.small3(),
          GuidedSteps(steps: [
              'Make sure you\'re selecting the exact network name shown above',
              'Check that caps lock is off when entering the password',
              'Try forgetting the network on your device and reconnecting',
              'If your router has separate 2.4 GHz and 5 GHz networks, try the 2.4 GHz one — some devices only support it',
            ]),
        ],
      )),
      if (wpa3Only)
        _stepCard(context, _infoBox(context,
            'Your router is set to WPA3-only security. '
            'Older devices (phones before 2019, many smart home devices) can\'t connect with this setting. '
            'Choose Back to router home, open Incredible-WiFi, and check whether WPA2/WPA3 compatibility is available.')),
      if (macActive)
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBox(
              context,
              'Your router has a device blocklist turned on.\n\nThis controls which devices can connect — it may be blocking this device.\n\nTurning it off lets any device join using your WiFi password. Your password is still required.',
            ),
            const AppGap.small3(),
            Row(children: [
              Expanded(
                child: _isDisablingMacFilter
                    ? const _LoadingButton(label: 'Turning off…')
                    : AppFilledButton('Turn off blocklist',
                onTap: _disableMacFilter),
              ),
              const AppGap.small2(),
              Expanded(
                child: AppOutlinedButton('Leave it on',
                onTap: () {}),
              ),
            ]),
          ],
        )),
      if (_macFilterDisabled)
        _infoBox(context, 'Device blocklist turned off. Try connecting again.',
            icon: LinksysIcons.checkCircle,
            color: InstantTestTone.good.color(context)),
      const AppGap.small2(),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Still not connecting?'),
          const AppGap.small2(),
          const AppText.bodyMedium(
            'If the steps above haven\'t worked, restarting your router often '
            'fixes connection issues that nothing else does.',
          ),
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
              child: AppFilledButton('Device is connected now',
                onTap: widget.onDone),
          ),
        ],
      )),
      const _SatisfactionPrompt(),

    ];
  }

  List<Widget> _pathB(BuildContext context, InstantVerifyPivotState state) {
    final ssid = state.wifiSsid ?? '(see router settings)';
    final password = state.wifiPassword ?? '(see router settings)';
    final wpa3Only = state.isWpa3Only;

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Connect your smart home device'),
          const AppGap.small3(),
          GuidedSteps(steps: [
              'Make sure your phone is on the same WiFi network you want the device on — not a guest network',
              'Use the 2.4 GHz network if your router has separate names for 2.4 and 5 GHz',
            ]),
          const AppGap.small2(),
          _wifiCredRow(context, 'Network name', ssid),
          const AppGap.small1(),
          _wifiCredRow(context, 'Password', password),
        ],
      )),
      if (wpa3Only)
        _stepCard(context,
            _infoBox(
              context,
              'Some older smart home devices don\'t support the latest WiFi security standard. If this device keeps failing:\n\nChoose Back to router home, open Incredible-WiFi, and check whether WPA2 compatibility is available.',
            )),
      const AppGap.small2(),
      Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Device is connected now',
                onTap: widget.onDone),
      ),

    ];
  }

  Widget _wifiCredRow(BuildContext context, String label, String value) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: AppText.bodyMedium(label,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Expanded(
            child: AppText.labelLarge(value, selectable: true),
          ),
        ],
      );

  Future<void> _disableMacFilter() async {
    setState(() => _isDisablingMacFilter = true);
    await ref.read(instantVerifyPivotProvider.notifier).disableMacFilter();
    setState(() {
      _isDisablingMacFilter = false;
      _macFilterDisabled = true;
    });
  }
}

// ── Data class for SSID-not-visible findings ─────────────────────────────────

class _SlowDeviceFinding {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String fix; // short actionable fix shown in the colored pill
  const _SlowDeviceFinding({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.fix,
  });
}

class _SsidFinding {
  final IconData icon;
  final InstantTestTone tone;
  final String title;
  final String detail;
  final bool isBlocker;
  const _SsidFinding({
    required this.icon,
    required this.tone,
    required this.title,
    required this.detail,
    required this.isBlocker,
  });
}
