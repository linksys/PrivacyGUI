import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dialog for adding a new DHCP reservation.
///
/// Returns a `({String mac, String ip, bool enable})` record on Add, or null on Cancel.
class DhcpReservationDialog extends StatefulWidget {
  const DhcpReservationDialog({super.key});

  @override
  State<DhcpReservationDialog> createState() => _DhcpReservationDialogState();
}

class _DhcpReservationDialogState extends State<DhcpReservationDialog> {
  final _macController = TextEditingController();
  final _ipController = TextEditingController();
  bool _enabled = true;

  @override
  void dispose() {
    _macController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(loc(context).addDhcpReservation),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _macController,
            hintText: 'MAC Address (e.g. AA:BB:CC:DD:EE:FF)',
          ),
          AppGap.lg(),
          AppTextField(
            controller: _ipController,
            hintText: 'IP Address (e.g. 192.168.1.100)',
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            final mac = _macController.text.trim();
            final ip = _ipController.text.trim();
            if (mac.isEmpty || ip.isEmpty) return;
            Navigator.of(context).pop((mac: mac, ip: ip, enable: _enabled));
          },
          child: Text(loc(context).add),
        ),
      ],
    );
  }
}
