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
    // `AppDialog`, not the raw Material `AlertDialog` this was still using: #1166
    // moved the other rule dialogs over and missed this one, so the third tab's
    // dialog had a different frame, title style and scroll behaviour from the
    // two next to it.
    return AppDialog(
      title: AppText.titleLarge(_isEdit
          ? loc(context).editPortTriggering
          : loc(context).addPortTriggering),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `AppTextFormField(label:)`, not `AppTextField(hintText:)` — see the
          // note in `port_forwarding_dialog.dart` (#1081).
          AppTextFormField(
            controller: _descController,
            identifier: 'pf-trigger-description',
            label: loc(context).applicationName,
          ),
          AppGap.xl(),
          // 1.x's headings for the two halves of a trigger rule. `labelLarge`
          // because each covers a range *and* a protocol, so it is a section
          // heading rather than a field label (those are bodyMedium below).
          AppText.labelLarge(loc(context).triggeredRange),
          AppGap.md(),
          AppRangeInput(
            startController: _trigPortStartController,
            endController: _trigPortEndController,
            startLabel: loc(context).startPort,
            // Keeps "(optional)": unlike port range forwarding, a trigger rule
            // with no end port is valid and means a single port.
            endLabel: loc(context).endPortOptional,
            startIdentifier: 'pf-trigger-trigger-port-start',
            endIdentifier: 'pf-trigger-trigger-port-end',
          ),
          AppGap.md(),
          // Stack the protocol label above the segmented control so a long
          // localized label (e.g. fi "Protokolla" + "Molemmat") can't squeeze
          // the control and clip its last segment in a narrow AppDialog
          // (#1261). A Wrap can't be used here because SegmentedButton has no
          // dry-layout support and Wrap measures its children.
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
                selected: {_triggerProtocol},
                onSelectionChanged: (v) =>
                    setState(() => _triggerProtocol = v.first),
              ),
            ],
          ),
          AppGap.xl(),
          AppText.labelLarge(loc(context).forwardedRange),
          AppGap.md(),
          AppRangeInput(
            startController: _fwdPortStartController,
            endController: _fwdPortEndController,
            startLabel: loc(context).startPort,
            endLabel: loc(context).endPortOptional,
            startIdentifier: 'pf-trigger-forward-port-start',
            endIdentifier: 'pf-trigger-forward-port-end',
          ),
          AppGap.md(),
          // Same stacking reason as the trigger protocol above (#1261).
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
                identifier: 'pf-trigger-enabled',
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'port-triggering-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        // `AppButton.text` like the other two rule dialogs' submit. The
        // identifiers stay `port-triggering-*` rather than being renamed to the
        // `pf-trigger-*` prefix used inside: they are the E2E suite's contract.
        AppButton.text(
          identifier: 'port-triggering-submit',
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _submit,
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
