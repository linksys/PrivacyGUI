import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/usp_page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/usp_page/internet_settings/views/components/usp_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// IPv6 settings section.
///
/// Displays IPv6 enable toggle, DHCPv6 toggle, DUID (read-only),
/// and 6rd tunnel configuration.
class UspIpv6Section extends ConsumerStatefulWidget {
  final InternetSettingsFeatureState state;
  final bool isEditing;

  const UspIpv6Section({
    super.key,
    required this.state,
    required this.isEditing,
  });

  @override
  ConsumerState<UspIpv6Section> createState() => _UspIpv6SectionState();
}

class _UspIpv6SectionState extends ConsumerState<UspIpv6Section> {
  late TextEditingController _prefixController;
  late TextEditingController _maskLengthController;
  late TextEditingController _borderRelayController;

  @override
  void initState() {
    super.initState();
    final form = widget.state.edited;
    _prefixController = TextEditingController(text: form.ipv6rdPrefix);
    _maskLengthController =
        TextEditingController(text: form.ipv6rdIpv4MaskLength.toString());
    _borderRelayController =
        TextEditingController(text: form.ipv6rdBorderRelay);
  }

  @override
  void didUpdateWidget(covariant UspIpv6Section oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.edited != widget.state.edited) {
      final form = widget.state.edited;
      _syncIfDifferent(_prefixController, form.ipv6rdPrefix);
      _syncIfDifferent(
          _maskLengthController, form.ipv6rdIpv4MaskLength.toString());
      _syncIfDifferent(_borderRelayController, form.ipv6rdBorderRelay);
    }
  }

  void _syncIfDifferent(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _maskLengthController.dispose();
    _borderRelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.state.edited;
    final isEditing = widget.isEditing;
    final l = loc(context);

    return UspSectionCard(
      title: l.ipv6Settings,
      leadingIcon: Icons.hexagon_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IPv6 Enable
          _switchRow(
            l.ipv6,
            form.ipv6Enabled,
            isEditing
                ? (v) => _updateField((f) => f.copyWith(ipv6Enabled: v))
                : null,
          ),
          AppGap.md(),
          // DHCPv6 Enable
          _switchRow(
            l.dhcpv6,
            form.dhcpv6Enabled,
            isEditing
                ? (v) => _updateField((f) => f.copyWith(dhcpv6Enabled: v))
                : null,
          ),
          AppGap.md(),
          // DUID (read-only)
          UspInfoRow(label: l.duid, value: widget.state.dhcpv6Duid),
          AppGap.lg(),
          // 6rd Tunnel
          _switchRow(
            l.sixrdTunnel,
            form.ipv6rdEnabled,
            isEditing
                ? (v) => _updateField((f) => f.copyWith(ipv6rdEnabled: v))
                : null,
          ),
          if (form.ipv6rdEnabled) ...[
            AppGap.md(),
            ..._build6rdFields(form, isEditing),
          ],
        ],
      ),
    );
  }

  List<Widget> _build6rdFields(UspInternetSettingsForm form, bool isEditing) {
    final l = loc(context);
    if (!isEditing) {
      return [
        UspInfoRow(label: l.prefix, value: form.ipv6rdPrefix),
        UspInfoRow(
            label: l.prefixLength, value: '${form.ipv6rdIpv4MaskLength}'),
        UspInfoRow(label: l.borderRelay, value: form.ipv6rdBorderRelay),
      ];
    }
    return [
      AppTextFormField(
        controller: _prefixController,
        label: l.prefix,
        onChanged: (v) => _updateField((f) => f.copyWith(ipv6rdPrefix: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _maskLengthController,
        label: l.prefixLength,
        keyboardType: TextInputType.number,
        onChanged: (v) => _updateField(
            (f) => f.copyWith(ipv6rdIpv4MaskLength: int.tryParse(v) ?? 0)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _borderRelayController,
        label: l.borderRelay,
        hintText: '192.0.2.1',
        onChanged: (v) => _updateField((f) => f.copyWith(ipv6rdBorderRelay: v)),
      ),
    ];
  }

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool>? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 160, child: AppText.labelLarge(label)),
          const Spacer(),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
