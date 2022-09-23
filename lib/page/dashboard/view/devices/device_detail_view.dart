import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/device.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/route/model/devices_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/model/profile_group_path.dart';
import 'package:linksys_moab/route/_route.dart';


class DeviceDetailView extends ArgumentsStatefulView {
  const DeviceDetailView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<DeviceDetailView> createState() => _DeviceDetailViewState();
}

class _DeviceDetailViewState extends State<DeviceDetailView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(
        builder: (context, state) => BasePageView(
              scrollable: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                // iconTheme:
                // IconThemeData(color: Theme.of(context).colorScheme.primary),
                elevation: 0,
                title: Text(
                  state.selectedDeviceInfo?.name ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              child: BasicLayout(
                alignment: CrossAxisAlignment.start,
                header: _header(state),
                content: _content(state),
              ),
            ));
  }

  _header(DeviceState state) {
    return Column(
      children: [
        box24(),
        Image.asset(
          state.selectedDeviceInfo?.icon ?? 'assets/images/icon_device.png',
          width: 100,
          height: 100,
        ),
        box16(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getWifiIcon(),
            // TODO: Set status according to device info
            const Text(
              'Online',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(8, 112, 234, 1.0),
              ),
            ),
          ],
        ),
        box16(),
        _headerCell(getAppLocalizations(context).device_name,
            state.selectedDeviceInfo?.name, () {
          NavigationCubit.of(context).push(EditDeviceNamePath());
        }),
        _headerCell(getAppLocalizations(context).node_detail_label_connected_to,
            state.selectedDeviceInfo?.connectedTo, () {}),
        if (state.selectedDeviceInfo?.profileId != null)
          _headerCell(
              getAppLocalizations(context).profile,
              context
                  .read<ProfilesCubit>()
                  .state
                  .profiles[state.selectedDeviceInfo?.profileId]
                  ?.name,
              () {
                String? profileId = state.selectedDeviceInfo?.profileId;
                Profile? profile = context
                    .read<ProfilesCubit>().state.profiles[profileId ?? ''];
                if (profile != null) {
                  context
                      .read<ProfilesCubit>()
                      .selectProfile(profile);
                  NavigationCubit.of(context).push(ProfileOverviewPath());
                }
              }),
        box24(),
      ],
    );
  }

  _headerCell(String title, String? data, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            if (data != null)
              Text(
                data,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(102, 102, 102, 1.0),
                ),
              ),
            box16(),
            Image.asset('assets/images/icon_chevron.png'),
          ],
        ),
      ),
    );
  }

  _content(DeviceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getAppLocalizations(context).wifi_all_capital,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(0, 0, 0, 0.5),
          ),
        ),
        _contentCell(getAppLocalizations(context).ip_address,
            state.selectedDeviceInfo?.ipAddress ?? ''),
        _contentCell(getAppLocalizations(context).mac_address,
            state.selectedDeviceInfo?.macAddress ?? ''),
        box36(),
        Text(
          getAppLocalizations(context).details_all_capital,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(0, 0, 0, 0.5),
          ),
        ),
        _contentCell(getAppLocalizations(context).manufacturer,
            state.selectedDeviceInfo?.manufacturer ?? ''),
        _contentCell(getAppLocalizations(context).model,
            state.selectedDeviceInfo?.model ?? ''),
        _contentCell(getAppLocalizations(context).operating_system,
            state.selectedDeviceInfo?.os ?? ''),
      ],
    );
  }

  _contentCell(String title, String data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
          box4(),
          Text(
            data,
            style: const TextStyle(
              fontSize: 13,
              color: Color.fromRGBO(102, 102, 102, 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget getWifiIcon() {
    // TODO: According to device wifi signal return proper wifi icon
    return Image.asset(
      'assets/images/icon_wifi_signal_excellent.png',
      width: 22,
      height: 22,
    );
  }
}
