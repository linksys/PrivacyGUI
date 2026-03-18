import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_form_validator.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_notifier.dart';
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
    final state = ref.watch(uspInternetSettingsProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).internetSettings,
      onRefresh: () => ref.read(uspInternetSettingsProvider.notifier).fetch(),
      bottomBar: _buildBottomBar(context, ref, state),
      child: (childContext, constraints) {
        if (state.status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (state.status.errorMessage != null) {
          return _buildError(childContext, ref, state.status.errorMessage!);
        }
        return _buildContent(childContext, ref, state);
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.bodyLarge(loc(context).failedToLoadSettings),
          AppGap.md(),
          AppText.bodyMedium(error),
          AppGap.xl(),
          AppButton.primary(
            label: loc(context).retry,
            onTap: () =>
                ref.read(uspInternetSettingsProvider.notifier).fetch(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    InternetSettingsFeatureState state,
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
    InternetSettingsFeatureState state,
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
    InternetSettingsFeatureState state,
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
    InternetSettingsFeatureState state,
  ) {
    if (state.status.isLoading || !state.isEditing) return null;

    final isValid = ref.watch(uspInternetFormValidProvider);
    final isSaving = state.status.activeMutation == 'save';

    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: state.isDirty && isValid && !isSaving,
      onPositiveTap: () => _save(context, ref),
      onNegativeTap: () =>
          ref.read(uspInternetSettingsProvider.notifier).exitEditMode(),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspInternetSettingsProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).changesSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, '$e');
      }
    }
  }
}
