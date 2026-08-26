import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_form_validator.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_section_card.dart';
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
        hintText: '2001:db8::/32',
        externalErrorText: validateIpv6rdPrefix(form.ipv6rdPrefix),
        onChanged: (v) => _updateField((f) => f.copyWith(ipv6rdPrefix: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _maskLengthController,
        label: l.prefixLength,
        hintText: '0-32',
        keyboardType: TextInputType.number,
        externalErrorText:
            validateIpv6rdPrefixLength(form.ipv6rdIpv4MaskLength),
        onChanged: (v) => _updateField(
            (f) => f.copyWith(ipv6rdIpv4MaskLength: int.tryParse(v) ?? 0)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _borderRelayController,
        label: l.borderRelay,
        hintText: '192.0.2.1',
        externalErrorText: validateIpv6rdBorderRelay(form.ipv6rdBorderRelay),
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
          // `Expanded`, not a fixed 160px box plus a `Spacer`. Two columns of a
          // 601px page give this row ~253px, and 160px + the switch + the section
          // card's insets was 5.5px past that in all 26 locales (#1380) — the
          // desktop layout's narrowest column is narrower than the whole content
          // box of a 320px phone, so this row was the only one on the page with a
          // hard floor under it. The switch does not move: the `Spacer` existed only
          // to push it to the far edge, which the `Expanded` does as well.
          //
          // What it costs, measured rather than assumed: the share is 142.5px where
          // the box was 160px, and across all three labels × 26 locales exactly one
          // string is in between — `sv`'s "6rd Tunnel (6rd-tunnel)" at 159.8px, which
          // now takes two lines. The other 77 are 58.6px or less. A clean two-line
          // wrap in one locale for a row that was clipped in all 26 is the trade, and
          // no smaller gap buys it back (`sm` would reclaim 4px of the 17px). Both
          // directions guarded in test/page/_shared/page_surface_overflow_test.dart.
          Expanded(child: AppText.labelLarge(label)),
          AppGap.md(),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
