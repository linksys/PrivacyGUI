import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_navigation.dart';
import 'package:privacy_gui/page/instant_verify/views/my_devices_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/overview_tab.dart';
import 'package:privacy_gui/page/instant_verify/views/symptom_chooser.dart';

/// Instant-Test home (route `menuInstantTest`): the diagnostic result and the
/// help choices. Device details, Network details and each help flow are
/// child routes pushed from here.
class InstantTestPage extends ConsumerStatefulWidget {
  const InstantTestPage({super.key});

  @override
  ConsumerState<InstantTestPage> createState() => _InstantTestPageState();
}

class _InstantTestPageState extends ConsumerState<InstantTestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(instantVerifyPivotProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) => OverviewTab(
        showProblemCards: false,
        leading: SymptomChooser(
            onSelect: (flow) => pushInstantTestHelp(context, ref, flow)),
        onNavigateToFlow: (index) =>
            pushInstantTestHelp(context, ref, index + 1),
        onTroubleshootWeakDevices: () => pushInstantTestHelp(context, ref, 31),
        onViewNetwork: () => pushInstantTestNetwork(context, ref),
        onTroubleshootDevice: (device) =>
            pushInstantTestHelp(context, ref, 31, device: device),
      );
}

/// Device details (route `instantTestDevices`).
class InstantTestDevicesPage extends ConsumerWidget {
  const InstantTestDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MyDevicesTab(
      onNavigateToFlow: (flow, {device}) =>
          pushInstantTestHelp(context, ref, flow, device: device));
}
