import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [PortForwardingDialog].
class PortForwardingDialogResult {
  final String description;
  final int externalPort;
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortForwardingDialogResult({
    required this.description,
    required this.externalPort,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });
}

/// Dialog for adding or editing a port forwarding rule.
///
/// Pass [rule] to pre-fill for editing; omit for adding.
class PortForwardingDialog extends StatefulWidget {
  final PortForwardingRuleUIModel? rule;
  final List<AppAutoCompleteOption> deviceOptions;

  const PortForwardingDialog({
    super.key,
    this.rule,
    this.deviceOptions = const [],
  });

  @override
  State<PortForwardingDialog> createState() => _PortForwardingDialogState();
}

class _PortForwardingDialogState extends State<PortForwardingDialog> {
  late TextEditingController _descController;
  late TextEditingController _extPortController;
  late TextEditingController _intPortController;
  late TextEditingController _intClientController;
  // One focus node per text field: validation runs on focus-loss, not on every
  // keystroke. Validating in onChanged calls setState → rebuild → the CanvasKit
  // <input> is torn down mid-edit, dropping focus and the value being typed.
  // (Same focus-loss pattern as usp_local_network_view.)
  final _descFocus = FocusNode();
  final _extPortFocus = FocusNode();
  final _intPortFocus = FocusNode();
  final _intClientFocus = FocusNode();
  late String _protocol;
  late bool _enabled;

  Map<String, String> _errors = {};

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _descController = TextEditingController(text: r?.description ?? '');
    _extPortController =
        TextEditingController(text: r != null ? '${r.externalPort}' : '');
    _intPortController =
        TextEditingController(text: r != null ? '${r.internalPort}' : '');
    _intClientController = TextEditingController(text: r?.internalClient ?? '');
    _protocol = r?.protocol ?? 'TCP';
    _enabled = r?.enabled ?? true;
    // Validate when each field loses focus (updates the shown errorText).
    for (final f in [
      _descFocus,
      _extPortFocus,
      _intPortFocus,
      _intClientFocus
    ]) {
      f.addListener(() {
        if (!f.hasFocus && mounted) _validate(context);
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _extPortController.dispose();
    _intPortController.dispose();
    _intClientController.dispose();
    _descFocus.dispose();
    _extPortFocus.dispose();
    _intPortFocus.dispose();
    _intClientFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  static final _ipAddressRule = IpAddressRule();
  static final _ipNoReservedRule = IpAddressNoReservedRule();
  static final _noWhitespaceRule = NoSurroundWhitespaceRule();

  /// Rebuild to re-evaluate the Add-button enable state (_isFormValid) WITHOUT
  /// surfacing errors mid-edit — validation (and thus error text) runs on
  /// focus-loss so the CanvasKit <input> isn't torn down while typing.
  void _onInputChanged() {
    setState(() {});
  }

  void _validate(BuildContext context) {
    setState(() {
      _errors = _validateFields(context);
    });
  }

  /// Format-only validation: an EMPTY field never reports an error (so no
  /// error text appears while the form is still being filled, which would
  /// rebuild the field and drop focus mid-edit). Emptiness is handled by the
  /// Add-button enable gate (_hasRequiredInput) and re-checked on submit.
  Map<String, String> _validateFields(BuildContext context) {
    final errors = <String, String>{};
    final desc = _descController.text.trim();
    final extPort = _extPortController.text.trim();
    final intPort = _intPortController.text.trim();
    final client = _intClientController.text.trim();

    // Description — only when non-empty.
    if (desc.isNotEmpty) {
      if (!_noWhitespaceRule.validate(desc)) {
        errors['description'] = loc(context).noLeadingTrailingSpaces;
      } else if (desc.length > 32) {
        errors['description'] = loc(context).mustBe32CharsOrLess;
      }
    }

    // External port — only when non-empty.
    if (extPort.isNotEmpty) {
      final ext = int.tryParse(extPort);
      if (ext == null || ext < 1 || ext > 65535) {
        errors['externalPort'] = loc(context).portMustBe1To65535;
      }
    }

    // Internal port — only when non-empty.
    if (intPort.isNotEmpty) {
      final intP = int.tryParse(intPort);
      if (intP == null || intP < 1 || intP > 65535) {
        errors['internalPort'] = loc(context).portMustBe1To65535;
      }
    }

    // Internal client (IPv4) — only when non-empty.
    if (client.isNotEmpty) {
      if (!_ipAddressRule.validate(client)) {
        errors['internalClient'] = loc(context).invalidIpv4Format;
      } else if (!_ipNoReservedRule.validate(client)) {
        errors['internalClient'] = loc(context).reservedIpNotAllowed;
      }
    }

    return errors;
  }

  /// All required fields present.
  bool get _hasRequiredInput =>
      _descController.text.trim().isNotEmpty &&
      _extPortController.text.trim().isNotEmpty &&
      _intPortController.text.trim().isNotEmpty &&
      _intClientController.text.trim().isNotEmpty;

  /// Enable submit: every required field filled AND no format errors. Uses the
  /// format-only validator so an in-progress (partly empty) form doesn't show
  /// errors, but submit stays disabled until complete + valid.
  bool _isFormValid(BuildContext context) =>
      _hasRequiredInput && _validateFields(context).isEmpty;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppText.titleLarge(_isEdit
          ? loc(context).editPortForwarding
          : loc(context).addPortForwarding),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _descController,
            focusNode: _descFocus,
            identifier: 'pf-single-description',
            hintText: loc(context).description,
            errorText: _errors['description'],
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          AppTextField(
            controller: _extPortController,
            focusNode: _extPortFocus,
            identifier: 'pf-single-external-port',
            hintText: loc(context).externalPort,
            keyboardType: TextInputType.number,
            errorText: _errors['externalPort'],
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          AppTextField(
            controller: _intPortController,
            focusNode: _intPortFocus,
            identifier: 'pf-single-internal-port',
            hintText: loc(context).internalPort,
            keyboardType: TextInputType.number,
            errorText: _errors['internalPort'],
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          AppSelectAutoComplete(
            options: widget.deviceOptions,
            controller: _intClientController,
            onSelected: (_) => _validate(context),
            child: AppTextField(
              controller: _intClientController,
              focusNode: _intClientFocus,
              identifier: 'pf-single-internal-ip',
              hintText: loc(context).internalIpHint,
              errorText: _errors['internalClient'],
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
                segments: [
                  ButtonSegment(value: 'TCP', label: Text(loc(context).tcp)),
                  ButtonSegment(value: 'UDP', label: Text(loc(context).udp)),
                  ButtonSegment(value: 'Both', label: Text(loc(context).both)),
                ],
                selected: {_protocol},
                onSelectionChanged: (v) => setState(() => _protocol = v.first),
              ),
            ],
          ),
          AppGap.lg(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).enabled),
              AppSwitch(
                identifier: 'pf-single-enabled',
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'pf-single-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        AppButton.text(
          identifier: 'pf-single-submit',
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _isFormValid(context) ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    final extPort = int.tryParse(_extPortController.text.trim());
    final intPort = int.tryParse(_intPortController.text.trim());
    final client = _intClientController.text.trim();
    if (extPort == null || intPort == null || client.isEmpty) return;
    Navigator.of(context).pop(PortForwardingDialogResult(
      description: _descController.text.trim(),
      externalPort: extPort,
      internalPort: intPort,
      internalClient: client,
      protocol: _protocol,
      enabled: _enabled,
    ));
  }
}
