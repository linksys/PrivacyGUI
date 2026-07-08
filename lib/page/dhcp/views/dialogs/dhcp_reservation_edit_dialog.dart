import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Unified dialog for adding or editing a DHCP reservation.
///
/// Pass [reservation] to pre-fill for editing; omit for adding.
/// Returns a `({String mac, String ip, bool enable})` record on submit, or null on cancel.
class DhcpReservationEditDialog extends StatefulWidget {
  final DhcpReservationUIModel? reservation;
  final List<AppAutoCompleteOption> macDeviceOptions;
  final List<AppAutoCompleteOption> ipDeviceOptions;

  const DhcpReservationEditDialog({
    super.key,
    this.reservation,
    this.macDeviceOptions = const [],
    this.ipDeviceOptions = const [],
  });

  @override
  State<DhcpReservationEditDialog> createState() =>
      _DhcpReservationEditDialogState();
}

class _DhcpReservationEditDialogState extends State<DhcpReservationEditDialog> {
  static final _macRule = MACAddressRule();
  static final _ipRule = IpAddressRule();
  static final _ipNoReservedRule = IpAddressNoReservedRule();

  late TextEditingController _macController;
  late TextEditingController _ipController;
  final _macFocusNode = FocusNode();
  final _ipFocusNode = FocusNode();
  late bool _enabled;
  Map<String, String> _errors = {};

  bool get _isEdit => widget.reservation != null;
  bool get _isFormValid => _errors.isEmpty && _hasInput;
  bool get _hasInput =>
      _macController.text.trim().isNotEmpty &&
      _ipController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final r = widget.reservation;
    _macController = TextEditingController(text: r?.mac ?? '');
    _ipController = TextEditingController(text: r?.ip ?? '');
    _enabled = r?.enable ?? true;
    _macFocusNode.addListener(_onMacFocusChange);
    _ipFocusNode.addListener(_onIpFocusChange);
  }

  @override
  void dispose() {
    _macFocusNode.removeListener(_onMacFocusChange);
    _ipFocusNode.removeListener(_onIpFocusChange);
    _macFocusNode.dispose();
    _ipFocusNode.dispose();
    _macController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _onMacFocusChange() {
    if (!_macFocusNode.hasFocus) _validate();
  }

  void _onIpFocusChange() {
    if (!_ipFocusNode.hasFocus) _validate();
  }

  void _validate() {
    final errors = <String, String>{};
    final mac = _macController.text.trim();
    final ip = _ipController.text.trim();

    if (mac.isNotEmpty && !_macRule.validate(mac)) {
      errors['mac'] = 'invalidMacAddressFormat';
    }

    if (ip.isNotEmpty) {
      if (!_ipRule.validate(ip)) {
        errors['ip'] = 'invalidIpv4Format';
      } else if (!_ipNoReservedRule.validate(ip)) {
        errors['ip'] = 'reservedIpNotAllowed';
      }
    }

    setState(() => _errors = errors);
  }

  String? _localizeError(String? key) {
    if (key == null) return null;
    return switch (key) {
      'invalidMacAddressFormat' => loc(context).invalidMacAddressFormat,
      'invalidIpv4Format' => loc(context).invalidIpv4Format,
      'reservedIpNotAllowed' => loc(context).reservedIpNotAllowed,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppText.titleLarge(_isEdit
          ? loc(context).editDhcpReservation
          : loc(context).addDhcpReservation),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSelectAutoComplete(
            options: widget.macDeviceOptions,
            controller: _macController,
            onSelected: (value) {
              final match = widget.macDeviceOptions
                  .where((o) => o.value == value)
                  .firstOrNull;
              if (match?.subtitle != null) {
                _ipController.text = match!.subtitle!;
              }
              _validate();
            },
            child: AppTextField(
              controller: _macController,
              focusNode: _macFocusNode,
              hintText: loc(context).macAddressHint,
              errorText: _localizeError(_errors['mac']),
            ),
          ),
          AppGap.lg(),
          AppSelectAutoComplete(
            options: widget.ipDeviceOptions,
            controller: _ipController,
            onSelected: (value) {
              final match = widget.ipDeviceOptions
                  .where((o) => o.value == value)
                  .firstOrNull;
              if (match?.subtitle != null) {
                _macController.text = match!.subtitle!;
              }
              _validate();
            },
            child: AppTextField(
              controller: _ipController,
              focusNode: _ipFocusNode,
              hintText: loc(context).ipAddressHint,
              errorText: _localizeError(_errors['ip']),
            ),
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
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.text(
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _isFormValid ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    _validate();
    if (!_isFormValid) return;
    final mac = _macController.text.trim();
    final ip = _ipController.text.trim();
    context.pop((mac: mac, ip: ip, enable: _enabled));
  }
}
