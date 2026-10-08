import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_form_validator.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_status_banner.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv4_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv6_section.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/helpers/bridge_redirect_dialog.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_optional_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_renew_section.dart';
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
/// - Optional Settings (MTU + MAC clone), when Auto-IPoE does not manage WAN
/// - Release & Renew (DHCP lease actions)
///
/// Read-only where the surface says so (Remote Assistance, #1626): the edit
/// toggle and Release & Renew both come from one
/// `SurfaceStrategy.internetSettingsEditor` answer, so neither can be offered
/// without the other.
class UspInternetSettingsView extends ConsumerWidget {
  const UspInternetSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspInternetSettingsProvider);
    final notifier = ref.read(uspInternetSettingsProvider.notifier);
    // One decision, read once, for both affordances: `null` means the page is
    // for reading only, so there is no toggle AND no Release & Renew. Watched
    // here rather than in the `child` builder, which runs outside this build.
    final editor = ref
        .watch(surfaceStrategyProvider)
        .internetSettingsEditor(notifier.enterEditMode);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).internetSettings,
      onRefresh: () => ref.read(uspInternetSettingsProvider.notifier).fetch(),
      bottomBar: _buildBottomBar(context, ref, state),
      child: (childContext, constraints) {
        if (state.status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (state.status.error != null) {
          return ServiceErrorView(
            error: state.status.error,
            title: loc(context).failedToLoadSettings,
            onRetry: () =>
                ref.read(uspInternetSettingsProvider.notifier).fetch(),
          );
        }
        return _buildContent(childContext, ref, notifier, state, editor);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UspInternetSettingsNotifier notifier,
    InternetSettingsFeatureState state,
    VoidCallback? editor,
  ) {
    final isEditing = state.isEditing;
    final onEditToggle = switch (state.status.isSaving ? null : editor) {
      null => null,
      final enter => isEditing ? notifier.exitEditMode : enter,
    };
    final showRenew = editor != null && !isEditing;

    final ipoe = ref.watch(autoIPoEDataProvider).valueOrNull;
    if (ipoe?.capabilities.isSupported == true ||
        state.connectionType == UspWanConnectionType.ipoe) {
      ref.watch(autoIPoEPageProvider);
    }
    return AppResponsiveLayout(
      mobile: (_) => _buildMobileLayout(
          context, notifier, state, isEditing, onEditToggle, showRenew),
      desktop: (_) => _buildDesktopLayout(
          context, notifier, state, isEditing, onEditToggle, showRenew),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    UspInternetSettingsNotifier notifier,
    InternetSettingsFeatureState state,
    bool isEditing,
    VoidCallback? onEditToggle,
    bool showRenew,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner with integrated edit icon
        UspConnectionStatusBanner(
          state: state,
          isEditing: isEditing,
          onEditToggle: onEditToggle,
        ),
        AppGap.lg(),
        // IPv4 Connection section
        UspIpv4Section(state: state, isEditing: isEditing),
        AppGap.lg(),
        // Auto-IPoE owns IPv6 until its reset has completed.
        if (state.connectionType != UspWanConnectionType.ipoe &&
            !notifier.needsIPoEReset) ...[
          UspIpv6Section(state: state, isEditing: isEditing),
          AppGap.lg(),
          UspOptionalSection(state: state, isEditing: isEditing),
          AppGap.lg(),
        ],
        // Release & Renew section
        if (showRenew) ...[
          UspRenewSection(state: state),
          AppGap.lg(),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    UspInternetSettingsNotifier notifier,
    InternetSettingsFeatureState state,
    bool isEditing,
    VoidCallback? onEditToggle,
    bool showRenew,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status banner with integrated edit icon
        UspConnectionStatusBanner(
          state: state,
          isEditing: isEditing,
          onEditToggle: onEditToggle,
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
                  if (state.connectionType != UspWanConnectionType.ipoe &&
                      !notifier.needsIPoEReset) ...[
                    AppGap.lg(),
                    UspIpv6Section(state: state, isEditing: isEditing),
                  ],
                ],
              ),
            ),
            AppGap.gutter(),
            // Right column: Optional settings + Release & Renew
            Expanded(
              child: Column(
                children: [
                  if (state.connectionType != UspWanConnectionType.ipoe &&
                      !notifier.needsIPoEReset) ...[
                    UspOptionalSection(state: state, isEditing: isEditing),
                    AppGap.lg(),
                  ],
                  if (showRenew) UspRenewSection(state: state),
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
    final ipoe = ref.watch(autoIPoEDataProvider).valueOrNull;
    final submission = ref.watch(autoIPoESubmissionProvider);
    final supported = ipoe?.capabilities.isSupported == true ||
        state.connectionType == UspWanConnectionType.ipoe;
    final ipoeDirty = supported && ref.watch(autoIPoEPageProvider).isDirty;
    if (state.status.isLoading || !state.isEditing) return null;

    final isValid = ref.watch(uspInternetFormValidProvider);
    final isSaving = state.status.isSaving ||
        ipoe?.runtime.isBusy == true ||
        ipoe?.outcomeFor(submission) == AutoIPoEOutcome.pending;

    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: (state.isDirty || ipoeDirty) && isValid && !isSaving,
      isNegativeEnabled: !state.status.isSaving,
      onPositiveTap: () => _save(context, ref),
      onNegativeTap: () =>
          ref.read(uspInternetSettingsProvider.notifier).exitEditMode(),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(uspInternetSettingsProvider.notifier);
    final preSave = ref.read(uspInternetSettingsProvider);
    // Read the submitted transition BEFORE saving: `original` is the baseline
    // type, `edited` is what the user just chose. This is the unambiguous
    // intent signal, independent of post-save device timing.
    final previousType = preSave.original.connectionType;
    final submittedType = preSave.edited.connectionType;
    final hostName = preSave.readOnlyInfo.hostName;

    try {
      var resetConfirmed = false;
      final needsReset =
          submittedType != UspWanConnectionType.ipoe && notifier.needsIPoEReset;
      if (needsReset) {
        await showSimpleAppDialog(context,
            title: loc(context).autoIpoeReset,
            content:
                AppText.bodyMedium(loc(context).autoIpoeResetBeforeSwitching),
            actions: [
              AppButton.text(
                  label: loc(context).cancel, onTap: () => context.pop()),
              AppButton.primary(
                  identifier: 'auto-ipoe-confirm-reset',
                  label: loc(context).autoIpoeReset,
                  onTap: () {
                    resetConfirmed = true;
                    context.pop();
                  }),
            ]);
        if (!resetConfirmed || !context.mounted) return;
      }
      if (submittedType == UspWanConnectionType.ipoe || needsReset) {
        await notifier.save(resetConfirmed: resetConfirmed);
      } else {
        await doSomethingWithSpinner(context, notifier.save());
      }
      if (!context.mounted) return;

      if (shouldRedirectToBridge(
        previousType: previousType,
        newType: submittedType,
        hostName: hostName,
      )) {
        await showBridgeRedirectDialog(context, hostName: hostName);
      } else {
        showSuccessSnackBar(context, loc(context).changesSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}

/// Whether a save transition should trigger the Bridge Mode redirect dialog:
/// the WAN entered bridge (was not bridge, now is) and a hostname is known.
bool shouldRedirectToBridge({
  required UspWanConnectionType previousType,
  required UspWanConnectionType newType,
  required String hostName,
}) {
  return previousType != UspWanConnectionType.bridge &&
      newType == UspWanConnectionType.bridge &&
      hostName.isNotEmpty;
}
