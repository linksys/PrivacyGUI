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

  /// LAN devices offered by the IP field's autocomplete. Empty is legal — the
  /// field stays a plain text input, which is what it was before #1081.
  final List<AppAutoCompleteOption> deviceOptions;

  const PortRangeForwardingDialog({
    super.key,
    this.rule,
    this.deviceOptions = const [],
  });

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
          // `AppTextFormField(label:)`, not `AppTextField(hintText:)` — see the
          // note in `port_forwarding_dialog.dart`. The name persists while you
          // type, and it is the 1.x word rather than the TR-181 one (#1081).
          AppTextFormField(
            controller: _descController,
            focusNode: _descFocus,
            identifier: 'pf-range-description',
            label: loc(context).applicationName,
            externalErrorText: _localizeError(_errors['description']),
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          // The start/end pair is one range, so it gets one group label and the
          // ui_kit range control rather than two independently-named fields.
          // `AppRangeInput` renders `startLabel`/`endLabel` as hints and has no
          // label slot, so the group label sits above it — `bodyMedium` to match
          // the protocol label below and 1.x's own range headings.
          AppText.bodyMedium(loc(context).startEndPorts),
          AppGap.sm(),
          AppRangeInput(
            startController: _extPortStartController,
            endController: _extPortEndController,
            startFocusNode: _extPortStartFocus,
            endFocusNode: _extPortEndFocus,
            startLabel: loc(context).startPort,
            endLabel: loc(context).endPort,
            startIdentifier: 'pf-range-external-port-start',
            endIdentifier: 'pf-range-external-port-end',
            // One error slot for the pair: "end must be greater than start" is a
            // fact about the range, not about either box on its own.
            errorText: _localizeError(_errors['extStart'] ?? _errors['extEnd']),
            onChanged: (_, __) => _onInputChanged(),
          ),
          AppGap.lg(),
          AppTextFormField(
            controller: _intPortController,
            focusNode: _intPortFocus,
            identifier: 'pf-range-internal-port',
            label: loc(context).internalPort,
            keyboardType: TextInputType.number,
            externalErrorText: _localizeError(_errors['intPort']),
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.lg(),
          // Same device picker the single-port dialog has had since #1172: the
          // two dialogs write the same TR-181 field, so typing the IP by hand in
          // one and picking a device in the other was a gap, not a design.
          AppSelectAutoComplete(
            options: widget.deviceOptions,
            controller: _intClientController,
            onSelected: (_) => _validate(),
            child: AppTextFormField(
              controller: _intClientController,
              focusNode: _intClientFocus,
              identifier: 'pf-range-internal-ip',
              label: loc(context).ipAddress,
              hintText: loc(context).ipAddressHint,
              externalErrorText: _localizeError(_errors['client']),
              onChanged: (_) => _onInputChanged(),
            ),
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
