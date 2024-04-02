import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class FirmwareUpdateProcessView extends ConsumerStatefulWidget {
  final (LinksysDevice, FirmwareUpdateStatus)? current;
  const FirmwareUpdateProcessView({super.key, this.current});

  @override
  ConsumerState<FirmwareUpdateProcessView> createState() =>
      _FirmwareUpdateProcessViewState();
}

class _FirmwareUpdateProcessViewState
    extends ConsumerState<FirmwareUpdateProcessView> {
  static const _updateMessageMap = {
    'Checking': {
      'title': 'Downloading...',
      'message1': 'You can use your Wi-Fi during this update.',
      'message2':
          'But things might be slower than usual while we improve your system.',
      'message3':
          'This will take about 15 minutes, after which your Wi-Fi will restart.',
    },
    'Downloading': {
      'title': 'Downloading...',
      'message1': 'You can use your Wi-Fi during this update.',
      'message2':
          'But things might be slower than usual while we improve your system.',
      'message3':
          'This will take about 15 minutes, after which your Wi-Fi will restart.',
    },
    'Installing': {
      'title': 'Installing...',
      'message1': 'You can use your Wi-Fi during this update.',
      'message2':
          'But things might be slower than usual while we improve your system.',
      'message3':
          'This will take about 15 minutes, after which your Wi-Fi will restart.',
    },
    'Rebooting': {
      'title': 'Restarting...',
      'message1': 'Restarting your Wi-Fi',
      'message2':
          'Future updates will happen overnight - automatically - and only take a few minutes.',
      'message3': 'This takes 2-3 minutes.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final messages =
        _updateMessageMap[widget.current?.$2.pendingOperation?.operation ?? ''];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Firmware Updating...'),
        const AppGap.big(),
        CircularProgressIndicator.adaptive(),
        const AppGap.big(),
        AppText.labelLarge(
            'Current Update - ${widget.current?.$1.getDeviceName() ?? ''} - ${widget.current?.$2.pendingOperation?.progressPercent}'),
        const AppGap.big(),
        if (messages != null) ...[
          AppText.titleSmall(messages['title'] ?? ''),
          AppText.bodySmall(messages['message1'] ?? ''),
          AppText.bodySmall(messages['message2'] ?? ''),
          AppText.bodySmall(messages['message3'] ?? ''),
        ]
      ],
    );
  }
}
