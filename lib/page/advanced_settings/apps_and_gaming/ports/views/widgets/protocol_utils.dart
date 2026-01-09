import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';

import 'package:ui_kit_library/ui_kit.dart';

mixin ProtocolMixin on State {}
String getProtocolTitle(BuildContext context, String key) {
  if (key == 'UDP') {
    return loc(context).udp;
  } else if (key == 'TCP') {
    return loc(context).tcp;
  } else {
    return loc(context).udpAndTcp;
  }
}

Future<String?> showSelectProtocolModal(
  BuildContext context,
  String value,
) {
  String selected = value;
  return showSimpleAppDialog<String?>(context,
      title: loc(context).channel,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRadioList<String>(
            selected: value,
            itemHeight: 56,
            items: ['TCP', 'UDP', 'Both']
                .map((e) => AppRadioListItem(
                      title: getProtocolTitle(context, e),
                      value: e,
                    ))
                .toList(),
            onChanged: (index, selectedType) {
              if (selectedType != null) {
                selected = selectedType;
              }
            },
          ),
        ],
      ),
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          label: loc(context).ok,
          onTap: () {
            context.pop(selected);
          },
        ),
      ]);
}
