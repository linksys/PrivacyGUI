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
  }

  @override
  void dispose() {
    _descController.dispose();
    _extPortController.dispose();
    _intPortController.dispose();
    _intClientController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  static final _ipAddressRule = IpAddressRule();
  static final _ipNoReservedRule = IpAddressNoReservedRule();
  static final _noWhitespaceRule = NoSurroundWhitespaceRule();

  void _validate(BuildContext context) {
    setState(() {
      _errors = _validateFields(context);
    });
  }

  Map<String, String> _validateFields(BuildContext context) {
    final errors = <String, String>{};
    final desc = _descController.text.trim();
    final extPort = _extPortController.text.trim();
    final intPort = _intPortController.text.trim();
    final client = _intClientController.text.trim();

    // Description
    if (desc.isEmpty) {
      errors['description'] = loc(context).descriptionRequired;
    } else if (!_noWhitespaceRule.validate(desc)) {
      errors['description'] = loc(context).noLeadingTrailingSpaces;
    } else if (desc.length > 32) {
      errors['description'] = loc(context).mustBe32CharsOrLess;
    }

    // External port
    final ext = int.tryParse(extPort);
    if (extPort.isEmpty) {
      errors['externalPort'] = loc(context).externalPortRequired;
    } else if (ext == null || ext < 1 || ext > 65535) {
      errors['externalPort'] = loc(context).portMustBe1To65535;
    }

    // Internal port
    final intP = int.tryParse(intPort);
    if (intPort.isEmpty) {
      errors['internalPort'] = loc(context).internalPortRequired;
    } else if (intP == null || intP < 1 || intP > 65535) {
      errors['internalPort'] = loc(context).portMustBe1To65535;
    }

    // Internal client (IPv4)
    if (client.isEmpty) {
      errors['internalClient'] = loc(context).ipAddressRequired;
    } else if (!_ipAddressRule.validate(client)) {
      errors['internalClient'] = loc(context).invalidIpv4Format;
    } else if (!_ipNoReservedRule.validate(client)) {
      errors['internalClient'] = loc(context).reservedIpNotAllowed;
    }

    return errors;
  }

  bool _isFormValid(BuildContext context) => _validateFields(context).isEmpty;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit
          ? loc(context).editPortForwarding
          : loc(context).addPortForwarding),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _descController,
              hintText: loc(context).description,
              errorText: _errors['description'],
              onChanged: (_) => _validate(context),
            ),
            AppGap.lg(),
            AppTextField(
              controller: _extPortController,
              hintText: loc(context).externalPort,
              keyboardType: TextInputType.number,
              errorText: _errors['externalPort'],
              onChanged: (_) => _validate(context),
            ),
            AppGap.lg(),
            AppTextField(
              controller: _intPortController,
              hintText: loc(context).internalPort,
              keyboardType: TextInputType.number,
              errorText: _errors['internalPort'],
              onChanged: (_) => _validate(context),
            ),
            AppGap.lg(),
            AppSelectAutoComplete(
              options: widget.deviceOptions,
              controller: _intClientController,
              onSelected: (_) => _validate(context),
              child: AppTextField(
                controller: _intClientController,
                hintText: loc(context).internalIpHint,
                errorText: _errors['internalClient'],
                onChanged: (_) => _validate(context),
              ),
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).protocol),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'TCP', label: Text(loc(context).tcp)),
                    ButtonSegment(value: 'UDP', label: Text(loc(context).udp)),
                    ButtonSegment(
                        value: 'Both', label: Text(loc(context).both)),
                  ],
                  selected: {_protocol},
                  onSelectionChanged: (v) =>
                      setState(() => _protocol = v.first),
                ),
              ],
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).enabled),
                AppSwitch(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc(context).cancel),
        ),
        FilledButton(
          onPressed: _isFormValid(context) ? _submit : null,
          child: Text(_isEdit ? loc(context).save : loc(context).add),
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
