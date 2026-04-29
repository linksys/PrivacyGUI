import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
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

  @override
  Widget build(BuildContext context) {
    final form = widget.state.edited;
    final isEditing = widget.isEditing;
    // final isAutoMtu = form.mtu == 0;
    final l = loc(context);

    return UspSectionCard(
      title: l.optionalSettings,
      leadingIcon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MTU — Auto toggle hidden until backend supports auto detection
          // if (!isEditing) ...[
          //   UspInfoRow(label: l.mtu, value: isAutoMtu ? l.auto : '${form.mtu}'),
          // ] else ...[
          //   Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       AppText.bodyMedium(l.mtu),
          //       Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           AppText.bodyMedium(l.auto),
          //           AppGap.sm(),
          //           AppSwitch(
          //             value: isAutoMtu,
          //             onChanged: (v) {
          //               _updateField((f) => f.copyWith(mtu: v ? 0 : 1500));
          //               if (!v) {
          //                 _mtuController.text = '1500';
          //               }
          //             },
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          //   if (!isAutoMtu) ...[
          //     AppGap.md(),
          //     AppTextFormField(
          //       controller: _mtuController,
          //       label: l.size,
          //       keyboardType: TextInputType.number,
          //       onChanged: (v) =>
          //           _updateField((f) => f.copyWith(mtu: int.tryParse(v) ?? 0)),
          //     ),
          //   ],
          // ],
          if (!isEditing) ...[
            UspInfoRow(label: l.mtu, value: '${form.mtu}'),
          ] else ...[
            AppTextFormField(
              controller: _mtuController,
              label: l.mtu,
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  _updateField((f) => f.copyWith(mtu: int.tryParse(v) ?? 0)),
            ),
          ],
          AppGap.lg(),
          AppDivider(),
          AppGap.lg(),
          // MAC Address Clone — read-only until USP data model supports write
          AppText.labelLarge(l.macAddressClone),
          AppGap.md(),
          UspInfoRow(
              label: l.currentMac, value: widget.state.currentMacAddress),
        ],
      ),
    );
  }

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }
}
