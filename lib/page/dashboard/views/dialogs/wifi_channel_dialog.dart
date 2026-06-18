import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
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
      title: Text('${loc(context).channel} — ${widget.radio.band}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyMedium(loc(context).autoChannel),
              AppSwitch(
                value: _autoChannel,
                onChanged: (value) => setState(() => _autoChannel = value),
              ),
            ],
          ),
          AppGap.lg(),
          AppTextField(
            controller: _channelController,
            hintText: loc(context).channelNumber,
            keyboardType: TextInputType.number,
            readOnly: _autoChannel,
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
            final channel =
                int.tryParse(_channelController.text) ?? widget.radio.channel;
            Navigator.of(context)
                .pop((channel: channel, autoChannel: _autoChannel));
          },
          child: Text(loc(context).apply),
        ),
      ],
    );
  }
}
