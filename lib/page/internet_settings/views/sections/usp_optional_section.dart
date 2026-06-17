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
    final form = widget.state.edited;
    _mtuController =
        TextEditingController(text: form.mtu == 0 ? '' : form.mtu.toString());
  }

  @override
  void didUpdateWidget(covariant UspOptionalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.edited != widget.state.edited) {
      final form = widget.state.edited;
      final mtuText = form.mtu == 0 ? '' : form.mtu.toString();
      if (_mtuController.text != mtuText) {
        _mtuController.text = mtuText;
      }
    }
  }

  @override
  void dispose() {
    _mtuController.dispose();
    super.dispose();
  }

  int get _mtuMin => 576;
  int get _mtuMax {
    final type = widget.state.edited.connectionType;
    // MTU max varies by connection type due to protocol overhead
    return switch (type) {
      UspWanConnectionType.pppoe => 1492, // 1500 - 8 (PPP header)
      // Future: pptp/l2tp => 1460 (tunnel overhead)
      _ => 1500, // Ethernet standard (DHCP, Static, Bridge)
    };
  }

  String? _getMtuError(int mtu) {
    if (mtu < _mtuMin) return 'MTU must be at least $_mtuMin (IPv4 minimum)';
    if (mtu > _mtuMax) return 'MTU must not exceed $_mtuMax';
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
            UspInfoRow(label: l.mtu, value: '${form.mtu}'),
          ] else ...[
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
            if (_getMtuError(form.mtu) != null) ...[
              AppGap.xs(),
              AppText.bodySmall(
                _getMtuError(form.mtu)!,
                color: Theme.of(context).colorScheme.error,
              ),
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

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }
}
