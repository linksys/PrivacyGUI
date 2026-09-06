import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/help_me_fix_it_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';

/// Customer diagnostics and guided help share one home and one return path.
/// Uses the caller's existing authenticated session, or a preview override.
class InstantTestPage extends ConsumerStatefulWidget {
  const InstantTestPage({super.key});

  @override
  ConsumerState<InstantTestPage> createState() => _InstantTestPageState();
}

class _InstantTestPageState extends ConsumerState<InstantTestPage> {
  final _pendingFlow = ValueNotifier<int?>(null);
  bool _showFlow = false;

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
  void dispose() {
    _pendingFlow.dispose();
    super.dispose();
  }

  void _launch(int flow) {
    _pendingFlow.value = flow;
    setState(() => _showFlow = true);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_showFlow)
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
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: _showFlow,
                  child: ExcludeFocus(
                    excluding: _showFlow,
                    child: OverviewTab(
                      showProblemCards: false,
                      onViewClients: () => _launch(31),
                      onNavigateToFlow: (index) => _launch(index + 1),
                    ),
                  ),
                ),
                if (_showFlow)
                  Positioned.fill(
                    child: HelpMeFixItTab(
                      pendingFlowNotifier: _pendingFlow,
                      singlePage: true,
                      onExitToHome: () => setState(() => _showFlow = false),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}
