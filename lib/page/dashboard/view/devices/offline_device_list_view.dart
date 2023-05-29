import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/bloc/profiles/_profiles.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/_customs.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

class OfflineDeviceListView extends ArgumentsConsumerStatefulView {
  const OfflineDeviceListView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<OfflineDeviceListView> createState() =>
      _OfflineDeviceListViewState();
}

class _OfflineDeviceListViewState extends ConsumerState<OfflineDeviceListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) => BasePageView(
        // scrollable: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).offline_devices,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).clear_all,
              onPressed:
                  context.read<DeviceCubit>().state.offlineDeviceList.isEmpty
                      ? null
                      : () {
                          ref
                              .read(navigationsProvider.notifier)
                              .push(ClearOfflineDevicesPath());
                        },
            ),
          ],
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.offlineDeviceList.length.toString() +
                    ' '.toLowerCase() +
                    getAppLocalizations(context).offline.toLowerCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              box16(),
              _offlineDeviceList(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offlineDeviceList(DeviceState state) {
    if (state.offlineDeviceList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box36(),
          Text(getAppLocalizations(context).there_are_no_offline_devices),
        ],
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        // physics: const NeverScrollableScrollPhysics(),
        itemCount: state.offlineDeviceList.length,
        itemBuilder: (context, index) => InkWell(
          child:
              _offlineDeviceInfoCell(state.offlineDeviceList.elementAt(index)),
          onTap: null,
        ),
      );
    }
  }

  _offlineDeviceInfoCell(DeviceDetailInfo deviceInfo) {
    Widget deviceIcon = ImageWithBadge(
      imagePath: deviceInfo.icon,
      badgePath: deviceInfo.profileId != null
          ? context
              .read<ProfilesCubit>()
              .state
              .profiles[deviceInfo.profileId!]
              ?.icon
          : null,
      imageSize: 48,
      badgeSize: 19,
      offset: deviceInfo.profileId != null ? 5 : 0,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          deviceIcon,
          box16(),
          Expanded(
            child: Text(
              deviceInfo.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
