import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

class ClearDevicesModal extends ConsumerWidget {
  const ClearDevicesModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePageView.bottomSheetModal(
      bottomSheet: Container(
        // color: Colors.white,
        height: 350,
        padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getAppLocalizations(context).clear_all_offline_devices,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            box16(),
            Text(
              getAppLocalizations(context).clear_all_offline_devices_desc,
              style: const TextStyle(fontSize: 15),
            ),
            box24(),
            PrimaryButton(
              text: getAppLocalizations(context).clear,
              onPress: () {
                context
                    .read<DeviceCubit>()
                    .deleteDeviceList(
                        context.read<DeviceCubit>().state.offlineDeviceList)
                    .then((value) =>
                        ref.read(navigationsProvider.notifier).pop());
              },
            ),
            box16(),
            SecondaryButton(
              text: getAppLocalizations(context).cancel,
              onPress: () {
                ref.read(navigationsProvider.notifier).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
