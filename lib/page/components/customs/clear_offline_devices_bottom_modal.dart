import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClearDevicesModal extends StatelessWidget {
  const ClearDevicesModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    .then((value) => NavigationCubit.of(context).pop());
              },
            ),
            box16(),
            SecondaryButton(
              text: getAppLocalizations(context).cancel,
              onPress: () {
                NavigationCubit.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
