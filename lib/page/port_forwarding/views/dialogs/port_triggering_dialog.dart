import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [PortTriggeringDialog].
class PortTriggeringDialogResult {
  final String description;
  final int triggerPort;
  final int triggerPortEndRange;
  final String triggerProtocol;
  final int forwardPort;
  final int forwardPortEndRange;
  final String forwardProtocol;
  final bool enabled;

  const PortTriggeringDialogResult({
    required this.description,
    required this.triggerPort,
    this.triggerPortEndRange = 0,
    required this.triggerProtocol,
    required this.forwardPort,
    this.forwardPortEndRange = 0,
    required this.forwardProtocol,
    required this.enabled,
  });
}

/// Dialog for adding or editing a port triggering rule.
///
/// Pass [rule] to pre-fill for editing; omit for adding.
class PortTriggeringDialog extends StatefulWidget {
  final PortTriggeringRuleUIModel? rule;

  const PortTriggeringDialog({super.key, this.rule});

  @override
  State<PortTriggeringDialog> createState() => _PortTriggeringDialogState();
}

class _PortTriggeringDialogState extends State<PortTriggeringDialog> {
  late TextEditingController _descController;
  late TextEditingController _trigPortStartController;
  late TextEditingController _trigPortEndController;
  late TextEditingController _fwdPortStartController;
  late TextEditingController _fwdPortEndController;
  late String _triggerProtocol;
  late String _forwardProtocol;
  late bool _enabled;

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _descController = TextEditingController(text: r?.description ?? '');
    _trigPortStartController =
        TextEditingController(text: r != null ? '${r.triggerPort}' : '');
    _trigPortEndController = TextEditingController(
        text: r != null && r.triggerPortEndRange > 0
            ? '${r.triggerPortEndRange}'
            : '');
    _triggerProtocol = r?.triggerProtocol ?? 'TCP';

    // Pre-fill from first forward rule if editing
    final fwd =
        r?.forwardRules.isNotEmpty == true ? r!.forwardRules.first : null;
    _fwdPortStartController =
        TextEditingController(text: fwd != null ? '${fwd.forwardPort}' : '');
    _fwdPortEndController = TextEditingController(
        text: fwd != null && fwd.forwardPortEndRange > 0
            ? '${fwd.forwardPortEndRange}'
            : '');
    _forwardProtocol = fwd?.forwardProtocol ?? 'TCP';
    _enabled = r?.enabled ?? true;
  }

  @override
  void dispose() {
    _descController.dispose();
    _trigPortStartController.dispose();
    _trigPortEndController.dispose();
    _fwdPortStartController.dispose();
    _fwdPortEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit
          ? loc(context).editPortTriggering
          : loc(context).addPortTriggering),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _descController,
              hintText: loc(context).description,
            ),
            AppGap.xl(),
            AppText.labelLarge(loc(context).triggerPorts),
            AppGap.md(),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _trigPortStartController,
                    hintText: loc(context).startPort,
                    keyboardType: TextInputType.number,
                  ),
                ),
                AppGap.md(),
                Expanded(
                  child: AppTextField(
                    controller: _trigPortEndController,
                    hintText: loc(context).endPortOptional,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            AppGap.md(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).protocol),
                SegmentedButton<String>(
                  segments: [
                    const ButtonSegment(value: 'TCP', label: Text('TCP')),
                    const ButtonSegment(value: 'UDP', label: Text('UDP')),
                    ButtonSegment(
                        value: 'Both', label: Text(loc(context).both)),
                  ],
                  selected: {_triggerProtocol},
                  onSelectionChanged: (v) =>
                      setState(() => _triggerProtocol = v.first),
                ),
              ],
            ),
            AppGap.xl(),
            AppText.labelLarge(loc(context).forwardedPorts),
            AppGap.md(),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _fwdPortStartController,
                    hintText: loc(context).startPort,
                    keyboardType: TextInputType.number,
                  ),
                ),
                AppGap.md(),
                Expanded(
                  child: AppTextField(
                    controller: _fwdPortEndController,
                    hintText: loc(context).endPortOptional,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            AppGap.md(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).protocol),
                SegmentedButton<String>(
                  segments: [
                    const ButtonSegment(value: 'TCP', label: Text('TCP')),
                    const ButtonSegment(value: 'UDP', label: Text('UDP')),
                    ButtonSegment(
                        value: 'Both', label: Text(loc(context).both)),
                  ],
                  selected: {_forwardProtocol},
                  onSelectionChanged: (v) =>
                      setState(() => _forwardProtocol = v.first),
                ),
              ],
            ),
            AppGap.xl(),
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
          onPressed: _submit,
          child: Text(_isEdit ? loc(context).save : loc(context).add),
        ),
      ],
    );
  }

  void _submit() {
    final trigStart = int.tryParse(_trigPortStartController.text.trim());
    final trigEnd = int.tryParse(_trigPortEndController.text.trim()) ?? 0;
    final fwdStart = int.tryParse(_fwdPortStartController.text.trim());
    final fwdEnd = int.tryParse(_fwdPortEndController.text.trim()) ?? 0;
    if (trigStart == null || fwdStart == null) return;
    Navigator.of(context).pop(PortTriggeringDialogResult(
      description: _descController.text.trim(),
      triggerPort: trigStart,
      triggerPortEndRange: trigEnd,
      triggerProtocol: _triggerProtocol,
      forwardPort: fwdStart,
      forwardPortEndRange: fwdEnd,
      forwardProtocol: _forwardProtocol,
      enabled: _enabled,
    ));
  }
}
