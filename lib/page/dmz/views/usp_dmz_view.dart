import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP DMZ settings page — enable/disable DMZ, set destination IP,
/// and configure source restriction.
class UspDmzView extends ConsumerStatefulWidget {
  const UspDmzView({super.key});

  @override
  ConsumerState<UspDmzView> createState() => _UspDmzViewState();
}

class _UspDmzViewState extends ConsumerState<UspDmzView> {
  late TextEditingController _destIpController;
  late TextEditingController _cidrController;

  @override
  void initState() {
    super.initState();
    _destIpController = TextEditingController();
    _cidrController = TextEditingController();
  }

  @override
  void dispose() {
    _destIpController.dispose();
    _cidrController.dispose();
    super.dispose();
  }

  /// Sync controllers when state data arrives or changes.
  void _syncControllers(DmzFeatureState state) {
    final pending = state.settings.current.model;
    if (_destIpController.text != pending.destIp) {
      _destIpController.text = pending.destIp;
    }
    if (_cidrController.text != pending.sourcePrefix) {
      _cidrController.text = pending.sourcePrefix;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uspDmzProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).dmz,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () =>
          ref.read(uspDmzProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.error != null) {
          return ServiceErrorView(
            error: status.error,
            onRetry: () =>
                ref.read(uspDmzProvider.notifier).fetch(forceRemote: true),
          );
        }
        _syncControllers(state);
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
    DmzFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled:
          !state.status.isSaving && state.status.fieldErrors.isEmpty,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(uspDmzProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DmzFeatureState state,
  ) {
    final notifier = ref.read(uspDmzProvider.notifier);
    final pending = state.settings.current.model;
    final disabled = state.status.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).dmzPageDesc,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        _buildEnableCard(context, pending, notifier, disabled),
        if (pending.isEnabled) ...[
          AppGap.md(),
          _buildDestinationCard(context, pending, notifier, disabled),
          AppGap.md(),
          _buildSourceCard(context, pending, notifier, disabled),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Enable Card
  // ---------------------------------------------------------------------------

  Widget _buildEnableCard(
    BuildContext context,
    DmzUIModel pending,
    UspDmzNotifier notifier,
    bool disabled,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(loc(context).dmz),
                  AppGap.sm(),
                  AppText.bodyMedium(
                    loc(context).dmzRouteToHost,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            AppSwitch(
              value: pending.isEnabled,
              onChanged: disabled
                  ? null
                  : (v) => notifier.updateSetting(
                        (m) => m.copyWith(isEnabled: v),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Destination IP Card
  // ---------------------------------------------------------------------------

  Widget _buildDestinationCard(
    BuildContext context,
    DmzUIModel pending,
    UspDmzNotifier notifier,
    bool disabled,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).destinationIp),
          AppGap.md(),
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppIpv4TextField(
              controller: _destIpController,
              onChanged: (value) {
                notifier.updateSetting((m) => m.copyWith(destIp: value));
              },
              errorText: ref.watch(uspDmzProvider).status.fieldErrors['destIp'],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Source Restriction Card
  // ---------------------------------------------------------------------------

  Widget _buildSourceCard(
    BuildContext context,
    DmzUIModel pending,
    UspDmzNotifier notifier,
    bool disabled,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).sourceRestriction),
          AppGap.md(),
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppRadioList(
              selected: pending.sourceType,
              itemHeight: 56,
              items: [
                AppRadioListItem(
                  title: loc(context).anyAllSources,
                  value: DmzSourceType.any,
                ),
                AppRadioListItem(
                  title: loc(context).cidrRange,
                  expandedWidget: pending.sourceType == DmzSourceType.cidr
                      ? Container(
                          constraints: const BoxConstraints(maxWidth: 429),
                          child: AppTextFormField(
                            controller: _cidrController,
                            hintText: 'e.g. 192.168.1.0/24',
                            onChanged: (value) {
                              notifier.updateSetting(
                                  (m) => m.copyWith(sourcePrefix: value));
                            },
                          ),
                        )
                      : null,
                  value: DmzSourceType.cidr,
                ),
              ],
              onChanged: (index, value) {
                if (value == null || value == pending.sourceType) return;
                notifier.updateSetting((m) => m.copyWith(sourceType: value));
              },
            ),
          ),
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
        ref.read(uspDmzProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).dmzSettingsSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
