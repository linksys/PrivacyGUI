import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/administration/models/administration_feature_state.dart';
import 'package:privacy_gui/page/administration/providers/usp_administration_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Advanced Settings → Administration (#1660, #1694).
///
/// 1.x's page of the same name, carrying the parts FLWRT 2.0 has a data model
/// for: the UPnP switch (`Device.UPnP.Device.Enable`) and the SIP ALG switch
/// (`Device.Firewall.ConnectionTracking.SIP.Enable`). Management access and
/// Express Forwarding stay in #875.
///
/// Not the menu's "Administration" (`UspAdminView`: password, time zone,
/// reboot) — 1.x called that one Instant-Admin.
///
/// Buffered save (Type A): the switch edits the working copy, Save writes it, and
/// leaving with an unsaved change is caught by the route's dirty guard.
class UspAdministrationView extends ConsumerWidget {
  const UspAdministrationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspAdministrationProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).administration,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () =>
          ref.read(uspAdministrationProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.error != null) {
          return ServiceErrorView(
            error: status.error,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref
                .read(uspAdministrationProvider.notifier)
                .fetch(forceRemote: true),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UspUpnpCard(
              enabled: state.settings.current.upnpEnabled,
              isSaving: status.isSaving,
              onChanged:
                  ref.read(uspAdministrationProvider.notifier).setUpnpEnabled,
            ),
            AppGap.md(),
            UspSipAlgCard(
              enabled: state.settings.current.sipAlgEnabled,
              isSaving: status.isSaving,
              onChanged:
                  ref.read(uspAdministrationProvider.notifier).setSipAlgEnabled,
            ),
          ],
        );
      },
    );
  }

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    AdministrationFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () =>
          ref.read(uspAdministrationProvider.notifier).revert(),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspAdministrationProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).changesSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}

/// The UPnP switch.
///
/// Public only so the layout gate can name it in `requires:`; it reads no
/// provider.
class UspUpnpCard extends StatelessWidget {
  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  const UspUpnpCard({
    super.key,
    required this.enabled,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => _SwitchCard(
        label: loc(context).upnp,
        identifier: 'administration-upnp',
        enabled: enabled,
        isSaving: isSaving,
        onChanged: onChanged,
      );
}

/// The SIP ALG switch (#1694): `Device.Firewall.ConnectionTracking.SIP.Enable`.
///
/// Public only so the layout gate can name it in `requires:`; it reads no
/// provider.
class UspSipAlgCard extends StatelessWidget {
  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  const UspSipAlgCard({
    super.key,
    required this.enabled,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => _SwitchCard(
        label: loc(context).administrationApplicationLayerGateway,
        identifier: 'administration-sip-alg',
        enabled: enabled,
        isSaving: isSaving,
        onChanged: onChanged,
      );
}

/// One label beside one switch, in a card. While a save is in flight every
/// switch on the page is busy: one Save writes them all.
class _SwitchCard extends StatelessWidget {
  final String label;
  final String identifier;
  final bool enabled;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.label,
    required this.identifier,
    required this.enabled,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: AppText.labelLarge(label)),
            AppSwitch(
              identifier: identifier,
              value: enabled,
              // Same busy treatment the rule rows carry — see
              // `usp_single_port_tab.dart` for why a null `onChanged` was not
              // one (#1542).
              isLoading: isSaving,
              busySemanticLabel: isSaving ? loc(context).processing : null,
              onChanged: isSaving ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
