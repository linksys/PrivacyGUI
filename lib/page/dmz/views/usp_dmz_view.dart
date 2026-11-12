import 'package:privacy_gui/page/_shared/components/tunnel_forwarding_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/dmz/models/dmz_feature_state.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP DMZ settings page — enable/disable DMZ, set the DMZ host by IP or by
/// MAC (#1775), and configure source restriction.
class UspDmzView extends ConsumerStatefulWidget {
  const UspDmzView({super.key});

  @override
  ConsumerState<UspDmzView> createState() => _UspDmzViewState();
}

class _UspDmzViewState extends ConsumerState<UspDmzView> {
  late TextEditingController _destIpController;
  late TextEditingController _destMacController;
  late TextEditingController _cidrController;
  final _destIpFocus = FocusNode();
  final _destMacFocus = FocusNode();
  final _cidrFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _destIpController = TextEditingController();
    _destMacController = TextEditingController();
    _cidrController = TextEditingController();
    for (final focus in [_destIpFocus, _destMacFocus, _cidrFocus]) {
      focus.addListener(_onFieldFocusChange);
    }
  }

  /// Validate when a field loses focus, not on every keystroke: a state
  /// change while typing unfocuses the field on the web.
  void _onFieldFocusChange() {
    if (!_destIpFocus.hasFocus &&
        !_destMacFocus.hasFocus &&
        !_cidrFocus.hasFocus) {
      ref.read(uspDmzProvider.notifier).validate();
    }
  }

  @override
  void dispose() {
    for (final focus in [_destIpFocus, _destMacFocus, _cidrFocus]) {
      focus.removeListener(_onFieldFocusChange);
      focus.dispose();
    }
    _destIpController.dispose();
    _destMacController.dispose();
    _cidrController.dispose();
    super.dispose();
  }

  /// Sync controllers when state data arrives or changes.
  void _syncControllers(DmzFeatureState state) {
    final pending = state.settings.current.model;
    if (_destIpController.text != pending.destIp) {
      _destIpController.text = pending.destIp;
    }
    if (_destMacController.text != pending.destMac) {
      _destMacController.text = pending.destMac;
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
            title: loc(context).failedToLoadSettings,
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
    // Always return a config to keep widget tree stable.
    // Returning null when !isDirty causes tree structure change,
    // which triggers TextField unfocus on Flutter Web.
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: state.isDirty &&
          !state.status.isSaving &&
          state.status.fieldErrors.isEmpty,
      isNegativeEnabled: state.isDirty,
      onPositiveTap: state.isDirty ? () => _onSave(context, ref) : null,
      onNegativeTap: state.isDirty
          ? () => ref.read(uspDmzProvider.notifier).revert()
          : null,
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
        const TunnelForwardingNotice(),
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
              identifier: 'dmz-enabled',
              value: pending.isEnabled,
              // Same busy treatment the rule rows carry — see
              // `usp_single_port_tab.dart` for why a null `onChanged` was not one
              // (#1542). `disabled` here *is* `status.isSaving`.
              isLoading: disabled,
              busySemanticLabel: disabled ? loc(context).processing : null,
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
  // Destination Card
  // ---------------------------------------------------------------------------

  /// The DMZ host, by IP or by MAC (FWDEV#204). Each field suggests the LAN's
  /// devices, as the DHCP reservation dialog does, in place of 1.x's "View
  /// DHCP client table".
  Widget _buildDestinationCard(
    BuildContext context,
    DmzUIModel pending,
    UspDmzNotifier notifier,
    bool disabled,
  ) {
    final errors = ref.watch(uspDmzProvider).status.fieldErrors;
    final devices =
        ref.watch(devicesDataProvider).valueOrNull?.clientDevices ?? const [];
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).dmzDestination),
          AppGap.md(),
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppRadioList<DmzDestinationType>(
              selected: pending.destinationType,
              itemHeight: 56,
              items: [
                for (final type in DmzDestinationType.values)
                  _destinationItem(
                      context, type, pending, notifier, errors, devices),
              ],
              onChanged: disabled
                  ? null
                  : (index, value) {
                      if (value == null || value == pending.destinationType) {
                        return;
                      }
                      notifier.updateSetting(
                          (m) => m.copyWith(destinationType: value));
                      // The other field's error no longer applies.
                      notifier.validate();
                    },
            ),
          ),
        ],
      ),
    );
  }

  /// One option of the destination list; the selected one expands into its
  /// field, which suggests the LAN's devices.
  AppRadioListItem<DmzDestinationType> _destinationItem(
    BuildContext context,
    DmzDestinationType type,
    DmzUIModel pending,
    UspDmzNotifier notifier,
    Map<String, String> errors,
    List<ClientDevice> devices,
  ) {
    final byIp = type == DmzDestinationType.ip;
    final controller = byIp ? _destIpController : _destMacController;
    void write(String value) => notifier.updateSetting(
        (m) => byIp ? m.copyWith(destIp: value) : m.copyWith(destMac: value));
    return AppRadioListItem(
      identifier: byIp ? 'dmz-dest-type-ip' : 'dmz-dest-type-mac',
      title: byIp ? loc(context).ipAddress : loc(context).macAddress,
      value: type,
      expandedWidget: pending.destinationType != type
          ? null
          : AppSelectAutoComplete(
              options: _deviceOptions(devices, type),
              controller: controller,
              onSelected: (value) {
                write(value);
                notifier.validate();
              },
              child: AppTextFormField(
                controller: controller,
                focusNode: byIp ? _destIpFocus : _destMacFocus,
                identifier: byIp ? 'dmz-dest-ip' : 'dmz-dest-mac',
                hintText: byIp
                    ? loc(context).ipAddressHint
                    : loc(context).macAddressHint,
                externalErrorText:
                    _fieldError(context, errors[byIp ? 'destIp' : 'destMac']),
                onChanged: write,
              ),
            ),
    );
  }

  /// The LAN's devices as suggestions for the [type]'s field: the value is
  /// the address that field takes, the subtitle the other one.
  static List<AppAutoCompleteOption> _deviceOptions(
    List<ClientDevice> devices,
    DmzDestinationType type,
  ) {
    final byMac = type == DmzDestinationType.mac;
    return [
      for (final d in devices)
        if ((byMac ? d.mac : d.ip).isNotEmpty)
          AppAutoCompleteOption(
            label: d.displayName,
            value: byMac ? d.mac : d.ip,
            subtitle: byMac ? d.ip : d.mac,
            isActive: d.isActive,
          ),
    ];
  }

  static String? _fieldError(BuildContext context, String? key) =>
      switch (key) {
        null => null,
        DmzErrorKeys.destIpRequired => loc(context).ipAddressRequired,
        DmzErrorKeys.invalidIpAddress => loc(context).invalidIpAddress,
        DmzErrorKeys.destMacRequired => loc(context).macAddressRequired,
        DmzErrorKeys.invalidMacAddress => loc(context).invalidMACAddress,
        _ => loc(context).invalidInput,
      };

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
                  identifier: 'dmz-source-any',
                  title: loc(context).anyAllSources,
                  value: DmzSourceType.any,
                ),
                AppRadioListItem(
                  identifier: 'dmz-source-cidr',
                  title: loc(context).cidrRange,
                  expandedWidget: pending.sourceType == DmzSourceType.cidr
                      ? Container(
                          constraints: const BoxConstraints(maxWidth: 429),
                          child: AppTextFormField(
                            controller: _cidrController,
                            focusNode: _cidrFocus,
                            identifier: 'dmz-source-cidr-ip',
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
        showSaveErrorSnackBar(context, e);
      }
    }
  }
}
