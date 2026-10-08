import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart' show MeshNodeInfo, BackhaulHealth;
import 'package:privacy_gui/page/instant_verify/providers/instant_test_device_id_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/answer_row.dart';
import 'package:privacy_gui/page/instant_verify/views/details_disclosure.dart';
import 'package:privacy_gui/page/instant_verify/views/device_actions.dart';
import 'package:privacy_gui/page/instant_verify/views/diagnostic_selection_area.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_navigation.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_style.dart';
import 'package:privacy_gui/page/instant_verify/views/restart_helper.dart';
import 'package:privacy_gui/page/instant_verify/views/user_step_heading.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

part 'help_shared.dart';
part 'flow_internet.dart';
part 'flow_speed.dart';
part 'flow_device.dart';
part 'flow_coverage.dart';
part 'flow_drops.dart';
part 'flow_two_routers.dart';

/// One guided help flow, as its own page (route `instantTestHelp`, flow id in
/// the `flow` query parameter). Opening another flow pushes another page;
/// Back pops, or steps back within the flow while it has earlier steps.
///
/// _SessionSummaryCard — key diagnostic data at escalation screens.
/// _SatisfactionPrompt — satisfaction rating at terminal screens.
class InstantTestHelpView extends ConsumerStatefulWidget {
  const InstantTestHelpView({super.key, required this.flow});

  /// 1-6, or a device flow: 30 (connected), 31 (slow), 32 (drops).
  final int flow;

  static const flows = {1, 2, 3, 4, 5, 6, 30, 31, 32};

  static String title(int flow) => switch (flow) {
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

  @override
  ConsumerState<InstantTestHelpView> createState() =>
      _InstantTestHelpViewState();
}

class _InstantTestHelpViewState extends ConsumerState<InstantTestHelpView> {
  final _stepBack = ValueNotifier<VoidCallback?>(null);
  final _indicator = ValueNotifier<String?>(null);
  DiagnosticClient? _device;

  @override
  void initState() {
    super.initState();
    // Read once: a later flow may hand over a different device.
    final mac = ref.read(instantTestDeviceIdProvider);
    _device = mac.isEmpty
        ? null
        : ref
            .read(instantVerifyPivotProvider)
            .clients
            .firstWhereOrNull((client) => client.macAddress == mac);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recordFlow(widget.flow);
    });
  }

  @override
  void dispose() {
    _stepBack.dispose();
    _indicator.dispose();
    super.dispose();
  }

  void _recordFlow(int flow) {
    const names = {1: 'internet_not_working', 2: 'internet_slow',
      3: 'device_connectivity', 30: 'device_connectivity', 31: 'device_slow', 32: 'device_drops',
      4: 'wifi_coverage', 5: 'connection_drops', 6: 'bridge_mode'};
    ref.read(instantVerifyPivotProvider.notifier)
        .recordFlowEntered(names[flow] ?? 'flow_$flow');
  }

  void _done() => popInstantTestHelp(context, ref);

  void _openFlow(int flow) => pushInstantTestHelp(context, ref, flow);

  void _checkAgain() {
    ref.read(instantVerifyPivotProvider.notifier).fetch();
    popToInstantTestHome(context, ref);
  }

  Widget _flow() {
    final flow = widget.flow;
    return switch (flow) {
      1 => _Flow1(onDone: _done, onNavigateToFlow: _openFlow, stepBackNotifier: _stepBack),
      2 => _Flow2(onDone: _done, onNavigateToFlow: _openFlow, singlePage: true,
          stepBackNotifier: _stepBack, stepIndicatorNotifier: _indicator),
      3 || 30 || 31 || 32 => _Flow3(onDone: _done,
          initialConnected: flow == 30 || flow == 31,
          initialSlowDevice: flow == 31,
          initialIssue: flow == 32 ? _ConnectIssue.keepsDropping
              : flow == 3 ? _ConnectIssue.cantConnect : null,
          initialDevice: _device, singlePage: true,
          stepBackNotifier: _stepBack, stepIndicatorNotifier: _indicator),
      4 => _Flow4(onDone: _done, stepBackNotifier: _stepBack, singlePage: true),
      5 => _Flow5(onDone: _done, onNavigateToFlow: _openFlow,
          stepBackNotifier: _stepBack, stepIndicatorNotifier: _indicator, singlePage: true),
      6 => _Flow6BridgeMode(onDone: _done, stepBackNotifier: _stepBack, stepIndicatorNotifier: _indicator),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // The connection check has its own re-check beside its result; a second
    // "Check again" here would do something different under the same name.
    final checkAgain = widget.flow != 1;
    return ValueListenableBuilder<VoidCallback?>(
      valueListenable: _stepBack,
      // Back steps back within the flow first, then pops the page.
      builder: (context, stepBack, _) => StyledAppPageView(
        title: InstantTestHelpView.title(widget.flow),
        scrollable: true,
        onBackTap: stepBack,
        child: (context, constraints) => DiagnosticSelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: _indicator,
                builder: (_, indicator, __) => indicator == null
                    ? const SizedBox.shrink()
                    : AppText.labelSmall(indicator),
              ),
              _flow(),
              if (checkAgain) ...[
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
                          onTap: _checkAgain, icon: LinksysIcons.refresh),
                    ]),
              ],
              const AppGap.large2(),
              _linksysSupportTile(context),
            ],
          ),
        ),
      ),
    );
  }
}
