import 'package:flutter/material.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows a dialog to edit timezone settings (timezone string, NTP servers).
///
/// Returns a [TimezoneEditResult] if saved, or null if cancelled.
Future<TimezoneEditResult?> showTimezoneEditDialog(
  BuildContext context, {
  required TimeSettingsUIModel current,
}) {
  final tzController = TextEditingController(text: current.localTimeZone);
  final ntp1Controller = TextEditingController(text: current.ntpServer1);
  final ntp2Controller = TextEditingController(text: current.ntpServer2);

  return showSubmitAppDialog<TimezoneEditResult>(
    context,
    scrollable: true,
    useRootNavigator: false,
    title: 'Edit Timezone',
    contentBuilder: (context, setState, onSubmit) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            key: const Key('timezoneField'),
            controller: tzController,
            label: 'Timezone (POSIX)',
          ),
          AppGap.lg(),
          AppTextFormField(
            key: const Key('ntp1Field'),
            controller: ntp1Controller,
            label: 'NTP Server 1',
          ),
          AppGap.lg(),
          AppTextFormField(
            key: const Key('ntp2Field'),
            controller: ntp2Controller,
            label: 'NTP Server 2',
          ),
        ],
      );
    },
    event: () async {
      return TimezoneEditResult(
        localTimeZone: tzController.text,
        ntpServer1: ntp1Controller.text,
        ntpServer2: ntp2Controller.text,
      );
    },
  );
}

class TimezoneEditResult {
  final String localTimeZone;
  final String ntpServer1;
  final String ntpServer2;

  const TimezoneEditResult({
    required this.localTimeZone,
    required this.ntpServer1,
    required this.ntpServer2,
  });
}
