import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/provider/devices/external_device_detail_provider.dart';
import 'package:linksys_app/provider/devices/external_device_detail_state.dart';
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
    final state = ref.watch(externalDeviceDetailProvider);
    //TODO: XXXXXX Fix wrong device error!!
    return LayoutBuilder(
      builder: (context, constraint) {
        return AppProfileHeaderLayout(
          expandedHeight: constraint.maxHeight / 2,
          collaspeTitle: state.item.name,
          onCollaspeBackTap: () {
            context.pop();
          },
          header: Column(
            children: [
              LinksysAppBar(
                backgroundColor:
                    AppTheme.of(context).colors.headerBackgroundEnd,
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
      },
    );
  }

  Widget _header(ExternalDeviceDetailState state) {
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
          _deviceAvatar(state.item.icon),
          const AppGap.regular(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppText.textLinkLarge(
                state.item.name,
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
          // const AppGap.extraBig(),
          _deviceStatus(state),
          const AppGap.semiSmall(),
        ],
      ),
    );
  }

  Widget _deviceAvatar(String iconName) {
    return AppDeviceAvatar.extraLarge(
      image: AppTheme.of(context).images.devices.getByName(iconName),
    );
  }

  Widget _deviceStatus(ExternalDeviceDetailState state) {
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
                      state.item.upstreamIcon,
                    ),
                height: 120 * 0.75,
                width: 120 * 0.75,
              ),
            ),
            AppText.label(
              state.item.upstreamDevice,
              color: textColor,
            ),
          ],
        ),
        InkWell(
          onTap: () {
            context.pushNamed(
              RouteNamed.settingsNodes,
              queryParameters: {
                'selectedDeviceId': state.item.deviceId,
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
                    state.item.signalStrength,
                  ),
                ),
              ),
              AppText.label(
                Utils.getWifiSignalLevel(state.item.signalStrength).displayTitle,
                color: textColor,
              ),
            ],
          ),
        ),
        const Center(),
      ],
    );
  }

  Widget _content(ExternalDeviceDetailState state) {
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

  Widget _wifiSection(ExternalDeviceDetailState state) {
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
          description: state.item.ipv4Address,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).mac_address,
          description: state.item.macAddress,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).ipv6_address,
          description: state.item.ipv6Address,
        ),
      ],
    );
  }

  Widget _detailSection(ExternalDeviceDetailState state) {
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
          description: state.item.manufacturer,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).model,
          description: state.item.model,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).operating_system,
          description: state.item.operatingSystem,
        ),
      ],
    );
  }
}
