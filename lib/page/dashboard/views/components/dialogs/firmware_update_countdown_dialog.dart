import 'dart:async';
import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A countdown dialog shown after firmware update completion.
/// Displays a 5-second countdown before reloading the application.
class FirmwareUpdateCountdownDialog extends StatefulWidget {
  final VoidCallback onFinish;
  const FirmwareUpdateCountdownDialog({super.key, required this.onFinish});

  @override
  State<FirmwareUpdateCountdownDialog> createState() =>
      _FirmwareUpdateCountdownDialogState();
}

class _FirmwareUpdateCountdownDialogState
    extends State<FirmwareUpdateCountdownDialog> {
  int _seconds = 5;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 1) {
        _timer.cancel();
        Navigator.of(context).pop();
        widget.onFinish();
      } else {
        setState(() {
          _seconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleLarge(loc(context).firmwareUpdated),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          AppGap.lg(),
          AppText.labelLarge(
            loc(context).firmwareUpdateCountdownMessage(_seconds),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
