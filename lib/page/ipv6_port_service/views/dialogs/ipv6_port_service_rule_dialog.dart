import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [Ipv6PortServiceRuleDialog].
class Ipv6PortServiceRuleDialogResult {
  final String description;
  final String ipv6Address;
  final String protocol;
  final int startPort;
  final int endPort;
  final bool enabled;

  const Ipv6PortServiceRuleDialogResult({
    required this.description,
    required this.ipv6Address,
    required this.protocol,
    required this.startPort,
    required this.endPort,
    required this.enabled,
  });
}

/// Dialog for adding or editing an IPv6 port service rule.
///
/// Pass [rule] to pre-fill for editing; omit for adding.
class Ipv6PortServiceRuleDialog extends StatefulWidget {
  final Ipv6PortServiceRuleUIModel? rule;
  final List<AppAutoCompleteOption> deviceOptions;

  /// Every other rule on the page, without [rule]. The new rule may not
  /// overlap one of them, nor take its description: FW refuses both
  /// (FWDEV#204).
  final List<Ipv6PortServiceRuleUIModel> otherRules;

  /// Descriptions of the firewall rules the page does not list, which FW also
  /// refuses a description of.
  final Set<String> hiddenRuleDescriptions;

  const Ipv6PortServiceRuleDialog({
    super.key,
    this.rule,
    this.deviceOptions = const [],
    this.otherRules = const [],
    this.hiddenRuleDescriptions = const {},
  });

  @override
  State<Ipv6PortServiceRuleDialog> createState() =>
      _Ipv6PortServiceRuleDialogState();
}

class _Ipv6PortServiceRuleDialogState extends State<Ipv6PortServiceRuleDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _ipv6Controller;
  late TextEditingController _startPortController;
  late TextEditingController _endPortController;
  // Validate on focus-loss, not per keystroke: validating in onChanged setState's
  // a changed _errors map, which on CanvasKit rebuilds the field with an error
  // slot mid-edit and drops focus + the value being typed. (Same fix as the
  // port-forwarding dialogs / usp_local_network_view.)
  final _descriptionFocus = FocusNode();
  final _ipv6Focus = FocusNode();
  final _startPortFocus = FocusNode();
  final _endPortFocus = FocusNode();
  late String _protocol;
  late bool _enabled;

  Map<String, String> _errors = {};

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _ipv6Controller = TextEditingController(text: r?.ipv6Address ?? '');
    _startPortController = TextEditingController(
      text: r != null && r.startPort >= 0 ? '${r.startPort}' : '',
    );
    _endPortController = TextEditingController(
      text: r != null && r.endPort >= 0 ? '${r.endPort}' : '',
    );
    _protocol = r?.protocol ?? 'Both';
    _enabled = r?.enabled ?? true;
    // A stored rule can already break a check (the page allowed 32
    // characters before FW counted 64 bytes, and FW refused no duplicate
    // before feed_usp#50), and Save is then disabled from the first frame.
    // Show the reason from the first frame too. Edit only: an empty Add form
    // would open with every field in error.
    if (r != null) _errors = _validateFields();
    for (final f in [
      _descriptionFocus,
      _ipv6Focus,
      _startPortFocus,
      _endPortFocus
    ]) {
      f.addListener(() {
        if (!f.hasFocus && mounted) _validate();
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _ipv6Controller.dispose();
    _startPortController.dispose();
    _endPortController.dispose();
    _descriptionFocus.dispose();
    _ipv6Focus.dispose();
    _startPortFocus.dispose();
    _endPortFocus.dispose();
    super.dispose();
  }

  /// Full validation (shows error text) — only run on focus-loss.
  void _validate() {
    setState(() => _errors = _validateFields());
  }

  Map<String, String> _validateFields() =>
      Ipv6PortServiceRuleUIModel.validateRule(
        description: _descriptionController.text.trim(),
        ipv6Address: _ipv6Controller.text.trim(),
        startPort: _startPortController.text.trim(),
        endPort: _endPortController.text.trim(),
        protocol: _protocol,
        otherRules: widget.otherRules,
        hiddenRuleDescriptions: widget.hiddenRuleDescriptions,
      );

  String? _localizeError(String? key) {
    if (key == null) return null;
    final l = loc(context);
    return switch (key) {
      Ipv6PortServiceErrorKeys.descriptionRequired => l.descriptionRequired,
      Ipv6PortServiceErrorKeys.descriptionSurroundingSpaces =>
        l.noLeadingTrailingSpaces,
      Ipv6PortServiceErrorKeys.descriptionTooLong => l.max64Characters,
      Ipv6PortServiceErrorKeys.descriptionInUse => l.ruleNameInUse,
      Ipv6PortServiceErrorKeys.ipv6AddressRequired => l.ipAddressRequired,
      Ipv6PortServiceErrorKeys.invalidIpv6Address => l.invalidIpv6Format,
      Ipv6PortServiceErrorKeys.reservedIpv6Address => l.reservedIpNotAllowed,
      Ipv6PortServiceErrorKeys.invalidPort => l.portMustBe1To65535,
      Ipv6PortServiceErrorKeys.portRangeReversed => l.portRangeError,
      Ipv6PortServiceErrorKeys.rulesOverlap => l.rulesOverlapError,
      _ => l.invalidInput,
    };
  }

  /// What the name uses of FW's 64 bytes, under the field. Counted as FW
  /// counts, so a CJK character visibly takes three and no copy has to say so.
  /// Follows every keystroke: [_onInputChanged] already rebuilds for the
  /// submit gate. Over the limit it takes the error colour, ahead of the
  /// focus-loss error that names the limit.
  Widget _descriptionCounter(BuildContext context) {
    final bytes = Ipv6PortServiceRuleUIModel.descriptionBytes(
        _descriptionController.text.trim());
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: SizedBox(
        width: double.infinity,
        child: AppText.bodySmall(
          '$bytes/$kMaxIpv6RuleDescriptionBytes',
          textAlign: TextAlign.end,
          color: bytes > kMaxIpv6RuleDescriptionBytes
              ? scheme.error
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Lightweight rebuild to re-evaluate the submit-enable state (_isFormValid)
  /// WITHOUT surfacing errors mid-edit — so no error text appears while typing
  /// and focus is preserved.
  void _onInputChanged() => setState(() {});

  bool get _isFormValid => _validateFields().isEmpty;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppText.titleLarge(
          _isEdit ? loc(context).editRule : loc(context).addRule),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        // Left-align the children. The text fields already fill the content
        // width so they look the same either way, but an intrinsically-sized
        // child (the protocol block below) would be centred by the default
        // CrossAxisAlignment.center and sit indented from the fields (#1261).
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            identifier: 'ipv6-rule-description',
            hintText: loc(context).ruleName,
            errorText: _localizeError(_errors['description']),
            onChanged: (_) => _onInputChanged(),
          ),
          _descriptionCounter(context),
          AppGap.lg(),
          AppSelectAutoComplete(
            options: widget.deviceOptions,
            controller: _ipv6Controller,
            onSelected: (_) => _validate(),
            child: AppTextField(
              controller: _ipv6Controller,
              focusNode: _ipv6Focus,
              identifier: 'ipv6-rule-address',
              hintText: loc(context).ipv6AddressSearchHint,
              errorText: _localizeError(_errors['ipv6Address']),
              onChanged: (_) => _onInputChanged(),
            ),
          ),
          AppGap.lg(),
          // Stack the protocol label above the segmented control (Column, not a
          // spaceBetween Row) so a long localized label (e.g. fi "Protokolla" +
          // "Molemmat", tr "Her İkisi") can't squeeze the control and clip its
          // last segment in a narrow AppDialog (#1261). The control gets the
          // full content width. A Wrap can't be used here because SegmentedButton
          // has no dry-layout support and Wrap measures its children.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(loc(context).protocol),
              AppGap.sm(),
              SegmentedButton<String>(
                // Drop the check icon: SegmentedButton sizes all segments
                // equally, and the icon eats ~24px of the selected one. This
                // dialog defaults to 'Both' — the longest label — so with the
                // icon the fi "Molemmat" wraps to "Molemm/at". The selected
                // segment is still distinguished by its fill colour.
                showSelectedIcon: false,
                // The value stays the raw option name — UspIpv6PortServiceService
                // maps it to an IANA number ('Both' -> 255), so it must not be
                // localized. Only the label is translated, and only for 'Both';
                // TCP/UDP are protocol names that stay as-is in every locale
                // (matching the other port-forwarding dialogs).
                segments: Ipv6PortServiceRuleUIModel.protocolOptions
                    .map((name) => ButtonSegment(
                          value: name,
                          label:
                              Text(name == 'Both' ? loc(context).both : name),
                        ))
                    .toList(),
                selected: {_protocol},
                // An overlap depends on the protocol, so re-check the ports.
                onSelectionChanged: (v) {
                  _protocol = v.first;
                  _validate();
                },
              ),
            ],
          ),
          AppGap.lg(),
          AppRangeInput(
            startController: _startPortController,
            endController: _endPortController,
            startFocusNode: _startPortFocus,
            endFocusNode: _endPortFocus,
            startLabel: loc(context).startPort,
            endLabel: loc(context).endPort,
            startIdentifier: 'ipv6-rule-start-port',
            endIdentifier: 'ipv6-rule-end-port',
            // Raises the numeric keyboard only; it does not restrict input, so
            // the 1..65535 bounds still come from Ipv6PortServiceRuleUIModel
            // .validateRule, which owns this dialog's whole rule check (#1537).
            keyboardType: TextInputType.number,
            errorText:
                _localizeError(_errors['startPort'] ?? _errors['endPort']),
            onChanged: (_, __) => _onInputChanged(),
          ),
          AppGap.lg(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).enabled),
              AppSwitch(
                identifier: 'ipv6-rule-enabled',
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'ipv6-rule-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          identifier: 'ipv6-rule-submit',
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _isFormValid ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    final startPort = int.tryParse(_startPortController.text.trim()) ?? 0;
    final endPort = int.tryParse(_endPortController.text.trim()) ?? startPort;
    Navigator.of(context).pop(Ipv6PortServiceRuleDialogResult(
      description: _descriptionController.text.trim(),
      ipv6Address: _ipv6Controller.text.trim(),
      protocol: _protocol,
      startPort: startPort,
      endPort: endPort,
      enabled: _enabled,
    ));
  }
}
