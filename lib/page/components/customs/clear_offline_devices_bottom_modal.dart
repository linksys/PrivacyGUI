import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/bloc/device/_device.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';

class ClearDevicesModal extends ConsumerWidget {
  const ClearDevicesModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageView.bottomSheetModal(
      bottomSheet: Container(
        // color: Colors.white,
        height: 350,
        padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.subhead(
              getAppLocalizations(context).clear_all_offline_devices,
            ),
            const AppGap.semiBig(),
            AppText.label(
              getAppLocalizations(context).clear_all_offline_devices_desc,
            ),
            const AppGap.semiBig(),
            AppPrimaryButton(
              getAppLocalizations(context).clear,
              onTap: () {
                context
                    .read<DeviceCubit>()
                    .deleteDeviceList(
                        context.read<DeviceCubit>().state.offlineDeviceList)
                    .then((value) => context.pop());
              },
            ),
            const AppGap.regular(),
            AppSecondaryButton(
              getAppLocalizations(context).cancel,
              onTap: () {
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
