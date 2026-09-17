import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Optional settings section: MTU and MAC address clone.
class UspOptionalSection extends ConsumerStatefulWidget {
  final InternetSettingsFeatureState state;
  final bool isEditing;

  const UspOptionalSection({
    super.key,
    required this.state,
    required this.isEditing,
  });

  @override
  ConsumerState<UspOptionalSection> createState() => _UspOptionalSectionState();
}

class _UspOptionalSectionState extends ConsumerState<UspOptionalSection> {
  late TextEditingController _mtuController;

  @override
  void initState() {
    super.initState();
    _mtuController = TextEditingController(text: _mtuText);
  }

  @override
  void didUpdateWidget(covariant UspOptionalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.edited != widget.state.edited) {
      if (_mtuController.text != _mtuText) {
        _mtuController.text = _mtuText;
      }
    }
  }

  /// Text for the MTU field. `0` only occurs before the first fetch, where an
  /// empty field is friendlier than a bogus zero.
  String get _mtuText {
    final mtu = widget.state.edited.mtu;
    return mtu == 0 ? '' : mtu.toString();
  }

  @override
  void dispose() {
    _mtuController.dispose();
    super.dispose();
  }

  // MTU range is owned by [UspWanConnectionType] (single source of truth,
  // shared with the notifier's clamp on type switch).
  int get _mtuMin => widget.state.edited.connectionType.mtuMin;
  int get _mtuMax => widget.state.edited.connectionType.mtuMax;

  String? _getMtuError(BuildContext context, int mtu) {
    if (mtu < _mtuMin) return loc(context).mtuMinError(_mtuMin);
    if (mtu > _mtuMax) return loc(context).mtuMaxError(_mtuMax);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.state.edited;
    final isEditing = widget.isEditing;
    final l = loc(context);

    final isBridge = form.connectionType == UspWanConnectionType.bridge;

    return UspSectionCard(
      title: l.optionalSettings,
      leadingIcon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MTU — hidden for bridge mode (uses auto), manual input for others
          if (isBridge) ...[
            UspInfoRow(label: l.mtu, value: l.auto),
          ] else if (!isEditing) ...[
            // Auto reports the mode alone, like the bridge row above: the number
            // is the device's, and repeating it here would read as a setting.
            UspInfoRow(
              label: l.mtu,
              value: form.mtuAuto ? l.auto : '${form.mtu}',
            ),
          ] else ...[
            // Toggle is gated on firmware support: without X_LINKSYS_MTUMode the
            // mode can neither be read nor written, so only manual entry is shown.
            if (widget.state.mtuModeSupported)
              Row(
                children: [
                  AppText.labelLarge(l.autoMtu),
                  const Spacer(),
                  AppSwitch(
                    value: form.mtuAuto,
                    onChanged: _onMtuAutoChanged,
                  ),
                ],
              ),
            if (!form.mtuAuto) ...[
              if (widget.state.mtuModeSupported) AppGap.md(),
              AppTextFormField(
                controller: _mtuController,
                label: '${l.mtu} ($_mtuMin - $_mtuMax)',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed > 0) {
                    _updateField((f) => f.copyWith(mtu: parsed));
                  }
                },
              ),
              if (_getMtuError(context, form.mtu) != null) ...[
                AppGap.xs(),
                AppText.bodySmall(
                  _getMtuError(context, form.mtu)!,
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ],
          ],
          // MAC Address Clone — disabled: USP data model does not support write
          // AppGap.lg(),
          // AppDivider(),
          // AppGap.lg(),
          // AppText.labelLarge(l.macAddressClone),
          // AppGap.md(),
          // UspInfoRow(
          //     label: l.currentMac, value: widget.state.currentMacAddress),
        ],
      ),
    );
  }

  /// Flips MTU mode. Leaving auto seeds the field with the effective MTU the
  /// device reported, clamped to the current type's range — the user sees the
  /// baseline they are overriding and the form validates without further input.
  void _onMtuAutoChanged(bool value) {
    _updateField((f) => value
        ? f.copyWith(mtuAuto: true)
        : f.copyWith(mtuAuto: false, mtu: f.connectionType.clampMtu(f.mtu)));
  }

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }
}
