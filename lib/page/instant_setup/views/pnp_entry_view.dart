import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// PnP entry point — checks internet connectivity and routes to wizard or troubleshooter.
///
/// User authentication is handled by LoginLocalView before reaching this view.
/// This view only handles the post-login PnP flow: internet check and navigation.
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
    final pnpState = ref.watch(pnpProvider);

    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring) {
        context.goNamed(RouteNamed.pnpConfig);
      }
      if (next.phase is NoInternet) {
        context.go(RoutePath.pnpNoInternetConnection);
      }
    });

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
              AdminError(message: final msg) => _buildErrorCard(context, msg),
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

  Widget _buildErrorCard(BuildContext context, String message) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.font(Icons.error_outline, size: 48, color: Colors.red),
            AppGap.lg(),
            AppText.bodyMedium(message),
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
