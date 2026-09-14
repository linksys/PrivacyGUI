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
  // Focus nodes so validation runs on focus-loss, not per keystroke —
  // validating in onChanged calls setState with a changed _errors map, which
  // rebuilds the field with an error slot mid-edit, tearing down the CanvasKit
  // <input> and dropping focus + the value being typed. Same focus-loss pattern
  // as port_range_forwarding_dialog.
  final _descFocus = FocusNode();
  final _trigPortStartFocus = FocusNode();
  final _trigPortEndFocus = FocusNode();
  final _fwdPortStartFocus = FocusNode();
  final _fwdPortEndFocus = FocusNode();
  late String _triggerProtocol;
  late String _forwardProtocol;
  late bool _enabled;
  Map<String, String> _errors = {};

  bool get _isEdit => widget.rule != null;
  bool get _isFormValid => _errors.isEmpty && _hasRequiredInput;
  // Only the two START ports are required. Unlike port range forwarding, a
  // trigger/forward with no end port is valid and means a single port, so the
  // end boxes are NOT part of the required-input gate.
  bool get _hasRequiredInput =>
      _trigPortStartController.text.trim().isNotEmpty &&
      _fwdPortStartController.text.trim().isNotEmpty;

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
    for (final f in [
      _descFocus,
      _trigPortStartFocus,
      _trigPortEndFocus,
      _fwdPortStartFocus,
      _fwdPortEndFocus,
    ]) {
      f.addListener(() {
        if (!f.hasFocus && mounted) _validate();
      });
    }
  }

  /// Rebuild to re-evaluate the submit-button enable state (_hasRequiredInput)
  /// WITHOUT running validation — so no error text appears mid-edit and focus
  /// is preserved. Full validation happens on focus-loss.
  void _onInputChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _descController.dispose();
    _trigPortStartController.dispose();
    _trigPortEndController.dispose();
    _fwdPortStartController.dispose();
    _fwdPortEndController.dispose();
    _descFocus.dispose();
    _trigPortStartFocus.dispose();
    _trigPortEndFocus.dispose();
    _fwdPortStartFocus.dispose();
    _fwdPortEndFocus.dispose();
    super.dispose();
  }

  void _validate() {
    final errors = <String, String>{};
    final desc = _descController.text.trim();
    final trigStartText = _trigPortStartController.text.trim();
    final trigEndText = _trigPortEndController.text.trim();
    final fwdStartText = _fwdPortStartController.text.trim();
    final fwdEndText = _fwdPortEndController.text.trim();

    if (desc.isNotEmpty && desc.length > 32) {
      errors['description'] = 'max32Characters';
    }

    // Trigger start: required range check when present. int.tryParse('-1')
    // returns -1 (not null), so the null-only guard the old _submit used let
    // -1 / 99999 through — this bounds it to 1..65535.
    if (trigStartText.isNotEmpty) {
      final port = int.tryParse(trigStartText);
      if (port == null || port < 1 || port > 65535) {
        errors['trigStart'] = 'portMustBe1To65535';
      }
    }

    // Trigger end is OPTIONAL: only validate when non-empty. When it is set it
    // must be a valid port AND greater than the start port.
    if (trigEndText.isNotEmpty) {
      final port = int.tryParse(trigEndText);
      if (port == null || port < 1 || port > 65535) {
        errors['trigEnd'] = 'portMustBe1To65535';
      } else if (errors['trigStart'] == null && trigStartText.isNotEmpty) {
        final start = int.tryParse(trigStartText);
        if (start != null && port <= start) {
          errors['trigEnd'] = 'mustBeGreaterThanStartPort';
        }
      }
    }

    if (fwdStartText.isNotEmpty) {
      final port = int.tryParse(fwdStartText);
      if (port == null || port < 1 || port > 65535) {
        errors['fwdStart'] = 'portMustBe1To65535';
      }
    }

    // Forward end is OPTIONAL: same treatment as the trigger end above.
    if (fwdEndText.isNotEmpty) {
      final port = int.tryParse(fwdEndText);
      if (port == null || port < 1 || port > 65535) {
        errors['fwdEnd'] = 'portMustBe1To65535';
      } else if (errors['fwdStart'] == null && fwdStartText.isNotEmpty) {
        final start = int.tryParse(fwdStartText);
        if (start != null && port <= start) {
          errors['fwdEnd'] = 'mustBeGreaterThanStartPort';
        }
      }
    }

    setState(() => _errors = errors);
  }

  String? _localizeError(String? key) {
    if (key == null) return null;
    return switch (key) {
      'max32Characters' => loc(context).max32Characters,
      'portMustBe1To65535' => loc(context).portMustBe1To65535,
      'mustBeGreaterThanStartPort' => loc(context).mustBeGreaterThanStartPort,
      _ => key,
    };
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
            focusNode: _descFocus,
            identifier: 'pf-trigger-description',
            label: loc(context).applicationName,
            externalErrorText: _localizeError(_errors['description']),
            onChanged: (_) => _onInputChanged(),
          ),
          AppGap.xl(),
          // 1.x's headings for the two halves of a trigger rule. `labelLarge`
          // because each covers a range *and* a protocol, so it is a section
          // heading rather than a field label (those are bodyMedium below).
          AppText.labelLarge(loc(context).triggeredRange),
          AppGap.md(),
          // NOTE: `keyboardType` is NOT passed here — `AppRangeInput` (ui_kit
          // v3.2.0) exposes no `keyboardType` parameter and does not hardcode a
          // numeric keyboard internally (its inner TextField/AppTextField leave
          // keyboardType at the default). The pre-#1081 individual AppTextFields
          // used `keyboardType: TextInputType.number`; that capability can only
          // return once ui_kit's AppRangeInput adds the parameter. Range
          // bounds are still enforced by _validate() below.
          AppRangeInput(
            startController: _trigPortStartController,
            endController: _trigPortEndController,
            startFocusNode: _trigPortStartFocus,
            endFocusNode: _trigPortEndFocus,
            startLabel: loc(context).startPort,
            // Keeps "(optional)": unlike port range forwarding, a trigger rule
            // with no end port is valid and means a single port.
            endLabel: loc(context).endPortOptional,
            startIdentifier: 'pf-trigger-trigger-port-start',
            endIdentifier: 'pf-trigger-trigger-port-end',
            errorText:
                _localizeError(_errors['trigStart'] ?? _errors['trigEnd']),
            onChanged: (_, __) => _onInputChanged(),
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
          // NOTE: `keyboardType` intentionally omitted — see the same note on
          // the trigger AppRangeInput above (ui_kit v3.2.0 AppRangeInput has no
          // keyboardType parameter).
          AppRangeInput(
            startController: _fwdPortStartController,
            endController: _fwdPortEndController,
            startFocusNode: _fwdPortStartFocus,
            endFocusNode: _fwdPortEndFocus,
            startLabel: loc(context).startPort,
            endLabel: loc(context).endPortOptional,
            startIdentifier: 'pf-trigger-forward-port-start',
            endIdentifier: 'pf-trigger-forward-port-end',
            errorText: _localizeError(_errors['fwdStart'] ?? _errors['fwdEnd']),
            onChanged: (_, __) => _onInputChanged(),
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
        // The identifiers stay `port-triggering-*` rather than being renamed to
        // the `pf-trigger-*` prefix used inside: they are the E2E suite's
        // contract.
        AppButton.primary(
          identifier: 'port-triggering-submit',
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _isFormValid ? _submit : null,
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
