import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
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
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _canConfirm.dispose();
    super.dispose();
  }

  String? _errorFor(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (!UspMacFilterService.validateMac(value)) return 'invalidMacFormat';
    final normalized = UspMacFilterService.normalizeMac(value);
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

  void _confirm() {
    widget.onAdd(UspMacFilterService.normalizeMac(_controller.text));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (_) {
                setState(() => _errorKey = _errorFor(_controller.text));
                _revalidate();
              },
            ),
          ),
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
