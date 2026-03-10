import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_form_validator.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_state.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/components/usp_connection_status_banner.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/sections/usp_ipv4_section.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/sections/usp_ipv6_section.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/sections/usp_optional_section.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/sections/usp_renew_section.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Main page for USP-based Internet Settings.
///
/// Single scrollable page with responsive layout:
/// - Mobile: stacked cards
/// - Desktop: two-column layout (IPv4+IPv6 left, Optional+Renew right)
///
/// Sections:
/// - Connection Status Banner (with edit icon)
/// - IPv4 Connection (type + conditional fields)
/// - IPv6 Settings (enable + 6rd tunnel)
/// - Optional Settings (MTU + MAC clone)
/// - Release & Renew (DHCP lease actions)
class UspInternetSettingsView extends ConsumerWidget {
  const UspInternetSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspInternetSettingsProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).internetSettings,
      onRefresh: () => ref.refresh(uspInternetSettingsProvider.future),
      bottomBar: _buildBottomBar(context, ref, asyncState),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, stack) => _buildError(childContext, ref, error),
          data: (state) => _buildContent(childContext, ref, state),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(loc(context).failedToLoadSettings),
          AppGap.md(),
          AppText.bodyMedium(error.toString()),
          AppGap.xl(),
          AppButton.primary(
            label: loc(context).retry,
            onTap: () => ref.invalidate(uspInternetSettingsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UspInternetSettingsState state,
  ) {
    final isEditing = state.isEditing;
    final notifier = ref.read(uspInternetSettingsProvider.notifier);

    return AppResponsiveLayout(
      mobile: (_) => _buildMobileLayout(context, state, isEditing, notifier),
      desktop: (_) => _buildDesktopLayout(context, state, isEditing, notifier),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    UspInternetSettingsState state,
    bool isEditing,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner with integrated edit icon
        UspConnectionStatusBanner(
          state: state,
          isEditing: isEditing,
          onEditToggle: () {
              if (isEditing) {
                notifier.exitEditMode();
              } else {
                notifier.enterEditMode();
              }
            },
        ),
        AppGap.lg(),
        // IPv4 Connection section
        UspIpv4Section(state: state, isEditing: isEditing),
        AppGap.lg(),
        // IPv6 Settings section
        UspIpv6Section(state: state, isEditing: isEditing),
        AppGap.lg(),
        // Optional Settings section (MTU + MAC clone)
        UspOptionalSection(state: state, isEditing: isEditing),
        AppGap.lg(),
        // Release & Renew section
        if (!isEditing) ...[
          UspRenewSection(state: state),
          AppGap.lg(),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    UspInternetSettingsState state,
    bool isEditing,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner with integrated edit icon
        UspConnectionStatusBanner(
          state: state,
          isEditing: isEditing,
          onEditToggle: () {
              if (isEditing) {
                notifier.exitEditMode();
              } else {
                notifier.enterEditMode();
              }
            },
        ),
        AppGap.lg(),
        // Two-column layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: IPv4 + IPv6
            Expanded(
              child: Column(
                children: [
                  UspIpv4Section(state: state, isEditing: isEditing),
                  AppGap.lg(),
                  UspIpv6Section(state: state, isEditing: isEditing),
                ],
              ),
            ),
            AppGap.gutter(),
            // Right column: Optional + Renew
            Expanded(
              child: Column(
                children: [
                  UspOptionalSection(state: state, isEditing: isEditing),
                  AppGap.lg(),
                  if (!isEditing) UspRenewSection(state: state),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UspInternetSettingsState> asyncState,
  ) {
    final state = asyncState.valueOrNull;
    if (state == null || !state.isEditing) return null;

    final isValid = ref.watch(uspInternetFormValidProvider);
    final isLoading = ref.watch(uspInternetMutationLoadingProvider) == 'save';

    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: state.isDirty && isValid && !isLoading,
      onPositiveTap: () => _save(ref, state),
      onNegativeTap: () =>
          ref.read(uspInternetSettingsProvider.notifier).exitEditMode(),
    );
  }

  Future<void> _save(
    WidgetRef ref,
    UspInternetSettingsState state,
  ) async {
    ref.read(uspInternetMutationLoadingProvider.notifier).state = 'save';
    try {
      await ref.read(uspInternetSettingsProvider.notifier).save();
    } catch (_) {
      // Error handled by the notifier state
    } finally {
      ref.read(uspInternetMutationLoadingProvider.notifier).state = null;
    }
  }
}
