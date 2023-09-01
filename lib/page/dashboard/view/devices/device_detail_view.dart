import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/bloc/device/_device.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/profile_header_layout.dart';

class DeviceDetailView extends ArgumentsConsumerStatefulView {
  const DeviceDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

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
            context.pop();
          },
          background: Theme.of(context).colorScheme.tertiaryContainer,
          header: Column(
            children: [
              LinksysAppBar(
                leading: AppIconButton(
                  icon: getCharactersIcons(context).arrowLeft,
                  onTap: () {
                    context.pop();
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
      decoration:
          BoxDecoration(color: Theme.of(context).colorScheme.tertiaryContainer),
      child: Column(
        children: [
          _deviceAvatar(state),
          const AppGap.regular(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppText.titleSmall(
                device.name,
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
          // const AppGap.extraBig(),
          _deviceStatus(state),
          const AppGap.semiSmall(),
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
            AppText.headlineSmall(
              device.parentInfo?.place ?? '',
            ),
          ],
        ),
        InkWell(
          onTap: () {
            context.pushNamed(
              RouteNamed.settingsNodes,
              queryParameters: {
                'selectedDeviceId': device.deviceID,
              },
            );
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
              AppText.headlineSmall(
                Utils.getWifiSignalLevel(device.signal).displayTitle,
              ),
            ],
          ),
        ),
        const Center(),
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
        AppText.titleLarge(
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
        AppText.titleLarge(
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
