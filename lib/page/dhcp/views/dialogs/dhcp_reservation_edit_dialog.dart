import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Unified dialog for adding or editing a DHCP reservation.
///
/// Pass [reservation] to pre-fill for editing; omit for adding.
/// Returns a `({String mac, String ip, bool enable})` record on submit, or null on cancel.
class DhcpReservationEditDialog extends StatefulWidget {
  final DhcpReservationUIModel? reservation;

  const DhcpReservationEditDialog({super.key, this.reservation});

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
  }

  @override
  void dispose() {
    _macController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _validate() {
    final errors = <String, String>{};
    final mac = _macController.text.trim();
    final ip = _ipController.text.trim();

    if (mac.isNotEmpty && !_macRule.validate(mac)) {
      errors['mac'] = 'Invalid MAC address format (e.g. AA:BB:CC:DD:EE:FF)';
    }

    if (ip.isNotEmpty) {
      if (!_ipRule.validate(ip)) {
        errors['ip'] = 'Invalid IP address format';
      } else if (!_ipNoReservedRule.validate(ip)) {
        errors['ip'] = 'Reserved IP address is not allowed';
      }
    }

    setState(() => _errors = errors);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit DHCP Reservation' : 'Add DHCP Reservation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _macController,
            hintText: 'MAC Address (e.g. AA:BB:CC:DD:EE:FF)',
            onChanged: (_) => _validate(),
            errorText: _errors['mac'],
          ),
          AppGap.lg(),
          AppTextField(
            controller: _ipController,
            hintText: 'IP Address (e.g. 192.168.1.100)',
            onChanged: (_) => _validate(),
            errorText: _errors['ip'],
          ),
          AppGap.lg(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium('Enabled'),
              AppSwitch(
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isFormValid ? _submit : null,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    final mac = _macController.text.trim();
    final ip = _ipController.text.trim();
    Navigator.of(context).pop((mac: mac, ip: ip, enable: _enabled));
  }
}
