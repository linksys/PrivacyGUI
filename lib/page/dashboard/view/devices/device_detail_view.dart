import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/nodes_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/profile_header_layout.dart';

class DeviceDetailView extends ArgumentsConsumerStatefulView {
  const DeviceDetailView({Key? key, super.args, super.next}) : super(key: key);

  @override
  ConsumerState<DeviceDetailView> createState() => _DeviceDetailViewState();
}

class _DeviceDetailViewState extends ConsumerState<DeviceDetailView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(builder: (context, state) {
      return LayoutBuilder(builder: (context, constraint) {
        return AppProfileHeaderLayout(
          expandedHeight: constraint.maxHeight / 2,
          collaspeTitle: state.selectedDeviceInfo?.name,
          onCollaspeBackTap: () {
            ref.read(navigationsProvider.notifier).pop();
          },
          header: Column(
            children: [
              LinksysAppBar(
                backgroundColor:
                    AppTheme.of(context).colors.headerBackgroundEnd,
                leading: AppIconButton(
                  icon: getCharactersIcons(context).arrowLeft,
                  onTap: () {
                    ref.read(navigationsProvider.notifier).pop();
                  },
                ),
              ),
              const Spacer(),
              _header(state),
            ],
          ),
          body: Column(
            children: [
              _content(state),
            ],
          ),
        );
      });
    });
  }

  Widget _header(DeviceState state) {
    final device = state.selectedDeviceInfo!;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppTheme.of(context).colors.headerBackgroundStart,
            AppTheme.of(context).colors.headerBackgroundEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          _deviceAvatar(state),
          const AppGap.regular(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppText.textLinkLarge(
                device.name,
                color: AppTheme.of(context).colors.textBoxText,
              ),
              Positioned(
                top: -2.5,
                right: -(AppTheme.of(context).spacing.big),
                child: AppIconButton.noPadding(
                  icon: getCharactersIcons(context).editDefault,
                  onTap: () {
                    //TODO: Go to edit page
                  },
                ),
              ),
            ],
          ),
          const AppGap.extraBig(),
          _deviceStatus(state),
          const AppGap.big(),
        ],
      ),
    );
  }

  Widget _deviceAvatar(DeviceState state) {
    return AppDeviceAvatar.extraLarge(
        image: AppTheme.of(context)
            .images
            .devices
            .getByName(state.selectedDeviceInfo!.icon));
  }

  Widget _deviceStatus(DeviceState state) {
    final device = state.selectedDeviceInfo!;
    final textColor = AppTheme.of(context).colors.textBoxText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: Image(
                image: AppTheme.of(context).images.devices.getByName(
                      device.parentInfo?.icon ?? 'genericDevice',
                    ),
                height: 120 * 0.75,
                width: 120 * 0.75,
              ),
            ),
            AppText.label(
              device.parentInfo?.place ?? '',
              color: textColor,
            ),
          ],
        ),
        InkWell(
          onTap: () {
            ref.read(navigationsProvider.notifier).push(TopologyPath()
              ..args = {
                'selectedDeviceId': device.deviceID,
              });
          },
          child: Column(
            children: [
              Container(
                height: AppTheme.of(context).spacing.extraBig,
                width: AppTheme.of(context).spacing.extraBig,
                alignment: Alignment.center,
                child: AppIcon.big(
                  icon: Utils.getWifiSignalIconData(
                    context,
                    device.signal,
                  ),
                ),
              ),
              AppText.label(
                Utils.getWifiSignalLevel(device.signal).displayTitle,
                color: textColor,
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: AppIcon.big(
                icon: AppTheme.of(context).icons.characters.profileDefault,
              ),
            ),
            AppText.label(
              'Timmy',
              color: textColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _content(DeviceState state) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPadding(
                      padding: const AppEdgeInsets.symmetric(
                        horizontal: AppGapSize.semiBig,
                      ),
                      child: Column(
                        children: [
                          _wifiSection(state),
                          _detailSection(state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wifiSection(DeviceState state) {
    final device = state.selectedDeviceInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        AppText.tags(
          getAppLocalizations(context).wifi_all_capital,
          color: ConstantColors.secondaryCyberPurple,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).ip_address,
          description: device.ipAddress, //TODO: It may be empty
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).mac_address,
          description: device.macAddress,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).ipv6_address,
          description: device.macAddress, //TODO: Get IPv6 data
        ),
      ],
    );
  }

  Widget _detailSection(DeviceState state) {
    final device = state.selectedDeviceInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.tags(
          getAppLocalizations(context).details_all_capital,
          color: ConstantColors.secondaryCyberPurple,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).manufacturer,
          description: device.manufacturer,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).model,
          description: device.model,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).operating_system,
          description: device.os,
        ),
      ],
    );
  }
}
