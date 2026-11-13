import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// PnP entry point — starts the flow and shows its entry checks.
///
/// User authentication is handled by LoginLocalView before reaching this view.
/// The navigation the checks lead to — the wizard, or troubleshooting — is
/// `PnpFlowShell`'s, not this page's (#1511 P2).
class PnpEntryView extends ConsumerStatefulWidget {
  const PnpEntryView({super.key});

  @override
  ConsumerState<PnpEntryView> createState() => _PnpEntryViewState();
}

class _PnpEntryViewState extends ConsumerState<PnpEntryView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pnpProvider.notifier).startPostLoginFlow());
  }

  @override
  Widget build(BuildContext context) {
    // Renders the entry checks only. Where the flow goes next is the shell's
    // (`pnpFlowDestination`, #1511 P2).
    final pnpState = ref.watch(pnpProvider);

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      child: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxxl,
            ),
            child: switch (pnpState.phase) {
              AdminCheckingInternet() => _buildCheckingInternet(context),
              AdminInternetConnected() => _buildLoading(context),
              AdminReadFailure() => _buildErrorCard(context),
              WizardInitializing() => _buildLoading(context),
              _ => _buildLoading(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(child: AppLoader());
  }

  Widget _buildCheckingInternet(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(),
            AppGap.xxxl(),
            AppText.bodyMedium(
              loc(context).checkingForInternet,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.font(Icons.error_outline, size: 48, color: Colors.red),
            AppGap.lg(),
            AppText.bodyMedium(
              loc(context).unableToGatherDeviceInfo,
              textAlign: TextAlign.center,
            ),
            AppGap.xl(),
            AppButton.text(
              label: loc(context).tryAgain,
              onTap: () => ref.read(pnpProvider.notifier).startPostLoginFlow(),
            ),
          ],
        ),
      ),
    );
  }
}
