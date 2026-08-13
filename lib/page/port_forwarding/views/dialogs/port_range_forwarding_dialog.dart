import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [PortRangeForwardingDialog].
class PortRangeForwardingDialogResult {
  final String description;
  final int externalPortStart;
  final int externalPortEnd;
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortRangeForwardingDialogResult({
    required this.description,
    required this.externalPortStart,
    required this.externalPortEnd,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });
}

/// Dialog for adding or editing a port range forwarding rule.
///
/// Pass [rule] to pre-fill for editing; omit for adding.
class PortRangeForwardingDialog extends StatefulWidget {
  final PortForwardingRuleUIModel? rule;

  const PortRangeForwardingDialog({super.key, this.rule});

  @override
  State<PortRangeForwardingDialog> createState() =>
      _PortRangeForwardingDialogState();
}

class _PortRangeForwardingDialogState extends State<PortRangeForwardingDialog> {
  static final _ipRule = IpAddressRule();

  late TextEditingController _descController;
  late TextEditingController _extPortStartController;
  late TextEditingController _extPortEndController;
  late TextEditingController _intPortController;
  late TextEditingController _intClientController;
  // Focus nodes so validation runs on focus-loss, not per keystroke —
  // validating in onChanged calls setState with a changed _errors map, which
  // rebuilds the field with an error slot mid-edit, tearing down the CanvasKit
  // <input> and dropping focus + the value being typed. (Same focus-loss
  // pattern as usp_local_network_view.)
  final _descFocus = FocusNode();
  final _extPortStartFocus = FocusNode();
  final _extPortEndFocus = FocusNode();
  final _intPortFocus = FocusNode();
  final _intClientFocus = FocusNode();
  late String _protocol;
  late bool _enabled;
  Map<String, String> _errors = {};

  bool get _isEdit => widget.rule != null;
  bool get _isFormValid => _errors.isEmpty && _hasRequiredInput;
  bool get _hasRequiredInput =>
      _extPortStartController.text.trim().isNotEmpty &&
      _extPortEndController.text.trim().isNotEmpty &&
      _intPortController.text.trim().isNotEmpty &&
      _intClientController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _descController = TextEditingController(text: r?.description ?? '');
    _extPortStartController =
        TextEditingController(text: r != null ? '${r.externalPort}' : '');
    _extPortEndController = TextEditingController(
        text: r != null ? '${r.externalPortEndRange}' : '');
    _intPortController =
        TextEditingController(text: r != null ? '${r.internalPort}' : '');
    _intClientController = TextEditingController(text: r?.internalClient ?? '');
    _protocol = r?.protocol ?? 'TCP';
    _enabled = r?.enabled ?? true;
    for (final f in [
      _descFocus,
      _extPortStartFocus,
      _extPortEndFocus,
      _intPortFocus,
      _intClientFocus,
    ]) {
      f.addListener(() {
        if (!f.hasFocus && mounted) _validate();
      });
    }
  }

  /// Rebuild to re-evaluate the Add-button enable state (_hasRequiredInput)
  /// WITHOUT running validation — so no error text appears mid-edit and focus
  /// is preserved. Full validation happens on focus-loss.
  void _onInputChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _descController.dispose();
    _extPortStartController.dispose();
    _extPortEndController.dispose();
    _intPortController.dispose();
    _intClientController.dispose();
    _descFocus.dispose();
    _extPortStartFocus.dispose();
    _extPortEndFocus.dispose();
    _intPortFocus.dispose();
    _intClientFocus.dispose();
    super.dispose();
  }

  void _validate() {
    final errors = <String, String>{};
    final desc = _descController.text.trim();
    final extStartText = _extPortStartController.text.trim();
    final extEndText = _extPortEndController.text.trim();
    final intPortText = _intPortController.text.trim();
    final client = _intClientController.text.trim();

    if (desc.isNotEmpty && desc.length > 32) {
      errors['description'] = 'max32Characters';
    }

    if (extStartText.isNotEmpty) {
      final port = int.tryParse(extStartText);
      if (port == null || port < 1 || port > 65535) {
        errors['extStart'] = 'portMustBe1To65535';
      }
    }

    if (extEndText.isNotEmpty) {
      final port = int.tryParse(extEndText);
      if (port == null || port < 1 || port > 65535) {
        errors['extEnd'] = 'portMustBe1To65535';
      } else if (errors['extStart'] == null && extStartText.isNotEmpty) {
        final start = int.tryParse(extStartText);
        if (start != null && port <= start) {
          errors['extEnd'] = 'mustBeGreaterThanStartPort';
        }
      }
    }

    if (intPortText.isNotEmpty) {
      final port = int.tryParse(intPortText);
      if (port == null || port < 1 || port > 65535) {
        errors['intPort'] = 'portMustBe1To65535';
      }
    }

    if (client.isNotEmpty && !_ipRule.validate(client)) {
      errors['client'] = 'invalidIpv4Format';
    }

    setState(() => _errors = errors);
  }

  String? _localizeError(String? key) {
    if (key == null) return null;
    return switch (key) {
      'max32Characters' => loc(context).max32Characters,
      'portMustBe1To65535' => loc(context).portMustBe1To65535,
      'mustBeGreaterThanStartPort' => loc(context).mustBeGreaterThanStartPort,
      'invalidIpv4Format' => loc(context).invalidIpv4Format,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppText.titleLarge(_isEdit
          ? loc(context).editPortRangeForwarding
          : loc(context).addPortRangeForwarding),
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
            controller: _descController,
            focusNode: _descFocus,
            identifier: 'pf-range-description',
            hintText: loc(context).description,
            errorText: _localizeError(_errors['description']),
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _extPortStartController,
                  focusNode: _extPortStartFocus,
                  identifier: 'pf-range-external-port-start',
                  hintText: loc(context).externalPortStart,
                  keyboardType: TextInputType.number,
                  errorText: _localizeError(_errors['extStart']),
                  onChanged: (_) => _onInputChanged(),
                ),
              ),
              AppGap.md(),
              Expanded(
                child: AppTextField(
                  controller: _extPortEndController,
                  focusNode: _extPortEndFocus,
                  identifier: 'pf-range-external-port-end',
                  hintText: loc(context).externalPortEnd,
                  keyboardType: TextInputType.number,
                  errorText: _localizeError(_errors['extEnd']),
                  onChanged: (_) => _onInputChanged(),
                ),
              ),
            ],
          ),
          AppGap.lg(),
          AppTextField(
            controller: _intPortController,
            focusNode: _intPortFocus,
            identifier: 'pf-range-internal-port',
            hintText: loc(context).internalPort,
            keyboardType: TextInputType.number,
            errorText: _localizeError(_errors['intPort']),
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          AppTextField(
            controller: _intClientController,
            focusNode: _intClientFocus,
            identifier: 'pf-range-internal-ip',
            hintText: loc(context).internalIpHint,
            errorText: _localizeError(_errors['client']),
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          // Stack the protocol label above the segmented control (Column, not a
          // spaceBetween Row) so a long localized label (e.g. fi "Protokolla" +
          // "Molemmat") can't squeeze the control and clip its last segment in a
          // narrow AppDialog (#1261). The control gets the full content width. A
          // Wrap can't be used here because SegmentedButton has no dry-layout
          // support and Wrap measures its children.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(loc(context).protocol),
              AppGap.sm(),
              SegmentedButton<String>(
                segments: [
                  const ButtonSegment(value: 'TCP', label: Text('TCP')),
                  const ButtonSegment(value: 'UDP', label: Text('UDP')),
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
                identifier: 'pf-range-enabled',
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'pf-range-cancel',
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.text(
          identifier: 'pf-range-submit',
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _isFormValid ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    context.pop(PortRangeForwardingDialogResult(
      description: _descController.text.trim(),
      externalPortStart: int.parse(_extPortStartController.text.trim()),
      externalPortEnd: int.parse(_extPortEndController.text.trim()),
      internalPort: int.parse(_intPortController.text.trim()),
      internalClient: _intClientController.text.trim(),
      protocol: _protocol,
      enabled: _enabled,
    ));
  }
}
