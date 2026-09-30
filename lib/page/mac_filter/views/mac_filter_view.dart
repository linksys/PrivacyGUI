import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The MAC Filter page: choose a mode (Off / Allow / Deny) and manage the
/// filtered device list. Shares the `X_LINKSYS_SetMACFilter` backend with
/// Instant Privacy (which is this filter locked to Allow mode).
class MacFilterView extends ConsumerWidget {
  const MacFilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspMacFilterProvider);
    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).macFilter,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(uspMacFilterProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref.invalidate(uspMacFilterProvider),
          ),
          data: (state) => _buildContent(context, ref, state),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(loc(context).macFilterPageDesc),
        AppGap.lg(),
        _buildModeCard(context, ref, state),
        if (state.isEnabled) ...[
          AppGap.lg(),
          _buildDeviceList(context, ref, state),
        ],
      ],
    );
  }

  Widget _buildModeCard(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.md),
      child: AppRadioList<MacFilterMode>(
        selected: state.mode,
        onChanged: state.isBusy
            ? null
            : (_, mode) {
                if (mode != null && mode != state.mode) {
                  _onModeChange(context, ref, mode);
                }
              },
        items: [
          AppRadioListItem(
            identifier: 'mac-filter-mode-disabled',
            title: loc(context).macFilterModeDisabled,
            value: MacFilterMode.disabled,
            descriptionWidget:
                AppText.bodySmall(loc(context).macFilterModeDisabledDesc),
          ),
          AppRadioListItem(
            identifier: 'mac-filter-mode-allow',
            title: loc(context).macFilterModeAllow,
            value: MacFilterMode.allow,
            descriptionWidget:
                AppText.bodySmall(loc(context).macFilterModeAllowDesc),
          ),
          AppRadioListItem(
            identifier: 'mac-filter-mode-deny',
            title: loc(context).macFilterModeDeny,
            value: MacFilterMode.deny,
            descriptionWidget:
                AppText.bodySmall(loc(context).macFilterModeDenyDesc),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    return SizedBox(
      width: double.infinity,
      // Wrap, not Row: the header label and the Add button must reflow rather
      // than overflow at narrow widths / long locales — see instant_privacy's
      // #1380 note for the same treatment.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.sm,
            children: [
              AppText.labelLarge(
                  loc(context).macFilterListTitle(state.macs.length)),
              AppButton.text(
                identifier: 'mac-filter-add-device',
                label: loc(context).addDevice,
                onTap: state.isBusy
                    ? null
                    : () => _showAddMacDialog(context, ref, state),
              ),
            ],
          ),
          AppGap.md(),
          if (state.macs.isEmpty)
            AppText.bodySmall(loc(context).macFilterListEmpty)
          else
            ...state.macs.map((mac) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildDeviceRow(context, ref, state, mac),
                )),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(
      BuildContext context, WidgetRef ref, MacFilterState state, String mac) {
    final device = state.connectedDevices
        .where((d) => d.mac.toUpperCase() == mac.toUpperCase())
        .firstOrNull;
    final name = device?.displayName ?? mac;
    return LayoutBlock(
      child: Row(
        children: [
          AppIcon.font(Icons.devices, size: 20),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(name),
                AppText.bodySmall(mac),
              ],
            ),
          ),
          AppIconButton(
            identifier: 'mac-filter-remove-$mac',
            icon: AppIcon.font(Icons.close, size: 20),
            semanticLabel: loc(context).macFilterRemoveDevice,
            onTap: state.isBusy ? null : () => _onRemove(context, ref, mac),
          ),
        ],
      ),
    );
  }

  Future<void> _onModeChange(
      BuildContext context, WidgetRef ref, MacFilterMode mode) async {
    try {
      await ref.read(uspMacFilterProvider.notifier).setMode(mode);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeServiceError(context, e))),
        );
      }
    }
  }

  Future<void> _onRemove(
      BuildContext context, WidgetRef ref, String mac) async {
    try {
      await ref.read(uspMacFilterProvider.notifier).removeMac(mac);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeServiceError(context, e))),
        );
      }
    }
  }

  void _showAddMacDialog(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    final deviceOptions = state.connectedDevices
        .map((d) => AppAutoCompleteOption(
              label: d.displayName,
              value: d.mac,
              subtitle: d.ipAddress.isNotEmpty ? d.ipAddress : null,
            ))
        .toList();
    showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AddMacDialog(
        existingMacs: state.macs,
        deviceOptions: deviceOptions,
        onConfirm: (mac) async {
          await ref.read(uspMacFilterProvider.notifier).addMac(mac);
        },
      ),
    );
  }
}

/// Add-device dialog. Mirrors instant_privacy's dialog, including the #1059
/// Web-focus validation-on-unfocus workaround.
class _AddMacDialog extends StatefulWidget {
  const _AddMacDialog({
    required this.existingMacs,
    required this.deviceOptions,
    required this.onConfirm,
  });

  final List<String> existingMacs;
  final List<AppAutoCompleteOption> deviceOptions;
  final Future<void> Function(String mac) onConfirm;

  @override
  State<_AddMacDialog> createState() => _AddMacDialogState();
}

class _AddMacDialogState extends State<_AddMacDialog> {
  final _controller = TextEditingController();
  final _canConfirm = ValueNotifier<bool>(false);
  String? _errorKey;
  bool _isConfirming = false;

  @override
  void dispose() {
    _controller.dispose();
    _canConfirm.dispose();
    super.dispose();
  }

  String? _errorFor(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (!UspMacFilterService.validateMac(value)) return 'invalidMacFormat';
    final normalized = UspMacFilterService.normalizeMac(value);
    final present = widget.existingMacs
        .map((m) => m.toUpperCase())
        .contains(normalized.toUpperCase());
    if (present) return 'alreadyInList';
    return null;
  }

  void _revalidate() {
    final text = _controller.text;
    _canConfirm.value = text.trim().isNotEmpty && _errorFor(text) == null;
  }

  String? _localizedError(BuildContext context) => switch (_errorKey) {
        'invalidMacFormat' => loc(context).invalidMacAddressFormat,
        'alreadyInList' => loc(context).deviceAlreadyInAllowedList,
        _ => null,
      };

  Future<void> _confirm() async {
    setState(() => _isConfirming = true);
    await widget.onConfirm(UspMacFilterService.normalizeMac(_controller.text));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      titleText: loc(context).addDeviceManually,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).enterMacAddressToAllow),
          AppGap.md(),
          AppSelectAutoComplete(
            options: widget.deviceOptions,
            controller: _controller,
            onSelected: (value) {
              _controller.text = value;
              _revalidate();
            },
            child: AppTextField(
              identifier: 'mac-filter-add-mac-input',
              controller: _controller,
              hintText: loc(context).searchByNameMacIp,
              errorText: _localizedError(context),
              onChanged: (_) {
                setState(() => _errorKey = _errorFor(_controller.text));
                _revalidate();
              },
            ),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'mac-filter-add-mac-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _canConfirm,
          builder: (context, canConfirm, _) => AppButton.primary(
            identifier: 'mac-filter-add-mac-confirm',
            label: _isConfirming ? loc(context).adding : loc(context).add,
            onTap: (canConfirm && !_isConfirming) ? _confirm : null,
          ),
        ),
      ],
    );
  }
}
