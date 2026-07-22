import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';
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

  const Ipv6PortServiceRuleDialog({
    super.key,
    this.rule,
    this.deviceOptions = const [],
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
    setState(() {
      _errors = UspIpv6PortServiceService.validateRule(
        description: _descriptionController.text.trim(),
        ipv6Address: _ipv6Controller.text.trim(),
        startPort: _startPortController.text.trim(),
        endPort: _endPortController.text.trim(),
      );
    });
  }

  /// Lightweight rebuild to re-evaluate the submit-enable state (_isFormValid)
  /// WITHOUT surfacing errors mid-edit — so no error text appears while typing
  /// and focus is preserved.
  void _onInputChanged() => setState(() {});

  bool get _isFormValid {
    final errors = UspIpv6PortServiceService.validateRule(
      description: _descriptionController.text.trim(),
      ipv6Address: _ipv6Controller.text.trim(),
      startPort: _startPortController.text.trim(),
      endPort: _endPortController.text.trim(),
    );
    return errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? loc(context).editRule : loc(context).addRule),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              hintText: loc(context).ruleName,
              errorText: _errors['description'],
              onChanged: (_) => _onInputChanged(),
            ),
            AppGap.lg(),
            AppSelectAutoComplete(
              options: widget.deviceOptions,
              controller: _ipv6Controller,
              onSelected: (_) => _validate(),
              child: AppTextField(
                controller: _ipv6Controller,
                focusNode: _ipv6Focus,
                hintText: loc(context).ipv6AddressSearchHint,
                errorText: _errors['ipv6Address'],
                onChanged: (_) => _onInputChanged(),
              ),
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).protocol),
                SegmentedButton<String>(
                  segments: UspIpv6PortServiceService.protocolOptions
                      .map((name) =>
                          ButtonSegment(value: name, label: Text(name)))
                      .toList(),
                  selected: {_protocol},
                  onSelectionChanged: (v) =>
                      setState(() => _protocol = v.first),
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
              errorText: _errors['startPort'] ?? _errors['endPort'],
              onChanged: (_, __) => _onInputChanged(),
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
          onPressed: _isFormValid ? _submit : null,
          child: Text(_isEdit ? loc(context).save : loc(context).add),
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
