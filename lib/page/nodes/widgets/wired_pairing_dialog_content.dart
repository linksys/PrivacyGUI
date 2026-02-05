import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/instant_topology/widgets/app_mesh_wired_connection.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dialog content widget for wired node pairing process.
///
/// Uses ConsumerStatefulWidget to ensure [startAutoOnboarding] is only called
/// once during initialization, avoiding repeated calls on widget rebuilds.
class WiredPairingDialogContent extends ConsumerStatefulWidget {
  const WiredPairingDialogContent({super.key});

  @override
  ConsumerState<WiredPairingDialogContent> createState() =>
      _WiredPairingDialogContentState();
}

class _WiredPairingDialogContentState
    extends ConsumerState<WiredPairingDialogContent> {
  @override
  void initState() {
    super.initState();
    // Start auto onboarding only once when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(addWiredNodesProvider.notifier).startAutoOnboarding(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final addWiredNodesState = ref.watch(addWiredNodesProvider);
    final isCompleted = addWiredNodesState.isLoading == false &&
        addWiredNodesState.onboardingProceed == true;
    final anyOnboarded = addWiredNodesState.anyOnboarded == true;

    final message = isCompleted
        ? anyOnboarded
            ? loc(context).wiredPairComplete
            : loc(context).wiredPairCompleteNotFound
        : loc(context).pairingWiredChildNodeDesc;

    final theme = Theme.of(context).extension<AppDesignTheme>();
    final colors = theme?.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGap.md(),
        SizedBox(
          width: 300,
          height: 200,
          child: Stack(children: [
            AppMeshWiredConnection(animate: !isCompleted),
            if (isCompleted)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: AppIcon.font(
                    anyOnboarded
                        ? Icons.check_circle_outline
                        : Icons.warning_rounded,
                    size: 48,
                    color: anyOnboarded
                        ? colors?.semanticSuccess
                        : colors?.semanticWarning,
                  ),
                ),
              ),
          ]),
        ),
        AppGap.md(),
        SizedBox(
          width: kDefaultDialogWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(message),
              AppGap.xs(),
              AppText.bodyMedium(isCompleted && anyOnboarded
                  ? addWiredNodesState.loadingMessage ?? ''
                  : ''),
            ],
          ),
        ),
      ],
    );
  }
}
