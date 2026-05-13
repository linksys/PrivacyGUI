import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_feature_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Instant Safety page — toggle safe browsing (OpenDNS) on/off.
class UspInstantSafetyView extends ConsumerWidget {
  const UspInstantSafetyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspInstantSafetyProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Instant Safety',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () =>
          ref.read(uspInstantSafetyProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (state.status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (state.status.errorMessage != null) {
          return _buildError(context, ref, state.status.errorMessage!);
        }
        return _buildContent(context, ref, state);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    InstantSafetyFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: 'Save',
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(uspInstantSafetyProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load safe browsing settings'),
          AppGap.md(),
          AppText.bodyMedium(error),
          AppGap.xxl(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspInstantSafetyProvider),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    InstantSafetyFeatureState state,
  ) {
    final notifier = ref.read(uspInstantSafetyProvider.notifier);
    final isEnabled = state.settings.current.isEnabled;
    final isSaving = state.status.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          'Protect your family and block pre-determined adult, illegal and '
          'malicious content with a single tap. Safe browsing applies to all '
          'devices on your network.',
        ),
        AppGap.xl(),
        _buildSafeBrowsingCard(context, isEnabled, isSaving, notifier),
      ],
    );
  }

  Widget _buildSafeBrowsingCard(
    BuildContext context,
    bool isEnabled,
    bool isSaving,
    UspInstantSafetyNotifier notifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.labelLarge('Safe Browsing (OpenDNS)'),
              ),
              AppSwitch(
                value: isEnabled,
                onChanged:
                    isSaving ? null : (value) => notifier.setEnabled(value),
              ),
            ],
          ),
          if (isEnabled) ...[
            AppGap.lg(),
            const Divider(height: 1),
            AppGap.lg(),
            AppText.bodySmall(
              'DNS: 208.67.222.222, 208.67.220.220',
              color: Colors.grey,
            ),
            AppGap.xs(),
            AppText.bodySmall(
              'All devices on your network will use OpenDNS Family Shield '
              'for safer browsing.',
              color: Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspInstantSafetyProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, 'Safe browsing settings saved');
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, 'Failed to save: $e');
      }
    }
  }
}
