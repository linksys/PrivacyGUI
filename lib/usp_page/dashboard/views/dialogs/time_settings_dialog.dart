import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/time_settings_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [TimeSettingsDialog].
class TimeSettingsDialogResult {
  final bool enable;
  final String ntpServer1;
  final String ntpServer2;

  const TimeSettingsDialogResult({
    required this.enable,
    required this.ntpServer1,
    required this.ntpServer2,
  });
}

/// Dialog for editing Time Settings (enable + NTP servers).
class TimeSettingsDialog extends StatefulWidget {
  final TimeSettingsUIModel settings;

  const TimeSettingsDialog({super.key, required this.settings});

  @override
  State<TimeSettingsDialog> createState() => _TimeSettingsDialogState();
}

class _TimeSettingsDialogState extends State<TimeSettingsDialog> {
  late bool _enable;
  late TextEditingController _ntp1Controller;
  late TextEditingController _ntp2Controller;

  @override
  void initState() {
    super.initState();
    _enable = widget.settings.enable;
    _ntp1Controller = TextEditingController(text: widget.settings.ntpServer1);
    _ntp2Controller = TextEditingController(text: widget.settings.ntpServer2);
  }

  @override
  void dispose() {
    _ntp1Controller.dispose();
    _ntp2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Time Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium('Time Client'),
              AppSwitch(
                value: _enable,
                onChanged: (value) => setState(() => _enable = value),
              ),
            ],
          ),
          AppGap.lg(),
          AppTextField(
            controller: _ntp1Controller,
            hintText: 'NTP Server 1',
          ),
          AppGap.lg(),
          AppTextField(
            controller: _ntp2Controller,
            hintText: 'NTP Server 2',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(TimeSettingsDialogResult(
              enable: _enable,
              ntpServer1: _ntp1Controller.text.trim(),
              ntpServer2: _ntp2Controller.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
