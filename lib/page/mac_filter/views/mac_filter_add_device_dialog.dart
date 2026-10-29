import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Opens the shared "add device manually" dialog used by both the MAC Filter
/// and Instant Privacy pages. [onAdd] receives a normalized MAC and performs the
/// local (save-based) add; the dialog itself does the validation and closes on
/// confirm.
void showMacFilterAddDeviceDialog({
  required BuildContext context,
  required List<String> existingMacs,
  required List<MacFilterDeviceUIModel> connectedDevices,
  required void Function(String mac) onAdd,
}) {
  final options = connectedDevices
      .map((d) => AppAutoCompleteOption(
            label: d.displayName,
            value: d.mac,
            subtitle: d.ipAddress.isNotEmpty ? d.ipAddress : null,
          ))
      .toList();
  showAppDialog<void>(
    context: context,
    // The field reveals its error on change; a scrim tap must not close the
    // dialog out from under an in-progress edit (#1059).
    barrierDismissible: false,
    builder: (dialogContext) => _AddDeviceDialog(
      existingMacs: existingMacs,
      options: options,
      onAdd: onAdd,
    ),
  );
}

class _AddDeviceDialog extends StatefulWidget {
  const _AddDeviceDialog({
    required this.existingMacs,
    required this.options,
    required this.onAdd,
  });

  final List<String> existingMacs;
  final List<AppAutoCompleteOption> options;
  final void Function(String mac) onAdd;

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _canConfirm = ValueNotifier<bool>(false);
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _canConfirm.dispose();
    super.dispose();
  }

  String? _errorFor(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (!MacFilterRules.validateMac(value)) return 'invalidMacFormat';
    final normalized = MacFilterRules.normalizeMac(value);
    final present = widget.existingMacs
        .map((m) => m.toUpperCase())
        .contains(normalized.toUpperCase());
    if (present) return 'alreadyInList';
    return null;
  }

  void _revalidate() {
    final text = _controller.text;
    _canConfirm.value = text.trim().isNotEmpty && _errorFor(text) == null;
  }

  String? _localizedError(BuildContext context) => switch (_errorKey) {
        'invalidMacFormat' => loc(context).invalidMacAddressFormat,
        'alreadyInList' => loc(context).deviceAlreadyInAllowedList,
        _ => null,
      };

  /// The canonical form the value will be added as, while the field holds one
  /// complete, addable MAC in any accepted spelling (#1737). Null for partial
  /// input, a name or an IP — and while an error is shown, which already says
  /// why the value cannot be added.
  String? get _canonicalPreview {
    final text = _controller.text;
    if (_errorKey != null || !MacFilterRules.validateMac(text)) return null;
    return MacFilterRules.normalizeMac(text);
  }

  /// On blur, a complete MAC is rewritten to its canonical form (#1737). Only
  /// here, never per keystroke: the field is also the name / IP search box, and
  /// a partial entry cannot be told apart from a name or an IP (#1059).
  void _onFocusChange() {
    if (!mounted || _focusNode.hasFocus) return;
    final text = _controller.text;
    if (!MacFilterRules.validateMac(text)) return;
    final canonical = MacFilterRules.normalizeMac(text);
    if (canonical == text) return;
    _controller.value = TextEditingValue(
      text: canonical,
      selection: TextSelection.collapsed(offset: canonical.length),
    );
    setState(() => _errorKey = _errorFor(_controller.text));
    _revalidate();
  }

  void _confirm() {
    widget.onAdd(MacFilterRules.normalizeMac(_controller.text));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _canonicalPreview;
    return AppDialog(
      titleText: loc(context).addDeviceManually,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).enterMacAddressToAllow),
          AppGap.md(),
          AppSelectAutoComplete(
            options: widget.options,
            controller: _controller,
            onSelected: (value) {
              _controller.text = value;
              setState(() => _errorKey = _errorFor(_controller.text));
              _revalidate();
            },
            child: AppTextField(
              identifier: 'mac-filter-add-mac-input',
              controller: _controller,
              focusNode: _focusNode,
              hintText: loc(context).searchByNameMacIp,
              errorText: _localizedError(context),
              errorDisplayMode: AppErrorDisplayMode.text,
              onChanged: (_) {
                setState(() => _errorKey = _errorFor(_controller.text));
                _revalidate();
              },
            ),
          ),
          // After the field, never around it: wrapping or re-ordering the field
          // re-parents its semantics node, which blurs the <input> on web (#1736).
          if (preview != null) ...[
            AppGap.xs(),
            AppText.bodySmall(loc(context).macWillBeAddedAs(preview)),
          ],
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'mac-filter-add-mac-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _canConfirm,
          builder: (context, canConfirm, _) => AppButton.primary(
            identifier: 'mac-filter-add-mac-confirm',
            label: loc(context).add,
            onTap: canConfirm ? _confirm : null,
          ),
        ),
      ],
    );
  }
}
