import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// PnP entry point — handles factory-default detection and login.
class PnpAdminView extends ConsumerStatefulWidget {
  const PnpAdminView({super.key});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pnpProvider.notifier).startFlow());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pnpState = ref.watch(pnpProvider);

    // Listen for phase transitions that require navigation.
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
              AdminInitializing() => _buildLoading(context),
              AdminUnconfigured() => _buildUnconfiguredCard(context),
              AdminAwaitingPassword() => _buildPasswordCard(context),
              AdminLoggingIn() => _buildLoading(context),
              AdminLoginFailed(message: final msg) =>
                _buildPasswordCard(context, error: msg),
              AdminCheckingInternet() => _buildCheckingInternet(context),
              AdminInternetConnected() => _buildLoading(context),
              AdminError(message: final msg) => _buildErrorCard(context, msg),
              WizardInitializing() => _buildLoading(context),
              // Other phases handled by PnpSetupView after navigation.
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

  Widget _buildUnconfiguredCard(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.headlineSmall(loc(context).welcome),
            AppGap.xl(),
            AppText.bodyMedium(loc(context).pnpRouterLoginDesc),
            AppGap.xxxl(),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: loc(context).next,
                onTap: () =>
                    ref.read(pnpProvider.notifier).continueFromUnconfigured(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context, {String? error}) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.headlineSmall(loc(context).routerPassword),
            AppGap.xl(),
            AppText.bodyMedium(loc(context).pnpRouterLoginDesc),
            AppGap.lg(),
            AppPasswordInput(
              label: loc(context).routerPassword,
              controller: _passwordController,
              errorText: error,
              onSubmitted: (_) => _submit(),
            ),
            AppGap.xxxl(),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: loc(context).login,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    ref.read(pnpProvider.notifier).submitPassword(password);
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
              loc(context).pnpWaitingModemCheckingInternet,
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
              onTap: () => ref.read(pnpProvider.notifier).startFlow(),
            ),
          ],
        ),
      ),
    );
  }
}
