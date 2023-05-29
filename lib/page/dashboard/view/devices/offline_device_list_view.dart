import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/bloc/profiles/_profiles.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/customs/_customs.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';

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
      builder: (context, state) => StyledAppPageView(
        // scrollable: true,
        title: getAppLocalizations(context).offline_devices,
        actions: [
          AppTertiaryButton(
            getAppLocalizations(context).clear_all,
            onTap: context.read<DeviceCubit>().state.offlineDeviceList.isEmpty
                ? null
                : () {
                    ref
                        .read(navigationsProvider.notifier)
                        .push(ClearOfflineDevicesPath());
                  },
          ),
        ],
        child: AppBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.mainTitle(
                state.offlineDeviceList.length.toString() +
                    ' '.toLowerCase() +
                    getAppLocalizations(context).offline.toLowerCase(),
              ),
              const AppGap.regular(),
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
          const AppGap.big(),
          AppText.descriptionMain(
            getAppLocalizations(context).there_are_no_offline_devices,
          ),
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
    return AppPadding(
      padding: const AppEdgeInsets.symmetric(vertical: AppGapSize.regular),
      child: Row(
        children: [
          deviceIcon,
          const AppGap.regular(),
          Expanded(
            child: AppText.navLabel(
              deviceInfo.name,
            ),
          ),
        ],
      ),
    );
  }
}
