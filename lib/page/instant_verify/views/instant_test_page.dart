import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'instant_test_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/views/my_devices_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';

/// Customer diagnostics and guided help share one home and one return path.
/// Uses the caller's existing authenticated session, or a preview override.
class InstantTestPage extends ConsumerStatefulWidget {
  const InstantTestPage({super.key});

  @override
  ConsumerState<InstantTestPage> createState() => _InstantTestPageState();
}

class _InstantTestPageState extends ConsumerState<InstantTestPage> {
  List<int> _flowPath = [];
  bool get _showFlow => _flowPath.isNotEmpty;
  GoRouter? _router;
  String? _routePath;
  int? _details;
  final _pendingDevice = ValueNotifier<DiagnosticClient?>(null);

  static const symptoms = <(int, IconData, String)>[
    (1, Icons.wifi_off, "Internet isn't working"),
    (2, Icons.speed, 'Whole internet is slow'),
    (31, Icons.devices, 'One device is slow'),
    (3, Icons.device_unknown, "Device won't connect"),
    (4, Icons.meeting_room_outlined, "Doesn't reach a room"),
    (5, Icons.sync_problem, 'Keeps cutting out'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(instantVerifyPivotProvider.notifier).fetch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == _router) return;
    _router?.routeInformationProvider.removeListener(_readRoute);
    _router = router;
    _routePath = router?.routeInformationProvider.value.uri.path;
    router?.routeInformationProvider.addListener(_readRoute);
    _readRoute();
  }

  void _readRoute() {
    final uri = _router?.routeInformationProvider.value.uri;
    if (uri == null || uri.path != _routePath || !mounted) return;
    final location = InstantTestLocation.parse(uri.queryParameters['instant']);
    if (location.value ==
        InstantTestLocation(details: _details, flows: _flowPath).value) return;
    // Query navigation keeps the page's Navigator route mounted. Its popup
    // routes must not outlive the workflow that requested confirmation.
    final navigator = Navigator.of(context, rootNavigator: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) navigator.popUntil((route) => route is! PopupRoute);
    });
    setState(() {
      _details = location.details;
      _flowPath = location.flows;
    });
  }

  void _navigate({int? details, List<int> flows = const []}) {
    final location = InstantTestLocation(details: details, flows: flows);
    setState(() {
      _details = details;
      _flowPath = List.of(flows);
    });
    final router = _router;
    if (router == null) return; // Embedded widget/test without a route host.
    final uri = router.routeInformationProvider.value.uri;
    final query = Map<String, String>.of(uri.queryParameters)
      ..remove('instant');
    if (location.value.isNotEmpty) query['instant'] = location.value;
    router.go(uri.replace(queryParameters: query).toString());
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_readRoute);
    _pendingDevice.dispose();
    super.dispose();
  }

  void _launch(int flow, {DiagnosticClient? device}) {
    _pendingDevice.value = device;
    _navigate(details: _details, flows: [flow]);
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
      child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_showFlow && _details == null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (id, icon, label) in symptoms)
                            OutlinedButton.icon(
                              onPressed: () => _launch(id),
                              icon: Icon(icon, size: 20),
                              label: Text(label),
                            ),
                        ],
                      ),
                    ),
                  if (!_showFlow && _details == null)
                    Wrap(spacing: 8, children: [
                      TextButton(
                          onPressed: () => _navigate(details: 1),
                          child: const Text('Device details')),
                      TextButton(
                          onPressed: () => _navigate(details: 2),
                          child: const Text('Network details')),
                    ]),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Offstage(
                          offstage: _showFlow || _details != null,
                          child: ExcludeFocus(
                            excluding: _showFlow || _details != null,
                            child: SelectionArea(
                                child: OverviewTab(
                              showProblemCards: false,
                              onViewClients: () => _navigate(details: 1),
                              onNavigateToFlow: (index) => _launch(index + 1),
                              onTroubleshootWeakDevices: () => _launch(31),
                            )),
                          ),
                        ),
                        if (_details != null)
                          Offstage(
                            offstage: _showFlow,
                            child: ExcludeFocus(
                                excluding: _showFlow,
                                child: SelectionArea(
                                    child: Column(children: [
                                  ListTile(
                                    leading: IconButton(
                                        tooltip: 'Back to Instant-Test',
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () => _navigate()),
                                    title: Text(_details == 1
                                        ? 'Device details'
                                        : 'Network details'),
                                  ),
                                  Expanded(
                                      child: _details == 1
                                          ? MyDevicesTab(
                                              onNavigateToFlow: (flow,
                                                      {device}) =>
                                                  _launch(flow, device: device))
                                          : const MyNetworkTab()),
                                ]))),
                          ),
                        if (_showFlow)
                          Positioned.fill(
                            child: HelpMeFixItTab(
                              flowPath: _flowPath,
                              onFlowPathChanged: (flows) =>
                                  _navigate(details: _details, flows: flows),
                              pendingFlowDeviceNotifier: _pendingDevice,
                              exitLabel: _details == 1
                                  ? 'Back to device details'
                                  : 'Back to Instant-Test',
                              singlePage: true,
                              onCheckAgain: () {
                                _navigate();
                                ref
                                    .read(instantVerifyPivotProvider.notifier)
                                    .fetch();
                              },
                              onExitToHome: () => _navigate(details: _details),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ))));
}
