import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/_shared/models/wifi_radio_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dialog for editing WiFi radio channel settings.
///
/// Returns a `({int channel, bool autoChannel})` record on Apply, or null on Cancel.
class WifiChannelDialog extends StatefulWidget {
  final WifiRadioUIModel radio;

  const WifiChannelDialog({super.key, required this.radio});

  @override
  State<WifiChannelDialog> createState() => _WifiChannelDialogState();
}

class _WifiChannelDialogState extends State<WifiChannelDialog> {
  late bool _autoChannel;
  late TextEditingController _channelController;

  @override
  void initState() {
    super.initState();
    _autoChannel = widget.radio.autoChannelEnable;
    _channelController =
        TextEditingController(text: widget.radio.channel.toString());
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Channel — ${widget.radio.band}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium('Auto Channel'),
              AppSwitch(
                value: _autoChannel,
                onChanged: (value) => setState(() => _autoChannel = value),
              ),
            ],
          ),
          AppGap.lg(),
          AppTextField(
            controller: _channelController,
            hintText: 'Channel number',
            keyboardType: TextInputType.number,
            readOnly: _autoChannel,
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
            final channel =
                int.tryParse(_channelController.text) ?? widget.radio.channel;
            Navigator.of(context)
                .pop((channel: channel, autoChannel: _autoChannel));
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
