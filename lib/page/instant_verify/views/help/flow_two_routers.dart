part of 'help_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Flow 6: Two routers / Combo gateway (bridge mode guidance)
//
// Triggered from: Tab 0 "Your network has two routers" verdict finding CTA,
// or Help Me Fix It flow menu.
//
// Topology scenarios handled:
//   A. ISP combo gateway (modem+router) → advise bridge mode or Linksys AP mode
//   B. CGNAT from ISP → advise call ISP for dedicated IP
// ═══════════════════════════════════════════════════════════════════════════

enum _NatOption { bridgeMode, apMode, callIsp, leaveAsIs }

class _Flow6BridgeMode extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final ValueNotifier<String?>? stepIndicatorNotifier;
  const _Flow6BridgeMode({required this.onDone, this.stepBackNotifier, this.stepIndicatorNotifier});

  @override
  ConsumerState<_Flow6BridgeMode> createState() => _Flow6BridgeModeState();
}

class _Flow6BridgeModeState extends ConsumerState<_Flow6BridgeMode> {
  int _step = 0;
  _NatOption? _choice;
  final List<int> _stepHistory = [];

  void _pushStep(int s) {
    setState(() { _stepHistory.add(_step); _step = s; });
    _syncNotifiers();
  }
  void _stepBack() {
    if (_stepHistory.isNotEmpty) setState(() => _step = _stepHistory.removeLast());
    _syncNotifiers();
  }
  void _syncNotifiers() {
    widget.stepBackNotifier?.value = _stepHistory.isNotEmpty ? _stepBack : null;
    widget.stepIndicatorNotifier?.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    final isCgnat = _isCgnatIp(state.wanIpAddress);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(_step),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 0) ..._step0(context, isCgnat),
          if (_step == 1) ..._stepBridgeMode(context),
          if (_step == 2) ..._stepApMode(context),
          if (_step == 3) ..._stepCallIsp(context, isCgnat),
          if (_step == 4) ..._stepLeaveAsIs(context),
        ],
      ),
    );
  }

  bool _isCgnatIp(String? ip) {
    if (ip == null || ip.isEmpty) return false;
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final first = int.tryParse(parts[0]) ?? 0;
    final second = int.tryParse(parts[1]) ?? 0;
    return first == 100 && second >= 64 && second <= 127;
  }

  List<Widget> _step0(BuildContext context, bool isCgnat) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('Two routers detected'),
            const AppGap.small2(),
            if (isCgnat)
              _infoBox(context,
                  'Your internet company is using a shared IP address (Carrier-Grade NAT). '
                  'This is managed by your provider — you can\'t change it on the router.',
                  icon: LinksysIcons.infoCircle)
            else
              _infoBox(context,
                  'Your Linksys router is connected behind another router — '
                  'usually your internet company\'s gateway device. '
                  'This creates a "double router" situation that can cause issues '
                  'with port forwarding, gaming, and VoIP calls. '
                  'Your internet works, but some features are limited.'),
            const AppGap.small3(),
            UserStepHeading('What would you like to do?'),
            const AppGap.small2(),
            if (!isCgnat) ...[
              ListTile(
                leading: const Icon(LinksysIcons.ethernet),
                title: const AppText.bodyMedium('Enable bridge mode on the ISP gateway'),
                subtitle: const AppText.bodySmall('Best option — makes your router the only router'),
                onTap: () => _pushStep(1),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const Divider(height: 12),
              ListTile(
                leading: const Icon(LinksysIcons.wifi),
                title: const AppText.bodyMedium('Switch Linksys to WiFi access point mode'),
                subtitle: const AppText.bodySmall('Good for extending WiFi — ISP gateway handles routing'),
                onTap: () => _pushStep(2),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const Divider(height: 12),
            ],
            ListTile(
              leading: const Icon(LinksysIcons.call),
              title: AppText.bodyMedium(isCgnat
                  ? 'Contact my internet provider for a dedicated IP'
                  : 'Leave it as two routers — contact my internet provider'),
              subtitle: AppText.bodySmall(isCgnat
                  ? 'Required if you need port forwarding or gaming features'
                  : 'If you need port forwarding, gaming, or VoIP to work'),
              onTap: () => _pushStep(3),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (!isCgnat) ...[
              const Divider(height: 12),
              ListTile(
                leading: const Icon(LinksysIcons.checkCircle),
                title: const AppText.bodyMedium('Leave as-is — internet is working fine'),
                subtitle: const AppText.bodySmall('OK if you don\'t need port forwarding'),
                onTap: () => _pushStep(4),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ],
        )),
      ];

  List<Widget> _stepBridgeMode(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Enabling bridge mode'),
            const AppGap.small2(),
            _infoBox(context,
                'Bridge mode turns off the routing features on your internet '
                'company\'s gateway so your Linksys can handle everything. '
                'The steps depend on your internet provider\'s equipment.'),
            const AppGap.small3(),
            GuidedSteps(steps: [
              'Log into your internet company\'s gateway — usually at 192.168.100.1 or printed on the device',
              'Look for settings labelled "Bridge Mode", "IP Passthrough", or "DMZ". The name varies by provider.',
              'If your provider asks for a MAC address, use the internet (WAN) MAC address from your router settings. Ask your provider if you are unsure.',
              'Save and wait 2 minutes — both devices will restart',
              'Run the Instant-Test again to confirm you now have a public IP address',
            ]),
            const AppGap.small3(),
            AppText.bodySmall(
              'Not sure how? Search "[your internet provider] enable bridge mode" '
              '— or call them and say: "I want to put my gateway into bridge mode '
              'so my third-party router handles everything."',
              selectable: true,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
            ),
          ],
        )),
        const _SatisfactionPrompt(),

      ];

  List<Widget> _stepApMode(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Switch Linksys to access point mode'),
            const AppGap.small2(),
            _infoBox(context,
                'In access point mode, your Linksys handles WiFi but your internet '
                'company\'s gateway handles routing. This is simpler than bridge mode '
                'and works well if you just need better WiFi coverage.'),
            const AppGap.small2(),
            _infoBox(context,
                'Note: In AP mode, features like parental controls, device prioritization, '
                'and port forwarding on the Linksys won\'t work — those stay on the ISP gateway.',
                icon: LinksysIcons.error,
                color: InstantTestTone.warning.color(context)),
            const AppGap.small3(),
            GuidedSteps(steps: [
              'Open the Linksys app and go to Router Settings',
              'Look for "Operation Mode" or "Network Mode" and select "Access Point"',
              'Connect the Linksys to your internet company\'s gateway with an Ethernet cable',
              'Your devices will connect to the Linksys WiFi and get internet through the gateway',
            ]),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
            ),
          ],
        )),
        const _SatisfactionPrompt(),

      ];

  List<Widget> _stepCallIsp(BuildContext context, bool isCgnat) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserStepHeading('Contact your internet provider'),
            const AppGap.small2(),
            AppText.bodyMedium(
              isCgnat
                  ? 'Your provider manages the shared IP system — only they can assign you a dedicated public IP.'
                  : 'Your internet provider can help you put their device into bridge mode.',
            ),
            const AppGap.small3(),
            _ispScript(context,
                isCgnat
                    ? 'I have a Linksys router but I\'m getting a shared IP address. I need a public static or dynamic IP to use port forwarding and online gaming. Can you assign me a dedicated IP?'
                    : 'I connected my Linksys router to your gateway and my network has two routers. I\'d like to put your gateway into bridge mode so my Linksys handles everything. Can you walk me through that?'),
            const AppGap.medium(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
            ),
          ],
        )),

      ];

  List<Widget> _stepLeaveAsIs(BuildContext context) => [
        _stepCard(context, Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.titleSmall('Leaving as two routers'),
            const AppGap.small2(),
            _infoBox(context,
                'That\'s fine! Two routers (double-NAT) works for normal browsing, streaming, '
                'and most everyday use. You\'ll only notice issues if you need port '
                'forwarding, host game servers, or use business VoIP.'),
            const AppGap.small3(),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Got it — my internet is working',
                onTap: widget.onDone),
            ),
          ],
        )),
        const _SatisfactionPrompt(),
      ];
}
